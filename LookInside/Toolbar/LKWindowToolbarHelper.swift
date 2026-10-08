//
//  LKWindowToolbarHelper.swift
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
final class LKWindowToolbarHelper: NSObject {
    @objc(sharedInstance)
    static let shared = LKWindowToolbarHelper()

    override private init() {
        super.init()
    }

    /// The item for `identifier`. Use `makeAppInReadModeItem(with:)` for the
    /// reader's app item.
    @objc(makeToolBarItemWithIdentifier:preferenceManager:)
    func makeToolBarItem(identifier: String, preferenceManager manager: LKPreferenceManager) -> NSToolbarItem? {
        assert(identifier != LKToolBarIdentifier_AppInReadMode, "Use makeAppInReadModeItemWithAppInfo:")

        switch identifier {
        case LKToolBarIdentifier_GestureDebug:
            let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier(identifier))
            item.label = NSLocalizedString("Gestures", comment: "")
            item.toolTip = NSLocalizedString("Inspect SwiftUI responders and gesture events", comment: "")
            item.image = NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: item.label)
            return item

        case LKToolBarIdentifier_Measure:
            let button = LKToolbarPreferenceButton()
            button.preferenceManager = manager
            button.image = Self.templateImage("icon_measure")
            button.bezelStyle = .texturedRounded
            button.setButtonType(.pushOnPushOff)
            button.target = self
            button.action = #selector(handleToggleMeasureButton(_:))
            manager.measureState.subscribe(self, action: #selector(handleMeasureStateDidChange(_:)), relatedObject: button, sendAtOnce: true)
            return Self.item(LKToolBarIdentifier_Measure, label: NSLocalizedString("Measure", comment: ""), view: button)

        case LKToolBarIdentifier_Rotation:
            let button = Self.imageButton("icon_rotation", buttonType: .pushOnPushOff)
            manager.freeRotation.subscribe(self, action: #selector(handleOnOffDidChange(_:)), relatedObject: button, sendAtOnce: true)
            return Self.item(LKToolBarIdentifier_Rotation, label: NSLocalizedString("Free Rotation", comment: ""), view: button)

        case LKToolBarIdentifier_Dimension:
            let images = [Self.templateImage("icon_2d"), Self.templateImage("icon_3d")].compactMap { $0 }
            let control = LKToolbarPreferenceSegmentedControl(
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
            return Self.item(LKToolBarIdentifier_Dimension, label: "2D / 3D", view: control)

        case LKToolBarIdentifier_Scale:
            let scaleView = LKWindowToolbarScaleView()
            let slider = scaleView.slider
            slider.preferenceManager = manager
            slider.minValue = Double(LookinPreviewMinScale)
            slider.maxValue = Double(LookinPreviewMaxScale)
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
            return Self.item(LKToolBarIdentifier_Scale, label: NSLocalizedString("Zoom", comment: ""), view: scaleView)

        case LKToolBarIdentifier_Setting:
            return Self.item(LKToolBarIdentifier_Setting, label: nil, view: Self.imageButton("icon_setting"))

        case LKToolBarIdentifier_Reload:
            return Self.item(LKToolBarIdentifier_Reload, label: NSLocalizedString("Reload", comment: ""), view: Self.imageButton("icon_reload"))

        case LKToolBarIdentifier_App:
            let button = LKWindowToolbarAppButton()
            button.bezelStyle = .texturedRounded
            // The owning live document's window controller binds the button
            // to its inspected app.
            return Self.item(LKToolBarIdentifier_App, label: NSLocalizedString("Select App", comment: ""), view: button)

        case LKToolBarIdentifier_SwiftUIMode:
            let segmented = NSSegmentedControl(
                labels: [NSLocalizedString("Compact", comment: ""), NSLocalizedString("Verbose", comment: "")],
                trackingMode: .selectOne,
                target: LKSwiftUIHierarchyDisplayModeStore.self as AnyObject,
                action: #selector(LKSwiftUIHierarchyDisplayModeStore.swiftUIModeSegmentChanged(_:))
            )
            segmented.selectedSegment = LKSwiftUIHierarchyDisplayModeStore.currentMode() == .compact ? 0 : 1
            return Self.item(LKToolBarIdentifier_SwiftUIMode, label: NSLocalizedString("SwiftUI", comment: ""), view: segmented)

        case LKToolBarIdentifier_Console:
            let button = Self.imageButton("icon_console", buttonType: .pushOnPushOff)
            return Self.item(LKToolBarIdentifier_Console, label: NSLocalizedString("Console", comment: ""), view: button)

        case LKToolBarIdentifier_FastMode:
            let button = Self.imageButton("icon_turbo", buttonType: .pushOnPushOff)
            manager.fastMode.subscribe(self, action: #selector(handleOnOffDidChange(_:)), relatedObject: button, sendAtOnce: true)
            return Self.item(LKToolBarIdentifier_FastMode, label: NSLocalizedString("Fast Mode", comment: ""), view: button)

        case LKToolBarIdentifier_Add:
            let button = NSButton()
            let image = NSImage(named: NSImage.addTemplateName)
            image?.isTemplate = true
            button.image = image
            button.bezelStyle = .texturedRounded
            return Self.item(LKToolBarIdentifier_Add, label: nil, view: button)

        case LKToolBarIdentifier_Remove:
            return Self.item(LKToolBarIdentifier_Remove, label: nil, view: Self.imageButton("icon_delete"))

        case LKToolBarIdentifier_Message:
            return Self.item(LKToolBarIdentifier_Message, label: nil, view: Self.imageButton("icon_notification"))

        default:
            assertionFailure("Unknown toolbar item identifier \(identifier)")
            return nil
        }
    }

    /// The reader's app item, showing `appInfo`.
    @objc(makeAppInReadModeItemWithAppInfo:)
    func makeAppInReadModeItem(with appInfo: InspectedAppInfo?) -> NSToolbarItem {
        let button = LKWindowToolbarAppButton()
        button.bezelStyle = .texturedRounded
        button.appInfo = appInfo
        return Self.item(LKToolBarIdentifier_AppInReadMode, label: "iOS App", view: button)
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

    @objc private func handleDimension(_ control: LKToolbarPreferenceSegmentedControl) {
        control.preferenceManager?.previewDimension.setIntegerValue(control.selectedSegment, ignoreSubscriber: self)
    }

    @objc private func handleScaleSlider(_ slider: LKToolbarPreferenceSlider) {
        slider.preferenceManager?.previewScale.setDoubleValue(slider.doubleValue, ignoreSubscriber: self)
    }

    @objc private func handleScaleIncreaseButton(_ button: LKToolbarPreferenceButton) {
        stepScale(of: button.preferenceManager, by: LKToolbarRules.step)
    }

    @objc private func handleScaleDecreaseButton(_ button: LKToolbarPreferenceButton) {
        stepScale(of: button.preferenceManager, by: -LKToolbarRules.step)
    }

    private func stepScale(of manager: LKPreferenceManager?, by delta: Double) {
        guard let manager else { return }
        let scale = LKToolbarRules.stepped(
            manager.previewScale.currentDoubleValue,
            by: delta,
            lower: Double(LookinPreviewMinScale),
            upper: Double(LookinPreviewMaxScale)
        )
        manager.previewScale.setDoubleValue(scale, ignoreSubscriber: nil)
    }

    @objc private func handleToggleMeasureButton(_ button: LKToolbarPreferenceButton) {
        let state: LookinMeasureState = button.state == .on ? .locked : .no
        button.preferenceManager?.measureState.setIntegerValue(state.rawValue, ignoreSubscriber: self)
    }

    // MARK: - Preference → control

    @objc private func handlePreviewScaleDidChange(_ param: LookinMsgActionParams) {
        (param.relatedObject as? NSSlider)?.doubleValue = param.doubleValue
    }

    /// Fast mode and free rotation: the button is on while the preference is.
    @objc private func handleOnOffDidChange(_ param: LookinMsgActionParams) {
        (param.relatedObject as? NSButton)?.state = param.boolValue ? .on : .off
    }

    @objc private func handleDimensionDidChange(_ param: LookinMsgActionParams) {
        (param.relatedObject as? NSSegmentedControl)?.selectedSegment = param.integerValue
    }

    @objc private func handleMeasureStateDidChange(_ param: LookinMsgActionParams) {
        (param.relatedObject as? NSButton)?.state = param.integerValue != LookinMeasureState.no.rawValue ? .on : .off
    }
}

/// Toolbar controls that remember the preference manager they drive; the
/// shared helper is their target.
final class LKToolbarPreferenceButton: NSButton {
    weak var preferenceManager: LKPreferenceManager?
}

final class LKToolbarPreferenceSlider: NSSlider {
    weak var preferenceManager: LKPreferenceManager?
}

final class LKToolbarPreferenceSegmentedControl: NSSegmentedControl {
    weak var preferenceManager: LKPreferenceManager?
}
