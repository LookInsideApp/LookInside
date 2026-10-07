//
//  NSView+LookinClient.swift
//  LookInside
//

import AppKit

private var lk_backgroundColorNameKey: UInt8 = 0

extension NSView {
    /// Not hidden and not fully transparent.
    @objc var isVisible: Bool {
        !isHidden && alphaValue > 0
    }

    /// An asset catalog colour name painted onto the layer's background; nil
    /// clears it.
    @objc var backgroundColorName: String? {
        get {
            objc_getAssociatedObject(self, &lk_backgroundColorNameKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &lk_backgroundColorNameKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            if let newValue {
                layer?.backgroundColor = NSColor(named: newValue)?.cgColor
            } else {
                layer?.backgroundColor = nil
            }
        }
    }

    /// Adds `view` below every existing subview.
    @objc(lk_insertSubviewAtBottom:)
    func lk_insertSubviewAtBottom(_ view: NSView) {
        if let first = subviews.first {
            addSubview(view, positioned: .below, relativeTo: first)
        } else {
            addSubview(view)
        }
    }

    @objc func showDebugBorder() {
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.cgColor
    }
}
