//
//  HierarchyView.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit

private let rowHeight: CGFloat = 28

/// Posted with the display item as object to print it in the console;
/// StaticViewController shows the console.
private let showConsoleNotification = Notification.Name("LKAppShowConsoleNotificationName")

/// A row's context menu, which knows the row it belongs to.
private final class HierarchyRowMenu: NSMenu {
    weak var rowView: HierarchyRowView?
}

/// Runs the latest scheduled action once no new one arrived for `delay`.
private final class HierarchyDebouncer {
    private let delay: TimeInterval
    private var pending: DispatchWorkItem?

    init(delay: TimeInterval) {
        self.delay = delay
    }

    func schedule(_ action: @escaping () -> Void) {
        pending?.cancel()
        let item = DispatchWorkItem(block: action)
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    deinit {
        pending?.cancel()
    }
}

@objc protocol HierarchyViewDelegate: NSObjectProtocol {
    @objc(hierarchyView:didSelectItem:)
    func hierarchyView(_ view: HierarchyView!, didSelect item: DisplayItem!)

    @objc(hierarchyView:didDoubleClickItem:)
    func hierarchyView(_ view: HierarchyView!, didDoubleClick item: DisplayItem!)

    @objc(hierarchyView:didHoverAtItem:)
    func hierarchyView(_ view: HierarchyView!, didHoverAt item: DisplayItem!)

    @objc(hierarchyView:needToExpandItem:recursively:)
    func hierarchyView(_ view: HierarchyView!, needToExpand item: DisplayItem!, recursively: Bool)

    @objc(hierarchyView:needToCollapseItem:)
    func hierarchyView(_ view: HierarchyView!, needToCollapse item: DisplayItem!)

    @objc(hierarchyView:needToCollapseChildrenOfItem:)
    func hierarchyView(_ view: HierarchyView!, needToCollapseChildrenOf item: DisplayItem!)

    /// 在底部的搜索框里输入了文字，string 可能为空字符串或 nil
    /// 当用户通过搜索框的关闭按钮、ESC 等方式手动结束搜索时，该方法同样会被调用，参数是 nil
    @objc(hierarchyView:didInputSearchString:)
    func hierarchyView(_ view: HierarchyView!, didInputSearch string: String!)

    @objc(hierarchyView:needToCancelPreviewOfItem:)
    optional func hierarchyView(_ view: HierarchyView!, needToCancelPreviewOf item: DisplayItem!)

    @objc(hierarchyView:needToShowPreviewOfItem:)
    optional func hierarchyView(_ view: HierarchyView!, needToShowPreviewOf item: DisplayItem!)
}

@objc(LKHierarchyView)
@objcMembers
class HierarchyView: BaseView {
    let tableView: TableView!
    /// The filter field under the rows. The DEBUG UI snapshots type into it.
    let searchTextFieldView: TextFieldView!
    var dataSource: HierarchyDataSource!
    /// Phase A 引入:由 owner(StaticHierarchyController / StaticViewController 链路)注入的 per-instance update manager(weak)。
    /// 若 nil 则 fallback 到 +sharedInstance,以保留 read-only / archive workspace 的 legacy 行为。
    weak var asyncUpdateManager: StaticAsyncUpdateManager?
    weak var delegate: HierarchyViewDelegate?

    private let backgroundEffectView = VisualEffectView()
    private let guidesShapeLayer = CAShapeLayer()
    private var emptyDataLabel: TextLabel?
    private var displayItems: [DisplayItem] = []
    private var minIndentLevel = 0
    private var observations: [NSKeyValueObservation] = []
    private var textChangeObserver: NSObjectProtocol?
    private let searchDebouncer = HierarchyDebouncer(delay: 0.5)
    private let guidesDebouncer = HierarchyDebouncer(delay: 0.75)

