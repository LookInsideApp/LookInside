//
//  StaticViewController.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit

/// The content of a live inspector window: the hierarchy tree on the left;
/// on the right the preview with the dashboard (or measure panel) over it,
/// and the console under them; tips float above the preview.
@objc(LKStaticViewController)
final class StaticViewController: BaseViewController, NSSplitViewDelegate {
    /// Set when the fast mode tip is dismissed for good.
    private static let ignoreFastModeTipsDefaultsKey = "IgnoreFastModeTips"

    /// The per-document data source, owned by StaticWindowController.
    @objc private(set) weak var hierarchyDataSource: StaticHierarchyDataSource?

    /// The per-document update manager, owned by StaticWindowController.
    @objc private(set) weak var asyncUpdateManager: StaticAsyncUpdateManager?

    @objc let viewsPreviewController: PreviewController

    @objc let progressView = ProgressIndicatorView()

    /// Shows or hides the console under the preview. Observable with KVO.
    @objc dynamic var showConsole = false {
        didSet { applyShowConsole() }
    }

    private let mainSplitView = SplitView()
    private let rightSplitView = SplitView()
    private let splitTopView = BaseView()

    private let imageSyncTipsView = TipsView()
    private let tooLargeToSyncScreenshotTipsView = RedTipsView()
    private let userConfigNoPreviewTipsView = TipsView()
    private let noPreviewTipView = TipsView()
    private let customViewTipView = TipsView()
    private let focusTipView = YellowTipsView()
    private let fastModeTipView = TipsView()
    private let serverUpgradeTipView = TipsView()

    /// Read with KVC by the DEBUG UI snapshots.
    @objc let dashboardController: DashboardViewController
    private let hierarchyController: StaticHierarchyController
    private var consoleController: ConsoleViewController?
    private let measureController: MeasureController

    private var notificationObservers: [NSObjectProtocol] = []
    private var keyValueObservations: [NSKeyValueObservation] = []
    private let dataSourceSignals = SyncSubscriptionBag()
    private var modifyingUpdatesTask: Task<Void, Never>?

