//
//  LKLabel.swift
//  Lookin
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit

@objc(LKLabel)
class LKLabel: NSTextField {
    /// 默认为 nil
    @objc var textColors: LKTwoColors? {
        didSet {
            updateColors()
        }
    }

    /// 默认为 nil
    @objc var backgroundColors: LKTwoColors? {
        didSet {
            updateColors()
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        backgroundColor = .clear
        isBezeled = false
        drawsBackground = true
        isEditable = false
        isSelectable = false

        updateColors()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 不做保护的话，传入 nil 会 crash：an Objective-C nil reaches this
    /// setter as an empty string.
    override var stringValue: String {
        get {
            super.stringValue
        }
        set {
            super.stringValue = newValue
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    private func updateColors() {
        if let textColors {
            textColor = textColors.color
        }
        if let backgroundColors {
            backgroundColor = backgroundColors.color
        }
    }
}
