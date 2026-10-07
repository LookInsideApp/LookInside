//
//  LKImageTextView.swift
//  LookInside
//

import AppKit

/// An image followed by a one-line label, centred vertically.
@objc(LKImageTextView)
class LKImageTextView: LKBaseView {
    @objc let imageView = NSImageView()
    @objc let label = LKLabel()

    var imageMargins = HorizontalMargins(left: 0, right: 0)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(imageView)
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(imageView)
        addSubview(label)
    }

    override func layout() {
        super.layout()
        imageView.lkLayout.sizeToFit().x(imageMargins.left).verAlign()
        label.lkLayout.x(imageView.frame.maxX + imageMargins.right).toRight(0).heightToFit().verAlign()
    }

    override func sizeThatFits(_: NSSize) -> NSSize {
        let labelSize = label.sizeThatFits(NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        let imageSize = imageView.image?.size ?? .zero
        return NSSize(
            width: imageMargins.left + imageSize.width + imageMargins.right + labelSize.width,
            height: max(imageSize.height, labelSize.height)
        )
    }
}
