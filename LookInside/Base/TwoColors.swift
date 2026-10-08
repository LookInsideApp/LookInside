//
//  TwoColors.swift
//  LookInside
//

import AppKit

/// A colour pair resolved against the app's current appearance.
final class TwoColors: NSObject {
    @objc var colorInLightMode: NSColor?
    @objc var colorInDarkMode: NSColor?

    @objc(colorsWithColorInLightMode:colorInDarkMode:)
    static func colors(inLightMode colorInLightMode: NSColor?, inDarkMode colorInDarkMode: NSColor?) -> TwoColors {
        let colors = TwoColors()
        colors.colorInLightMode = colorInLightMode
        colors.colorInDarkMode = colorInDarkMode
        return colors
    }

    /// The Swift spelling of +colorsWithColorInLightMode:colorInDarkMode:,
    /// as Swift imported the Objective-C factory.
    convenience init(colorInLightMode: NSColor?, colorInDarkMode: NSColor?) {
        self.init()
        self.colorInLightMode = colorInLightMode
        self.colorInDarkMode = colorInDarkMode
    }

    /// The dark colour while the app's effective appearance is dark, the
    /// light one otherwise.
    @objc var color: NSColor? {
        let isDarkMode = NSApp?.effectiveAppearance.isDarkMode ?? false
        return isDarkMode ? colorInDarkMode : colorInLightMode
    }
}
