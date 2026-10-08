//
//  StaticWindowController.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/4.
//  https://lookin.work
//
//  The window of a live document: hierarchy, preview and dashboard of one
//  inspected app, with the inspector toolbar. Owns the document's hierarchy
//  data source and async update manager; every request goes to the app the
//  owning LiveDocument injects (`inspectableApp`).
//

import AppKit
import LookInsideHostCore
import UniformTypeIdentifiers

@objc(LKStaticWindowController)
@MainActor
final class StaticWindowController: WindowController, NSToolbarDelegate, @preconcurrency StaticAsyncUpdateManagerDelegate {
    /// Who asked for a hierarchy reload. Recorded when a reload actually
    /// starts, so an observer of the data source's `didReloadHierarchyInfo`
    /// can attribute the reload it just saw. Reloads cannot overlap, so the
    /// value only changes between them.
    enum ReloadInitiator {
        /// A person acted in the inspector, or the Host decided to reload.
        case host
        /// A client of the local bridge socket asked for it
        /// (`hierarchy.refresh`); clients use this to ignore their own echo.
        case agent
    }

    /// The refusals and failures of `reloadHierarchy(completion:)` that this
    /// window raises itself. Errors from the request keep their
    /// `LookinErrorDomain` code.
    enum ReloadError {
        static let domain = "LKStaticWindowControllerReloadErrorDomain"

        /// A hierarchy fetch is already in flight on this window.
        static let alreadyInProgress = 1
        /// The async detail sync is running. Reloading now would throw away
        /// work already paid for, so the caller has to stop it first.
        static let detailSyncInProgress = 2
        /// No inspectable app is bound to this window.
        static let noInspectableApp = 3
        /// The window went away while the fetch was in flight, leaving no
        /// data source to absorb the result.
        static let windowClosed = 4
        /// The request ended without a hierarchy and without an error --
        /// reachable when the connection channel tears down mid-request.
        static let noResponse = 5

        static func make(_ code: Int, _ description: String) -> NSError {
            NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
        }
    }

    /// What one hierarchy request sent first.
    private enum HierarchyFetchResult {
        /// Its first value; nil when that value is not a hierarchy.
        case info(HierarchyInfo?)
        /// It ended without sending a value.
        case noResponse
    }

    /// Implicitly unwrapped for the Swift callers written against the
    /// Objective-C header; set before init returns.
    @objc private(set) var viewController: StaticViewController!

    /// Per-window hierarchy data source.
    @objc private(set) var hierarchyDataSource: StaticHierarchyDataSource!

    /// Per-window async update manager.
    @objc private(set) var asyncUpdateManager: StaticAsyncUpdateManager!

    /// Injected by the owning LiveDocument, which also swaps it when
    /// the app reconnects; every request uses it.
    @objc dynamic weak var inspectableApp: InspectableApp? {
        didSet {
            updateAppButton()
        }
    }

    /// Who asked for the most recent reload that actually started.
    private(set) var lastReloadInitiator: ReloadInitiator = .host

    private var toolbarItemsMap: [NSToolbarItem.Identifier: NSToolbarItem] = [:]
    private var gestureDebugWindowController: GestureDebugWindowController?
    /// The reload item as it was when the window was set up; the fetching
    /// state enables and disables this one.
    private var fetchingStateReloadItem: NSToolbarItem?
    private var observations: [NSKeyValueObservation] = []

    /// True while the hierarchy and its screenshots are being fetched.
    private var isFetchingHierarchy = false {
        didSet {
            guard oldValue != isFetchingHierarchy else { return }
            updateToolbarForFetchingState()
        }
    }

    private var isFetchingDetails = false {
        didSet {
            guard oldValue != isFetchingDetails else { return }
            updateToolbarForFetchingState()
        }
    }

    // MARK: - Init

