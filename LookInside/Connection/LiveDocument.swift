//
//  LiveDocument.swift
//  LookInside
//
//  The document of one live inspection session against one inspectable
//  app over its channel. It is untitled, never autosaves, and Save As exports
//  the current hierarchy as a `.lookin` file. When the app's channel ends,
//  the document shows a banner and looks for the same app every 3 seconds;
//  when it reappears, the document switches to its new channel.
//

import AppKit

@objc(LookinLiveDocument)
final class LiveDocument: NSDocument {
    /// Posted (object: the document) once `LiveDocumentController`
    /// added the document and made its window controllers, so observers can
    /// read `inspectableApp` and `hierarchyDataSource` at once.
    /// `NSDocumentController` has no such notification of its own.
    static let didOpenNotification = Notification.Name("LookinLiveDocumentDidOpenNotification")

    /// Posted (object: the document) at the start of `close()`, while the
    /// document is still whole.
    static let willCloseNotification = Notification.Name("LookinLiveDocumentWillCloseNotification")

    /// The app this document inspects. Replaced by a new `InspectableApp`
    /// (new channel and app info) when the app reconnects. Observable with
    /// KVO.
    @objc private(set) dynamic var inspectableApp: InspectableApp

    /// Why the connection was lost, or nil while connected. Observable with
    /// KVO; the window shows it as a banner.
    @objc private(set) dynamic var connectionLossBannerMessage: String?

    /// The app info from before the channel ended, matched against the
    /// apps found while reconnecting.
    private var lastKnownAppInfo: InspectedAppInfo?
    private var channelEndTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?

    init(inspectableApp: InspectableApp) {
        self.inspectableApp = inspectableApp
        super.init()
        subscribeChannelLifecycle()
    }

    /// A document can be freed without `close()` (for example when its
    /// window never opened). The tasks hold `self` weakly, so they would
    /// stay parked and the channel-end subscriber would stay registered;
    /// cancelling ends the stream, which unregisters it.
    deinit {
        channelEndTask?.cancel()
        reconnectTask?.cancel()
    }

    /// The live document whose window is `window`, or nil.
    @objc(documentInWindow:)
    static func document(in window: NSWindow?) -> LiveDocument? {
        guard let window else { return nil }
        return NSDocumentController.shared.document(for: window) as? LiveDocument
    }

    /// Nil before `makeWindowControllers()` ran.
    var staticWindowController: StaticWindowController? {
        windowControllers.first as? StaticWindowController
    }

    /// Nil before `makeWindowControllers()` ran.
    @objc var hierarchyDataSource: StaticHierarchyDataSource? {
        staticWindowController?.hierarchyDataSource
    }

    /// Nil before `makeWindowControllers()` ran.
    @objc var asyncUpdateManager: StaticAsyncUpdateManager? {
        staticWindowController?.asyncUpdateManager
    }

    // MARK: - NSDocument

    override var displayName: String! {
        get {
            let info = inspectableApp.appInfo
            let appName = info?.appName ?? ""
            let deviceDescription = info?.deviceDescription ?? ""
            if !appName.isEmpty, !deviceDescription.isEmpty {
                return "\(appName) — \(deviceDescription)"
            } else if !appName.isEmpty {
                return appName
            }
            return super.displayName
        }
        set {
            super.displayName = newValue
        }
    }

    override var hasUnautosavedChanges: Bool {
        false
    }

    override var isDocumentEdited: Bool {
        false
    }

    override class var autosavesInPlace: Bool {
        false
    }

    override class var autosavesDrafts: Bool {
        false
    }

    override class var preservesVersions: Bool {
        false
    }

    override class var usesUbiquitousStorage: Bool {
        false
    }

    override func writableTypes(for saveOperation: NSDocument.SaveOperationType) -> [String] {
        saveOperation == .saveAsOperation ? ["com.lookin.lookin"] : []
    }

    override func data(ofType typeName: String) throws -> Data {
        guard typeName == "com.lookin.lookin",
              let info = hierarchyDataSource?.rawHierarchyInfo,
              let data = ExportManager.sharedInstance().data(from: info, imageCompression: 1.0, fileName: nil)
        else {
            throw ConnectionError.inner
        }
        return data
    }

    override func makeWindowControllers() {
        addWindowController(StaticWindowController(inspectableApp: inspectableApp))
    }

    override func close() {
        // Before any teardown, so observers can still read the app info and
        // the data source.
        NotificationCenter.default.post(name: Self.willCloseNotification, object: self)
        channelEndTask?.cancel()
        channelEndTask = nil
        reconnectTask?.cancel()
        reconnectTask = nil
        super.close()
    }

    // MARK: - Channel lifecycle

    /// Watches the current app's channel; a reconnect calls this again for
    /// the new channel.
    private func subscribeChannelLifecycle() {
        guard inspectableApp.channel != nil else {
            // Nothing to watch until a reconnect brings a channel.
            return
        }
        channelEndTask?.cancel()
        let endedChannels = ConnectionManager.shared.channelWillEndEvents()
        channelEndTask = Task { [weak self] in
            for await channel in endedChannels {
                guard let self else { return }
                if channel === inspectableApp.channel {
                    handleChannelDidEnd()
                    return
                }
            }
        }
    }

    private func handleChannelDidEnd() {
        let priorInfo = inspectableApp.appInfo
        lastKnownAppInfo = priorInfo
        let appName = (priorInfo?.appName).flatMap { $0.isEmpty ? nil : $0 }
            ?? NSLocalizedString("Inspected app", comment: "")
        connectionLossBannerMessage = String(
            format: NSLocalizedString("Connection to %@ lost. Trying to reconnect…", comment: ""),
            appName
        )
        attemptAutoReconnect()
    }

    private func attemptAutoReconnect() {
        guard lastKnownAppInfo != nil else { return }
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled, let self else { return }
                guard let newApp = await fetchInspectableAppMatchingLastKnown() else { continue }
                guard !Task.isCancelled else { return }
                adoptReconnectedApp(newApp)
                return
            }
        }
    }

    /// The hierarchy is not fetched again here; the next reload uses the
    /// new channel.
    private func adoptReconnectedApp(_ newApp: InspectableApp) {
        inspectableApp = newApp
        // The window controller and its async update manager hold the app
        // weakly and rely on this document to keep it alive; replacing it
        // here would leave them with nil, so they get the new app too.
        for case let windowController as StaticWindowController in windowControllers {
            windowController.inspectableApp = newApp
            windowController.asyncUpdateManager?.inspectableApp = newApp
        }
        connectionLossBannerMessage = nil
        reconnectTask = nil
        subscribeChannelLifecycle()
    }

    private func fetchInspectableAppMatchingLastKnown() async -> InspectableApp? {
        guard let targetInfo = lastKnownAppInfo else { return nil }
        let apps = await AppsManager.shared.fetchAppInfos(needImages: false, localInfos: nil)
        guard let match = apps.first(where: { targetInfo.isEqual(to: $0.appInfo) }) else {
            return nil
        }
        // Without images the response has no icon; keep the one we had.
        match.appInfo?.appIcon = targetInfo.appIcon
        return match
    }
}
