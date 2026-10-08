//
//  DashboardSectionView.swift
//  LookInside
//
//  Created by Li Kai on 2019/6/7.
//  https://lookin.work
//

import AppKit

/// Whether a section shows a button that adds it to, or removes it from,
/// its card.
enum DashboardSectionManageState {
    case none
    case canAdd
    case canRemove
}

/// One section of a card: an optional title and separator, then the
/// attribute views flowed into rows.
final class DashboardSectionView: BaseView {
    private let titleMarginTop: CGFloat = 6

    private var attrViews: [DashboardAttributeView] = []
    private var titleLabel: TextLabel?
    private let topSepLayer = CALayer()
    private var manageButton: NSButton?
    private var jsonPopupButton: NSButton?

    weak var dashboardViewController: DashboardViewController?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // Lets the separator run past the right edge.
        layer?.masksToBounds = false

        topSepLayer.removeImplicitAnimations()
        layer?.addSublayer(topSepLayer)

        updateColors()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    var attrSection: AttributesSection? {
        didSet { renderSection() }
    }

    var showTopSeparator = false {
        didSet { topSepLayer.isHidden = !showTopSeparator }
    }

    var manageState: DashboardSectionManageState = .none {
        didSet { renderManageState() }
    }

    // MARK: - Layout

    override func layout() {
        super.layout()

        var contentsX: CGFloat = 0
        let selfWidth = frame.width
        var contentsY: CGFloat = 0

        if let manageButton, manageButton.isVisible {
            let y: CGFloat
            if topSepLayer.isHidden {
                y = 0
            } else if titleLabel?.isVisible == true {
                y = 6
            } else {
                y = 9
            }
            manageButton.dashboardLayout.sizeToFit().x(0).y(y)
            contentsX = manageButton.frame.maxX + 6
        }

        if let jsonPopupButton, jsonPopupButton.isVisible {
            jsonPopupButton.dashboardLayout.width(30).height(28).right(-5).y(0)
        }

        if !topSepLayer.isHidden {
            topSepLayer.dashboardLayout.x(contentsX).width(selfWidth).height(1).y(0)
            contentsY = DashboardMetrics.attrItemVerInterspace
        }

        if let titleLabel, titleLabel.isVisible {
            var titleWidth = selfWidth
            if jsonPopupButton?.isVisible == true {
                titleWidth -= 20
            }
            titleLabel.dashboardLayout.x(contentsX).width(titleWidth).heightToFit().y(topSepLayer.isHidden ? 0 : titleMarginTop)
            contentsY = titleLabel.frame.maxY + DashboardMetrics.attrItemVerInterspace
        }

        var rowTop = contentsY
        for row in rowsOfVisibleAttrViews(inAvailableWidth: selfWidth) {
            var itemX = contentsX
            var rowHeight: CGFloat = 0
            for view in row {
                let width = width(of: view, inAvailableWidth: selfWidth)
                view.dashboardLayout.width(width).heightToFit().x(itemX).y(rowTop)
                // A row is as tall as its tallest item, so a 21 pt switch
                // does not clip the 38 pt number input next to it.
                rowHeight = max(rowHeight, view.frame.height)
                itemX = view.frame.maxX + DashboardMetrics.attrItemHorInterspace
            }
            rowTop += rowHeight + DashboardMetrics.attrItemVerInterspace
        }
    }

    /// The width an attribute view gets in a container of `availableWidth`.
    /// Layout and measuring share it so they never disagree.
    private func width(of view: DashboardAttributeView, inAvailableWidth availableWidth: CGFloat) -> CGFloat {
        let numberOfColumns = view.numberOfColumnsOccupied()
        if numberOfColumns == 0 {
            return view.sizeThatFits(DashboardMetrics.maxSize).width
        }
        let horSpace = DashboardMetrics.attrItemHorInterspace
        return floor((availableWidth + horSpace) / CGFloat(numberOfColumns)) - horSpace
    }