    /// Used by LiveDocument: the window, data source and update
    /// manager, all bound to `app`.
    @objc(initWithInspectableApp:)
    init(inspectableApp app: InspectableApp?) {
        let screenSize = NSScreen.main?.frame.size ?? .zero
        let window = AppWindow(
            contentRect: NSRect(x: 0, y: 0, width: screenSize.width * 0.7, height: screenSize.height * 0.7),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.tabbingMode = .disallowed
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
        window.minSize = NSSize(width: HierarchyMinWidth + DashboardViewWidth + 200, height: 500)
        window.center()
        window.setFrameUsingName(windowSizeNameStatic)

        super.init(window: window)

        // Saves this window's frame across launches.
        windowFrameAutosaveName = windowSizeNameStatic

        let dataSource = StaticHierarchyDataSource()
        let updateManager = StaticAsyncUpdateManager(hierarchyDataSource: dataSource, inspectableApp: nil)
        dataSource.asyncUpdateManager = updateManager
        hierarchyDataSource = dataSource
        asyncUpdateManager = updateManager

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwiftUIModeDidChange(_:)),
            name: .swiftUIHierarchyDisplayModeDidChange,
            object: nil
        )

        // Flipping the backing-layer toggle changes the node set itself, so
        // it always goes through a full server-side reload.
        PreferenceManager.shared.showBackingLayers.subscribe(
            self,
            action: #selector(handleShowBackingLayersDidChange(_:)),
            relatedObject: nil
        )

        // The view controller builds its view inside its initializer, so the
        // data source and update manager go in up front.
        let viewController = StaticViewController(hierarchyDataSource: dataSource, asyncUpdateManager: updateManager)
        self.viewController = viewController
        window.contentView = viewController.view
        contentViewController = viewController

        let toolbar = NSToolbar()
        toolbar.displayMode = .iconAndLabel
        toolbar.sizeMode = .regular
        toolbar.delegate = self
        window.toolbar = toolbar

        fetchingStateReloadItem = toolbarItemsMap[NSToolbarItem.Identifier(toolbarIdentifierReload)]
        updateManager.delegate = self
        updateToolbarForFetchingState()

        observations.append(dataSource.observe(\.selectedItem, options: [.initial, .new]) { [weak self] dataSource, _ in
            MainActor.assumeIsolated {
                let measureButton = self?.toolbarItemsMap[NSToolbarItem.Identifier(toolbarIdentifierMeasure)]?.view as? NSButton
                measureButton?.isEnabled = dataSource.selectedItem != nil
            }
        })

        DispatchQueue.main.async {
            self.autoConnectAppIfRequested()
        }

        // Every request (reload, modify…) goes to this app's channel.
        inspectableApp = app
        updateManager.inspectableApp = app
        updateAppButton()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func updateToolbarForFetchingState() {
        let isFetching = isFetchingHierarchy || isFetchingDetails
        for identifier in [NSToolbarItem.Identifier(toolbarIdentifierApp), NSToolbarItem.Identifier(toolbarIdentifierConsole), NSToolbarItem.Identifier(toolbarIdentifierFastMode)] {
            toolbarItemsMap[identifier]?.isEnabled = !isFetching
        }
        fetchingStateReloadItem?.isEnabled = !isFetchingHierarchy
    }

    private func updateAppButton() {
        let appButton = toolbarItemsMap[NSToolbarItem.Identifier(toolbarIdentifierApp)]?.view as? WindowToolbarAppButton
        appButton?.appInfo = inspectableApp?.appInfo
    }

    // MARK: - Fetching

    /// Sends a hierarchy request to `app` and returns what it sent first.
    private static func fetchHierarchy(from app: InspectableApp) async throws -> HierarchyFetchResult {
        let responses = app.responses(
            type: UInt32(LookinRequestTypeHierarchy),
            data: InspectableApp.hierarchyRequestParameters()
        )
        for try await value in responses {
            return .info(value as? HierarchyInfo)
        }
        return .noResponse
    }

    private func alertError(_ error: Error?, in window: NSWindow?) {
        let error = (error as NSError?) ?? ConnectionError.inner
        guard error.code != LookinErrCode_Discard, let window else {
            return
        }
        NSAlert(error: error).beginSheetModal(for: window, completionHandler: nil)
    }

