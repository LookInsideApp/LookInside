//
//  NSValue+Lookin.swift
//  LookinCore
//
//  Was NSValue+Lookin.m: the
//  UIKit-style NSValue boxing on AppKit, the insets boxing on both, and the
//  exported NSStringFrom* C functions (defined here with @_cdecl).
//
//  CGVector and CGAffineTransform values are still built from raw bytes with
//  their @encode type; such values cannot be keyed-archived, the known wire
//  limitation recorded in PLAN 阶段 0. Keep it unchanged.
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

    // MARK: - C functions

    /// The `%.*g` precision the Objective-C original passed (an `int`).
    private let precision17: Int32 = 17

    #if os(macOS)
        @_cdecl("NSStringFromInsets")
        public func lookin_NSStringFromInsets(_ insets: NSEdgeInsets) -> NSString {
            NSString(format: "{%.*g, %.*g, %.*g, %.*g}", precision17, insets.top, precision17, insets.left, precision17, insets.bottom, precision17, insets.right)
        }

        @_cdecl("NSStringFromCGAffineTransform")
        public func lookin_NSStringFromCGAffineTransform(_ transform: CGAffineTransform) -> NSString {
            NSString(format: "[%.*g, %.*g, %.*g, %.*g, %.*g, %.*g]",
                     precision17, transform.a, precision17, transform.b, precision17, transform.c,
                     precision17, transform.d, precision17, transform.tx, precision17, transform.ty)
        }

        @_cdecl("NSStringFromCGVector")
        public func lookin_NSStringFromCGVector(_ vector: CGVector) -> NSString {
            NSString(format: "{%.*g, %.*g}", precision17, vector.dx, precision17, vector.dy)
        }

        @_cdecl("NSStringFromCGRect")
        public func lookin_NSStringFromCGRect(_ rect: CGRect) -> NSString {
            NSStringFromRect(rect) as NSString
        }

        @_cdecl("NSStringFromCGPoint")
        public func lookin_NSStringFromCGPoint(_ point: CGPoint) -> NSString {
            NSStringFromPoint(point) as NSString
        }

        @_cdecl("NSStringFromCGSize")
        public func lookin_NSStringFromCGSize(_ size: CGSize) -> NSString {
            NSStringFromSize(size) as NSString
        }

        @_cdecl("NSStringFromDirectionalEdgeInsets")
        public func lookin_NSStringFromDirectionalEdgeInsets(_ insets: NSDirectionalEdgeInsets) -> NSString {
            NSString(format: "{%.*g, %.*g, %.*g, %.*g}", precision17, insets.top, precision17, insets.leading, precision17, insets.bottom, precision17, insets.trailing)
        }
    #else
        @_cdecl("NSStringFromInsets")
        public func lookin_NSStringFromInsets(_ insets: UIEdgeInsets) -> NSString {
            NSString(format: "{%.*g, %.*g, %.*g, %.*g}", precision17, insets.top, precision17, insets.left, precision17, insets.bottom, precision17, insets.right)
        }
    #endif

    // MARK: - NSValue (Lookin)

    public extension NSValue {
        #if os(macOS)
            @objc(valueWithCGVector:)
            class func lookin_value(cgVector vector: CGVector) -> NSValue {
                var vector = vector
                return NSValue(bytes: &vector, objCType: LookinEncoding(.cgVector))
            }

            @objc(valueWithCGRect:)
            class func lookin_value(cgRect rect: CGRect) -> NSValue {
                NSValue(rect: rect)
            }

            @objc(valueWithCGPoint:)
            class func lookin_value(cgPoint point: CGPoint) -> NSValue {
                NSValue(point: point)
            }

            @objc(valueWithCGSize:)
            class func lookin_value(cgSize size: CGSize) -> NSValue {
                NSValue(size: size)
            }

            @objc(valueWithCGAffineTransform:)
            class func lookin_value(cgAffineTransform transform: CGAffineTransform) -> NSValue {
                var transform = transform
                return NSValue(bytes: &transform, objCType: LookinEncoding(.cgAffineTransform))
            }

            @objc(CGAffineTransformValue)
            func cgAffineTransform() -> CGAffineTransform {
                var transform = CGAffineTransform()
                getValue(&transform)
                return transform
            }

            @objc(CGVectorValue)
            func cgVectorValue() -> CGVector {
                var vector = CGVector()
                getValue(&vector)
                return vector
            }

            @objc(CGRectValue)
            func cgRectValue() -> CGRect {
                rectValue
            }

            @objc(CGPointValue)
            func cgPointValue() -> CGPoint {
                pointValue
            }

            @objc(CGSizeValue)
            func cgSizeValue() -> CGSize {
                sizeValue
            }

            @objc(valueWithInsets:)
            class func lookin_value(insets: NSEdgeInsets) -> NSValue {
                NSValue(edgeInsets: insets)
            }

            @objc(InsetsValue)
            func insetsValue() -> NSEdgeInsets {
                edgeInsetsValue
            }
        #else
            @objc(valueWithInsets:)
            class func lookin_value(insets: UIEdgeInsets) -> NSValue {
                NSValue(uiEdgeInsets: insets)
            }

            @objc(InsetsValue)
            func insetsValue() -> UIEdgeInsets {
                uiEdgeInsetsValue
            }
        #endif
    }

#endif
