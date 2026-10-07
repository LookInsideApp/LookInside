//
//  LKDashboardAttributeNumberInputView.swift
//  LookInside
//
//  Created by Li Kai on 2019/2/21.
//  https://lookin.work
//

import AppKit

/// A single number: opacity, corner radius, font size and the like.
@objc(LKDashboardAttributeNumberInputView)
final class LKDashboardAttributeNumberInputView: LKDashboardAttributeView, NSTextFieldDelegate {
    @objc let inputView = LKNumberInputView()

    /// Laid out horizontally (title inside the field) with three decimals;
    /// everything else is vertical (title below) with two.
    private static let horizontalAttrs: Set<String> = [
        LookinAttr_ViewLayer_Visibility_Opacity,
        LookinAttr_ViewLayer_Corner_Radius,
        LookinAttr_ViewLayer_Tag_Tag,
        LookinAttr_UILabel_Font_Size,
        LookinAttr_UILabel_NumberOfLines_NumberOfLines,
        LookinAttr_UITextView_Font_Size,
        LookinAttr_UITextField_Font_Size,
        LookinAttr_UITextField_CanAdjustFont_MinSize,
        LookinAttr_ViewLayer_Border_Width,
        LookinAttr_UITableView_SectionsNumber_Number,
        LookinAttr_AutoLayout_Resistance_Ver,
        LookinAttr_AutoLayout_Resistance_Hor,
        LookinAttr_AutoLayout_Hugging_Ver,
        LookinAttr_AutoLayout_Hugging_Hor,
        LookinAttr_UIStackView_Spacing_Spacing,
        LookinAttr_NSWindow_Appearance_AlphaValue,
        LookinAttr_NSControl_Value_IntValue,
        LookinAttr_NSControl_Value_IntegerValue,
        LookinAttr_NSControl_Value_FloatValue,
        LookinAttr_NSControl_Value_DoubleValue,
        LookinAttr_NSTextField_PreferredMaxLayoutWidth_PreferredMaxLayoutWidth,
        LookinAttr_NSTextField_MaximumNumberOfLines_MaximumNumberOfLines,
        LookinAttr_UITraitCollection_Display_DisplayScale,
        LookinAttr_UIWindowScene_Traits_DisplayScale,
        LookinAttr_UIWindowScene_Windows_WindowCount,
        LookinAttr_UIWindowScene_Screen_ScreenScale,
        // Three per row, each labelled with a single letter inside the
        // field, the same shape as the inset rows above them in the card.
        LookinAttr_NSScrollView_LineScroll_Horizontal,
        LookinAttr_NSScrollView_LineScroll_Vertical,
        LookinAttr_NSScrollView_LineScroll_LineScroll,
        LookinAttr_NSScrollView_PageScroll_Horizontal,
        LookinAttr_NSScrollView_PageScroll_Vertical,
        LookinAttr_NSScrollView_PageScroll_PageScroll,
    ]

