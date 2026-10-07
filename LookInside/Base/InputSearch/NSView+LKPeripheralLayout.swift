//
//  NSView+LKPeripheralLayout.swift
//  LookInside
//
//  Frame helpers for the Swift peripheral modules (About, Console, Export,
//  Measure, Preference, InputSearch). They keep the arithmetic of the
//  ShortCocoa calls they replace: setters snap to the main screen's pixel
//  grid, `lkpSizeToFit` / `lkpHeightToFit` only size LKBaseView and NSControl
//  instances, and edges are measured against the superview's bounds.
//

import AppKit

/// Rounds up to the main screen's pixel grid, like ShortCocoa's `CGFloatSnapToPixel`.
func lkpSnapToPixel(_ value: CGFloat) -> CGFloat {
    if value == .leastNormalMagnitude || value == .greatestFiniteMagnitude {
        return value
    }
    let scale = NSScreen.main?.backingScaleFactor ?? 1
    return (value * scale).rounded(.up) / scale
}

/// `NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)`.
let lkpMaxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

extension NSView {
    var lkpSuperSize: NSSize {
        superview?.bounds.size ?? .zero
    }

    /// ShortCocoa's `visibles` test: in a superview, not hidden, not transparent.
    var lkpIsShown: Bool {
        superview != nil && !isHidden && alphaValue >= 0.01
    }

    func lkpSetX(_ value: CGFloat) {
        frame.origin.x = lkpSnapToPixel(value)
    }

    func lkpSetY(_ value: CGFloat) {
        frame.origin.y = lkpSnapToPixel(value)
    }

    func lkpSetWidth(_ value: CGFloat) {
        frame.size.width = lkpSnapToPixel(value)
    }

    func lkpSetHeight(_ value: CGFloat) {
        frame.size.height = lkpSnapToPixel(value)
    }

    func lkpSetSize(_ size: NSSize) {
        lkpSetWidth(size.width)
        lkpSetHeight(size.height)
    }

    func lkpSetMidX(_ value: CGFloat) {
        lkpSetX(value - bounds.width / 2)
    }

    func lkpSetMidY(_ value: CGFloat) {
        lkpSetY(value - bounds.height / 2)
    }

    func lkpSetMaxX(_ value: CGFloat) {
        lkpSetX(value - bounds.width)
    }

    func lkpSetMaxY(_ value: CGFloat) {
        lkpSetY(value - bounds.height)
    }

    func lkpOffsetY(_ delta: CGFloat) {
        frame.origin.y = lkpSnapToPixel(frame.minY + delta)
    }

    /// Stretches the width so the right edge sits `inset` from the superview's right edge.
    func lkpToRight(_ inset: CGFloat) {
        let width = lkpSnapToPixel(lkpSuperSize.width - frame.minX - inset)
        frame.size.width = max(width, 0)
    }

    /// Places the right edge `inset` from the superview's right edge.
    func lkpRight(_ inset: CGFloat) {
        lkpSetMaxX(lkpSuperSize.width - inset)
    }

    /// Places the view `inset` from the superview's bottom edge.
    func lkpBottom(_ inset: CGFloat) {
        guard let superview else { return }
        if superview.isFlipped {
            lkpSetMaxY(superview.bounds.height - inset)
        } else {
            lkpSetY(inset)
        }
    }

    func lkpHorAlign() {
        lkpSetMidX(lkpSuperSize.width / 2)
    }

    func lkpVerAlign() {
        lkpSetMidY(lkpSuperSize.height / 2)
    }

    func lkpCenterAlign() {
        lkpHorAlign()
        lkpVerAlign()
    }

    func lkpFullWidth() {
        lkpSetX(0)
        lkpToRight(0)
    }

    func lkpFullHeight() {
        lkpSetHeight(lkpSuperSize.height)
        lkpSetY(0)
    }

    func lkpFullFrame() {
        lkpFullWidth()
        lkpFullHeight()
    }

    func lkpMaxWidth(_ value: CGFloat) {
        if frame.width > value {
            frame.size.width = value
        }
    }

    /// Sizes LKBaseView and NSControl instances to their fitting size; other views stay as they are.
    func lkpSizeToFit() {
        if let view = self as? LKBaseView {
            view.setFrameSize(view.sizeThatFits(lkpMaxSize))
        } else if let control = self as? NSControl {
            var size = control.sizeThatFits(lkpMaxSize)
            if size.width.isNaN {
                size.width = 0
            }
            if size.height.isNaN {
                size.height = 0
            }
            control.setFrameSize(size)
        }
    }

    /// Sets the fitting height for the current width (LKBaseView and NSControl only).
    func lkpHeightToFit() {
        let limit = NSSize(width: bounds.width, height: .greatestFiniteMagnitude)
        if let view = self as? LKBaseView {
            frame.size.height = view.sizeThatFits(limit).height
        } else if let control = self as? NSControl {
            frame.size.height = control.sizeThatFits(limit).height
        }
    }

    /// Sets the fitting width for the current height (NSControl only).
    func lkpWidthToFit() {
        guard let control = self as? NSControl else { return }
        let width = control.sizeThatFits(NSSize(width: .greatestFiniteMagnitude, height: bounds.height)).width
        lkpSetWidth(width)
    }
}

extension CALayer {
    func lkpSetFrame(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil) {
        var rect = frame
        if let width {
            rect.size.width = lkpSnapToPixel(width)
        }
        if let height {
            rect.size.height = lkpSnapToPixel(height)
        }
        if let x {
            rect.origin.x = lkpSnapToPixel(x)
        }
        if let y {
            rect.origin.y = lkpSnapToPixel(y)
        }
        frame = rect
    }

    /// Stretches the width so the right edge sits `inset` from the superlayer's right edge.
    func lkpToRight(_ inset: CGFloat) {
        let superWidth = superlayer?.bounds.width ?? 0
        var rect = frame
        rect.size.width = max(lkpSnapToPixel(superWidth - rect.minX - inset), 0)
        frame = rect
    }

    func lkpFullWidth() {
        lkpSetFrame(x: 0)
        lkpToRight(0)
    }
}
