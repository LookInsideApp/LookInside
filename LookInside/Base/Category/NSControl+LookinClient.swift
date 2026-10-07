//
//  NSControl+LookinClient.swift
//  LookInside
//

import AppKit

extension NSControl {
    private static let lk_unlimitedSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)

    @objc(heightForWidth:)
    func height(forWidth width: CGFloat) -> CGFloat {
        sizeThatFits(NSSize(width: width, height: .greatestFiniteMagnitude)).height
    }

    @objc func bestHeight() -> CGFloat {
        sizeThatFits(Self.lk_unlimitedSize).height
    }

    @objc func bestWidth() -> CGFloat {
        sizeThatFits(Self.lk_unlimitedSize).width
    }

    @objc func bestSize() -> NSSize {
        sizeThatFits(Self.lk_unlimitedSize)
    }
}
