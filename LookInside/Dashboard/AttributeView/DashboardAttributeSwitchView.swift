//
//  DashboardAttributeSwitchView.swift
//  LookInside
//
//  Created by Li Kai on 2019/2/21.
//  https://lookin.work
//

import AppKit

/// A BOOL attribute as a checkbox.
final class DashboardAttributeSwitchView: DashboardAttributeView {
    private let button = NSButton()

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        button.ignoresMultiClick = true
        button.setButtonType(.switch)
        button.target = self
        button.action = #selector(handleButton)
        button.font = DashboardStyle.font(13)
        addSubview(button)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        button.dashboardLayout.fullFrame()
    }

    override func renderWithAttribute() {
        guard let attribute else { return }
        let title: String?
        if attribute.isUserCustom() {
            title = attribute.displayTitle
        } else {
            title = DashboardBlueprint.briefTitle(withAttrID: attribute.identifier)
        }
        button.attributedTitle = DashboardText.attributed(title ?? "", color: NSColor(named: "DashboardCardValueColor"))

        let isOn = (attribute.value as? NSNumber)?.boolValue ?? false
        button.state = isOn ? .on : .off
        button.isEnabled = canEdit()

        needsLayout = true
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        let size = button.sizeThatFits(limitedSize)
        // The button's fitting size is a little short.
        return NSSize(width: size.width + 3, height: size.height + 2)
    }

    override func numberOfColumnsOccupied() -> Int {
        guard let attribute else { return 0 }
        if attribute.isUserCustom() {
            return 1
        }
        if attribute.identifier == LookinAttr_UIScrollView_Zoom_Bounce {
            return 1
        }
        return 0
    }

    @objc private func handleButton() {
        let expectedValue: NSNumber
        switch button.state {
        case .off:
            expectedValue = DashboardModification.boolValue(isOn: false)
        case .on:
            expectedValue = DashboardModification.boolValue(isOn: true)
        default:
            assertionFailure()
            return
        }
        Task { @MainActor [weak self] in
            do {
                try await self?.submit(expectedValue)
            } catch {
                self?.renderWithAttribute()
            }
        }
    }
}
