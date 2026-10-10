//
//  StaticLayout.swift
//  LookInside
//
//  The few frame operations the inspector window's controllers used from
//  ShortCocoa's `$(view)` layout chain, with the same rounding: every
//  value set is rounded up to the main screen's pixel grid.
//

import AppKit

@MainActor
struct StaticLayout {
    let view: NSView

    init(_ view: NSView) {
        self.view = view
    }

    /// Rounds up to the main screen's pixel grid; the extreme values used as
    /// markers are left alone.
    static func snapToPixel(_ value: CGFloat) -> CGFloat {
        if value == .leastNormalMagnitude || value == .greatestFiniteMagnitude {
            return value
        }
        let scale = NSScreen.main?.backingScaleFactor ?? 1
        return (value * scale).rounded(.up) / scale
    }

    private func update(_ change: (inout CGRect) -> Void) {
        var frame = view.frame
        change(&frame)
        view.frame = frame
    }

    func x(_ value: CGFloat) {
        update { $0.origin.x = Self.snapToPixel(value) }
    }

    func y(_ value: CGFloat) {
        update { $0.origin.y = Self.snapToPixel(value) }
    }

    func width(_ value: CGFloat) {
        update { $0.size.width = Self.snapToPixel(value) }
    }

    func height(_ value: CGFloat) {
        update { $0.size.height = Self.snapToPixel(value) }
    }

    /// Places the view `value` from its superview's right edge.
    func right(_ value: CGFloat) {
        guard let superview = view.superview else {
            assertionFailure("needs a superview")
            return
        }
        x(superview.bounds.width - value - view.bounds.width)
    }

    func midX(_ value: CGFloat) {
        x(value - view.bounds.width / 2)
    }

    /// Spans the superview's width.
    func fullWidth() {
        x(0)
        let superWidth = view.superview?.bounds.width ?? 0
        update { $0.size.width = max(Self.snapToPixel(superWidth - $0.minX), 0) }
    }

    /// Spans the superview's height.
    func fullHeight() {
        guard let superview = view.superview else {
            assertionFailure("needs a superview")
            return
        }
        height(superview.bounds.height)
        y(0)
    }

    func fullFrame() {
        fullWidth()
        fullHeight()
    }

    /// Sizes an BaseView to what it needs with no limit.
    func sizeToFit() {
        guard let baseView = view as? BaseView else { return }
        let size = baseView.sizeThatFits(NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        update { $0.size = size }
    }
}
