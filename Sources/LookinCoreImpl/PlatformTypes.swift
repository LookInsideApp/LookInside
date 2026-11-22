//
//  PlatformTypes.swift
//  LookinCore
//
//  The UIKit or AppKit type behind each kind of object the Host and the
//  Server share code about, so that code is written once for both. This was
//  part of LookinDefines.h.
//
//  `TARGET_OS_IPHONE` covers iOS, tvOS, visionOS and Mac Catalyst; in Swift
//  that is `canImport(UIKit)`. `TARGET_OS_OSX` is `os(macOS)`.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    #if canImport(UIKit)
        import UIKit

        public typealias PlatformColor = UIColor
        public typealias PlatformEdgeInsets = UIEdgeInsets
        public typealias PlatformImage = UIImage
        public typealias PlatformWindow = UIWindow
        public typealias PlatformApplication = UIApplication
        public typealias PlatformImageView = UIImageView
        public typealias PlatformView = UIView
        public typealias PlatformViewController = UIViewController
        public typealias PlatformFont = UIFont
        public typealias PlatformResponder = UIResponder
        public typealias PlatformLayoutGuide = UILayoutGuide
        public typealias PlatformGestureRecognizer = UIGestureRecognizer
        public typealias PlatformControl = UIControl
        public typealias PlatformCollectionView = UICollectionView
        public typealias PlatformTextField = UITextField
        public typealias PlatformTextView = UITextView
        public typealias PlatformLayoutConstraintAxis = NSLayoutConstraint.Axis

        /// The names of the platform's base classes, for code that compares
        /// class names.
        public enum PlatformClassName {
            public static let view = "UIView"
            public static let viewController = "UIViewController"
        }
    #elseif os(macOS)
        import AppKit

        public typealias PlatformColor = NSColor
        public typealias PlatformEdgeInsets = NSEdgeInsets
        public typealias PlatformImage = NSImage
        public typealias PlatformWindow = NSWindow
        public typealias PlatformApplication = NSApplication
        public typealias PlatformImageView = NSImageView
        public typealias PlatformView = NSView
        public typealias PlatformViewController = NSViewController
        public typealias PlatformFont = NSFont
        public typealias PlatformResponder = NSResponder
        public typealias PlatformLayoutGuide = NSLayoutGuide
        public typealias PlatformGestureRecognizer = NSGestureRecognizer
        public typealias PlatformControl = NSControl
        public typealias PlatformCollectionView = NSCollectionView
        public typealias PlatformTextField = NSTextField
        public typealias PlatformTextView = NSTextView
        public typealias PlatformLayoutConstraintAxis = NSLayoutConstraint.Orientation

        /// The names of the platform's base classes, for code that compares
        /// class names.
        public enum PlatformClassName {
            public static let view = "NSView"
            public static let viewController = "NSViewController"
        }
    #endif

#endif
