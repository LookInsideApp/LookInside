//
//  FrameLayout.swift
//  LookInside
//
//  Frame arithmetic for views and layers laid out by hand. It replaces
//  ShortCocoa's `$(view)` chains with the same results: every setter snaps
//  to the main screen's pixel grid, `sizeToFit` / `heightToFit` behave as
//  ShortCocoa+LookinClient's replacements did, and views and layers can be
//  mixed in one chain.
//

import AppKit

@objc(LKFrameLayout)
final class FrameLayout: NSObject {
    private enum Target {
        case view(NSView)
        case layer(CALayer)

        var frame: CGRect {
            get {
                switch self {
                case let .view(view): view.frame
                case let .layer(layer): layer.frame
                }
            }
            nonmutating set {
                switch self {
                case let .view(view): view.frame = newValue
                case let .layer(layer): layer.frame = newValue
                }
            }
        }

        var bounds: CGRect {
            switch self {
            case let .view(view): view.bounds
            case let .layer(layer): layer.bounds
            }
        }

        /// The superview's or superlayer's bounds; nil without one.
        var parentBounds: CGRect? {
            switch self {
            case let .view(view): view.superview?.bounds
            case let .layer(layer): layer.superlayer?.bounds
            }
        }

        var parentIsFlipped: Bool {
            switch self {
            case let .view(view): view.superview?.isFlipped ?? false
            case let .layer(layer): layer.superlayer?.contentsAreFlipped() ?? false
            }
        }

        var parent: AnyObject? {
            switch self {
            case let .view(view): view.superview
            case let .layer(layer): layer.superlayer
            }
        }

        var isVisible: Bool {
            switch self {
            case let .view(view):
                !view.isHidden && view.superview != nil && view.alphaValue >= 0.01
            case let .layer(layer):
                !layer.isHidden && layer.superlayer != nil && layer.opacity >= 0.01
            }
        }
    }

    private var targets: [Target]

    /// Wraps views and layers; anything else (and nil) is ignored.
    init(_ objects: [AnyObject?]) {
        targets = objects.compactMap { object in
            if let view = object as? NSView {
                return .view(view)
            }
            if let layer = object as? CALayer {
                return .layer(layer)
            }
            return nil
        }
    }

    private init(targets: [Target]) {
        self.targets = targets
    }

    /// ObjC entry point: `[LKFrameLayout of:view]`.
    @objc(of:)
    static func of(_ object: AnyObject?) -> FrameLayout {
        FrameLayout([object])
    }

    /// ObjC entry point for several views or layers at once.
    @objc(ofAll:)
    static func ofAll(_ objects: [AnyObject]) -> FrameLayout {
        FrameLayout(objects)
    }

    /// Rounds up to the main screen's pixel grid. `CGFLOAT_MIN` and
    /// `CGFLOAT_MAX` pass through because callers use them as markers.
    @objc
    static func snapToPixel(_ value: CGFloat) -> CGFloat {
        if value == .leastNormalMagnitude || value == .greatestFiniteMagnitude {
            return value
        }
        let scale = NSScreen.main?.backingScaleFactor ?? 0
        return ceil(value * scale) / scale
    }

    private static func checked(_ value: CGFloat) -> CGFloat {
        if value.isNaN {
            assertionFailure("NaN passed to a layout setter")
            return 0
        }
        return value
    }

    private func each(_ body: (Target) -> Void) {
        targets.forEach(body)
    }

    // MARK: - Sizing

    /// Sizes an BaseView or NSControl to `sizeThatFits:` of an unlimited
    /// size; other views and layers are left alone.
    @objc @discardableResult
    func sizeToFit() -> FrameLayout {
        each { target in
            guard case let .view(view) = target else { return }
            let unlimited = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
            if let baseView = view as? BaseView {
                var rect = baseView.frame
                rect.size = baseView.sizeThatFits(unlimited)
                baseView.frame = rect
            } else if let control = view as? NSControl {
                var size = control.sizeThatFits(unlimited)
                if size.width.isNaN {
                    size.width = 0
                }
                if size.height.isNaN {
                    size.height = 0
                }
                var rect = control.frame
                rect.size = size
                control.frame = rect
            }
        }
        return self
    }

