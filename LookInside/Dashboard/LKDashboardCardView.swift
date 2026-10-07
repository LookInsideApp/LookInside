//
//  LKDashboardCardView.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/18.
//  https://lookin.work
//

import AppKit
import QuartzCore

/// The clickable title row of a card: icon, title, SwiftUI accent and
/// disclosure arrow.
final class LKDashboardCardTitleControl: LKBaseControl {
    let iconImageView = NSImageView()
    let label = LKLabel()
    let disclosureImageView = NSImageView()
    let accentImageView = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(iconImageView)

        label.textColor = .labelColor
        label.font = LKDashboardStyle.font(13)
        addSubview(label)

        addSubview(disclosureImageView)

        accentImageView.contentTintColor = LKHelper.accentColor()
        accentImageView.isHidden = true
        addSubview(accentImageView)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        iconImageView.dashboardLayout.sizeToFit().verAlign().x(LKDashboardMetrics.horInset).offsetY(-1)
        label.dashboardLayout.sizeToFit().verAlign().offsetY(-1).x(iconImageView.frame.maxX + 3)

        var tailX = label.frame.maxX
        if !accentImageView.isHidden {
            accentImageView.dashboardLayout.sizeToFit().verAlign().x(tailX + 4)
            tailX = accentImageView.frame.maxX
        }
        disclosureImageView.dashboardLayout.sizeToFit().verAlign().x(tailX + 3)
    }
}

protocol LKDashboardCardViewDelegate: AnyObject {
    func dashboardCardViewNeedToggleCollapse(_ view: LKDashboardCardView)
}

/// One attribute group as a card: a title that collapses it, the shown
/// sections, and a "more" button that offers the hidden sections in a
/// panel beside the window.
final class LKDashboardCardView: LKBaseView, LKUserActionManagerDelegate, LKDashboardAccessoryWindowControllerDelegate {
    private let titleHeight: CGFloat = 30
    private let insetBottom: CGFloat = 12
    private var contentsY: CGFloat = 35

    private let backgroundEffectView = LKVisualEffectView()
    private let titleControl = LKDashboardCardTitleControl()
    private var detailButton: NSButton!
    private var relationHelpButton: NSButton?
    private var fadeView: LKBaseView?

    private let sectionViewPool = LKDashboardSectionViewPool()
    private var sectionViews: [LKDashboardSectionView] = []
    private var accessoryWindowController: LKDashboardAccessoryWindowController?

    weak var dashboardViewController: LKDashboardViewController?
    weak var delegate: LKDashboardCardViewDelegate?

    /// The group to render; setting it does not render.
    var attrGroup: LookinAttributesGroup?

