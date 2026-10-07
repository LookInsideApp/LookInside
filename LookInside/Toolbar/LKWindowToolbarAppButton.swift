//
//  LKWindowToolbarAppButton.swift
//  LookinClient
//
//  Created by 李凯 on 2020/6/14.
//  Copyright © 2020 hughkli. All rights reserved.
//

import AppKit

/// The toolbar button that names the inspected app and its device: app
/// icon, app name, a chevron, device icon, device and OS. Without an app it
/// shows a plain app icon.
@objc(LKWindowToolbarAppButton)
final class LKWindowToolbarAppButton: NSButton {
    private let appImageView = NSImageView()
    private let appNameLabel = LKLabel()
    private let sepImageView = NSImageView()
    private let deviceImageView = NSImageView()
    private let deviceLabel = LKLabel()

    private let appImageWidth: CGFloat = 14
    /// Gaps before the app icon, the name, the chevron, the device icon and
    /// the device label.
    private let spaces: [CGFloat] = [7, 3, 3, 4, 1]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        title = ""

        appImageView.wantsLayer = true
        appImageView.layer?.cornerRadius = 2
        appImageView.layer?.masksToBounds = true
        addSubview(appImageView)

        appNameLabel.textColors = Self.labelColors
        addSubview(appNameLabel)

        sepImageView.image = NSImage(named: "icon_go_forward")
        sepImageView.image?.isTemplate = true
        addSubview(sepImageView)

        addSubview(deviceImageView)

        deviceLabel.textColors = Self.labelColors
        deviceLabel.lineBreakMode = .byTruncatingMiddle
        addSubview(deviceLabel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private static var labelColors: LKTwoColors {
        LKTwoColors(colorInLightMode: NSColor(red: 65 / 255.0, green: 65 / 255.0, blue: 65 / 255.0, alpha: 1), colorInDarkMode: .labelColor)
    }

    @objc var appInfo: LookinAppInfo? {
        didSet { appInfoDidChange() }
    }

    override func layout() {
        super.layout()
        LKViewFrameLayout(appImageView).width(appImageWidth).height(appImageWidth).x(spaces[0]).verAlign().offsetY(-0.5)
        LKViewFrameLayout(appNameLabel).sizeToFit().verAlign().x(appImageView.frame.maxX + spaces[1]).offsetY(-1)
        LKViewFrameLayout(sepImageView).sizeToFit().verAlign().x(appNameLabel.frame.maxX + spaces[2]).offsetY(-0.5)
        LKViewFrameLayout(deviceImageView).sizeToFit().x(sepImageView.frame.maxX + spaces[3]).verAlign()
        LKViewFrameLayout(deviceLabel).sizeToFit().verAlign().x(deviceImageView.frame.maxX + spaces[4]).toMaxX(bounds.width).offsetY(-1)
    }

    private func appInfoDidChange() {
        let parts: [NSView] = [appImageView, appNameLabel, sepImageView, deviceImageView, deviceLabel]
        if let appInfo {
            parts.forEach { $0.isHidden = false }
            image = nil
            appImageView.image = appInfo.appIcon ?? NSImage(named: "Icon_EmptyProject")
            appNameLabel.stringValue = appInfo.appName ?? ""
            deviceLabel.stringValue = "\(appInfo.deviceDescription ?? "(null)") (\(appInfo.osDescription ?? "(null)"))"
            // Prefer the icon of the actual hardware model the app runs on. Falls back to the
            // per-family asset when the peer's LookinServer does not report a model identifier.
            deviceImageView.image = LKDeviceIconProvider.deviceIcon(forAppInfo: appInfo, pointSize: LKDeviceIconProvider.toolbarPointSize)
                ?? Self.familyIcon(for: appInfo)
        } else {
            parts.forEach { $0.isHidden = true }
            image = NSImage(named: "icon_app")
        }
        invalidateIntrinsicContentSize()
        needsLayout = true
    }

    private static func familyIcon(for appInfo: LookinAppInfo) -> NSImage? {
        if LKHelper.appInfoLooksLikeMacTarget(appInfo) {
            return NSImage(named: "icon_mac_small")
        }
        switch appInfo.deviceType {
        case .simulator:
            return NSImage(named: "icon_simulator_small")
        case .iPad:
            return NSImage(named: "icon_ipad_small")
        case .others:
            return NSImage(named: "icon_iphone_small")
        case .macCatalyst:
            // A Catalyst app runs on Mac hardware, so it gets the Mac icon even
            // though its views are UIKit ones. It reaches this switch at all
            // because +appInfoLooksLikeMacTarget: above deliberately answers NO
            // for Catalyst — that predicate is about the UI framework, not the
            // hardware.
            return NSImage(named: "icon_mac_small")
        default:
            return NSImage(named: "icon_simulator_small")
        }
    }

    override func sizeThatFits(_ size: NSSize) -> NSSize {
        guard appInfo != nil else {
            return NSSize(width: 42, height: 34)
        }
        let unlimited = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        let contentWidth = [appNameLabel, sepImageView, deviceImageView, deviceLabel]
            .reduce(appImageWidth) { $0 + $1.sizeThatFits(unlimited).width }
        return NSSize(width: spaces.reduce(0, +) + contentWidth, height: size.height)
    }

    override var intrinsicContentSize: NSSize {
        let size = sizeThatFits(NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        return NSSize(width: size.width + 6, height: 34)
    }
}
