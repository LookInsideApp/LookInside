//
//  HierarchyFrameLayout.swift
//  LookInside
//
//  Frame layout for the hierarchy outline and its table views, with the
//  arithmetic and pixel snapping of the ShortCocoa `$(view)` calls it
//  replaces, so rows land on the same pixels as before.
//

import AppKit
import QuartzCore

/// Lays out one view or layer inside its superview / superlayer.
///
/// Every value written is rounded up to the main screen's pixel grid, as
/// ShortCocoa did. Methods return `self` so calls chain in the same order as
/// the ShortCocoa expressions they replace.
struct HierarchyFrameLayout {
    private let getFrame: () -> CGRect
    private let setFrame: (CGRect) -> Void
    private let ownBounds: () -> CGRect
    private let superBounds: () -> CGRect?
    private let superIsFlipped: () -> Bool
    /// `sizeThatFits` of the view a fitting call sizes. LookInside's
    /// ShortCocoa fitting (ShortCocoa+LookinClient) sized LKBaseViews and
    /// NSControls only; other views have none.
    private let measure: ((NSSize) -> NSSize)?
    /// NaN sizes count as 0 for controls, as there.
    private let zeroesNaN: Bool

    init(_ view: NSView) {
        getFrame = { view.frame }
        setFrame = { view.frame = $0 }
        ownBounds = { view.bounds }
        superBounds = { view.superview?.bounds }
        superIsFlipped = { view.superview?.isFlipped ?? false }
        if let baseView = view as? BaseView {
            measure = { baseView.sizeThatFits($0) }
            zeroesNaN = false
        } else if let control = view as? NSControl {
            measure = { control.sizeThatFits($0) }
            zeroesNaN = true
        } else {
            measure = nil
            zeroesNaN = false
        }
    }

    init(_ layer: CALayer) {
        getFrame = { layer.frame }
        setFrame = { layer.frame = $0 }
        ownBounds = { layer.bounds }
        superBounds = { layer.superlayer?.bounds }
        superIsFlipped = { layer.superlayer?.contentsAreFlipped() ?? false }
        measure = nil
        zeroesNaN = false
    }

    static func snap(_ value: CGFloat) -> CGFloat {
        if value == .leastNormalMagnitude || value == .greatestFiniteMagnitude {
            return value
        }
        let scale = NSScreen.main?.backingScaleFactor ?? 1
        return ceil(value * scale) / scale
    }

    private func update(_ change: (inout CGRect) -> Void) {
        var frame = getFrame()
        change(&frame)
        setFrame(frame)
    }

    @discardableResult
    func x(_ value: CGFloat) -> Self {
        update { $0.origin.x = Self.snap(value) }
        return self
    }

    @discardableResult
    func y(_ value: CGFloat) -> Self {
        update { $0.origin.y = Self.snap(value) }
        return self
    }

    @discardableResult
    func width(_ value: CGFloat) -> Self {
        update { $0.size.width = Self.snap(value) }
        return self
    }

    @discardableResult
    func height(_ value: CGFloat) -> Self {
        update { $0.size.height = Self.snap(value) }
        return self
    }

    @discardableResult
    func frame(_ value: CGRect) -> Self {
        x(value.minX).y(value.minY).width(value.width).height(value.height)
    }

    @discardableResult
    func midX(_ value: CGFloat) -> Self {
        x(value - ownBounds().width / 2)
    }

    @discardableResult
    func midY(_ value: CGFloat) -> Self {
        y(value - ownBounds().height / 2)
    }

    @discardableResult
    func maxY(_ value: CGFloat) -> Self {
        y(value - ownBounds().height)
    }

    @discardableResult
    func offsetY(_ value: CGFloat) -> Self {
        update { $0.origin.y = Self.snap($0.minY + value) }
        return self
    }

    /// Keeps the left edge and moves the right edge to `value` inset from
    /// the superview's right edge.
    @discardableResult
    func toRight(_ value: CGFloat) -> Self {
        let superWidth = superBounds()?.width ?? 0
        update { $0.size.width = max(Self.snap(superWidth - $0.minX - value), 0) }
        return self
    }

    /// Keeps the left edge and moves the right edge to `value`.
    @discardableResult
    func toMaxX(_ value: CGFloat) -> Self {
        update { $0.size.width = Self.snap(max(value, $0.minX) - $0.minX) }
        return self
    }

    /// Keeps the top edge and moves the bottom edge to `value`.
    @discardableResult
    func toMaxY(_ value: CGFloat) -> Self {
        update { $0.size.height = Self.snap(max(value, $0.minY) - $0.minY) }
        return self
    }

    /// Keeps the bottom edge and moves the top edge to `value`.
    @discardableResult
    func toY(_ value: CGFloat) -> Self {
        update { frame in
            let top = min(value, frame.maxY)
            frame.size.height = Self.snap(frame.maxY - top)
            frame.origin.y = Self.snap(top)
        }
        return self
    }

    /// Moves the bottom edge to `value` above the superview's bottom.
    @discardableResult
    func toBottom(_ value: CGFloat) -> Self {
        guard let superBounds = superBounds() else {
            return self
        }
        if superIsFlipped() {
            return toMaxY(superBounds.height - value)
        }
        return toY(value)
    }

    /// Places the bottom edge `value` above the superview's bottom.
    @discardableResult
    func bottom(_ value: CGFloat) -> Self {
        guard let superBounds = superBounds() else {
            return self
        }
        if superIsFlipped() {
            return maxY(superBounds.height - value)
        }
        return y(value)
    }

    @discardableResult
    func fullWidth() -> Self {
        x(0).toRight(0)
    }

    @discardableResult
    func fullHeight() -> Self {
        guard let superBounds = superBounds() else {
            return self
        }
        return height(superBounds.height).y(0)
    }

    @discardableResult
    func fullFrame() -> Self {
        fullWidth().fullHeight()
    }

    @discardableResult
    func horAlign() -> Self {
        guard let superBounds = superBounds() else {
            return self
        }
        return midX(superBounds.width / 2)
    }

    @discardableResult
    func verAlign() -> Self {
        guard let superBounds = superBounds() else {
            return self
        }
        return midY(superBounds.height / 2)
    }

    @discardableResult
    func centerAlign() -> Self {
        verAlign().horAlign()
    }

    /// Sizes an BaseView or a control to `sizeThatFits` with no limit, as
    /// LookInside's replacement for ShortCocoa's `sizeToFit` did; other
    /// views are left alone. AppKit's own `-sizeToFit` sizes an image view
    /// to nothing, which hid the row icons.
    @discardableResult
    func sizeToFit() -> Self {
        guard let measure else {
            return self
        }
        var size = measure(NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        if zeroesNaN, size.width.isNaN {
            size.width = 0
        }
        if zeroesNaN, size.height.isNaN {
            size.height = 0
        }
        var rect = getFrame()
        rect.size = size
        setFrame(rect)
        return self
    }

    /// Fits an BaseView's or a control's height to its width; other views
    /// are left alone.
    @discardableResult
    func heightToFit() -> Self {
        guard let measure else {
            return self
        }
        let fitting = measure(NSSize(width: ownBounds().width, height: .greatestFiniteMagnitude))
        var rect = getFrame()
        rect.size.height = fitting.height
        setFrame(rect)
        return self
    }
}

extension NSView {
    /// ShortCocoa's visibility test for layout: shown, in a superview and
    /// not transparent.
    var lkHierarchyIsLaidOutVisible: Bool {
        !isHidden && superview != nil && alphaValue >= 0.01
    }
}
