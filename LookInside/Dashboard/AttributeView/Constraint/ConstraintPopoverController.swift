//
//  ConstraintPopoverController.swift
//  LookInside
//
//  Created by Li Kai on 2019/9/28.
//  https://lookin.work
//

import AppKit

/// Every field of one constraint, with buttons that jump to its items.
final class ConstraintPopoverController: BaseViewController {
    private let horInset: CGFloat = 5
    private let insetBottom: CGFloat = 10
    private let titleHeight: CGFloat = 26
    private let textsViewMarginTop: CGFloat = 10

    private var titleView: TextFieldView?
    private let textsView = TextsMenuView()
    private var jumpObjects: [ObjectIdentifier: InspectedObject] = [:]

    /// Asked to jump to an item of the constraint.
    var requestJumpingToObject: ((InspectedObject) -> Void)?

    /// `canJumpToObject` decides whether an item's jump button is enabled:
    /// the item can be missing from the current tree (released, not
    /// captured, or from data that predates object identity). Nil enables
    /// every button.
    init(constraint: AutoLayoutConstraint, canJumpToObject: ((InspectedObject) -> Bool)?) {
        super.init(containerView: nil)

        if !constraint.effective {
            let titleView = TextFieldView.label()
            titleView.textField.font = DashboardStyle.font(AppHelper.isEnglish() ? 12 : 13)
            titleView.textColors = TwoColors(colorInLightMode: DashboardStyle.rgb(53, 60, 70), colorInDarkMode: DashboardStyle.rgb(216, 220, 228))
            titleView.textField.alignment = .center
            titleView.textField.stringValue = NSLocalizedString("The layout of selected view is not affected by this constraint.", comment: "")
            titleView.backgroundColors = TwoColors(colorInLightMode: DashboardStyle.rgb(0, 0, 0, 0.1), colorInDarkMode: DashboardStyle.rgb(0, 0, 0, 0.2))
            titleView.image = DashboardStyle.image("Constraint_Popover_Info")
            titleView.insets = NSEdgeInsets(top: 0, left: horInset, bottom: 0, right: horInset)
            view.addSubview(titleView)
            self.titleView = titleView
        }

        textsView.verSpace = 8
        textsView.horSpace = 4
        textsView.font = DashboardStyle.font(13)
        textsView.type = .center
        view.addSubview(textsView)

        func tuple(_ first: String, _ second: String?) -> StringTwoTuple {
            StringTwoTuple(first: first, second: second ?? "")
        }
        let texts = [
            tuple("FirstItem", AutoLayoutConstraint.description(withItemObject: constraint.firstItem, type: constraint.firstItemType, detailed: true)),
            tuple("FirstAttribute", (AutoLayoutConstraint.description(withAttributeInt: constraint.firstAttribute) as NSString).capitalizingFirstLetter()),
            tuple("Relation", AutoLayoutConstraint.description(with: constraint.relation)),
            tuple("SecondItem", AutoLayoutConstraint.description(withItemObject: constraint.secondItem, type: constraint.secondItemType, detailed: true)),
            tuple("SecondAttribute", (AutoLayoutConstraint.description(withAttributeInt: constraint.secondAttribute) as NSString).capitalizingFirstLetter()),
            tuple("Multiplier", "\(NSNumber(value: Double(constraint.multiplier)))"),
            tuple("Constant", "\(NSNumber(value: Double(constraint.constant)))"),
            tuple("Priority", "\(NSNumber(value: Double(constraint.priority)))"),
            tuple("Active", constraint.active ? "YES" : "NO"),
            tuple("ShouldBeArchived", constraint.shouldBeArchived ? "YES" : "NO"),
            tuple("Identifier", constraint.identifier ?? ""),
        ]

        if let firstJumpObject = constraint.jumpableItemObject(for: .first) {
            textsView.add(jumpButton(for: firstJumpObject, canJumpToObject: canJumpToObject), at: 0)
        }
        if let secondJumpObject = constraint.jumpableItemObject(for: .second) {
            textsView.add(jumpButton(for: secondJumpObject, canJumpToObject: canJumpToObject), at: 3)
        }

        textsView.texts = texts
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        titleView?.dashboardLayout.fullWidth().height(titleHeight).y(0)
        let y = titleView == nil ? 0 : titleHeight
        textsView.dashboardLayout.sizeToFit().horAlign().y(y + textsViewMarginTop)
    }

    func contentSize() -> NSSize {
        var resultSize = textsView.sizeThatFits(DashboardMetrics.maxSize)
        if let titleView {
            let titleWidth = titleView.sizeThatFits(DashboardMetrics.maxSize).width
            resultSize.width = max(titleWidth, resultSize.width)
            resultSize.height += titleHeight
        }
        resultSize.width += horInset * 2
        resultSize.height += insetBottom + textsViewMarginTop
        return resultSize
    }

    private func jumpButton(for jumpObject: InspectedObject, canJumpToObject: ((InspectedObject) -> Bool)?) -> NSButton {
        let button = NSButton.borderlessImageButton(with: DashboardStyle.image("Icon_JumpDisclosure"), target: self, action: #selector(handleJumpButton(_:)))
        jumpObjects[ObjectIdentifier(button)] = jumpObject
        if let canJumpToObject, !canJumpToObject(jumpObject) {
            button.isEnabled = false
            button.toolTip = NSLocalizedString("This object is not in the current hierarchy — it may have been released, filtered out, or come from data captured before it had an identity.", comment: "")
        }
        return button
    }

    @objc private func handleJumpButton(_ button: NSButton) {
        guard let object = jumpObjects[ObjectIdentifier(button)] else {
            assertionFailure()
            return
        }
        requestJumpingToObject?(object)
    }
}