    /// Sets an BaseView's or NSControl's height to what it needs at its
    /// current width.
    @objc @discardableResult
    func heightToFit() -> FrameLayout {
        each { target in
            guard case let .view(view) = target else { return }
            let height: CGFloat
            if let baseView = view as? BaseView {
                height = baseView.sizeThatFits(NSSize(width: baseView.bounds.width, height: .greatestFiniteMagnitude)).height
            } else if let control = view as? NSControl {
                height = control.sizeThatFits(NSSize(width: control.bounds.width, height: .greatestFiniteMagnitude)).height
            } else {
                return
            }
            var rect = view.frame
            rect.size.height = height
            view.frame = rect
        }
        return self
    }

    @objc(width:) @discardableResult
    func width(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { $0.frame.size.width = Self.snapToPixel(value) }
        return self
    }

    @objc(height:) @discardableResult
    func height(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { $0.frame.size.height = Self.snapToPixel(value) }
        return self
    }

    @objc(size:) @discardableResult
    func size(_ value: NSSize) -> FrameLayout {
        width(value.width).height(value.height)
    }

    /// Grows the width to `value` when it is narrower; never snaps.
    @objc(minWidth:) @discardableResult
    func minWidth(_ value: CGFloat) -> FrameLayout {
        if value.isNaN {
            assertionFailure("NaN passed to minWidth")
            return self
        }
        each { target in
            if target.frame.width < value {
                target.frame.size.width = value
            }
        }
        return self
    }

    // MARK: - Position

    @objc(x:) @discardableResult
    func x(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { $0.frame.origin.x = Self.snapToPixel(value) }
        return self
    }

    @objc(y:) @discardableResult
    func y(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { $0.frame.origin.y = Self.snapToPixel(value) }
        return self
    }

    @objc(offsetX:) @discardableResult
    func offsetX(_ value: CGFloat) -> FrameLayout {
        offset(x: value, y: 0)
    }

    @objc(offsetY:) @discardableResult
    func offsetY(_ value: CGFloat) -> FrameLayout {
        offset(x: 0, y: value)
    }

    private func offset(x: CGFloat, y: CGFloat) -> FrameLayout {
        let x = Self.checked(x)
        let y = Self.checked(y)
        each { target in
            var rect = target.frame
            rect.origin.x = Self.snapToPixel(target.frame.minX + x)
            rect.origin.y = Self.snapToPixel(target.frame.minY + y)
            target.frame = rect
        }
        return self
    }

    @objc(midX:) @discardableResult
    func midX(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { FrameLayout(targets: [$0]).x(value - $0.bounds.width / 2) }
        return self
    }

    @objc(maxX:) @discardableResult
    func maxX(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { FrameLayout(targets: [$0]).x(value - $0.bounds.width) }
        return self
    }

    @objc(midY:) @discardableResult
    func midY(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { FrameLayout(targets: [$0]).y(value - $0.bounds.height / 2) }
        return self
    }

    @objc(maxY:) @discardableResult
    func maxY(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { FrameLayout(targets: [$0]).y(value - $0.bounds.height) }
        return self
    }

    /// Puts the right edge `value` points from the parent's right edge.
    @objc(right:) @discardableResult
    func right(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { target in
            guard let parentBounds = target.parentBounds else {
                assertionFailure("right: needs a superview or superlayer")
                return
            }
            FrameLayout(targets: [target]).maxX(parentBounds.width - value)
        }
        return self
    }

    /// Puts the bottom edge `value` points from the parent's bottom edge,
    /// in the parent's own (possibly unflipped) coordinates.
    @objc(bottom:) @discardableResult
    func bottom(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { target in
            guard let parentBounds = target.parentBounds else {
                assertionFailure("bottom: needs a superview or superlayer")
                return
            }
            if target.parentIsFlipped {
                FrameLayout(targets: [target]).maxY(parentBounds.height - value)
            } else {
                FrameLayout(targets: [target]).y(value)
            }
        }
        return self
    }

    @objc @discardableResult
    func horAlign() -> FrameLayout {
        each { target in
            guard let parentBounds = target.parentBounds else {
                assertionFailure("horAlign needs a superview or superlayer")
                return
            }
            FrameLayout(targets: [target]).midX(parentBounds.width / 2)
        }
        return self
    }

    @objc @discardableResult
    func verAlign() -> FrameLayout {
        each { target in
            guard let parentBounds = target.parentBounds else {
                assertionFailure("verAlign needs a superview or superlayer")
                return
            }
            FrameLayout(targets: [target]).midY(parentBounds.height / 2)
        }
        return self
    }

