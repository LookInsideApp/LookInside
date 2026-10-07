//
//  LKLaunchAppView.swift
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

import AppKit

/// One inspectable app in the launch window or the apps popover: its
/// screenshot over the device icon, device name and OS. An app whose Server
/// version is unsupported shows the error and a link to the explanation
/// instead.
@objc(LKLaunchAppView)
final class LKLaunchAppView: LKBaseControl {
    private let hoverBgLayer = CALayer()
    private let previewImageView = NSImageView()
    private let iconImageView = NSImageView()
    private let titleLabel = LKLabel()
    private let subtitleLabel = LKLabel()

    private var errorImageView: NSImageView?
    private var errorTitleLabel: LKLabel?
    private var errorSubtitleLabel: LKLabel?

    private var previewSize = NSSize.zero
    private var insets = NSEdgeInsetsZero
    private var iconTop: CGFloat = 0
    private var iconMarginRight: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.cornerRadius = 4

        hoverBgLayer.opacity = 0
        hoverBgLayer.cornerRadius = 4
        layer?.addSublayer(hoverBgLayer)

        addSubview(previewImageView)
        addSubview(iconImageView)

        titleLabel.textColor = .labelColor
        addSubview(titleLabel)

        subtitleLabel.textColor = .labelColor
        addSubview(subtitleLabel)

        applyLayoutMetrics()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// The smaller metrics the apps popover uses. Defaults to false.
    @objc var compactLayout = false {
        didSet { applyLayoutMetrics() }
    }

    @objc var app: LKInspectableApp? {
        didSet { appDidChange() }
    }

    private var hasServerVersionError: Bool {
        app?.serverVersionError != nil
    }

    private func applyLayoutMetrics() {
        if compactLayout {
            previewSize = NSSize(width: 120, height: 220)
            insets = NSEdgeInsets(top: 12, left: 13, bottom: 8, right: 13)
            iconTop = 10
            iconMarginRight = 6
            titleLabel.font = NSFont.systemFont(ofSize: 12)
            subtitleLabel.font = NSFont.systemFont(ofSize: 11)
        } else {
            previewSize = NSSize(width: 142, height: 260)
            insets = NSEdgeInsets(top: 12, left: 25, bottom: 12, right: 25)
            iconTop = 10
            iconMarginRight = 8
            titleLabel.font = NSFont.systemFont(ofSize: 13)
            subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        hoverBgLayer.frame = layer?.bounds ?? .zero

        if hasServerVersionError, let errorImageView, let errorTitleLabel, let errorSubtitleLabel {
            LKViewFrameLayout(errorImageView).sizeToFit().horAlign()
            LKViewFrameLayout(errorTitleLabel).x(10).toRight(10).heightToFit().y(errorImageView.frame.maxY + 15)
            LKViewFrameLayout(errorSubtitleLabel).sizeToFit().horAlign().y(errorTitleLabel.frame.maxY + 10)
            let errorViews: [NSView] = [errorImageView, errorTitleLabel, errorSubtitleLabel]
            LKViewFrameLayout.groupVerAlign(errorViews)
            errorViews.forEach { LKViewFrameLayout($0).offsetY(-10) }
        } else if !hasServerVersionError {
            LKViewFrameLayout(previewImageView).size(previewSize).horAlign().y(insets.top)
            LKViewFrameLayout(iconImageView).sizeToFit().y(insets.top + previewSize.height + iconTop)

            LKViewFrameLayout(titleLabel).sizeToFit()
            LKViewFrameLayout(subtitleLabel).sizeToFit().y(titleLabel.frame.maxY + 2)
            let labels: [NSView] = [titleLabel, subtitleLabel]
            labels.forEach { LKViewFrameLayout($0).x(iconImageView.frame.maxX + iconMarginRight) }
            LKViewFrameLayout.groupMidY(labels, iconImageView.frame.midY)

            let row: [NSView] = [iconImageView, titleLabel, subtitleLabel]
            LKViewFrameLayout.groupHorAlign(row)
            row.forEach { LKViewFrameLayout($0).offsetX(-2) }
        }
    }

    override func sizeThatFits(_: NSSize) -> NSSize {
        if hasServerVersionError {
            return NSSize(
                width: previewSize.width + insets.left + insets.right,
                height: insets.top + previewSize.height + iconTop + insets.bottom
            )
        }
        let unlimited = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        let iconSize = iconImageView.image?.size ?? .zero
        let previewWidth = previewSize.width + insets.left + insets.right
        let labelsWidth = iconSize.width + iconMarginRight
            + max(titleLabel.sizeThatFits(unlimited).width, subtitleLabel.sizeThatFits(unlimited).width)
            + insets.left + insets.right
        return NSSize(
            width: max(previewWidth, labelsWidth),
            height: insets.top + previewSize.height + iconTop + iconSize.height + insets.bottom
        )
    }

    override func sizeToFit() {
        setFrameSize(sizeThatFits(NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)))
    }

