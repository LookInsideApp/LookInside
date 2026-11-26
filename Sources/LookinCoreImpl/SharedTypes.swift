//
//  SharedTypes.swift
//  LookinCore
//
//  The enums and option sets the Host and the Server share, formerly C
//  NS_ENUM / NS_OPTIONS declarations. Each enum is nested in the type it
//  belongs to (DisplayItem.NodeKind, InspectedAttribute.ValueType); raw types
//  and raw values are the C ones, and every type and case keeps its C name
//  for Objective-C through `@objc(...)`. The types are `@frozen`: the
//  XCFramework builds with library evolution and the tests without it, and
//  frozen enums switch the same way in both.
//
//  An enum decoded from the wire answers nil for a raw value it does not
//  know, where the imported C enum carried the value through; the decoders
//  fall back to their documented default then (protocol.md, "Wire enums").
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    // MARK: - Attributes

    extension InspectedAttribute {
        /// The type of an attribute's value. Append only: the integers travel on
        /// the wire, and a Host and a Server of different versions must agree on
        /// every case they both know.
        @frozen
        @objc(LookinAttrType)
        public enum ValueType: Int, Sendable {
            @objc(LookinAttrTypeNone) case none = 0
            @objc(LookinAttrTypeVoid) case void = 1
            @objc(LookinAttrTypeChar) case char = 2
            @objc(LookinAttrTypeInt) case int = 3
            @objc(LookinAttrTypeShort) case short = 4
            @objc(LookinAttrTypeLong) case long = 5
            @objc(LookinAttrTypeLongLong) case longLong = 6
            @objc(LookinAttrTypeUnsignedChar) case unsignedChar = 7
            @objc(LookinAttrTypeUnsignedInt) case unsignedInt = 8
            @objc(LookinAttrTypeUnsignedShort) case unsignedShort = 9
            @objc(LookinAttrTypeUnsignedLong) case unsignedLong = 10
            @objc(LookinAttrTypeUnsignedLongLong) case unsignedLongLong = 11
            @objc(LookinAttrTypeFloat) case float = 12
            @objc(LookinAttrTypeDouble) case double = 13
            @objc(LookinAttrTypeBOOL) case bool = 14
            @objc(LookinAttrTypeSel) case selector = 15
            @objc(LookinAttrTypeClass) case `class` = 16
            @objc(LookinAttrTypeCGPoint) case cgPoint = 17
            @objc(LookinAttrTypeCGVector) case cgVector = 18
            @objc(LookinAttrTypeCGSize) case cgSize = 19
            @objc(LookinAttrTypeCGRect) case cgRect = 20
            @objc(LookinAttrTypeCGAffineTransform) case cgAffineTransform = 21
            @objc(LookinAttrTypeUIEdgeInsets) case uiEdgeInsets = 22
            @objc(LookinAttrTypeUIOffset) case uiOffset = 23
            @objc(LookinAttrTypeNSString) case nsString = 24
            @objc(LookinAttrTypeEnumInt) case enumInt = 25
            @objc(LookinAttrTypeEnumLong) case enumLong = 26
            /// The value is an RGBA array: four NSNumbers from 0 to 1.
            @objc(LookinAttrTypeUIColor) case uiColor = 27
            /// The value's shape depends on the attribute identifier.
            @objc(LookinAttrTypeCustomObj) case customObject = 28
            @objc(LookinAttrTypeEnumString) case enumString = 29
            @objc(LookinAttrTypeShadow) case shadow = 30
            @objc(LookinAttrTypeJson) case json = 31
        }
    }

    extension InspectedAttribute {
        /// Which object on a display item an attribute reads from and writes to.
        /// The Host picks the target oid for a modification with this; the older
        /// per-kind boolean queries on the blueprint remain as wrappers around it.
        @frozen
        @objc(LookinAttrTargetKind)
        public enum TargetKind: Int, Sendable {
            @objc(LookinAttrTargetKindLayer) case layer = 0
            @objc(LookinAttrTargetKindView) case view = 1
            @objc(LookinAttrTargetKindWindow) case window = 2
            /// AppKit only.
            @objc(LookinAttrTargetKindCell) case cell = 3
            /// A layout guide node's own guide (`UILayoutGuide`, `NSLayoutGuide`
            /// and their subclasses), which the node carries as its kindObject.
            @objc(LookinAttrTargetKindLayoutGuide) case layoutGuide = 4
        }
    }

    extension AttributesSection {
        /// How a dashboard section lays out its attributes.
        @frozen
        @objc(LookinAttributesSectionStyle)
        public enum Style: Int, Sendable {
            /// Every attribute on a row of its own.
            @objc(LookinAttributesSectionStyleDefault) case oneAttributePerRow = 0
            /// For frame-like cards: the first four attributes two to a row, then
            /// every attribute on one row, each a quarter of the width.
            @objc(LookinAttributesSectionStyle0) case twoPerRowThenQuarters = 1
            /// The first attribute on the left of the first row, the second on its
            /// right, then every attribute on a row of its own.
            @objc(LookinAttributesSectionStyle1) case firstRowPairThenOnePerRow = 2
            /// The first attribute on a row of its own, the rest on one row,
            /// sharing its width equally.
            @objc(LookinAttributesSectionStyle2) case firstAloneThenSharedRow = 3
        }
    }

    // MARK: - Connection

    extension ConnectionAttachment {
        /// The kind of value a connection attachment carries.
        @frozen
        @objc(LookinCodingValueType)
        public enum ValueType: Int, Sendable {
            @objc(LookinCodingValueTypeUnknown) case unknown = 0
            @objc(LookinCodingValueTypeChar) case char = 1
            @objc(LookinCodingValueTypeDouble) case double = 2
            @objc(LookinCodingValueTypeFloat) case float = 3
            @objc(LookinCodingValueTypeLongLong) case longLong = 4
            @objc(LookinCodingValueTypeBOOL) case bool = 5
            @objc(LookinCodingValueTypeColor) case color = 6
            @objc(LookinCodingValueTypeEnum) case `enum` = 7
            @objc(LookinCodingValueTypeImage) case image = 8
        }
    }

    extension InspectedAppInfo {
        /// The device an inspected app runs on. Append only: the raw value goes to
        /// the Host over the wire. Upstream Lookin knows only the first three
        /// (0 to 2) and falls into its default branch for anything larger, which
        /// shows as a missing device icon rather than an error.
        @frozen
        @objc(LookinAppInfoDevice)
        public enum Device: Int, Sendable {
            /// The Simulator.
            @objc(LookinAppInfoDeviceSimulator) case simulator = 0
            /// A real iPad.
            @objc(LookinAppInfoDeviceIPad) case iPad = 1
            /// Anything else, taken as a real iPhone.
            @objc(LookinAppInfoDeviceOthers) case others = 2
            /// A Mac app built with AppKit (not Mac Catalyst).
            @objc(LookinAppInfoDeviceMac) case mac = 3
            /// A Mac Catalyst app: it runs on the Mac with a UIKit interface.
            @objc(LookinAppInfoDeviceMacCatalyst) case macCatalyst = 4
        }
    }

    // MARK: - Display items

    extension DisplayItem {
        /// How a display item's images are encoded when it is archived.
        @frozen
        @objc(LookinDisplayItemImageEncodeType)
        public enum ImageEncoding: UInt, Sendable {
            /// Not encoded.
            @objc(LookinDisplayItemImageEncodeTypeNone) case none = 0
            /// Converted to NSData.
            @objc(LookinDisplayItemImageEncodeTypeNSData) case nsData = 1
            /// Encoded with NSImage's or UIImage's own encoding.
            @objc(LookinDisplayItemImageEncodeTypeImage) case image = 2
        }
    }

    extension DisplayItem {
        /// Whether, and why not, a display item's screenshot may be fetched.
        @frozen
        @objc(LookinDoNotFetchScreenshotReason)
        public enum DoNotFetchScreenshotReason: UInt, Sendable {
            /// The screenshot can be fetched.
            @objc(LookinFetchScreenshotPermitted) case permitted = 0
            /// The layer is too large.
            @objc(LookinDoNotFetchScreenshotForTooLarge) case tooLarge = 1
            /// The LookinServer user's configuration refused it.
            @objc(LookinDoNotFetchScreenshotForUserConfig) case userConfiguration = 2
            /// The node has no pixels of its own (a layout guide, for example): no
            /// screenshot task is sent, but the preview still draws its wireframe.
            @objc(LookinDoNotFetchScreenshotForNoPixels) case noPixels = 3
        }
    }

    extension DisplayItem {
        /// The display item property a `displayItem:propertyDidChange:` call is
        /// about.
        @frozen
        @objc(LookinDisplayItemProperty)
        public enum Property: UInt, Sendable {
            /// Sent once, right when the delegate is first set.
            @objc(LookinDisplayItemProperty_None) case none = 0
            @objc(LookinDisplayItemProperty_FrameToRoot) case frameToRoot = 1
            @objc(LookinDisplayItemProperty_DisplayingInHierarchy) case displayingInHierarchy = 2
            @objc(LookinDisplayItemProperty_InHiddenHierarchy) case inHiddenHierarchy = 3
            @objc(LookinDisplayItemProperty_IsExpandable) case isExpandable = 4
            @objc(LookinDisplayItemProperty_IsExpanded) case isExpanded = 5
            @objc(LookinDisplayItemProperty_SoloScreenshot) case soloScreenshot = 6
            @objc(LookinDisplayItemProperty_GroupScreenshot) case groupScreenshot = 7
            @objc(LookinDisplayItemProperty_IsSelected) case isSelected = 8
            @objc(LookinDisplayItemProperty_IsHovered) case isHovered = 9
            @objc(LookinDisplayItemProperty_AvoidSyncScreenshot) case avoidSyncScreenshot = 10
            @objc(LookinDisplayItemProperty_InNoPreviewHierarchy) case inNoPreviewHierarchy = 11
            @objc(LookinDisplayItemProperty_IsInSearch) case isInSearch = 12
            @objc(LookinDisplayItemProperty_HighlightedSearchString) case highlightedSearchString = 13
        }
    }

    extension DisplayItem {
        /// What a hierarchy node *is*. Append only: the integers travel on the wire
        /// and inside .lookin archives, so existing cases must never be renumbered.
        @frozen
        @objc(LookinDisplayItemNodeKind)
        public enum NodeKind: Int, Sendable {
            /// Data produced before this field existed (old servers, old archives).
            /// Consumers must read resolvedNodeKind, which derives the kind from the
            /// legacy object slots in this case.
            @objc(LookinDisplayItemNodeKindUnspecified) case unspecified = 0
            @objc(LookinDisplayItemNodeKindLayer) case layer = 1
            @objc(LookinDisplayItemNodeKindView) case view = 2
            @objc(LookinDisplayItemNodeKindWindow) case window = 3
            @objc(LookinDisplayItemNodeKindWindowScene) case windowScene = 4
            /// A customInfo node (including SwiftUI virtual nodes — those are told
            /// apart by customInfo.isSwiftUI, not by a separate kind).
            @objc(LookinDisplayItemNodeKindCustom) case custom = 5
            @objc(LookinDisplayItemNodeKindLayoutGuide) case layoutGuide = 6
            /// AppKit-only: an NSControl's cell as a child node of the control
            /// (cell-node proposal). Wireframe preview, attributes read from the cell.
            @objc(LookinDisplayItemNodeKindCell) case cell = 7
            /// UIKit-only: the outermost layer of a view whose backing layer UIKit
            /// wrapped in an intermediate one (_UIMultiLayer, iOS 26+). The geometry
            /// and the group-compositing rules moved onto it while the contents
            /// stayed on the view's own backing layer, so it has no pixels of its
            /// own — no screenshot is ever fetched for it — but it still gets a
            /// preview plane of its own, parallel to the view it wraps, like any
            /// other child node (node-pixel-ownership proposal).
            @objc(LookinDisplayItemNodeKindViewOuterLayer) case viewOuterLayer = 8
            /// A view's backing layer, emitted as a child of that view's node when
            /// the show-backing-layers toggle is on (backing-layer-toggle proposal).
            /// An ordinary pixel-bearing node: with the toggle on, content shows on
            /// the layer that really renders it, and the view nodes above render as
            /// wireframes. Never emitted while the toggle is off.
            @objc(LookinDisplayItemNodeKindBackingLayer) case backingLayer = 9
        }
    }

    extension DisplayItemDetail {
        /// Values of `LookinDisplayItemDetail.failureCode`. The property stays a
        /// plain integer on the wire.
        @frozen
        @objc(LookinDisplayItemDetailFailureCode)
        public enum FailureCode: Int, Sendable {
            @objc(LookinDisplayItemDetailFailureCodeNone) case none = 0
            /// The oid resolved to an object no detail branch handles — a real
            /// fault worth surfacing. The only value servers sent before 2026-08, so
            /// old hosts alert on exactly this one.
            @objc(LookinDisplayItemDetailFailureCodeUnhandledObject) case unhandledObject = -1
            /// The oid resolved to nothing: the object was released after the
            /// hierarchy build. The inspected app's short-lived internals (TextKit 2
            /// fragment views, portals) go away on their own, so this is routine —
            /// the node keeps showing the data captured at build time and hosts log
            /// it without alerting. Old hosts treat it as a successful empty detail,
            /// which is harmless.
            @objc(LookinDisplayItemDetailFailureCodeObjectGone) case objectGone = -2
        }
    }

    // MARK: - Constraints

    extension AutoLayoutConstraint {
        /// What one end of an Auto Layout constraint points at.
        @frozen
        @objc(LookinConstraintItemType)
        public enum ItemType: Int, Sendable {
            @objc(LookinConstraintItemTypeUnknown) case unknown = 0
            @objc(LookinConstraintItemTypeNil) case `nil` = 1
            @objc(LookinConstraintItemTypeView) case view = 2
            @objc(LookinConstraintItemTypeSelf) case `self` = 3
            @objc(LookinConstraintItemTypeSuper) case `super` = 4
            @objc(LookinConstraintItemTypeLayoutGuide) case layoutGuide = 5
        }
    }

    extension AutoLayoutConstraint {
        /// Which end of a constraint.
        @frozen
        @objc(LookinConstraintEndpoint)
        public enum Endpoint: Int, Sendable {
            @objc(LookinConstraintEndpointFirst) case first = 0
            @objc(LookinConstraintEndpointSecond) case second = 1
        }
    }

    // MARK: - Event handlers

    extension EventHandlerDescription {
        /// How an event handler receives its events.
        @frozen
        @objc(LookinEventHandlerType)
        public enum HandlerType: Int, Sendable {
            @objc(LookinEventHandlerTypeTargetAction) case targetAction = 0
            @objc(LookinEventHandlerTypeGesture) case gesture = 1
        }
    }

    // MARK: - Detail tasks

    extension StaticAsyncUpdateTask {
        /// Which image a detail task asks for.
        @frozen
        @objc(LookinStaticAsyncUpdateTaskType)
        public enum TaskType: Int, Sendable {
            @objc(LookinStaticAsyncUpdateTaskTypeNoScreenshot) case noScreenshot = 0
            @objc(LookinStaticAsyncUpdateTaskTypeSoloScreenshot) case soloScreenshot = 1
            @objc(LookinStaticAsyncUpdateTaskTypeGroupScreenshot) case groupScreenshot = 2
        }
    }

    extension StaticAsyncUpdateTask {
        /// Whether a detail task wants the node's attribute groups.
        @frozen
        @objc(LookinDetailUpdateTaskAttrRequest)
        public enum AttributeRequest: Int, Sendable {
            /// The Server decides: within one batch of tasks it builds a layer's
            /// attributes only once. In Lookin's turbo mode tasks for the same
            /// layer can land in different batches, so attributes may be built
            /// more than once, which costs some time.
            @objc(LookinDetailUpdateTaskAttrRequest_Automatic) case automatic = 0
            /// The attributes are wanted.
            @objc(LookinDetailUpdateTaskAttrRequest_Need) case need = 1
            /// The attributes are not wanted.
            @objc(LookinDetailUpdateTaskAttrRequest_NotNeed) case notNeed = 2
        }
    }

    // MARK: - Key appearance

    /// How far a macOS Server goes to show the inactive app as it looks in
    /// front while it takes images (`RequestParameterKey.keyAppearanceLevel`). Each
    /// level does what the one below it does, and more.
    @frozen
    @objc(LookinKeyAppearanceLevel)
    public enum KeyAppearanceLevel: Int, Sendable {
        /// The window keeps the inactive look.
        @objc(LookinKeyAppearanceLevelOff)
        case off = 0

        /// The would-be key window is drawn as key (AppKit's private
        /// -acquireKeyAppearance): AppKit's own views look active; the window
        /// does not become key and the app is not told anything.
        @objc(LookinKeyAppearanceLevelDrawsAsKey)
        case drawsAsKey = 1

        /// As `drawsAsKey`, and the window answers true from -isKeyWindow and
        /// the app gets NSWindowDidBecomeKeyNotification /
        /// NSWindowDidResignKeyNotification, so views the app draws from
        /// -isKeyWindow look active too. The app's own become-key and
        /// resign-key code runs on every refresh.
        @objc(LookinKeyAppearanceLevelTreatsAsKey)
        case treatsAsKey = 2
    }

    // MARK: - Preview

    /// The SceneKit category bits the Host's preview gives its nodes.
    public struct PreviewBitMask: OptionSet, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let selectable = PreviewBitMask(rawValue: 1 << 1)
        public static let unselectable = PreviewBitMask(rawValue: 1 << 2)
        public static let hasLight = PreviewBitMask(rawValue: 1 << 3)
        public static let noLight = PreviewBitMask(rawValue: 1 << 4)
    }

#endif
