//
//  LKMeasureController.swift
//  LookInside
//
//  The Measure panel: while measuring, it shows the distances between the
//  selected item and the hovered item, or a placeholder that says what to do
//  next (hover a layer) or why it cannot measure (a zero-sized frame).
//

import AppKit
import LookInsideHostCore

@objc(LKMeasureController)
final class LKMeasureController: LKBaseViewController {
    private static let placeholderInsets = NSEdgeInsets(top: 15, left: 5, bottom: 12, right: 5)

    private let dataSource: LKHierarchyDataSource
    private let placeholderView = LKBaseView()
    private let placeholderImageView = NSImageView()
    private let placeholderTitleLabel = LKLabel()
    private let placeholderSubtitleLabel = LKLabel()
    private let resultView = LKMeasureResultView()
    private var shortcutLabel: LKLabel?
    private var lockSwitchButton: NSButton?
    private var itemObservations: [NSKeyValueObservation] = []

    @objc(initWithDataSource:)
    init(dataSource: LKHierarchyDataSource) {
        self.dataSource = dataSource
        super.init(containerView: nil)

        placeholderView.hasEffectedBackground = true
        placeholderView.layer?.cornerRadius = DashboardCardCornerRadius
        view.addSubview(placeholderView)

        placeholderView.addSubview(placeholderImageView)

        placeholderTitleLabel.font = .boldSystemFont(ofSize: 14)
        placeholderTitleLabel.alignment = .center
        placeholderView.addSubview(placeholderTitleLabel)

        placeholderSubtitleLabel.font = .systemFont(ofSize: 12)
        placeholderSubtitleLabel.alignment = .center
        placeholderView.addSubview(placeholderSubtitleLabel)

        view.addSubview(resultView)

        dataSource.preferenceManager().measureState.subscribe(
            self, action: #selector(measureStateDidChange(_:)), relatedObject: nil
        )

        itemObservations = [
            dataSource.observe(\.selectedItem, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.reRender() }
            },
            dataSource.observe(\.hoveredItem, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.reRender() }
            },
        ]
        reRender()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        let titleHeight = LKNavigationManager.shared.windowTitleBarHeight

        var contentView: NSView?
        if placeholderView.isVisible {
            placeholderView.lkpFullWidth()
            placeholderView.lkpSetHeight(placeholderHeight(forWidth: view.bounds.width))
            placeholderView.lkpVerAlign()
            placeholderView.lkpOffsetY(titleHeight / 2)
            layoutPlaceholderView()
            contentView = placeholderView
        }
        if resultView.isVisible {
            resultView.lkpFullWidth()
            resultView.lkpHeightToFit()
            resultView.lkpVerAlign()
            resultView.lkpOffsetY(titleHeight / 2)
            contentView = resultView
        }
        let belowContent = (contentView?.frame.maxY ?? 0) + 5
        if let shortcutLabel {
            shortcutLabel.lkpSizeToFit()
            shortcutLabel.lkpHorAlign()
            shortcutLabel.lkpSetY(belowContent)
        }
        if let lockSwitchButton {
            lockSwitchButton.lkpSizeToFit()
            lockSwitchButton.lkpHorAlign()
            lockSwitchButton.lkpSetY(belowContent)
        }
    }

    @objc private func measureStateDidChange(_ params: LookinMsgActionParams) {
        shortcutLabel?.isHidden = true

        switch LookinMeasureState(rawValue: params.integerValue) {
        case .no:
            lockSwitchButton?.isHidden = true
            lockSwitchButton?.state = .off
        case .unlocked:
            // Entered with the shortcut.
            let button = lockSwitchButton ?? makeLockSwitchButton()
            button.state = .on
            button.isHidden = false
        case .locked:
            let label = shortcutLabel ?? makeShortcutLabel()
            label.isHidden = false
        default:
            break
        }
        reRender()
    }

    private func makeLockSwitchButton() -> NSButton {
        let button = NSButton()
        button.setButtonType(.switch)
        button.font = .systemFont(ofSize: 15)
        button.title = NSLocalizedString("Cancel measure after key up.", comment: "")
        button.target = self
        button.action = #selector(handleLockSwitchButton)
        view.addSubview(button)
        lockSwitchButton = button
        return button
    }

    private func makeShortcutLabel() -> LKLabel {
        let label = LKLabel()
        label.stringValue = NSLocalizedString("shortcut: holding \"option\" key", comment: "")
        label.textColor = .secondaryLabelColor
        view.addSubview(label)
        shortcutLabel = label
        return label
    }

    private func reRender() {
        let measureState: LookinIntegerMsgAttribute = dataSource.preferenceManager().measureState
        guard measureState.currentIntegerValue != LookinMeasureState.no.rawValue,
              let selectedItem = dataSource.selectedItem
        else { return }

        guard let hoveredItem = dataSource.hoveredItem, hoveredItem !== selectedItem else {
            let format = NSLocalizedString("to measure between it and selected %@.", comment: "")
            resultView.isHidden = true
            renderPlaceholder(image: NSImage(named: "measure_hover"),
                              title: NSLocalizedString("Hover on a layer", comment: ""),
                              subtitle: String(format: format, selectedItem.title()))
            view.needsLayout = true
            return
        }

        let selectedFrame = selectedItem.calculateFrameToRoot()
        let hoveredFrame = hoveredItem.calculateFrameToRoot()
        let invalid: (item: DisplayItem, property: String)? =
            if selectedFrame.width <= 0 {
                (selectedItem, NSLocalizedString("width", comment: ""))
            } else if selectedFrame.height <= 0 {
                (selectedItem, NSLocalizedString("height", comment: ""))
            } else if hoveredFrame.width <= 0 {
                (hoveredItem, NSLocalizedString("width", comment: ""))
            } else if hoveredFrame.height <= 0 {
                (hoveredItem, NSLocalizedString("height", comment: ""))
            } else {
                nil
            }
        if let invalid {
            let format = NSLocalizedString("Selected %@'s %@ is less than or equal to 0.", comment: "")
            resultView.isHidden = true
            renderPlaceholder(image: NSImage(named: "measure_info"),
                              title: NSLocalizedString("Invalid Size", comment: ""),
                              subtitle: String(format: format, invalid.item.title(), invalid.property))
            view.needsLayout = true
            return
        }

        placeholderView.isHidden = true
        resultView.isHidden = false
        resultView.render(mainRect: selectedFrame, mainImage: selectedItem.groupScreenshot,
                          referRect: hoveredFrame, referImage: hoveredItem.groupScreenshot)
        view.needsLayout = true
    }

    private func renderPlaceholder(image: NSImage?, title: String, subtitle: String) {
        placeholderImageView.image = image
        placeholderTitleLabel.stringValue = title
        placeholderSubtitleLabel.stringValue = subtitle
        placeholderView.isHidden = false
    }

    private func placeholderHeight(forWidth width: CGFloat) -> CGFloat {
        let insets = Self.placeholderInsets
        let contentWidth = width - insets.left - insets.right
        let limit = NSSize(width: contentWidth, height: .greatestFiniteMagnitude)
        return insets.top + insets.bottom
            + (placeholderImageView.image?.size.height ?? 0) + 11
            + placeholderTitleLabel.sizeThatFits(limit).height + 6
            + placeholderSubtitleLabel.sizeThatFits(limit).height
    }

    private func layoutPlaceholderView() {
        let insets = Self.placeholderInsets
        placeholderImageView.lkpSizeToFit()
        placeholderImageView.lkpHorAlign()
        placeholderImageView.lkpSetY(insets.top)

        placeholderTitleLabel.lkpSizeToFit()
        placeholderTitleLabel.lkpHorAlign()
        placeholderTitleLabel.lkpSetY(placeholderImageView.frame.maxY + 11)

        placeholderSubtitleLabel.lkpSetX(insets.left)
        placeholderSubtitleLabel.lkpToRight(insets.right)
        placeholderSubtitleLabel.lkpHeightToFit()
        placeholderSubtitleLabel.lkpSetY(placeholderTitleLabel.frame.maxY + 6)
    }

    @objc private func handleLockSwitchButton() {
        guard let lockSwitchButton else { return }
        let state: LookinMeasureState = lockSwitchButton.state == .on ? .unlocked : .locked
        dataSource.preferenceManager().measureState.setIntegerValue(state.rawValue, ignoreSubscriber: self)
    }
}
