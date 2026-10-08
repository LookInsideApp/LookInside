//
//  WindowToolbarHelper.swift
//  Lookin
//
//  Created by Li Kai on 2019/5/8.
//  https://lookin.work
//

import AppKit

/// Makes the toolbar items the inspector and reader windows share.
///
/// The items for dimension, rotation, scale, measure and fast mode follow a
/// preference manager both ways. The window sets the click action of the
/// others itself: Reload, App, Setting, Console, Add, Remove and Message.
@objc(LKWindowToolbarHelper)
@MainActor
final class WindowToolbarHelper: NSObject {
    @objc(sharedInstance)
    static let shared = WindowToolbarHelper()

    override private init() {
        super.init()
    }

    /// The item for `identifier`. Use `makeAppInReadModeItem(with:)` for the
    /// reader's app item.
    @objc(makeToolBarItemWithIdentifier:preferenceManager:)
    func makeToolBarItem(identifier: String, preferenceManager manager: PreferenceManager) -> NSToolbarItem? {
        assert(identifier != toolbarIdentifierAppInReadMode, "Use makeAppInReadModeItemWithAppInfo:")

        switch identifier {
        case toolbarIdentifierGestureDebug:
            let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier(identifier))
            item.label = NSLocalizedString("Gestures", comment: "")
            item.toolTip = NSLocalizedString("Inspect SwiftUI responders and gesture events", comment: "")
            item.image = NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: item.label)
            return item

