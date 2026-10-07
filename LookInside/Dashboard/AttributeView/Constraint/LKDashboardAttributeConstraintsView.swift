//
//  LKDashboardAttributeConstraintsView.swift
//  LookInside
//
//  Created by Li Kai on 2019/9/12.
//  https://lookin.work
//

import AppKit

/// One constraint as a line of text, such as "self.width = 100 @ 750".
/// Constraints that do not affect the view are greyed out.
final class LKDashboardAttributeConstraintsItemControl: LKTextControl {
    var constraint: LookinAutoLayoutConstraint? {
        didSet {
            label.stringValue = constraint.map(Self.string(from:)) ?? ""
            updateLabelColor()
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        label.alignment = .left
        label.font = LKDashboardStyle.font(12)
        didChangeAppearance = { [weak self] _, _ in
            self?.updateLabelColor()
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func updateLabelColor() {
        if constraint?.effective == true {
            label.textColor = .labelColor
        } else if effectiveAppearance.lk_isDarkMode {
            label.textColor = LKDashboardStyle.rgb(130, 131, 132)
        } else {
            label.textColor = LKDashboardStyle.rgb(150, 151, 152)
        }
    }

    static func string(from constraint: LookinAutoLayoutConstraint) -> String {
        let firstItem = LookinAutoLayoutConstraint.description(withItemObject: constraint.firstItem, type: constraint.firstItemType, detailed: false)
        let firstAttribute = LookinAutoLayoutConstraint.description(withAttributeInt: constraint.firstAttribute)
        let relation = LookinAutoLayoutConstraint.symbol(with: constraint.relation)
        var string = "\(firstItem).\(firstAttribute) \(relation)"
        if constraint.secondAttribute == 0 {
            string += " " + NSString.lookin_string(from: Double(constraint.constant), decimal: 3)
        } else {
            let secondItem = LookinAutoLayoutConstraint.description(withItemObject: constraint.secondItem, type: constraint.secondItemType, detailed: false)
            let secondAttribute = LookinAutoLayoutConstraint.description(withAttributeInt: constraint.secondAttribute)
            string += " \(secondItem).\(secondAttribute)"
            if constraint.multiplier != 1 {
                string += " * " + NSString.lookin_string(from: Double(constraint.multiplier), decimal: 3)
            }
            if constraint.constant > 0 {
                string += " + " + NSString.lookin_string(from: Double(constraint.constant), decimal: 3)
            } else if constraint.constant < 0 {
                string += " - " + NSString.lookin_string(from: Double(-constraint.constant), decimal: 3)
            }
        }
        if constraint.priority != 1000 {
            string += " @ \(NSNumber(value: Double(constraint.priority)))"
        }
        return string
    }

    override func shouldTrackMouseEnteredAndExited() -> Bool {
        true
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        alphaValue = 0.5
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        alphaValue = 1
    }
}

/// The constraints that affect (or mention) the view; a click shows the
/// details of one.
@objc(LKDashboardAttributeConstraintsView)
final class LKDashboardAttributeConstraintsView: LKDashboardAttributeView {
    private let verInterSpace: CGFloat = 8
    private var textControls: [LKDashboardAttributeConstraintsItemControl] = []

    override func renderWithAttribute() {
        super.renderWithAttribute()
        let rawData = attribute?.value as? [LookinAutoLayoutConstraint] ?? []
        let constraints = LKDashboardConstraintOrder.sorted(rawData)

        while textControls.count < constraints.count {
            let control = LKDashboardAttributeConstraintsItemControl()
            control.addTarget(self, clickAction: #selector(handleClickItem(_:)))
            addSubview(control)
            textControls.append(control)
        }
        for (idx, control) in textControls.enumerated() {
            if idx < constraints.count {
                control.isHidden = false
                control.constraint = constraints[idx]
                control.needsLayout = true
            } else {
                control.isHidden = true
            }
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        var y: CGFloat = 0
        for control in textControls where !control.isHidden {
            control.dashboardLayout.fullFrame().heightToFit().y(y)
            y = control.frame.maxY + verInterSpace
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var height: CGFloat = 0
        for (idx, control) in textControls.filter({ !$0.isHidden }).enumerated() {
            height += control.sizeThatFits(limitedSize).height
            if idx > 0 {
                height += verInterSpace
            }
        }
        var size = limitedSize
        size.height = height
        return size
    }

    @objc private func handleClickItem(_ control: LKDashboardAttributeConstraintsItemControl) {
        guard let constraint = control.constraint else { return }
        let jumpDataSource = dashboardViewController?.currentDataSource()
        let viewController = LKConstraintPopoverController(constraint: constraint) { lookinObject in
            lookinObject.oid != 0 && jumpDataSource?.displayItem(withOid: lookinObject.oid) != nil
        }

        let popover = NSPopover()
        popover.animates = false
        popover.behavior = .transient
        popover.contentSize = viewController.contentSize()
        popover.contentViewController = viewController
        viewController.requestJumpingToObject = { [weak popover, weak self] lookinObject in
            popover?.close()

            guard let dataSource = self?.dashboardViewController?.currentDataSource(),
                  let item = dataSource.displayItem(withOid: lookinObject.oid)
            else { return }
            // Expand first so selecting can scroll to the item.
            if !item.displayingInHierarchy {
                dataSource.expand(toShow: item)
            }
            dataSource.selectedItem = item
        }
        popover.show(relativeTo: NSRect(x: 0, y: 0, width: control.bounds.width, height: control.bounds.height), of: control, preferredEdge: .maxX)
    }
}
