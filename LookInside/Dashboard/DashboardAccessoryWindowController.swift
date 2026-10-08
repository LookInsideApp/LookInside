//
//  DashboardAccessoryWindowController.swift
//  LookInside
//
//  Created by Li Kai on 2019/8/30.
//  https://lookin.work
//

import AppKit

protocol DashboardAccessoryWindowControllerDelegate: AnyObject {
    func dashboardAccessoryWindowControllerWillClose(_ controller: DashboardAccessoryWindowController)
}

/// The panel beside the window that lists a card's hidden sections, each
/// with a button that adds it to the card.
final class DashboardAccessoryWindowController: WindowController, NSWindowDelegate {
    private let groupID: String?
    private weak var dashboardController: DashboardViewController?
    /// Keyed by section identifier.
    private var sectionViews: [String: DashboardSectionView] = [:]

    weak var delegate: DashboardAccessoryWindowControllerDelegate?

    init(dashboardController: DashboardViewController?, attrGroupID groupID: String?) {
        self.groupID = groupID
        self.dashboardController = dashboardController
        let panel = PopPanel(size: NSSize(width: 400, height: 100))
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
            let view: DashboardSectionView
            if let existing = sectionViews[identifier] {
                view = existing
                needlessViews.removeAll { $0 === existing }
                view.isHidden = false
            } else {
                view = DashboardSectionView()
                sectionViews[identifier] = view
            }
            view.dashboardViewController = dashboardController
            view.manageState = .canAdd
            view.attrSection = section
            view.showTopSeparator = idx != 0
            window?.contentView?.addSubview(view)
        }

        needlessViews.forEach { $0.isHidden = true }

        let normalSectionWidth = DashboardMetrics.viewWidth - DashboardMetrics.horInset * 2
        var y: CGFloat = 8
        for sectionID in DashboardBlueprint.sectionIDs(forGroupID: groupID) ?? [] {
            guard let view = sectionViews[sectionID], !view.isHidden else { continue }
            view.dashboardLayout.x(DashboardMetrics.horInset).width(normalSectionWidth - DashboardMetrics.horInset * 2).heightToFit().y(y)
            y = view.frame.maxY + DashboardMetrics.sectionMarginTop
        }

        return NSSize(width: normalSectionWidth + 23, height: y)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_: Notification) {
        delegate?.dashboardAccessoryWindowControllerWillClose(self)
    }
}
