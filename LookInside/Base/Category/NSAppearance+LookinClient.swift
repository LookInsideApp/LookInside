//
//  NSAppearance+LookinClient.swift
//  LookInside
//

import AppKit

extension NSAppearance {
    /// Whether this is one of the dark appearances, including the vibrant
    /// and high-contrast variants.
    @objc var lk_isDarkMode: Bool {
        [.darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark].contains(name)
    }
}
