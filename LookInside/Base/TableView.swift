//
//  TableView.swift
//  LookInside
//
//  Created by Li Kai on 2019/4/20.
//  https://lookin.work
//

import AppKit

/// The table inside an `TableView`. Arrow keys go to the scroll view's
/// responder chain instead of moving NSTableView's own selection.
private final class KeyForwardingTableView: NSTableView {
    weak var responder: NSResponder?

    override func keyDown(with event: NSEvent) {
        responder?.keyDown(with: event)
    }
}

/// Every row argument may be -1.
@objc(LKTableViewDelegate)
protocol TableViewDelegate: NSTableViewDelegate {
    @objc(tableView:didSelectRow:)
    optional func tableView(_ tableView: TableView!, didSelectRow row: Int)
    @objc(tableView:didHoverAtRow:)
    optional func tableView(_ tableView: TableView!, didHoverAtRow row: Int)
    @objc(tableView:didDoubleClickAtRow:)
    optional func tableView(_ tableView: TableView!, didDoubleClickAtRow row: Int)
    /// A click on the blank area below the rows.
    @objc(tableViewDidClickBlankArea:)
    optional func tableViewDidClickBlankArea(_ tableView: TableView!)
}

@objc(LKTableViewDataSource)
protocol TableViewDataSource: NSTableViewDataSource {}

@objc(LKTableView)
class TableView: NSScrollView {
    @objc let tableView: NSTableView!

    /// Defaults to true.
    @objc var canScrollHorizontally: Bool = true {
        didSet {
            hasHorizontalScroller = canScrollHorizontally
            if !canScrollHorizontally {
                horizontalScrollWidthManager = nil
            }
        }
    }

    @objc weak var delegate: TableViewDelegate?
    @objc weak var dataSource: TableViewDataSource?

    /// Defaults to true.
    @objc var adjustsSelectionAutomatically: Bool = true
    /// Defaults to true.
    @objc var adjustsHoverAutomatically: Bool = true

    private var horizontalScrollWidthManager: TableViewHorizontalScrollWidthManager?

    /// -1 when no row is hovered.
    private var hoveredRow: Int = -1 {
        didSet {
            guard hoveredRow != oldValue else {
                return
            }
            hoveredRowDidChange(from: oldValue)
        }
    }

    /// -1 when no row is selected.
    private var selectedRow: Int = -1

    @objc override init(frame frameRect: NSRect) {
        let tableView = KeyForwardingTableView()
        self.tableView = tableView
        super.init(frame: frameRect)

        backgroundColor = .clear
        drawsBackground = false
        hasVerticalScroller = true
        autohidesScrollers = true

        tableView.responder = self
        tableView.style = .plain
        tableView.delegate = self
        tableView.dataSource = self
        tableView.wantsLayer = true
        tableView.backgroundColor = .clear
        tableView.headerView = nil
        tableView.focusRingType = .none
        tableView.selectionHighlightStyle = .none
        tableView.intercellSpacing = .zero
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("column"))
        column.isEditable = false
        tableView.addTableColumn(column)
        contentView.documentView = tableView
        tableView.target = self
        tableView.action = #selector(handleTableViewDefaultAction)
        tableView.doubleAction = #selector(handleDoubleClickTableView)