    var isCollapsed = false {
        didSet {
            titleControl.disclosureImageView.image = LKDashboardStyle.image(isCollapsed ? "icon_arrow_right" : "icon_arrow_down")
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.cornerRadius = LKDashboardMetrics.cardCornerRadius

        backgroundEffectView.blendingMode = .withinWindow
        backgroundEffectView.state = .active
        addSubview(backgroundEffectView)

        titleControl.addTarget(self, clickAction: #selector(handleClickTitle))
        addSubview(titleControl)

        detailButton = NSButton(image: LKDashboardStyle.image("icon_more") ?? NSImage(), target: self, action: #selector(handleClickDetailButton))
        detailButton.bezelStyle = .roundRect
        detailButton.isBordered = false
        addSubview(detailButton)

        updateColors()

        LKUserActionManager.sharedInstance().add(self)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        backgroundEffectView.dashboardLayout.fullFrame()
        titleControl.dashboardLayout.fullWidth().height(titleHeight).y(0)
        if detailButton.isVisible {
            detailButton.dashboardLayout.width(50).height(28).right(-3).y(0)
        }
        if let relationHelpButton, relationHelpButton.isVisible {
            relationHelpButton.dashboardLayout.width(30).height(28).right(5).y(0)
        }

        guard attrGroup != nil, !sectionViews.isEmpty else { return }

        var y = contentsY
        for view in sectionViews {
            view.dashboardLayout.x(LKDashboardMetrics.horInset).toRight(LKDashboardMetrics.horInset).heightToFit().y(y)
            y = view.frame.maxY + LKDashboardMetrics.sectionMarginTop
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        if isCollapsed {
            size.height = titleHeight
            return size
        }
        size.width -= LKDashboardMetrics.horInset * 2
        var height = contentsY
        for view in sectionViews {
            height += view.sizeThatFits(size).height + LKDashboardMetrics.sectionMarginTop
        }
        height -= LKDashboardMetrics.sectionMarginTop
        height += insetBottom
        size.height = height
        return size
    }

    /// Renders `attrGroup`.
    func render() {
        guard let attrGroup else {
            assertionFailure()
            return
        }
        switch attrGroup.identifier {
        case LookinAttrGroup_Class:
            contentsY = 28
        case LookinAttrGroup_Relation:
            contentsY = 30
        default:
            contentsY = 35
        }

        let inspectedAppInfo = dashboardViewController?.currentDataSource()?.rawHierarchyInfo?.appInfo
        let isMacTarget = LKHelper.appInfoLooksLikeMacTarget(inspectedAppInfo)
        titleControl.label.stringValue = attrGroup.queryDisplayTitle(forMacTarget: isMacTarget)
        titleControl.iconImageView.image = Self.image(for: attrGroup)

        // Cards are reused per unique key; clear the accent when the card
        // now shows a group that is not SwiftUI's.
        let isSwiftUIGroup = Self.looksLikeSwiftUI(attrGroup)
        titleControl.accentImageView.isHidden = !isSwiftUIGroup
        titleControl.accentImageView.image = isSwiftUIGroup ? Self.swiftUIAccentImage : nil
        titleControl.toolTip = isSwiftUIGroup ? NSLocalizedString("LookInside Pro · Activated", comment: "") : nil
        titleControl.needsLayout = true

        detailButton.isHidden = !shouldShowDetailButton(groupID: attrGroup.identifier)

        sectionViews.forEach { $0.removeFromSuperview() }
        sectionViews.removeAll()
        sectionViewPool.recycleAll()

        for (idx, section) in (attrGroup.attrSections ?? []).enumerated() {
            if !section.isUserCustom() && !LKPreferenceManager.shared.isSectionShowing(section.identifier) {
                continue
            }
            let sectionView = sectionViewPool.dequeueView(for: section)
            sectionViews.append(sectionView)
            addSubview(sectionView)
            sectionView.dashboardViewController = dashboardViewController
            sectionView.attrSection = section
            sectionView.showTopSeparator = idx > 0
            sectionView.manageState = accessoryWindowController == nil ? .none : .canRemove
        }

        if accessoryWindowController != nil {
            renderAccessoryWindowController()
        }

        if attrGroup.identifier == LookinAttrGroup_Relation {
            showRelationHelpButton()
        } else {
            relationHelpButton?.removeFromSuperview()
        }

        needsLayout = true
    }

    func querySectionView(with section: LookinAttributesSection) -> LKDashboardSectionView? {
        sectionViews.first { $0.attrSection === section }
    }

    /// Dims the card, except for `rect` when it is not empty, then fades
    /// back after a second.
    func playFadeAnimation(highlightRect rect: CGRect) {
        if fadeView != nil {
            return
        }
        let fadeView = LKBaseView()
        fadeView.backgroundColor = isDarkMode() ? LKDashboardStyle.rgb(0, 0, 0, 0.7) : LKDashboardStyle.rgb(0, 0, 0, 0.6)
        fadeView.alphaValue = 0
        fadeView.frame = bounds
        addSubview(fadeView)
        self.fadeView = fadeView

        if rect != .zero {
            var totalHeight = fadeView.frame.height
            if totalHeight <= 0 {
                assertionFailure()
                totalHeight = 1
            }
            let maskLayer = CAGradientLayer()
            let black = NSColor.black.cgColor
            let clear = NSColor.clear.cgColor
            maskLayer.colors = [black, black, clear, clear, black, black]
            maskLayer.startPoint = CGPoint(x: 0, y: 0)
            maskLayer.endPoint = CGPoint(x: 0, y: 1)
            maskLayer.locations = [
                0,
                NSNumber(value: Double((rect.minY - 4) / totalHeight)),
                NSNumber(value: Double((rect.minY + 10) / totalHeight)),
                NSNumber(value: Double((rect.maxY + 2) / totalHeight)),
                NSNumber(value: Double((rect.maxY + 16) / totalHeight)),
                1,
            ]
            maskLayer.frame = fadeView.bounds
            fadeView.layer?.mask = maskLayer
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            fadeView.animator().alphaValue = 1
        } completionHandler: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.removeFadeAnimation()
            }
        }
    }

    private func removeFadeAnimation() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.fadeView?.animator().alphaValue = 0
        } completionHandler: {
            self.fadeView?.removeFromSuperview()
            self.fadeView = nil
        }
    }

