//
//  LookinDefines.swift
//  LookinCore
//
//  The Swift spelling of the LookinDefines.h macros that Swift cannot import
//  (type macros, error macros, string macros). Shared by every Swift
//  implementation file in LookinCoreImpl and LookinServerImpl; the Host
//  compiles it from DerivedSource as well. Values must stay identical to the
//  macros in LookinDefines.h: the error replies are pinned by
//  Tests/WireFormatGolden (Response-Error-*).
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    // `TARGET_OS_IPHONE` covers iOS, tvOS, visionOS and Mac Catalyst; in Swift
    // that is `canImport(UIKit)`. `TARGET_OS_OSX` is `os(macOS)`.
    #if canImport(UIKit)
        import UIKit

        public typealias LookinColor = UIColor
        public typealias LookinInsets = UIEdgeInsets
        public typealias LookinImage = UIImage
        public typealias LookinWindow = UIWindow
        public typealias LookinApplication = UIApplication
        public typealias LookinImageView = UIImageView
        public typealias LookinView = UIView
        public typealias LookinViewController = UIViewController
        public typealias LookinFont = UIFont
        public typealias LookinResponder = UIResponder
        public typealias LookinLayoutGuide = UILayoutGuide
        public typealias LookinGestureRecognizer = UIGestureRecognizer
        public typealias LookinControl = UIControl
        public typealias LookinCollectionView = UICollectionView
        public typealias LookinTextField = UITextField
        public typealias LookinTextView = UITextView
        public let LookinLayoutConstraintAxisHorizontal = NSLayoutConstraint.Axis.horizontal
        public let LookinLayoutConstraintAxisVertical = NSLayoutConstraint.Axis.vertical
        public let LookinCollectionElementKindSectionHeader = UICollectionView.elementKindSectionHeader
        public let LookinCollectionElementKindSectionFooter = UICollectionView.elementKindSectionFooter
        public let LookinViewString = "UIView"
        public let LookinViewControllerString = "UIViewController"
    #elseif os(macOS)
        import AppKit

        public typealias LookinColor = NSColor
        public typealias LookinInsets = NSEdgeInsets
        public typealias LookinImage = NSImage
        public typealias LookinWindow = NSWindow
        public typealias LookinApplication = NSApplication
        public typealias LookinImageView = NSImageView
        public typealias LookinView = NSView
        public typealias LookinViewController = NSViewController
        public typealias LookinFont = NSFont
        public typealias LookinResponder = NSResponder
        public typealias LookinLayoutGuide = NSLayoutGuide
        public typealias LookinGestureRecognizer = NSGestureRecognizer
        public typealias LookinControl = NSControl
        public typealias LookinCollectionView = NSCollectionView
        public typealias LookinTextField = NSTextField
        public typealias LookinTextView = NSTextView
        public let LookinLayoutConstraintAxisHorizontal = NSLayoutConstraint.Orientation.horizontal
        public let LookinLayoutConstraintAxisVertical = NSLayoutConstraint.Orientation.vertical
        public let LookinCollectionElementKindSectionHeader = NSCollectionView.elementKindSectionHeader
        public let LookinCollectionElementKindSectionFooter = NSCollectionView.elementKindSectionFooter
        public let LookinViewString = "NSView"
        public let LookinViewControllerString = "NSViewController"
    #endif

    // MARK: - Errors

    /// `LookinErr_ObjNotFound`. A new NSError on every read, like the macro.
    public var LookinErr_ObjNotFound: NSError {
        NSError(domain: LookinErrorDomain, code: Int(LookinErrCode_ObjectNotFound), userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("Failed to get target object in iOS app", comment: ""),
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Perhaps the related object was deallocated. You can reload LookInside to get newest data.", comment: ""),
        ])
    }

    /// `LookinErr_NoConnect`.
    public var LookinErr_NoConnect: NSError {
        NSError(domain: LookinErrorDomain, code: Int(LookinErrCode_NoConnect), userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("The operation failed due to disconnection with the iOS app.", comment: ""),
        ])
    }

    /// `LookinErr_Inner`.
    public var LookinErr_Inner: NSError {
        NSError(domain: LookinErrorDomain, code: Int(LookinErrCode_Inner), userInfo: [
            NSLocalizedDescriptionKey: NSLocalizedString("The operation failed due to an inner error.", comment: ""),
        ])
    }

    /// `LookinErrorMake(errorTitle, errorDetail)`.
    public func LookinErrorMake(_ errorTitle: String, _ errorDetail: String) -> NSError {
        NSError(domain: LookinErrorDomain, code: Int(LookinErrCode_Default), userInfo: [
            NSLocalizedDescriptionKey: errorTitle,
            NSLocalizedRecoverySuggestionErrorKey: errorDetail,
        ])
    }

    /// `LookinErrorText_Timeout`.
    public var LookinErrorText_Timeout: String {
        NSLocalizedString("Perhaps your iOS app is paused with breakpoint in Xcode, blocked by other tasks in main thread, or moved to background state.", comment: "")
    }

    // MARK: - Colors

    /// `LookinColorRGBAMake(r, g, b, a)`: components in 0...255, alpha in 0...1.
    public func LookinColorRGBAMake(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> LookinColor {
        LookinColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }

    /// `LookinColorMake(r, g, b)`.
    public func LookinColorMake(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> LookinColor {
        LookinColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
    }

#endif
