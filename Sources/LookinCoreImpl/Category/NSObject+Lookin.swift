//
//  NSObject+Lookin.swift
//  LookinCore
//
//  Was NSObject+Lookin.m: the
//  associated-object bindings and the color / image coding that
//  LookinConnectionAttachment uses on the wire (pinned by
//  Tests/WireFormatGolden, LookinConnectionAttachment-color and -image).
//
//  Plain `@objc` extension members with the original selectors: the runtime
//  registers them as a category when the image loads, as it did the
//  Objective-C category. Swift sees them under the names the old header's
//  import gave them.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    import ObjectiveC
    #if SWIFT_PACKAGE
        import LookinCore
    #endif
    #if canImport(UIKit)
        import UIKit
    #elseif os(macOS)
        import AppKit
    #endif

    public extension NSObject {
        // MARK: - Data Bind

        @objc(lookin_bindObject:forKey:)
        func lookin_bindObject(_ object: Any?, forKey key: String?) {
            guard let key, !key.isEmpty else {
                assertionFailure("")
                return
            }
            // @synchronized (self): objc_sync_enter / objc_sync_exit is the
            // same recursive lock.
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            if let object {
                lookinAllBindObjects(self).setObject(object, forKey: key as NSString)
            } else {
                lookinAllBindObjects(self).removeObject(forKey: key as NSString)
            }
        }

        @objc(lookin_bindObjectWeakly:forKey:)
        func lookin_bindObjectWeakly(_ object: Any?, forKey key: String?) {
            guard let key, !key.isEmpty else {
                assertionFailure("")
                return
            }
            if let object {
                let container = LookinWeakContainer()
                container.object = object as AnyObject
                lookin_bindObject(container, forKey: key)
            } else {
                lookin_bindObject(nil, forKey: key)
            }
        }

        @objc(lookin_getBindObjectForKey:)
        func lookin_getBindObject(forKey key: String?) -> Any? {
            guard let key, !key.isEmpty else {
                assertionFailure("")
                return nil
            }
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            let storedObj = lookinAllBindObjects(self).object(forKey: key as NSString)
            if let container = storedObj as? LookinWeakContainer {
                return container.object
            }
            return storedObj
        }

        @objc(lookin_bindDouble:forKey:)
        func lookin_bindDouble(_ doubleValue: Double, forKey key: String?) {
            lookin_bindObject(NSNumber(value: doubleValue), forKey: key)
        }

        @objc(lookin_getBindDoubleForKey:)
        func lookin_getBindDouble(forKey key: String?) -> Double {
            guard let number = lookin_getBindObject(forKey: key) as? NSNumber else {
                return 0.0
            }
            return number.doubleValue
        }

        @objc(lookin_bindBOOL:forKey:)
        func lookin_bindBOOL(_ boolValue: Bool, forKey key: String?) {
            lookin_bindObject(NSNumber(value: boolValue), forKey: key)
        }

        @objc(lookin_getBindBOOLForKey:)
        func lookin_getBindBOOL(forKey key: String?) -> Bool {
            guard let number = lookin_getBindObject(forKey: key) as? NSNumber else {
                return false
            }
            return number.boolValue
        }

        @objc(lookin_bindLong:forKey:)
        func lookin_bindLong(_ longValue: Int, forKey key: String?) {
            lookin_bindObject(NSNumber(value: longValue), forKey: key)
        }

        @objc(lookin_getBindLongForKey:)
        func lookin_getBindLong(forKey key: String?) -> Int {
            guard let number = lookin_getBindObject(forKey: key) as? NSNumber else {
                return 0
            }
            return number.intValue
        }

        @objc(lookin_bindPoint:forKey:)
        func lookin_bindPoint(_ pointValue: CGPoint, forKey key: String?) {
            #if canImport(UIKit)
                lookin_bindObject(NSValue(cgPoint: pointValue), forKey: key)
            #elseif os(macOS)
                lookin_bindObject(NSValue(point: pointValue), forKey: key)
            #endif
        }

        @objc(lookin_getBindPointForKey:)
        func lookin_getBindPoint(forKey key: String?) -> CGPoint {
            guard let value = lookin_getBindObject(forKey: key) as? NSValue else {
                return .zero
            }
            #if canImport(UIKit)
                return value.cgPointValue
            #elseif os(macOS)
                return value.pointValue
            #endif
        }

        @objc(lookin_clearBindForKey:)
        func lookin_clearBind(forKey key: String?) {
            lookin_bindObject(nil, forKey: key)
        }
    }

    public extension NSObject {
        @objc(lookin_encodedObjectWithType:)
        func lookin_encodedObject(with type: LookinCodingValueType) -> Any? {
            switch type {
            case .color:
                guard isKind(of: LookinColor.self) else {
                    assertionFailure("")
                    return nil
                }
                var r: CGFloat = 0
                var g: CGFloat = 0
                var b: CGFloat = 0
                var a: CGFloat = 0
                #if canImport(UIKit)
                    let color = unsafeDowncast(self, to: UIColor.self)
                    var white: CGFloat = 0
                    if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
                        // valid
                    } else if color.getWhite(&white, alpha: &a) {
                        r = white
                        g = white
                        b = white
                    } else {
                        assertionFailure("")
                        r = 0
                        g = 0
                        b = 0
                        a = 0
                    }
                #elseif os(macOS)
                    // Messaging a nil sRGB conversion left the components unset;
                    // read them as 0 here.
                    unsafeDowncast(self, to: NSColor.self).usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
                #endif
                let rgba: NSArray = [
                    NSNumber(value: Double(r)),
                    NSNumber(value: Double(g)),
                    NSNumber(value: Double(b)),
                    NSNumber(value: Double(a)),
                ]
                return rgba

            case .image:
                #if canImport(UIKit)
                    guard isKind(of: UIImage.self) else {
                        assertionFailure("")
                        return nil
                    }
                    return lookinPNGRepresentation(unsafeDowncast(self, to: UIImage.self))
                #elseif os(macOS)
                    guard isKind(of: NSImage.self) else {
                        assertionFailure("")
                        return nil
                    }
                    return unsafeDowncast(self, to: NSImage.self).lookin_data().map { $0 as NSData }
                #endif

            default:
                return self
            }
        }

        @objc(lookin_decodedObjectWithType:)
        func lookin_decodedObject(with type: LookinCodingValueType) -> Any? {
            switch type {
            case .color:
                guard isKind(of: NSArray.self) else {
                    assertionFailure("")
                    return nil
                }
                let rgba = unsafeDowncast(self, to: NSArray.self)
                let r = lookinDoubleValue(rgba.object(at: 0))
                let g = lookinDoubleValue(rgba.object(at: 1))
                let b = lookinDoubleValue(rgba.object(at: 2))
                let a = lookinDoubleValue(rgba.object(at: 3))
                return LookinColor(red: r, green: g, blue: b, alpha: a)

            case .image:
                guard isKind(of: NSData.self) else {
                    assertionFailure("")
                    return nil
                }
                return LookinImage(data: unsafeDowncast(self, to: NSData.self) as Data)

            default:
                return self
            }
        }
    }

    // MARK: - Helpers

    #if canImport(UIKit)
        /// `UIImagePNGRepresentation(image)` itself, looked up at run time: Swift
        /// only offers `pngData()`, whose `Data` bridges back as a different
        /// NSData class than the NSMutableData UIKit returns, and the class name
        /// is archived on the wire (Tests/WireFormatGolden, LookinDisplayItem and
        /// LookinConnectionAttachment-image).
        private let lookinUIImagePNGRepresentation: (@convention(c) (UIImage) -> Unmanaged<NSData>?)? = {
            // RTLD_DEFAULT
            guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "UIImagePNGRepresentation") else {
                return nil
            }
            return unsafeBitCast(symbol, to: (@convention(c) (UIImage) -> Unmanaged<NSData>?).self)
        }()

        private func lookinPNGRepresentation(_ image: UIImage) -> NSData? {
            if let function = lookinUIImagePNGRepresentation {
                return function(image)?.takeUnretainedValue()
            }
            return image.pngData().map { $0 as NSData }
        }
    #endif

    private nonisolated(unsafe) var kAssociatedObjectKey_LookinAllBindObjects: UInt8 = 0

    /// `-lookin_allBindObjects`: the mutable dictionary every binding lives in,
    /// created on first use.
    private func lookinAllBindObjects(_ object: NSObject) -> NSMutableDictionary {
        if let dict = objc_getAssociatedObject(object, &kAssociatedObjectKey_LookinAllBindObjects) as? NSMutableDictionary {
            return dict
        }
        let dict = NSMutableDictionary()
        objc_setAssociatedObject(object, &kAssociatedObjectKey_LookinAllBindObjects, dict, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return dict
    }

    /// `[value doubleValue]` for an archived rgba element. NSNumber and NSString
    /// answer it; any other object gets the same unrecognized-selector
    /// exception the message send raised.
    private func lookinDoubleValue(_ value: Any) -> CGFloat {
        if let number = value as? NSNumber {
            return CGFloat(number.doubleValue)
        }
        if let string = value as? NSString {
            return CGFloat(string.doubleValue)
        }
        let selector = NSSelectorFromString("doubleValue")
        let object = value as AnyObject
        guard object.responds(to: selector) else {
            (object as? NSObject)?.doesNotRecognizeSelector(selector)
            return 0
        }
        var result: Double = 0
        if let returned = LookinInvoke(object, selector, nil, nil) as? NSValue,
           LookinMethodReturnType(object, selector, nil) == LookinEncoding(.double)
        {
            returned.getValue(&result, size: MemoryLayout<Double>.size)
        }
        return CGFloat(result)
    }

#endif
