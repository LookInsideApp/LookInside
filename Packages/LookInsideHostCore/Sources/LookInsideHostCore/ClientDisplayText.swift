// The text decisions behind the Host's client-side extensions on LookinCore
// model classes (LookinDisplayItem, LookinObject, LookinAutoLayoutConstraint)
// and on NSColor / NSString: how a class name, a constraint or a colour is
// written in the inspector, and how SwiftUI identifiers are read back out of
// attribute strings. The app-side extensions only gather the model values
// and call these, so the rules are covered here without building the app.

import Foundation

public enum ClientDisplayText {}

// MARK: - Class names

public extension ClientDisplayText {
    /// Drops the module prefix from a demangled class name
    /// ("AppKit._NSCoreHostingView<AppKit.ThemeWidgetView>" becomes
    /// "_NSCoreHostingView<AppKit.ThemeWidgetView>"). Only dots before the
    /// first '<' count, so generic arguments keep their own prefixes.
    static func removingModulePrefix(_ name: String) -> String {
        let ns = name as NSString
        let angleBracket = ns.range(of: "<").location
        let prefixPortion = angleBracket != NSNotFound ? ns.substring(to: angleBracket) : name
        let lastDot = (prefixPortion as NSString).range(of: ".", options: .backwards).location
        if lastDot != NSNotFound {
            return ns.substring(from: lastDot + 1)
        }
        return name
    }

    /// Whether a class chain entry names the type itself once its module
    /// prefix is gone ("SwiftUI.HostingView" matches "HostingView").
    static func classChainEntry(_ entry: String, matches className: String) -> Bool {
        entry.components(separatedBy: ".").last == className
    }

    private static let swiftUISupportMarkers = [
        "SwiftUI",
        "HostingView",
        "UIHosting",
        "NSHosting",
        "ViewRendererHost",
        "PlatformViewHost",
        "_UIHosting",
        "_NSHosting",
    ]

    /// Whether a class name (or a row title / subtitle) belongs to SwiftUI's
    /// hosting machinery.
    static func looksLikeSwiftUISupport(_ className: String?) -> Bool {
        guard let className, !className.isEmpty else { return false }
        return swiftUISupportMarkers.contains { className.contains($0) }
    }
}

// MARK: - SwiftUI identifiers in attribute strings

public extension ClientDisplayText {
    /// Every token of `string` that reads as a SwiftUI display-list ID: a
    /// decimal or 0x-prefixed hex number in 1..<UInt32.max, in order and
    /// without repeats. Tokens are split on anything that is not a letter or
    /// digit.
    static func swiftUIDisplayListIDs(in string: String) -> [UInt64] {
        guard !string.isEmpty else { return [] }
        var result: [UInt64] = []
        let separators = CharacterSet.alphanumerics.inverted
        for rawToken in string.components(separatedBy: separators) where !rawToken.isEmpty {
            let token = rawToken.lowercased()
            var value: UInt64 = 0
            if token.hasPrefix("0x") {
                let scanner = Scanner(string: String(token.dropFirst(2)))
                guard scanner.scanHexInt64(&value), scanner.isAtEnd else { continue }
            } else {
                let scanner = Scanner(string: token)
                guard scanner.scanUnsignedLongLong(&value), scanner.isAtEnd else { continue }
            }
            if value == 0 || value >= UInt64(UInt32.max) {
                continue
            }
            if !result.contains(value) {
                result.append(value)
            }
        }
        return result
    }

    /// The first "0x…" hex address in an object description, lowercased
    /// ("<CALayer: 0x6000AB>" gives "0x6000ab"), or nil when there is none.
    static func memoryAddress(inObjectDescription description: String) -> String? {
        let ns = description as NSString
        guard ns.length > 0 else { return nil }
        let prefixRange = ns.range(of: "0x", options: .caseInsensitive)
        guard prefixRange.location != NSNotFound else { return nil }
        let start = prefixRange.location
        var index = NSMaxRange(prefixRange)
        let hexDigits = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        while index < ns.length {
            guard let scalar = Unicode.Scalar(ns.character(at: index)), hexDigits.contains(scalar) else { break }
            index += 1
        }
        guard index > NSMaxRange(prefixRange) else { return nil }
        return ns.substring(with: NSRange(location: start, length: index - start)).lowercased()
    }
}

// MARK: - Auto Layout constraints

