// LKMCPBridgeInspectionModels.swift
//
// Codable DTOs returned in MCPBridge response frames. These are deliberately
// flat, JSON-friendly value types so the wire format stays self-describing
// to any consumer (proprietary `lookinside-mcp` shim, future CI bridges,
// remote inspectors). They do not depend on AppKit / UIKit types.
//
// The naming follows the wire vocabulary: a "target" is one inspection
// session bound to a running app (one `LookinLiveDocument`); a "view node"
// is one row in a target's UI hierarchy (one `LookinDisplayItem`).

import CoreGraphics
import Foundation

// MARK: - Rect

/// CGRect represented as JSON-friendly doubles. Origin is the root coordinate
/// space of the inspected hierarchy.
public struct LKMCPBridgeRect: Sendable, Codable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public init(cgRect: CGRect) {
        self.init(
            x: Double(cgRect.origin.x),
            y: Double(cgRect.origin.y),
            width: Double(cgRect.size.width),
            height: Double(cgRect.size.height)
        )
    }
}

// MARK: - TargetInfo

/// One row in a `targets.list` response: a single live inspection session
/// (typically corresponding to one inspector window in the host UI).
public struct LKMCPBridgeTargetInfo: Sendable, Codable {
    /// Stable identifier for the duration of the inspection session.
    /// Derived from `LookinAppInfo.appInfoIdentifier` (randomly generated per
    /// app launch and reused across reconnects to the same app instance).
    public let targetIdentifier: String

    /// Human-readable application name, e.g. "WeRead".
    public let applicationName: String?

    /// Reverse-DNS bundle identifier, e.g. "com.example.weread".
    public let bundleIdentifier: String?

    /// Human-readable device description, e.g. "iPhone 15 Pro".
    public let deviceDescription: String?

    /// Human-readable operating-system description, e.g. "17.4".
    public let operatingSystemDescription: String?

    /// One of `simulator`, `iPad`, `device`, `mac`, `unknown`.
    public let deviceKind: String

    /// Numeric `LookinServer` version reported by the connected app.
    public let serverVersion: Int

    /// One of `licensed`, `trial`, `unlicensed`. V0 reports `licensed` for
    /// every entry; the entitlement gate that produces real values lands in
    /// a follow-up commit.
    public let licenseState: String
}

// MARK: - ViewNode

/// One node in a target's UI hierarchy. Returned by `hierarchy.read`.
///
/// The shape is intentionally minimal for v1 — frame, identity, visibility,
/// and the immediate parent / child relationship. Per-attribute reads and
/// screenshot URIs live in separate methods to be added in subsequent
/// commits.
public struct LKMCPBridgeViewNode: Sendable, Codable {
    /// Hex-encoded `LookinObject.oid`, prefixed with `0x` (for example,
    /// `0x600000abc123`). Stable within a single connected app instance.
    public let objectIdentifier: String

    /// Leaf Objective-C class name (head of `LookinObject.classChainList`),
    /// e.g. "UIButton". May be empty if the underlying display item is
    /// configured by the in-app `lookin_customDebugInfos` hook without
    /// touching a real view / layer.
    public let className: String

    /// Frame in the root coordinate space (host calls this `frameToRoot`).
    public let frame: LKMCPBridgeRect

    /// `true` when the view is hidden via UIKit / AppKit visibility flags.
    public let isHidden: Bool

    /// Composite alpha in `0.0 ... 1.0`.
    public let alpha: Double

    /// `true` when this node represents the key `UIWindow` / `NSWindow`.
    public let representsKeyWindow: Bool

    /// Object identifiers of immediate children, in source order.
    public let childObjectIdentifiers: [String]

    /// Inlined child nodes when the request asked for a depth greater than
    /// one. `nil` means children were not expanded; an empty array means
    /// children were expanded and there are none.
    public let children: [LKMCPBridgeViewNode]?
}

// MARK: - AttributeGroup / Section / Attribute

/// One attribute "card" in the host's inspector — a coherent bundle of
/// related attributes (Frame, View, Layer, AutoLayout, UIControl, …).
public struct LKMCPBridgeAttributeGroup: Sendable, Codable {
    /// Group identifier (`LookinAttrGroupIdentifier`, e.g. `Layout`,
    /// `UIScrollView`, `NSWindow`), or the user-supplied title when the
    /// group originates from `lookin_customDebugInfos`.
    public let identifier: String

    /// `true` when this group comes from in-app `lookin_customDebugInfos`
    /// rather than LookinServer's built-in introspection.
    public let isUserCustom: Bool

    /// `true` when this group was produced by the activation-gated SwiftUI
    /// extension; agents can use this to flag paid-feature data origin.
    public let isSwiftUIGroup: Bool

    public let sections: [LKMCPBridgeAttributeSection]
}

/// One sub-row inside an attribute group.
public struct LKMCPBridgeAttributeSection: Sendable, Codable {
    public let identifier: String
    public let attributes: [LKMCPBridgeAttribute]
}

/// One inspected attribute value with a type-discriminating `kind`.
public struct LKMCPBridgeAttribute: Sendable, Codable {
    /// `LookinAttrIdentifier` string (e.g. `BasicViewClass_Frame`,
    /// `BasicViewClass_Hidden`). Stable across LookinServer versions.
    public let identifier: String

    /// Human-readable title set by `lookin_customDebugInfos`; empty for
    /// built-in attributes.
    public let displayTitle: String?

    /// `true` when this attribute originates from `lookin_customDebugInfos`.
    public let isUserCustom: Bool

    /// Type discriminator for `value`. See `LKMCPBridgeAttributeEncoder`
    /// for the full kind → JSON-shape mapping. Common values:
    /// `integer`, `double`, `bool`, `string`, `selector`, `class`,
    /// `point`, `size`, `rect`, `edgeInsets`, `offset`, `transform`,
    /// `color`, `shadow`, `enum`, `json`, `custom`, `void`,
    /// `unknown` (when the encoder cannot project the type cleanly and
    /// falls back to a `{ "rawDescription": "..." }` payload).
    public let kind: String

    /// The encoded attribute value, shape-correlated with `kind`. `nil`
    /// when the source attribute carries no value (`LookinAttrTypeVoid`
    /// or genuinely empty optional fields).
    public let value: LKMCPBridgeJSONValue?

    /// Auxiliary payload for select kinds. For `enum` types, this is the
    /// list of all enum case names the inspected object can hold (the
    /// host calls these `extraValue` on `LookinAttribute`).
    public let extraValue: LKMCPBridgeJSONValue?

    /// Server-side identifier of a custom-attribute setter, present only
    /// when the host can write to this attribute through a registered
    /// custom setter. Pass-through; the bridge does not interpret it.
    public let customSetterIdentifier: String?
}

