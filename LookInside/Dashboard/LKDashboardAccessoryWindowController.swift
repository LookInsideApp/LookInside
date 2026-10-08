//
//  LKDashboardAccessoryWindowController.swift
//  LookInside
//
//  Created by Li Kai on 2019/8/30.
//  https://lookin.work
//

import AppKit

protocol LKDashboardAccessoryWindowControllerDelegate: AnyObject {
    func dashboardAccessoryWindowControllerWillClose(_ controller: LKDashboardAccessoryWindowController)
}

/// The panel beside the window that lists a card's hidden sections, each
/// with a button that adds it to the card.
final class LKDashboardAccessoryWindowController: LKWindowController, NSWindowDelegate {
    private let groupID: String?
    private weak var dashboardController: LKDashboardViewController?
    /// Keyed by section identifier.
    private var sectionViews: [String: LKDashboardSectionView] = [:]

    weak var delegate: LKDashboardAccessoryWindowControllerDelegate?

    init(dashboardController: LKDashboardViewController?, attrGroupID groupID: String?) {
        self.groupID = groupID
        self.dashboardController = dashboardController
        let panel = LKPopPanel(size: NSSize(width: 400, height: 100))
        super.init(window: panel)
        panel.delegate = self
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Shows `sections` and returns the window size they need.
    func render(attrSections sections: [AttributesSection]) -> NSSize {
        var needlessViews = Array(sectionViews.values)

        for (idx, section) in sections.enumerated() {
            let identifier = section.identifier ?? ""
            let view: LKDashboardSectionView
            if let existing = sectionViews[identifier] {
                view = existing
                needlessViews.removeAll { $0 === existing }
                view.isHidden = false
            } else {
                view = LKDashboardSectionView()
                sectionViews[identifier] = view
            }
            view.dashboardViewController = dashboardController
            view.manageState = .canAdd
            view.attrSection = section
            view.showTopSeparator = idx != 0
            window?.contentView?.addSubview(view)
        }

        needlessViews.forEach { $0.isHidden = true }

        let normalSectionWidth = LKDashboardMetrics.viewWidth - LKDashboardMetrics.horInset * 2
        var y: CGFloat = 8
        for sectionID in DashboardBlueprint.sectionIDs(forGroupID: groupID) ?? [] {
            guard let view = sectionViews[sectionID], !view.isHidden else { continue }
            view.dashboardLayout.x(LKDashboardMetrics.horInset).width(normalSectionWidth - LKDashboardMetrics.horInset * 2).heightToFit().y(y)
            y = view.frame.maxY + LKDashboardMetrics.sectionMarginTop
        }

        return NSSize(width: normalSectionWidth + 23, height: y)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_: Notification) {
        delegate?.dashboardAccessoryWindowControllerWillClose(self)
    }
}
