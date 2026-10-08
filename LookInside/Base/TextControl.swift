//
//  TextControl.swift
//  Lookin
//
//  Created by Li Kai on 2019/3/12.
//  https://lookin.work
//

import AppKit

@objc(LKTextControl)
class TextControl: BaseControl {
    @objc let label = TextLabel()

    @objc var insets = NSEdgeInsets() {
        didSet {
            needsLayout = true
        }
    }

    @objc var rightImage: NSImage? {
        didSet {
            if let rightImage {
                if rightImageView == nil {
                    let imageView = NSImageView()
                    addSubview(imageView)
                    rightImageView = imageView
                }
                rightImageView?.image = rightImage
            } else {
                rightImageView?.removeFromSuperview()
            }
            needsLayout = true
        }
    }

    @objc var spaceBetweenLabelAndImage: CGFloat = 0 {
        didSet {
            needsLayout = true
        }
    }

    @objc var rightImageOffsetY: CGFloat = 0 {
        didSet {
            needsLayout = true
        }
    }

    /// Created by the first rightImage and kept (only taken out of the view
    /// tree) when the image is cleared.
    private var rightImageView: NSImageView?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        label.alignment = .center
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        label.alignment = .center
        addSubview(label)
    }

    override func layout() {
        super.layout()
        var labelMaxX = frame.width - insets.right
        if let rightImageView {
            rightImageView.frameLayout.sizeToFit().verAlign().right(insets.right).offsetY(rightImageOffsetY)
            labelMaxX = rightImageView.frame.minX - spaceBetweenLabelAndImage
        }
        label.frameLayout.x(insets.left).toMaxX(labelMaxX).heightToFit().verAlign()
        if insets.top != insets.bottom {
            label.frameLayout.offsetY(insets.top - insets.bottom)
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        // Without an image view the image space still counts, as it did in
        // Objective-C (a nil view reads as not hidden, 0 wide).
        let reservesImageSpace = !(rightImageView?.isHidden ?? false)
        let imageSpace = reservesImageSpace ? (rightImageView?.bestWidth() ?? 0) + spaceBetweenLabelAndImage : 0

        let labelMaxWidth = limitedSize.width - insets.left - insets.right - imageSpace
        let labelSize = label.sizeThatFits(NSSize(width: labelMaxWidth, height: .greatestFiniteMagnitude))

        let resultWidth = labelSize.width + insets.left + insets.right + imageSpace
        let resultHeight = labelSize.height + insets.top + insets.bottom
        return NSSize(width: resultWidth, height: resultHeight)
    }
}
