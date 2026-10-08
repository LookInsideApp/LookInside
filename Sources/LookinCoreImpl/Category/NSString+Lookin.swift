//
//  NSString+Lookin.swift
//  LookinCore
//
//  Was NSString+Lookin.m. The
//  number formatting goes through NSString formats, as before, so the
//  attribute texts the Host shows stay byte-identical.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif
    #if canImport(UIKit)
        import UIKit
    #elseif os(macOS)
        import AppKit
    #endif

    public extension NSString {
        @objc(lookin_stringFromDouble:decimal:)
        class func string(from doubleValue: Double, decimal: UInt) -> String {
            let formatString = NSString(format: "%%.%@f", NSNumber(value: decimal))
            var string = NSString(format: formatString, doubleValue)
            // A zero-length string would raise in -substringFromIndex: in the
            // Objective-C original; "%.Nf" never formats to one.
            for _ in 0 ..< decimal {
                if string.substring(from: string.length - 1) == "0" {
                    string = string.substring(to: string.length - 1) as NSString
                }
            }
            if string.substring(from: string.length - 1) == "." {
                string = string.substring(to: string.length - 1) as NSString
            }
            return string as String
        }

        @available(*, deprecated, renamed: "string(from:decimal:)")
        class func lookin_string(from doubleValue: Double, decimal: UInt) -> String {
            string(from: doubleValue, decimal: decimal)
        }

        @objc(lookin_stringFromRect:)
        class func string(from rect: CGRect) -> String {
            String(format: "{%@, %@, %@, %@}",
                   twoDecimalString(rect.origin.x),
                   twoDecimalString(rect.origin.y),
                   twoDecimalString(rect.size.width),
                   twoDecimalString(rect.size.height))
        }

        @available(*, deprecated, renamed: "string(from:)")
        class func lookin_string(from rect: CGRect) -> String {
            string(from: rect)
        }

        @objc(lookin_stringFromInset:)
        class func string(fromInset insets: PlatformEdgeInsets) -> String {
            String(format: "{%@, %@, %@, %@}",
                   twoDecimalString(insets.top),
                   twoDecimalString(insets.left),
                   twoDecimalString(insets.bottom),
                   twoDecimalString(insets.right))
        }

        @available(*, deprecated, renamed: "string(fromInset:)")
        class func lookin_string(fromInset insets: PlatformEdgeInsets) -> String {
            string(fromInset: insets)
        }

        @objc(lookin_stringFromSize:)
        class func string(from size: CGSize) -> String {
            String(format: "{%@, %@}",
                   twoDecimalString(size.width),
                   twoDecimalString(size.height))
        }

        @available(*, deprecated, renamed: "string(from:)")
        class func lookin_string(from size: CGSize) -> String {
            string(from: size)
        }

        @objc(lookin_stringFromPoint:)
        class func string(from point: CGPoint) -> String {
            String(format: "{%@, %@}",
                   twoDecimalString(point.x),
                   twoDecimalString(point.y))
        }

        @available(*, deprecated, renamed: "string(from:)")
        class func lookin_string(from point: CGPoint) -> String {
            string(from: point)
        }

        @objc(lookin_rgbaStringFromColor:)
        class func rgbaString(from color: PlatformColor?) -> String {
            guard let color else {
                return "nil"
            }
            #if canImport(UIKit)
                let rgbColor: PlatformColor? = color
            #elseif os(macOS)
                let rgbColor = color.usingColorSpace(.sRGB)
            #endif

            // Components the color does not report (a nil sRGB conversion, a
            // pattern color) were left unset in Objective-C; read them as 0.
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            _ = rgbColor?.getRed(&r, green: &g, blue: &b, alpha: &a)

            if a >= 1 {
                return String(format: "(%.0f, %.0f, %.0f)", Double(r * 255), Double(g * 255), Double(b * 255))
            }
            return String(format: "(%.0f, %.0f, %.0f, %@)",
                          Double(r * 255), Double(g * 255), Double(b * 255),
                          NSString.string(from: Double(a), decimal: 2) as NSString)
        }

        @available(*, deprecated, renamed: "rgbaString(from:)")
        class func lookin_rgbaString(from color: PlatformColor?) -> String {
            rgbaString(from: color)
        }

        @objc(lookin_safeInitWithUTF8String:)
        func safeInit(withUTF8String string: UnsafePointer<CChar>?) -> String? {
            // `[[NSString alloc] lookin_safeInitWithUTF8String:]`: the receiver
            // is the class's placeholder; -initWithUTF8String: on a fresh
            // NSString gives the same string, nil for invalid UTF-8.
            guard let string else {
                return nil
            }
            return NSString(utf8String: string) as String?
        }

        @available(*, deprecated, renamed: "safeInit(withUTF8String:)")
        func lookin_safeInit(withUTF8String string: UnsafePointer<CChar>?) -> String? {
            safeInit(withUTF8String: string)
        }

        @objc(lookin_numbericOSVersion)
        func numericOSVersion() -> Int {
            if length == 0 {
                return 0
            }
            let versionArr = components(separatedBy: ".")
            if versionArr.isEmpty {
                return 0
            }

            var numbericOSVersion = 0
            var pos = 0
            let componentCount = min(versionArr.count, 3)

            while pos < componentCount {
                // NSInteger += NSInteger * double: computed in double, then
                // converted back to NSInteger.
                let component = Double((versionArr[pos] as NSString).integerValue)
                numbericOSVersion = integerFromDouble(Double(numbericOSVersion) + component * pow(10, Double(4 - pos * 2)))
                pos += 1
            }

            return numbericOSVersion
        }

        @available(*, deprecated, renamed: "numericOSVersion()")
        func lookin_numbericOSVersion() -> Int {
            numericOSVersion()
        }
    }

    /// The C double-to-NSInteger conversion as arm64 performs it: truncate
    /// toward zero, saturate out-of-range values, NaN becomes 0. Swift's
    /// `Int(_:)` traps instead, and the version strings come from the peer.
    private func integerFromDouble(_ value: Double) -> Int {
        if value.isNaN {
            return 0
        }
        if value >= 9_223_372_036_854_775_807.0 {
            return Int.max
        }
        if value <= -9_223_372_036_854_775_808.0 {
            return Int.min
        }
        return Int(value)
    }

    /// `[NSString lookin_stringFromDouble:value decimal:2]` as an NSString
    /// format argument.
    private func twoDecimalString(_ value: CGFloat) -> NSString {
        NSString.string(from: Double(value), decimal: 2) as NSString
    }

#endif
