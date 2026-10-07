//
//  LKOutlineRowView.swift
//  LookInside
//
//  Created by Li Kai on 2019/4/20.
//  https://lookin.work
//

import AppKit

private let indentUnitWidth: CGFloat = 14
private let disclosureWidth: CGFloat = 16

@objc enum LKOutlineRowViewStatus: UInt {
    case notExpandable
    case expanded
    case collapsed
}

@objc(LKOutlineRowView)
@objcMembers
class LKOutlineRowView: LKTableRowView {
    let disclosureButton: NSButton!
    let imageView: NSImageView!

    var image: NSImage? {
        didSet {
            imageView.image = image
            imageView.isHidden = (image == nil)
            needsLayout = true
        }
    }

    var status: LKOutlineRowViewStatus = .notExpandable {
        didSet {
            updateDisclosureButton()
        }
    }

    var indentLevel: UInt = 0 {
        didSet {
            needsLayout = true
        }
    }

    /// The gap between the title and the subtitle; set by init(compactUI:).
    private(set) var subtitleLeft: CGFloat

    private let imageLeft: CGFloat = 5
    private let imageRight: CGFloat = 2
    private let titleLeft: CGFloat

    init(compactUI compact: Bool) {
        titleLeft = compact ? 0 : 2
        subtitleLeft = compact ? 2 : 10
        disclosureButton = NSButton()
        imageView = NSImageView()
        super.init(frame: .zero)

        disclosureButton.isBordered = false
        disclosureButton.setButtonType(.momentaryChange)
        addSubview(disclosureButton)

        imageView.isHidden = true
        addSubview(imageView)
    }

    override convenience init(frame _: NSRect) {
        self.init(compactUI: false)
    }

    required init?(coder _: NSCoder) {
        fatalError("LKOutlineRowView is not loaded from archives")
    }

    override func layout() {
        super.layout()

        LKHierarchyFrameLayout(disclosureButton)
            .width(disclosureWidth)
            .fullHeight()
            .midX(Self.dislosureMidX(withIndentLevel: indentLevel))
            .verAlign()

        var x = disclosureButton.frame.maxX
        if !imageView.isHidden, imageView.alphaValue > 0 {
            LKHierarchyFrameLayout(imageView).sizeToFit().verAlign().x(x + imageLeft)
            x = imageView.frame.maxX + imageRight
        }

        LKHierarchyFrameLayout(titleLabel).sizeToFit().x(x + titleLeft).verAlign()
        var maxX = titleLabel.frame.maxX

        if !subtitleLabel.isHidden, subtitleLabel.alphaValue > 0 {
            LKHierarchyFrameLayout(subtitleLabel).sizeToFit().x(titleLabel.frame.maxX + subtitleLeft).verAlign()
            maxX = subtitleLabel.frame.maxX
        }
        for view: NSView in [disclosureButton!, titleLabel!, subtitleLabel!] where view.lkHierarchyIsLaidOutVisible {
            LKHierarchyFrameLayout(view).offsetY(-1)
        }

        horizontalScrollWidthManager?.rowDidLayout(withWidth: maxX)
    }

    override var isRowSelected: Bool {
        didSet {
            updateDisclosureButton()
        }
    }

    class func dislosureMidX(withIndentLevel level: UInt) -> CGFloat {
        insetLeft() + CGFloat(level) * indentUnitWidth + disclosureWidth / 2
    }

    private func updateDisclosureButton() {
        switch status {
        case .notExpandable:
            disclosureButton.isHidden = true
        case .expanded:
            disclosureButton.isHidden = false
            disclosureButton.image = NSImage(named: isSelected ? "icon_arrow_down_selected" : "icon_arrow_down")
        default:
            disclosureButton.isHidden = false
            disclosureButton.image = NSImage(named: isSelected ? "icon_arrow_right_selected" : "icon_arrow_right")
        }
    }

    // MARK: - Subclassing hooks

    class func insetLeft() -> CGFloat {
        6
    }
}