        case toolbarIdentifierMeasure:
            let button = ToolbarPreferenceButton()
            button.preferenceManager = manager
            button.image = Self.templateImage("icon_measure")
            button.bezelStyle = .texturedRounded
            button.setButtonType(.pushOnPushOff)
            button.target = self
            button.action = #selector(handleToggleMeasureButton(_:))
            manager.measureState.subscribe(self, action: #selector(handleMeasureStateDidChange(_:)), relatedObject: button, sendAtOnce: true)
            return Self.item(toolbarIdentifierMeasure, label: NSLocalizedString("Measure", comment: ""), view: button)

        case toolbarIdentifierRotation:
            let button = Self.imageButton("icon_rotation", buttonType: .pushOnPushOff)
            manager.freeRotation.subscribe(self, action: #selector(handleOnOffDidChange(_:)), relatedObject: button, sendAtOnce: true)
            return Self.item(toolbarIdentifierRotation, label: NSLocalizedString("Free Rotation", comment: ""), view: button)

        case toolbarIdentifierDimension:
            let images = [Self.templateImage("icon_2d"), Self.templateImage("icon_3d")].compactMap { $0 }
            let control = ToolbarPreferenceSegmentedControl(
                images: images,
                trackingMode: .selectOne,
                target: self,
                action: #selector(handleDimension(_:))
            )
            control.preferenceManager = manager
            control.segmentDistribution = .fillEqually
            control.setWidth(45, forSegment: 0)
            control.setWidth(45, forSegment: 1)
            manager.previewDimension.subscribe(self, action: #selector(handleDimensionDidChange(_:)), relatedObject: control, sendAtOnce: true)
            return Self.item(toolbarIdentifierDimension, label: "2D / 3D", view: control)

        case toolbarIdentifierScale:
            let scaleView = WindowToolbarScaleView()
            let slider = scaleView.slider
            slider.preferenceManager = manager
            slider.minValue = Double(previewMinScale)
            slider.maxValue = Double(previewMaxScale)
            slider.doubleValue = manager.previewScale.currentDoubleValue
            slider.target = self
            slider.action = #selector(handleScaleSlider(_:))
            scaleView.increaseButton.target = self
            scaleView.increaseButton.action = #selector(handleScaleIncreaseButton(_:))
            scaleView.increaseButton.preferenceManager = manager
            scaleView.decreaseButton.target = self
            scaleView.decreaseButton.action = #selector(handleScaleDecreaseButton(_:))
            scaleView.decreaseButton.preferenceManager = manager
            manager.previewScale.subscribe(self, action: #selector(handlePreviewScaleDidChange(_:)), relatedObject: slider, sendAtOnce: true)
            return Self.item(toolbarIdentifierScale, label: NSLocalizedString("Zoom", comment: ""), view: scaleView)

        case toolbarIdentifierSetting:
            return Self.item(toolbarIdentifierSetting, label: nil, view: Self.imageButton("icon_setting"))

        case toolbarIdentifierReload:
            return Self.item(toolbarIdentifierReload, label: NSLocalizedString("Reload", comment: ""), view: Self.imageButton("icon_reload"))

        case toolbarIdentifierApp:
            let button = WindowToolbarAppButton()
            button.bezelStyle = .texturedRounded
            // The owning live document's window controller binds the button
            // to its inspected app.
            return Self.item(toolbarIdentifierApp, label: NSLocalizedString("Select App", comment: ""), view: button)

        case toolbarIdentifierSwiftUIMode:
            let segmented = NSSegmentedControl(
                labels: [NSLocalizedString("Compact", comment: ""), NSLocalizedString("Verbose", comment: "")],
                trackingMode: .selectOne,
                target: SwiftUIHierarchyDisplayModeStore.self as AnyObject,
                action: #selector(SwiftUIHierarchyDisplayModeStore.swiftUIModeSegmentChanged(_:))
            )
            segmented.selectedSegment = SwiftUIHierarchyDisplayModeStore.currentMode() == .compact ? 0 : 1
            return Self.item(toolbarIdentifierSwiftUIMode, label: NSLocalizedString("SwiftUI", comment: ""), view: segmented)

        case toolbarIdentifierConsole:
            let button = Self.imageButton("icon_console", buttonType: .pushOnPushOff)
            return Self.item(toolbarIdentifierConsole, label: NSLocalizedString("Console", comment: ""), view: button)

        case toolbarIdentifierFastMode:
            let button = Self.imageButton("icon_turbo", buttonType: .pushOnPushOff)
            manager.fastMode.subscribe(self, action: #selector(handleOnOffDidChange(_:)), relatedObject: button, sendAtOnce: true)
            return Self.item(toolbarIdentifierFastMode, label: NSLocalizedString("Fast Mode", comment: ""), view: button)

        case toolbarIdentifierAdd:
            let button = NSButton()
            let image = NSImage(named: NSImage.addTemplateName)
            image?.isTemplate = true
            button.image = image
            button.bezelStyle = .texturedRounded
            return Self.item(toolbarIdentifierAdd, label: nil, view: button)

        case toolbarIdentifierRemove:
            return Self.item(toolbarIdentifierRemove, label: nil, view: Self.imageButton("icon_delete"))

        case toolbarIdentifierMessage:
            return Self.item(toolbarIdentifierMessage, label: nil, view: Self.imageButton("icon_notification"))

        default:
            assertionFailure("Unknown toolbar item identifier \(identifier)")
            return nil
        }
    }

    /// The reader's app item, showing `appInfo`.
    @objc(makeAppInReadModeItemWithAppInfo:)
    func makeAppInReadModeItem(with appInfo: InspectedAppInfo?) -> NSToolbarItem {
        let button = WindowToolbarAppButton()
        button.bezelStyle = .texturedRounded
        button.appInfo = appInfo
        return Self.item(toolbarIdentifierAppInReadMode, label: "iOS App", view: button)
    }

    // MARK: - Building

    private static func item(_ identifier: String, label: String?, view: NSView) -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier(identifier))
        if let label {
            item.label = label
        }
        item.view = view
        return item
    }

    private static func templateImage(_ name: String) -> NSImage? {
        let image = NSImage(named: name)
        image?.isTemplate = true
        return image
    }

    private static func imageButton(_ imageName: String, buttonType: NSButton.ButtonType? = nil) -> NSButton {
        let button = NSButton()
        button.image = templateImage(imageName)
        button.bezelStyle = .texturedRounded
        if let buttonType {
            button.setButtonType(buttonType)
        }
        return button
    }

    // MARK: - Control → preference

    @objc private func handleDimension(_ control: ToolbarPreferenceSegmentedControl) {
        control.preferenceManager?.previewDimension.setIntegerValue(control.selectedSegment, ignoreSubscriber: self)
    }

    @objc private func handleScaleSlider(_ slider: ToolbarPreferenceSlider) {
        slider.preferenceManager?.previewScale.setDoubleValue(slider.doubleValue, ignoreSubscriber: self)
    }

    @objc private func handleScaleIncreaseButton(_ button: ToolbarPreferenceButton) {
        stepScale(of: button.preferenceManager, by: ToolbarRules.step)
    }

    @objc private func handleScaleDecreaseButton(_ button: ToolbarPreferenceButton) {
        stepScale(of: button.preferenceManager, by: -ToolbarRules.step)
    }

    private func stepScale(of manager: PreferenceManager?, by delta: Double) {
        guard let manager else { return }
        let scale = ToolbarRules.stepped(
            manager.previewScale.currentDoubleValue,
            by: delta,
            lower: Double(previewMinScale),
            upper: Double(previewMaxScale)
        )
        manager.previewScale.setDoubleValue(scale, ignoreSubscriber: nil)
    }

    @objc private func handleToggleMeasureButton(_ button: ToolbarPreferenceButton) {
        let state: MeasureState = button.state == .on ? .locked : .no
        button.preferenceManager?.measureState.setIntegerValue(state.rawValue, ignoreSubscriber: self)
    }

    // MARK: - Preference → control

    @objc private func handlePreviewScaleDidChange(_ param: MessageActionParameters) {
        (param.relatedObject as? NSSlider)?.doubleValue = param.doubleValue
    }

    /// Fast mode and free rotation: the button is on while the preference is.
    @objc private func handleOnOffDidChange(_ param: MessageActionParameters) {
        (param.relatedObject as? NSButton)?.state = param.boolValue ? .on : .off
    }

    @objc private func handleDimensionDidChange(_ param: MessageActionParameters) {
        (param.relatedObject as? NSSegmentedControl)?.selectedSegment = param.integerValue
    }

    @objc private func handleMeasureStateDidChange(_ param: MessageActionParameters) {
        (param.relatedObject as? NSButton)?.state = param.integerValue != MeasureState.no.rawValue ? .on : .off
    }
}

/// Toolbar controls that remember the preference manager they drive; the
/// shared helper is their target.
final class ToolbarPreferenceButton: NSButton {
    weak var preferenceManager: PreferenceManager?
}

final class ToolbarPreferenceSlider: NSSlider {
    weak var preferenceManager: PreferenceManager?
}

final class ToolbarPreferenceSegmentedControl: NSSegmentedControl {
    weak var preferenceManager: PreferenceManager?
}
