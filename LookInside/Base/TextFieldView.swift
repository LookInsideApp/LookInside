//
//  TextFieldView.swift
//  LookInside
//

import AppKit

/// A text field with insets, an optional leading image and an optional
/// trailing button that clears a search.
@objc(LKTextFieldView)
class TextFieldView: BaseView {
    @objc let textField = NSTextField()

    @objc var insets = NSEdgeInsetsZero {
        didSet { needsLayout = true }
    }

    @objc var textColors: TwoColors? {
        didSet { updateColors() }
    }

    @objc var image: NSImage? {
        didSet { updateImageView() }
    }

    /// Set by `initCloseButton()`.
    @objc private(set) var closeButton: NSButton?

    private var imageView: NSImageView?
    private var textDidChangeObserver: NSObjectProtocol?
    private var stringValueObservation: NSKeyValueObservation?

    /// A read-only, borderless label.
    @objc(labelView) static func label() -> TextFieldView {
        let view = TextFieldView()
        view.textField.wantsLayer = true
        view.textField.backgroundColor = .clear
        view.textField.isBezeled = false
        view.textField.drawsBackground = true
        view.textField.isEditable = false
        view.textField.isSelectable = false
        return view
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(textField)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(textField)
    }

    deinit {
        if let textDidChangeObserver {
            NotificationCenter.default.removeObserver(textDidChangeObserver)
        }
    }

    override func layout() {
        super.layout()
        if let imageView {
            if textField.isEditable {
                // An input, like the hierarchy's filter field.
                imageView.lkLayout.sizeToFit().x(insets.left).verAlign().offsetY(1)
                if let closeButton {
                    closeButton.lkLayout.y(1).toBottom(0).width(100).right(insets.right)
                    textField.lkLayout.x(imageView.frame.maxX + 5).toMaxX(closeButton.frame.minX - 5).heightToFit().verAlign()
                } else {
                    textField.lkLayout.x(imageView.frame.maxX + 5).toRight(insets.right).heightToFit().verAlign()
                }
            } else {
                // A plain label, like the constraint popover's title.
                FrameLayout([imageView, textField]).sizeToFit().verAlign()
                textField.lkLayout.x(imageView.frame.maxX)
                FrameLayout([imageView, textField]).groupHorAlign()
            }
        } else {
            textField.lkLayout.x(insets.left).toRight(insets.right).heightToFit().verAlign().offsetY(insets.top - insets.bottom)
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var textFieldMaxWidth = limitedSize.width - insets.left - insets.right
        if imageView != nil {
            textFieldMaxWidth -= image?.size.width ?? 0
        }
        let textFieldSize = textField.sizeThatFits(NSSize(width: textFieldMaxWidth, height: .greatestFiniteMagnitude))
        var resultWidth = textFieldSize.width + insets.left + insets.right
        if imageView != nil {
            resultWidth += image?.size.width ?? 0
        }
        return NSSize(width: resultWidth, height: textFieldSize.height + insets.top + insets.bottom)
    }

    override func updateColors() {
        super.updateColors()
        if let textColors {
            textField.textColor = textColors.color
        }
    }

    private func updateImageView() {
        if let image {
            let imageView = self.imageView ?? NSImageView()
            if self.imageView == nil {
                addSubview(imageView)
                self.imageView = imageView
            }
            imageView.image = image
        } else {
            imageView?.removeFromSuperview()
            imageView = nil
        }
        needsLayout = true
    }

    /// Adds the trailing "cancel search" button, shown while the field has
    /// text.
    @objc func initCloseButton() {
        guard closeButton == nil else { return }
        let closeButton = NSButton()
        closeButton.title = NSLocalizedString("CancelSearch", comment: "")
        closeButton.bezelStyle = .regularSquare
        addSubview(closeButton)
        self.closeButton = closeButton
        needsLayout = true

        // Typing posts text-did-change; code that sets stringValue (Esc
        // clearing the filter) only shows up through KVO. Watch both.
        let update = { [weak self] in
            guard let self else { return }
            self.closeButton?.isHidden = self.textField.stringValue.isEmpty
        }
        textDidChangeObserver = NotificationCenter.default.addObserver(forName: NSControl.textDidChangeNotification, object: textField, queue: nil) { _ in update() }
        stringValueObservation = textField.observe(\.stringValue, options: [.initial]) { _, _ in update() }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        // Without this, clicking where the close button would be does not
        // start editing, which is confusing.
        if textField.isEditable {
            textField.becomeFirstResponder()
        }
    }
}