    init!(dataSource: HierarchyDataSource!) {
        self.dataSource = dataSource
        tableView = TableView()
        searchTextFieldView = TextFieldView()
        super.init(frame: .zero)

        backgroundEffectView.material = .sidebar
        backgroundEffectView.blendingMode = .behindWindow
        backgroundEffectView.state = .active
        addSubview(backgroundEffectView)

        tableView.adjustsSelectionAutomatically = false
        tableView.delegate = self
        tableView.dataSource = self
        addSubview(tableView)
        tableView.reloadData()

        guidesShapeLayer.lineWidth = 1
        guidesShapeLayer.isHidden = true
        guidesShapeLayer.removeImplicitAnimations()
        guidesShapeLayer.lineDashPattern = [2, 2]
        tableView.contentView.documentView?.layer?.addSublayer(guidesShapeLayer)

        setUpSearchField()
        observe(dataSource)
        updateColors()
    }

    required init?(coder _: NSCoder) {
        fatalError("HierarchyView is not loaded from archives")
    }

    deinit {
        if let textChangeObserver {
            NotificationCenter.default.removeObserver(textChangeObserver)
        }
    }

    override func layout() {
        super.layout()
        HierarchyFrameLayout(backgroundEffectView).fullFrame()
        HierarchyFrameLayout(searchTextFieldView).fullWidth().height(25).bottom(0)

        HierarchyFrameLayout(tableView).fullFrame().y(searchTextFieldView.frame.minY)
        HierarchyFrameLayout(tableView).fullFrame().toMaxY(searchTextFieldView.frame.minY)

        HierarchyFrameLayout(guidesShapeLayer).frame(.zero)

        if let emptyDataLabel, !emptyDataLabel.isHidden, emptyDataLabel.alphaValue > 0 {
            HierarchyFrameLayout(emptyDataLabel).sizeToFit().centerAlign()
        }
    }

    override func updateColors() {
        super.updateColors()
        guidesShapeLayer.strokeColor = isDarkMode()
            ? NSColor(red: 1, green: 1, blue: 1, alpha: 0.3).cgColor
            : NSColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor
    }

    @objc(scrollToMakeItemVisible:)
    func scroll(toMakeItemVisible item: DisplayItem!) {
        guard let item, let row = displayItems.firstIndex(where: { $0 === item }) else {
            return
        }
        tableView.scrollRowToVisible(row)
    }

    /// 激活搜索框
    func activateSearchBar() {
        searchTextFieldView.textField.becomeFirstResponder()
    }

    // MARK: - Setup

    private func setUpSearchField() {
        let textField = searchTextFieldView.textField
        textField.placeholderString = NSLocalizedString("Filter", comment: "")
        searchTextFieldView.initCloseButton()
        searchTextFieldView.insets = NSEdgeInsets(top: 0, left: 7, bottom: 0, right: 1)
        textField.font = .systemFont(ofSize: 13)
        textField.usesSingleLineMode = true
        textField.lineBreakMode = .byTruncatingTail
        textField.drawsBackground = false
        textField.isBordered = false
        textField.focusRingType = .none
        searchTextFieldView.borderPosition = .top
        searchTextFieldView.borderColors = TwoColors(
            colorInLightMode: NSColor(red: 200 / 255, green: 201 / 255, blue: 202 / 255, alpha: 1),
            colorInDarkMode: NSColor(red: 67 / 255, green: 68 / 255, blue: 69 / 255, alpha: 1)
        )
        searchTextFieldView.image = NSImage(named: "icon_hierarchy_search")
        textField.delegate = self
        addSubview(searchTextFieldView)

        // What the user types reaches the delegate 0.5 s after the last
        // keystroke, without any whitespace.
        textChangeObserver = NotificationCenter.default.addObserver(
            forName: NSControl.textDidChangeNotification,
            object: textField,
            queue: nil
        ) { [weak self] _ in
            self?.searchDebouncer.schedule { [weak self] in
                self?.deliverSearchString()
            }
        }

        searchTextFieldView.closeButton?.target = self
        searchTextFieldView.closeButton?.action = #selector(handleSearchCloseButton)
    }

