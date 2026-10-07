//
//  LKConsoleRowViews.swift
//  LookInside
//
//  The Console transcript rows: the input row (target picker and text
//  field), a submitted call, and a returned description.
//

import AppKit

private func lkpConsoleTargetColor(isDarkMode: Bool) -> NSColor {
    isDarkMode
        ? NSColor(red: 85 / 255.0, green: 200 / 255.0, blue: 95 / 255.0, alpha: 1)
        : NSColor(red: 54 / 255.0, green: 155 / 255.0, blue: 62 / 255.0, alpha: 1)
}

/// The last transcript row: a button showing the call target (it opens the
/// target picker) and the input field with selector suggestions.
final class LKConsoleInputRowView: LKTableRowView, LKInputSearchViewDelegate {
    private let dataSource: LKConsoleDataSource
    private let selectButton = NSButton()
    private let inputView = LKInputSearchView(throttleTime: 0.15)
    private let selectPopoverController: LKConsoleSelectPopoverController

    init(dataSource: LKConsoleDataSource) {
        self.dataSource = dataSource
        selectPopoverController = LKConsoleSelectPopoverController(dataSource: dataSource)
        super.init(frame: .zero)

        selectPopoverController.needShowError = { [weak self] error in
            LKPeripheralAlerts.show(error, in: self?.window)
        }

        selectButton.font = .systemFont(ofSize: 13)
        selectButton.imagePosition = .imageRight
        selectButton.bezelStyle = .roundRect
        selectButton.isBordered = false
        selectButton.image = NSImage(named: "Console_UpDownArrow")
        selectButton.target = self
        selectButton.action = #selector(handleSelectButton)
        addSubview(selectButton)

        inputView.delegate = self
        inputView.textField.focusRingType = .none
        addSubview(inputView)

        setIsDarkMode(effectiveAppearance.lkpIsDarkMode)

        dataSource.currentObjectDidChange = { [weak self] in
            self?.handleCurrentObjectDidChange()
        }
        handleCurrentObjectDidChange()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        selectButton.lkpFullHeight()
        selectButton.lkpWidthToFit()
        selectButton.lkpMaxWidth(bounds.width * 0.5)
        selectButton.lkpSetX(ConsoleInsetLeft)

        inputView.lkpSetX(selectButton.frame.maxX + 5)
        inputView.lkpToRight(ConsoleInsetRight)
        inputView.lkpFullHeight()
    }

    override func setIsDarkMode(_ isDarkMode: Bool) {
        super.setIsDarkMode(isDarkMode)
        // The target button's color follows the appearance.
        handleCurrentObjectDidChange()
    }

    func makeTextFieldFirstResponder() {
        window?.makeFirstResponder(inputView.textField)
    }

    @objc private func handleSelectButton() {
        selectPopoverController.reRender()
        let popover = NSPopover()
        popover.animates = false
        popover.behavior = .transient
        popover.contentSize = NSSize(width: LKHelper.isEnglish() ? 465 : 400,
                                     height: selectPopoverController.bestHeight())
        popover.contentViewController = selectPopoverController
        popover.show(relativeTo: NSRect(origin: .zero, size: selectButton.bounds.size),
                     of: selectButton, preferredEdge: .minY)
        selectPopoverController.needClose = { [weak popover] in
            popover?.close()
        }
    }

    private func handleCurrentObjectDidChange() {
        // Called from LKTableRowView's initializer through setIsDarkMode
        // before this row is set up; the init call repeats it.
        guard selectButton.target != nil else { return }
        inputView.clearContentAndSuggestions()

        let color = lkpConsoleTargetColor(isDarkMode: isDarkMode)
        let title: String
        if let object = dataSource.currentObject {
            title = "<\(object.lk_simpleDemangledClassName()): \(object.memoryAddress ?? "(null)")>"
            inputView.textField.isEditable = true
            inputView.textField.placeholderString = NSLocalizedString("Type property or method name here", comment: "")
        } else {
            title = NSLocalizedString("Select target object", comment: "")
            inputView.textField.isEditable = false
            inputView.textField.placeholderString = ""
        }
        selectButton.attributedTitle = NSAttributedString(string: title, attributes: [.foregroundColor: color])
        needsLayout = true
    }

    // MARK: - LKInputSearchViewDelegate

    func inputSearchView(_: LKInputSearchView, suggestionsFor string: String) -> [LKInputSearchSuggestionItem]? {
        guard string.count >= 3 else { return nil }
        let matches = LKHelper.bestMatches(inCandidates: dataSource.currentObjectSelectorNames, input: string,
                                           maxResultsCount: 8)
        return matches.map { name in
            let item = LKInputSearchSuggestionItem()
            item.image = NSImage(named: "icon_method")
            item.text = name
            return item
        }
    }

    func inputSearchView(_ view: LKInputSearchView, submitText text: String) {
        Task { [weak self, weak view] in
            guard let self else { return }
            do {
                try await dataSource.submit(text)
                view?.clearContentAndSuggestions()
            } catch {
                LKPeripheralAlerts.show(error, in: window)
            }
        }
    }
}

/// A submitted call: the target in green, then the method name.
final class LKConsoleSubmitRowView: LKTableRowView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        titleLabel.isSelectable = true
        titleLabel.font = .systemFont(ofSize: 13)

        subtitleLabel.isSelectable = true
        subtitleLabel.textColor = .labelColor
        subtitleLabel.font = .systemFont(ofSize: 13)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        var titleSize = titleLabel.sizeThatFits(lkpMaxSize)
        titleSize.width = min(titleSize.width, bounds.width * 0.5)
        titleLabel.lkpSetX(ConsoleInsetLeft)
        titleLabel.lkpSetWidth(titleSize.width)
        titleLabel.lkpSetHeight(titleSize.height)
        titleLabel.lkpVerAlign()

        subtitleLabel.lkpSetX(titleLabel.frame.maxX + 5)
        subtitleLabel.lkpToRight(ConsoleInsetRight)
        subtitleLabel.lkpHeightToFit()
        subtitleLabel.lkpVerAlign()
    }

    override func setIsDarkMode(_ isDarkMode: Bool) {
        super.setIsDarkMode(isDarkMode)
        titleLabel.textColor = lkpConsoleTargetColor(isDarkMode: isDarkMode)
    }
}

/// A returned description, wrapped to the row width.
final class LKConsoleReturnRowView: LKTableRowView {
    private static let insets = NSEdgeInsets(top: 0, left: ConsoleInsetLeft, bottom: 5, right: ConsoleInsetRight)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        titleLabel.isSelectable = true
        titleLabel.textColor = .labelColor
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.maximumNumberOfLines = 0
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        let insets = Self.insets
        titleLabel.lkpSetX(insets.left)
        titleLabel.lkpToRight(insets.right)
        titleLabel.lkpHeightToFit()
        titleLabel.lkpSetY(insets.top)
    }

    func height(forWidth width: CGFloat) -> CGFloat {
        let insets = Self.insets
        let limit = NSSize(width: width - insets.left - insets.right, height: .greatestFiniteMagnitude)
        return titleLabel.sizeThatFits(limit).height + insets.top + insets.bottom
    }
}
