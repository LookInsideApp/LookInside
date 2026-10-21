//
//  LaunchAppCardItem.swift
//  LookInside
//
//  One app in the launch window's grid: its screenshot over its icon and
//  name. An app whose Server version is unsupported shows the error and a
//  link to the explanation instead of the screenshot; an app in the
//  background or not answering in time is dimmed, labelled "In Background"
//  or "Not Responding" over its screenshot, and cannot be clicked. Under
//  the name: the bundle identifier, the Server version and the screen size.
//

import AppKit

/// What one card shows.
struct LaunchAppCard {
    let origin: InspectableAppOrigin
    let app: InspectableApp
    /// The app's info, or for an unresponsive app the info it sent before
    /// it stopped answering, when the launch window saw it.
    let displayedAppInfo: InspectedAppInfo?

    /// A click opens the app or, for a version error, explains it.
    var isClickable: Bool {
        !app.isUnresponsive
    }
}

final class LaunchAppCardItem: NSCollectionViewItem {
    static let itemSize = NSSize(width: 176, height: 312)

    /// Runs when the card is clicked while it is clickable.
    var onClick: (() -> Void)?

    private lazy var cardView: LaunchAppCardView = {
        let cardView = LaunchAppCardView(frame: NSRect(origin: .zero, size: Self.itemSize))
        cardView.onClick = { [weak self] in
            self?.onClick?()
        }
        return cardView
    }()

    override func loadView() {
        view = cardView
    }

    func configure(with card: LaunchAppCard) {
        cardView.configure(with: card)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onClick = nil
    }
}

private final class LaunchAppCardView: NSView {
    private static let screenshotAreaSize = NSSize(width: 156, height: 224)
    private static let screenshotCornerRadius: CGFloat = 10
    private static let appIconPointSize: CGFloat = 20
    private static let backgroundAlpha: CGFloat = 0.4

    var onClick: (() -> Void)?

    /// The screenshot keeps its aspect ratio inside this area.
    private let screenshotArea = NSLayoutGuide()
    private let screenshotImageView = NSImageView()
    private var screenshotAspectRatio: NSLayoutConstraint?
    private let statusLabel = NSTextField(labelWithString: "")
    private let statusBackgroundView = NSVisualEffectView()
    private let appIconImageView = NSImageView()
    private let appNameLabel = NSTextField(labelWithString: "")
    private let bundleIdentifierLabel = NSTextField(labelWithString: "")
    private let serverVersionView = LaunchAppCardDetailView(symbolName: "shippingbox")
    private let screenSizeView = LaunchAppCardDetailView(symbolName: "rectangle.portrait")
    private lazy var detailsStackView = NSStackView(views: [serverVersionView, screenSizeView])
    private let errorImageView = NSImageView()
    private let errorTitleLabel = NSTextField(wrappingLabelWithString: "")
    private let errorDetailsLabel = NSTextField(labelWithString: NSLocalizedString("Show Details", comment: "App card link that opens the Server version alert"))
    private lazy var errorStackView = NSStackView(views: [errorImageView, errorTitleLabel, errorDetailsLabel])
    private lazy var nameStackView = NSStackView(views: [appIconImageView, appNameLabel])