    /// For the end-to-end runs: connects to the app named by
    /// `LOOKINSIDE_AUTO_CONNECT_BUNDLE_ID`, or with
    /// `LOOKINSIDE_AUTO_CONNECT_FIRST` to the first compatible app.
    private func autoConnectAppIfRequested() {
        let environment = ProcessInfo.processInfo.environment
        let targetBundleID = environment["LOOKINSIDE_AUTO_CONNECT_BUNDLE_ID"] ?? ""
        let shouldConnectFirst = ((environment["LOOKINSIDE_AUTO_CONNECT_FIRST"] ?? "") as NSString).boolValue
        guard !targetBundleID.isEmpty || shouldConnectFirst else {
            return
        }

        viewController.progressView.animate(toProgress: InitialIndicatorProgressWhenFetchHierarchy)

        Task { [weak self] in
            let apps = await AppsManager.shared.fetchAppInfos(needImages: true, localInfos: nil)
            guard let self else { return }
            let targetApp: InspectableApp?
            if !targetBundleID.isEmpty {
                targetApp = apps.first { $0.appInfo?.appBundleIdentifier == targetBundleID }
            } else {
                targetApp = apps.first { $0.serverVersionError == nil && $0.appInfo != nil }
            }
            guard let targetApp else {
                viewController.progressView.resetToZero()
                return
            }

            let currentInfo = inspectableApp?.appInfo
            let isTheSameApp = currentInfo.map { $0.isEqual(targetApp.appInfo) } ?? false
            do {
                if case let .info(info) = try await Self.fetchHierarchy(from: targetApp) {
                    applyHierarchyInfo(info, for: targetApp, keepState: isTheSameApp)
                }
            } catch {
                viewController.progressView.resetToZero()
                alertError(error, in: window)
            }
        }
    }

    @objc(popupAllInspectableAppsWithSource:)
    func popupAllInspectableApps(with source: MenuPopoverAppsListControllerEventSource) {
        let appItemView = toolbarItemsMap[NSToolbarItem.Identifier(toolbarIdentifierApp)]?.view

        Task { [weak self] in
            let apps = await AppsManager.shared.fetchAppInfos(needImages: true, localInfos: nil)
            guard let self else { return }
            let listController = MenuPopoverAppsListController(apps: apps, source: source)
            let popover = NSPopover()
            listController.didSelectApp = { [weak self, weak popover] app in
                popover?.close()
                guard let self else { return }
                didSelectAppInPicker(app)
            }
            popover.behavior = .transient
            popover.animates = false
            popover.contentSize = listController.bestSize()
            popover.contentViewController = listController
            guard let appItemView else { return }
            popover.show(relativeTo: appItemView.bounds, of: appItemView, preferredEdge: .maxY)
        }
    }

    private func didSelectAppInPicker(_ app: InspectableApp) {
        if let versionError = app.serverVersionError {
            if versionError.code == LookinErrCode_ServerVersionTooLow {
                AppHelper.openLookinWebsite(withPath: "faq/server-version-too-low/")
            } else {
                AppHelper.openLookinWebsite(withPath: "faq/server-version-too-high/")
            }
            return
        }

        // A different app opens in a new window rather than swapping this
        // window's target; LiveDocumentController brings forward a
        // window already open on the same channel.
        let currentInfo = inspectableApp?.appInfo
        let isTheSameApp = currentInfo.map { $0.isEqual(app.appInfo) } ?? false

        guard isTheSameApp else {
            // The new window shows its own progress while the tree streams
            // in, and errors (including the hierarchy timeout) go to that
            // window, so this window's session is never disturbed. A picker
            // click always means "inspect now", so the hierarchy is fetched
            // even when the document was already open.
            let (document, alreadyOpen) = LiveDocumentController.shared.openLiveDocument(for: app)
            guard let targetController = document.windowControllers.first as? StaticWindowController else {
                return
            }
            targetController.viewController.progressView.animate(toProgress: InitialIndicatorProgressWhenFetchHierarchy)
            Task {
                do {
                    guard case let .info(info) = try await Self.fetchHierarchy(from: app) else {
                        return
                    }
                    guard let info else {
                        targetController.viewController.progressView.resetToZero()
                        targetController.alertError(ConnectionError.inner, in: targetController.window)
                        return
                    }
                    targetController.applyHierarchyInfo(info, for: app, keepState: alreadyOpen)
                } catch {
                    targetController.viewController.progressView.resetToZero()
                    targetController.alertError(error, in: targetController.window)
                }
            }
            return
        }

        // The same app: reload in place, as before.
        viewController.progressView.animate(toProgress: InitialIndicatorProgressWhenFetchHierarchy)
        Task {
            do {
                if case let .info(info) = try await Self.fetchHierarchy(from: app) {
                    applyHierarchyInfo(info, for: app, keepState: true)
                }
            } catch {
                alertError(error, in: window)
                viewController.progressView.resetToZero()
            }
        }
    }

