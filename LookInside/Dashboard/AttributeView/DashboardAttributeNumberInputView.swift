//
//  DashboardAttributeNumberInputView.swift
//  LookInside
//
//  Created by Li Kai on 2019/2/21.
//  https://lookin.work
//

import AppKit
import FoundationToolbox

/// A single number: opacity, corner radius, font size and the like.
@Loggable(subsystem: "com.lookinside.app")
final class DashboardAttributeNumberInputView: DashboardAttributeView, NSTextFieldDelegate {
    let inputView = NumberInputView()

    /// Laid out horizontally (title inside the field) with three decimals;
    /// everything else is vertical (title below) with two.
    private static let horizontalAttributes: Set<InspectedAttribute.Identifier> = [
        InspectedAttribute.Identifier.ViewLayer.Visibility.opacity,
        InspectedAttribute.Identifier.ViewLayer.Corner.radius,
        InspectedAttribute.Identifier.ViewLayer.Tag.tag,
        InspectedAttribute.Identifier.UILabel.Font.size,
        InspectedAttribute.Identifier.UILabel.NumberOfLines.numberOfLines,
        InspectedAttribute.Identifier.UITextView.Font.size,
        InspectedAttribute.Identifier.UITextField.Font.size,
        InspectedAttribute.Identifier.UITextField.CanAdjustFont.minSize,
        InspectedAttribute.Identifier.ViewLayer.Border.width,
        InspectedAttribute.Identifier.UITableView.SectionsNumber.number,
        InspectedAttribute.Identifier.AutoLayout.Resistance.vertical,
        InspectedAttribute.Identifier.AutoLayout.Resistance.horizontal,
        InspectedAttribute.Identifier.AutoLayout.Hugging.vertical,
        InspectedAttribute.Identifier.AutoLayout.Hugging.horizontal,
        InspectedAttribute.Identifier.UIStackView.Spacing.spacing,
        InspectedAttribute.Identifier.NSWindow.Appearance.alphaValue,
        InspectedAttribute.Identifier.NSControl.Value.intValue,
        InspectedAttribute.Identifier.NSControl.Value.integerValue,
        InspectedAttribute.Identifier.NSControl.Value.floatValue,
        InspectedAttribute.Identifier.NSControl.Value.doubleValue,
        InspectedAttribute.Identifier.NSTextField.PreferredMaxLayoutWidth.preferredMaxLayoutWidth,
        InspectedAttribute.Identifier.NSTextField.MaximumNumberOfLines.maximumNumberOfLines,
        InspectedAttribute.Identifier.UITraitCollection.Display.displayScale,
        InspectedAttribute.Identifier.UIWindowScene.Traits.displayScale,
        InspectedAttribute.Identifier.UIWindowScene.Windows.windowCount,
        InspectedAttribute.Identifier.UIWindowScene.Screen.screenScale,
        // Three per row, each labelled with a single letter inside the
        // field, the same shape as the inset rows above them in the card.
        InspectedAttribute.Identifier.NSScrollView.LineScroll.horizontal,
        InspectedAttribute.Identifier.NSScrollView.LineScroll.vertical,
        InspectedAttribute.Identifier.NSScrollView.LineScroll.lineScroll,
        InspectedAttribute.Identifier.NSScrollView.PageScroll.horizontal,
        InspectedAttribute.Identifier.NSScrollView.PageScroll.vertical,
        InspectedAttribute.Identifier.NSScrollView.PageScroll.pageScroll,
    ]

