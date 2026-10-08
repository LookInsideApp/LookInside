//
//  LKTipsView.swift
//  LookInside
//

import AppKit

/// A pill-shaped notice: optional image, a title, and an optional button
/// after a separator.
@objc(LKTipsView)
class LKTipsView: LKBaseView {
    @objc weak var bindingObject: AnyObject?

    @objc var title: String? {
        didSet { titleLabel.stringValue = title ?? "" }
    }

    /// Set `buttonText` or `buttonImage` rather than editing the button.
    @objc let button = NSButton()

    /// Only one of `buttonText` and `buttonImage` takes effect; set one.
    @objc var buttonText: String? {
        didSet { updateButton() }
    }

    @objc var buttonImage: NSImage? {
        didSet { updateButton() }
    }

    @objc var image: NSImage? {
        didSet {
            imageView.image = image
            imageView.isHidden = image == nil
        }
    }

    @objc weak var target: AnyObject?
    @objc var clickAction: Selector?
    @objc var didClick: ((LKTipsView) -> Void)?

    let titleLabel = LKLabel()
    private let imageView = NSImageView()
    let sepLayer = CALayer()

    private let insetLeft: CGFloat = 12
    private var insetRightWithButton: CGFloat = 3
    private var insetRightWithoutButton: CGFloat = 8
    private var imageRight: CGFloat = 4
    private let sepLeft: CGFloat = 7
    private let imageSize = NSSize(width: 18, height: 18)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        layer?.borderWidth = 1

        imageView.isHidden = true
        addSubview(imageView)

        titleLabel.font = NSFont.systemFont(ofSize: 13)
        addSubview(titleLabel)

        button.font = NSFont.systemFont(ofSize: 13)
        button.isBordered = false
        button.bezelStyle = .smallSquare
        button.target = self
        button.action = #selector(handleButton)
        button.isHidden = true
        addSubview(button)

        sepLayer.removeImplicitAnimations()
        sepLayer.isHidden = true
        layer?.addSublayer(sepLayer)

        updateColors()
    }

    override func layout() {
        super.layout()
        layer?.cornerRadius = frame.height / 2

        var x = insetLeft
        if !imageView.isHidden {
            imageView.lkLayout.size(imageSize).verAlign().x(x)
            x = imageView.frame.maxX + imageRight
        }

        titleLabel.lkLayout.sizeToFit().verAlign().x(x)
        x = titleLabel.frame.maxX

        if !sepLayer.isHidden {
            sepLayer.lkLayout.width(1).fullHeight().x(x + sepLeft)
            x = sepLayer.frame.maxX
        }

        if !button.isHidden {
            button.lkLayout.x(x).toRight(insetRightWithButton).fullHeight()
        }
    }

    override func sizeThatFits(_: NSSize) -> NSSize {
        let unlimited = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        var width = insetLeft
        if !imageView.isHidden {
            width += imageSize.width + imageRight
        }
        width += titleLabel.sizeThatFits(unlimited).width
        if !sepLayer.isHidden {
            width += sepLeft + 1
        }
        if !button.isHidden {
            width += button.sizeThatFits(unlimited).width + 16
        } else {
            width += insetRightWithoutButton
        }
        return NSSize(width: width, height: 28)
    }

    override func updateColors() {
        super.updateColors()
        let isDarkMode = isDarkMode()
        backgroundColor = isDarkMode ? .lkBaseRGB(0, 0, 0, 0.8) : .lkBaseRGB(255, 255, 255, 0.9)
        titleLabel.textColor = isDarkMode ? .lkBaseRGB(197, 198, 199) : .lkBaseRGB(108, 109, 110)
        let borderColor: NSColor = isDarkMode ? .lkBaseRGB(43, 44, 45) : .lkBaseRGB(216, 217, 218)
        layer?.borderColor = borderColor.cgColor
        sepLayer.backgroundColor = borderColor.cgColor
        updateButton()
    }

    @objc(setImageByDeviceType:)
    func setImage(byDeviceType type: LookinAppInfoDevice) {
        switch type {
        case .mac, .macCatalyst:
            // A Catalyst app runs on Mac hardware, so it gets the Mac icon
            // even though its views are UIKit ones.
            image = NSImage(named: "icon_mac_big")
        case .simulator:
            image = NSImage(named: "icon_simulator_big")
        case .iPad:
            image = NSImage(named: "icon_ipad_big")
        case .others:
            image = NSImage(named: "icon_iphone_big")
        @unknown default:
            assertionFailure("unknown device type \(type.rawValue)")
        }
    }

    /// Prefers the icon of the hardware model the app runs on, falling back
    /// to the device family's icon when the Server reports no model.
    @objc(setImageByAppInfo:)
    func setImage(byAppInfo appInfo: InspectedAppInfo?) {
        if let deviceIcon = LKDeviceIconProvider.deviceIcon(forAppInfo: appInfo, pointSize: LKDeviceIconProvider.tipsPointSize) {
            image = deviceIcon
            return
        }
        if LKHelper.appInfoLooksLikeMacTarget(appInfo) {
            image = NSImage(named: "icon_mac_big")
            return
        }
        setImage(byDeviceType: appInfo?.deviceType ?? .simulator)
    }

    @objc(setInternalInsetsRight:)
    func setInternalInsetsRight(_ value: CGFloat) {
        insetRightWithButton = value
        insetRightWithoutButton = value
        imageRight = value
    }

    @objc private func handleButton() {
        if let target, let clickAction {
            NSApp.sendAction(clickAction, to: target, from: self)
        }
        didClick?(self)
    }

    private func updateButton() {
        button.isHidden = false
        sepLayer.isHidden = false
        if let buttonText {
            let attributedTitle = NSMutableAttributedString(string: buttonText)
            if attributedTitle.length > 0 {
                attributedTitle.addAttribute(.foregroundColor, value: buttonTextColor(), range: NSRange(location: 0, length: attributedTitle.length))
            }
            button.attributedTitle = attributedTitle
            button.image = nil
        } else if let buttonImage {
            button.title = ""
            button.image = buttonImage
        } else {
            button.isHidden = true
            sepLayer.isHidden = true
        }
        needsLayout = true
    }

    /// Subclasses override this to recolour the button text.
    func buttonTextColor() -> NSColor {
        isDarkMode() ? .lkBaseRGB(64, 134, 216) : .lkBaseRGB(74, 145, 228)
    }
}