    @objc private func handleClickTitle() {
        delegate?.dashboardCardViewNeedToggleCollapse(self)
    }

    // MARK: - Group look

    /// Wire-compatibility fallback for v8 Servers, which do not send
    /// `isSwiftUIGroup`: the SwiftUI groups are user-custom groups whose
    /// title begins with "SwiftUI" ("SwiftUI Type", "SwiftUI Layout"), which
    /// the upstream user-custom path never produces. Remove with v8 support.
    static func looksLikeSwiftUI(_ group: LookinAttributesGroup) -> Bool {
        group.isSwiftUIGroup || (group.userCustomTitle?.hasPrefix("SwiftUI") ?? false)
    }

    private static let groupIconNames: [String: String] = {
        let names: [String: String] = [
            LookinAttrGroup_Class: "dashboard_class",
            LookinAttrGroup_Relation: "dashboard_relation",
            LookinAttrGroup_Layout: "dashboard_layout",
            LookinAttrGroup_AutoLayout: "dashboard_autolayout",
            LookinAttrGroup_ViewLayer: "dashboard_layer",
            LookinAttrGroup_UIImageView: "dashboard_imageview",
            LookinAttrGroup_UILabel: "dashboard_label",
            LookinAttrGroup_UIButton: "dashboard_button",
            LookinAttrGroup_UIControl: "dashboard_control",
            LookinAttrGroup_UIScrollView: "dashboard_scrollview",
            LookinAttrGroup_UITableView: "dashboard_tableview",
            LookinAttrGroup_UITextView: "dashboard_textview",
            LookinAttrGroup_UITextField: "dashboard_textfield",
            LookinAttrGroup_UIVisualEffectView: "dashboard_effectview",
            LookinAttrGroup_UIStackView: "dashboard_stackview",
            LookinAttrGroup_NSImageView: "dashboard_imageview",
            LookinAttrGroup_NSControl: "dashboard_control",
            LookinAttrGroup_NSButton: "dashboard_button",
            LookinAttrGroup_NSScrollView: "dashboard_scrollview",
            LookinAttrGroup_NSTableView: "dashboard_tableview",
            LookinAttrGroup_NSTextView: "dashboard_textview",
            LookinAttrGroup_NSTextField: "dashboard_textfield",
            LookinAttrGroup_NSVisualEffectView: "dashboard_effectview",
            LookinAttrGroup_NSStackView: "dashboard_stackview",
            // NSControl subclasses share the green hue NSControl itself uses.
            LookinAttrGroup_NSSlider: "dashboard_slider",
            LookinAttrGroup_NSStepper: "dashboard_stepper",
            LookinAttrGroup_NSSwitch: "dashboard_switch",
            LookinAttrGroup_NSSegmentedControl: "dashboard_segmentedcontrol",
            LookinAttrGroup_NSLevelIndicator: "dashboard_levelindicator",
            LookinAttrGroup_NSProgressIndicator: "dashboard_progressindicator",
            LookinAttrGroup_NSPopUpButton: "dashboard_popupbutton",
            LookinAttrGroup_NSComboBox: "dashboard_combobox",
            LookinAttrGroup_NSColorWell: "dashboard_colorwell",
            LookinAttrGroup_NSDatePicker: "dashboard_datepicker",
            // Data containers share the blue hue NSTableView uses.
            LookinAttrGroup_NSOutlineView: "dashboard_outlineview",
            LookinAttrGroup_NSCollectionView: "dashboard_collectionview",
            LookinAttrGroup_NSGridView: "dashboard_gridview",
            // Structural containers share the pink hue NSStackView uses.
            LookinAttrGroup_NSSplitView: "dashboard_splitview",
            LookinAttrGroup_NSTabView: "dashboard_tabview",
            LookinAttrGroup_NSBox: "dashboard_box",
            // Window chrome gets a graphite hue no content group uses.
            LookinAttrGroup_NSWindow: "dashboard_window",
            LookinAttrGroup_UIWindowScene: "dashboard_windowscene",
            LookinAttrGroup_UITraitCollection: "dashboard_traitcollection",
            LookinAttrGroup_LayoutGuide: "dashboard_layoutguide",
            LookinAttrGroup_NSCell: "dashboard_cell",
            LookinAttrGroup_UserCustom: "dashboard_custom",
        ]
        #if DEBUG
            // Fail on the first card rendered rather than only when someone
            // selects the unregistered kind; that is how 16 AppKit control
            // groups once shipped with a borrowed icon. This covers the groups
            // compiled for this platform; the iOS-only groups rely on the
            // per-lookup assertion.
            for groupID in LookinDashboardBlueprint.groupIDs() ?? [] {
                assert(names[groupID] != nil, "missing dashboard icon for group \(groupID)")
            }
        #endif
        return names
    }()

