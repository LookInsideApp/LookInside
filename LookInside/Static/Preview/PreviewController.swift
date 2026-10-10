//
//  PreviewController.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/6.
//  https://lookin.work
//

import AppKit

/// Hosts the 3D preview and turns mouse, trackpad and keyboard input into
/// rotation, translation, zoom, selection and the context menu.
final class PreviewController: BaseViewController, NSGestureRecognizerDelegate, NSMenuDelegate, PreviewStageViewDelegate {
    @objc weak var staticViewController: StaticViewController?

    /// Set by the owner in a live window; nil when reading a `.lookin` file.
    @objc weak var asyncUpdateManager: StaticAsyncUpdateManager?

    private let dataSource: HierarchyDataSource?
    private let previewView: PreviewView
    /// Configured by makeContainerView() during the superclass initializer.
    private let stageView = PreviewStageView()

    // Lazy because their target is self; they are first touched where they
    // used to be created.
    private lazy var panRecognizer = PreviewPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    private lazy var clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleClickGesture(_:)))
    private lazy var doubleClickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick(_:)))
    private lazy var rightClickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleRightClick(_:)))

    private let rightClickMenu = NSMenu()
    private var rightClickingDisplayItem: DisplayItem?

    private var eventMonitors: [Any] = []
    private var notificationObservers: [NSObjectProtocol] = []
    private var keyValueObservations: [NSKeyValueObservation] = []
    private let dataSourceSignals = SyncSubscriptionBag()

    private var hasLaidOut = false
    /// The rotation to go back to when switching from 2D to 3D.
    private var rotationBeforeFlattening: CGPoint = .zero
    /// The hierarchy shown before the current one, to tell whether the
    /// app's screen size changed.
    private var previousHierarchyInfo: HierarchyInfo?

    /// While space is held, panning moves the preview.
    private var isKeyingDownSpace = false {
        didSet {
            view.window?.invalidateCursorRects(for: view)
            doubleClickRecognizer.isEnabled = !isKeyingDownSpace
            rightClickRecognizer.isEnabled = !isKeyingDownSpace
        }
    }

    /// While command is held, clicks select through, and scrolling zooms.
    private var isKeyingDownCommand = false {
        didSet {
            let isQuickSelecting = isKeyingDownCommand && view.window?.isKeyWindow == true
            dataSource?.preferenceManager().isQuickSelecting.setBOOLValue(isQuickSelecting, ignoreSubscriber: nil)
        }
    }

    /// While option is held, the preview measures.
    private var isKeyingDownOption = false {
        didSet {
            guard isKeyingDownOption != oldValue, let preferenceManager = dataSource?.preferenceManager() else { return }
            if preferenceManager.measureState.currentIntegerValue == MeasureState.locked.rawValue {
                return
            }
            let measures = isKeyingDownOption && dataSource?.selectedItem != nil && view.window?.isKeyWindow == true
            let state: MeasureState = measures ? .unlocked : .no
            preferenceManager.measureState.setIntegerValue(state.rawValue, ignoreSubscriber: nil)
        }
    }

    @objc(initWithDataSource:)
    init(dataSource: HierarchyDataSource?) {
        self.dataSource = dataSource
        previewView = PreviewView(dataSource: dataSource)
        super.init(containerView: nil)
        setUp()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        for monitor in eventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func makeContainerView() -> NSView {
        let stageView = self.stageView
        stageView.didChangeAppearanceBlock = { view, isDarkMode in
            view?.backgroundColor = isDarkMode
                ? NSColor(red: 0, green: 0, blue: 0, alpha: 1)
                : NSColor(red: 1, green: 1, blue: 1, alpha: 1)
        }
        stageView.delegate = self
        return stageView
    }

    private func setUp() {
        let appInfo = dataSource?.rawHierarchyInfo?.appInfo
        let preferenceManager = dataSource?.preferenceManager()

        previewView.preferenceManager = preferenceManager
        previewView.alphaValue = 0
        previewView.appScreenSize = CGSize(width: appInfo?.screenWidth ?? 0, height: appInfo?.screenHeight ?? 0)
        previewView.showHiddenItems = preferenceManager?.showHiddenItems.currentBOOLValue ?? false
        preferenceManager?.showHiddenItems.subscribe(self, action: #selector(handleShowHiddenItemsChange(_:)), relatedObject: nil)
        stageView.didChangeAppearanceBlock = { [weak self] _, isDarkMode in
            self?.previewView.isDarkMode = isDarkMode
        }
        view.addSubview(previewView)

        // Render once now, then on every reload and every preview toggle.
        renderAllItems()
        dataSourceSignals.observe(dataSource?.didReloadHierarchyInfo) { [weak self] in
            self?.renderAllItems()
        }
        dataSourceSignals.observe(dataSource?.itemDidChangeNoPreview) { [weak self] in
            self?.renderAllItems()
        }
        dataSourceSignals.observe(dataSource?.didReloadFlatItemsWithSearchOrFocus) { [weak self] in
            guard let self else { return }
            let validItems = (dataSource?.flatItems ?? []).filter { !$0.inNoPreviewHierarchy }
            previewView.render(displayItems: validItems, discardCache: false)
        }

        // The z positions follow the displayed items, hidden / alpha
        // changes, and frame changes.
        if let dataSource {
            keyValueObservations.append(dataSource.observe(\.displayingFlatItems) { [weak self] _, _ in
                self?.previewView.updateZPosition()
            })
            // Resets translation and scale when the app is reloaded.
            keyValueObservations.append(dataSource.observe(\.rawHierarchyInfo) { [weak self] _, _ in
                self?.hierarchyInfoDidChange()
            })
            keyValueObservations.append(dataSource.observe(\.selectedItem, options: [.initial]) { [weak self] dataSource, _ in
                self?.previewView.didSelect(dataSource.selectedItem)
            })
        }
        if let staticDataSource = dataSource as? StaticHierarchyDataSource {
            dataSourceSignals.observe(staticDataSource.itemDidChangeHiddenAlphaValue) { [weak self] in
                self?.previewView.updateZPosition()
            }
            dataSourceSignals.observe(staticDataSource.itemsDidChangeFrame) { [weak self] in
                self?.previewView.updateZPosition()
            }
        }

        panRecognizer.delegate = self
        previewView.addGestureRecognizer(panRecognizer)

        clickRecognizer.numberOfClicksRequired = 1
        clickRecognizer.delegate = self
        previewView.addGestureRecognizer(clickRecognizer)

        doubleClickRecognizer.numberOfClicksRequired = 2
        previewView.addGestureRecognizer(doubleClickRecognizer)

        rightClickRecognizer.buttonMask = 0x2
        rightClickRecognizer.numberOfClicksRequired = 1
        previewView.addGestureRecognizer(rightClickRecognizer)

        rightClickMenu.autoenablesItems = false
        rightClickMenu.delegate = self

        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp, handler: { [weak self] event in
            // On a MacBook, holding space, dragging on the trackpad and then
            // releasing space never calls keyUp(with:); catch it here.
            if let self, event.type == .keyUp, event.charactersIgnoringModifiers == " " {
                isKeyingDownSpace = false
                view.window?.invalidateCursorRects(for: view)
            }
            return event
        }) {
            eventMonitors.append(monitor)
        }
        if let monitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: { [weak self] event in
            self?.isKeyingDownCommand = event.modifierFlags.contains(.command)
            self?.isKeyingDownOption = event.modifierFlags.contains(.option)
            return event
        }) {
            eventMonitors.append(monitor)
        }

        preferenceManager?.previewScale.subscribe(self, action: #selector(handlePreviewScaleChange(_:)), relatedObject: nil, sendAtOnce: true)
        preferenceManager?.previewDimension.subscribe(self, action: #selector(handlePreviewDimensionChange(_:)), relatedObject: nil, sendAtOnce: true)
        preferenceManager?.freeRotation.subscribe(self, action: #selector(handleFreeRotationChange(_:)), relatedObject: nil, sendAtOnce: true)
        preferenceManager?.zInterspace.subscribe(self, action: #selector(handleZInterspaceChange(_:)), relatedObject: nil, sendAtOnce: true)

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self, (note.object as? NSWindow) === self.view.window else { return }
                self.isKeyingDownSpace = false
                self.isKeyingDownOption = false
                self.isKeyingDownCommand = false
            }
        })
    }

    private func renderAllItems() {
        let validItems = (dataSource?.flatItems ?? []).filter { item in
            if item.inNoPreviewHierarchy {
                return false
            }
            if let customInfo = item.customInfo {
                return customInfo.hasValidFrame()
            }
            return true
        }
        previewView.render(displayItems: validItems, discardCache: true)
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        // Reach a dashboard's width further left (20 less, since the preview
        // usually turns right) and a title bar's height further down, so the
        // preview looks centred.
        let titleBarHeight = NavigationManager.shared.windowTitleBarHeight
        let layout = StaticLayout(previewView)
        layout.width(view.frame.width + DashboardViewWidth - DashboardHorInset - 20)
        layout.right(0)
        layout.height(view.frame.height + titleBarHeight)
        layout.y(0)

        if !hasLaidOut {
            hasLaidOut = true
            // The opening animation.
            previewView.setRotation(CGPoint(x: 0.8, y: 0), animated: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 1
                    self.previewView.animator().alphaValue = 1
                }
                self.previewView.setRotation(
                    CGPoint(x: 0.6, y: 0),
                    animated: true,
                    timingFunction: CAMediaTimingFunction(controlPoints: 0.3, 0.93, 0.26, 0.88),
                    duration: 1.5
                )
            }
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(self)
    }

    // MARK: - NSGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
        #if DEBUG
            if gestureRecognizer === clickRecognizer, event.locationInWindow.y <= 25 {
                // A click on the debug buttons at the bottom.
                return false
            }
        #endif
        if gestureRecognizer === panRecognizer, previewView.dimension != .dimension3D, !isKeyingDownSpace {
            // Without space the pan rotates, and a flat preview does not.
            return false
        }
        return true
    }

    // MARK: - PreviewStageViewDelegate

    func previewStageView(_: PreviewStageView, mouseMoved event: NSEvent) {
        guard let dataSource else { return }
        if isKeyingDownSpace {
            if dataSource.hoveredItem != nil {
                dataSource.hoveredItem = nil
            }
            return
        }
        guard let window = view.window else { return }
        var rawPoint = event.locationInWindow
        rawPoint.y = window.frame.size.height - rawPoint.y
        let targetView = window.contentView?.hitTest(rawPoint)
        guard targetView === previewView else { return }

        let point = previewView.convert(rawPoint, from: window.contentView)
        let item = previewView.displayItem(at: point)
        if dataSource.hoveredItem !== item {
            dataSource.hoveredItem = item
        }
    }

    func didResetCursorRects(in view: PreviewStageView) {
        if isKeyingDownSpace {
            view.addCursorRect(self.view.bounds, cursor: .openHand)
        }
    }

    // MARK: - Preferences

    @objc private func handleShowHiddenItemsChange(_ param: MessageActionParameters) {
        previewView.showHiddenItems = param.boolValue
        previewView.updateZPosition()
    }

    @objc private func handleFreeRotationChange(_ param: MessageActionParameters) {
        var rotation = previewView.rotation
        if param.boolValue {
            if previewView.dimension == .dimension3D {
                rotation.y = -0.05
                previewView.setRotation(rotation, animated: true)
            }
        } else {
            guard rotation.y != 0 else { return }
            rotation.y = 0
            previewView.setRotation(rotation, animated: true)
        }
    }

    @objc private func handlePreviewScaleChange(_ param: MessageActionParameters) {
        previewView.scale = param.doubleValue
    }

    @objc private func handlePreviewDimensionChange(_ param: MessageActionParameters) {
        guard let newDimension = PreviewDimension(rawValue: UInt(bitPattern: param.integerValue)),
              previewView.dimension != newDimension
        else {
            return
        }
        if newDimension == .dimension2D {
            rotationBeforeFlattening = previewView.rotation
            previewView.setDimension(newDimension, animated: true)
        } else {
            var rotation = rotationBeforeFlattening
            previewView.setDimension(newDimension, animated: true)

            // Too small a rotation would hide the switch between 2D and 3D.
            if rotation.x >= 0 {
                rotation.x = max(0.18, rotation.x)
            } else {
                rotation.x = min(-0.18, rotation.x)
            }
            if dataSource?.preferenceManager().freeRotation.currentBOOLValue != true {
                rotation.y = 0
            }
            previewView.setRotation(rotation, animated: true)
        }
    }

    @objc private func handleZInterspaceChange(_ param: MessageActionParameters) {
        previewView.zInterspace = param.doubleValue
    }

    private func hierarchyInfoDidChange() {
        guard let currentInfo = dataSource?.rawHierarchyInfo else {
            assertionFailure()
            return
        }
        let currentWidth = currentInfo.appInfo?.screenWidth ?? 0
        let currentHeight = currentInfo.appInfo?.screenHeight ?? 0
        previewView.appScreenSize = CGSize(width: currentWidth, height: currentHeight)

        let previousInfo = previousHierarchyInfo
        previousHierarchyInfo = currentInfo
        guard let previousInfo else { return }
        if previousInfo.appInfo?.screenWidth == currentWidth, previousInfo.appInfo?.screenHeight == currentHeight {
            return
        }
        // The app's screen size changed: reset the scale.
        dataSource?.preferenceManager().previewScale.setDoubleValue(Double(initialPreviewScale), ignoreSubscriber: nil)
    }

    // MARK: - Gestures

    @objc private func handlePanGesture(_ recognizer: PreviewPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            UserActionManager.sharedInstance().send(.previewOperation)
            // End any editing in a dashboard card.
            view.window?.makeFirstResponder(self)
            recognizer.purpose = isKeyingDownSpace ? .translate : .rotate
            recognizer.initialRotation = previewView.rotation
            recognizer.initialTranslation = previewView.translation

        case .changed:
            let translation = recognizer.translation(in: view)
            switch recognizer.purpose {
            case .rotate:
                guard previewView.dimension == .dimension3D else { return }
                let rotationX = recognizer.initialRotation.x + translation.x * 0.01
                let rotationY: CGFloat
                if dataSource?.preferenceManager().freeRotation.currentBOOLValue == true {
                    rotationY = recognizer.initialRotation.y + translation.y * 0.004
                } else {
                    rotationY = 0
                }
                previewView.setRotation(CGPoint(x: rotationX, y: rotationY), animated: false)
            case .translate:
                // The bigger the preview, the slower it moves, so a zoomed-in
                // image does not fly away at a light touch. Scale 0...1 maps
                // to a factor of 1...0.08.
                let factor = (1 - previewView.scale) * 0.92 + 0.08
                let initial = recognizer.initialTranslation
                previewView.translation = NSPoint(
                    x: initial.x + translation.x * 0.01 * factor,
                    y: initial.y - translation.y * 0.01 * factor
                )
            }

        default:
            break
        }
    }

    @objc private func handleClickGesture(_ recognizer: NSClickGestureRecognizer) {
        guard let dataSource, !dataSource.shouldAvoidChangingPreviewSelectionDueToDashboardSearch else { return }
        UserActionManager.sharedInstance().send(.previewOperation)
        // End any editing in a dashboard card.
        view.window?.makeFirstResponder(self)

        let item = previewView.displayItem(at: recognizer.location(in: previewView))
        if dataSource.selectedItem === item {
            return
        }
        // Expand before selecting, so the tree can scroll to the item.
        if let item, !item.displayingInHierarchy {
            dataSource.expand(toShow: item)
        }
        dataSource.selectedItem = item
    }

    @objc private func handleRightClick(_ recognizer: NSClickGestureRecognizer) {
        UserActionManager.sharedInstance().send(.previewOperation)
        // End any editing in a dashboard card.
        view.window?.makeFirstResponder(self)

        guard let item = previewView.displayItem(at: recognizer.location(in: previewView)),
              item.displayingInHierarchy
        else {
            return
        }
        if dataSource?.selectedItem !== item {
            dataSource?.selectedItem = item
        }
        rightClickingDisplayItem = item
        rightClickMenu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    @objc private func handleDoubleClick(_ recognizer: NSClickGestureRecognizer) {
        UserActionManager.sharedInstance().send(.previewOperation)
        // End any editing in a dashboard card.
        view.window?.makeFirstResponder(self)

        guard let item = previewView.displayItem(at: recognizer.location(in: previewView)),
              item.displayingInHierarchy
        else {
            return
        }
        switch PreferenceManager.shared.doubleClickBehavior {
        case .collapse:
            if item.isExpandable {
                if item.isExpanded {
                    dataSource?.collapse(item)
                } else {
                    dataSource?.expand(item)
                }
            }
        case .focus:
            dataSource?.focus(item)
        default:
            assertionFailure()
        }
    }

    // MARK: - Events

    override func magnify(with event: NSEvent) {
        super.magnify(with: event)
        guard event.phase == .changed, let manager = dataSource?.preferenceManager() else { return }
        let targetScale = min(max(manager.previewScale.currentDoubleValue + event.magnification * 0.3, 0), 1)
        manager.previewScale.setDoubleValue(targetScale, ignoreSubscriber: nil)
    }

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        if isKeyingDownCommand {
            guard let manager = dataSource?.preferenceManager() else { return }
            let targetScale = manager.previewScale.currentDoubleValue - event.deltaY * 0.005
            manager.previewScale.setDoubleValue(
                min(max(targetScale, previewMinScale), previewMaxScale),
                ignoreSubscriber: nil
            )
        } else {
            // The bigger the preview, the slower it moves. Scale 0...1 maps
            // to a factor of 1...0.3.
            let factor = (1 - previewView.scale) * 0.7 + 0.3
            var translation = previewView.translation
            translation.x += event.deltaX * 0.04 * factor
            translation.y -= event.deltaY * 0.04 * factor
            previewView.translation = translation
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == " " {
            isKeyingDownSpace = true
            return
        }
        if dataSource?.keyDown(event) == true {
            return
        }
        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        if event.charactersIgnoringModifiers == " " {
            isKeyingDownSpace = false
            return
        }
        super.keyUp(with: event)
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard let displayItem = rightClickingDisplayItem else { return }

        func addItem(_ title: String, _ action: Selector?) {
            let item = NSMenuItem()
            item.title = title
            if let action {
                item.target = self
                item.action = action
            }
            menu.addItem(item)
        }

        if !displayItem.isUserCustom() {
            addItem(NSLocalizedString("Focus", comment: ""), #selector(handleFocusCurrentItem(_:)))
            addItem(NSLocalizedString("Print", comment: ""), #selector(handlePrintItem(_:)))
            menu.addItem(.separator())

            if dataSource?.isReadOnly() == false {
                let isUpdating = asyncUpdateManager?.isUpdating() ?? false
                addItem(NSLocalizedString("Reload layer", comment: ""), isUpdating ? nil : #selector(handleReloadSelfItem(_:)))
                addItem(
                    NSLocalizedString("Reload layer and its children", comment: ""),
                    isUpdating ? nil : #selector(handleReloadSelfAndChildrenItem(_:))
                )
                menu.addItem(.separator())
            }
        }

        if displayItem.isExpandable {
            if displayItem.isExpanded {
                addItem(NSLocalizedString("Collapse children", comment: ""), #selector(handleCollapseChildren(_:)))
            } else {
                addItem(NSLocalizedString("Expand recursively", comment: ""), #selector(handleExpandRecursively(_:)))
            }
            menu.addItem(.separator())
        }

        addItem(NSLocalizedString("Hide screenshot this time", comment: ""), #selector(handleCancelPreview(_:)))

        if !displayItem.isUserCustom(), displayItem.groupScreenshot != nil {
            addItem(NSLocalizedString("Hide screenshot forever…", comment: ""), #selector(handleHideScreenshotForever))
            menu.addItem(.separator())
            addItem(NSLocalizedString("Export screenshot…", comment: ""), #selector(handleExportScreenshot(_:)))
        }
    }

    func menuDidClose(_: NSMenu) {
        // Holding command to open the menu, releasing it and then closing
        // the menu escapes the flags monitor; catch up here.
        isKeyingDownCommand = NSEvent.modifierFlags.contains(.command)
    }

    @objc private func handlePrintItem(_: NSMenuItem) {
        NotificationCenter.default.post(
            name: NSNotification.Name(appShowConsoleNotificationName),
            object: rightClickingDisplayItem
        )
    }

    @objc private func handleReloadSelfItem(_: NSMenuItem) {
        guard let item = rightClickingDisplayItem else { return }
        asyncUpdateManager?.reloadSingleDisplayItem(item)
    }

    @objc private func handleReloadSelfAndChildrenItem(_: NSMenuItem) {
        guard let item = rightClickingDisplayItem else { return }
        asyncUpdateManager?.reloadDisplayItemAndChildren(item)
    }

    @objc private func handleFocusCurrentItem(_: NSMenuItem) {
        dataSource?.focus(rightClickingDisplayItem)
    }

    @objc private func handleExpandRecursively(_: NSMenuItem) {
        assert(rightClickingDisplayItem != nil)
        dataSource?.expandItemsRooted(by: rightClickingDisplayItem)
    }

    @objc private func handleCollapseChildren(_: NSMenuItem) {
        assert(rightClickingDisplayItem != nil)
        dataSource?.collapseAllChildren(of: rightClickingDisplayItem)
    }

    @objc private func handleCancelPreview(_: NSMenuItem) {
        rightClickingDisplayItem?.noPreview = true
        dataSource?.itemDidChangeNoPreview.send()
    }

    @objc private func handleExportScreenshot(_: NSMenuItem) {
        guard let item = rightClickingDisplayItem else { return }
        ExportManager.exportScreenshot(with: item)
    }

    @objc private func handleHideScreenshotForever() {
        AppHelper.openCustomConfigWebsite()
    }
}
