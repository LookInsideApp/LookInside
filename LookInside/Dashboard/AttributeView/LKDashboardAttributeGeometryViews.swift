//
//  LKDashboardAttributeGeometryViews.swift
//  LookInside
//
//  Created by Li Kai on 2019/6/10.
//  https://lookin.work
//
//  The rect, insets, point and size attributes: a number field per
//  component, two per row, each titled with a letter inside the field.
//

import AppKit

/// Number fields, two per row. Subclasses fill them from the attribute's
/// `NSValue` and turn an edited field into the value to submit.
class LKDashboardAttributeFieldsView: LKDashboardAttributeView, NSTextFieldDelegate {
    /// The field titles, in field order.
    class var fieldTitles: [String] {
        []
    }

    private(set) var inputViews: [LKNumberInputView] = []

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        inputViews = Self.fieldTitles.map { title in
            let view = LKNumberInputView()
            view.title = title
            view.viewStyle = .horizontal
            view.textFieldView.textField.delegate = self
            view.textFieldView.backgroundColorName = "DashboardCardValueBGColor"
            addSubview(view)
            return view
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private var rowCount: Int {
        (inputViews.count + 1) / 2
    }

    override func layout() {
        super.layout()
        let horSpace = LKDashboardMetrics.attrItemHorInterspace
        let rowHeight = LKDashboardMetrics.numberInputHorizontalHeight
        let itemWidth = (frame.width - horSpace) / 2.0
        for (idx, view) in inputViews.enumerated() {
            let x = idx % 2 == 0 ? 0 : itemWidth + horSpace
            let y = CGFloat(idx / 2) * (rowHeight + LKDashboardMetrics.attrItemVerInterspace)
            view.dashboardLayout.width(itemWidth).height(rowHeight).x(x).y(y)
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        let rows = CGFloat(rowCount)
        size.height = LKDashboardMetrics.numberInputHorizontalHeight * rows + LKDashboardMetrics.attrItemVerInterspace * (rows - 1)
        return size
    }

    /// The field texts for the attribute's value, in field order.
    func fieldStrings(for _: NSValue) -> [String] {
        []
    }

    /// The value to submit after field `index` became `number`, or nil
    /// when nothing changed.
    func editedValue(from _: NSValue, field _: Int, number _: Double) -> NSValue? {
        nil
    }

    /// Submits `newValue`, the edit of `oldValue`.
    func submitEdit(_ newValue: NSValue, oldValue _: NSValue) {
        submitRenderingOnFailure(newValue)
    }

    override func renderWithAttribute() {
        guard let value = attribute?.value as? NSValue else {
            assertionFailure()
            return
        }
        let strings = fieldStrings(for: value)
        let editable = canEdit()
        for (view, string) in zip(inputViews, strings) {
            view.textFieldView.textField.isEditable = editable
            view.textFieldView.textField.stringValue = string
        }
    }

    // MARK: - NSTextFieldDelegate

    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        canEdit()
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        // A read-only attribute (such as the SwiftUI user-custom rows,
        // which have no setter) can still get an end-of-editing
        // notification when the field leaves the window or its editable
        // flag changes, although textShouldBeginEditing refused input.
        guard canEdit() else { return }
        if LKDashboardTextControlEditingFlag.shared.shouldIgnoreTextEditingChangeEvent {
            NSLog("忽略 controlTextDidEndEditing 事件，驳回")
            return
        }
        guard let editingTextField = notification.object as? NSTextField,
              let parsed = LKNumberInputView.parsedValue(with: editingTextField.stringValue, attrType: .double) as? NSNumber
        else {
            NSLog("输入格式校验不通过，驳回")
            renderWithAttribute()
            return
        }
        guard let oldValue = attribute?.value as? NSValue else { return }
        let index = inputViews.firstIndex { $0.textFieldView.textField === editingTextField } ?? NSNotFound
        guard let newValue = editedValue(from: oldValue, field: index, number: parsed.doubleValue) else {
            NSLog("修改没有变化，不做任何提交")
            renderWithAttribute()
            return
        }
        submitEdit(newValue, oldValue: oldValue)
    }

    override func dashboardViewControllerDidChange() {
        for view in inputViews {
            view.textFieldView.backgroundColorName = "DashboardCardValueBGColor"
        }
    }
}

@objc(LKDashboardAttributeRectView)
final class LKDashboardAttributeRectView: LKDashboardAttributeFieldsView {
    override class var fieldTitles: [String] {
        ["X", "Y", "W", "H"]
    }