    /// Reloads this window's hierarchy: re-entrancy gate, progress
    /// indicator, `keepState: true` hand-off to the data source. Error
    /// sheets stay with the callers, so the show-backing-layers switch can
    /// reload without one.
    ///
    /// The request starts before this returns. `completion` gets the
    /// reloaded hierarchy (after the data source took it), or an error in
    /// the reload domain (this window refused to start or lost the result)
    /// or `LookinErrorDomain` (the app failed the request); a refusal is
    /// reported before this returns.
    private func reloadHierarchy(
        initiator: ReloadInitiator = .host,
        completion: @escaping (Result<HierarchyInfo?, NSError>) -> Void
    ) {
        if isFetchingHierarchy {
            completion(.failure(ReloadError.make(
                ReloadError.alreadyInProgress,
                NSLocalizedString("A hierarchy reload is already running for this window.", comment: "")
            )))
            return
        }
        if isFetchingDetails {
            completion(.failure(ReloadError.make(
                ReloadError.detailSyncInProgress,
                NSLocalizedString("Detail synchronization is still running. Wait for it to finish before reloading.", comment: "")
            )))
            return
        }
        guard let app = inspectableApp else {
            completion(.failure(ReloadError.make(
                ReloadError.noInspectableApp,
                NSLocalizedString("This window is not attached to an app.", comment: "")
            )))
            return
        }

        // Recorded only once the reload starts, so a refused request never
        // relabels the reload that refused it.
        lastReloadInitiator = initiator
        isFetchingHierarchy = true
        viewController.progressView.animate(toProgress: InitialIndicatorProgressWhenFetchHierarchy)
        PerformanceReporter.sharedInstance().willStartReload()

        Task { [weak self] in
            let result: HierarchyFetchResult
            do {
                result = try await Self.fetchHierarchy(from: app)
            } catch {
                self?.viewController.progressView.resetToZero()
                self?.isFetchingHierarchy = false
                completion(.failure(error as NSError))
                return
            }
            guard let self else {
                // No data source left to hand the hierarchy to. Reporting
                // success would tell the caller the Host holds this tree
                // when nothing does.
                completion(.failure(ReloadError.make(
                    ReloadError.windowClosed,
                    NSLocalizedString("The inspector window closed while the hierarchy was being fetched.", comment: "")
                )))
                return
            }
            switch result {
            case let .info(info):
                viewController.progressView.finish(completion: nil)
                hierarchyDataSource.reload(with: info, keepState: true)
                isFetchingHierarchy = false
                PerformanceReporter.sharedInstance().didFetchHierarchy()
                completion(.success(info))
            case .noResponse:
                // Left unhandled this would strand every party: the reload
                // button stays disabled and the caller never hears back.
                viewController.progressView.resetToZero()
                isFetchingHierarchy = false
                completion(.failure(ReloadError.make(
                    ReloadError.noResponse,
                    NSLocalizedString("The app finished the hierarchy request without returning a hierarchy.", comment: "")
                )))
            }
        }
    }

    /// `reloadHierarchy(completion:)` for callers outside the UI: no error
    /// sheet, and the error is thrown instead.
    func reloadHierarchy(initiator: ReloadInitiator) async throws -> HierarchyInfo? {
        try await withCheckedThrowingContinuation { continuation in
            reloadHierarchy(initiator: initiator) { result in
                continuation.resume(with: result)
            }
        }
    }

