//
//  LookinDefines.swift
//  LookinCore
//
//  Versions, ports, request and push numbers, request parameter keys, error
//  codes, the platform type aliases and the geometry limits, shared by every
//  Swift file in LookinCoreImpl and LookinServerImpl; the Host compiles it
//  from DerivedSource as well. This was LookinDefines.h; each name and Swift
//  type is the one Swift saw when it imported that header, so callers did not
//  change. The request numbers and parameter keys cross the wire, and the
//  error replies are pinned by Tests/WireFormatGolden (Response-Error-*).
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import CoreGraphics
    import Foundation

    // MARK: - Version

    /// The connection protocol version of this LookinServer.
    public let LOOKIN_SERVER_VERSION: Int32 = 9

    /// The release version of LookinServer.
    public let LOOKIN_SERVER_READABLE_VERSION = "1.3.0"

    /// The connection protocol version of this LookinClient.
    public let LOOKIN_CLIENT_VERSION: Int32 = 9

    /// The oldest connection protocol version of LookinServer this
    /// LookinClient supports.
    public let LOOKIN_SUPPORTED_SERVER_MIN: Int32 = 8

    /// The newest connection protocol version of LookinServer this
    /// LookinClient supports.
    public let LOOKIN_SUPPORTED_SERVER_MAX: Int32 = 9

    // MARK: - Connection

    /// On a device the Server tries to listen on 47175 through 47179 in turn.
    public let LookinUSBDeviceIPv4PortNumberStart: Int32 = 47175
    public let LookinUSBDeviceIPv4PortNumberEnd: Int32 = 47179

    /// In the Simulator the Server tries to listen on 47164 through 47169 in
    /// turn.
    public let LookinSimulatorIPv4PortNumberStart: Int32 = 47164
    public let LookinSimulatorIPv4PortNumberEnd: Int32 = 47169

    /// In a macOS app the Server tries to listen on 47170 through 47174 in
    /// turn.
    public let LookinMacIPv4PortNumberStart: Int32 = 47170
    public let LookinMacIPv4PortNumberEnd: Int32 = 47174

    // MARK: - Requests and pushes

    // Request types take 200 to 299 and pushes 300 and up; 0 to 199 belong to
    // upstream Lookin. They are `Int`, as the anonymous C enum they replace
    // was imported.

    /// Whether both ends can still answer.
    public let LookinRequestTypePing = 200
    /// The app's screenshot, device model and other information.
    public let LookinRequestTypeApp = 201
    /// The hierarchy.
    public let LookinRequestTypeHierarchy = 202
    /// Screenshots and attribute groups.
    public let LookinRequestTypeHierarchyDetails = 203
    /// Modifies a built-in attribute.
    public let LookinRequestTypeInbuiltAttrModification = 204
    /// After an attribute changed, the latest screenshots and values.
    public let LookinRequestTypeAttrModificationPatch = 205
    /// Invokes a method.
    public let LookinRequestTypeInvokeMethod = 206
    /// Request `["oid": …]`; reply `LookinObject`.
    public let LookinRequestTypeFetchObject = 207
    public let LookinRequestTypeFetchImageViewImage = 208
    public let LookinRequestTypeModifyRecognizerEnable = 209
    /// The attribute group list.
    public let LookinRequestTypeAllAttrGroups = 210

    /// Encodes one window's whole layer tree with QuartzCore's
    /// CAEncodeLayerTree, the format AppKit's Dump Layer writes to `.caar`
    /// files, so the Host can draw the node images itself. Params:
    /// `LookinParam_LayerArchiveWindowOid`, `LookinParam_LayerArchiveLayerLimit`.
    /// Reply: `LookinLayerArchive`. Only macOS Servers that report
    /// `layerArchiveProtocolVersion` 1 answer it; older Servers close the
    /// connection on a request type they do not know, so the Host checks the
    /// capability first.
    public let LookinRequestTypeLayerArchive = 211

    /// Every selector name of a class in the inspected app, superclasses
    /// included.
    public let LookinRequestTypeAllSelectorNames = 213
    /// Modifies a custom attribute.
    public let LookinRequestTypeCustomAttrModification = 214

    /// License handshake: the Server sends a random nonce and its
    /// server_instance_id.
    public let LookinRequestTypeLicenseChallenge = 220
    /// License handshake: the client returns its intermediate certificate and
    /// its signature over the nonce.
    public let LookinRequestTypeLicenseVerify = 221

    /// Versioned SwiftUI gesture capture controls (start, stop, overlay,
    /// status).
    public let LookinRequestTypeGestureDebug = 222

    /// Unused since LookinServer 1.2.7 and Lookin 1.0.7.
    public let LookinPush_BringForwardScreenshotTask = 303
    /// The user cancelled the hierarchy details fetch in the client.
    public let LookinPush_CanceHierarchyDetails = 304
    /// The Server found a SwiftUI hosting view while it walked the hierarchy.
    public let LookinPush_SwiftUISupportDetected = 305
    /// JSON data carrying a versioned, bounded gesture capture batch.
    public let LookinPush_GestureDebug = 306

    /// The application resigned active or became active (UIKit only), tag 0.
    /// Payload: NSDictionary, `LookinParam_ApplicationIsActive` → NSNumber
    /// BOOL. Lets the Host tell an app in the background from a dead
    /// channel and refresh once the app is back. Hosts that predate it find
    /// no request of this type and tag waiting, refuse the frame and skip its
    /// payload (LookInside 2.3.x, 3.x and upstream Lookin all do).
    public let LookinPush_ApplicationStateChanged = 307

    // MARK: - Request parameters

    /// `LookinPush_ApplicationStateChanged` payload key: NSNumber boxed BOOL,
    /// true once the application became active, false when it resigned active.
    public let LookinParam_ApplicationIsActive = "active"

    public let LookinParam_ViewLayerTag = "tag"

    public let LookinParam_SelectorName = "sn"
    public let LookinParam_MethodType = "mt"
    public let LookinParam_SelectorClassName = "scn"

    /// SwiftUI hierarchy display mode payload key on `LookinRequestTypeHierarchy`.
    ///
    /// NSNumber boxed:
    ///   - 0 → verbose
    ///   - 1 → compact
    ///   - missing → the Server falls back to verbose (forward-compatible with
    ///     old Hosts)
    ///
    /// Additive payload: the Server reads it when present and ignores it
    /// otherwise. No version bump.
    public let LookinParam_SwiftUIDisplayMode = "swiftUIDisplayMode"

    /// Hierarchy request (202) param: the Host takes the hierarchy the way
    /// `hierarchyAcquisitionProtocolVersion` 1 describes. The Server then builds
    /// the tree over several main-queue turns, sends progress frames before the
    /// final `HierarchyInfo`, and leaves SwiftUI nodes' screenshots and attribute
    /// groups to the detail request (203), reached through
    /// `LookinCustomDisplayItemInfo.detailObjectOid`.
    ///
    /// NSNumber boxed BOOL. Missing (older Hosts, upstream Lookin) → the
    /// one-frame build with SwiftUI details inline, as before. Additive payload,
    /// no version bump.
    public let LookinParam_AsyncAcquisition = "asyncAcquisition"

    /// Layer archive request (211) param: the oid of the window to encode, as the
    /// hierarchy gave it. NSNumber boxed unsigned long.
    public let LookinParam_LayerArchiveWindowOid = "layerArchiveWindowOid"

    /// Layer archive request (211) param: the most layers the Server may encode.
    /// A window with more is not encoded; the reply then carries only its layer
    /// count. NSNumber boxed unsigned long.
    public let LookinParam_LayerArchiveLayerLimit = "layerArchiveLayerLimit"

    /// App (201) and hierarchy (202) request param: whether a macOS Server draws
    /// the window the inactive app would make key as the key window while it
    /// takes images, so they show the app as it looks in front. The Server keeps
    /// the last value it received for the connection; the requests after a 202
    /// (203, 211, attribute edits) follow it.
    ///
    /// NSNumber boxed BOOL. Missing (older Hosts, upstream Lookin) → on. Other
    /// platforms ignore it. Additive payload, no version bump.
    ///
    /// Servers that know `LookinParam_KeyAppearanceLevel` read that first and
    /// this only when it is missing or a level they do not know: true draws as
    /// key, false is off. A Host sends both, so an older Server falls back to
    /// drawing as key when the Host asks to treat the window as key.
    public let LookinParam_KeepsKeyAppearance = "keepsKeyAppearance"

    /// App (201) and hierarchy (202) request param: how far a macOS Server goes
    /// to show the inactive app as it looks in front while it takes images. As
    /// with `LookinParam_KeepsKeyAppearance`, which the Host sends alongside, the
    /// Server keeps the last value it received for the connection.
    ///
    /// NSNumber boxed `LookinKeyAppearanceLevel`. Missing → read
    /// `LookinParam_KeepsKeyAppearance`; both missing → `drawsAsKey`. Other
    /// platforms ignore it. Additive payload, no version bump.
    public let LookinParam_KeyAppearanceLevel = "keyAppearanceLevel"

    /// The description an invoked method's reply carries when the method
    /// returns void.
    public let LookinStringFlag_VoidReturn = "LOOKIN_TAG_RETURN_VALUE_VOID"

    // `TARGET_OS_IPHONE` covers iOS, tvOS, visionOS and Mac Catalyst; in Swift
    // that is `canImport(UIKit)`. `TARGET_OS_OSX` is `os(macOS)`.
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
        public let LookinLayoutConstraintAxisHorizontal = NSLayoutConstraint.Axis.horizontal
        public let LookinLayoutConstraintAxisVertical = NSLayoutConstraint.Axis.vertical
        public let LookinCollectionElementKindSectionHeader = UICollectionView.elementKindSectionHeader
        public let LookinCollectionElementKindSectionFooter = UICollectionView.elementKindSectionFooter
        public let LookinViewString = "UIView"
        public let LookinViewControllerString = "UIViewController"
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
        public let LookinLayoutConstraintAxisHorizontal = NSLayoutConstraint.Orientation.horizontal
        public let LookinLayoutConstraintAxisVertical = NSLayoutConstraint.Orientation.vertical
        public let LookinCollectionElementKindSectionHeader = NSCollectionView.elementKindSectionHeader
        public let LookinCollectionElementKindSectionFooter = NSCollectionView.elementKindSectionFooter
        public let LookinViewString = "NSView"
        public let LookinViewControllerString = "NSViewController"
    #endif

    // MARK: - Errors

    public let LookinErrorDomain = "LookinError"

    // The error codes are `Int`, as the anonymous C enum they replace was
    // imported.
    public let LookinErrCode_Default = -400
    /// An internal logic error in Lookin.
    public let LookinErrCode_Inner = -401
    /// An internal PeerTalk error.
    public let LookinErrCode_PeerTalk = -402
    /// There is no connection, or it was closed.
    public let LookinErrCode_NoConnect = -403
    /// A ping timed out.
    public let LookinErrCode_PingFailForTimeout = -404
    /// A request timed out.
    public let LookinErrCode_Timeout = -405
    /// A newer request of the same type was sent, so the older one was dropped.
    public let LookinErrCode_Discard = -406
    /// A ping failed because the app reported that it is in the background.
    public let LookinErrCode_PingFailForBackgroundState = -407
    /// The Host did not pass LookinServer's license check.
    public let LookinErrCode_LicenseRequired = -408

    /// The object was not found; it may have been deallocated.
    public let LookinErrCode_ObjectNotFound = -500
    /// The value type cannot be modified.
    public let LookinErrCode_ModifyValueTypeInvalid = -501
    public let LookinErrCode_Exception = -502

    /// LookinServer is too new; the client needs an update.
    public let LookinErrCode_ServerVersionTooHigh = -600
    /// LookinServer is too old; the Server needs an update.
    public let LookinErrCode_ServerVersionTooLow = -601

    /// The file type is not supported.
    public let LookinErrCode_UnsupportedFileType = -700

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
    public func LookinColorRGBAMake(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> PlatformColor {
        PlatformColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }

    /// `LookinColorMake(r, g, b)`.
    public func LookinColorMake(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> PlatformColor {
        PlatformColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: 1)
    }

    // MARK: - Preview

    /// The largest width and height, in pixels, of an image an SCNNode takes;
    /// SceneKit itself sets it.
    public let LookinNodeImageMaxLengthInPx: Double = 16384

    // MARK: - Geometry

    /// The largest coordinate or size, in points, of a rect an inspected app
    /// reports that geometry math still takes: 2^24, the largest integer single
    /// precision holds exactly. Core Animation's render server and the host's
    /// GPU work in single precision, so geometry past it is unreliable anyway.
    /// Real views get well past the 100 000 points this used to be: an outline
    /// view 107 829 points tall went out without a frame, left the host's
    /// preview and moved its rows to the window's origin.
    public let LookinMaximumUsableCoordinate: Double = 16_777_216

    /// Whether a rect reported by an inspected app is safe to feed into geometry
    /// math. NaN / Inf components poison every CGRect computation they touch and
    /// eventually reach layer and scene-graph geometry on the host, so they are
    /// rejected once here instead of at every call site, with anything beyond
    /// `LookinMaximumUsableCoordinate`. Reads the stored size, not the
    /// standardized one, as the C function did.
    public func LookinIsUsableRect(_ rect: CGRect) -> Bool {
        if rect.isNull || rect.isInfinite {
            return false
        }
        let originX = rect.origin.x
        let originY = rect.origin.y
        let width = rect.size.width
        let height = rect.size.height
        if originX.isNaN || originY.isNaN || width.isNaN || height.isNaN {
            return false
        }
        if originX.isInfinite || originY.isInfinite || width.isInfinite || height.isInfinite {
            return false
        }
        let maximumCoordinate = CGFloat(LookinMaximumUsableCoordinate)
        if abs(originX) > maximumCoordinate || abs(originY) > maximumCoordinate
            || width < 0 || height < 0
            || width > maximumCoordinate || height > maximumCoordinate
        {
            return false
        }
        return true
    }

#endif
