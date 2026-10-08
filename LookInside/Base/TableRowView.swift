//
//  TableRowView.swift
//  Lookin
//
//  Created by Li Kai on 2019/4/20.
//  https://lookin.work
//

import AppKit

@objc(LKTableRowView)
@objcMembers
class TableRowView: NSTableRowView {
    let titleLabel: TextLabel!
    let subtitleLabel: TextLabel!

    /// The selection TableView draws. NSTableView's own row selection
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

    weak var horizontalScrollWidthManager: TableViewHorizontalScrollWidthManager?

    private let backgroundColorLayer = CALayer()
    private var selectedState = false
    private var hoveredState = false
    private var darkModeState = false

    override init(frame frameRect: NSRect) {
        titleLabel = TextLabel()
        subtitleLabel = TextLabel()
        super.init(frame: frameRect)
        wantsLayer = true

        backgroundColorLayer.removeImplicitAnimations()
        layer?.addSublayer(backgroundColorLayer)

        titleLabel.lineBreakMode = .byTruncatingMiddle
        addSubview(titleLabel)

        addSubview(subtitleLabel)

        // Through the method, so subclasses see the initial value.
        setIsDarkMode(effectiveAppearance.isDarkMode)

        updateBackgroundLayerColor()
    }

    required init?(coder _: NSCoder) {
        fatalError("TableRowView is not loaded from archives")
    }

    override func layout() {
        super.layout()
        backgroundColorLayer.frameLayout.fullFrame()
    }

    override var isFlipped: Bool {
        true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        setIsDarkMode(effectiveAppearance.isDarkMode)
        updateBackgroundLayerColor()
    }

    private func updateBackgroundLayerColor() {
        if isRowSelected {
            backgroundColorLayer.backgroundColor = AppHelper.accentColor().cgColor
        } else if isHovered {
            backgroundColorLayer.backgroundColor = isDarkMode ? NSColor.rgb255(255, 255, 255, 0.15).cgColor : NSColor.rgb255(0, 0, 0, 0.1).cgColor
        } else {
            backgroundColorLayer.backgroundColor = NSColor.clear.cgColor
        }
    }
}

@objc(LKTableBlankRowView)
final class TableBlankRowView: TableRowView {}
