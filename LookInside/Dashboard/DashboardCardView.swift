//
//  DashboardCardView.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/18.
//  https://lookin.work
//

import AppKit
import QuartzCore

/// The clickable title row of a card: icon, title, SwiftUI accent and
/// disclosure arrow.
final class DashboardCardTitleControl: BaseControl {
    let iconImageView = NSImageView()
    let label = TextLabel()
    let disclosureImageView = NSImageView()
    let accentImageView = NSImageView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(iconImageView)

        label.textColor = .labelColor
        label.font = DashboardStyle.font(13)
        addSubview(label)

        addSubview(disclosureImageView)

        accentImageView.contentTintColor = AppHelper.accentColor()
        accentImageView.isHidden = true
        addSubview(accentImageView)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        iconImageView.dashboardLayout.sizeToFit().verAlign().x(DashboardMetrics.horInset).offsetY(-1)
        label.dashboardLayout.sizeToFit().verAlign().offsetY(-1).x(iconImageView.frame.maxX + 3)

        var tailX = label.frame.maxX
        if !accentImageView.isHidden {
            accentImageView.dashboardLayout.sizeToFit().verAlign().x(tailX + 4)
            tailX = accentImageView.frame.maxX
        }
        disclosureImageView.dashboardLayout.sizeToFit().verAlign().x(tailX + 3)
    }
}

protocol DashboardCardViewDelegate: AnyObject {
    func dashboardCardViewNeedToggleCollapse(_ view: DashboardCardView)
}

/// One attribute group as a card: a title that collapses it, the shown
/// sections, and a "more" button that offers the hidden sections in a
/// panel beside the window.
final class DashboardCardView: BaseView, UserActionManagerDelegate, DashboardAccessoryWindowControllerDelegate {
    private let titleHeight: CGFloat = 30
    private let insetBottom: CGFloat = 12
    private var contentsY: CGFloat = 35

