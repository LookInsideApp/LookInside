//
//  LKInputSearchView.swift
//  LookInside
//
//  A single-line text field with a floating suggestion list, used by the
//  Console input row. Typing asks the delegate for suggestions once the text
//  has been still for the throttle time; Return submits the trimmed text, the
//  arrow keys move through the suggestions, and Up on an empty selection
//  restores the previous input.
//

import AppKit

extension NSAppearance {
    /// The dark appearances, matched by name like `-[NSAppearance lk_isDarkMode]`.
    var lkpIsDarkMode: Bool {
        [.darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark]
            .contains(name)
    }
}

final class LKInputSearchSuggestionItem: NSObject {
    var image: NSImage?
    var text: String?
}

protocol LKInputSearchViewDelegate: AnyObject {
    func inputSearchView(_ view: LKInputSearchView, suggestionsFor string: String) -> [LKInputSearchSuggestionItem]?
    func inputSearchView(_ view: LKInputSearchView, submitText text: String)
}

final class LKInputSearchView: LKBaseView, NSTextFieldDelegate {
    weak var delegate: LKInputSearchViewDelegate?

    var horizontalInset: CGFloat = 0

    var textField: NSTextField {
        textFieldView.textField
    }

    private let throttleTime: TimeInterval
    private let textFieldView = LKTextFieldView()
    private let suggestionWindowController = LKInputSearchSuggestionWindowController()
    private var previousInput: String?
    private var pendingSuggestionUpdate: DispatchWorkItem?

    init(throttleTime: CGFloat) {
        self.throttleTime = TimeInterval(throttleTime)
        super.init(frame: .zero)

        let textField: NSTextField = textFieldView.textField
        textField.delegate = self
        textFieldView.insets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textField.isEditable = true
        textField.isBordered = false
        textField.isBezeled = false
        textField.usesSingleLineMode = true
        textField.backgroundColor = .clear
        textField.lineBreakMode = .byTruncatingTail
        textField.font = .systemFont(ofSize: 13)
        addSubview(textFieldView)

        let tableView = suggestionWindowController.suggestionsView.tableView
        tableView.target = self
        tableView.action = #selector(handleClickTableView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        textFieldView.lkpSetX(horizontalInset)
        textFieldView.lkpToRight(horizontalInset)
        textFieldView.lkpFullHeight()

        guard superview != nil, let window, let contentView = window.contentView,
              let suggestionWindow = suggestionWindowController.window
        else { return }
        let selfOrigin = contentView.convert(frame.origin, from: superview)
        let mainWindowFrame = window.frame
        let panelSize = suggestionWindowController.suggestionsView.bestSize()
        let panelHeight = panelSize.height
        let panelWidth = min(panelSize.width, 500)

        var y = mainWindowFrame.origin.y + contentView.frame.height - selfOrigin.y - panelHeight - frame.height
        if y < 200 {
            // Not enough room below: show the list above the field.
            y += panelHeight + frame.height
        }
        suggestionWindow.setFrame(
            NSRect(x: mainWindowFrame.origin.x + selfOrigin.x, y: y, width: panelWidth, height: panelHeight),
            display: true
        )
    }

    func clearContentAndSuggestions() {
        if !textField.stringValue.isEmpty {
            previousInput = textField.stringValue
        }
        textField.stringValue = ""
        suggestionWindowController.close()
    }

    @objc private func handleClickTableView() {
        if let text = suggestionWindowController.suggestionsView.currentSelectedItem()?.text {
            textField.stringValue = text
            suggestionWindowController.close()
        }
    }

    /// Runs `updateSuggestions(for:)` once the text has not changed for `throttleTime`.
    private func scheduleSuggestionUpdate(for text: String) {
        pendingSuggestionUpdate?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.updateSuggestions(for: text)
        }
        pendingSuggestionUpdate = work
        DispatchQueue.main.asyncAfter(deadline: .now() + throttleTime, execute: work)
    }

    private func updateSuggestions(for text: String) {
        let items = delegate?.inputSearchView(self, suggestionsFor: text) ?? []
        suggestionWindowController.suggestionsView.items = items
        if !items.isEmpty, textField.stringValue == text, let suggestionWindow = suggestionWindowController.window {
            window?.addChildWindow(suggestionWindow, ordered: .above)
            needsLayout = true
        } else {
            suggestionWindowController.close()
        }
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        let editorText = (obj.userInfo?["NSFieldEditor"] as? NSText)?.string ?? textField.stringValue
        scheduleSuggestionUpdate(for: editorText)
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        let suggestionsView = suggestionWindowController.suggestionsView
        let isShowingSuggestions = suggestionWindowController.window?.isVisible ?? false

        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            if !isShowingSuggestions || suggestionsView.currentSelectedItem() == nil, let previousInput {
                textField.stringValue = previousInput
                return true
            }
        }

        if commandSelector == #selector(NSResponder.moveDown(_:)) || commandSelector == #selector(NSResponder.moveUp(_:)) {
            if isShowingSuggestions, let event = NSApp.currentEvent {
                suggestionsView.tableView.keyDown(with: event)
                return true
            }
        }

        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            if isShowingSuggestions, let text = suggestionsView.currentSelectedItem()?.text {
                textField.stringValue = text
                suggestionWindowController.close()
                return true
            }
            let input = textField.stringValue.trimmingCharacters(in: .whitespaces)
            if !input.isEmpty {
                delegate?.inputSearchView(self, submitText: input)
            }
            // Keep the focus in the field either way.
            return true
        }
        return false
    }

    func control(_: NSControl, textShouldEndEditing _: NSText) -> Bool {
        suggestionWindowController.close()
        return true
    }
}

