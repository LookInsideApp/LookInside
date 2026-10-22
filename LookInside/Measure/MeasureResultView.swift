//
//  MeasureResultView.swift
//  LookInside
//
//  Draws the two measured items scaled into the Measure panel, with blue
//  horizontal and orange vertical distance lines and their value labels.
//

import AppKit
import LookInsideHostCore

final class MeasureResultView: BaseView {
    private static let horizontalInset: CGFloat = 20
    private static let verticalInset: CGFloat = 20
    private static let labelHeight: CGFloat = 18
    private static let handleLength: CGFloat = 3

    private static let horizontalColor = NSColor(red: 10 / 255.0, green: 127 / 255.0, blue: 251 / 255.0, alpha: 1)
    private static let verticalColor = NSColor(red: 209 / 255.0, green: 120 / 255.0, blue: 0, alpha: 1)

    private let contentView = BaseView()
    private let mainImageView = NSImageView()
    private let referImageView = NSImageView()
    private let linesContainerView = BaseView()
    private let horizontalLinesLayer = CAShapeLayer()
    private let verticalLinesLayer = CAShapeLayer()
    private let mainImageViewBorderLayer = CALayer()
    private let referImageViewBorderLayer = CALayer()
    private var labelViews: [TextFieldView] = []

    private var originalMainFrame: CGRect = .zero
    private var originalReferFrame: CGRect = .zero
    private var scaledMainFrame: CGRect = .zero
    private var scaledReferFrame: CGRect = .zero

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        hasEffectedBackground = true
        layer?.cornerRadius = DashboardCardCornerRadius

        // The labels often stick out of the content.
        contentView.layer?.masksToBounds = false
        addSubview(contentView)

        mainImageView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addSubview(mainImageView)

        referImageView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addSubview(referImageView)

        linesContainerView.layer?.masksToBounds = false
        contentView.addSubview(linesContainerView)

        for borderLayer in [mainImageViewBorderLayer, referImageViewBorderLayer] {
            borderLayer.borderWidth = 1
            borderLayer.removeImplicitAnimations()
            linesContainerView.layer?.addSublayer(borderLayer)
        }

        horizontalLinesLayer.lineWidth = 1
        horizontalLinesLayer.removeImplicitAnimations()
        horizontalLinesLayer.strokeColor = Self.horizontalColor.cgColor
        linesContainerView.layer?.addSublayer(horizontalLinesLayer)

        verticalLinesLayer.lineWidth = 1
        verticalLinesLayer.removeImplicitAnimations()
        verticalLinesLayer.strokeColor = Self.verticalColor.cgColor
        linesContainerView.layer?.addSublayer(verticalLinesLayer)

        updateColors()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func updateColors() {
        super.updateColors()
        let borderColor = isDarkMode()
            ? NSColor(red: 123 / 255.0, green: 123 / 255.0, blue: 123 / 255.0, alpha: 1)
            : NSColor(red: 190 / 255.0, green: 190 / 255.0, blue: 190 / 255.0, alpha: 1)
        referImageViewBorderLayer.borderColor = borderColor.cgColor
        mainImageViewBorderLayer.borderColor = borderColor.cgColor
    }

    override func layout() {
        super.layout()
        mainImageView.frame = scaledMainFrame
        referImageView.frame = scaledReferFrame

        let contentSize = MeasureGuides.extent(scaledMainFrame, scaledReferFrame)
        contentView.lkpSetWidth(contentSize.width)
        contentView.lkpSetHeight(contentSize.height)
        contentView.lkpCenterAlign()

        linesContainerView.frame = contentView.bounds
        horizontalLinesLayer.frame = linesContainerView.bounds
        verticalLinesLayer.frame = linesContainerView.bounds
        mainImageViewBorderLayer.frame = mainImageView.frame
        referImageViewBorderLayer.frame = referImageView.frame
        renderLinesAndLabels()
    }

    func render(mainRect: CGRect, mainImage: NSImage?, referRect: CGRect, referImage: NSImage?) {
        originalMainFrame = mainRect
        originalReferFrame = referRect
        mainImageView.image = mainImage
        referImageView.image = referImage

        let maxContentWidth = MeasureViewWidth - Self.horizontalInset * 2
        let windowHeight = window?.frame.height ?? 0
        let titleBarHeight = NavigationManager.shared.windowTitleBarHeight
        let maxContentHeight = max((windowHeight - titleBarHeight) * 0.8, 200)
        let factor = MeasureGuides.scaleFactor(main: mainRect, refer: referRect,
                                               maxWidth: maxContentWidth, maxHeight: maxContentHeight)
        // These are the frames the next layout uses.
        (scaledMainFrame, scaledReferFrame) = MeasureGuides.scaledFrames(main: mainRect, refer: referRect, factor: factor)
        needsLayout = true
    }