    private func observe(_ dataSource: HierarchyDataSource?) {
        var observations = [
            // Reads the insets from the scroll view: NSEdgeInsets does not
            // bridge from the NSValue KVO delivers, so change.newValue is
            // always nil and the title bar height was never passed on.
            tableView.observe(\.contentInsets, options: [.initial, .new]) { tableView, _ in
                MainActor.assumeIsolated {
                    let top = tableView.contentInsets.top
                    let navigation = NavigationManager.shared
                    if navigation.windowTitleBarHeight != top {
                        navigation.windowTitleBarHeight = top
                    }
                }
            },
        ]
        guard let dataSource else {
            self.observations = observations
            return
        }

        observations.append(dataSource.observe(\.selectedItem, options: [.initial]) { [weak self] dataSource, _ in
            guard let self else { return }
            tableView.reloadDataWithOffset()
            scroll(toMakeItemVisible: dataSource.selectedItem)
        })

        var lastHoveredItem: DisplayItem?
        var hasHoveredItem = false
        observations.append(dataSource.observe(\.hoveredItem, options: [.initial]) { [weak self] dataSource, _ in
            let item = dataSource.hoveredItem
            if hasHoveredItem, item === lastHoveredItem {
                return
            }
            hasHoveredItem = true
            lastHoveredItem = item
            self?.updateGuides(withHoveredItem: item)
        })

        observations.append(dataSource.observe(\.displayingFlatItems, options: [.initial]) { [weak self] dataSource, _ in
            guard let self else { return }
            render(dataSource.displayingFlatItems ?? [])
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                updateGuides(withHoveredItem: self.dataSource.hoveredItem)
            }
            guidesDebouncer.schedule { [weak self] in
                self?.bringGuidesLayerToFront()
            }
        })

        observations.append(dataSource.observe(\.state, options: [.initial]) { [weak self] dataSource, _ in
            guard let self else { return }
            // Hide the filter while focusing, so the hierarchy is never in
            // both states at once.
            let isFocus = dataSource.state == .focus
            searchTextFieldView.isHidden = isFocus
            if isFocus, !searchTextFieldView.textField.stringValue.isEmpty {
                searchTextFieldView.textField.stringValue = ""
                window?.makeFirstResponder(nil)
            }
        })
        self.observations = observations
    }

    // MARK: - Rendering

    private func render(_ items: [DisplayItem]) {
        displayItems = items
        minIndentLevel = items.map { $0.indentLevel() }.min() ?? 0

        tableView.reloadDataWithOffset()

        if items.isEmpty {
            let label: TextLabel
            if let emptyDataLabel {
                label = emptyDataLabel
            } else {
                label = TextLabel()
                label.font = .systemFont(ofSize: 15)
                label.stringValue = NSLocalizedString("No Filter Results", comment: "")
                addSubview(label)
                emptyDataLabel = label
            }
            label.isHidden = false
            needsLayout = true
        } else {
            emptyDataLabel?.isHidden = true
        }
    }

    private func deliverSearchString() {
        let raw = searchTextFieldView.textField.stringValue
        let string = raw.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        delegate?.hierarchyView(self, didInputSearch: string)
    }

    private func exitAndClearSearch() {
        searchTextFieldView.textField.stringValue = ""
        window?.makeFirstResponder(nil)
        delegate?.hierarchyView(self, didInputSearch: nil)
    }

    // MARK: - Guides

    func updateGuides(withHoveredItem item: DisplayItem!) {
        guard let item, let rootItem = item.super,
              let rootRow = displayItems.firstIndex(where: { $0 === rootItem })
        else {
            guidesShapeLayer.isHidden = true
            return
        }
        let childrenItems = (rootItem.subitems ?? []).filter { child in
            displayItems.contains { $0 === child }
        }
        guard let lastChild = childrenItems.last,
              let lastChildRow = displayItems.firstIndex(where: { $0 === lastChild })
        else {
            guidesShapeLayer.isHidden = true
            return
        }

        let rootX = HierarchyRowView.dislosureMidX(withIndentLevel: UInt(bitPattern: rootItem.indentLevel() - minIndentLevel))
        let rootY = rowHeight * CGFloat(rootRow) + rowHeight / 2
        let rootMaxY = CGFloat(lastChildRow) * rowHeight + rowHeight / 2

        let path = CGMutablePath()
        path.move(to: CGPoint(x: rootX, y: rootY))
        path.addLine(to: CGPoint(x: rootX, y: rootMaxY))
        for child in childrenItems {
            guard let row = displayItems.firstIndex(where: { $0 === child }) else {
                continue
            }
            let childY = CGFloat(row) * rowHeight + rowHeight / 2
            path.move(to: CGPoint(x: rootX, y: childY))
            path.addLine(to: CGPoint(x: child.isExpandable ? rootX + 10 : rootX + 28, y: childY))
        }
        guidesShapeLayer.path = path
        guidesShapeLayer.isHidden = false
    }

