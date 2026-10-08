//
//  LKTableRowView.swift
//  Lookin
//
//  Created by Li Kai on 2019/4/20.
//  https://lookin.work
//

import AppKit

@objc(LKTableRowView)
@objcMembers
class LKTableRowView: NSTableRowView {
    let titleLabel: LKLabel!
    let subtitleLabel: LKLabel!

    /// The selection LKTableView draws. NSTableView's own row selection
    /// (setSelected:) does not change it, but isSelected reports this value.
    var isRowSelected: Bool {
        get {
            selectedState
        }
        set {
            if selectedState == newValue {
                return
            }
            selectedState = newValue
            updateBackgroundLayerColor()
        }
    }

    /// The getter reports isRowSelected; the setter (-setSelected:, which
    /// NSTableView calls) keeps AppKit's behaviour and changes nothing here.
    override var isSelected: Bool {
        get {
            isRowSelected
        }
        set {
            super.isSelected = newValue
        }
    }

    var isHovered: Bool {
        get {
            hoveredState
        }
        set {
            if hoveredState == newValue {
                return
            }
            hoveredState = newValue
            updateBackgroundLayerColor()
        }
    }

    var isDarkMode: Bool {
        darkModeState
    }

    /// 子类可在该方法里更新 UI；子类重写时要调用 super。
    func setIsDarkMode(_ isDarkMode: Bool) {
        darkModeState = isDarkMode
    }

    weak var horizontalScrollWidthManager: LKTableViewHorizontalScrollWidthManager?

    private let backgroundColorLayer = CALayer()
    private var selectedState = false
    private var hoveredState = false
    private var darkModeState = false

    override init(frame frameRect: NSRect) {
        titleLabel = LKLabel()
        subtitleLabel = LKLabel()
        super.init(frame: frameRect)
        wantsLayer = true

        backgroundColorLayer.removeImplicitAnimations()
        layer?.addSublayer(backgroundColorLayer)

        titleLabel.lineBreakMode = .byTruncatingMiddle
        addSubview(titleLabel)

        addSubview(subtitleLabel)

        // Through the method, so subclasses see the initial value.
        setIsDarkMode(effectiveAppearance.lk_isDarkMode)

        updateBackgroundLayerColor()
    }

    required init?(coder _: NSCoder) {
        fatalError("LKTableRowView is not loaded from archives")
    }

    override func layout() {
        super.layout()
        backgroundColorLayer.lkLayout.fullFrame()
    }

    override var isFlipped: Bool {
        true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        setIsDarkMode(effectiveAppearance.lk_isDarkMode)
        updateBackgroundLayerColor()
    }

    private func updateBackgroundLayerColor() {
        if isRowSelected {
            backgroundColorLayer.backgroundColor = LKHelper.accentColor().cgColor
        } else if isHovered {
            backgroundColorLayer.backgroundColor = isDarkMode ? NSColor.lkBaseRGB(255, 255, 255, 0.15).cgColor : NSColor.lkBaseRGB(0, 0, 0, 0.1).cgColor
        } else {
            backgroundColorLayer.backgroundColor = NSColor.clear.cgColor
        }
    }
}

@objc(LKTableBlankRowView)
final class LKTableBlankRowView: LKTableRowView {}