    /// The icon of a group. Registering a new group means four host-side
    /// places: this table, the group title, the default sections and (when
    /// it has enums) the enum lists. An unregistered group falls back to a
    /// generic icon.
    static func image(for group: LookinAttributesGroup) -> NSImage? {
        let name = groupIconNames[group.identifier ?? ""]
        assert(name != nil, "missing dashboard icon for group \(group.identifier ?? "nil")")
        return LKDashboardStyle.image(name ?? "dashboard_layer")
    }

    private static let swiftUIAccentImage: NSImage? = {
        let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }()

    // MARK: - Relation help

    private func showRelationHelpButton() {
        if relationHelpButton == nil {
            let button = NSButton(image: LKDashboardStyle.image("ic_question") ?? NSImage(), target: self, action: #selector(handleRelationHelpButton))
            button.bezelStyle = .roundRect
            button.isBordered = false
            relationHelpButton = button
            addSubview(detailButton)
        }
        if let relationHelpButton {
            addSubview(relationHelpButton)
        }
    }

    @objc private func handleRelationHelpButton() {
        let menu = NSMenu()
        let menuItem = NSMenuItem()
        menuItem.image = LKDashboardStyle.image("Icon_Inspiration_small")
        menuItem.title = NSLocalizedString("How to display more member variables…", comment: "")
        menuItem.target = self
        menuItem.action = #selector(handleRelationDocument)
        menu.addItem(menuItem)
        if let event = NSApplication.shared.currentEvent, let relationHelpButton {
            NSMenu.popUpContextMenu(menu, with: event, for: relationHelpButton)
        }
    }

    @objc private func handleRelationDocument() {
        LKHelper.showDisabledExternalLinkAlert(withMessage: NSLocalizedString("Legacy member-variable documentation links are disabled in this community build. See the repository README instead.", comment: ""))
    }

    // MARK: - Others

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        LKUserActionManager.sharedInstance().send(.dashboardClick)
    }

