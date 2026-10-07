//
//  LKHierarchyController.swift
//  LookInside
//
//  Created by Li Kai on 2019/5/12.
//  https://lookin.work
//

import AppKit

@objc(LKHierarchyController)
@objcMembers
class LKHierarchyController: LKBaseViewController, LKHierarchyViewDelegate {
    private(set) var dataSource: LKHierarchyDataSource!
    private(set) var hierarchyView: LKHierarchyView!

    init!(dataSource: LKHierarchyDataSource!) {
        let hierarchyView = LKHierarchyView(dataSource: dataSource)
        self.dataSource = dataSource
        self.hierarchyView = hierarchyView
        super.init(containerView: hierarchyView)
        hierarchyView?.delegate = self
    }

    required init?(coder _: NSCoder) {
        fatalError("LKHierarchyController is not loaded from archives")
    }

    func currentSelectedRowView() -> NSView! {
        guard let selectedItem = dataSource.selectedItem,
              let row = dataSource.displayingFlatItems.firstIndex(where: { $0 === selectedItem })
        else {
            return nil
        }
        return hierarchyView.tableView.tableView.rowView(atRow: row, makeIfNecessary: false)
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if dataSource.keyDown(event) {
            return
        }
        super.keyDown(with: event)
    }

    // MARK: - LKHierarchyViewDelegate

    @objc(hierarchyView:didSelectItem:)
    func hierarchyView(_: LKHierarchyView!, didSelect item: LookinDisplayItem!) {
        dataSource.selectedItem = item
    }

    @objc(hierarchyView:didDoubleClickItem:)
    func hierarchyView(_: LKHierarchyView!, didDoubleClick item: LookinDisplayItem!) {
        switch LKPreferenceManager.shared.doubleClickBehavior {
        case .collapse:
            guard item.isExpandable else {
                return
            }
            if item.isExpanded {
                dataSource.collapse(item)
            } else {
                dataSource.expand(item)
            }
        case .focus:
            dataSource.focus(item)
        @unknown default:
            assertionFailure("unknown double-click behavior")
        }
    }

    /// `item` is nil when the mouse leaves the rows.
    @objc(hierarchyView:didHoverAtItem:)
    func hierarchyView(_: LKHierarchyView!, didHoverAt item: LookinDisplayItem!) {
        dataSource.hoveredItem = item
    }

    @objc(hierarchyView:needToCollapseItem:)
    func hierarchyView(_: LKHierarchyView!, needToCollapse item: LookinDisplayItem!) {
        dataSource.collapse(item)
    }

    @objc(hierarchyView:needToCollapseChildrenOfItem:)
    func hierarchyView(_: LKHierarchyView!, needToCollapseChildrenOf item: LookinDisplayItem!) {
        dataSource.collapseAllChildren(of: item)
    }

    @objc(hierarchyView:needToExpandItem:recursively:)
    func hierarchyView(_: LKHierarchyView!, needToExpand item: LookinDisplayItem!, recursively: Bool) {
        if recursively {
            dataSource.expandItemsRooted(by: item)
        } else {
            dataSource.expand(item)
        }
    }

    @objc(hierarchyView:didInputSearchString:)
    func hierarchyView(_: LKHierarchyView!, didInputSearch string: String!) {
        NSLog("search string:%@", string ?? "(null)")
        if let string, !string.isEmpty {
            dataSource.search(with: string)
            return
        }
        dataSource.endSearch()
        if dataSource.selectedItem != nil {
            // Scroll back to the selected item once the rows are restored.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                hierarchyView.scroll(toMakeItemVisible: dataSource.selectedItem)
            }
        }
    }
}
