//
//  LookinCoreModelSupport.swift
//  LookinCore
//
//  Objective-C semantics the Swift implementations of the LookinCore model
//  classes rely on.
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

    // MARK: Strings

    // The originals compared and hashed NSString values through NSString
    // (literal comparison, -[NSString hash]) and leaned on nil messaging
    // (`[nil isEqualToString:]` is NO, `[nil hash]` is 0). Swift's String
    // equality and hashing differ (canonical equivalence, per-process seeds),
    // so these go through NSString explicitly.

    /// `[lhs isEqualToString:rhs]`: NO when either side is nil.
    func stringsEqual(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs, let rhs else {
            return false
        }
        return (lhs as NSString).isEqual(to: rhs)
    }

    /// `string.hash`: -[NSString hash], or 0 for nil.
    func stringHash(_ string: String?) -> Int {
        guard let string else {
            return 0
        }
        return (string as NSString).hash
    }

    // MARK: Image data

    // The encoders archive image data as the very NSData object the
    // Objective-C API returned. UIImagePNGRepresentation answers an
    // NSMutableData, which NSKeyedArchiver writes as an NSMutableData object,
    // while the same bytes bridged through Swift's Data are written inline.
    // These helpers reach the APIs without bridging, so the archives keep
    // their structure (pinned by Tests/WireFormatGolden on iOS).

    /// `-[UIImage lookin_data]` lives in LookinServer (UIImage+LookinServer.h)
    /// and LookinCore does not link against the server, so it is sent
    /// dynamically, as the original's import did; `-[NSImage lookin_data]`
    /// (Image+Lookin.h) goes the same way so it is not bridged to Data.
    @objc private protocol ScreenshotDataBridge {
        @objc(lookin_data) func encodedData() -> NSData?
    }

    /// `image.encodedData` (PNG on iOS, TIFF on macOS); nil for a nil image.
    func screenshotData(_ image: PlatformImage?) -> NSData? {
        guard let image else {
            return nil
        }
        return unsafeBitCast(image, to: ScreenshotDataBridge.self).encodedData()
    }

    #if canImport(UIKit)
        private typealias PNGRepresentationFunction = @convention(c) (UIImage) -> Unmanaged<NSData>?

        /// `UIImagePNGRepresentation`, which Swift imports returning Data.
        private let pngRepresentationFunctionPointer: PNGRepresentationFunction? = {
            // RTLD_DEFAULT, which Swift does not import on every platform.
            let defaultHandle = UnsafeMutableRawPointer(bitPattern: -2)
            guard let symbol = dlsym(defaultHandle, "UIImagePNGRepresentation") else {
                return nil
            }
            return unsafeBitCast(symbol, to: PNGRepresentationFunction.self)
        }()

        /// `UIImagePNGRepresentation(image)`; nil for a nil image.
        func pngRepresentation(_ image: UIImage?) -> NSData? {
            guard let image, let function = pngRepresentationFunctionPointer else {
                return nil
            }
            return function(image)?.takeUnretainedValue()
        }
    #elseif os(macOS)
        @objc private protocol TIFFRepresentationBridge {
            @objc(TIFFRepresentation) var tiffRepresentation: NSData? { get }
        }

        /// `image.TIFFRepresentation`; nil for a nil image.
        func tiffRepresentation(_ image: NSImage?) -> NSData? {
            guard let image else {
                return nil
            }
            return unsafeBitCast(image, to: TIFFRepresentationBridge.self).tiffRepresentation
        }
    #endif

#endif
