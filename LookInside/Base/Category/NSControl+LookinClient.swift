//
//  NSControl+LookinClient.swift
//  LookInside
//

import AppKit

extension NSControl {
    private static let unlimitedSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)

    @objc(heightForWidth:)
    func height(forWidth width: CGFloat) -> CGFloat {
        sizeThatFits(NSSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    @objc func bestHeight() -> CGFloat {
        sizeThatFits(Self.unlimitedSize).height
    }

    @objc func bestWidth() -> CGFloat {
        sizeThatFits(Self.unlimitedSize).width
    }

    @objc func bestSize() -> NSSize {
        sizeThatFits(Self.unlimitedSize)
    }
}