    /// The visible attribute views grouped into rows the way layout places
    /// them, so a row is never measured at one height and drawn at another.
    private func rowsOfVisibleAttrViews(inAvailableWidth availableWidth: CGFloat) -> [[DashboardAttributeView]] {
        var rows: [[DashboardAttributeView]] = []
        var currentRowWidth: CGFloat = 0
        let horSpace = DashboardMetrics.attrItemHorInterspace
        for view in attrViews where view.isVisible {
            let width = width(of: view, inAvailableWidth: availableWidth)
            if !rows.isEmpty, currentRowWidth + horSpace + width <= availableWidth {
                currentRowWidth += horSpace + width
                rows[rows.count - 1].append(view)
            } else {
                rows.append([view])
                currentRowWidth = width
            }
        }
        return rows
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var height: CGFloat = 0
        if !topSepLayer.isHidden {
            height += DashboardMetrics.attrItemVerInterspace
        }
        if let titleLabel, titleLabel.isVisible {
            var titleWidth = limitedSize.width
            if jsonPopupButton?.isVisible == true {
                titleWidth -= 20
            }
            height += titleLabel.sizeThatFits(NSSize(width: titleWidth, height: .greatestFiniteMagnitude)).height + titleMarginTop
        }

        for (rowIdx, row) in rowsOfVisibleAttrViews(inAvailableWidth: limitedSize.width).enumerated() {
            var rowHeight: CGFloat = 0
            for view in row {
                // Measured at the width the item gets, not the full width:
                // wrapping labels grow when narrowed.
                let width = width(of: view, inAvailableWidth: limitedSize.width)
                rowHeight = max(rowHeight, view.sizeThatFits(NSSize(width: width, height: .greatestFiniteMagnitude)).height)
            }
            if rowIdx > 0 {
                height += DashboardMetrics.attrItemVerInterspace
            }
            height += rowHeight
        }

        var size = limitedSize
        size.height = height
        return size
    }

    override func updateColors() {
        super.updateColors()
        topSepLayer.backgroundColor = DashboardStyle.separatorColor(isDarkMode: isDarkMode()).cgColor
    }

    // MARK: - Rendering

    private func renderSection() {
        guard let attrSection else {
            assertionFailure()
            return
        }

        if let title = resolveSectionTitle(), !title.isEmpty {
            let label: TextLabel
            if let titleLabel {
                label = titleLabel
                label.isHidden = false
            } else {
                label = TextLabel()
                label.font = .boldSystemFont(ofSize: 12)
                addSubview(label)
                titleLabel = label
            }
            label.stringValue = title
        } else {
            titleLabel?.isHidden = true
        }

        var notUsedViews = attrViews
        for attr in attrSection.attributes ?? [] {
            guard let viewClass = Self.attrViewClass(for: attr.attrType, identifier: attr.identifier) else {
                // Debug builds stop here so a missing case surfaces at once;
                // release builds skip the attribute and log it.
                NSLog("LookInside dashboard: skipping attribute with unsupported attrType=%ld identifier=%@", attr.attrType.rawValue, attr.identifier ?? "nil")
                assertionFailure("LookInside dashboard: no attrView class for attrType=\(attr.attrType.rawValue) identifier=\(attr.identifier ?? "nil")")
                continue
            }
            let view: DashboardAttributeView
            if let index = notUsedViews.firstIndex(where: { type(of: $0) == viewClass }) {
                view = notUsedViews.remove(at: index)
                view.isHidden = false
            } else {
                view = viewClass.init(frame: .zero)
                view.dashboardViewController = dashboardViewController
                attrViews.append(view)
                addSubview(view)
            }
            view.attribute = attr
        }
        notUsedViews.forEach { $0.isHidden = true }

        let hasJSONAttr = (attrSection.attributes ?? []).contains { $0.attrType == .json }
        if hasJSONAttr {
            showJSONPopupButton()
        } else {
            jsonPopupButton?.removeFromSuperview()
        }

        needsLayout = true
    }