    private let backgroundEffectView = VisualEffectView()
    private let titleControl = DashboardCardTitleControl()
    private lazy var detailButton = NSButton(image: DashboardStyle.image("icon_more") ?? NSImage(), target: self, action: #selector(handleClickDetailButton))
    private var relationHelpButton: NSButton?
    private var fadeView: BaseView?

    private let sectionViewPool = DashboardSectionViewPool()
    private var sectionViews: [DashboardSectionView] = []
    private var accessoryWindowController: DashboardAccessoryWindowController?

    weak var dashboardViewController: DashboardViewController?
    weak var delegate: DashboardCardViewDelegate?

    /// The group to render; setting it does not render.
    var attrGroup: AttributesGroup?

    var isCollapsed = false {
        didSet {
            titleControl.disclosureImageView.image = DashboardStyle.image(isCollapsed ? "icon_arrow_right" : "icon_arrow_down")
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.cornerRadius = DashboardMetrics.cardCornerRadius

        backgroundEffectView.blendingMode = .withinWindow
        backgroundEffectView.state = .active
        addSubview(backgroundEffectView)

        titleControl.addTarget(self, clickAction: #selector(handleClickTitle))
        addSubview(titleControl)

        detailButton.bezelStyle = .roundRect
        detailButton.isBordered = false
        addSubview(detailButton)

        updateColors()

        UserActionManager.sharedInstance().add(self)
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
            view.dashboardLayout.x(DashboardMetrics.horInset).toRight(DashboardMetrics.horInset).heightToFit().y(y)
            y = view.frame.maxY + DashboardMetrics.sectionMarginTop
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        if isCollapsed {
            size.height = titleHeight
            return size
        }
        size.width -= DashboardMetrics.horInset * 2
        var height = contentsY
        for view in sectionViews {
            height += view.sizeThatFits(size).height + DashboardMetrics.sectionMarginTop
        }
        height -= DashboardMetrics.sectionMarginTop
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
        case AttributesGroup.Identifier.class:
            contentsY = 28
        case AttributesGroup.Identifier.relation:
            contentsY = 30
        default:
            contentsY = 35
        }

        let inspectedAppInfo = dashboardViewController?.currentDataSource()?.rawHierarchyInfo?.appInfo
        let isMacTarget = AppHelper.appInfoLooksLikeMacTarget(inspectedAppInfo)
        titleControl.label.stringValue = attrGroup.queryDisplayTitle(forMacTarget: isMacTarget)
        titleControl.iconImageView.image = Self.image(for: attrGroup)

        // Cards are reused per unique key; clear the accent when the card
        // now shows a group that is not SwiftUI's.
        let isSwiftUIGroup = Self.looksLikeSwiftUI(attrGroup)
        titleControl.accentImageView.isHidden = !isSwiftUIGroup
        titleControl.accentImageView.image = isSwiftUIGroup ? Self.swiftUIAccentImage : nil
        titleControl.toolTip = isSwiftUIGroup ? NSLocalizedString("LookInside Pro · Activated", comment: "") : nil
        titleControl.needsLayout = true

        detailButton.isHidden = !shouldShowDetailButton(group: attrGroup.identifier)

        sectionViews.forEach { $0.removeFromSuperview() }
        sectionViews.removeAll()
        sectionViewPool.recycleAll()

        for (idx, section) in (attrGroup.attrSections ?? []).enumerated() {
            if !section.isUserCustom() && !(section.identifier.map { PreferenceManager.shared.isSectionShowing($0) } ?? false) {
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

        if attrGroup.identifier == AttributesGroup.Identifier.relation {
            showRelationHelpButton()
        } else {
            relationHelpButton?.removeFromSuperview()
        }

        needsLayout = true
    }

    func querySectionView(with section: AttributesSection) -> DashboardSectionView? {
        sectionViews.first { $0.attrSection === section }
    }

    /// Dims the card, except for `rect` when it is not empty, then fades
    /// back after a second.
    func playFadeAnimation(highlightRect rect: CGRect) {
        if fadeView != nil {
            return
        }
        let fadeView = BaseView()
        fadeView.backgroundColor = isDarkMode() ? DashboardStyle.rgb(0, 0, 0, 0.7) : DashboardStyle.rgb(0, 0, 0, 0.6)
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
    static func looksLikeSwiftUI(_ group: AttributesGroup) -> Bool {
        group.isSwiftUIGroup || (group.userCustomTitle?.hasPrefix("SwiftUI") ?? false)
    }

    /// Internal for DashboardRegistrationTests.
    static let groupIconNames: [AttributesGroup.Identifier: String] = {
        let names: [AttributesGroup.Identifier: String] = [
            AttributesGroup.Identifier.class: "dashboard_class",
            AttributesGroup.Identifier.relation: "dashboard_relation",
            AttributesGroup.Identifier.layout: "dashboard_layout",
            AttributesGroup.Identifier.autoLayout: "dashboard_autolayout",
            AttributesGroup.Identifier.viewLayer: "dashboard_layer",
            AttributesGroup.Identifier.uiImageView: "dashboard_imageview",
            AttributesGroup.Identifier.uiLabel: "dashboard_label",
            AttributesGroup.Identifier.uiButton: "dashboard_button",
            AttributesGroup.Identifier.uiControl: "dashboard_control",
            AttributesGroup.Identifier.uiScrollView: "dashboard_scrollview",
            AttributesGroup.Identifier.uiTableView: "dashboard_tableview",
            AttributesGroup.Identifier.uiTextView: "dashboard_textview",
            AttributesGroup.Identifier.uiTextField: "dashboard_textfield",
            AttributesGroup.Identifier.uiVisualEffectView: "dashboard_effectview",
            AttributesGroup.Identifier.uiStackView: "dashboard_stackview",
            AttributesGroup.Identifier.nsImageView: "dashboard_imageview",
            AttributesGroup.Identifier.nsControl: "dashboard_control",
            AttributesGroup.Identifier.nsButton: "dashboard_button",
            AttributesGroup.Identifier.nsScrollView: "dashboard_scrollview",
            AttributesGroup.Identifier.nsTableView: "dashboard_tableview",
            AttributesGroup.Identifier.nsTextView: "dashboard_textview",
            AttributesGroup.Identifier.nsTextField: "dashboard_textfield",
            AttributesGroup.Identifier.nsVisualEffectView: "dashboard_effectview",
            AttributesGroup.Identifier.nsStackView: "dashboard_stackview",
            // NSControl subclasses share the green hue NSControl itself uses.
            AttributesGroup.Identifier.nsSlider: "dashboard_slider",
            AttributesGroup.Identifier.nsStepper: "dashboard_stepper",
            AttributesGroup.Identifier.nsSwitch: "dashboard_switch",
            AttributesGroup.Identifier.nsSegmentedControl: "dashboard_segmentedcontrol",
            AttributesGroup.Identifier.nsLevelIndicator: "dashboard_levelindicator",
            AttributesGroup.Identifier.nsProgressIndicator: "dashboard_progressindicator",
            AttributesGroup.Identifier.nsPopUpButton: "dashboard_popupbutton",
            AttributesGroup.Identifier.nsComboBox: "dashboard_combobox",
            AttributesGroup.Identifier.nsColorWell: "dashboard_colorwell",
            AttributesGroup.Identifier.nsDatePicker: "dashboard_datepicker",
            // Data containers share the blue hue NSTableView uses.
            AttributesGroup.Identifier.nsOutlineView: "dashboard_outlineview",
            AttributesGroup.Identifier.nsCollectionView: "dashboard_collectionview",
            AttributesGroup.Identifier.nsGridView: "dashboard_gridview",
            // Structural containers share the pink hue NSStackView uses.
            AttributesGroup.Identifier.nsSplitView: "dashboard_splitview",
            AttributesGroup.Identifier.nsTabView: "dashboard_tabview",
            AttributesGroup.Identifier.nsBox: "dashboard_box",
            // Window chrome gets a graphite hue no content group uses.
            AttributesGroup.Identifier.nsWindow: "dashboard_window",
            AttributesGroup.Identifier.uiWindowScene: "dashboard_windowscene",
            AttributesGroup.Identifier.uiTraitCollection: "dashboard_traitcollection",
            AttributesGroup.Identifier.layoutGuide: "dashboard_layoutguide",
            AttributesGroup.Identifier.nsCell: "dashboard_cell",
            AttributesGroup.Identifier.uiSlider: "dashboard_slider",
            AttributesGroup.Identifier.uiStepper: "dashboard_stepper",
            AttributesGroup.Identifier.uiSwitch: "dashboard_switch",
            AttributesGroup.Identifier.uiSegmentedControl: "dashboard_segmentedcontrol",
            AttributesGroup.Identifier.uiProgressView: "dashboard_progressindicator",
            AttributesGroup.Identifier.uiActivityIndicatorView: "dashboard_progressindicator",
            AttributesGroup.Identifier.uiPageControl: "dashboard_pagecontrol",
            AttributesGroup.Identifier.uiDatePicker: "dashboard_datepicker",
            AttributesGroup.Identifier.uiColorWell: "dashboard_colorwell",
            AttributesGroup.Identifier.uiRefreshControl: "dashboard_progressindicator",
            AttributesGroup.Identifier.uiPickerView: "dashboard_picker",
            AttributesGroup.Identifier.uiCalendarView: "dashboard_datepicker",
            AttributesGroup.Identifier.uiPasteControl: "dashboard_button",
            AttributesGroup.Identifier.uiCollectionView: "dashboard_collectionview",
            AttributesGroup.Identifier.uiCollectionReusableView: "dashboard_cell",
            AttributesGroup.Identifier.uiTableViewCell: "dashboard_cell",
            AttributesGroup.Identifier.uiTableViewHeaderFooterView: "dashboard_cell",
            AttributesGroup.Identifier.uiNavigationBar: "dashboard_navigationbar",
            AttributesGroup.Identifier.uiTabBar: "dashboard_tabbar",
            AttributesGroup.Identifier.uiToolbar: "dashboard_toolbar",
            AttributesGroup.Identifier.uiSearchBar: "dashboard_searchfield",
            AttributesGroup.Identifier.uiInputView: "dashboard_view",
            AttributesGroup.Identifier.uiContentUnavailableView: "dashboard_view",
            AttributesGroup.Identifier.uiBackgroundExtensionView: "dashboard_effectview",
            AttributesGroup.Identifier.uiWindow: "dashboard_window",
            AttributesGroup.Identifier.uiView: "dashboard_view",
            AttributesGroup.Identifier.nsClipView: "dashboard_scrollview",
            AttributesGroup.Identifier.nsScroller: "dashboard_scrollview",
            AttributesGroup.Identifier.nsBrowser: "dashboard_browser",
            AttributesGroup.Identifier.nsMatrix: "dashboard_gridview",
            AttributesGroup.Identifier.nsPathControl: "dashboard_pathcontrol",
            AttributesGroup.Identifier.nsRuleEditor: "dashboard_ruleeditor",
            AttributesGroup.Identifier.nsSearchField: "dashboard_searchfield",
            AttributesGroup.Identifier.nsComboButton: "dashboard_button",
            AttributesGroup.Identifier.nsGlassEffectView: "dashboard_effectview",
            AttributesGroup.Identifier.nsBackgroundExtensionView: "dashboard_effectview",
            AttributesGroup.Identifier.nsRulerView: "dashboard_ruler",
            AttributesGroup.Identifier.nsTableCellView: "dashboard_cell",
            AttributesGroup.Identifier.nsTableRowView: "dashboard_tableview",
            AttributesGroup.Identifier.nsTableHeaderView: "dashboard_tableview",
            AttributesGroup.Identifier.nsTextInsertionIndicator: "dashboard_textview",
            AttributesGroup.Identifier.nsView: "dashboard_view",
            AttributesGroup.Identifier.caLayer: "dashboard_layer",
            AttributesGroup.Identifier.userCustom: "dashboard_custom",
        ]
        #if DEBUG
            // Fail on the first card rendered rather than only when someone
            // selects the unregistered kind; that is how 16 AppKit control
            // groups once shipped with a borrowed icon. Every group of the
            // catalog, the UIKit ones included: the Host shows both.
            for group in DashboardBlueprintTables.catalog {
                assert(names[group.identifier] != nil, "missing dashboard icon for group \(group.identifier)")
            }
        #endif
        return names
    }()

    /// The icon of a group. Registering a new group means four host-side
    /// places: this table, the group title, the default sections and (when
    /// it has enums) the enum lists. An unregistered group falls back to a
    /// generic icon.
    static func image(for group: AttributesGroup) -> NSImage? {
        let name = group.identifier.flatMap { groupIconNames[$0] }
        assert(name != nil, "missing dashboard icon for group \(group.identifier?.rawValue ?? "nil")")
        return DashboardStyle.image(name ?? "dashboard_layer")
    }

    private static let swiftUIAccentImage: NSImage? = {
        let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }()

    // MARK: - Relation help

    private func showRelationHelpButton() {
        if relationHelpButton == nil {
            let button = NSButton(image: DashboardStyle.image("ic_question") ?? NSImage(), target: self, action: #selector(handleRelationHelpButton))
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
        menuItem.image = DashboardStyle.image("Icon_Inspiration_small")
        menuItem.title = NSLocalizedString("How to display more member variables…", comment: "")
        menuItem.target = self
        menuItem.action = #selector(handleRelationDocument)
        menu.addItem(menuItem)
        if let event = NSApplication.shared.currentEvent, let relationHelpButton {
            NSMenu.popUpContextMenu(menu, with: event, for: relationHelpButton)
        }
    }

    @objc private func handleRelationDocument() {
        AppHelper.showDisabledExternalLinkAlert(withMessage: NSLocalizedString("Legacy member-variable documentation links are disabled in this community build. See the repository README instead.", comment: ""))
    }

    // MARK: - Others

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        UserActionManager.sharedInstance().send(.dashboardClick)
    }

    // MARK: - UserActionManagerDelegate

    func userActionManager(_: UserActionManager, didAct type: UserActionType) {
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

        UserActionManager.sharedInstance().send(.dashboardClick)

        if isCollapsed {
            // Expand a collapsed card first.
            delegate?.dashboardCardViewNeedToggleCollapse(self)
        }

        guard let attrGroup else { return }
        let controller = DashboardAccessoryWindowController(dashboardController: dashboardViewController, group: attrGroup.identifier)
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

        let allSections = attrGroup.identifier.flatMap { DashboardBlueprint.sectionIdentifiers(in: $0) } ?? []
        let hiddenSections = allSections.filter { !PreferenceManager.shared.isSectionShowing($0) }
        if hiddenSections.isEmpty {
            controller.window?.contentView?.isHidden = true
            return
        }
        controller.window?.contentView?.isHidden = false

        let sections = hiddenSections.compactMap { sectionIdentifier in
            (attrGroup.attrSections ?? []).first { $0.identifier == sectionIdentifier }
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

    func dashboardAccessoryWindowControllerWillClose(_: DashboardAccessoryWindowController) {
        sectionViews.forEach { $0.manageState = .none }
        accessoryWindowController = nil
    }

    private func shouldShowDetailButton(group: AttributesGroup.Identifier?) -> Bool {
        if group == .userCustom {
            return false
        }
        // The group's own section count, not the blueprint's: some groups
        // (Layout for NSWindow, for example) are built with fewer sections.
        let actualCount = attrGroup?.attrSections?.count ?? 0
        let blueprintCount = group.flatMap { DashboardBlueprint.sectionIdentifiers(in: $0)?.count } ?? 0
        return min(actualCount, blueprintCount) > 1
    }
}
