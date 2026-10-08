//
//  NumberInputView.swift
//  LookInside
//

import AppKit

extension NumberInputView {
    /// The field's height in the horizontal and the vertical style.
    static let horizontalHeight: CGFloat = 21
    static let verticalHeight: CGFloat = 38
}

@objc enum NumberInputViewStyle: UInt {
    /// The title sits inside the field, on its right.
    case horizontal
    /// The title sits under the field.
    case vertical
}

/// A Dashboard number field with a short title.
@objc(LKNumberInputView)
class NumberInputView: BaseView {
    @objc let textFieldView = TextFieldView()
    private let titleLabel = TextLabel()

    @objc var viewStyle: NumberInputViewStyle = .horizontal {
        didSet { applyViewStyle() }
    }

    @objc var title: String? {
        didSet {
            titleLabel.stringValue = title ?? ""
            // The title can be truncated or abbreviated to a single letter,
            // so keep the full name reachable on hover.
            titleLabel.toolTip = title?.isEmpty == false ? title : nil
            updateTitleLabelFontAndColor()
            needsLayout = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        textFieldView.backgroundColorName = "DashboardCardValueBGColor"
        textFieldView.layer?.cornerRadius = DashboardCardControlCornerRadius
        let textField = textFieldView.textField
        textField.cell = NSTextFieldCell()
        textField.cell?.focusRingType = .none
        textField.cell?.usesSingleLineMode = true
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.cell?.isScrollable = true
        textField.cell?.isEditable = true
        textField.cell?.isSelectable = true
        textField.drawsBackground = false
        textField.textColor = NSColor(named: "DashboardCardValueColor")
        textField.font = NSFont.systemFont(ofSize: 12)
        addSubview(textFieldView)

        titleLabel.alignment = .center
        // The vertical style lays the title out under the field, inside a
        // column that can be narrower than the title. Truncate rather than
        // overflow — an unclamped title used to spill onto its neighbours.
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.usesSingleLineMode = true
        titleLabel.cell?.truncatesLastVisibleLine = true
        addSubview(titleLabel)
    }

    override func layout() {
        super.layout()
        textFieldView.frameLayout.fullWidth().height(NumberInputView.horizontalHeight)
        switch viewStyle {
        case .horizontal:
            titleLabel.frameLayout.sizeToFit().minWidth(15).verAlign().right(2)
            var insets = textFieldView.insets
            insets.right = frame.width - titleLabel.frame.minX + 2
            textFieldView.insets = insets
        case .vertical:
            // Clamped to the column width, so a title wider than its column
            // no longer overlaps whatever sits to its left and right.
            titleLabel.frameLayout.width(frame.width).heightToFit().x(0).y(textFieldView.frame.maxY + 3)
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        switch viewStyle {
        case .horizontal:
            size.height = NumberInputView.horizontalHeight
        case .vertical:
            size.height = NumberInputView.verticalHeight
        }
        return size
    }

    private func applyViewStyle() {
        switch viewStyle {
        case .horizontal:
            textFieldView.textField.alignment = .left
            textFieldView.insets = NSEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        case .vertical:
            textFieldView.textField.alignment = .center
            textFieldView.insets = NSEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        }
        updateTitleLabelFontAndColor()
        needsLayout = true
    }

    /// The value `string` parses to for `attrType` (an integer or a floating
    /// point type), or nil when it does not parse.
    @objc(parsedValueWithString:attrType:)
    static func parsedValue(with string: String, attrType: LookinAttrType) -> Any? {
        switch attrType {
        case .int, .long, .longLong:
            return Scanner(string: string).scanInt64().map { NSNumber(value: $0) }
        case .float, .double:
            return Scanner(string: string).scanDouble().map { NSNumber(value: $0) }
        default:
            assertionFailure("unsupported attribute type \(attrType.rawValue)")
            return nil
        }
    }

    private func updateTitleLabelFontAndColor() {
        if viewStyle == .horizontal {
            if ((title ?? "") as NSString).length > 1 {
                titleLabel.textColor = NSColor(named: "DashboardCardValueColor")
                titleLabel.font = NSFont.systemFont(ofSize: 12)
            } else {
                titleLabel.textColor = NSColor(named: "DashboardInputAccessoryColor")
                titleLabel.font = NSFont.systemFont(ofSize: 10)
            }
        } else {
            titleLabel.font = NSFont.systemFont(ofSize: 11)
            titleLabel.textColor = NSColor(named: "DashboardCardValueColor")
        }
        needsLayout = true
    }
}
