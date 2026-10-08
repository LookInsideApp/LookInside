//
//  ColorIndicatorLayer.swift
//  LookInside
//

import AppKit

/// A round colour swatch: a checkerboard behind translucent colours, a
/// "no colour" image for nil, and a contrasting border.
class ColorIndicatorLayer: CALayer {
    private var colorLayer: CALayer?
    private var imageLayer: CALayer?

    /// Defaults to black.
    @objc var color: NSColor? = .rgb255(0, 0, 0) {
        didSet { updateForColor() }
    }

    override init() {
        super.init()
        removeImplicitAnimations()
        borderWidth = 1
        let colorLayer = CALayer()
        colorLayer.backgroundColor = color?.cgColor
        colorLayer.removeImplicitAnimations()
        addSublayer(colorLayer)
        self.colorLayer = colorLayer
        masksToBounds = true
    }

    /// Presentation copies carry no sublayer references.
    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func updateForColor() {
        if let color {
            if color.alphaComponent < 1 {
                createImageLayerIfNeeded()
                imageLayer?.isHidden = false
                imageLayer?.contents = NSImage(named: "Transparent_Background")
            } else {
                imageLayer?.isHidden = true
            }
        } else {
            createImageLayerIfNeeded()
            imageLayer?.isHidden = false
            imageLayer?.contents = NSImage(named: "Nil_Color_Image")
        }
        colorLayer?.backgroundColor = color?.cgColor
        borderColor = contrastColor(for: color).cgColor
    }

    private func contrastColor(for color: NSColor?) -> NSColor {
        guard let color else { return .rgb255(191, 191, 191) }
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let newBrightness = brightness > 0.5 ? brightness - 0.2 : brightness + 0.2
        let newAlpha = min(1, alpha + 0.3)
        return NSColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: newAlpha)
    }

    private func createImageLayerIfNeeded() {
        guard imageLayer == nil else { return }
        let imageLayer = CALayer()
        imageLayer.removeImplicitAnimations()
        insertSublayer(imageLayer, at: 0)
        self.imageLayer = imageLayer
        setNeedsLayout()
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        FrameLayout([imageLayer, colorLayer]).visibles().fullFrame()
        cornerRadius = min(frame.width, frame.height) / 2
    }

    private static let renderingLayer = ColorIndicatorLayer()

    /// The swatch drawn into an image of `shapeSize` plus `insets`.
    @objc(imageWithColor:shapeSize:insets:)
    static func image(with color: NSColor?, shapeSize: NSSize, insets: NSEdgeInsets) -> NSImage {
        let layer = renderingLayer
        let image = NSImage(size: NSSize(width: shapeSize.width + insets.left + insets.right, height: shapeSize.height + insets.top + insets.bottom))
        image.lockFocus()
        layer.frame = NSRect(origin: .zero, size: shapeSize)
        layer.color = color
        if let context = NSGraphicsContext.current?.cgContext {
            context.translateBy(x: insets.left, y: insets.top)
            layer.render(in: context)
        }
        image.unlockFocus()
        return image
    }
}