    // MARK: - LKUserActionManagerDelegate

    func lkUserActionManager(_: LKUserActionManager, didAct type: LKUserActionType) {
        guard let accessoryWindowController else { return }
        guard [.previewOperation, .dashboardClick, .selectedItemChange].contains(type) else { return }
        accessoryWindowController.close()
    }

    // MARK: - Accessory

    @objc private func handleClickDetailButton() {
        if let accessoryWindowController {
            accessoryWindowController.close()
            return
        }

        LKUserActionManager.sharedInstance().send(.dashboardClick)

        if isCollapsed {
            // Expand a collapsed card first.
            delegate?.dashboardCardViewNeedToggleCollapse(self)
        }

        guard let attrGroup else { return }
        let controller = LKDashboardAccessoryWindowController(dashboardController: dashboardViewController, attrGroupID: attrGroup.identifier)
        controller.delegate = self
        accessoryWindowController = controller

        renderAccessoryWindowController()

        if let panel = controller.window {
            window?.addChildWindow(panel, ordered: .above)
        }
    }

    private func renderAccessoryWindowController() {
        guard let controller = accessoryWindowController, let attrGroup else {
            assertionFailure()
            return
        }

        sectionViews.forEach { $0.manageState = .canRemove }

        let allSectionIDs = LookinDashboardBlueprint.sectionIDs(forGroupID: attrGroup.identifier) ?? []
        let hiddenSectionIDs = allSectionIDs.filter { !LKPreferenceManager.shared.isSectionShowing($0) }
        if hiddenSectionIDs.isEmpty {
            controller.window?.contentView?.isHidden = true
            return
        }
        controller.window?.contentView?.isHidden = false

        let sections = hiddenSectionIDs.compactMap { sectionID in
            (attrGroup.attrSections ?? []).first { $0.identifier == sectionID }
        }
        let contentSize = controller.render(attrSections: sections)

        guard let window else { return }
        // Top-left origin: 0 when the card's top is the window's top.
        let selfFrameInWindow = window.contentView?.convert(frame, from: superview) ?? .zero
        // Bottom-left origin, in screen coordinates.
        let selfWindowFrame = window.frame
        // Kept above the bottom of the screen.
        let panelY = max(selfWindowFrame.origin.y + (selfWindowFrame.size.height - selfFrameInWindow.origin.y) - contentSize.height, 0)
        var panelX = selfWindowFrame.maxX + 5
        if panelX + contentSize.width > (window.screen?.frame.size.width ?? 0) {
            // Kept within the right edge of the screen: placed to the left.
            panelX = selfWindowFrame.origin.x + selfFrameInWindow.minX - contentSize.width - 5
        }
        // Screen coordinates even though the panel is a child window: a
        // y of 0 puts the panel's bottom on the screen's bottom.
        controller.window?.setFrame(NSRect(x: panelX, y: panelY, width: contentSize.width, height: contentSize.height), display: true)
    }

    func dashboardAccessoryWindowControllerWillClose(_: LKDashboardAccessoryWindowController) {
        sectionViews.forEach { $0.manageState = .none }
        accessoryWindowController = nil
    }

    private func shouldShowDetailButton(groupID: String?) -> Bool {
        if groupID == LookinAttrGroup_UserCustom {
            return false
        }
        // The group's own section count, not the blueprint's: some groups
        // (Layout for NSWindow, for example) are built with fewer sections.
        let actualCount = attrGroup?.attrSections?.count ?? 0
        let blueprintCount = LookinDashboardBlueprint.sectionIDs(forGroupID: groupID)?.count ?? 0
        return min(actualCount, blueprintCount) > 1
    }
}
