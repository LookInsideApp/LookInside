//
//  NSArray+LookinClient.swift
//  LookInside
//

import AppKit

extension NSArray {
    /// The views that are not hidden. Every element must be an NSView.
    @objc func visibleViews() -> [Any] {
        filter { object in
            guard let view = object as? NSView else {
                assertionFailure("visibleViews expects views only")
                return false
            }
            return !view.isHidden
        }
    }
}
