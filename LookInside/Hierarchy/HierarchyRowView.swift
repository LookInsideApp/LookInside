//
//  HierarchyRowView.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit

/// Row icons by class, searched along the node's class chain in this order.
private let classIconNames: [(className: String, imageName: String)] = [
    ("UIWindow", "hierarchy_window"),
    ("UIWindowScene", "hierarchy_window"),
    ("UINavigationBar", "hierarchy_navigationbar"),
    ("UITabBar", "hierarchy_tabbar"),
    ("UITextView", "hierarchy_textview"),
    ("UIStackView", "hierarchy_stackview"),
    ("UITextField", "hierarchy_textfield"),
    ("UITableView", "hierarchy_tableview"),
    ("UICollectionView", "hierarchy_collectionview"),
    ("UICollectionViewCell", "hierarchy_collectioncell"),
    ("UICollectionReusableView", "hierarchy_collectionreuseview"),
    ("UITableViewCell", "hierarchy_tablecell"),
    ("UISlider", "hierarchy_slider"),
    ("WKWebView", "hierarchy_webview"),
    ("UIWebView", "hierarchy_webview"),
    ("_UITableViewCellSeparatorView", "hierarchy_tablecellseparator"),
    ("UITableViewCellContentView", "hierarchy_cellcontent"),
    ("_UITableViewHeaderFooterContentView", "hierarchy_cellcontent"),
    ("UITableViewHeaderFooterView", "hierarchy_tableheaderfooter"),
    ("UIScrollView", "hierarchy_scrollview"),
    ("UILabel", "hierarchy_label"),
    ("UIButton", "hierarchy_button"),
    ("UIImageView", "hierarchy_imageview"),
    ("UIControl", "hierarchy_control"),
    ("UIVisualEffectView", "hierarchy_effectview"),

    ("NSWindow", "hierarchy_window"),
    ("NSTabView", "hierarchy_tabbar"),
    ("NSTextView", "hierarchy_textview"),
    ("NSStackView", "hierarchy_stackview"),
    ("NSTextField", "hierarchy_textfield"),
    ("NSTableView", "hierarchy_tableview"),
    ("NSCollectionView", "hierarchy_collectionview"),
    ("NSCollectionViewItem", "hierarchy_collectioncell"),
    ("NSTableCellView", "hierarchy_tablecell"),
    ("NSSlider", "hierarchy_slider"),
    ("NSScrollView", "hierarchy_scrollview"),
    ("NSButton", "hierarchy_button"),
    ("NSImageView", "hierarchy_imageview"),
    ("NSControl", "hierarchy_control"),
    ("NSVisualEffectView", "hierarchy_effectview"),
]

/// Wire-compat fallback for v8 servers (no isSwiftUI flag yet). SwiftUI
/// nodes always get at least one custom attr group whose userCustomTitle
/// starts with "SwiftUI" (LKS_SwiftUIAttrGroupsMaker always emits "SwiftUI
/// Type"). LKS_CustomDisplayItemsMaker (lookin_customDebugInfos path) sets
/// customInfo but never produces SwiftUI-prefixed groups, so this
/// distinguishes correctly. Remove once v8 support is dropped.
private func displayItemLooksLikeSwiftUI(_ item: DisplayItem) -> Bool {
    if item.customInfo?.isSwiftUI == true {
        return true
    }
    return (item.customAttrGroupList ?? []).contains { $0.userCustomTitle?.hasPrefix("SwiftUI") == true }
}

