//
//  LKDashboardAttributeView.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/18.
//  https://lookin.work
//

import AppKit

/// One attribute row on a Dashboard card. Subclasses render `attribute`,
/// size themselves through `sizeThatFits(_:)` and say how many of them fit
/// in a row.
@objc(LKDashboardAttributeView)
class LKDashboardAttributeView: LKBaseView {
    /// Setting the attribute renders it.
    @objc var attribute: InspectedAttribute? {
        didSet { renderWithAttribute() }
    }

    @objc weak var dashboardViewController: LKDashboardViewController? {
        didSet { dashboardViewControllerDidChange() }
    }

    /// Required so a section can make a view from its class.
    override required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Whether the user can change the value: a user-custom attribute with
    /// a setter, or a known attribute with a setter on a live (not read
    /// from file) dashboard.
    @objc func canEdit() -> Bool {
        guard let attribute else { return false }
        if attribute.isUserCustom() {
            return !(attribute.customSetterID ?? "").isEmpty
        }
        let setter = DashboardBlueprint.setter(withAttrID: attribute.identifier)
        return setter != nil && (dashboardViewController?.isStaticMode ?? false)
    }

    /// Reads `attribute` and renders it.
    @objc func renderWithAttribute() {}

    /// How many of this view fit in a row: 1 takes the whole row, 0 sizes
    /// the view to its content.
    @objc func numberOfColumnsOccupied() -> Int {
        1
    }

    /// Subclasses set colours that depend on being on a dashboard.
    func dashboardViewControllerDidChange() {}

    /// Submits `newValue` through the dashboard. Returns whether the
    /// attribute was modified; throws, after the dashboard has shown the
    /// error, when the modification failed.
    @discardableResult
    func submit(_ newValue: Any?) async throws -> Bool {
        guard let attribute, let dashboardViewController else { return false }
        return try await dashboardViewController.modifyAttribute(attribute, newValue: newValue)
    }

    /// Submits `newValue`; on failure renders the current value again.
    func submitRenderingOnFailure(_ newValue: Any?) {
        Task { @MainActor [weak self] in
            do {
                try await self?.submit(newValue)
            } catch {
                NSLog("修改返回 error")
                self?.renderWithAttribute()
            }
        }
    }

    /// Submits `newValue`; on success renders the new value.
    func submitRenderingOnSuccess(_ newValue: Any?) {
        Task { @MainActor [weak self] in
            if (try? await self?.submit(newValue)) == true {
                self?.renderWithAttribute()
            }
        }
    }
}

/// Set while a modification result reloads the dashboard. The reload
/// removes the editing card, which ends text editing again; the text
/// fields ignore that second end-of-editing so the value is not submitted
/// twice.
@objc(LKDashboardTextControlEditingFlag)
final class LKDashboardTextControlEditingFlag: NSObject {
    @objc(sharedInstance)
    static let shared = LKDashboardTextControlEditingFlag()

    @objc var shouldIgnoreTextEditingChangeEvent = false

    override private init() {
        super.init()
    }
}
