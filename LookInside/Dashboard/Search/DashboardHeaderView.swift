//
//  DashboardHeaderView.swift
//  LookInside
//
//  Created by Li Kai on 2019/9/5.
//  https://lookin.work
//

import AppKit

protocol DashboardHeaderViewDelegate: AnyObject {
    func dashboardHeaderView(_ view: DashboardHeaderView, didToggleActive isActive: Bool)
    func dashboardHeaderView(_ view: DashboardHeaderView, didInputString string: String)
}

/// The search field above the cards, with the "add custom property" button.
/// Clicking it activates the search; typing reports the text 0.3 s after
/// the last keystroke.
final class DashboardHeaderView: BaseView, NSTextFieldDelegate {
    private static let inputDebounceInterval: TimeInterval = 0.3

    private let iconXWhenActive: CGFloat = 11
    private let iconXWhenInactive: CGFloat = 89

    private let inputBorderView = NSView()
    private let iconImageView = NSImageView()
    private let textField = NSTextField()
    private let addButton = NSButton()
    private var pendingInput: DispatchWorkItem?

    weak var delegate: DashboardHeaderViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        inputBorderView.wantsLayer = true
        inputBorderView.layer?.cornerRadius = DashboardMetrics.cardCornerRadius
        inputBorderView.layer?.borderWidth = 1
        addSubview(inputBorderView)

        iconImageView.image = DashboardStyle.image("icon_search")
        addSubview(iconImageView)

        textField.placeholderString = NSLocalizedString("properties or methods", comment: "")
        textField.delegate = self
        textField.focusRingType = .none
        textField.isEditable = true
        textField.isBordered = false
        textField.isBezeled = false
        textField.usesSingleLineMode = true
        textField.backgroundColor = .clear
        textField.lineBreakMode = .byTruncatingTail
        textField.font = DashboardStyle.font(13)
        textField.isHidden = true
        addSubview(textField)

        addButton.image = NSImage(named: NSImage.addTemplateName)
        addButton.bezelStyle = .rounded
        addButton.target = self
        addButton.action = #selector(handleAddButton)
        addButton.frame = NSRect(x: 0, y: 0, width: 84, height: 40)
        addSubview(addButton)

        updateColors()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    var isActive = false {
        didSet {
            guard isActive != oldValue else { return }
            updateColors()

            if isActive {
                addButton.animator().alphaValue = 0
                inputBorderView.animator().setFrameSize(frame.size)
                iconImageView.animator().setFrameOrigin(NSPoint(x: iconXWhenActive, y: iconImageView.frame.minY))
                textField.animator().isHidden = false
                textField.becomeFirstResponder()
            } else {
                addButton.animator().alphaValue = 1
                inputBorderView.animator().setFrameSize(NSSize(width: frame.width - 48, height: frame.height))
                iconImageView.animator().setFrameOrigin(NSPoint(x: iconXWhenInactive, y: iconImageView.frame.minY))
                textField.animator().isHidden = true
                textField.stringValue = ""
            }

            delegate?.dashboardHeaderView(self, didToggleActive: isActive)
        }
    }

    var currentInputString: String {
        textField.stringValue
    }

    override func layout() {
        super.layout()
        if isActive {
            inputBorderView.dashboardLayout.fullFrame()
            iconImageView.dashboardLayout.sizeToFit().x(iconXWhenActive)
        } else {
            addButton.dashboardLayout.width(50).fullHeight().right(-6).offsetY(1)
            inputBorderView.dashboardLayout.x(0).toRight(48).fullHeight()
            iconImageView.dashboardLayout.sizeToFit().verAlign().x(iconXWhenInactive)
        }
        textField.dashboardLayout.x(30).toRight(2).heightToFit().verAlign()
    }

    override func updateColors() {
        super.updateColors()
        let isDarkMode = isDarkMode()
        let color: NSColor
        if isActive {
            color = isDarkMode ? DashboardStyle.rgb(70, 71, 72) : DashboardStyle.rgb(198, 199, 200)
        } else {
            color = isDarkMode ? DashboardStyle.rgb(47, 48, 49) : DashboardStyle.rgb(220, 221, 222)
        }
        inputBorderView.layer?.borderColor = color.cgColor
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        isActive = true
    }

    @objc private func handleAddButton() {
        let menu = NSMenu()
        let menuItem = NSMenuItem()
        menuItem.image = DashboardStyle.image("Icon_Inspiration_small")
        menuItem.title = NSLocalizedString("How to add custom properties…", comment: "")
        menuItem.target = self
        menuItem.action = #selector(handleAddCustomAttr)
        menu.addItem(menuItem)
        if let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: addButton)
        }
    }

    @objc private func handleAddCustomAttr() {
        AppHelper.showDisabledExternalLinkAlert(withMessage: NSLocalizedString("Legacy custom property guides are disabled in this community build. See the repository README instead.", comment: ""))
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidChange(_: Notification) {
        // The text as typed now; only the last one within the interval is
        // reported.
        let text = textField.stringValue
        pendingInput?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.delegate?.dashboardHeaderView(self, didInputString: text)
        }
        pendingInput = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.inputDebounceInterval, execute: workItem)
    }

    func controlTextDidEndEditing(_: Notification) {
        isActive = false
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Escape
            isActive = false
            return true
        }
        return false
    }
}