    /// The superclass initializer sets the view, and setting it builds the
    /// children that read the data source and the update manager, so they
    /// are stored first, and the child controllers are created here, in the
    /// order buildContent() used to create them.
    @objc(initWithHierarchyDataSource:asyncUpdateManager:)
    init(hierarchyDataSource: StaticHierarchyDataSource, asyncUpdateManager: StaticAsyncUpdateManager) {
        self.hierarchyDataSource = hierarchyDataSource
        self.asyncUpdateManager = asyncUpdateManager
        hierarchyController = StaticHierarchyController(dataSource: hierarchyDataSource)
        viewsPreviewController = PreviewController(dataSource: hierarchyDataSource)
        dashboardController = DashboardViewController(staticDataSource: hierarchyDataSource)
        measureController = MeasureController(dataSource: hierarchyDataSource)
        super.init(containerView: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        modifyingUpdatesTask?.cancel()
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func makeContainerView() -> NSView {
        let splitView = mainSplitView
        splitView.didFinishFirstLayout = { view in
            let x = min(max(350, view.bounds.size.width * 0.3), 700)
            view.setPosition(x, ofDividerAt: 0)
        }
        splitView.arrangesAllSubviews = false
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        return splitView
    }

    override func shouldShowConnectionTips() -> Bool {
        true
    }

    override var view: NSView {
        get { super.view }
        set {
            super.view = newValue
            buildContent()
        }
    }

    // MARK: - Building

    private func buildContent() {
        let preferenceManager = PreferenceManager.shared
        preferenceManager.measureState.subscribe(self, action: #selector(handleMeasureStateChange(_:)), relatedObject: nil)

        // Set by the initializer, which takes a non-optional data source.
        let dataSource = hierarchyDataSource!

        addChild(hierarchyController)
        mainSplitView.addArrangedSubview(hierarchyController.view)
        // Hand the per-document update manager down the owner chain.
        hierarchyController.hierarchyView.asyncUpdateManager = asyncUpdateManager

        rightSplitView.arrangesAllSubviews = true
        rightSplitView.isVertical = false
        rightSplitView.dividerStyle = .thin
        rightSplitView.delegate = self
        mainSplitView.addArrangedSubview(rightSplitView)

        rightSplitView.addArrangedSubview(splitTopView)

        viewsPreviewController.staticViewController = self
        viewsPreviewController.asyncUpdateManager = asyncUpdateManager
        splitTopView.addSubview(viewsPreviewController.view)
        addChild(viewsPreviewController)

        dashboardController.asyncUpdateManager = asyncUpdateManager
        splitTopView.addSubview(dashboardController.view)
        addChild(dashboardController)

        // Once the window has a live document, hand it to the children that
        // send per-document requests (dashboard, console).
        observeWindowBecomingMain { [weak self] in
            guard let self else { return }
            let document = LiveDocument.document(in: view.window)
            dashboardController.liveDocument = document
            consoleController?.liveDocument = document
        }

        measureController.view.isHidden = true
        splitTopView.addSubview(measureController.view)
        addChild(measureController)

        buildTips()

        view.addSubview(progressView)

        observeDataSource(dataSource)

        // The image sync tip shows the icon of the owning document's app.
        // Re-evaluating whenever a window becomes main covers both the first
        // window-document binding and reconnecting to a new app.
        observeWindowBecomingMain { [weak self] in
            guard let self, let app = LiveDocument.document(in: view.window)?.inspectableApp else { return }
            imageSyncTipsView.setImage(byAppInfo: app.appInfo)
        }

        if let updates = asyncUpdateManager?.modifyingUpdates.subscribe() {
            modifyingUpdatesTask = Task { @MainActor [weak self] in
                for await event in updates {
                    self?.handleModifyingUpdate(event)
                }
            }
        }

        preferenceManager.fastMode.subscribe(self, action: #selector(handleFastModeChange(_:)), relatedObject: nil, sendAtOnce: true)

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: NSNotification.Name(appShowConsoleNotificationName),
            object: nil,
            queue: nil
        ) { [weak self] note in
            MainActor.assumeIsolated {
                self?.showConsoleAndPrint(note.object as? DisplayItem)
            }
        })
    }

    private func buildTips() {
        imageSyncTipsView.isHidden = true
        view.addSubview(imageSyncTipsView)

        tooLargeToSyncScreenshotTipsView.image = NSImage(named: "icon_info")
        tooLargeToSyncScreenshotTipsView.title = NSLocalizedString("Image is too large to be displayed.", comment: "")
        tooLargeToSyncScreenshotTipsView.isHidden = true
        view.addSubview(tooLargeToSyncScreenshotTipsView)

        focusTipView.image = NSImage(named: "icon_info")
        focusTipView.title = NSLocalizedString("Currently in focus mode", comment: "")
        focusTipView.isHidden = true
        focusTipView.buttonText = NSLocalizedString("Exit", comment: "")
        focusTipView.target = self
        focusTipView.clickAction = #selector(handleExitFocusTipView)
        view.addSubview(focusTipView)

        fastModeTipView.image = NSImage(named: "Icon_Inspiration_small")
        fastModeTipView.title = NSLocalizedString("Fast refresh mode is enabled, which may result in layer consistency issues.", comment: "")
        fastModeTipView.isHidden = true
        fastModeTipView.buttonText = NSLocalizedString("Details", comment: "")
        fastModeTipView.target = self
        fastModeTipView.clickAction = #selector(handleFastModeTipViewClick)
        view.addSubview(fastModeTipView)

        noPreviewTipView.image = NSImage(named: "icon_hide")
        noPreviewTipView.title = NSLocalizedString("The screenshot of selected item is not displayed.", comment: "")
        noPreviewTipView.buttonText = NSLocalizedString("Display", comment: "")
        noPreviewTipView.target = self
        noPreviewTipView.clickAction = #selector(handleNoPreviewTipView)
        noPreviewTipView.isHidden = true
        view.addSubview(noPreviewTipView)

        customViewTipView.image = NSImage(named: "Icon_Inspiration_small")
        // The view class name depends on the inspected app, which is unknown
        // until a hierarchy arrives; handleSelectItemDidChange() refreshes
        // the title before showing it.
        customViewTipView.title = customViewTipTitle()
        customViewTipView.buttonText = NSLocalizedString("Details", comment: "")
        customViewTipView.target = self
        customViewTipView.clickAction = #selector(handleCustomViewTipsView)
        customViewTipView.isHidden = true
        view.addSubview(customViewTipView)

        userConfigNoPreviewTipsView.image = NSImage(named: "icon_hide")
        userConfigNoPreviewTipsView.title = NSLocalizedString("The screenshot is not displayed due to the config in iOS App.", comment: "")
        userConfigNoPreviewTipsView.buttonText = NSLocalizedString("Details", comment: "")
        userConfigNoPreviewTipsView.target = self
        userConfigNoPreviewTipsView.clickAction = #selector(handleUserConfigNoPreviewTipView)
        userConfigNoPreviewTipsView.isHidden = true
        view.addSubview(userConfigNoPreviewTipsView)

        serverUpgradeTipView.image = NSImage(named: "Icon_Inspiration_small")
        serverUpgradeTipView.title = NSLocalizedString("The app's integrator should upgrade LookInside Server.", comment: "Tip shown once per inspected app whose LookInside Server is 0.2.9 or older")
        serverUpgradeTipView.buttonText = NSLocalizedString("OK", comment: "")
        serverUpgradeTipView.target = self
        serverUpgradeTipView.clickAction = #selector(handleServerUpgradeTipView)
        serverUpgradeTipView.isHidden = true
        view.addSubview(serverUpgradeTipView)

        // The 220 reply that carries the Server's release can arrive before
        // or after this window gets its document.
        observeWindowBecomingMain { [weak self] in
            self?.updateServerUpgradeTip()
        }
        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: ServerUpgradeHint.releaseDidArriveNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateServerUpgradeTip()
            }
        })
    }

    /// Shows the upgrade hint when this window's app reported an old Server
    /// and no window showed the hint for that app during this launch.
    private func updateServerUpgradeTip() {
        guard serverUpgradeTipView.isHidden,
              ServerUpgradeHint.shouldShowHint(for: LiveDocument.document(in: view.window)?.inspectableApp)
        else {
            return
        }
        serverUpgradeTipView.isHidden = false
        view.needsLayout = true
    }

    private func observeDataSource(_ dataSource: StaticHierarchyDataSource?) {
        guard let dataSource else { return }
        var isInitialSelection = true
        keyValueObservations.append(dataSource.observe(\.selectedItem, options: [.initial]) { [weak self] _, _ in
            guard let self else { return }
            handleSelectItemDidChange()
            if isInitialSelection {
                isInitialSelection = false
            } else {
                updateNoPreviewTip()
            }
        })
        dataSourceSignals.observe(dataSource.itemDidChangeNoPreview) { [weak self] in
            self?.updateNoPreviewTip()
        }
        keyValueObservations.append(dataSource.observe(\.state, options: [.initial]) { [weak self] dataSource, _ in
            guard let self else { return }
            let isFocus = dataSource.state == .focus
            focusTipView.isHidden = !isFocus
            if isFocus {
                focusTipView.startAnimation()
            } else {
                focusTipView.endAnimation()
            }
            view.needsLayout = true
        })
    }

    private func observeWindowBecomingMain(_ handler: @escaping @MainActor () -> Void) {
        handler()
        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: nil
        ) { _ in
            MainActor.assumeIsolated {
                handler()
            }
        })
    }

    // MARK: - Layout

    override func viewDidLayout() {
        super.viewDidLayout()
        let dashboardLayout = StaticLayout(dashboardController.view)
        dashboardLayout.width(DashboardViewWidth)
        dashboardLayout.right(0)
        dashboardLayout.fullHeight()

        let measureLayout = StaticLayout(measureController.view)
        measureLayout.width(MeasureViewWidth)
        measureLayout.right(DashboardHorInset)
        measureLayout.fullHeight()

        StaticLayout(viewsPreviewController.view).fullFrame()

        let windowTitleHeight = NavigationManager.shared.windowTitleBarHeight

        let progressLayout = StaticLayout(progressView)
        progressLayout.fullWidth()
        progressLayout.height(3)
        progressLayout.y(windowTitleHeight)

        let tips: [NSView?] = [
            connectionTipsView,
            imageSyncTipsView,
            tooLargeToSyncScreenshotTipsView,
            noPreviewTipView,
            focusTipView,
            userConfigNoPreviewTipsView,
            customViewTipView,
            fastModeTipView,
            serverUpgradeTipView,
        ]
        var tipsY = windowTitleHeight + 10
        for tipsView in tips.compactMap({ $0 }) where Self.isVisible(tipsView) {
            let midX = hierarchyController.view.frame.width + (viewsPreviewController.view.frame.width - DashboardViewWidth) / 2
            let layout = StaticLayout(tipsView)
            layout.sizeToFit()
            layout.y(tipsY)
            layout.midX(midX)
            tipsY = tipsView.frame.maxY + 5
        }
    }

    /// ShortCocoa's `visibles` filter.
    private static func isVisible(_ view: NSView) -> Bool {
        !view.isHidden && view.superview != nil && view.alphaValue >= 0.01
    }

    // MARK: - Console

    private func showConsoleAndPrint(_ item: DisplayItem?) {
        let isFirstTimeToShowConsole = consoleController == nil
        showConsole = true
        if isFirstTimeToShowConsole {
            // Give the console a moment to set up.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.consoleController?.submit(with: item?.viewObject, text: "self")
            }
        } else {
            consoleController?.submit(with: item?.viewObject, text: "self")
        }
    }

    private func applyShowConsole() {
        if showConsole {
            let consoleController: ConsoleViewController
            if let existing = self.consoleController {
                consoleController = existing
            } else {
                guard let hierarchyDataSource else { return }
                consoleController = ConsoleViewController(hierarchyDataSource: hierarchyDataSource)
                // Made on first show, so it takes the window's live document
                // at that moment.
                consoleController.liveDocument = LiveDocument.document(in: view.window)
                addChild(consoleController)
                self.consoleController = consoleController
            }
            rightSplitView.addArrangedSubview(consoleController.view)

            if consoleController.view.bounds.size.height < 20 {
                DispatchQueue.main.async {
                    self.rightSplitView.setPosition(self.rightSplitView.bounds.size.height - 150, ofDividerAt: 0)
                }
            }
        } else if let consoleView = consoleController?.view, consoleView.superview != nil {
            rightSplitView.removeArrangedSubview(consoleView)
        } else {
            assertionFailure()
        }
        consoleController?.isControllerShowing = showConsole
    }

    /// The hierarchy view of the tree on the left.
    @objc func currentHierarchyView() -> HierarchyView? {
        hierarchyController.hierarchyView
    }

    private var dataSource: HierarchyDataSource? {
        hierarchyController.dataSource
    }

    // MARK: - NSSplitViewDelegate

    func splitView(_: NSSplitView, canCollapseSubview _: NSView) -> Bool {
        false
    }

    func splitView(_ splitView: NSSplitView, constrainMinCoordinate _: CGFloat, ofSubviewAt _: Int) -> CGFloat {
        if splitView === mainSplitView {
            return HierarchyMinWidth
        }
        return splitView.bounds.size.height * 0.3
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate _: CGFloat, ofSubviewAt _: Int) -> CGFloat {
        if splitView === mainSplitView {
            return max(splitView.bounds.size.width - DashboardViewWidth - 100, HierarchyMinWidth)
        }
        return splitView.bounds.size.height - 50
    }

    func splitViewDidResizeSubviews(_: Notification) {
        view.needsLayout = true
    }

    // MARK: - Events

    private func handleModifyingUpdate(_ event: ModifyingUpdateEvent) {
        switch event {
        case let .progress(received, total):
            let progress = CGFloat(received) / CGFloat(max(1, total))
            if progress >= 1 {
                progressView.finish(completion: nil)
                imageSyncTipsView.isHidden = true
            } else {
                progressView.animate(toProgress: max(progress, 0.2), duration: 0.1)
                imageSyncTipsView.isHidden = false
                imageSyncTipsView.title = String(
                    format: NSLocalizedString("Updating screenshots… %@ / %@", comment: ""),
                    NSNumber(value: received),
                    NSNumber(value: total)
                )
                view.needsLayout = true
            }
        case .failure:
            // A failed screenshot patch is silent, as it always was; only
            // the progress UI is cleared.
            imageSyncTipsView.isHidden = true
            progressView.resetToZero()
        }
    }

    private func updateNoPreviewTip() {
        let item = hierarchyDataSource?.selectedItem
        let shouldShowNoPreviewTip = (item?.inNoPreviewHierarchy ?? false)
            && item?.doNotFetchScreenshotReason != .doNotFetchScreenshotForUserConfig
        guard shouldShowNoPreviewTip || !noPreviewTipView.isHidden else { return }
        noPreviewTipView.title = String(
            format: NSLocalizedString("The screenshot of selected %@ is not displayed.", comment: ""),
            item?.title() ?? ""
        )
        noPreviewTipView.bindingObject = item
        noPreviewTipView.isHidden = !shouldShowNoPreviewTip
        view.needsLayout = true
    }

    @objc private func handleNoPreviewTipView() {
        guard let item = noPreviewTipView.bindingObject as? DisplayItem else { return }
        hierarchyController.hierarchyView(hierarchyController.hierarchyView, needToShowPreviewOf: item)
    }

    @objc private func handleCustomViewTipsView() {
        AppHelper.showDisabledExternalLinkAlert(withMessage: NSLocalizedString(
            "Legacy custom information guides are disabled in this community build. See the repository README instead.",
            comment: ""
        ))
    }

    @objc private func handleServerUpgradeTipView() {
        serverUpgradeTipView.isHidden = true
        view.needsLayout = true
    }

    @objc private func handleExitFocusTipView() {
        dataSource?.endFocus()
    }

    @objc private func handleFastModeTipViewClick() {
        let menu = NSMenu()

        let documentationItem = NSMenuItem()
        documentationItem.title = NSLocalizedString("View feature description", comment: "")
        documentationItem.target = self
        documentationItem.action = #selector(handleFastModeDocumentation)
        menu.addItem(documentationItem)

        menu.addItem(.separator())

        let ignoreItem = NSMenuItem()
        ignoreItem.title = NSLocalizedString("Don't remind me again", comment: "")
        ignoreItem.target = self
        ignoreItem.action = #selector(handleIgnoreFastModeTip)
        menu.addItem(ignoreItem)

        if let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: fastModeTipView.button)
        }
    }

    @objc private func handleFastModeDocumentation() {
        AppHelper.showDisabledExternalLinkAlert(withMessage: NSLocalizedString(
            "Legacy fast mode documentation links are disabled in this community build. See the repository README instead.",
            comment: ""
        ))
    }

    @objc private func handleIgnoreFastModeTip() {
        UserDefaults.standard.set(true, forKey: Self.ignoreFastModeTipsDefaultsKey)
        fastModeTipView.isHidden = true
    }

    @objc private func handleUserConfigNoPreviewTipView() {
        AppHelper.openCustomConfigWebsite()
    }

    @objc private func handleMeasureStateChange(_ param: MessageActionParameters) {
        let isMeasure = param.integerValue != MeasureState.no.rawValue
        dashboardController.view.isHidden = isMeasure
        measureController.view.isHidden = !isMeasure
    }

    @objc private func handleFastModeChange(_ param: MessageActionParameters) {
        guard param.boolValue else {
            fastModeTipView.isHidden = true
            return
        }
        fastModeTipView.isHidden = UserDefaults.standard.bool(forKey: Self.ignoreFastModeTipsDefaultsKey)
        view.needsLayout = true
    }

    private func handleSelectItemDidChange() {
        let item = dataSource?.selectedItem

        let showsTooLargeTip = item != nil
            && item?.optionalAppropriateScreenshot == nil
            && item?.doNotFetchScreenshotReason == .doNotFetchScreenshotForTooLarge
        if tooLargeToSyncScreenshotTipsView.isHidden != !showsTooLargeTip {
            tooLargeToSyncScreenshotTipsView.isHidden = !showsTooLargeTip
            if showsTooLargeTip {
                tooLargeToSyncScreenshotTipsView.startAnimation()
            } else {
                tooLargeToSyncScreenshotTipsView.endAnimation()
            }
            view.needsLayout = true
        }

        let showsCustomTip = item?.isUserCustom() ?? false
        if showsCustomTip {
            customViewTipView.title = customViewTipTitle()
        }
        if customViewTipView.isHidden != !showsCustomTip {
            customViewTipView.isHidden = !showsCustomTip
            view.needsLayout = true
        }
    }

    private func customViewTipTitle() -> String {
        let inspectedAppInfo = hierarchyController.dataSource.rawHierarchyInfo?.appInfo
        return String(
            format: NSLocalizedString("This object may not be a %@ or CALayer.", comment: ""),
            AppHelper.viewClassName(for: inspectedAppInfo)
        )
    }
}
