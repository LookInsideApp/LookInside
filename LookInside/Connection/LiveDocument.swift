//
//  LiveDocument.swift
//  LookInside
//
//  The document of one live inspection session against one inspectable
//  app over its channel. It is untitled, never autosaves, and Save As exports
//  the current hierarchy as a `.lookin` file. When the app's channel ends,
//  the document shows a banner and looks for the same app every 3 seconds;
//  when it reappears, the document watches its new channel. AppKit apps
//  refresh on reconnect. UIKit apps keep their tree when they return and
//  wait for a reload before switching to a new process.
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

    /// Explains why the app cannot be inspected yet, while it is in the
    /// background or while a new process is waiting for a hierarchy reload.
    @objc private(set) dynamic var applicationStatusBannerMessage: String?

    /// Only hierarchy reloads can use this app until the new tree arrives.
    /// Requests for objects in the old tree still use the disconnected app.
    private(set) var reconnectedAppAwaitingReload: InspectableApp?

    var connectedChannel: ServerChannel? {
        (reconnectedAppAwaitingReload ?? inspectableApp).channel
    }

    private var sessionState = LiveSessionState()

    /// The app info from before the channel ended, matched against the
    /// apps found while reconnecting.
    private var lastKnownAppInfo: InspectedAppInfo?
    /// The physical device the app ran on when its channel ended
    /// (`ConnectionManager.physicalDevice(of:)`): a reconnect takes over
    /// the same app on the same device only.
    private var lastKnownPhysicalDevice: String?
    private var channelEndTask: Task<Void, Never>?
    private var applicationStateTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var backgroundProbeTask: Task<Void, Never>?
    /// The refresh started after a Mac app reconnected, with its retries.
    private var automaticRefreshTask: Task<Void, Never>?

    private static let automaticRefreshRetryPolicy = AutomaticRefreshRetryPolicy()

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
        automaticRefreshTask?.cancel()
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
        automaticRefreshTask?.cancel()
        automaticRefreshTask = nil
        reconnectedAppAwaitingReload = nil
        super.close()
    }

    // MARK: - Channel lifecycle

    /// Watches the current app's channel for its end and for its Server's
    /// background reports; a reconnect calls this again for the new channel.
    /// The app holds its channel weakly, so the channel may already be gone,
    /// or ended, when this runs; that counts as an end, and the document
    /// reconnects.
    private func watchCurrentChannel(reloadHierarchyOnReconnect: Bool = false) {
        channelEndTask?.cancel()
        channelEndTask = nil
        applicationStateTask?.cancel()
        applicationStateTask = nil
        // A refresh still waiting to be retried was meant for the old one.
        automaticRefreshTask?.cancel()
        automaticRefreshTask = nil
        guard let channel = connectedChannel, channel.isConnected else {
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
        handle(.watchedChannel(isAlive: true, reloadHierarchyOnReconnect: reloadHierarchyOnReconnect))
    }

    /// Applies `event` to the session, shows its banner and carries out
    /// what it asks for.
    private func handle(_ event: LiveSessionState.Event) {
        let actions = sessionState.handle(event)
        updateBanners()
        #if DEBUG
            DebugE2EDump.recordSessionEvent(
                String(describing: event),
                banner: String(describing: sessionState.banner),
                actions: actions.map { String(describing: $0) },
                bundleIdentifier: (inspectableApp.appInfo ?? lastKnownAppInfo)?.appBundleIdentifier
            )
        #endif
        for action in actions {
            switch action {
            case .startReconnecting:
                reconnectedAppAwaitingReload = nil
                if let appInfo = inspectableApp.appInfo {
                    lastKnownAppInfo = appInfo
                }
                if let origin = inspectableApp.origin {
                    lastKnownPhysicalDevice = ConnectionManager.shared.physicalDevice(of: origin.kind)
                }
                automaticRefreshTask?.cancel()
                automaticRefreshTask = nil
                attemptAutoReconnect()
            case .reloadHierarchy:
                reloadHierarchyAfterReconnect()
            case let .startBackgroundProbe(interval):
                startBackgroundProbe(interval: interval)
            case .stopBackgroundProbe:
                backgroundProbeTask?.cancel()
                backgroundProbeTask = nil
            }
        }
    }

    private func updateBanners() {
        let appInfo = inspectableApp.appInfo ?? lastKnownAppInfo
        let appName = (appInfo?.appName).flatMap { $0.isEmpty ? nil : $0 }
            ?? NSLocalizedString("Inspected app", comment: "")
        let lossMessage: String?
        let applicationMessage: String?
        switch sessionState.banner {
        case .none:
            lossMessage = nil
            applicationMessage = reconnectedAppAwaitingReload.map { _ in
                String(format: NSLocalizedString("Connection to %@ restored. Reload to inspect the current hierarchy.", comment: "Banner when a reconnected app needs a manual hierarchy reload; %@ is the app's name"), appName)
            }
        case .connectionLost:
            lossMessage = String(format: NSLocalizedString("Connection to %@ lost. Trying to reconnect…", comment: ""), appName)
            applicationMessage = nil
        case .applicationInBackground:
            lossMessage = nil
            applicationMessage = String(
                format: NSLocalizedString("%@ is in the background.", comment: "Banner while the inspected app is in the background; %@ is the app's name"),
                appName
            )
        }
        // Only on change: KVO observers restart the banner's animation.
        if connectionLossBannerMessage != lossMessage {
            connectionLossBannerMessage = lossMessage
        }
        if applicationStatusBannerMessage != applicationMessage {
            applicationStatusBannerMessage = applicationMessage
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

    private func adoptReconnectedApp(_ newApp: InspectableApp) {
        let osDescription = newApp.appInfo?.osDescription?.lowercased() ?? ""
        let reloadAutomatically = osDescription.hasPrefix("macos") || osDescription.hasPrefix("os x")
            || (osDescription.isEmpty && newApp.appInfo?.deviceType == .mac)
        let treeProcessID = hierarchyDataSource?.rawHierarchyInfo?.appInfo?.appInfoIdentifier
            ?? inspectableApp.appInfo?.appInfoIdentifier ?? 0
        if reloadAutomatically || (treeProcessID != 0 && treeProcessID == newApp.appInfo?.appInfoIdentifier) {
            replaceApp(with: newApp)
        } else {
            reconnectedAppAwaitingReload = newApp
        }
        reconnectTask = nil
        watchCurrentChannel(reloadHierarchyOnReconnect: reloadAutomatically)
    }

    /// Makes `app` the one this document inspects: its window was just
    /// handed a hierarchy fetched from it, by the launch window, the
    /// window's app picker or the auto-connect, each with an
    /// `InspectableApp` a scan made. On another channel, that channel is
    /// watched from now on, and a reconnect still looking for the old app
    /// stops.
    func bind(to app: InspectableApp) {
        guard app !== inspectableApp else { return }
        let isOnAnotherChannel = app.channel !== connectedChannel
        reconnectedAppAwaitingReload = nil
        replaceApp(with: app)
        guard isOnAnotherChannel else {
            updateBanners()
            return
        }
        reconnectTask?.cancel()
        reconnectTask = nil
        watchCurrentChannel()
    }

    /// The window controller and its async update manager hold the app
    /// weakly and rely on this document to keep it alive; replacing it
    /// here alone would leave them with nil, so they get the new app too.
    private func replaceApp(with app: InspectableApp) {
        inspectableApp = app
        for case let windowController as StaticWindowController in windowControllers {
            windowController.inspectableApp = app
            windowController.asyncUpdateManager.inspectableApp = app
        }
    }

    private func fetchInspectableAppMatchingLastKnown() async -> InspectableApp? {
        guard let targetInfo = lastKnownAppInfo else { return nil }
        let apps = await AppsManager.shared.fetchAppInfos(needImages: false, localInfos: nil)
        let candidates = apps.map { app in
            ReconnectCandidate(
                identity: app.appInfo.map(Self.identity(of:)) ?? Self.unidentifiedApp,
                // An app listed without a channel (its Server is too old for
                // this Host, for one) cannot be inspected.
                canBeInspected: app.channel?.isConnected == true && app.serverVersionError == nil && app.appInfo != nil,
                physicalDevice: app.origin.map { ConnectionManager.shared.physicalDevice(of: $0.kind) }
            )
        }
        guard let index = ReconnectTargetSelection.candidateIndex(
            for: Self.identity(of: targetInfo),
            onPhysicalDevice: lastKnownPhysicalDevice,
            among: candidates
        ) else {
            return nil
        }
        let match = apps[index]
        // Without images the response has no icon; keep the one we had.
        match.appInfo?.appIcon = targetInfo.appIcon
        return match
    }

    private static func identity(of appInfo: InspectedAppInfo) -> InspectedAppIdentity {
        InspectedAppIdentity(
            appName: appInfo.appName,
            bundleIdentifier: appInfo.appBundleIdentifier,
            deviceDescription: appInfo.deviceDescription,
            deviceModelIdentifier: appInfo.deviceModelIdentifier,
            osDescription: appInfo.osDescription,
            deviceType: appInfo.deviceType.rawValue
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

    /// The refresh after an AppKit app reconnects. If the window refuses
    /// because a fetch or a detail sync is running, try again once it ends
    /// (`AutomaticRefreshRetryPolicy`); a refresh started meanwhile, a new
    /// channel and closing the document cancel the retries. Any other
    /// failure leaves the old tree: a refusal in the background shows its
    /// banner through the connection manager's report, and other errors are
    /// the ones a manual reload would show.
    private func reloadHierarchyAfterReconnect() {
        automaticRefreshTask?.cancel()
        automaticRefreshTask = Task { [weak self] in
            var retriesSoFar = 0
            while true {
                guard let outcome = await self?.attemptAutomaticRefresh(),
                      !Task.isCancelled,
                      let delay = Self.automaticRefreshRetryPolicy.delayBeforeRetry(after: outcome, retriesSoFar: retriesSoFar)
                else {
                    return
                }
                retriesSoFar += 1
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
            }
        }
    }

    /// One attempt of `reloadHierarchyAfterReconnect()`; nil without a window.
    private func attemptAutomaticRefresh() async -> AutomaticRefreshRetryPolicy.Outcome? {
        guard let staticWindowController else { return nil }
        do {
            _ = try await staticWindowController.reloadHierarchy(initiator: .host)
            return .succeeded
        } catch {
            let error = error as NSError
            typealias ReloadError = StaticWindowController.ReloadError
            if error.domain == ReloadError.domain,
               error.code == ReloadError.alreadyInProgress || error.code == ReloadError.detailSyncInProgress
            {
                #log(.debug, "LiveDocument - refresh after the app returned waits for a running fetch: \(error.localizedDescription, privacy: .public)")
                return .refusedWhileBusy
            }
            #log(.default, "LiveDocument - refresh after the app returned failed: \(error.localizedDescription, privacy: .public)")
            return .failed
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
                guard let channel = connectedChannel, channel.isConnected else { return }
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