    /// The view class for an attribute type (and, for custom objects, its
    /// identifier); nil when there is none.
    static func attrViewClass(for type: LookinAttrType, identifier: String?) -> DashboardAttributeView.Type? {
        switch type {
        case .cgRect:
            return DashboardAttributeRectView.self
        case .uiEdgeInsets:
            return DashboardAttributeInsetsView.self
        case .BOOL:
            return DashboardAttributeSwitchView.self
        case .float, .double, .long, .unsignedLong, .int, .unsignedInt:
            return DashboardAttributeNumberInputView.self
        case .uiColor:
            return DashboardAttributeColorView.self
        case .enumInt, .enumLong, .enumString:
            return DashboardAttributeEnumsView.self
        case .cgPoint:
            return DashboardAttributePointView.self
        case .cgSize:
            return DashboardAttributeSizeView.self
        case .nsString:
            return DashboardAttributeTextView.self
        case .shadow:
            return DashboardAttributeShadowView.self
        case .json:
            return DashboardAttributeJSONView.self
        case .customObj:
            switch identifier ?? "" {
            case "lookinside.private_discriminator.field":
                return DashboardAttributePrivateDiscriminatorView.self
            case LookinAttr_UITableView_RowsNumber_Number:
                return DashboardAttributeRowsCountView.self
            case LookinAttr_Class_Class_Class:
                return DashboardAttributeClassView.self
            case LookinAttr_Relation_Relation_Relation:
                return DashboardAttributeRelationView.self
            case LookinAttr_AutoLayout_Constraints_Constraints:
                return DashboardAttributeConstraintsView.self
            case LookinAttr_UIImageView_Open_Open, LookinAttr_NSImageView_Open_Open:
                return DashboardAttributeOpenImageView.self
            case LookinAttr_UIVisualEffectView_Style_Style:
                return DashboardAttributeEnumsView.self
            default:
                return nil
            }
        default:
            return nil
        }
    }

    private func showJSONPopupButton() {
        if jsonPopupButton != nil {
            return
        }
        let button = NSButton(image: DashboardStyle.image("open_newwindow") ?? NSImage(), target: self, action: #selector(handleJSONPopupButton))
        button.bezelStyle = .roundRect
        button.isBordered = false
        addSubview(button)
        jsonPopupButton = button
    }

    @objc private func handleJSONPopupButton() {
        guard let view = attrViews.first(where: { $0.attribute?.attrType == .json }) as? DashboardAttributeJSONView else {
            assertionFailure()
            return
        }
        view.showInNewWindow()
    }

    private func resolveSectionTitle() -> String? {
        guard let attrSection else { return nil }
        if !attrSection.isUserCustom() {
            return DashboardBlueprint.sectionTitle(withSectionID: attrSection.identifier)
        }
        guard let attr = attrSection.attributes?.first else {
            assertionFailure()
            return nil
        }
        // A user-custom switch carries its title on the checkbox.
        return attr.attrType == .BOOL ? nil : attr.displayTitle
    }

    // MARK: - Manage

    private func renderManageState() {
        let imageName: String
        switch manageState {
        case .none:
            manageButton?.isHidden = true
            needsLayout = true
            return
        case .canAdd:
            imageName = "icon_manage_add"
        case .canRemove:
            imageName = "icon_manage_remove"
        }
        let image = DashboardStyle.image(imageName)
        if let manageButton {
            manageButton.image = image
            manageButton.isHidden = false
        } else {
            let button = NSButton(image: image ?? NSImage(), target: self, action: #selector(handleManageButton))
            button.bezelStyle = .roundRect
            button.isBordered = false
            addSubview(button)
            manageButton = button
        }
        needsLayout = true
    }

    @objc private func handleManageButton() {
        guard let identifier = attrSection?.identifier else { return }
        let manager = PreferenceManager.shared
        switch manageState {
        case .canAdd:
            manager.showSection(identifier)
        case .canRemove:
            manager.hideSection(identifier)
        case .none:
            assertionFailure()
        }
    }
}

/// Reuses section views across renders of a card, keyed by section
/// identifier (by attribute titles for user-custom sections).
final class DashboardSectionViewPool {
    /// Views handed out since the last `recycleAll()`.
    private var dequeuedViews = Set<ObjectIdentifier>()
    /// Every view made, dequeued or not.
    private var cache: [String: [DashboardSectionView]] = [:]

    func recycleAll() {
        dequeuedViews.removeAll()
    }

    func dequeueView(for section: AttributesSection) -> DashboardSectionView {
        let key = Self.cacheKey(for: section)
        if let view = cache[key, default: []].first(where: { !dequeuedViews.contains(ObjectIdentifier($0)) }) {
            dequeuedViews.insert(ObjectIdentifier(view))
            return view
        }
        let view = DashboardSectionView()
        dequeuedViews.insert(ObjectIdentifier(view))
        cache[key, default: []].append(view)
        return view
    }

    static func cacheKey(for section: AttributesSection) -> String {
        if !section.isUserCustom() {
            return section.identifier ?? ""
        }
        return (section.attributes ?? []).map { $0.displayTitle ?? "" }.joined(separator: ",")
    }
}
