//
//  LKDashboardAttributeTextView.swift
//  LookInside
//
//  Created by Li Kai on 2019/9/16.
//  https://lookin.work
//

import AppKit

/// A string attribute in an editable text view. SwiftUI attributes that
/// name another node get a button that jumps to it.
@objc(LKDashboardAttributeTextView)
final class LKDashboardAttributeTextView: LKDashboardAttributeView, NSTextViewDelegate {
    private let titleLabel = LKLabel()
    private let scrollView: NSScrollView
    private let textView: NSTextView
    private var jumpButton: NSButton!

    private var initialText = ""

    required init(frame frameRect: NSRect) {
        scrollView = LKHelper.scrollableTextView()
        textView = scrollView.documentView as! NSTextView
        super.init(frame: frameRect)

        layer?.cornerRadius = LKDashboardMetrics.cardControlCornerRadius

        titleLabel.textColor = NSColor(named: "DashboardInputAccessoryColor")
        titleLabel.font = LKDashboardStyle.font(10)
        titleLabel.maximumNumberOfLines = 1
        titleLabel.isHidden = true
        addSubview(titleLabel)

        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        textView.font = LKDashboardStyle.font(12)
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 2, height: 4)
        textView.delegate = self
        addSubview(scrollView)

        jumpButton = NSButton(image: LKDashboardStyle.image("Icon_JumpDisclosure") ?? NSImage(), target: self, action: #selector(handleJumpButton(_:)))
        jumpButton.bezelStyle = .roundRect
        jumpButton.isBordered = false
        jumpButton.toolTip = NSLocalizedString("Jump in hierarchy", comment: "")
        jumpButton.isHidden = true
        addSubview(jumpButton)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        let jumpButtonWidth: CGFloat = jumpButton.isHidden ? 0 : 24
        if titleLabel.isHidden {
            scrollView.dashboardLayout.fullFrame().toRight(jumpButtonWidth)
        } else {
            let titleHeight = titleLabel.sizeThatFits(LKDashboardMetrics.maxSize).height
            titleLabel.dashboardLayout.x(7).toRight(7).heightToFit().y(4)
            scrollView.dashboardLayout.x(0).toRight(jumpButtonWidth).y(4 + titleHeight + 1).toBottom(0)
        }
        if !jumpButton.isHidden {
            jumpButton.dashboardLayout.width(20).height(20).right(2).midY(scrollView.frame.midY)
        }
    }

    override func renderWithAttribute() {
        guard let attribute else { return }
        // Known attributes show their short title above the value.
        if !attribute.isUserCustom(), let briefTitle = DashboardBlueprint.briefTitle(withAttrID: attribute.identifier), !briefTitle.isEmpty {
            titleLabel.stringValue = briefTitle
            titleLabel.isHidden = false
        } else {
            titleLabel.isHidden = true
        }

        initialText = attribute.value as? String ?? ""
        textView.string = initialText
        textView.isEditable = canEdit()
        jumpButton.isHidden = jumpTargetItem() == nil
        needsLayout = true
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        size.width -= textView.textContainerInset.width * 2

        let attributes: [NSAttributedString.Key: Any] = textView.font.map { [.font: $0] } ?? [:]
        let attributedString = NSAttributedString(string: textView.string, attributes: attributes)
        let rect = attributedString.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
        let contentHeight = rect.size.height + textView.textContainerInset.height * 2
        var textHeight = min(max(contentHeight, 24), 80)

        if !titleLabel.isHidden {
            let titleHeight = titleLabel.sizeThatFits(LKDashboardMetrics.maxSize).height
            textHeight += 3 + titleHeight + 1
        }

        size.height = textHeight
        return size
    }

    override func dashboardViewControllerDidChange() {
        backgroundColorName = "DashboardCardValueBGColor"
    }

    private func jumpTargetItem() -> DisplayItem? {
        dashboardViewController?.currentDataSource()?.swiftUIJumpTarget(for: attribute)
    }

    @objc private func handleJumpButton(_: NSButton) {
        dashboardViewController?.currentDataSource()?.selectAndRevealItem(jumpTargetItem())
    }

    // MARK: - NSTextViewDelegate

    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            window?.makeFirstResponder(nil)
            return true
        }
        return false
    }

    func textDidEndEditing(_: Notification) {
        let expectedValue = textView.string
        if expectedValue == initialText {
            NSLog("修改没有变化，不做任何提交")
            renderWithAttribute()
            return
        }
        submitRenderingOnFailure(expectedValue)
    }
}
