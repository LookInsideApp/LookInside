//
//  Color+Lookin.swift
//  LookinCore
//
//  Was Color+Lookin.m. The category
//  only exists on AppKit.
//

#if SHOULD_COMPILE_LOOKIN_SERVER && os(macOS)

    import AppKit
    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    public extension NSColor {
        @objc(lookin_colorFromRGBAComponents:)
        class func lookin_color(fromRGBAComponents components: [NSNumber]?) -> Self! {
            guard let components else {
                return nil
            }
            guard components.count == 4 else {
                assertionFailure("")
                return nil
            }
            let color = NSColor(
                red: components[0].doubleValue,
                green: components[1].doubleValue,
                blue: components[2].doubleValue,
                alpha: components[3].doubleValue
            )
            // The original returned a plain NSColor whatever class received the
            // message, which `instancetype` allows in Objective-C.
            return unsafeDowncast(color, to: self)
        }

        @objc(lookin_rgbaComponents)
        func lookin_rgbaComponents() -> [NSNumber]! {
            // Messaging a nil sRGB conversion left the components unset; read
            // them as 0 here.
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
            return [
                NSNumber(value: Double(r)),
                NSNumber(value: Double(g)),
                NSNumber(value: Double(b)),
                NSNumber(value: Double(a)),
            ]
        }
    }

#endif