    private func bringGuidesLayerToFront() {
        guidesShapeLayer.removeFromSuperlayer()
        tableView.contentView.documentView?.layer?.addSublayer(guidesShapeLayer)
    }

    fileprivate func item(atRow row: Int) -> DisplayItem? {
        displayItems.indices.contains(row) ? displayItems[row] : nil
    }

    fileprivate func displayItem(of menuItem: NSMenuItem) -> DisplayItem? {
        (menuItem.menu as? HierarchyRowMenu)?.rowView?.displayItem
    }

    // MARK: - Menu and control actions

    @objc private func handleSearchCloseButton() {
        exitAndClearSearch()
    }

    @objc private func handleDisclosureButton(_ button: NSButton) {
        guard let item = item(atRow: button.tag), item.isExpandable else {
            assertionFailure("the disclosure button of a row that cannot expand")
            return
        }
        if item.isExpanded {
            delegate?.hierarchyView(self, needToCollapse: item)
        } else {
            delegate?.hierarchyView(self, needToExpand: item, recursively: false)
        }
    }

    @objc fileprivate func handlePrintItem(_ menuItem: NSMenuItem) {
        NotificationCenter.default.post(name: showConsoleNotification, object: displayItem(of: menuItem))
    }

    @objc fileprivate func handleReloadSelfItem(_ menuItem: NSMenuItem) {
        guard let item = displayItem(of: menuItem) else { return }
        asyncUpdateManager?.reloadSingleDisplayItem(item)
    }

    @objc fileprivate func handleReloadSelfAndChildrenItem(_ menuItem: NSMenuItem) {
        guard let item = displayItem(of: menuItem) else { return }
        asyncUpdateManager?.reloadDisplayItemAndChildren(item)
    }

    @objc fileprivate func handleFocusCurrentItem(_ menuItem: NSMenuItem) {
        guard let item = displayItem(of: menuItem) else {
            assertionFailure("a menu without its row")
            return
        }
        dataSource.focus(item)
    }

    @objc fileprivate func handleJumpToDisplayItem(_ menuItem: NSMenuItem) {
        dataSource.selectAndRevealItem(menuItem.representedObject as? DisplayItem)
    }

    @objc fileprivate func handleShowPreview(_ menuItem: NSMenuItem) {
        delegate?.hierarchyView?(self, needToShowPreviewOf: displayItem(of: menuItem))
    }

    @objc fileprivate func handleCancelPreview(_ menuItem: NSMenuItem) {
        delegate?.hierarchyView?(self, needToCancelPreviewOf: displayItem(of: menuItem))
    }

    @objc fileprivate func handleExportScreenshot(_ menuItem: NSMenuItem) {
        guard let item = displayItem(of: menuItem) else { return }
        ExportManager.exportScreenshot(with: item)
    }

    @objc fileprivate func handleCopyDisplayItemName(_ menuItem: NSMenuItem) {
        guard let string = menuItem.representedObject as? String else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([string as NSString])
    }

    @objc fileprivate func handleExpandRecursively(_ menuItem: NSMenuItem) {
        let item = displayItem(of: menuItem)
        assert(item != nil)
        delegate?.hierarchyView(self, needToExpand: item, recursively: true)
    }

    @objc fileprivate func handleCollapseChildren(_ menuItem: NSMenuItem) {
        let item = displayItem(of: menuItem)
        assert(item != nil)
        delegate?.hierarchyView(self, needToCollapseChildrenOf: item)
    }