    /// Columns per attribute; any other known attribute takes a quarter row.
    private static let columns: [String: Int] = [
        LookinAttr_ViewLayer_Visibility_Opacity: 1,
        LookinAttr_ViewLayer_Corner_Radius: 1,
        LookinAttr_ViewLayer_Tag_Tag: 1,
        LookinAttr_UITextView_Font_Size: 1,
        LookinAttr_UITextField_Font_Size: 1,
        LookinAttr_UITextField_CanAdjustFont_MinSize: 1,
        LookinAttr_ViewLayer_Border_Width: 1,
        LookinAttr_UITableView_SectionsNumber_Number: 1,
        LookinAttr_UILabel_NumberOfLines_NumberOfLines: 1,
        LookinAttr_UILabel_Font_Size: 1,
        LookinAttr_UIStackView_Spacing_Spacing: 1,
        LookinAttr_NSWindow_Appearance_AlphaValue: 1,
        LookinAttr_NSWindow_Info_WindowNumber: 2,
        LookinAttr_NSWindow_Info_BackingScaleFactor: 2,
        LookinAttr_NSControl_Value_IntValue: 1,
        LookinAttr_NSControl_Value_IntegerValue: 1,
        LookinAttr_NSControl_Value_FloatValue: 1,
        LookinAttr_NSControl_Value_DoubleValue: 1,
        LookinAttr_NSTextField_PreferredMaxLayoutWidth_PreferredMaxLayoutWidth: 1,
        LookinAttr_NSTextField_MaximumNumberOfLines_MaximumNumberOfLines: 1,

        LookinAttr_AutoLayout_Resistance_Ver: 2,
        LookinAttr_AutoLayout_Resistance_Hor: 2,
        LookinAttr_AutoLayout_Hugging_Ver: 2,
        LookinAttr_AutoLayout_Hugging_Hor: 2,

        LookinAttr_UIScrollView_Zoom_Scale: 3,
        LookinAttr_UIScrollView_Zoom_MinScale: 3,
        LookinAttr_UIScrollView_Zoom_MaxScale: 3,

        LookinAttr_NSScrollView_LineScroll_Horizontal: 3,
        LookinAttr_NSScrollView_LineScroll_Vertical: 3,
        LookinAttr_NSScrollView_LineScroll_LineScroll: 3,
        LookinAttr_NSScrollView_PageScroll_Horizontal: 3,
        LookinAttr_NSScrollView_PageScroll_Vertical: 3,
        LookinAttr_NSScrollView_PageScroll_PageScroll: 3,

        // Kept in the vertical style ("Current" / "Max" / "Min" read
        // better as words than as glyphs) but widened to a third of the
        // row so the words fit without truncation.
        LookinAttr_NSScrollView_Magnification_Magnification: 3,
        LookinAttr_NSScrollView_Magnification_Max: 3,
        LookinAttr_NSScrollView_Magnification_Min: 3,

        LookinAttr_UITraitCollection_Display_DisplayScale: 1,
        LookinAttr_UIWindowScene_Traits_DisplayScale: 1,
        LookinAttr_UIWindowScene_Windows_WindowCount: 1,
        LookinAttr_UIWindowScene_Screen_ScreenScale: 1,
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
            size.height = LKDashboardMetrics.numberInputHorizontalHeight
        case .vertical:
            size.height = LKDashboardMetrics.numberInputVerticalHeight
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
            inputView.title = LookinDashboardBlueprint.briefTitle(withAttrID: attribute.identifier)
        }

        let doubleValue = (attribute.value as? NSNumber)?.doubleValue ?? 0

        if attribute.isUserCustom() {
            inputView.viewStyle = .horizontal
            textField.stringValue = NSString.lookin_string(from: doubleValue, decimal: 6)
        } else if Self.horizontalAttrs.contains(attribute.identifier ?? "") {
            inputView.viewStyle = .horizontal
            textField.stringValue = NSString.lookin_string(from: doubleValue, decimal: 3)
        } else {
            inputView.viewStyle = .vertical
            textField.stringValue = NSString.lookin_string(from: doubleValue, decimal: 2)
        }
    }

    override func numberOfColumnsOccupied() -> Int {
        guard let attribute, !attribute.isUserCustom() else { return 1 }
        return Self.columns[attribute.identifier ?? ""] ?? 4
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
        if LKDashboardTextControlEditingFlag.shared.shouldIgnoreTextEditingChangeEvent {
            NSLog("忽略 controlTextDidEndEditing 事件，驳回")
            return
        }
        guard let parsed = LKNumberInputView.parsedValue(with: inputView.textFieldView.textField.stringValue, attrType: attribute.attrType) as? NSNumber else {
            NSLog("输入格式校验不通过，驳回")
            renderWithAttribute()
            return
        }
        guard let expectedValue = LKDashboardModification.numberValue(parsed, for: attribute) else {
            NSLog("修改没有变化，不做任何提交")
            renderWithAttribute()
            return
        }
        submitRenderingOnFailure(expectedValue)
    }
}
