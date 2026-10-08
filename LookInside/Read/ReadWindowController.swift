//
//  ReadWindowController.swift
//  Lookin
//
//  Created by Li Kai on 2019/5/12.
//  https://lookin.work
//

import AppKit

/// The window of a `ArchiveDocument`.
///
/// Reader windows are owned by the document exclusively:
/// `NavigationManager.showReaderWithHierarchyFile:title:` wraps in-memory
/// hierarchies in an untitled document, and archives on disk open through
/// `NSDocumentController.openDocumentWithContentsOfURL:`.
@objc(LKReadWindowController)
final class ReadWindowController: WindowController, NSToolbarDelegate {
    /// This window's own preference set: the reader's view settings, including
    /// the show-backing-layers toggle, are per document window. A document that
    /// can rebuild its tree reads the toggle from here.
    @objc let preferenceManager = PreferenceManager()

    private var viewController: ReadViewController?
    private var toolbarItemsMap: [String: NSToolbarItem] = [:]
    private var hierarchyFileObservation: NSKeyValueObservation?
    private var selectedItemObservation: NSKeyValueObservation?
    private weak var shownFile: HierarchyFile?

    @objc(initWithDocument:)
    init(document: ArchiveDocument) {
        let screenSize = NSScreen.main?.frame.size ?? .zero
        let window = AppWindow(
            contentRect: NSRect(x: 0, y: 0, width: screenSize.width * 0.7, height: screenSize.height * 0.7),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.tabbingMode = .disallowed
        window.toolbarStyle = .unified
        window.minSize = NSSize(width: 800, height: 500)
        window.center()

        super.init(window: window)

        if document.hierarchyFile == nil {
            // The document is still importing in the background (an Xcode
            // capture): hold the window on a placeholder until the file lands.
            window.contentView = ReadLoadingView()
        }
        // Every file the document produces gets a reader built in place: the
        // one that lands after the import, and each rebuild the backing-layer
        // toggle asks for.
        hierarchyFileObservation = document.observe(\.hierarchyFile, options: [.initial, .new]) { [weak self] document, _ in
            MainActor.assumeIsolated {
                self?.hierarchyFileDidChange(document.hierarchyFile)
            }
        }
        // Flipping the toggle changes the node set itself, so — as in a live
        // session — the tree is rebuilt whole, by the document, when it can.
        preferenceManager.showBackingLayers.subscribe(
            self,
            action: #selector(handleShowBackingLayersDidChange(_:)),
            relatedObject: nil
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func hierarchyFileDidChange(_ file: HierarchyFile?) {
        // Each new file once; the same file set again is not a new reader.
        guard let file, file !== shownFile else { return }
        shownFile = file
        showHierarchyFile(file)
    }

    @objc private func handleShowBackingLayersDidChange(_ param: MessageActionParameters) {
        guard let document = document as? ArchiveDocument, document.canRebuildHierarchyFile() else {
            return
        }
        // Back to the placeholder; the new file's reader replaces it. Toolbar
        // items belong to one toolbar, so they are made afresh for the new one.
        contentViewController = nil
        viewController = nil
        selectedItemObservation = nil
        toolbarItemsMap = [:]
        window?.toolbar = nil
        window?.contentView = ReadLoadingView()
        document.rebuildHierarchyFile(showingBackingLayers: param.boolValue)
    }

    /// Builds the reader for `file` in this window: the view controller, the
    /// measure button's enabled state, and the toolbar, whose items need the
    /// data source to exist.
    private func showHierarchyFile(_ file: HierarchyFile) {
        guard let window else { return }
        let viewController = ReadViewController(file: file, preferenceManager: preferenceManager)
        self.viewController = viewController
        // Setting contentViewController sizes the window to the view; keep the
        // size the window already has.
        viewController.view.frame = window.contentView?.bounds ?? .zero
        window.contentView = viewController.view
        contentViewController = viewController

        selectedItemObservation = viewController.hierarchyDataSource.observe(\.selectedItem, options: [.initial, .new]) { [weak self] dataSource, _ in
            MainActor.assumeIsolated {
                let measureButton = self?.toolbarItemsMap[LKToolBarIdentifier_Measure]?.view as? NSButton
                measureButton?.isEnabled = dataSource.selectedItem != nil
            }
        }

        let toolbar = NSToolbar()
        toolbar.displayMode = .iconAndLabel
        toolbar.sizeMode = .regular
        toolbar.delegate = self
        window.toolbar = toolbar
    }

    // MARK: - NSToolbarDelegate

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            LKToolBarIdentifier_AppInReadMode,
            NSToolbarItem.Identifier.flexibleSpace.rawValue,
            LKToolBarIdentifier_Dimension,
            LKToolBarIdentifier_Rotation,
            LKToolBarIdentifier_Setting,
            NSToolbarItem.Identifier.flexibleSpace.rawValue,
            LKToolBarIdentifier_Scale,
            NSToolbarItem.Identifier.flexibleSpace.rawValue,
            LKToolBarIdentifier_Measure,
        ].map { NSToolbarItem.Identifier($0) }
    }

    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool
    ) -> NSToolbarItem? {
        let identifier = itemIdentifier.rawValue
        if let item = toolbarItemsMap[identifier] {
            return item
        }
        let helper = WindowToolbarHelper.shared
        let item: NSToolbarItem?
        if identifier == LKToolBarIdentifier_AppInReadMode {
            item = helper.makeAppInReadModeItem(with: viewController?.hierarchyDataSource.rawHierarchyInfo?.appInfo)
        } else {
            item = helper.makeToolBarItem(identifier: identifier, preferenceManager: preferenceManager)
        }
        guard let item else { return nil }
        toolbarItemsMap[identifier] = item

        if identifier == LKToolBarIdentifier_Setting {
            item.label = NSLocalizedString("View", comment: "")
            item.target = self
            item.action = #selector(handleSetting(_:))
        } else if identifier == LKToolBarIdentifier_Rotation {
            item.target = self
            item.action = #selector(handleFreeRotation)
        }
        return item
    }