    /// Columns per attribute; any other known attribute takes a quarter row.
    private static let columns: [InspectedAttribute.Identifier: Int] = [
        InspectedAttribute.Identifier.ViewLayer.Visibility.opacity: 1,
        InspectedAttribute.Identifier.ViewLayer.Corner.radius: 1,
        InspectedAttribute.Identifier.ViewLayer.Tag.tag: 1,
        InspectedAttribute.Identifier.UITextView.Font.size: 1,
        InspectedAttribute.Identifier.UITextField.Font.size: 1,
        InspectedAttribute.Identifier.UITextField.CanAdjustFont.minSize: 1,
        InspectedAttribute.Identifier.ViewLayer.Border.width: 1,
        InspectedAttribute.Identifier.UITableView.SectionsNumber.number: 1,
        InspectedAttribute.Identifier.UILabel.NumberOfLines.numberOfLines: 1,
        InspectedAttribute.Identifier.UILabel.Font.size: 1,
        InspectedAttribute.Identifier.UIStackView.Spacing.spacing: 1,
        InspectedAttribute.Identifier.NSWindow.Appearance.alphaValue: 1,
        InspectedAttribute.Identifier.NSWindow.Information.windowNumber: 2,
        InspectedAttribute.Identifier.NSWindow.Information.backingScaleFactor: 2,
        InspectedAttribute.Identifier.NSControl.Value.intValue: 1,
        InspectedAttribute.Identifier.NSControl.Value.integerValue: 1,
        InspectedAttribute.Identifier.NSControl.Value.floatValue: 1,
        InspectedAttribute.Identifier.NSControl.Value.doubleValue: 1,
        InspectedAttribute.Identifier.NSTextField.PreferredMaxLayoutWidth.preferredMaxLayoutWidth: 1,
        InspectedAttribute.Identifier.NSTextField.MaximumNumberOfLines.maximumNumberOfLines: 1,

        InspectedAttribute.Identifier.AutoLayout.Resistance.vertical: 2,
        InspectedAttribute.Identifier.AutoLayout.Resistance.horizontal: 2,
        InspectedAttribute.Identifier.AutoLayout.Hugging.vertical: 2,
        InspectedAttribute.Identifier.AutoLayout.Hugging.horizontal: 2,

        InspectedAttribute.Identifier.UIScrollView.Zoom.scale: 3,
        InspectedAttribute.Identifier.UIScrollView.Zoom.minScale: 3,
        InspectedAttribute.Identifier.UIScrollView.Zoom.maxScale: 3,

        InspectedAttribute.Identifier.NSScrollView.LineScroll.horizontal: 3,
        InspectedAttribute.Identifier.NSScrollView.LineScroll.vertical: 3,
        InspectedAttribute.Identifier.NSScrollView.LineScroll.lineScroll: 3,
        InspectedAttribute.Identifier.NSScrollView.PageScroll.horizontal: 3,
        InspectedAttribute.Identifier.NSScrollView.PageScroll.vertical: 3,
        InspectedAttribute.Identifier.NSScrollView.PageScroll.pageScroll: 3,

        // Kept in the vertical style ("Current" / "Max" / "Min" read
        // better as words than as glyphs) but widened to a third of the
        // row so the words fit without truncation.
        InspectedAttribute.Identifier.NSScrollView.Magnification.magnification: 3,
        InspectedAttribute.Identifier.NSScrollView.Magnification.maximum: 3,
        InspectedAttribute.Identifier.NSScrollView.Magnification.minimum: 3,

        InspectedAttribute.Identifier.UITraitCollection.Display.displayScale: 1,
        InspectedAttribute.Identifier.UIWindowScene.Traits.displayScale: 1,
        InspectedAttribute.Identifier.UIWindowScene.Windows.windowCount: 1,
        InspectedAttribute.Identifier.UIWindowScene.Screen.screenScale: 1,
    ]

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        inputView.textFieldView.textField.delegate = self
        addSubview(inputView)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        inputView.dashboardLayout.fullFrame()
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        switch inputView.viewStyle {
        case .horizontal:
            size.height = DashboardMetrics.numberInputHorizontalHeight
        case .vertical:
            size.height = DashboardMetrics.numberInputVerticalHeight
        @unknown default:
            assertionFailure()
        }
        return size
    }

    override func renderWithAttribute() {
        guard let attribute else { return }
        let textField: NSTextField = inputView.textFieldView.textField
        textField.isEditable = canEdit()

        if attribute.isUserCustom() {
            inputView.title = nil
        } else {
            inputView.title = attribute.identifier.flatMap(DashboardBlueprint.briefTitle(of:))
        }

        let doubleValue = (attribute.value as? NSNumber)?.doubleValue ?? 0

        if attribute.isUserCustom() {
            inputView.viewStyle = .horizontal
            textField.stringValue = NSString.string(from: doubleValue, decimal: 6)
        } else if attribute.identifier.map(Self.horizontalAttributes.contains) ?? false {
            inputView.viewStyle = .horizontal
            textField.stringValue = NSString.string(from: doubleValue, decimal: 3)
        } else {
            inputView.viewStyle = .vertical
            textField.stringValue = NSString.string(from: doubleValue, decimal: 2)
        }
    }

    override func numberOfColumnsOccupied() -> Int {
        guard let attribute, !attribute.isUserCustom() else { return 1 }
        return attribute.identifier.flatMap { Self.columns[$0] } ?? 4
    }

    override func dashboardViewControllerDidChange() {
        inputView.textFieldView.backgroundColorName = "DashboardCardValueBGColor"
    }

    // MARK: - NSTextFieldDelegate

    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        canEdit()
    }

    func controlTextDidEndEditing(_: Notification) {
        // A read-only attribute (such as the SwiftUI user-custom rows,
        // which have no setter) can still get an end-of-editing
        // notification when the field leaves the window or its editable
        // flag changes, although textShouldBeginEditing refused input.
        guard canEdit(), let attribute else { return }
        if DashboardTextControlEditingFlag.shared.shouldIgnoreTextEditingChangeEvent {
            #log(.default, "忽略 controlTextDidEndEditing 事件，驳回")
            return
        }
        guard let parsed = NumberInputView.parsedValue(with: inputView.textFieldView.textField.stringValue, attrType: attribute.attrType) as? NSNumber else {
            #log(.default, "输入格式校验不通过，驳回")
            renderWithAttribute()
            return
        }
        guard let expectedValue = DashboardModification.numberValue(parsed, for: attribute) else {
            #log(.default, "修改没有变化，不做任何提交")
            renderWithAttribute()
            return
        }
        submitRenderingOnFailure(expectedValue)
    }
}
