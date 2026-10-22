//
//  DashboardAttributeEnumsView.swift
//  LookInside
//
//  Created by Li Kai on 2019/2/21.
//  https://lookin.work
//

import AppKit
import FoundationToolbox

/// An enum attribute: the case name, and a menu of the cases on click.
@Loggable(subsystem: "com.lookinside.app")
final class DashboardAttributeEnumsView: DashboardAttributeView {
    private let labelX: CGFloat = 5
    private let labelRight: CGFloat = 20

    private let iconImageView = NSImageView()
    private let titleLabel = TextLabel()
    private let textLabel = TextLabel()

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.cornerRadius = DashboardMetrics.cardControlCornerRadius

        titleLabel.textColor = NSColor(named: "DashboardInputAccessoryColor")
        titleLabel.font = DashboardStyle.font(10)
        titleLabel.maximumNumberOfLines = 1
        addSubview(titleLabel)

        textLabel.textColor = NSColor(named: "DashboardCardValueColor")
        textLabel.maximumNumberOfLines = 0
        textLabel.font = DashboardStyle.font(12)
        addSubview(textLabel)

        iconImageView.image = DashboardStyle.image("Icon_ArrowUpDown")
        addSubview(iconImageView)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        iconImageView.dashboardLayout.sizeToFit().verAlign().right(9)
        if titleLabel.isHidden {
            textLabel.dashboardLayout.x(labelX).toRight(labelRight).heightToFit().verAlign()
        } else {
            let titleHeight = titleLabel.sizeThatFits(DashboardMetrics.maxSize).height
            let titleY: CGFloat = 3
            titleLabel.dashboardLayout.x(labelX).toRight(labelRight).height(titleHeight).y(titleY)
            textLabel.dashboardLayout.x(labelX).toRight(labelRight).heightToFit().y(titleY + titleHeight + 1)
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        let contentWidth = limitedSize.width - labelRight - labelX
        let textHeight = textLabel.sizeThatFits(NSSize(width: contentWidth, height: .greatestFiniteMagnitude)).height
        var size = limitedSize
        if titleLabel.isHidden {
            size.height = textHeight + 10
        } else {
            let titleHeight = titleLabel.sizeThatFits(NSSize(width: contentWidth, height: .greatestFiniteMagnitude)).height
            size.height = 3 + titleHeight + 1 + textHeight + 4
        }
        return size
    }

    override func renderWithAttribute() {
        guard let attribute else { return }
        // Known attributes show their short title above the value.
        if !attribute.isUserCustom(), let briefTitle = DashboardBlueprint.briefTitle(withAttrID: attribute.identifier), !briefTitle.isEmpty {
            titleLabel.stringValue = briefTitle
            titleLabel.isHidden = false
        } else {
            titleLabel.isHidden = true
        }

        if attribute.attrType == .enumString {
            guard let text = attribute.value as? String else {
                assertionFailure()
                return
            }
            textLabel.stringValue = text
        } else {
            let enumValue = (attribute.value as? NSNumber)?.intValue ?? 0
            let enumListName = DashboardBlueprint.enumListName(withAttrID: attribute.identifier)
            textLabel.stringValue = EnumListRegistry.shared.desc(forEnumName: enumListName, value: enumValue) ?? ""
        }
    }

    override func mouseDown(with event: NSEvent) {
        let menu = attribute?.isUserCustom() == true ? makeMenuForUserCustom() : makeMenuForPreset()
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    override func dashboardViewControllerDidChange() {
        backgroundColorName = "DashboardCardValueBGColor"
    }

    // MARK: - Menus

    private func makeMenuForPreset() -> NSMenu {
        let currentOSVersion = dashboardViewController?.currentDataSource()?.rawHierarchyInfo?.appInfo?.osMainVersion ?? 0
        let menu = NSMenu()
        menu.autoenablesItems = false
        let enumListName = DashboardBlueprint.enumListName(withAttrID: attribute?.identifier)
        let currentValue = (attribute?.value as? NSNumber)?.intValue ?? 0
        let editable = canEdit()
        for enumItem in EnumListRegistry.shared.items(forEnumName: enumListName) ?? [] {
            let validOSVersion = currentOSVersion >= enumItem.availableOSVersion
            let item = NSMenuItem()
            item.image = NSImage(size: NSSize(width: 1, height: 22))
            item.title = validOSVersion ? enumItem.desc : String(format: NSLocalizedString("%1$@ (iOS %2$lld)", comment: ""), enumItem.desc, enumItem.availableOSVersion)
            item.representedObject = NSNumber(value: enumItem.value)
            item.isEnabled = editable && validOSVersion
            item.target = self
            item.action = #selector(handleMenuItem(_:))
            item.state = enumItem.value == currentValue ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    private func makeMenuForUserCustom() -> NSMenu {
        let menu = NSMenu()
        guard let cases = attribute?.extraValue as? [Any], !cases.isEmpty else {
            return menu
        }
        let editable = canEdit()
        for case let text as String in cases {
            let item = NSMenuItem()
            item.image = NSImage(size: NSSize(width: 1, height: 22))
            item.title = text
            item.representedObject = text
            item.isEnabled = editable
            item.target = self
            item.action = #selector(handleMenuItem(_:))
            item.state = (attribute?.value as? NSObject)?.isEqual(text) == true ? .on : .off
            menu.addItem(item)
        }
        return menu
    }

    @objc private func handleMenuItem(_ item: NSMenuItem) {
        let expectedValue = item.representedObject as? NSObject
        if let expectedValue, let current = attribute?.value, expectedValue.isEqual(current) {
            #log(.default, "修改没有变化，不做任何提交")
            return
        }
        submitRenderingOnSuccess(expectedValue)
    }
}