    @objc fileprivate func handleHideScreenshotForever() {
        AppHelper.openCustomConfigWebsite()
    }

    fileprivate func menuItem(_ title: String, action: Selector?, representedObject: Any? = nil) -> NSMenuItem {
        let item = NSMenuItem()
        if let action {
            item.target = self
            item.action = action
        }
        item.title = title
        item.representedObject = representedObject
        return item
    }

    fileprivate func jumpMenuItem(_ title: String, target: DisplayItem) -> NSMenuItem {
        menuItem(title, action: #selector(handleJumpToDisplayItem(_:)), representedObject: target)
    }
}

// MARK: - TableViewDataSource / TableViewDelegate

extension HierarchyView: TableViewDataSource, TableViewDelegate {
    func tableView(_: TableView!, didHoverAtRow row: Int) {
        // nil when the mouse is not over a row.
        delegate?.hierarchyView(self, didHoverAt: item(atRow: row))
    }

    func tableView(_: NSTableView, heightOfRow _: Int) -> CGFloat {
        rowHeight
    }

    func numberOfRows(in _: NSTableView) -> Int {
        displayItems.count
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let item = item(atRow: row) else {
            assertionFailure("no item at row \(row)")
            return TableBlankRowView()
        }
        let rowView: HierarchyRowView
        if let reused = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("cell"), owner: self) as? HierarchyRowView {
            rowView = reused
        } else {
            rowView = HierarchyRowView(dataSource: dataSource)
            rowView.disclosureButton.target = self
            rowView.disclosureButton.action = #selector(handleDisclosureButton(_:))
            rowView.identifier = NSUserInterfaceItemIdentifier("cell")

            let menu = HierarchyRowMenu()
            menu.autoenablesItems = true
            menu.rowView = rowView
            menu.delegate = self
            rowView.menu = menu
        }
        rowView.minIndentLevel = minIndentLevel
        rowView.displayItem = item
        rowView.disclosureButton.tag = row
        return rowView
    }

    func tableView(_: TableView!, didSelectRow row: Int) {
        guard let item = item(atRow: row) else {
            return
        }
        delegate?.hierarchyView(self, didSelect: item)
        DispatchQueue.main.async { [weak self] in
            self?.bringGuidesLayerToFront()
        }
    }

    func tableView(_: TableView!, didDoubleClickAtRow row: Int) {
        guard let item = item(atRow: row) else {
            return
        }
        delegate?.hierarchyView(self, didDoubleClick: item)
    }
}

// MARK: - NSMenuDelegate