private func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> NSColor {
    NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

class HierarchyRowView: OutlineRowView {
    /// Weak: the table keeps many row views around, and a strong reference
    /// would keep display items (and their screenshots) alive across
    /// hierarchy reloads.
    weak var displayItem: DisplayItem? {
        didSet {
            displayItemDidChange(from: oldValue)
        }
    }

    var minIndentLevel: Int = 0

    /// 左侧的小蓝条图标
    private(set) var eventHandlerButton: NSButton?

    private var dataSource: HierarchyDataSource?
    private var strikethroughLayer: CALayer?
    private var eventHandlerButtonColorLayer: CALayer?
    private var swiftUIBadge: NSImageView?
    private var isFocusingHandlerButton = false {
        didSet {
            guard isFocusingHandlerButton != oldValue else {
                return
            }
            updateEventHandlerButtonLayout()
            updateEventHandlerButtonColors()
        }
    }

    init(dataSource: HierarchyDataSource) {
        self.dataSource = dataSource
        super.init(compactUI: false)
    }

    required init?(coder _: NSCoder) {
        fatalError("HierarchyRowView is not loaded from archives")
    }

    override func layout() {
        super.layout()

        if let eventHandlerButton {
            HierarchyFrameLayout(eventHandlerButton).y(3).toBottom(3).width(10).x(3)
        }
        updateEventHandlerButtonLayout()

        // Put the SwiftUI badge between the title and the (optional)
        // subtitle. The superclass placed the subtitle right after the title,
        // where it would overlap the badge, so move it right and report the
        // row width again.
        if let swiftUIBadge, !swiftUIBadge.isHidden {
            HierarchyFrameLayout(swiftUIBadge).sizeToFit().x(titleLabel.frame.maxX + 4).verAlign()
            var finalMaxX = swiftUIBadge.frame.maxX
            if !subtitleLabel.isHidden, subtitleLabel.alphaValue > 0 {
                HierarchyFrameLayout(subtitleLabel).x(swiftUIBadge.frame.maxX + subtitleLeft)
                finalMaxX = subtitleLabel.frame.maxX
            }
            horizontalScrollWidthManager?.rowDidLayout(withWidth: finalMaxX)
        }

        if let strikethroughLayer, !strikethroughLayer.isHidden {
            let maxX = subtitleLabel.isHidden ? titleLabel.frame.maxX + 2 : subtitleLabel.frame.maxX + 2
            HierarchyFrameLayout(strikethroughLayer)
                .height(1)
                .x(titleLabel.frame.minX - 1)
                .toMaxX(maxX)
                .midY(titleLabel.frame.midY + 1)
        }
    }

    override var isHovered: Bool {
        didSet {
            updateEventHandlerButtonColors()
        }
    }

    override class func insetLeft() -> CGFloat {
        13
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateEventHandlerButtonColors()
    }

    override func setIsDarkMode(_ isDarkMode: Bool) {
        super.setIsDarkMode(isDarkMode)
        updateStrikethroughLayer()
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let point = convert(event.locationInWindow, from: nil)
        isFocusingHandlerButton = point.x < 16
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isFocusingHandlerButton = false
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    // MARK: - Rendering

    private func displayItemDidChange(from previousItem: DisplayItem?) {
        // Even when the item is unchanged its rowViewDelegate may point at
        // another row: select a view, focus it, leave focus, and without this
        // the row could no longer be deselected.
        if let item = displayItem, item.rowViewDelegate !== self {
            item.rowViewDelegate = self
        }
        if displayItem !== previousItem {
            reRender()
        }
    }

    fileprivate func reRender() {
        guard let item = displayItem else {
            return
        }
        isRowSelected = (dataSource?.selectedItem === item)
        isHovered = (dataSource?.hoveredItem === item)
        image = resolveIconImage(for: item)
        indentLevel = UInt(bitPattern: item.indentLevel() - minIndentLevel)
        updateEventsButton()
        updateExpandStatus()
        updateStrikethroughLayer()
        updateLabelStringsAndImageViewAlpha(for: item)
        updateLabelsFonts(for: item)
        updateSwiftUIBadge(for: item)

        needsLayout = true
    }

    fileprivate func updateHoverState() {
        isHovered = (dataSource?.hoveredItem === displayItem)
    }

    private func updateSwiftUIBadge(for item: DisplayItem) {
        let isSwiftUINode = displayItemLooksLikeSwiftUI(item)
        if isSwiftUINode, swiftUIBadge == nil {
            let image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
            image?.isTemplate = true
            let badge = NSImageView()
            badge.image = image
            badge.contentTintColor = AppHelper.accentColor()
            addSubview(badge)
            swiftUIBadge = badge
        }
        swiftUIBadge?.isHidden = !isSwiftUINode
        toolTip = isSwiftUINode ? NSLocalizedString("LookInside Pro · Activated", comment: "") : nil
    }

    private func updateLabelStringsAndImageViewAlpha(for item: DisplayItem) {
        let titleColor: NSColor
        let subtitleColor: NSColor
        if isSelected {
            titleColor = .white
            subtitleColor = .white
            imageView.alphaValue = 1
        } else if shouldFadeContent(of: item) {
            titleColor = .tertiaryLabelColor
            subtitleColor = .tertiaryLabelColor
            imageView.alphaValue = 0.6
        } else {
            titleColor = .labelColor
            subtitleColor = .secondaryLabelColor
            imageView.alphaValue = 1
        }

        let title = NSMutableAttributedString(string: item.title(), attributes: [.foregroundColor: titleColor])
        let subtitle = NSMutableAttributedString(string: item.subtitle() ?? "", attributes: [.foregroundColor: subtitleColor])

        if item.isInSearch, let searchString = item.highlightedSearchString, !searchString.isEmpty {
            // Filtering, and this row matched the search string.
            let background = isDarkMode ? rgba(190, 120, 0, 1) : rgba(255, 240, 100, 1)
            let attributes: [NSAttributedString.Key: Any] = [
                .backgroundColor: background,
                .foregroundColor: NSColor.labelColor,
            ]
            for string in [title, subtitle] {
                let range = (string.string as NSString).range(of: searchString, options: .caseInsensitive)
                if range.location != NSNotFound {
                    string.addAttributes(attributes, range: range)
                }
            }
        }

        titleLabel.attributedStringValue = title
        subtitleLabel.attributedStringValue = subtitle
    }

    private func updateEventsButton() {
        guard let item = displayItem, !(item.eventHandlers ?? []).isEmpty else {
            eventHandlerButton?.isHidden = true
            return
        }
        if eventHandlerButton == nil {
            let button = NSButton()
            button.title = ""
            button.target = self
            button.action = #selector(handleClickEventHandlerButton(_:))
            button.wantsLayer = true
            button.isBordered = false
            button.bezelStyle = .roundRect
            button.layer?.backgroundColor = NSColor.clear.cgColor
            addSubview(button)
            eventHandlerButton = button

            let colorLayer = CALayer()
            colorLayer.actions = ["contents": NSNull()]
            button.layer?.addSublayer(colorLayer)
            eventHandlerButtonColorLayer = colorLayer
        }
        eventHandlerButton?.isHidden = false
        updateEventHandlerButtonColors()
    }

    private func updateStrikethroughLayer() {
        guard let item = displayItem, item.hasPreviewBoxAbility(), item.inNoPreviewHierarchy else {
            strikethroughLayer?.isHidden = true
            return
        }
        let layer: CALayer
        if let strikethroughLayer {
            layer = strikethroughLayer
        } else {
            layer = CALayer()
            layer.removeImplicitAnimations()
            self.layer?.addSublayer(layer)
            strikethroughLayer = layer
        }
        if isSelected {
            layer.backgroundColor = NSColor.white.withAlphaComponent(0.75).cgColor
        } else {
            layer.backgroundColor = isDarkMode ? rgba(255, 255, 255, 0.2).cgColor : rgba(0, 0, 0, 0.2).cgColor
        }
        layer.isHidden = false
        needsLayout = true
    }

    private func updateEventHandlerButtonColors() {
        guard let eventHandlerButton, !eventHandlerButton.isHidden else {
            return
        }
        let color = isSelected ? NSColor.white : rgba(74, 144, 226, isFocusingHandlerButton ? 1 : 0.5)
        eventHandlerButtonColorLayer?.backgroundColor = color.cgColor
    }

    private func updateEventHandlerButtonLayout() {
        guard let eventHandlerButtonColorLayer else {
            return
        }
        let width: CGFloat = isFocusingHandlerButton ? 8 : 5
        HierarchyFrameLayout(eventHandlerButtonColorLayer).fullHeight().width(width).horAlign()
        eventHandlerButtonColorLayer.cornerRadius = width / 2
    }

    private func updateLabelsFonts(for item: DisplayItem) {
        let noImage = item.inNoPreviewHierarchy || item.inHiddenHierarchy
        let isPrivate = PrivateDiscriminatorStore.shared.isPrivateDisplayItem(item)
        if !item.isUserCustom(), noImage || isPrivate {
            titleLabel.font = AppHelper.italicFont(ofSize: 13)
            subtitleLabel.font = AppHelper.italicFont(ofSize: 12)
        } else {
            titleLabel.font = .systemFont(ofSize: 13)
            subtitleLabel.font = .systemFont(ofSize: 12)
        }
        needsLayout = true
    }

    private func updateExpandStatus() {
        guard let item = displayItem, item.isExpandable else {
            status = .notExpandable
            return
        }
        status = item.isExpanded ? .expanded : .collapsed
    }

    private func shouldFadeContent(of item: DisplayItem) -> Bool {
        if item.isInSearch, (item.highlightedSearchString ?? "").isEmpty {
            return true
        }
        guard item.hasPreviewBoxAbility() else {
            return false
        }
        return item.inHiddenHierarchy || item.inNoPreviewHierarchy
    }

    private func resolveIconImage(for item: DisplayItem) -> NSImage? {
        var imageName: String?
        if item.isUserCustom() {
            imageName = "hierarchy_custom"
        } else if item.hostViewControllerObject != nil || item.hostWindowControllerObject != nil {
            imageName = "hierarchy_controller"
        } else {
            switch item.resolvedNodeKind() {
            case .view:
                let classChain = item.viewObject?.classChainList ?? []
                imageName = classChain.lazy.compactMap { className in
                    classIconNames.first { $0.className == className }?.imageName
                }.first ?? "hierarchy_view"
            case .layer, .viewOuterLayer, .backingLayer:
                // A view's outer layer and a backing layer node are still
                // layers as far as the row icon goes.
                for className in item.layerObject?.classChainList ?? [] {
                    if className == "CAShapeLayer" {
                        imageName = "hierarchy_shapelayer"
                        break
                    }
                    if className == "CAGradientLayer" {
                        imageName = "hierarchy_gradientlayer"
                        break
                    }
                }
                if imageName == nil {
                    imageName = "hierarchy_layer"
                }
            case .window, .windowScene:
                imageName = "hierarchy_window"
            case .layoutGuide:
                imageName = "hierarchy_layoutguide"
            case .cell:
                imageName = "hierarchy_cell"
            default:
                break
            }
        }
        let name = imageName ?? "hierarchy_view"

        if dataSource?.selectedItem === item, let selectedImage = NSImage(named: name + "_selected") {
            return selectedImage
        }
        return NSImage(named: name)
    }

    // MARK: - Event handlers

    @objc private func handleClickEventHandlerButton(_ button: NSButton) {
        guard let item = displayItem else {
            return
        }
        // A row inside a Live Doc's window is editable; rows in a read-only
        // archive or launch window are not.
        let editable = LiveDocument.document(in: window) != nil

        let controller = HierarchyHandlersPopoverController(displayItem: item, editable: editable)
        let popover = NSPopover()
        popover.animates = false
        popover.behavior = .transient
        popover.contentSize = controller.neededSize()
        popover.contentViewController = controller
        popover.show(relativeTo: NSRect(origin: .zero, size: button.bounds.size), of: button, preferredEdge: .maxY)
    }
}

extension HierarchyRowView: DisplayItemDelegate {
    func displayItem(_: DisplayItem, propertyDidChange property: LookinDisplayItemProperty) {
        if property == .isHovered {
            updateHoverState()
        } else {
            reRender()
        }
    }
}
