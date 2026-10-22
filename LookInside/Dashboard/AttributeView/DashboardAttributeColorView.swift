//
//  DashboardAttributeColorView.swift
//  LookInside
//
//  Created by Li Kai on 2019/2/21.
//  https://lookin.work
//

import AppKit
import FoundationToolbox

/// The rounded box of a colour attribute; a click opens the colour menu.
private final class DashboardAttributeColorContainerView: BaseView {
    var onMouseDown: ((NSEvent) -> Void)?

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        onMouseDown?(event)
    }
}

/// A colour: swatch, hex or RGBA text, and the colour's alias names from
/// the app's colour configuration.
@Loggable(subsystem: "com.lookinside.app")
final class DashboardAttributeColorView: DashboardAttributeView, NSMenuDelegate {
    private let mainContainerHeight: CGFloat = 30
    private let aliasLabelMarginTop: CGFloat = 1
    private let labelX: CGFloat = 28

    /// Border and shadow colours show no alias.
    private let identifiersToHideAlias: Set<String> = [
        LookinAttr_ViewLayer_Border_Color,
        LookinAttr_ViewLayer_Shadow_Color,
    ]

    private let containerView = DashboardAttributeColorContainerView()
    private let indicatorLayer = ColorIndicatorLayer()
    private let iconImageView = NSImageView()
    private let descLabel = TextLabel()
    private var aliasLabel: TextLabel?
    private var rgbaFormatObservation: NSKeyValueObservation?

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        containerView.layer?.cornerRadius = DashboardMetrics.cardControlCornerRadius
        containerView.onMouseDown = { [weak self] event in
            self?.handleClick(event)
        }
        addSubview(containerView)

        containerView.layer?.addSublayer(indicatorLayer)

        iconImageView.image = DashboardStyle.image("Icon_ArrowUpDown")
        containerView.addSubview(iconImageView)

        descLabel.textColor = NSColor(named: "DashboardCardValueColor")
        descLabel.font = DashboardStyle.font(13)
        containerView.addSubview(descLabel)

        // Re-render when the user switches between hex and RGBA.
        rgbaFormatObservation = PreferenceManager.shared.observe(\.rgbaFormat, options: [.new]) { [weak self] _, _ in
            runOnMain { self?.renderWithAttribute() }
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        containerView.dashboardLayout.fullWidth().height(mainContainerHeight).y(0)
        indicatorLayer.dashboardLayout.width(16).height(16).x(8).verAlign()
        descLabel.dashboardLayout.x(labelX).toRight(20).heightToFit().verAlign().offsetY(-1)
        iconImageView.dashboardLayout.sizeToFit().verAlign().right(9)
        if let aliasLabel, aliasLabel.isVisible {
            aliasLabel.dashboardLayout.x(labelX).toRight(0).y(containerView.frame.maxY + aliasLabelMarginTop).heightToFit()
        }
    }

    override func renderWithAttribute() {
        iconImageView.isHidden = !canEdit()

        let color = NSColor.sRGBColor(fromRGBAComponents: attribute?.value as? [NSNumber])
        indicatorLayer.color = color

        if let color {
            descLabel.stringValue = PreferenceManager.shared.rgbaFormat ? color.rgbaString() : color.hexString()
        } else {
            descLabel.stringValue = "nil"
        }

        let dataSource = dashboardViewController?.currentDataSource()
        let alias = dataSource?.alias(for: color)
        if let alias, !identifiersToHideAlias.contains(attribute?.identifier ?? "") {
            let label: TextLabel
            if let aliasLabel {
                label = aliasLabel
            } else {
                label = TextLabel()
                label.textColor = NSColor(named: "DashboardCardValueColor")
                addSubview(label)
                aliasLabel = label
            }
            label.isHidden = false
            label.attributedStringValue = DashboardText.attributed(alias.joined(separator: "\n"), font: DashboardStyle.font(11), lineHeight: 18)
        } else {
            aliasLabel?.isHidden = true
        }
        needsLayout = true
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var height = mainContainerHeight
        if let aliasLabel, aliasLabel.isVisible {
            let width = limitedSize.width - labelX
            height += aliasLabelMarginTop + aliasLabel.sizeThatFits(NSSize(width: width, height: .greatestFiniteMagnitude)).height
        }
        var size = limitedSize
        size.height = height
        return size
    }

    override func dashboardViewControllerDidChange() {
        containerView.backgroundColorName = "DashboardCardValueBGColor"
    }

    // MARK: - Menu

    private func handleClick(_ event: NSEvent) {
        guard canEdit(), let menu = dashboardViewController?.currentDataSource()?.selectColorMenu else { return }
        menu.delegate = self
        NSMenu.popUpContextMenu(menu, with: event, for: containerView)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        for menuItem in menu.items {
            if menuItem.hasSubmenu {
                menuItem.submenu?.items.forEach(updateMenuItem)
            } else {
                updateMenuItem(menuItem)
            }
        }
    }

    private func updateMenuItem(_ menuItem: NSMenuItem) {
        let dataSource = dashboardViewController?.currentDataSource()
        if menuItem.tag == dataSource?.customColorMenuItemTag {
            // "Custom colour…"
            menuItem.state = .off
            menuItem.target = self
            menuItem.action = #selector(handleCustomColorMenuItem)
            return
        }
        if menuItem.tag == dataSource?.toggleColorFormatMenuItemTag {
            menuItem.state = .off
            menuItem.target = self
            menuItem.action = #selector(handleToggleColorFormatMenuItem)
            return
        }

        menuItem.target = self
        menuItem.action = #selector(handlePresetMenuItem(_:))
        let color = menuItem.representedObject as? NSColor
        let currentValue = attribute?.value as? NSObject
        let isCurrent: Bool
        if let color {
            isCurrent = currentValue?.isEqual(color.sRGBAComponents()) ?? false
        } else {
            // Both nil: the item for "no colour" while the value is nil.
            isCurrent = currentValue == nil
        }
        menuItem.state = isCurrent ? .on : .off
    }

    @objc private func handlePresetMenuItem(_ item: NSMenuItem) {
        modify(to: item.representedObject as? NSColor)
    }

    @objc private func handleCustomColorMenuItem() {
        let initialColor = NSColor.sRGBColor(fromRGBAComponents: attribute?.value as? [NSNumber])
        let panel = NSColorPanel.shared
        panel.showsAlpha = true
        panel.isContinuous = false
        if let initialColor {
            panel.color = initialColor
        }
        panel.setTarget(self)
        panel.setAction(#selector(handleSystemColorPanel(_:)))
        panel.orderFront(self)
    }

    @objc private func handleToggleColorFormatMenuItem() {
        let manager = PreferenceManager.shared
        manager.rgbaFormat = !manager.rgbaFormat
    }

    @objc private func handleSystemColorPanel(_ panel: NSColorPanel) {
        modify(to: panel.color)
    }

    private func modify(to targetColor: NSColor?) {
        let expectedValue = targetColor?.sRGBAComponents()
        if let currentValue = attribute?.value as? NSObject, let expectedValue, currentValue.isEqual(expectedValue) {
            #log(.default, "修改没有变化，不做任何提交")
            return
        }
        submitRenderingOnSuccess(expectedValue)
    }
}