/// The floating panel that shows the suggestion list.
final class LKInputSearchSuggestionWindowController: LKWindowController {
    let suggestionsView: LKInputSearchSuggestionsContentView

    init() {
        let view = LKInputSearchSuggestionsContentView()
        suggestionsView = view

        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 100),
                            styleMask: .utilityWindow, backing: .buffered, defer: true)
        panel.contentView = view
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.backgroundColor = .clear
        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

final class LKInputSearchSuggestionsContentView: LKBaseView, NSTableViewDelegate, NSTableViewDataSource {
    private static let rowHeight: CGFloat = 28

    var items: [LKInputSearchSuggestionItem] = [] {
        didSet { tableView.reloadData() }
    }

    let tableView = NSTableView()

    private let backgroundEffectView = LKVisualEffectView()
    private lazy var measuringRowView = LKInputSearchSuggestionsRowView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.cornerRadius = 4

        backgroundEffectView.blendingMode = .behindWindow
        backgroundEffectView.state = .active
        addSubview(backgroundEffectView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.wantsLayer = true
        tableView.headerView = nil
        tableView.intercellSpacing = .zero
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("column"))
        column.isEditable = false
        tableView.addTableColumn(column)
        addSubview(tableView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        backgroundEffectView.lkpFullFrame()
        tableView.lkpFullFrame()
    }

    func currentSelectedItem() -> LKInputSearchSuggestionItem? {
        let row = tableView.selectedRow
        return items.indices.contains(row) ? items[row] : nil
    }

    func bestSize() -> NSSize {
        let rowView = measuringRowView
        let width = items.reduce(CGFloat(0)) { widest, item in
            rowView.imageView.image = item.image
            rowView.titleLabel.stringValue = item.text ?? ""
            return max(rowView.bestWidth(), widest)
        }
        return NSSize(width: width, height: Self.rowHeight * CGFloat(items.count))
    }

    // MARK: - NSTableViewDataSource, NSTableViewDelegate

    func numberOfRows(in _: NSTableView) -> Int {
        items.count
    }

    func tableView(_: NSTableView, heightOfRow _: Int) -> CGFloat {
        Self.rowHeight
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard items.indices.contains(row) else {
            return LKInputSearchSuggestionsRowView()
        }
        let item = items[row]
        let identifier = NSUserInterfaceItemIdentifier("cell")
        let view = tableView.makeView(withIdentifier: identifier, owner: self) as? LKInputSearchSuggestionsRowView
            ?? {
                let view = LKInputSearchSuggestionsRowView()
                view.identifier = identifier
                return view
            }()
        view.titleLabel.stringValue = item.text ?? ""
        view.imageView.image = item.image
        view.needsLayout = true
        return view
    }

    func tableView(_: NSTableView, viewFor _: NSTableColumn?, row _: Int) -> NSView? {
        nil
    }
}

final class LKInputSearchSuggestionsRowView: NSTableRowView {
    private static let horizontalInset: CGFloat = 10
    private static let titleLeft: CGFloat = 5

    let titleLabel = LKLabel()
    let imageView = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(imageView)

        titleLabel.maximumNumberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.font = .systemFont(ofSize: 14)
        addSubview(titleLabel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        imageView.lkpSizeToFit()
        imageView.lkpSetX(Self.horizontalInset)
        imageView.lkpVerAlign()

        titleLabel.lkpSetX(imageView.frame.maxX + Self.titleLeft)
        titleLabel.lkpToRight(Self.horizontalInset)
        titleLabel.lkpHeightToFit()
        titleLabel.lkpVerAlign()
        titleLabel.lkpOffsetY(-1)
    }

    func bestWidth() -> CGFloat {
        Self.horizontalInset * 2 + (imageView.image?.size.width ?? 0) + Self.titleLeft
            + titleLabel.sizeThatFits(lkpMaxSize).width
    }

    override func drawSelection(in _: NSRect) {
        guard selectionHighlightStyle != .none else { return }
        let color = effectiveAppearance.lkpIsDarkMode ? LKHelper.accentColor() : NSColor(red: 0, green: 0, blue: 0, alpha: 0.24)
        color.setFill()
        NSBezierPath(rect: bounds).fill()
    }
}
