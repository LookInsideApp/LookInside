//
//  LKBaseView.swift
//  Lookin
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit

private let effectiveAppearanceContext = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)

@objc enum LKViewBorderPosition: Int {
    case none
    case top
    case left
    case bottom
    case right
}

@objc(LKBaseView)
@objcMembers
class LKBaseView: NSView, NSViewToolTipOwner {
    var tooltipString: String? {
        didSet {
            if tooltipString != nil {
                addToolTip(bounds, owner: self, userData: nil)
            } else {
                removeAllToolTips()
            }
        }
    }

    var backgroundColor: NSColor? {
        didSet {
            layer?.backgroundColor = backgroundColor?.cgColor
        }
    }

    var backgroundColors: LKTwoColors? {
        didSet {
            updateColors()
        }
    }

    /// 可以单独设置某一条边有 border，颜色由 borderColors 属性决定，注意通过这个属性设置了单边 border 后，就不要再使用系统的 layer.border 接口来设置四边 border 了
    /// 默认为 .none
    var borderPosition: LKViewBorderPosition = .none {
        didSet {
            if borderPosition == .none {
                customBorderLayer?.removeFromSuperlayer()
                return
            }
            if customBorderLayer == nil {
                let borderLayer = CALayer()
                borderLayer.lookin_removeImplicitAnimations()
                customBorderLayer = borderLayer
                updateColors()
                layer?.addSublayer(borderLayer)
            }
            needsLayout = true
        }
    }

    /// 通过系统的 layer.border 接口和上面的 borderPosition 接口设置的 border 均可被该属性影响到
    /// 默认为 SeparatorLightModeColor / SeparatorDarkModeColor
    var borderColors: LKTwoColors? {
        didSet {
            updateColors()
        }
    }

    /// 当设置该 block 之后，该 block 会立即被调用一次
    var didChangeAppearanceBlock: ((LKBaseView?, Bool) -> Void)? {
        didSet {
            triggerDidChangeAppearanceBlock()
        }
    }

    var didLayout: (() -> Void)?

    /// 是否磨砂背景
    var hasEffectedBackground: Bool = false {
        didSet {
            if hasEffectedBackground {
                if backgroundEffectView != nil {
                    return
                }
                let effectView = LKVisualEffectView()
                effectView.blendingMode = .withinWindow
                effectView.state = .active
                backgroundEffectView = effectView
                lk_insertSubviewAtBottom(effectView)
                needsLayout = true
            } else {
                backgroundEffectView?.removeFromSuperview()
                backgroundEffectView = nil
            }
        }
    }

    private var customBorderLayer: CALayer?
    private var backgroundEffectView: LKVisualEffectView?
    private var isObservingEffectiveAppearance = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true

        borderColors = LKTwoColors(colorInLightMode: .lkBaseRGB(215, 215, 215), colorInDarkMode: .lkBaseRGB(67, 67, 69))
        beginObservingAppearanceIfNeeded()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        if isObservingEffectiveAppearance {
            removeObserver(self, forKeyPath: "effectiveAppearance", context: effectiveAppearanceContext)
        }
    }

    /// Overrides the NSView extension (Base/Category/NSView+LookinClient.swift):
    /// a base view also needs a superview to count as visible.
    override var isVisible: Bool {
        superview != nil && !isHidden && alphaValue >= 0.01
    }

    override var isFlipped: Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if isHidden || alphaValue <= 0 {
            return nil
        }
        return super.hitTest(point)
    }

    override func layout() {
        super.layout()

        if let backgroundEffectView {
            backgroundEffectView.lkLayout.fullFrame()
        }

        if tooltipString != nil {
            addToolTip(bounds, owner: self, userData: nil)
        } else {
            removeAllToolTips()
        }

        switch borderPosition {
        case .top:
            customBorderLayer?.lkLayout.fullWidth().height(1).y(0)
        case .left:
            customBorderLayer?.lkLayout.fullHeight().width(1).x(0)
        case .bottom:
            customBorderLayer?.lkLayout.fullFrame().height(1).bottom(0)
        case .right:
            customBorderLayer?.lkLayout.fullHeight().width(1).right(0)
        default:
            break
        }

        didLayout?()
    }

    func view(_: NSView, stringForToolTip _: NSView.ToolTipTag, point _: NSPoint, userData _: UnsafeMutableRawPointer?) -> String {
        tooltipString ?? ""
    }

    func height(forWidth width: CGFloat) -> CGFloat {
        sizeThatFits(NSSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    override func updateLayer() {
        super.updateLayer()
        if let backgroundColorName {
            layer?.backgroundColor = NSColor(named: backgroundColorName)?.cgColor
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == effectiveAppearanceContext {
            triggerDidChangeAppearanceBlock()
            return
        }
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }

    private func beginObservingAppearanceIfNeeded() {
        if isObservingEffectiveAppearance {
            return
        }
        addObserver(self, forKeyPath: "effectiveAppearance", options: [.initial, .new], context: effectiveAppearanceContext)
        isObservingEffectiveAppearance = true
    }

    private func triggerDidChangeAppearanceBlock() {
        didChangeAppearanceBlock?(self, isDarkMode())
        updateColors()
    }

    /// 用户切换主题时，该方法会被调用；子类重写时要调用 super。
    func updateColors() {
        if let backgroundColors {
            layer?.backgroundColor = backgroundColors.color?.cgColor
        }
        if let borderColors {
            layer?.borderColor = borderColors.color?.cgColor
            customBorderLayer?.backgroundColor = borderColors.color?.cgColor
        }
    }

    func isDarkMode() -> Bool {
        effectiveAppearance.lk_isDarkMode
    }

    // MARK: - Subclassing hooks

    func sizeThatFits(_: NSSize) -> NSSize {
        .zero
    }

    func sizeToFit() {}
}

@objc(LKVisualEffectView)
class LKVisualEffectView: NSVisualEffectView {
    override var isFlipped: Bool {
        true
    }
}