    override func renderWithAttribute() {
        guard attribute != nil else {
            assertionFailure()
            return
        }
        super.renderWithAttribute()
    }

    override func fieldStrings(for value: NSValue) -> [String] {
        let rect = value.rectValue
        return [rect.origin.x, rect.origin.y, rect.size.width, rect.size.height].map {
            NSString.lookin_string(from: Double($0), decimal: 3)
        }
    }

    override func editedValue(from value: NSValue, field index: Int, number: Double) -> NSValue? {
        guard let rect = LKDashboardModification.rect(value.rectValue, replacingField: index, with: number) else {
            return nil
        }
        let newValue = NSValue(rect: rect)
        return newValue.isEqual(value) ? nil : newValue
    }

    override func submitEdit(_ newValue: NSValue, oldValue: NSValue) {
        let oldRect = oldValue.rectValue
        let expectedRect = newValue.rectValue
        Task { @MainActor [weak self] in
            do {
                guard let self, try await self.submit(newValue) else { return }
                let currentRect = (self.attribute?.value as? NSValue)?.rectValue ?? .zero
                if LKDashboardModification.rectEditWasReverted(old: oldRect, expected: expectedRect, current: currentRect) {
                    // The Server applied the new frame, then the app's own
                    // code (layoutSubviews, for example) set it back. Say so,
                    // or it looks as if the edit failed.
                    LKDashboardStyle.alert(
                        title: NSLocalizedString("The modification seems to have no effect.", comment: ""),
                        detail: NSLocalizedString("After modifying successfully by LookInside, the value seems to be recovered by the code in your iOS app. For example, modifying \"frame\" of a view may trigger \"layoutSubviews\", and \"layoutSubviews\" may modify the value again.", comment: ""),
                        window: self.window
                    )
                }
            } catch {
                NSLog("修改返回 error")
                self?.renderWithAttribute()
            }
        }
    }
}

@objc(LKDashboardAttributeInsetsView)
final class LKDashboardAttributeInsetsView: LKDashboardAttributeFieldsView {
    override class var fieldTitles: [String] {
        ["T", "L", "B", "R"]
    }

    override func renderWithAttribute() {
        guard attribute != nil else {
            assertionFailure()
            return
        }
        super.renderWithAttribute()
    }

    override func fieldStrings(for value: NSValue) -> [String] {
        let insets = value.edgeInsetsValue
        return [insets.top, insets.left, insets.bottom, insets.right].map {
            NSString.lookin_string(from: Double($0), decimal: 3)
        }
    }

    override func editedValue(from value: NSValue, field index: Int, number: Double) -> NSValue? {
        let oldInsets = value.edgeInsetsValue
        guard let insets = LKDashboardModification.insets(oldInsets, replacingField: index, with: number),
              LKDashboardModification.insetsDiffer(oldInsets, insets)
        else {
            return nil
        }
        return NSValue(edgeInsets: insets)
    }
}

@objc(LKDashboardAttributePointView)
final class LKDashboardAttributePointView: LKDashboardAttributeFieldsView {
    override class var fieldTitles: [String] {
        ["X", "Y"]
    }

    override func fieldStrings(for value: NSValue) -> [String] {
        let point = value.pointValue
        return [point.x, point.y].map { NSString.lookin_string(from: Double($0), decimal: 3) }
    }

    override func editedValue(from value: NSValue, field index: Int, number: Double) -> NSValue? {
        guard let point = LKDashboardModification.point(value.pointValue, replacingField: index, with: number) else {
            return nil
        }
        let newValue = NSValue(point: point)
        return newValue.isEqual(value) ? nil : newValue
    }
}

@objc(LKDashboardAttributeSizeView)
final class LKDashboardAttributeSizeView: LKDashboardAttributeFieldsView {
    override class var fieldTitles: [String] {
        ["W", "H"]
    }

    override func renderWithAttribute() {
        guard attribute != nil else {
            assertionFailure()
            return
        }
        super.renderWithAttribute()
    }

    override func fieldStrings(for value: NSValue) -> [String] {
        let size = value.sizeValue
        return [size.width, size.height].map { dimension in
            // Extremely large values (CGFLOAT_MAX, for example) read as "Max".
            dimension >= 1e15 ? "Max" : NSString.lookin_string(from: Double(dimension), decimal: 3)
        }
    }

    override func editedValue(from value: NSValue, field index: Int, number: Double) -> NSValue? {
        guard let size = LKDashboardModification.size(value.sizeValue, replacingField: index, with: number) else {
            return nil
        }
        let newValue = NSValue(size: size)
        return newValue.isEqual(value) ? nil : newValue
    }
}
