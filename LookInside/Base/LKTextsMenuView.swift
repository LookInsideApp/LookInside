//
//  LKTextsMenuView.swift
//  LookInside
//

import AppKit

@objc enum LKTextsMenuViewType: Int {
    /// Left column left-aligned, right column right-aligned.
    case justified
    /// Both columns meet in the middle.
    case center
}

/// Two columns of key / value labels, optionally with a button after a
/// value.
@objc(LKTextsMenuView)
class LKTextsMenuView: LKBaseView {
    /// Defaults to {0, 3, 0, 5}.
    @objc var insets = NSEdgeInsets(top: 0, left: 3, bottom: 0, right: 5)

    @objc var type: LKTextsMenuViewType = .justified {
        didSet { updateAlignments() }
    }

    @objc var texts: [StringTwoTuple] = [] {
        didSet { reloadLabels() }
    }

    @objc var font: NSFont?

    /// Defaults to 2.
    @objc var verSpace: CGFloat = 2
    /// Defaults to 10.
    @objc var horSpace: CGFloat = 10

    private var leftLabels: [LKLabel] = []
    private var rightLabels: [LKLabel] = []
    private var buttons: [Int: NSButton] = [:]
    private let buttonMarginLeft: CGFloat = 4

    override func layout() {
        super.layout()
        let visibleLeftLabels = leftLabels.filter { !$0.isHidden }
        let visibleRightLabels = rightLabels.filter { !$0.isHidden }

        if type == .center {
            var leftLabelMaxWidth = insets.left
            for (idx, leftLabel) in visibleLeftLabels.enumerated() {
                let y = idx > 0 ? visibleLeftLabels[idx - 1].frame.maxY + verSpace : 0
                leftLabel.lkLayout.sizeToFit().y(y)
                leftLabelMaxWidth = max(leftLabelMaxWidth, leftLabel.frame.width + insets.left)
            }
            for (idx, leftLabel) in visibleLeftLabels.enumerated() {
                leftLabel.lkLayout.maxX(leftLabelMaxWidth)
                let midY = leftLabel.frame.midY
                let rightLabel = visibleRightLabels[idx]
                rightLabel.lkLayout.x(leftLabelMaxWidth + horSpace).sizeToFit().midY(midY)
                if let button = buttons[idx] {
                    var x = rightLabel.frame.maxX
                    if !rightLabel.stringValue.isEmpty {
                        x += buttonMarginLeft
                    }
                    button.lkLayout.sizeToFit().x(x).midY(midY + 1)
                }
            }
        } else {
            for (idx, rightLabel) in visibleRightLabels.enumerated() {
                let leftLabel = visibleLeftLabels[idx]
                let y = idx > 0 ? visibleLeftLabels[idx - 1].frame.maxY + verSpace : 0
                leftLabel.lkLayout.sizeToFit().x(0).y(y)
                var rightLabelMaxX = frame.width
                if let button = buttons[idx] {
                    button.lkLayout.sizeToFit().right(0).midY(leftLabel.frame.midY)
                    rightLabelMaxX = button.frame.minX - buttonMarginLeft
                }
                rightLabel.lkLayout.x(leftLabel.frame.maxX + horSpace).toMaxX(rightLabelMaxX).heightToFit().midY(leftLabel.frame.midY)
            }
        }
    }

    private func makeLabel() -> LKLabel {
        let label = LKLabel()
        label.isSelectable = true
        label.font = font
        label.maximumNumberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        addSubview(label)
        return label
    }

    /// Reuses the existing labels, adds missing ones and hides the rest.
    private func reloadLabels() {
        for (idx, text) in texts.enumerated() {
            if idx >= leftLabels.count {
                leftLabels.append(makeLabel())
            }
            leftLabels[idx].isHidden = false
            leftLabels[idx].stringValue = text.first ?? ""
        }
        for label in leftLabels.dropFirst(texts.count) {
            label.isHidden = true
        }
        for (idx, text) in texts.enumerated() {
            if idx >= rightLabels.count {
                rightLabels.append(makeLabel())
            }
            rightLabels[idx].isHidden = false
            rightLabels[idx].stringValue = text.second ?? ""
        }
        for label in rightLabels.dropFirst(texts.count) {
            label.isHidden = true
        }
        updateColors()
        updateAlignments()
        needsLayout = true
    }

    private func updateAlignments() {
        for label in leftLabels {
            label.alignment = type == .justified ? .left : .right
        }
        for label in rightLabels {
            label.alignment = type == .justified ? .right : .left
        }
    }

    override func sizeThatFits(_: NSSize) -> NSSize {
        var resultHeight: CGFloat = 0
        var leftMaxWidth: CGFloat = 0
        var rightMaxWidth: CGFloat = 0
        for (idx, label) in leftLabels.filter({ !$0.isHidden }).enumerated() {
            let size = label.bestSize()
            leftMaxWidth = max(leftMaxWidth, size.width)
            resultHeight += size.height
            if idx > 0 {
                resultHeight += verSpace
            }
        }
        for (idx, label) in rightLabels.filter({ !$0.isHidden }).enumerated() {
            var width = label.bestWidth()
            if let button = buttons[idx] {
                width += button.bestWidth()
                if !label.stringValue.isEmpty {
                    width += buttonMarginLeft
                }
            }
            rightMaxWidth = max(rightMaxWidth, width)
        }
        let resultWidth = leftMaxWidth + rightMaxWidth + horSpace + insets.left + insets.right
        return NSSize(width: resultWidth, height: resultHeight)
    }

    override func updateColors() {
        super.updateColors()
        let isDarkMode = isDarkMode()
        for label in leftLabels {
            label.textColor = (isDarkMode ? NSColor.lkBaseRGB(216, 220, 228) : NSColor.lkBaseRGB(53, 60, 70)).withAlphaComponent(0.7)
        }
        for label in rightLabels {
            label.textColor = isDarkMode ? .lkBaseRGB(250, 251, 252) : .lkBaseRGB(13, 20, 30)
        }
    }

    /// Puts `button` after the value on row `idx`; the caller handles its
    /// action.
    @objc(addButton:atIndex:)
    func add(_ button: NSButton, at idx: UInt) {
        let idx = Int(idx)
        guard buttons[idx] == nil else {
            assertionFailure("row \(idx) already has a button")
            return
        }
        buttons[idx] = button
        addSubview(button)
        needsLayout = true
    }
}
