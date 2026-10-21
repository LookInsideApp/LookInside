//
//  LaunchAppCardItem.swift
//  LookInside
//
//  One app in the launch window's grid: its screenshot over its icon and
//  name. An app whose Server version is unsupported shows the error and a
//  link to the explanation instead of the screenshot; an app in the
//  background is dimmed, labelled "In Background", and cannot be clicked.
//

import AppKit

/// What one card shows.
struct LaunchAppCard {
    let origin: InspectableAppOrigin
    let app: InspectableApp
    /// The app's info, or for an app in the background the info it sent
    /// before it went there, when the launch window saw it.
    let displayedAppInfo: InspectedAppInfo?

    /// A click opens the app or, for a version error, explains it.
    var isClickable: Bool {
        !app.isInBackground
    }
}

final class LaunchAppCardItem: NSCollectionViewItem {
    static let itemSize = NSSize(width: 176, height: 300)

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
    private static let backgroundAlpha: CGFloat = 0.4

    var onClick: (() -> Void)?

    private let screenshotImageView = NSImageView()
    private let appIconImageView = NSImageView()
    private let appNameLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
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
        layer?.cornerRadius = 8

        screenshotImageView.imageScaling = .scaleProportionallyDown
        screenshotImageView.imageAlignment = .alignCenter

        appIconImageView.imageScaling = .scaleProportionallyUpOrDown
        appNameLabel.font = .systemFont(ofSize: 13)
        appNameLabel.lineBreakMode = .byTruncatingTail
        appNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameStackView.orientation = .horizontal
        nameStackView.spacing = 5
        nameStackView.alignment = .centerY

        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center
        statusLabel.lineBreakMode = .byTruncatingTail

        errorImageView.image = NSImage(named: "icon_alert_big")
        errorTitleLabel.alignment = .center
        errorTitleLabel.font = .systemFont(ofSize: 12)
        errorTitleLabel.isSelectable = false
        errorTitleLabel.preferredMaxLayoutWidth = Self.screenshotAreaSize.width
        errorDetailsLabel.textColor = .linkColor
        errorStackView.orientation = .vertical
        errorStackView.spacing = 10
        errorStackView.alignment = .centerX

        for subview in [screenshotImageView, errorStackView, nameStackView, statusLabel] as [NSView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            screenshotImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            screenshotImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            screenshotImageView.widthAnchor.constraint(equalToConstant: Self.screenshotAreaSize.width),
            screenshotImageView.heightAnchor.constraint(equalToConstant: Self.screenshotAreaSize.height),

            errorStackView.centerXAnchor.constraint(equalTo: screenshotImageView.centerXAnchor),
            errorStackView.centerYAnchor.constraint(equalTo: screenshotImageView.centerYAnchor),
            errorStackView.widthAnchor.constraint(equalTo: screenshotImageView.widthAnchor),

            appIconImageView.widthAnchor.constraint(equalToConstant: 16),
            appIconImageView.heightAnchor.constraint(equalToConstant: 16),
            nameStackView.topAnchor.constraint(equalTo: screenshotImageView.bottomAnchor, constant: 10),
            nameStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),

            statusLabel.topAnchor.constraint(equalTo: nameStackView.bottomAnchor, constant: 3),
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
        ])

        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:))))
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with card: LaunchAppCard) {
        let appInfo = card.displayedAppInfo
        let appName = appInfo?.appName.flatMap { $0.isEmpty ? nil : $0 }
            ?? NSLocalizedString("Unknown App", comment: "Launch window app card: the app sent no name")
        appNameLabel.stringValue = appName
        appIconImageView.image = appInfo?.appIcon
        appIconImageView.isHidden = appInfo?.appIcon == nil
        isClickable = card.isClickable

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
            if let screenshot = appInfo?.screenshot {
                screenshotImageView.image = screenshot
                screenshotImageView.contentTintColor = nil
            } else {
                screenshotImageView.image = NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil)?
                    .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 48, weight: .light))
                screenshotImageView.contentTintColor = .tertiaryLabelColor
            }
        }

        if card.app.isInBackground {
            statusLabel.stringValue = NSLocalizedString("In Background", comment: "Launch window app card: the app is connected but in the background")
            statusLabel.isHidden = false
            toolTip = NSLocalizedString("Bring this app to the foreground to inspect it.", comment: "Tooltip of a launch window app card for an app in the background")
            screenshotImageView.alphaValue = Self.backgroundAlpha
            appIconImageView.alphaValue = Self.backgroundAlpha
            appNameLabel.textColor = .secondaryLabelColor
            setAccessibilityEnabled(false)
        } else {
            statusLabel.isHidden = true
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
        let hoverColor = NSColor.labelColor.withAlphaComponent(effectiveAppearance.isDarkMode ? 0.12 : 0.07)
        layer?.backgroundColor = isHovered ? hoverColor.cgColor : NSColor.clear.cgColor
    }
}