    // MARK: - Filling the parent

    @objc @discardableResult
    func fullWidth() -> FrameLayout {
        x(0).toRight(0)
    }

    @objc @discardableResult
    func fullHeight() -> FrameLayout {
        each { target in
            guard let parentBounds = target.parentBounds else {
                assertionFailure("fullHeight needs a superview or superlayer")
                return
            }
            FrameLayout(targets: [target]).height(parentBounds.height).y(0)
        }
        return self
    }

    @objc @discardableResult
    func fullFrame() -> FrameLayout {
        fullWidth().fullHeight()
    }

    /// Stretches the width so the right edge sits `value` points from the
    /// parent's right edge; never negative.
    @objc(toRight:) @discardableResult
    func toRight(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { target in
            let parentWidth = target.parentBounds?.width ?? 0
            var rect = target.frame
            rect.size.width = max(0, Self.snapToPixel(parentWidth - rect.minX - value))
            target.frame = rect
        }
        return self
    }

    /// Stretches the width so the right edge sits at `value`, never past the
    /// left edge.
    @objc(toMaxX:) @discardableResult
    func toMaxX(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { target in
            var rect = target.frame
            let safeValue = max(value, rect.minX)
            rect.size.width = Self.snapToPixel(safeValue - rect.minX)
            target.frame = rect
        }
        return self
    }

    /// Stretches the height so the bottom edge sits at `value`, never above
    /// the top edge.
    @objc(toMaxY:) @discardableResult
    func toMaxY(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { target in
            var rect = target.frame
            let safeValue = max(value, rect.minY)
            rect.size.height = Self.snapToPixel(safeValue - rect.minY)
            target.frame = rect
        }
        return self
    }

    /// Moves the top edge to `value` keeping the bottom edge in place.
    @objc(toY:) @discardableResult
    func toY(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { target in
            var rect = target.frame
            let safeValue = min(value, rect.maxY)
            rect.size.height = Self.snapToPixel(rect.maxY - safeValue)
            rect.origin.y = Self.snapToPixel(safeValue)
            target.frame = rect
        }
        return self
    }

    /// Stretches the height so the bottom edge sits `value` points from the
    /// parent's bottom edge.
    @objc(toBottom:) @discardableResult
    func toBottom(_ value: CGFloat) -> FrameLayout {
        let value = Self.checked(value)
        each { target in
            guard let parentBounds = target.parentBounds else {
                assertionFailure("toBottom: needs a superview or superlayer")
                return
            }
            if target.parentIsFlipped {
                FrameLayout(targets: [target]).toMaxY(parentBounds.height - value)
            } else {
                FrameLayout(targets: [target]).toY(value)
            }
        }
        return self
    }

    // MARK: - Groups

    /// Keeps only the visible views and layers: not hidden, attached, and at
    /// least 1% opaque.
    @objc @discardableResult
    func visibles() -> FrameLayout {
        targets = targets.filter(\.isVisible)
        return self
    }

    /// Centres the group's union horizontally in the shared parent, moving
    /// every member by the same amount. Does nothing when the members do
    /// not share a parent.
    @objc @discardableResult
    func groupHorAlign() -> FrameLayout {
        guard let first = targets.first, let parent = first.parent else {
            if !targets.isEmpty {
                assertionFailure("groupHorAlign needs a shared superview or superlayer")
            }
            return self
        }
        guard targets.allSatisfy({ $0.parent === parent }) else {
            assertionFailure("groupHorAlign needs a shared superview or superlayer")
            return self
        }
        let parentWidth = first.parentBounds?.width ?? 0
        let minX = targets.map(\.frame.minX).min() ?? 0
        let maxX = targets.map(\.frame.maxX).max() ?? 0
        let groupMidX = minX + (maxX - minX) / 2
        return offset(x: parentWidth / 2 - groupMidX, y: 0)
    }
}

extension NSView {
    /// Frame layout for this view, replacing ShortCocoa's `$(view)`.
    var frameLayout: FrameLayout {
        FrameLayout([self])
    }
}

extension CALayer {
    /// Frame layout for this layer, replacing ShortCocoa's `$(layer)`.
    var frameLayout: FrameLayout {
        FrameLayout([self])
    }
}
