//
//  Image+Lookin.swift
//  LookinCore
//
//  Was Image+Lookin.m. The category
//  only exists on AppKit.
//

#if SHOULD_COMPILE_LOOKIN_SERVER && os(macOS)

    import AppKit
    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    public extension NSImage {
        @objc(lookin_data)
        func lookin_data() -> Data! {
            if representations.isEmpty {
                return nil
            }
            // Bitmap representations first (raster images).
            if let data = NSBitmapImageRep.representationOfImageReps(in: representations, using: .png, properties: [:]) {
                return data
            }
            // Fallback: render into a bitmap (vector images, SF Symbols).
            var proposedRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let cgImage = cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
                return nil
            }
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            return bitmapRep.representation(using: .png, properties: [:])
        }
    }

#endif
