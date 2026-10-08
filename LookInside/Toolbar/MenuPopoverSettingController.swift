//
//  MenuPopoverSettingController.swift
//  Lookin
//
//  Created by Li Kai on 2019/1/9.
//  https://lookin.work
//

import AppKit

/// The View popover of a window toolbar: outline, hidden items, system
/// layout guides, backing layers, item separation, and a way to the
/// preferences.
@objc(LKMenuPopoverSettingController)
final class MenuPopoverSettingController: BaseViewController {
    private let manager: PreferenceManager

    private let enableOutlineButton = NSButton()
    private let showInvisiblesButton = NSButton()
    private let showSystemLayoutGuidesButton = NSButton()
    private let showBackingLayersButton = NSButton()
    private let spaceSlider = NSSlider()
    private let spaceSliderLabel = TextLabel()
    private let preferenceButton = MenuPopoverSettingController.makePreferenceButton()

    /// `isMacTarget` describes the app being inspected, not the host. It decides whether the
    /// copy talks about `NSView` or `UIView`.
    @objc(initWithPreferenceManager:isMacTarget:)
    init(preferenceManager manager: PreferenceManager, isMacTarget: Bool) {
        self.manager = manager
        super.init(containerView: nil)

        configureSwitch(
            enableOutlineButton,
            title: NSLocalizedString("Show layer outline", comment: ""),
            action: #selector(handleOutlineControl),
            isOn: manager.showOutline.currentBOOLValue
        )
        configureSwitch(
            showInvisiblesButton,
            title: String(
                format: NSLocalizedString("Show hidden %@ and CALayer", comment: ""),
                AppHelper.viewClassName(forMacTarget: isMacTarget)
            ),
            action: #selector(handleShowInvisiblesControl),
            isOn: manager.showHiddenItems.currentBOOLValue
        )
        configureSwitch(
            showSystemLayoutGuidesButton,
            title: NSLocalizedString("Show system layout guides", comment: ""),
            action: #selector(handleShowSystemLayoutGuidesControl),
            isOn: manager.showSystemLayoutGuides.currentBOOLValue
        )
        configureSwitch(
            showBackingLayersButton,
            title: NSLocalizedString("Show backing layers", comment: ""),
            action: #selector(handleShowBackingLayersControl),
            isOn: manager.showBackingLayers.currentBOOLValue
        )

        spaceSlider.minValue = Double(LookinPreviewMinZInterspace)
        spaceSlider.maxValue = Double(LookinPreviewMaxZInterspace)
        spaceSlider.target = self
        spaceSlider.action = #selector(handleSpaceSlider(_:))
        view.addSubview(spaceSlider)

        spaceSliderLabel.font = NSFont.systemFont(ofSize: 14)
        spaceSliderLabel.stringValue = NSLocalizedString("Item separation", comment: "")
        view.addSubview(spaceSliderLabel)

        preferenceButton.target = self
        preferenceButton.action = #selector(handlePreferenceButton)
        view.addSubview(preferenceButton)

        manager.zInterspace.subscribe(self, action: #selector(handleZInterspaceDidChange(_:)), relatedObject: nil, sendAtOnce: true)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// `+[NSButton lk_normalButtonWithTitle:target:action:]`.
    private static func makePreferenceButton() -> NSButton {
        let button = NSButton()
        button.bezelStyle = .rounded
        button.title = NSLocalizedString("More…", comment: "")
        button.font = NSFont.systemFont(ofSize: 13)
        button.frame = NSRect(x: 0, y: 0, width: 84, height: 40)
        return button
    }

    private func configureSwitch(_ button: NSButton, title: String, action: Selector, isOn: Bool) {
        button.setButtonType(.switch)
        button.font = NSFont.systemFont(ofSize: 14)
        button.title = title
        button.target = self
        button.action = action
        view.addSubview(button)
        button.state = isOn ? .on : .off
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        ViewFrameLayout(enableOutlineButton).x(15).toRight(0).height(24).y(15)
        ViewFrameLayout(showInvisiblesButton).x(15).toRight(0).height(24).y(enableOutlineButton.frame.maxY + 6)
        ViewFrameLayout(showSystemLayoutGuidesButton).x(15).toRight(0).height(24).y(showInvisiblesButton.frame.maxY + 6)
        ViewFrameLayout(showBackingLayersButton).x(15).toRight(0).height(24).y(showSystemLayoutGuidesButton.frame.maxY + 6)

        ViewFrameLayout(spaceSlider).x(15).toRight(15).height(26).y(showBackingLayersButton.frame.maxY + 22)
        ViewFrameLayout(spaceSliderLabel).sizeToFit().x(spaceSlider.frame.minX + 3).y(spaceSlider.frame.maxY)

        ViewFrameLayout(preferenceButton).width(130).horAlign().bottom(4)
    }

    @objc private func handleOutlineControl() {
        manager.showOutline.setBOOLValue(enableOutlineButton.state == .on, ignoreSubscriber: nil)
    }

    @objc private func handleShowInvisiblesControl() {
        manager.showHiddenItems.setBOOLValue(showInvisiblesButton.state == .on, ignoreSubscriber: nil)
    }

    @objc private func handleShowSystemLayoutGuidesControl() {
        manager.showSystemLayoutGuides.setBOOLValue(showSystemLayoutGuidesButton.state == .on, ignoreSubscriber: nil)
    }

    @objc private func handleShowBackingLayersControl() {
        manager.showBackingLayers.setBOOLValue(showBackingLayersButton.state == .on, ignoreSubscriber: nil)
    }

    @objc private func handleSpaceSlider(_ slider: NSSlider) {
        manager.zInterspace.setDoubleValue(slider.doubleValue, ignoreSubscriber: self)
    }

    @objc private func handlePreferenceButton() {
        NavigationManager.shared.showPreference()
    }

    @objc private func handleZInterspaceDidChange(_ param: MessageActionParameters) {
        spaceSlider.doubleValue = param.doubleValue
    }
}
