//
//  LiveDocument.swift
//  LookInside
//
//  The document of one live inspection session against one inspectable
//  app over its channel. It is untitled, never autosaves, and Save As exports
//  the current hierarchy as a `.lookin` file. When the app's channel ends,
//  the document shows a banner and looks for the same app every 3 seconds;
//  when it reappears, the document switches to its new channel and fetches
//  the hierarchy again. While the app is in the background the document
//  shows another banner and refreshes once the app is back.
//  `LiveSessionState` makes those decisions; this class carries them out.
//

import AppKit
import FoundationToolbox
import LookInsideHostCore

@Loggable(subsystem: "com.lookinside.app")
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

    /// Set while the app is in the background, which keeps it from
    /// answering; nil otherwise. Never set together with
    /// `connectionLossBannerMessage`. Observable with KVO; the window shows it
    /// as a banner.
    @objc private(set) dynamic var applicationInBackgroundBannerMessage: String?

    private var sessionState = LiveSessionState()

    /// The app info from before the channel ended, matched against the
    /// apps found while reconnecting.
    private var lastKnownAppInfo: InspectedAppInfo?
    private var channelEndTask: Task<Void, Never>?
    private var applicationStateTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var backgroundProbeTask: Task<Void, Never>?

    init(inspectableApp: InspectableApp) {
        self.inspectableApp = inspectableApp
        super.init()
        watchCurrentChannel()
    }

    /// A document can be freed without `close()` (for example when its
    /// window never opened). The tasks hold `self` weakly, so they would
    /// stay parked and the channel-end subscriber would stay registered;
    /// cancelling ends the stream, which unregisters it.
    deinit {
        channelEndTask?.cancel()
        applicationStateTask?.cancel()
        reconnectTask?.cancel()
        backgroundProbeTask?.cancel()
    }

    /// The live document whose window is `window`, or nil.
    static func document(in window: NSWindow?) -> LiveDocument? {
        guard let window else { return nil }
        return NSDocumentController.shared.document(for: window) as? LiveDocument
    }

    /// Nil before `makeWindowControllers()` ran.
    var staticWindowController: StaticWindowController? {
        windowControllers.first as? StaticWindowController
    }

    /// Nil before `makeWindowControllers()` ran.
    var hierarchyDataSource: StaticHierarchyDataSource? {
        staticWindowController?.hierarchyDataSource
    }

    /// Nil before `makeWindowControllers()` ran.
    var asyncUpdateManager: StaticAsyncUpdateManager? {
        staticWindowController?.asyncUpdateManager
    }

    // MARK: - NSDocument

    override var displayName: String? {
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

    /// The file cannot ask the app later: first fetch what the tree misses,
    /// then show the save panel.
    override func saveAs(_ sender: Any?) {
        guard let asyncUpdateManager else {
            super.saveAs(sender)
            return
        }
        asyncUpdateManager.fetchWholeTree {
            super.saveAs(sender)
        }
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
        applicationStateTask?.cancel()
        applicationStateTask = nil
        reconnectTask?.cancel()
        reconnectTask = nil
        backgroundProbeTask?.cancel()
        backgroundProbeTask = nil
        super.close()
    }

    // MARK: - Channel lifecycle

    /// Watches the current app's channel for its end and for its Server's
    /// background reports; a reconnect calls this again for the new channel.
    /// The app holds its channel weakly, so the channel may already be gone,
    /// or ended, when this runs; that counts as an end, and the document
    /// reconnects.
    private func watchCurrentChannel() {
        channelEndTask?.cancel()
        channelEndTask = nil
        applicationStateTask?.cancel()
        applicationStateTask = nil
        guard let channel = inspectableApp.channel, channel.isConnected else {
            handle(.watchedChannel(isAlive: false))
            return
        }
        let endedChannels = ConnectionManager.shared.channelWillEndEvents()
        channelEndTask = Task { [weak self, weak channel] in
            for await endedChannel in endedChannels where endedChannel === channel {
                self?.handle(.channelEnded)
                return
            }
        }
        let stateReports = ConnectionManager.shared.applicationStateEvents()
        applicationStateTask = Task { [weak self, weak channel] in
            for await report in stateReports where report.channel === channel {
                guard let self else { return }
                switch report.kind {
                case let .serverReported(isActive):
                    handle(.serverReportedApplicationState(isActive: isActive))
                case .requestRefusedInBackground:
                    handle(.requestRefusedInBackground)
                }
            }
        }
        handle(.watchedChannel(isAlive: true))
    }

    /// Applies `event` to the session, shows its banner and carries out
    /// what it asks for.
    private func handle(_ event: LiveSessionState.Event) {
        let actions = sessionState.handle(event)
        updateBanners()
        for action in actions {
            switch action {
            case .startReconnecting:
                if let appInfo = inspectableApp.appInfo {
                    lastKnownAppInfo = appInfo
                }
                attemptAutoReconnect()
            case .reloadHierarchy:
                reloadHierarchyAfterReturn()
            case let .startBackgroundProbe(interval):
                startBackgroundProbe(interval: interval)
            case .stopBackgroundProbe:
                backgroundProbeTask?.cancel()
                backgroundProbeTask = nil
            }
        }
    }

    private func updateBanners() {
        let info = inspectableApp.appInfo ?? lastKnownAppInfo
        let appName = (info?.appName).flatMap { $0.isEmpty ? nil : $0 }
            ?? NSLocalizedString("Inspected app", comment: "")
        let lossMessage: String?
        let backgroundMessage: String?
        switch sessionState.banner {
        case .none:
            lossMessage = nil
            backgroundMessage = nil
        case .connectionLost:
            lossMessage = String(format: NSLocalizedString("Connection to %@ lost. Trying to reconnect…", comment: ""), appName)
            backgroundMessage = nil
        case .applicationInBackground:
            lossMessage = nil
            backgroundMessage = String(
                format: NSLocalizedString("%@ is in the background. LookInside refreshes when it returns.", comment: "Banner over a live inspector window while the inspected app is in the background; %@ is the app's name"),
                appName
            )
        }
        // Only on change: KVO observers restart the banner's animation.
        if connectionLossBannerMessage != lossMessage {
            connectionLossBannerMessage = lossMessage
        }
        if applicationInBackgroundBannerMessage != backgroundMessage {
            applicationInBackgroundBannerMessage = backgroundMessage
        }
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

    /// Switches to the app found again; watching its channel fetches the
    /// hierarchy again (`LiveSessionState`), since the tree on screen belongs
    /// to the old process.
    private func adoptReconnectedApp(_ newApp: InspectableApp) {
        inspectableApp = newApp
        // The window controller and its async update manager hold the app
        // weakly and rely on this document to keep it alive; replacing it
        // here would leave them with nil, so they get the new app too.
        for case let windowController as StaticWindowController in windowControllers {
            windowController.inspectableApp = newApp
            windowController.asyncUpdateManager.inspectableApp = newApp
        }
        reconnectTask = nil
        watchCurrentChannel()
    }

    private func fetchInspectableAppMatchingLastKnown() async -> InspectableApp? {
        guard let targetInfo = lastKnownAppInfo else { return nil }
        let apps = await AppsManager.shared.fetchAppInfos(needImages: false, localInfos: nil)
        let candidates = apps.map { app in
            ReconnectCandidate(
                identity: app.appInfo.map(Self.identity(of:)) ?? Self.unidentifiedApp,
                // An app listed without a channel (its Server is too old for
                // this Host, for one) cannot be inspected.
                canBeInspected: app.channel?.isConnected == true && app.serverVersionError == nil && app.appInfo != nil
            )
        }
        guard let index = ReconnectTargetSelection.candidateIndex(for: Self.identity(of: targetInfo), among: candidates) else {
            return nil
        }
        let match = apps[index]
        // Without images the response has no icon; keep the one we had.
        match.appInfo?.appIcon = targetInfo.appIcon
        return match
    }

    private static func identity(of info: InspectedAppInfo) -> InspectedAppIdentity {
        InspectedAppIdentity(
            appName: info.appName,
            bundleIdentifier: info.appBundleIdentifier,
            deviceDescription: info.deviceDescription,
            deviceModelIdentifier: info.deviceModelIdentifier,
            osDescription: info.osDescription,
            deviceType: info.deviceType.rawValue
        )
    }

    /// An app that sent no app info; it matches nothing.
    private static let unidentifiedApp = InspectedAppIdentity(
        appName: nil,
        bundleIdentifier: nil,
        deviceDescription: nil,
        deviceModelIdentifier: nil,
        osDescription: nil,
        deviceType: -1
    )

    /// The refresh after a reconnect or after the app came back from the
    /// background. A failure leaves the old tree: a refusal in the background
    /// shows its banner through the connection manager's report, and other
    /// errors are the ones a manual reload would show.
    private func reloadHierarchyAfterReturn() {
        guard let staticWindowController else { return }
        Task {
            do {
                _ = try await staticWindowController.reloadHierarchy(initiator: .host)
            } catch {
                #log(.default, "LiveDocument - refresh after the app returned failed: \((error as NSError).localizedDescription, privacy: .public)")
            }
        }
    }

    /// Pings the app every `interval` while it is in the background. Ends
    /// on its own once a ping is answered from the foreground; a ping that
    /// times out on a silent channel closes it (`ChannelLivenessPolicy`),
    /// which ends the channel and so this probe.
    private func startBackgroundProbe(interval: Duration) {
        backgroundProbeTask?.cancel()
        backgroundProbeTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled, let self else { return }
                guard let channel = inspectableApp.channel, channel.isConnected else { return }
                do {
                    try await ConnectionManager.shared.ping(channel: channel)
                } catch {
                    continue
                }
                guard !Task.isCancelled else { return }
                backgroundProbeTask = nil
                handle(.backgroundProbeAnswered)
                return
            }
        }
    }
}
