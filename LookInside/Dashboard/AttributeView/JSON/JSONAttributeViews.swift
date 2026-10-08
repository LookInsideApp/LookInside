//
//  JSONAttributeViews.swift
//  LookInside
//
//  Created by likai.123 on 2023/11/30.
//
//  A JSON attribute as a collapsible tree: inline on the card, and in a
//  window of its own.
//

import AppKit

/// The JSON tree rows of the card, flush with the card's left edge.
private final class JSONAttributeContentRowView: OutlineRowView {
    override class func insetLeft() -> CGFloat {
        0
    }
}

/// The tree of rows shared by the card and the window.
private final class JSONAttributeTree {
    var rootItems: [JSONAttributeItem]?
    private(set) var flatItems: [JSONAttributeItem] = []

    func render(json: String?) {
        rootItems = JSONAttributeItem.rootItems(fromJSON: json)
        rebuild()
    }

    func rebuild() {
        flatItems = JSONAttributeItem.flatItems(of: rootItems)
    }

    func item(at row: Int) -> JSONAttributeItem? {
        flatItems.indices.contains(row) ? flatItems[row] : nil
    }

    /// Fills a row with `item`: title, description, indentation and
    /// disclosure state.
    static func configure(_ view: OutlineRowView, row: Int, with item: JSONAttributeItem) {
        view.titleLabel.stringValue = item.titleText ?? ""
        view.subtitleLabel.stringValue = item.desc ?? ""
        view.disclosureButton.tag = row
        view.indentLevel = UInt(item.indentation)
        if item.subItems.isEmpty {
            view.status = .notExpandable
        } else {
            view.status = item.expanded ? .expanded : .collapsed
        }
        view.needsLayout = true
    }

    /// Toggles the item of the row whose disclosure button was clicked.
    func toggle(row: Int) -> Bool {
        guard let item = item(at: row) else { return false }
        item.expanded.toggle()
        rebuild()
        return true
    }
}

/// The tree on a Dashboard card.
@objc(LKJSONAttributeContentView)
final class JSONAttributeContentView: BaseView, TableViewDelegate, TableViewDataSource {
    private static let rowIdentifier = NSUserInterfaceItemIdentifier("myView")

    private let tableView = TableView()
    private let tree = JSONAttributeTree()
    private let rowHeight: CGFloat
    /// Never set: the rows use the small font even in the big-font layout,
    /// as they always have.
    private let useBigFont = false

    /// Called after a row is expanded or collapsed.
    var didReloadData: (() -> Void)?

    init(bigFont: Bool) {
        rowHeight = bigFont ? 25 : 20
        super.init(frame: .zero)
        tableView.drawsBackground = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.adjustsSelectionAutomatically = false
        tableView.adjustsHoverAutomatically = false
        tableView.automaticallyAdjustsContentInsets = false
        tableView.contentInsets = bigFont ? NSEdgeInsets(top: 5, left: 0, bottom: 5, right: 0) : NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        addSubview(tableView)
    }

    @available(*, unavailable)
    override init(frame _: NSRect) {
        fatalError("use init(bigFont:)")
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        tableView.dashboardLayout.fullFrame()
    }

    func render(json: String?) {
        tree.render(json: json)
        tableView.reloadData()
    }

    func queryContentHeight() -> CGFloat {
        CGFloat(tree.flatItems.count) * rowHeight
    }

    // MARK: - TableView

    func numberOfRows(in _: NSTableView) -> Int {
        tree.flatItems.count
    }

    func tableView(_: NSTableView, heightOfRow _: Int) -> CGFloat {
        rowHeight
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let item = tree.item(at: row) else {
            return TableBlankRowView()
        }
        let view: OutlineRowView
        if let reused = tableView.makeView(withIdentifier: Self.rowIdentifier, owner: self) as? OutlineRowView {
            view = reused
        } else {
            view = JSONAttributeContentRowView(compactUI: true)
            view.titleLabel.textColor = .secondaryLabelColor
            let fontSize: CGFloat = useBigFont ? 14 : 12
            view.titleLabel.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: .regular)
            view.subtitleLabel.font = .monospacedDigitSystemFont(ofSize: fontSize, weight: .regular)
            view.titleLabel.isSelectable = true
            view.subtitleLabel.textColor = .labelColor
            view.subtitleLabel.isSelectable = true
            view.disclosureButton.target = self
            view.disclosureButton.action = #selector(handleExpand(_:))
            view.identifier = Self.rowIdentifier
        }
        JSONAttributeTree.configure(view, row: row, with: item)
        return view
    }

    @objc private func handleExpand(_ button: NSButton) {
        guard tree.toggle(row: button.tag) else { return }
        tableView.reloadData()
        didReloadData?()
    }
}