extension HierarchyView: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard let displayItem = (menu as? HierarchyRowMenu)?.rowView?.displayItem else {
            return
        }
        let isReadOnly = dataSource.isReadOnly()

        if !displayItem.isUserCustom() {
            menu.addItem(menuItem(NSLocalizedString("Focus", comment: ""), action: #selector(handleFocusCurrentItem(_:))))
            if !isReadOnly {
                menu.addItem(menuItem(NSLocalizedString("Print", comment: ""), action: #selector(handlePrintItem(_:))))
            }
            menu.addItem(.separator())
            if !isReadOnly {
                let isUpdating = asyncUpdateManager?.isUpdating() ?? false
                menu.addItem(menuItem(
                    NSLocalizedString("Reload layer", comment: ""),
                    action: isUpdating ? nil : #selector(handleReloadSelfItem(_:))
                ))
                menu.addItem(menuItem(
                    NSLocalizedString("Reload layer and its children", comment: ""),
                    action: isUpdating ? nil : #selector(handleReloadSelfAndChildrenItem(_:))
                ))
            }
        }

        // Copy text: the class name (unless it is a short system class such
        // as UIView or CALayer), the host controllers and the ivar names.
        var stringsToCopy: [String] = []
        let title = displayItem.title()
        if !((title.hasPrefix("UI") || title.hasPrefix("CA")) && (title as NSString).length < 10) {
            stringsToCopy.append(title)
        }
        if let name = displayItem.hostViewControllerObject?.simpleDemangledClassName(), !name.isEmpty {
            stringsToCopy.append(name)
        }
        if let name = displayItem.hostWindowControllerObject?.simpleDemangledClassName(), !name.isEmpty {
            stringsToCopy.append(name)
        }
        let ivarTraces = displayItem.displayingObject()?.ivarTraces ?? []
        if !ivarTraces.isEmpty {
            let ivarNames = ivarTraces.map { trace -> String in
                let name = trace.ivarName ?? ""
                return name.hasPrefix("_") ? String(name.dropFirst()) : name
            }
            // Unique, in set order, as before.
            stringsToCopy += NSSet(array: ivarNames).allObjects.compactMap { $0 as? String }
        }
        for (index, string) in stringsToCopy.enumerated() {
            if index == 0 {
                menu.addItem(.separator())
            }
            guard !string.isEmpty else {
                assertionFailure("HierarchyView, menuNeedsUpdate, stringsToCopy length is zero.")
                continue
            }
            menu.addItem(menuItem(
                String(format: NSLocalizedString("Copy text \"%@\"", comment: ""), string),
                action: #selector(handleCopyDisplayItemName(_:)),
                representedObject: string
            ))
        }

        let backingLayerItems = dataSource.swiftUIBackingLayerItems(for: displayItem) ?? []
        let swiftUISourceItem = dataSource.swiftUISourceItem(forLayerItem: displayItem)
        if !backingLayerItems.isEmpty || swiftUISourceItem != nil {
            menu.addItem(.separator())
            let jumpTitle = NSLocalizedString("Jump to backing CALayer", comment: "")
            if backingLayerItems.count == 1 {
                menu.addItem(jumpMenuItem(jumpTitle, target: backingLayerItems[0]))
            } else if backingLayerItems.count > 1 {
                let submenuItem = NSMenuItem()
                submenuItem.title = jumpTitle
                let submenu = NSMenu()
                for item in backingLayerItems {
                    let itemTitle = "\(item.title()) \(item.layerObject?.memoryAddress ?? "")"
                    submenu.addItem(jumpMenuItem(itemTitle, target: item))
                }
                submenuItem.submenu = submenu
                menu.addItem(submenuItem)
            }
            if let swiftUISourceItem {
                menu.addItem(jumpMenuItem(NSLocalizedString("Jump to SwiftUI node", comment: ""), target: swiftUISourceItem))
            }
        }

        menu.addItem(.separator())

        if displayItem.isExpandable {
            menu.addItem(menuItem(NSLocalizedString("Expand recursively", comment: ""), action: #selector(handleExpandRecursively(_:))))
            menu.addItem(menuItem(NSLocalizedString("Collapse children", comment: ""), action: #selector(handleCollapseChildren(_:))))
        }

        // Show and hide the screenshot.
        menu.addItem(.separator())

        if displayItem.hasPreviewBoxAbility() {
            if displayItem.inNoPreviewHierarchy {
                let title = displayItem.doNotFetchScreenshotReason == .fetchScreenshotPermitted
                    ? NSLocalizedString("Show screenshot", comment: "")
                    : NSLocalizedString("Show layer border", comment: "")
                menu.addItem(menuItem(title, action: #selector(handleShowPreview(_:))))
            } else {
                menu.addItem(menuItem(NSLocalizedString("Hide screenshot this time", comment: ""), action: #selector(handleCancelPreview(_:))))
            }
        }

        if !displayItem.isUserCustom(), !displayItem.inNoPreviewHierarchy {
            menu.addItem(menuItem(NSLocalizedString("Hide screenshot forever…", comment: ""), action: #selector(handleHideScreenshotForever)))
        }

        menu.addItem(.separator())

        if displayItem.groupScreenshot != nil {
            menu.addItem(menuItem(NSLocalizedString("Export screenshot…", comment: ""), action: #selector(handleExportScreenshot(_:))))
        }
    }
}

// MARK: - NSTextFieldDelegate

extension HierarchyView: NSTextFieldDelegate {
    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard commandSelector == #selector(NSResponder.cancelOperation(_:)) else {
            return false
        }
        // Escape.
        exitAndClearSearch()
        return true
    }
}