    // MARK: - NSToolbarDelegate

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        var identifiers: [NSToolbarItem.Identifier] = [
            NSToolbarItem.Identifier(toolbarIdentifierReload), NSToolbarItem.Identifier(toolbarIdentifierFastMode), NSToolbarItem.Identifier(toolbarIdentifierApp), NSToolbarItem.Identifier(toolbarIdentifierSwiftUIMode),
            NSToolbarItem.Identifier(toolbarIdentifierGestureDebug),
            .flexibleSpace,
            NSToolbarItem.Identifier(toolbarIdentifierDimension), NSToolbarItem.Identifier(toolbarIdentifierRotation), NSToolbarItem.Identifier(toolbarIdentifierSetting),
            .flexibleSpace,
            NSToolbarItem.Identifier(toolbarIdentifierScale),
            .flexibleSpace,
            NSToolbarItem.Identifier(toolbarIdentifierMeasure), NSToolbarItem.Identifier(toolbarIdentifierConsole),
        ]
        if !MessageManager.sharedInstance().queryMessages().isEmpty {
            identifiers.append(NSToolbarItem.Identifier(toolbarIdentifierMessage))
        }
        return identifiers
    }

    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool
    ) -> NSToolbarItem? {
        if let item = toolbarItemsMap[itemIdentifier] {
            return item
        }
        guard let item = WindowToolbarHelper.shared.makeToolBarItem(
            identifier: itemIdentifier.rawValue,
            preferenceManager: PreferenceManager.shared
        ) else {
            return nil
        }
        toolbarItemsMap[itemIdentifier] = item

        switch item.itemIdentifier {
        case NSToolbarItem.Identifier(toolbarIdentifierReload):
            item.target = self
            item.action = #selector(handleReload)
        case NSToolbarItem.Identifier(toolbarIdentifierGestureDebug):
            item.target = self
            item.action = #selector(handleGestureDebug)
        case NSToolbarItem.Identifier(toolbarIdentifierApp):
            item.target = self
            item.action = #selector(handleApp)
            // Shows the bound app's icon; `inspectableApp` updates it when
            // LiveDocument swaps in the reconnected app.
            updateAppButton()
        case NSToolbarItem.Identifier(toolbarIdentifierRotation):
            item.target = self
            item.action = #selector(handleFreeRotation)
        case NSToolbarItem.Identifier(toolbarIdentifierSetting):
            item.label = NSLocalizedString("View", comment: "")
            item.target = self
            item.action = #selector(handleSetting(_:))
        case NSToolbarItem.Identifier(toolbarIdentifierConsole):
            item.target = self
            item.action = #selector(handleConsole)
            observations.append(viewController.observe(\.showConsole, options: [.old, .new]) { [weak item] _, change in
                guard let showConsole = change.newValue, change.oldValue != showConsole else { return }
                MainActor.assumeIsolated {
                    (item?.view as? NSButton)?.state = showConsole ? .on : .off
                }
            })
        case NSToolbarItem.Identifier(toolbarIdentifierMessage):
            item.label = NSLocalizedString("Notifications", comment: "")
            item.target = self
            item.action = #selector(handleMessage(_:))
        case NSToolbarItem.Identifier(toolbarIdentifierFastMode):
            item.target = self
            item.action = #selector(handleFastMode)
        default:
            break
        }
        return item
    }

    // MARK: - Toolbar actions

    @objc(_handleReload)
    private func handleReload() {
        // The button does two things the reload itself does not: while
        // details sync it is a stop button, and with no app bound it opens
        // the app picker. Only a click gets those; other callers get errors.
        if isFetchingDetails {
            // 停止拉取
            asyncUpdateManager.endUpdating()
            return
        }
        guard inspectableApp != nil else {
            popupAllInspectableApps(with: .reloadButton)
            return
        }
        if isFetchingHierarchy {
            return
        }
        reloadHierarchy { [weak self] result in
            guard let self, case let .failure(error) = result, let window else { return }
            NSAlert(error: error).beginSheetModal(for: window, completionHandler: nil)
        }
    }

    @objc(_handleShowBackingLayersDidChange:)
    private func handleShowBackingLayersDidChange(_: MessageActionParameters) {
        // No app bound or a reload already running: the new value still
        // applies on the next manual reload, so refusals stay quiet.
        reloadHierarchy { _ in }
    }

    @objc(_handleApp)
    private func handleApp() {
        popupAllInspectableApps(with: .appButton)
    }

    @objc(_handleSetting:)
    private func handleSetting(_ button: NSButton) {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = false
        popover.contentSize = NSSize(width: AppHelper.isEnglish() ? 270 : 350, height: 260)
        popover.contentViewController = MenuPopoverSettingController(
            preferenceManager: PreferenceManager.shared,
            isMacTarget: AppHelper.appInfoLooksLikeMacTarget(inspectableApp?.appInfo)
        )
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
    }

    @objc(_handleGestureDebug)
    private func handleGestureDebug() {
        let controller = gestureDebugWindowController ?? GestureDebugWindowController(owner: self)
        gestureDebugWindowController = controller
        controller.showWindow(self)
        controller.window?.makeKeyAndOrderFront(self)
    }

    @objc(_handleConsole)
    private func handleConsole() {
        viewController.showConsole.toggle()
    }

    @objc func handleFastMode() {
        let fastMode = PreferenceManager.shared.fastMode
        fastMode.setBOOLValue(!fastMode.currentBOOLValue, ignoreSubscriber: nil)
    }

    @objc(_handleMessage:)
    private func handleMessage(_ button: NSButton) {
        let menu = NSMenu()
        for message in MessageManager.sharedInstance().queryMessages() {
            if message == jobsMessageIdentifier {
                let item = NSMenuItem()
                item.image = NSImage(named: "Icon_Inspiration_small")
                item.title = NSLocalizedString("Job openings…(China)", comment: "")
                item.target = self
                item.action = #selector(handleJobsMenuItem)
                menu.addItem(item)
                menu.addItem(.separator())
            } else if message == swiftSubspecMessageIdentifier {
                let tipItem = NSMenuItem()
                tipItem.image = NSImage(named: "Icon_Inspiration_small")
                tipItem.title = NSLocalizedString("Your iOS project seems to use Swift, but you haven't turn on Swift optimization for LookInside", comment: "")
                menu.addItem(tipItem)

                let linkItem = NSMenuItem()
                linkItem.image = NSImage(size: NSSize(width: 18, height: 1))
                linkItem.title = NSLocalizedString("How to turn on…", comment: "")
                linkItem.target = self
                linkItem.action = #selector(handleTurnOnSwift)
                menu.addItem(linkItem)
                menu.addItem(.separator())
            }
        }

        if menu.numberOfItems == 0 {
            let item = NSMenuItem()
            item.title = NSLocalizedString("No message", comment: "")
            menu.addItem(item)
        }

        guard let event = NSApplication.shared.currentEvent else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: button)
    }

    @objc(_handleFreeRotation)
    private func handleFreeRotation() {
        let freeRotation = PreferenceManager.shared.freeRotation
        freeRotation.setBOOLValue(!freeRotation.currentBOOLValue, ignoreSubscriber: nil)
    }

    @objc func handleJobsMenuItem() {
        AppHelper.showDisabledExternalLinkAlert(withMessage: NSLocalizedString("This upstream community link is not available in this build.", comment: ""))
        MessageManager.sharedInstance().removeMessage(jobsMessageIdentifier)
    }

    @objc func handleTurnOnSwift() {
        AppHelper.showDisabledExternalLinkAlert(withMessage: NSLocalizedString("Legacy Swift integration guides are disabled in this community build. See the repository README instead.", comment: ""))
    }

    // MARK: - AppMenuManagerDelegate

    @objc func appMenuManagerDidSelectReload() {
        if isFetchingHierarchy {
            return
        }
        if isFetchingDetails {
            let error = NSError(domain: LookinErrorDomain, code: LookinErrCode_Default, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("Cannot reload at this time", comment: ""),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please wait until current sync is completed. You can get sync progress in the upper-left corner of this window.", comment: ""),
            ])
            if let window {
                NSAlert(error: error).beginSheetModal(for: window, completionHandler: nil)
            }
            return
        }
        handleReload()
    }

    @objc func appMenuManagerDidSelectDimension() {
        let dimension = PreferenceManager.shared.previewDimension
        let dimension2D = Int(PreviewDimension.dimension2D.rawValue)
        let dimension3D = Int(PreviewDimension.dimension3D.rawValue)
        dimension.setIntegerValue(dimension.currentIntegerValue == dimension2D ? dimension3D : dimension2D, ignoreSubscriber: nil)
    }

    @objc func appMenuManagerDidSelectZoomIn() {
        adjustPreviewScale(by: 0.1)
    }

    @objc func appMenuManagerDidSelectZoomOut() {
        adjustPreviewScale(by: -0.1)
    }

    private func adjustPreviewScale(by delta: Double) {
        let scale = PreferenceManager.shared.previewScale
        let target = min(max(scale.currentDoubleValue + delta, Double(previewMinScale)), Double(previewMaxScale))
        scale.setDoubleValue(target, ignoreSubscriber: nil)
    }

    @objc func appMenuManagerDidSelectDecreaseInterspace() {
        adjustZInterspace(by: -0.1)
    }

    @objc func appMenuManagerDidSelectIncreaseInterspace() {
        adjustZInterspace(by: 0.1)
    }

    private func adjustZInterspace(by delta: Double) {
        let interspace = PreferenceManager.shared.zInterspace
        let target = min(max(interspace.currentDoubleValue + delta, Double(previewMinZInterspace)), Double(previewMaxZInterspace))
        interspace.setDoubleValue(target, ignoreSubscriber: nil)
    }

    @objc func appMenuManagerDidSelectExpansionIndex(_ index: UInt) {
        hierarchyDataSource.adjustExpansion(by: Int(index), referenceDict: nil, selectedItem: nil)
        hierarchyDataSource.persistExpansionStateToPreferences()
    }

    @objc func appMenuManagerDidSelectExport() {
        guard let hierarchyInfo = hierarchyDataSource.rawHierarchyInfo else {
            return
        }
        var fileName: NSString?
        var exportedData: Data?

        let accessoryView = ExportAccessoryView()
        // The data is rebuilt whenever the accessory view changes the
        // compression, for as long as the panel is up.
        let compressionObservation = PreferenceManager.shared.observe(\.preferredExportCompression, options: [.initial, .new]) { manager, _ in
            MainActor.assumeIsolated {
                exportedData = ExportManager.sharedInstance().data(
                    from: hierarchyInfo,
                    imageCompression: manager.preferredExportCompression,
                    fileName: &fileName
                )
                accessoryView.dataSize = UInt(exportedData?.count ?? 0)
            }
        }

        // Manual frame layout: the panel cannot size the view itself.
        accessoryView.setFrameSize(accessoryView.sizeThatFits(NSSize(width: CGFloat.greatestFiniteMagnitude,
                                                                     height: CGFloat.greatestFiniteMagnitude)))

        let panel = NSSavePanel()
        panel.accessoryView = accessoryView
        panel.nameFieldStringValue = (fileName as String?) ?? ""
        panel.allowsOtherFileTypes = false
        panel.allowedContentTypes = [UTType("com.lookin.lookin") ?? .data]
        panel.isExtensionHidden = true
        panel.canCreateDirectories = true
        guard let window else { return }
        panel.beginSheetModal(for: window) { response in
            compressionObservation.invalidate()
            guard response == .OK, let url = panel.url else { return }
            guard let exportedData else {
                assertionFailure("LookinClient - write fail, no data")
                return
            }
            do {
                try exportedData.write(to: url)
            } catch {
                NSLog("LookinClient - write fail:%@", error as NSError)
            }
        }
    }

    @objc func appMenuManagerDidSelectOpenInNewWindow() {
        let newHierarchyInfo = hierarchyDataSource.rawHierarchyInfo?.copy() as? HierarchyInfo
        let file = HierarchyFile()
        file.serverVersion = newHierarchyInfo?.serverVersion ?? 0
        file.hierarchyInfo = newHierarchyInfo
        NavigationManager.shared.showReader(with: file, title: nil)
    }

    @objc func appMenuManagerDidSelectFilter() {
        viewController.currentHierarchyView()?.activateSearchBar()
    }

    // MARK: - StaticAsyncUpdateManagerDelegate

    func detailUpdateTasksTotalCount(_ totalCount: UInt, finishedCount: UInt) {
        let reloadItem = toolbarItemsMap[NSToolbarItem.Identifier(toolbarIdentifierReload)]
        let reloadButton = reloadItem?.view as? NSButton

        if totalCount > finishedCount {
            if !isFetchingDetails {
                // 进入 fetch 状态
                isFetchingDetails = true
                let image = NSImage(named: "icon_stop")
                image?.isTemplate = true
                reloadButton?.image = image
            }
            reloadItem?.label = "\(finishedCount) / \(totalCount)"
        } else if isFetchingDetails {
            // 退出 fetch 状态
            isFetchingDetails = false
            reloadItem?.label = NSLocalizedString("Reload", comment: "")
            let image = NSImage(named: "icon_reload")
            image?.isTemplate = true
            reloadButton?.image = image
        }
    }

    func detailUpdateReceivedError(_ error: Error) {
        alertError(error, in: window)
    }

    // MARK: - Hierarchy reloads

    /// Binds `app` to this window and loads `info`. Every same-window
    /// reload (auto-connect, toolbar same app, SwiftUI mode) goes through
    /// here.
    private func applyHierarchyInfo(_ info: HierarchyInfo?, for app: InspectableApp, keepState: Bool) {
        viewController.progressView.finish(completion: nil)
        inspectableApp = app
        asyncUpdateManager.inspectableApp = app
        hierarchyDataSource.reload(with: info, keepState: keepState)

        // Move this bundle id to the front of the expansion-state LRU, so
        // inspected apps aren't evicted just because nothing was toggled yet.
        PreferenceManager.shared.bumpExpansionStateBundleIdentifierToMostRecent(info?.appInfo?.appBundleIdentifier)
    }

    @objc(_handleSwiftUIModeDidChange:)
    private func handleSwiftUIModeDidChange(_: Notification) {
        guard let app = inspectableApp else {
            return
        }

        // Remember the selection, to restore (or migrate) it after the reload.
        let priorSwiftUIID = hierarchyDataSource.selectedItem?.customInfo?.swiftUIDisplayItemID
        let priorWasSwiftUI = SwiftUISelectionMigration.isSwiftUIID(priorSwiftUIID)

        app.cancelHierarchyDetailFetching()
        viewController.progressView.animate(toProgress: InitialIndicatorProgressWhenFetchHierarchy)
        Task { [weak self] in
            do {
                let result = try await Self.fetchHierarchy(from: app)
                guard let self, case let .info(info) = result else { return }
                // The mode toggle keeps the target app, so keepState keeps
                // expansion and scroll where possible.
                applyHierarchyInfo(info, for: app, keepState: true)
                if priorWasSwiftUI, let priorSwiftUIID {
                    restoreSwiftUISelection(priorIdentifier: priorSwiftUIID)
                }
            } catch {
                guard let self else { return }
                viewController.progressView.resetToZero()
                alertError(error, in: window)
            }
        }
    }

    private func restoreSwiftUISelection(priorIdentifier: String) {
        let flatItems = hierarchyDataSource.displayingFlatItems ?? []
        let identifiers = flatItems.map { $0.customInfo?.swiftUIDisplayItemID }
        switch SwiftUISelectionMigration.target(priorIdentifier: priorIdentifier, in: identifiers) {
        case let .exact(index):
            hierarchyDataSource.selectedItem = flatItems[index]
        case let .migrated(index):
            hierarchyDataSource.selectedItem = flatItems[index]
            showSelectionMigratedToast(for: flatItems[index])
        case .none:
            break
        }
    }

    /// A transient toast that fades out after 2 seconds. Not an alert
    /// sheet: a modal sheet would block switching the segmented control
    /// again until dismissed.
    private func showSelectionMigratedToast(for item: DisplayItem) {
        let typeName = item.customInfo?.title ?? NSLocalizedString("SwiftUI item", comment: "Fallback name of a SwiftUI node in the selection-moved toast")
        let message = String(
            format: NSLocalizedString(
                "Selection moved to %@ (modifiers folded in compact mode).",
                comment: "hierarchy.swiftui.selection.migrated.body"
            ),
            typeName
        )

        guard let host = viewController.view as NSView? else { return }
        let toast = NSTextField(labelWithString: message)
        toast.font = .systemFont(ofSize: 12, weight: .medium)
        toast.textColor = .white
        toast.alignment = .center
        toast.lineBreakMode = .byTruncatingTail
        toast.wantsLayer = true
        toast.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.78).cgColor
        toast.layer?.cornerRadius = 6
        toast.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -32),
            toast.widthAnchor.constraint(lessThanOrEqualTo: host.widthAnchor, multiplier: 0.7),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),
        ])
        // After 2 seconds, fade out over 0.3 seconds, then remove.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                toast.animator().alphaValue = 0
            } completionHandler: {
                toast.removeFromSuperview()
            }
        }
    }
}