/// A JSON attribute on a card; the section's pop-out button shows it in a
/// window.
@objc(LKDashboardAttributeJsonView)
final class DashboardAttributeJSONView: DashboardAttributeView {
    private let contentView = JSONAttributeContentView(bigFont: false)

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.cornerRadius = DashboardMetrics.cardControlCornerRadius
        contentView.didReloadData = { [weak self] in
            self?.dashboardViewController?.view.needsLayout = true
        }
        addSubview(contentView)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        contentView.dashboardLayout.fullFrame()
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        size.height = contentView.queryContentHeight()
        return size
    }

    override func renderWithAttribute() {
        guard let json = attribute?.value as? String else {
            contentView.render(json: nil)
            assertionFailure()
            return
        }
        contentView.render(json: json)
    }

    func showInNewWindow() {
        guard let json = attribute?.value as? String else {
            assertionFailure()
            return
        }
        NavigationManager.shared.showJSONWindow(json)
    }
}

/// The JSON tree in a window of its own, with the bigger font.
@objc(LKJSONAttributeViewController)
final class JSONAttributeViewController: BaseViewController, TableViewDelegate, TableViewDataSource {
    private static let rowIdentifier = NSUserInterfaceItemIdentifier("myView")

    private var tableView: TableView!
    private let tree = JSONAttributeTree()

    override func makeContainerView() -> NSView {
        let containerView = BaseView()

        let tableView = TableView()
        tableView.drawsBackground = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.canScrollHorizontally = false
        tableView.adjustsSelectionAutomatically = false
        tableView.adjustsHoverAutomatically = false
        tableView.automaticallyAdjustsContentInsets = false
        tableView.contentInsets = NSEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        containerView.addSubview(tableView)
        self.tableView = tableView

        return containerView
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        tableView.dashboardLayout.fullFrame().toY(28)
    }

    @objc(renderWithJSON:)
    func render(json: String?) {
        tree.render(json: json)
        tableView.reloadData()
    }

    // MARK: - TableView

    func numberOfRows(in _: NSTableView) -> Int {
        tree.flatItems.count
    }

    func tableView(_: NSTableView, heightOfRow _: Int) -> CGFloat {
        25
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let item = tree.item(at: row) else {
            return TableBlankRowView()
        }
        let view: OutlineRowView
        if let reused = tableView.makeView(withIdentifier: Self.rowIdentifier, owner: self) as? OutlineRowView {
            view = reused
        } else {
            view = OutlineRowView()
            view.titleLabel.textColor = .secondaryLabelColor
            view.titleLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
            view.titleLabel.isSelectable = true
            view.subtitleLabel.textColor = .labelColor
            view.subtitleLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
            view.subtitleLabel.isSelectable = true
            view.disclosureButton.target = self
            view.disclosureButton.action = #selector(handleExpand(_:))
            view.identifier = Self.rowIdentifier
        }
        JSONAttributeTree.configure(view, row: row, with: item)
        return view
    }

    @objc private func handleExpand(_ button: NSButton) {
        guard tree.toggle(row: button.tag) else { return }
        tableView.reloadData()
    }
}

/// The window of `JSONAttributeViewController`.
@objc(LKJSONAttributeWindowController)
final class JSONAttributeWindowController: WindowController {
    @objc convenience init() {
        let window = AppWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 320),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.minSize = CGSize(width: 200, height: 200)
        window.center()

        self.init(window: window)

        let viewController = JSONAttributeViewController()
        window.contentView = viewController.view
        contentViewController = viewController
    }
}
