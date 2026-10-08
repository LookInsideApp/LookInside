//
//  NSColor+LookinClient.swift
//  LookInside
//

import AppKit
import LookInsideHostCore

extension NSColor {
    /// sRGB components in 0...1; zeros when the colour has no sRGB form.
    private var sRGBComponentValues: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }

    /// "(15, 17, 19)" when opaque, "(15, 17, 19, 0.50)" otherwise.
    @objc func rgbaString() -> String {
        let rgba = sRGBComponentValues
        return ClientDisplayText.rgbaString(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha)
    }

    /// "#0f1113" when opaque, "#0f111380" otherwise.
    @objc func hexString() -> String {
        let rgba = sRGBComponentValues
        return ClientDisplayText.hexString(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha)
    }
}

extension NSColor {
    /// `LookinColorMake` / `LookinColorRGBAMake` for Swift: 0...255
    /// channels and a 0...1 alpha.
    static func rgb255(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
        NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }
}