        // Initializers skip the property observer.
        hasHorizontalScroller = true
    }

    required init?(coder _: NSCoder) {
        fatalError("TableView is not loaded from archives")
    }

    override func layout() {
        super.layout()
        let tableLayout = HierarchyFrameLayout(tableView)
        guard canScrollHorizontally, let manager = horizontalScrollWidthManager else {
            tableLayout.fullWidth()
            return
        }
        if manager.maxRowWidth <= frame.width {
            tableLayout.fullWidth()
        } else {
            tableLayout.width(manager.maxRowWidth + 20)
        }
    }

    @objc func reloadData() {
        setSelectedRow(-1)

        horizontalScrollWidthManager = nil
        if canScrollHorizontally {
            let manager = TableViewHorizontalScrollWidthManager()
            manager.didReachNewMaxWidth = { [weak self] in
                self?.handleRowViewMaxWidthChange()
            }
            horizontalScrollWidthManager = manager
        }

        tableView.reloadData()
    }

    /// Reloads but keeps the scroll position; `reloadData()` resets it.
    @objc func reloadDataWithOffset() {
        let offset = documentVisibleRect.origin
        reloadData()
        needsLayout = true
        layoutSubtreeIfNeeded()
        documentView?.scroll(offset)
    }

    @objc(scrollRowToVisible:)
    func scrollRowToVisible(_ row: Int) {
        tableView.scrollRowToVisible(row)
    }

    private func handleRowViewMaxWidthChange() {
        guard canScrollHorizontally, let manager = horizontalScrollWidthManager else {
            return
        }
        guard manager.maxRowWidth > frame.width else {
            return
        }
        HierarchyFrameLayout(tableView).width(manager.maxRowWidth + 20)
    }

    // MARK: - Event handlers

    /// Runs on mouse-up, after tableViewSelectionIsChanging(_:) ran on
    /// mouse-down.
    @objc private func handleTableViewDefaultAction() {
        let clickedRow = tableView.clickedRow
        if clickedRow < 0, let delegate, delegate.responds(to: #selector(TableViewDelegate.tableViewDidClickBlankArea(_:))) {
            delegate.tableViewDidClickBlankArea?(self)
        }
    }

    @objc private func handleDoubleClickTableView() {
        let clickedRow = tableView.clickedRow
        delegate?.tableView?(self, didDoubleClickAtRow: clickedRow)
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard adjustsHoverAutomatically else {
            return
        }
        hoveredRow = row(at: event)
    }

    /// A row view's `mouseExited(with:)` reaches here through its `super`
    /// call when the mouse moves from one row to another.
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard adjustsHoverAutomatically else {
            return
        }
        hoveredRow = row(at: event)
    }

    private func row(at event: NSEvent) -> Int {
        let point = tableView.convert(event.locationInWindow, from: nil)
        return tableView.row(at: point)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    // MARK: - Hover and selection

    private func lkRowView(at row: Int) -> TableRowView? {
        guard row >= 0, row < tableView.numberOfRows else {
            return nil
        }
        return tableView.rowView(atRow: row, makeIfNecessary: false) as? TableRowView
    }

    private func hoveredRowDidChange(from previousRow: Int) {
        lkRowView(at: previousRow)?.isHovered = false

        if hoveredRow >= 0, hoveredRow < tableView.numberOfRows {
            let canHover = delegate?.tableView?(tableView, shouldSelectRow: hoveredRow) ?? true
            if canHover {
                lkRowView(at: hoveredRow)?.isHovered = true
            }
        }
        delegate?.tableView?(self, didHoverAtRow: hoveredRow)
    }

    private func setSelectedRow(_ row: Int) {
        guard adjustsSelectionAutomatically, selectedRow != row else {
            return
        }
        let previousRow = selectedRow
        selectedRow = row

        lkRowView(at: previousRow)?.isRowSelected = false

        if row >= 0, row < tableView.numberOfRows {
            lkRowView(at: row)?.isRowSelected = true
            delegate?.tableView?(self, didSelectRow: row)
        }
    }
}

// MARK: - NSTableViewDataSource / NSTableViewDelegate

extension TableView: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        // Asks the delegate whether it answers, then asks the data source,
        // as the Objective-C version did; both are the same object for every
        // caller.
        guard let delegate, delegate.responds(to: #selector(NSTableViewDataSource.numberOfRows(in:))) else {
            return 0
        }
        return dataSource?.numberOfRows?(in: tableView) ?? 0
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        delegate?.tableView?(tableView, heightOfRow: row) ?? 0
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let delegate, delegate.responds(to: #selector(NSTableViewDelegate.tableView(_:rowViewForRow:))) else {
            return nil
        }
        let rowView = delegate.tableView?(tableView, rowViewForRow: row)
        if let rowView = rowView as? TableRowView {
            rowView.isHovered = (hoveredRow == row)
            if adjustsSelectionAutomatically {
                rowView.isRowSelected = (selectedRow == row)
            }
            if canScrollHorizontally {
                rowView.horizontalScrollWidthManager = horizontalScrollWidthManager
            }
        }
        return rowView
    }

    func tableView(_: NSTableView, viewFor _: NSTableColumn?, row _: Int) -> NSView? {
        nil
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        delegate?.tableView?(tableView, shouldSelectRow: row) ?? true
    }

    func tableViewSelectionIsChanging(_: Notification) {
        let row = tableView.selectedRow
        guard row >= 0 else {
            return
        }
        setSelectedRow(row)

        if !adjustsSelectionAutomatically {
            delegate?.tableView?(self, didSelectRow: row)
        }

        // Clear NSTableView's own selection so that clicking the same row
        // again still reports it: after the user selects row 10 here and
        // row 20 in the preview, NSTableView would otherwise still think 10
        // is selected and skip the change.
        tableView.deselectRow(row)
    }
}
