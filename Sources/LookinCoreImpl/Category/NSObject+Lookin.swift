//
//  NSObject+Lookin.swift
//  LookinCore
//
//  Was NSObject+Lookin.m: the
//  associated-object bindings and the color / image coding that
//  ConnectionAttachment uses on the wire (pinned by
//  Tests/WireFormatGolden, ConnectionAttachment-color and -image).
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
        func bindObject(_ object: Any?, forKey key: String?) {
            guard let key, !key.isEmpty else {
                assertionFailure("")
                return
            }
            // @synchronized (self): objc_sync_enter / objc_sync_exit is the
            // same recursive lock.
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            if let object {
                allBindObjects(self).setObject(object, forKey: key as NSString)
            } else {
                allBindObjects(self).removeObject(forKey: key as NSString)
            }
        }

        @available(*, deprecated, renamed: "bindObject(_:forKey:)")
        func lookin_bindObject(_ object: Any?, forKey key: String?) {
            bindObject(object, forKey: key)
        }

        @objc(lookin_bindObjectWeakly:forKey:)
        func bindObjectWeakly(_ object: Any?, forKey key: String?) {
            guard let key, !key.isEmpty else {
                assertionFailure("")
                return
            }
            if let object {
                let container = WeakContainer()
                container.object = object as AnyObject
                bindObject(container, forKey: key)
            } else {
                bindObject(nil, forKey: key)
            }
        }

        @available(*, deprecated, renamed: "bindObjectWeakly(_:forKey:)")
        func lookin_bindObjectWeakly(_ object: Any?, forKey key: String?) {
            bindObjectWeakly(object, forKey: key)
        }

        @objc(lookin_getBindObjectForKey:)
        func getBindObject(forKey key: String?) -> Any? {
            guard let key, !key.isEmpty else {
                assertionFailure("")
                return nil
            }
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            let storedObj = allBindObjects(self).object(forKey: key as NSString)
            if let container = storedObj as? WeakContainer {
                return container.object
            }
            return storedObj
        }

        @available(*, deprecated, renamed: "getBindObject(forKey:)")
        func lookin_getBindObject(forKey key: String?) -> Any? {
            getBindObject(forKey: key)
        }

        @objc(lookin_bindDouble:forKey:)
        func bindDouble(_ doubleValue: Double, forKey key: String?) {
            bindObject(NSNumber(value: doubleValue), forKey: key)
        }

        @available(*, deprecated, renamed: "bindDouble(_:forKey:)")
        func lookin_bindDouble(_ doubleValue: Double, forKey key: String?) {
            bindDouble(doubleValue, forKey: key)
        }

        @objc(lookin_getBindDoubleForKey:)
        func getBindDouble(forKey key: String?) -> Double {
            guard let number = getBindObject(forKey: key) as? NSNumber else {
                return 0.0
            }
            return number.doubleValue
        }

        @available(*, deprecated, renamed: "getBindDouble(forKey:)")
        func lookin_getBindDouble(forKey key: String?) -> Double {
            getBindDouble(forKey: key)
        }

        @objc(lookin_bindBOOL:forKey:)
        func bindBool(_ boolValue: Bool, forKey key: String?) {
            bindObject(NSNumber(value: boolValue), forKey: key)
        }

        @available(*, deprecated, renamed: "bindBool(_:forKey:)")
        func lookin_bindBOOL(_ boolValue: Bool, forKey key: String?) {
            bindBool(boolValue, forKey: key)
        }

        @objc(lookin_getBindBOOLForKey:)
        func getBindBool(forKey key: String?) -> Bool {
            guard let number = getBindObject(forKey: key) as? NSNumber else {
                return false
            }
            return number.boolValue
        }

        @available(*, deprecated, renamed: "getBindBool(forKey:)")
        func lookin_getBindBOOL(forKey key: String?) -> Bool {
            getBindBool(forKey: key)
        }

        @objc(lookin_bindLong:forKey:)
        func bindLong(_ longValue: Int, forKey key: String?) {
            bindObject(NSNumber(value: longValue), forKey: key)
        }

        @available(*, deprecated, renamed: "bindLong(_:forKey:)")
        func lookin_bindLong(_ longValue: Int, forKey key: String?) {
            bindLong(longValue, forKey: key)
        }

        @objc(lookin_getBindLongForKey:)
        func getBindLong(forKey key: String?) -> Int {
            guard let number = getBindObject(forKey: key) as? NSNumber else {
                return 0
            }
            return number.intValue
        }

        @available(*, deprecated, renamed: "getBindLong(forKey:)")
        func lookin_getBindLong(forKey key: String?) -> Int {
            getBindLong(forKey: key)
        }

        @objc(lookin_bindPoint:forKey:)
        func bindPoint(_ pointValue: CGPoint, forKey key: String?) {
            #if canImport(UIKit)
                bindObject(NSValue(cgPoint: pointValue), forKey: key)
            #elseif os(macOS)
                bindObject(NSValue(point: pointValue), forKey: key)
            #endif
        }

        @available(*, deprecated, renamed: "bindPoint(_:forKey:)")
        func lookin_bindPoint(_ pointValue: CGPoint, forKey key: String?) {
            bindPoint(pointValue, forKey: key)
        }

        @objc(lookin_getBindPointForKey:)
        func getBindPoint(forKey key: String?) -> CGPoint {
            guard let value = getBindObject(forKey: key) as? NSValue else {
                return .zero
            }
            #if canImport(UIKit)
                return value.cgPointValue
            #elseif os(macOS)
                return value.pointValue
            #endif
        }

        @available(*, deprecated, renamed: "getBindPoint(forKey:)")
        func lookin_getBindPoint(forKey key: String?) -> CGPoint {
            getBindPoint(forKey: key)
        }

        @objc(lookin_clearBindForKey:)
        func clearBind(forKey key: String?) {
            bindObject(nil, forKey: key)
        }

        @available(*, deprecated, renamed: "clearBind(forKey:)")
        func lookin_clearBind(forKey key: String?) {
            clearBind(forKey: key)
        }
    }

    public extension NSObject {
        @objc(lookin_encodedObjectWithType:)
        func encodedObject(with type: LookinCodingValueType) -> Any? {
            switch type {
            case .color:
                guard isKind(of: PlatformColor.self) else {
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
                    return pngRepresentation(unsafeDowncast(self, to: UIImage.self))
                #elseif os(macOS)
                    guard isKind(of: NSImage.self) else {
                        assertionFailure("")
                        return nil
                    }
                    return unsafeDowncast(self, to: NSImage.self).encodedData().map { $0 as NSData }
                #endif

            default:
                return self
            }
        }

        @available(*, deprecated, renamed: "encodedObject(with:)")
        func lookin_encodedObject(with type: LookinCodingValueType) -> Any? {
            encodedObject(with: type)
        }

        @objc(lookin_decodedObjectWithType:)
        func decodedObject(with type: LookinCodingValueType) -> Any? {
            switch type {
            case .color:
                guard isKind(of: NSArray.self) else {
                    assertionFailure("")
                    return nil
                }
                let rgba = unsafeDowncast(self, to: NSArray.self)
                let r = cgFloatValue(rgba.object(at: 0))
                let g = cgFloatValue(rgba.object(at: 1))
                let b = cgFloatValue(rgba.object(at: 2))
                let a = cgFloatValue(rgba.object(at: 3))
                return PlatformColor(red: r, green: g, blue: b, alpha: a)

            case .image:
                guard isKind(of: NSData.self) else {
                    assertionFailure("")
                    return nil
                }
                return PlatformImage(data: unsafeDowncast(self, to: NSData.self) as Data)

            default:
                return self
            }
        }

        @available(*, deprecated, renamed: "decodedObject(with:)")
        func lookin_decodedObject(with type: LookinCodingValueType) -> Any? {
            decodedObject(with: type)
        }
    }

    // MARK: - Helpers

    #if canImport(UIKit)
        /// `UIImagePNGRepresentation(image)` itself, looked up at run time: Swift
        /// only offers `pngData()`, whose `Data` bridges back as a different
        /// NSData class than the NSMutableData UIKit returns, and the class name
        /// is archived on the wire (Tests/WireFormatGolden, DisplayItem and
        /// ConnectionAttachment-image).
        private let uiImagePNGRepresentation: (@convention(c) (UIImage) -> Unmanaged<NSData>?)? = {
            // RTLD_DEFAULT
            guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "UIImagePNGRepresentation") else {
                return nil
            }
            return unsafeBitCast(symbol, to: (@convention(c) (UIImage) -> Unmanaged<NSData>?).self)
        }()

        private func pngRepresentation(_ image: UIImage) -> NSData? {
            if let function = uiImagePNGRepresentation {
                return function(image)?.takeUnretainedValue()
            }
            return image.pngData().map { $0 as NSData }
        }
    #endif

    private nonisolated(unsafe) var kAssociatedObjectKey_LookinAllBindObjects: UInt8 = 0

    /// `-lookin_allBindObjects`: the mutable dictionary every binding lives in,
    /// created on first use.
    private func allBindObjects(_ object: NSObject) -> NSMutableDictionary {
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
    private func cgFloatValue(_ value: Any) -> CGFloat {
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
