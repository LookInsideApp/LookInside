//
//  NSControl+LookinClient.swift
//  LookInside
//

import AppKit

extension NSControl {
    private static let unlimitedSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)

    func height(forWidth width: CGFloat) -> CGFloat {
        sizeThatFits(NSSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    func bestHeight() -> CGFloat {
        sizeThatFits(Self.unlimitedSize).height
    }

    func bestWidth() -> CGFloat {
        sizeThatFits(Self.unlimitedSize).width
    }

    func bestSize() -> NSSize {
        sizeThatFits(Self.unlimitedSize)
    }
}