    private var isClickable = false
    private var isHovered = false {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.cornerCurve = .continuous
        layer?.borderWidth = 1

        screenshotImageView.imageScaling = .scaleProportionallyUpOrDown
        screenshotImageView.wantsLayer = true
        screenshotImageView.layer?.cornerRadius = Self.screenshotCornerRadius
        screenshotImageView.layer?.masksToBounds = true

        statusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        statusLabel.alignment = .center
        statusLabel.lineBreakMode = .byTruncatingTail
        statusBackgroundView.material = .popover
        statusBackgroundView.blendingMode = .withinWindow
        statusBackgroundView.state = .active
        statusBackgroundView.wantsLayer = true
        statusBackgroundView.layer?.cornerRadius = 6
        statusBackgroundView.layer?.masksToBounds = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusBackgroundView.addSubview(statusLabel)

        appIconImageView.imageScaling = .scaleProportionallyUpOrDown
        // The Server sends the icon unmasked; round it as the Home Screen does.
        appIconImageView.wantsLayer = true
        appIconImageView.layer?.cornerRadius = Self.appIconPointSize * 0.2237
        appIconImageView.layer?.cornerCurve = .continuous
        appIconImageView.layer?.masksToBounds = true
        appNameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        appNameLabel.lineBreakMode = .byTruncatingTail
        appNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameStackView.orientation = .horizontal
        nameStackView.spacing = 5
        nameStackView.alignment = .centerY

        bundleIdentifierLabel.font = .systemFont(ofSize: 11)
        bundleIdentifierLabel.textColor = .secondaryLabelColor
        bundleIdentifierLabel.alignment = .center
        bundleIdentifierLabel.lineBreakMode = .byTruncatingMiddle
        bundleIdentifierLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        detailsStackView.orientation = .horizontal
        detailsStackView.spacing = 8
        detailsStackView.alignment = .centerY

        errorImageView.image = NSImage(named: "icon_alert_big")
        errorTitleLabel.alignment = .center
        errorTitleLabel.font = .systemFont(ofSize: 12)
        errorTitleLabel.isSelectable = false
        errorTitleLabel.preferredMaxLayoutWidth = Self.screenshotAreaSize.width
        errorDetailsLabel.textColor = .linkColor
        errorStackView.orientation = .vertical
        errorStackView.spacing = 10
        errorStackView.alignment = .centerX

        addLayoutGuide(screenshotArea)
        for subview in [screenshotImageView, statusBackgroundView, errorStackView, nameStackView, bundleIdentifierLabel, detailsStackView] as [NSView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        // As large as the area allows at the screenshot's aspect ratio.
        let fillWidth = screenshotImageView.widthAnchor.constraint(equalTo: screenshotArea.widthAnchor)
        fillWidth.priority = .defaultHigh
        let fillHeight = screenshotImageView.heightAnchor.constraint(equalTo: screenshotArea.heightAnchor)
        fillHeight.priority = .defaultHigh
        NSLayoutConstraint.activate([
            screenshotArea.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            screenshotArea.centerXAnchor.constraint(equalTo: centerXAnchor),
            screenshotArea.widthAnchor.constraint(equalToConstant: Self.screenshotAreaSize.width),
            screenshotArea.heightAnchor.constraint(equalToConstant: Self.screenshotAreaSize.height),

            screenshotImageView.centerXAnchor.constraint(equalTo: screenshotArea.centerXAnchor),
            screenshotImageView.centerYAnchor.constraint(equalTo: screenshotArea.centerYAnchor),
            screenshotImageView.widthAnchor.constraint(lessThanOrEqualTo: screenshotArea.widthAnchor),
            screenshotImageView.heightAnchor.constraint(lessThanOrEqualTo: screenshotArea.heightAnchor),
            fillWidth,
            fillHeight,

            statusLabel.leadingAnchor.constraint(equalTo: statusBackgroundView.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: statusBackgroundView.trailingAnchor, constant: -8),
            statusLabel.topAnchor.constraint(equalTo: statusBackgroundView.topAnchor, constant: 4),
            statusLabel.bottomAnchor.constraint(equalTo: statusBackgroundView.bottomAnchor, constant: -4),
            statusBackgroundView.centerXAnchor.constraint(equalTo: screenshotArea.centerXAnchor),
            statusBackgroundView.centerYAnchor.constraint(equalTo: screenshotArea.centerYAnchor),
            statusBackgroundView.widthAnchor.constraint(lessThanOrEqualTo: screenshotArea.widthAnchor, constant: -16),

            errorStackView.centerXAnchor.constraint(equalTo: screenshotArea.centerXAnchor),
            errorStackView.centerYAnchor.constraint(equalTo: screenshotArea.centerYAnchor),
            errorStackView.widthAnchor.constraint(equalTo: screenshotArea.widthAnchor),

            appIconImageView.widthAnchor.constraint(equalToConstant: Self.appIconPointSize),
            appIconImageView.heightAnchor.constraint(equalToConstant: Self.appIconPointSize),
            nameStackView.topAnchor.constraint(equalTo: screenshotArea.bottomAnchor, constant: 10),
            nameStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),

            bundleIdentifierLabel.topAnchor.constraint(equalTo: nameStackView.bottomAnchor, constant: 2),
            bundleIdentifierLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            bundleIdentifierLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),

            detailsStackView.topAnchor.constraint(equalTo: bundleIdentifierLabel.bottomAnchor, constant: 4),
            detailsStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            detailsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
        ])
        setScreenshotAspectRatio(Self.screenshotAreaSize.width / Self.screenshotAreaSize.height)

        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:))))
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setScreenshotAspectRatio(_ ratio: CGFloat) {
        guard ratio.isFinite, ratio > 0, screenshotAspectRatio?.multiplier != ratio else { return }
        screenshotAspectRatio?.isActive = false
        screenshotAspectRatio = screenshotImageView.widthAnchor.constraint(equalTo: screenshotImageView.heightAnchor, multiplier: ratio)
        screenshotAspectRatio?.isActive = true
    }

    func configure(with card: LaunchAppCard) {
        let appInfo = card.displayedAppInfo
        let appName = appInfo?.appName.flatMap { $0.isEmpty ? nil : $0 }
            ?? NSLocalizedString("Unknown App", comment: "Launch window app card: the app sent no name")
        appNameLabel.stringValue = appName
        appIconImageView.image = appInfo?.appIcon
        appIconImageView.isHidden = appInfo?.appIcon == nil
        isClickable = card.isClickable

        let bundleIdentifier = appInfo?.appBundleIdentifier ?? ""
        bundleIdentifierLabel.stringValue = bundleIdentifier
        bundleIdentifierLabel.isHidden = bundleIdentifier.isEmpty
        bundleIdentifierLabel.toolTip = bundleIdentifier.isEmpty ? nil : bundleIdentifier
        let serverVersion = appInfo?.serverReadableVersion ?? ""
        serverVersionView.text = serverVersion
        serverVersionView.isHidden = serverVersion.isEmpty
        serverVersionView.toolTip = serverVersion.isEmpty ? nil : "LookInside Server \(serverVersion)"
        let screenSize = appInfo.map(Self.screenSizeDescription(of:)) ?? ""
        screenSizeView.text = screenSize
        screenSizeView.isHidden = screenSize.isEmpty

        if let error = card.app.serverVersionError {
            screenshotImageView.isHidden = true
            errorStackView.isHidden = false
            errorTitleLabel.stringValue = LaunchRules.serverVersionErrorTitle(
                errorCode: error.code,
                localizedDescription: error.localizedDescription
            )
        } else {
            screenshotImageView.isHidden = false
            errorStackView.isHidden = true
            if let screenshot = appInfo?.screenshot, screenshot.size.height > 0 {
                screenshotImageView.image = screenshot
                screenshotImageView.contentTintColor = nil
                setScreenshotAspectRatio(screenshot.size.width / screenshot.size.height)
                screenshotImageView.layer?.borderWidth = 1
            } else {
                screenshotImageView.image = NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil)?
                    .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 48, weight: .light))
                screenshotImageView.contentTintColor = .tertiaryLabelColor
                setScreenshotAspectRatio(Self.screenshotAreaSize.width / Self.screenshotAreaSize.height)
                screenshotImageView.layer?.borderWidth = 0
            }
        }

        if let unresponsiveness = card.app.unresponsiveness {
            switch unresponsiveness {
            case .inBackground:
                statusLabel.stringValue = NSLocalizedString("In Background", comment: "Launch window app card: the app is connected but in the background")
                toolTip = NSLocalizedString("Bring this app to the foreground to inspect it.", comment: "Tooltip of a launch window app card for an app in the background")
            case .notResponding:
                statusLabel.stringValue = NSLocalizedString("Not Responding", comment: "Launch window app card: the app is connected but did not answer in time")
                toolTip = NSLocalizedString("This app did not answer in time. It may be busy or paused in a debugger.", comment: "Tooltip of a launch window app card for an app that did not answer in time")
            }
            statusBackgroundView.isHidden = false
            screenshotImageView.alphaValue = Self.backgroundAlpha
            appIconImageView.alphaValue = Self.backgroundAlpha
            appNameLabel.textColor = .secondaryLabelColor
            setAccessibilityEnabled(false)
        } else {
            statusBackgroundView.isHidden = true
            toolTip = nil
            screenshotImageView.alphaValue = 1
            appIconImageView.alphaValue = 1
            appNameLabel.textColor = .labelColor
            setAccessibilityEnabled(true)
        }
        setAccessibilityLabel(appName)
        if !isClickable {
            isHovered = false
        }
        needsDisplay = true
    }

    /// "393×852 @3x", from the size in points and the scale the app sent;
    /// empty when it sent none.
    private static func screenSizeDescription(of appInfo: InspectedAppInfo) -> String {
        guard appInfo.screenWidth > 0, appInfo.screenHeight > 0 else { return "" }
        let size = "\(Int(appInfo.screenWidth.rounded()))×\(Int(appInfo.screenHeight.rounded()))"
        guard appInfo.screenScale > 0 else { return size }
        let scale = appInfo.screenScale.rounded() == appInfo.screenScale
            ? String(Int(appInfo.screenScale))
            : String(format: "%.1f", appInfo.screenScale)
        return "\(size) @\(scale)x"
    }

    @objc private func handleClick(_: NSClickGestureRecognizer) {
        guard isClickable else { return }
        onClick?()
    }

    override func accessibilityPerformPress() -> Bool {
        guard isClickable else { return false }
        onClick?()
        return true
    }

    // MARK: - Hover

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        isHovered = isClickable
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        isHovered = false
    }

    override var wantsUpdateLayer: Bool {
        true
    }

    override func updateLayer() {
        super.updateLayer()
        // A tile on the canvas, so its dots stay out from under the text;
        // the hover outlines it in the accent colour.
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        let borderColor = isHovered
            ? NSColor.controlAccentColor.withAlphaComponent(0.7).cgColor
            : NSColor.separatorColor.cgColor
        if let layer, layer.borderColor != borderColor {
            // The hover fades in and out rather than snapping.
            let fade = CABasicAnimation(keyPath: "borderColor")
            fade.fromValue = layer.presentation()?.borderColor ?? layer.borderColor
            fade.toValue = borderColor
            fade.duration = 0.15
            fade.timingFunction = CAMediaTimingFunction(name: .easeOut)
            layer.add(fade, forKey: "hoverFade")
            layer.borderColor = borderColor
        }
        screenshotImageView.layer?.borderColor = NSColor.separatorColor.cgColor
    }
}

/// A small SF Symbol and a value beside it, for a card's details line.
private final class LaunchAppCardDetailView: NSStackView {
    private let valueLabel = NSTextField(labelWithString: "")

    var text: String {
        get { valueLabel.stringValue }
        set { valueLabel.stringValue = newValue }
    }

    init(symbolName: String) {
        super.init(frame: .zero)
        let symbolImageView = NSImageView()
        symbolImageView.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 9, weight: .regular))
        symbolImageView.contentTintColor = .tertiaryLabelColor
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        valueLabel.textColor = .tertiaryLabelColor
        valueLabel.lineBreakMode = .byTruncatingTail
        orientation = .horizontal
        spacing = 3
        alignment = .centerY
        addArrangedSubview(symbolImageView)
        addArrangedSubview(valueLabel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