    // MARK: - Events

    @objc private func handleSetting(_ sender: Any?) {
        // The toolbar sends its item's view as the sender.
        guard let button = sender as? NSView else { return }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = false
        popover.contentSize = NSSize(width: AppHelper.isEnglish() ? 270 : 350, height: 260)
        let inspectedAppInfo = viewController?.hierarchyDataSource.rawHierarchyInfo?.appInfo
        popover.contentViewController = MenuPopoverSettingController(
            preferenceManager: preferenceManager,
            isMacTarget: AppHelper.appInfoLooksLikeMacTarget(inspectedAppInfo)
        )
        popover.show(relativeTo: NSRect(origin: .zero, size: button.bounds.size), of: button, preferredEdge: .maxY)
    }

    @objc private func handleFreeRotation() {
        let freeRotation: BoolMessageAttribute = preferenceManager.freeRotation
        freeRotation.setBOOLValue(!freeRotation.currentBOOLValue, ignoreSubscriber: nil)
    }

    // MARK: - AppMenuManagerDelegate

    @objc func appMenuManagerDidSelectDimension() {
        let dimension: IntegerMessageAttribute = preferenceManager.previewDimension
        let target: PreviewDimension = dimension.currentIntegerValue == PreviewDimension.dimension2D.rawValue ? .dimension3D : .dimension2D
        dimension.setIntegerValue(Int(target.rawValue), ignoreSubscriber: nil)
    }

    @objc func appMenuManagerDidSelectZoomIn() {
        stepScale(by: ToolbarRules.step)
    }

    @objc func appMenuManagerDidSelectZoomOut() {
        stepScale(by: -ToolbarRules.step)
    }

    @objc func appMenuManagerDidSelectDecreaseInterspace() {
        stepInterspace(by: -ToolbarRules.step)
    }

    @objc func appMenuManagerDidSelectIncreaseInterspace() {
        stepInterspace(by: ToolbarRules.step)
    }

    @objc func appMenuManagerDidSelectExpansionIndex(_ index: UInt) {
        viewController?.hierarchyDataSource.adjustExpansion(by: Int(index), referenceDict: nil, selectedItem: nil)
    }

    @objc func appMenuManagerDidSelectFilter() {
        viewController?.currentHierarchyView()?.activateSearchBar()
    }

    private func stepScale(by delta: Double) {
        let scale: DoubleMessageAttribute = preferenceManager.previewScale
        let value = ToolbarRules.stepped(
            scale.currentDoubleValue,
            by: delta,
            lower: Double(LookinPreviewMinScale),
            upper: Double(LookinPreviewMaxScale)
        )
        scale.setDoubleValue(value, ignoreSubscriber: nil)
    }

    private func stepInterspace(by delta: Double) {
        let interspace: DoubleMessageAttribute = preferenceManager.zInterspace
        let value = ToolbarRules.stepped(
            interspace.currentDoubleValue,
            by: delta,
            lower: Double(LookinPreviewMinZInterspace),
            upper: Double(LookinPreviewMaxZInterspace)
        )
        interspace.setDoubleValue(value, ignoreSubscriber: nil)
    }
}

/// What the window shows while a document is still importing in the
/// background: an indeterminate spinner and one line of text.
final class ReadLoadingView: BaseView {
    private let indicator = NSProgressIndicator()
    private let titleLabel = TextLabel()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        indicator.isIndeterminate = true
        indicator.style = .spinning
        indicator.controlSize = .regular
        addSubview(indicator)
        indicator.startAnimation(nil)

        titleLabel.textColor = .secondaryLabelColor
        titleLabel.font = NSFont.systemFont(ofSize: 14)
        titleLabel.stringValue = NSLocalizedString("Loading capture…", comment: "")
        addSubview(titleLabel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        indicator.sizeToFit()
        ViewFrameLayout(titleLabel).sizeToFit().x(indicator.frame.maxX + 8).midY(indicator.frame.midY)
        let views: [NSView] = [indicator, titleLabel]
        ViewFrameLayout.groupHorAlign(views)
        ViewFrameLayout.groupMidY(views, bounds.height * 0.5)
    }
}