    private func renderLinesAndLabels() {
        for labelView in labelViews {
            labelView.isHidden = true
        }
        horizontalLinesLayer.isHidden = true
        verticalLinesLayer.isHidden = true

        // The frame that contains the other is dimmed: the lines then run
        // outside the inner frame but inside the outer one.
        let alphas = MeasureGuides.Overlap(main: scaledMainFrame, refer: scaledReferFrame).alphas
        mainImageView.alphaValue = alphas.main
        referImageView.alphaValue = alphas.refer

        let horizontalLines = MeasureGuides.horizontalLines(a: scaledMainFrame, b: scaledReferFrame,
                                                            originalA: originalMainFrame, originalB: originalReferFrame)
        let verticalLines = MeasureGuides.verticalLines(a: scaledMainFrame, b: scaledReferFrame,
                                                        originalA: originalMainFrame, originalB: originalReferFrame)
        let handle = Self.handleLength

        let horizontalPath = CGMutablePath()
        for line in horizontalLines {
            horizontalPath.move(to: CGPoint(x: line.startX, y: line.y))
            horizontalPath.addLine(to: CGPoint(x: line.endX, y: line.y))
            // Small handles at both ends.
            horizontalPath.move(to: CGPoint(x: line.startX + 0.5, y: line.y - handle))
            horizontalPath.addLine(to: CGPoint(x: line.startX + 0.5, y: line.y + handle))
            horizontalPath.move(to: CGPoint(x: line.endX - 0.5, y: line.y - handle))
            horizontalPath.addLine(to: CGPoint(x: line.endX - 0.5, y: line.y + handle))

            let labelView = dequeueLabelView()
            labelView.backgroundColor = .systemBlue
            labelView.textField.stringValue = NSString.string(from: Double(line.value), decimal: 2)
            labelView.lkpSizeToFit()
            labelView.lkpSetHeight(Self.labelHeight)
            labelView.lkpSetMidX(line.startX + (line.endX - line.startX) / 2)
            labelView.lkpSetMaxY(line.y - 5)
        }

        let verticalPath = CGMutablePath()
        for line in verticalLines {
            verticalPath.move(to: CGPoint(x: line.x, y: line.startY))
            verticalPath.addLine(to: CGPoint(x: line.x, y: line.endY))
            // Small handles at both ends.
            verticalPath.move(to: CGPoint(x: line.x - handle, y: line.startY + 0.5))
            verticalPath.addLine(to: CGPoint(x: line.x + handle, y: line.startY + 0.5))
            verticalPath.move(to: CGPoint(x: line.x - handle, y: line.endY - 0.5))
            verticalPath.addLine(to: CGPoint(x: line.x + handle, y: line.endY - 0.5))

            let labelView = dequeueLabelView()
            labelView.backgroundColor = Self.verticalColor
            labelView.textField.stringValue = NSString.string(from: Double(line.value), decimal: 2)
            labelView.lkpSizeToFit()
            labelView.lkpSetHeight(Self.labelHeight)
            labelView.lkpSetMidY(line.startY + (line.endY - line.startY) / 2)
            labelView.lkpSetMaxX(line.x - 5)
            if overlapsAnotherLabel(labelView) {
                labelView.lkpSetX(line.x + 5)
                // Let the covered text show through a little.
                labelView.backgroundColor = Self.verticalColor.withAlphaComponent(0.5)
            }
        }

        horizontalLinesLayer.path = horizontalPath
        horizontalLinesLayer.isHidden = false
        verticalLinesLayer.path = verticalPath
        verticalLinesLayer.isHidden = false
    }

    private func overlapsAnotherLabel(_ target: NSView) -> Bool {
        labelViews.contains { other in
            guard other !== target, other.isVisible else { return false }
            let intersection = other.frame.intersection(target.frame)
            return !intersection.isNull && intersection.width * intersection.height > 100
        }
    }

    override func sizeThatFits(_: NSSize) -> NSSize {
        let height = MeasureGuides.extent(scaledMainFrame, scaledReferFrame).height
        return NSSize(width: MeasureViewWidth, height: height + Self.verticalInset * 2)
    }

    private func dequeueLabelView() -> TextFieldView {
        if let hidden = labelViews.first(where: { $0.isHidden }) {
            hidden.isHidden = false
            return hidden
        }
        let labelView = TextFieldView.label()
        labelView.insets = NSEdgeInsets(top: 0, left: 3, bottom: 0, right: 3)
        labelView.textField.textColor = .white
        labelView.textField.font = .systemFont(ofSize: 13)
        labelView.textField.alignment = .center
        labelView.layer?.cornerRadius = Self.labelHeight / 2
        contentView.addSubview(labelView)
        labelViews.append(labelView)
        return labelView
    }
}
