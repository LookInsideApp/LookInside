//
//  LKConsoleViewController.swift
//  LookInside
//
//  The Console below the inspector: a transcript of method calls on the
//  target object, an input row with selector suggestions, and a button that
//  clears the transcript.
//

import AppKit

@objc(LKConsoleViewController)
final class LKConsoleViewController: LKBaseViewController, LKTableViewDelegate, LKTableViewDataSource {
    private let dataSource: LKConsoleDataSource
    private let tableView = LKTableView()
    private let clearButton = NSButton()
    private let inputRowView: LKConsoleInputRowView
    private let topBorderLayer = CALayer()
    private lazy var measuringReturnRowView = LKConsoleReturnRowView()
    private var previousWidth: CGFloat = 0

    @objc weak var liveDocument: LookinLiveDocument? {
        didSet { dataSource.liveDocument = liveDocument }
    }

    /// Whether the Console is on screen; while it is, the highlighted
    /// hierarchy item can become the call target.
    @objc var isControllerShowing: Bool {
        get { dataSource.isShowingConsole }
        set { dataSource.isShowingConsole = newValue }
    }

    @objc(initWithHierarchyDataSource:)
    init(hierarchyDataSource: LKHierarchyDataSource) {
        dataSource = LKConsoleDataSource(hierarchyDataSource: hierarchyDataSource)
        inputRowView = LKConsoleInputRowView(dataSource: dataSource)
        super.init(containerView: nil)

        dataSource.rowItemsDidChange = { [weak self] in
            self?.handleRowItemsDidChange()
        }
        handleRowItemsDidChange()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func makeContainerView() -> NSView {
        let containerView = LKBaseView()
        containerView.layer?.backgroundColor = NSColor(named: "ConsoleBackgroundColor")?.cgColor

        tableView.drawsBackground = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.canScrollHorizontally = false
        tableView.adjustsSelectionAutomatically = false
        tableView.adjustsHoverAutomatically = false
        tableView.automaticallyAdjustsContentInsets = false
        tableView.contentInsets = NSEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        containerView.addSubview(tableView)

        let clearButtonImage = NSImage(named: "icon_delete")
        clearButtonImage?.isTemplate = true
        clearButton.image = clearButtonImage
        clearButton.bezelStyle = .roundRect
        clearButton.isBordered = false
        clearButton.target = self
        clearButton.action = #selector(handleClearButton)
        containerView.addSubview(clearButton)

        topBorderLayer.lookin_removeImplicitAnimations()
        containerView.layer?.addSublayer(topBorderLayer)
        containerView.didChangeAppearanceBlock = { [weak self] _, isDarkMode in
            self?.topBorderLayer.backgroundColor = isDarkMode
                ? NSColor(white: 1, alpha: 0.12).cgColor
                : NSColor(white: 0, alpha: 0.15).cgColor
        }
        return containerView
    }

    private func handleRowItemsDidChange() {
        tableView.reloadData()
        tableView.layoutSubtreeIfNeeded()
        if !dataSource.rowItems.isEmpty {
            tableView.scrollRowToVisible(dataSource.rowItems.count - 1)
        }
        inputRowView.makeTextFieldFirstResponder()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            tableView.scrollRowToVisible(dataSource.rowItems.count - 1)
            inputRowView.makeTextFieldFirstResponder()
        }
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        topBorderLayer.lkpFullWidth()
        topBorderLayer.lkpSetFrame(y: 0, height: 1)

        tableView.lkpFullFrame()
        clearButton.lkpSizeToFit()
        clearButton.lkpRight(20)
        clearButton.lkpBottom(8)

        let width = view.bounds.width
        if previousWidth != width {
            previousWidth = width
            tableView.reloadData()
        }
    }

    @objc private func handleClearButton() {
        dataSource.clearHistoryContents()
    }

    /// Calls `text` on `obj` and adds the call to the transcript; errors are only logged.
    @objc(submitWithObj:text:)
    func submit(with obj: LookinObject?, text: String) {
        Task {
            do {
                try await dataSource.submit(object: obj, text: text)
            } catch {
                NSLog("Submit error: %@", String(describing: error))
            }
        }
    }

    // MARK: - LKTableViewDelegate, LKTableViewDataSource

    func numberOfRows(in _: NSTableView) -> Int {
        dataSource.rowItems.count
    }

    func tableView(_: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard dataSource.rowItems.indices.contains(row) else { return 0 }
        let item = dataSource.rowItems[row]
        switch item.kind {
        case .input, .submit:
            return 20
        case .returnValue:
            let measuringView = measuringReturnRowView
            measuringView.titleLabel.stringValue = item.normalText ?? ""
            return measuringView.height(forWidth: tableView.bounds.width)
        }
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard dataSource.rowItems.indices.contains(row) else {
            return LKTableBlankRowView()
        }
        let item = dataSource.rowItems[row]
        switch item.kind {
        case .input:
            return inputRowView
        case .submit:
            let identifier = NSUserInterfaceItemIdentifier("submit")
            let view = tableView.makeView(withIdentifier: identifier, owner: self) as? LKConsoleSubmitRowView
                ?? {
                    let view = LKConsoleSubmitRowView()
                    view.identifier = identifier
                    return view
                }()
            view.titleLabel.stringValue = item.highlightText ?? ""
            view.subtitleLabel.stringValue = item.normalText ?? ""
            view.needsLayout = true
            return view
        case .returnValue:
            let identifier = NSUserInterfaceItemIdentifier("return")
            let view = tableView.makeView(withIdentifier: identifier, owner: self) as? LKConsoleReturnRowView
                ?? {
                    let view = LKConsoleReturnRowView()
                    view.identifier = identifier
                    return view
                }()
            view.titleLabel.stringValue = item.normalText ?? ""
            view.needsLayout = true
            return view
        }
    }

    func tableViewDidClickBlankArea(_: LKTableView) {
        inputRowView.makeTextFieldFirstResponder()
    }
}