    private func appDidChange() {
        let normalViews: [NSView] = [previewImageView, iconImageView, titleLabel, subtitleLabel]
        if let error = app?.serverVersionError {
            makeErrorViewsIfNeeded()
            [errorImageView, errorTitleLabel, errorSubtitleLabel].forEach { $0?.isHidden = false }
            normalViews.forEach { $0.isHidden = true }
            errorTitleLabel?.stringValue = LKLaunchRules.serverVersionErrorTitle(
                errorCode: error.code,
                localizedDescription: error.localizedDescription
            )
        } else {
            [errorImageView, errorTitleLabel, errorSubtitleLabel].forEach { $0?.isHidden = true }
            normalViews.forEach { $0.isHidden = false }

            let appInfo = app?.appInfo
            previewImageView.image = appInfo?.screenshot
            iconImageView.image = Self.deviceIcon(for: appInfo)
            titleLabel.stringValue = appInfo?.deviceDescription ?? ""
            subtitleLabel.stringValue = appInfo?.osDescription ?? "(null)"
        }
        updateLayer()
        needsLayout = true
    }

    /// Prefer the icon of the actual hardware model the app runs on. Falls back to the
    /// per-family asset when the peer's LookinServer does not report a model identifier.
    private static func deviceIcon(for appInfo: LookinAppInfo?) -> NSImage? {
        if let icon = LKDeviceIconProvider.deviceIcon(forAppInfo: appInfo, pointSize: LKDeviceIconProvider.launchPointSize) {
            return icon
        }
        if LKHelper.appInfoLooksLikeMacTarget(appInfo) || appInfo?.deviceType == .macCatalyst {
            // A Catalyst app runs on Mac hardware, so it gets the Mac icon even though
            // +appInfoLooksLikeMacTarget: deliberately answers NO for it (its views are UIKit).
            return NSImage(named: "icon_mac_big")
        }
        switch appInfo?.deviceType {
        case .simulator?:
            return NSImage(named: "icon_simulator_big")
        case .iPad?:
            return NSImage(named: "icon_ipad_big")
        default:
            return NSImage(named: "icon_iphone_big")
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        hoverBgLayer.opacity = 1
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        hoverBgLayer.opacity = 0
    }

    override func updateLayer() {
        super.updateLayer()
        let isDarkMode = effectiveAppearance.lk_isDarkMode
        hoverBgLayer.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: isDarkMode ? 0.17 : 0.08).cgColor
        if hasServerVersionError {
            layer?.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: isDarkMode ? 0.13 : 0.05).cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil))
    }

    private func makeErrorViewsIfNeeded() {
        if errorImageView == nil {
            let imageView = NSImageView()
            imageView.image = NSImage(named: "icon_alert_big")
            addSubview(imageView)
            errorImageView = imageView
        }
        if errorTitleLabel == nil {
            let label = LKLabel()
            label.textColor = .labelColor
            label.alignment = .center
            label.maximumNumberOfLines = 0
            addSubview(label)
            errorTitleLabel = label
        }
        if errorSubtitleLabel == nil {
            let label = LKLabel()
            label.stringValue = NSLocalizedString("Find solution…", comment: "")
            label.textColor = .linkColor
            addSubview(label)
            errorSubtitleLabel = label
        }
    }
}