public extension ClientDisplayText {
    /// The name of an iOS `NSLayoutAttribute` raw value. iOS and macOS give
    /// the same attributes different values; constraints are described with
    /// the iOS numbering, and 32...37 are the autoresizing-mask attributes
    /// Xcode's view debugger shows. Unknown values return nil.
    static func layoutAttributeName(_ attribute: Int) -> String? {
        switch attribute {
        // Some apps really do have these; Reveal and Xcode show the same.
        case 0: "notAnAttribute"
        case 1: "left"
        case 2: "right"
        case 3: "top"
        case 4: "bottom"
        case 5: "leading"
        case 6: "trailing"
        case 7: "width"
        case 8: "height"
        case 9: "centerX"
        case 10: "centerY"
        case 11: "lastBaseline"
        case 12: "firstBaseline"
        case 13: "leftMargin"
        case 14: "rightMargin"
        case 15: "topMargin"
        case 16: "bottomMargin"
        case 17: "leadingMargin"
        case 18: "trailingMargin"
        case 19: "centerXWithinMargins"
        case 20: "centerYWithinMargins"
        case 32: "minX"
        case 33: "minY"
        case 34: "midX"
        case 35: "midY"
        case 36: "maxX"
        case 37: "maxY"
        default: nil
        }
    }

    /// "<=", "=" or ">=" for an `NSLayoutRelation` raw value, nil otherwise.
    static func layoutRelationSymbol(_ relation: Int) -> String? {
        switch relation {
        case -1: "<="
        case 0: "="
        case 1: ">="
        default: nil
        }
    }

    /// The spelled-out name of an `NSLayoutRelation` raw value, nil otherwise.
    static func layoutRelationName(_ relation: Int) -> String? {
        switch relation {
        case -1: "LessThanOrEqual"
        case 0: "Equal"
        case 1: "GreaterThanOrEqual"
        default: nil
        }
    }
}

// MARK: - Colours

public extension ClientDisplayText {
    /// "(15, 17, 19)" when opaque, "(15, 17, 19, 0.50)" otherwise, from sRGB
    /// components in 0...1.
    static func rgbaString(red: Double, green: Double, blue: Double, alpha: Double) -> String {
        if alpha >= 1 {
            return String(format: "(%.0f, %.0f, %.0f)", red * 255, green * 255, blue * 255)
        }
        return String(format: "(%.0f, %.0f, %.0f, %.2f)", red * 255, green * 255, blue * 255, alpha)
    }

    /// "#0f1113" when opaque, "#0f111380" otherwise, from sRGB components in
    /// 0...1. Each channel is truncated, not rounded, to 0...255.
    static func hexString(red: Double, green: Double, blue: Double, alpha: Double) -> String {
        func channel(_ value: Double) -> String {
            let hex = hexDigits(value.isFinite ? Int(value * 255) : 0)
            return hex.count < 2 ? "0" + hex : hex
        }
        if alpha >= 1 {
            return "#" + channel(red) + channel(green) + channel(blue)
        }
        return "#" + channel(red) + channel(green) + channel(blue) + channel(alpha)
    }

    /// Base-16 digits built one remainder at a time, as the original
    /// formatter did, so out-of-gamut (negative) channels keep its spelling.
    private static func hexDigits(_ integer: Int) -> String {
        var integer = integer
        var result = ""
        for _ in 0 ..< 9 {
            let remainder = integer % 16
            integer /= 16
            let letter = remainder >= 10 ? String(UnicodeScalar(UInt8(87 + remainder))) : String(remainder)
            result = letter + result
            if integer == 0 {
                break
            }
        }
        return result
    }
}

// MARK: - Preview screenshots

public extension ClientDisplayText {
    /// Whether an expanded node should show its group screenshot in the
    /// preview instead of its solo one: the solo screenshot is missing, or it
    /// is nearly empty (under 2% visible pixels) while the group screenshot
    /// clearly draws something (over 5%, and over four times the solo share).
    /// Ratios are nil when the screenshot itself is missing.
    static func prefersGroupScreenshot(soloVisibleRatio: () -> Double?, groupVisibleRatio: () -> Double?, hasGroupScreenshot: Bool) -> Bool {
        guard hasGroupScreenshot else { return false }
        guard let solo = soloVisibleRatio() else { return true }
        if solo >= 0.02 {
            return false
        }
        let group = groupVisibleRatio() ?? 0
        return group > max(0.05, solo * 4.0)
    }

    /// The share of pixels with alpha above 12 in a premultiplied RGBA
    /// buffer (4 bytes per pixel).
    static func visiblePixelRatio(rgbaPixels: [UInt8]) -> Double {
        let pixelCount = rgbaPixels.count / 4
        guard pixelCount > 0 else { return 0 }
        var visible = 0
        for index in 0 ..< pixelCount where rgbaPixels[index * 4 + 3] > 12 {
            visible += 1
        }
        return Double(visible) / Double(pixelCount)
    }
}
