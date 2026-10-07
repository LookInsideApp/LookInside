//
//  LKWindowToolbarScaleView.swift
//  Lookin
//
//  Created by Li Kai on 2019/10/14.
//  https://lookin.work
//

import AppKit

/// The toolbar's zoom control: a slider between a decrease and an increase
/// button.
final class LKWindowToolbarScaleView: LKBaseView {
    let slider = LKToolbarPreferenceSlider()
    let decreaseButton = LKWindowToolbarScaleView.makeButton(imageNamed: "icon_decrease")
    let increaseButton = LKWindowToolbarScaleView.makeButton(imageNamed: "icon_increase")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(slider)
        addSubview(decreaseButton)
        addSubview(increaseButton)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        LKViewFrameLayout(decreaseButton).width(20).fullHeight().x(0)
        LKViewFrameLayout(increaseButton).width(20).fullHeight().right(0)
        LKViewFrameLayout(slider).fullHeight().x(decreaseButton.frame.maxX).toMaxX(increaseButton.frame.minX)
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 160, height: 34)
    }

    /// `+[NSButton lk_buttonWithImage:target:action:]`: borderless, image only.
    private static func makeButton(imageNamed name: String) -> LKToolbarPreferenceButton {
        let button = LKToolbarPreferenceButton()
        button.image = NSImage(named: name)
        button.bezelStyle = .roundRect
        button.isBordered = false
        return button
    }
}
