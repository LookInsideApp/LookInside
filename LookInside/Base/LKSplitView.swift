//
//  LKSplitView.swift
//  LookInside
//

import AppKit

/// A split view without visible dividers that reports its first layout.
@objc(LKSplitView)
class LKSplitView: NSSplitView {
    /// Called once, after the first `layout`.
    @objc var didFinishFirstLayout: ((LKSplitView) -> Void)?

    private var hasLaidOut = false

    override var dividerThickness: CGFloat {
        0
    }

    override func layout() {
        super.layout()
        if !hasLaidOut {
            didFinishFirstLayout?(self)
            hasLaidOut = true
        }
    }
}