/// An orange notice that can pulse.
@objc(LKYellowTipsView)
class LKYellowTipsView: LKTipsView {
    private var isAnimating = false

    @objc func startAnimation() {
        guard !isAnimating else { return }
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        if effectiveAppearance.lk_isDarkMode {
            animation.fromValue = NSColor.systemOrange.withAlphaComponent(0.7).cgColor
            animation.toValue = NSColor.systemOrange.withAlphaComponent(0.64).cgColor
        } else {
            animation.fromValue = NSColor.systemOrange.withAlphaComponent(0.98).cgColor
            animation.toValue = NSColor.systemOrange.withAlphaComponent(0.92).cgColor
        }
        animation.duration = 0.8
        animation.repeatCount = .infinity
        animation.autoreverses = true
        layer?.removeAllAnimations()
        layer?.add(animation, forKey: nil)
        isAnimating = true
    }

    @objc func endAnimation() {
        layer?.removeAllAnimations()
        isAnimating = false
    }

    override func updateColors() {
        super.updateColors()
        titleLabel.textColor = .white
        layer?.borderColor = NSColor.clear.cgColor
        sepLayer.backgroundColor = NSColor.lkBaseRGB(255, 255, 255, 0.5).cgColor
    }

    override func buttonTextColor() -> NSColor {
        .white
    }
}

/// A red notice that pulses, used for connection loss.
@objc(LKRedTipsView)
class LKRedTipsView: LKTipsView {
    @objc func startAnimation() {
        let animation = CABasicAnimation(keyPath: "backgroundColor")
        animation.fromValue = NSColor.lkBaseRGB(208, 2, 27, 0.9).cgColor
        animation.toValue = NSColor.lkBaseRGB(208, 2, 27, 0.7).cgColor
        animation.duration = 0.8
        animation.repeatCount = .infinity
        animation.autoreverses = true
        layer?.removeAllAnimations()
        layer?.add(animation, forKey: nil)
    }

    @objc func endAnimation() {
        layer?.removeAllAnimations()
    }

    override func updateColors() {
        super.updateColors()
        titleLabel.textColor = .white
        layer?.borderColor = NSColor.clear.cgColor
        sepLayer.backgroundColor = NSColor.lkBaseRGB(255, 255, 255, 0.5).cgColor
    }

    override func buttonTextColor() -> NSColor {
        .white
    }
}
