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

// MARK: - Invocation

/// Structural metadata for an `NSObject` returned by an invocation
/// (RPC 206). The receiver of an `invoke.method` response may use
/// `objectIdentifier` as a handle for a follow-up `invoke.method` call on
/// the same object — but the identifier is a fresh server-registered
/// `LookinObject.oid` and is NOT guaranteed to appear in a subsequent
/// `hierarchy.read` (the hierarchy walks the view tree, not the server's
/// general object registry).
public struct LKMCPBridgeReturnedObject: Sendable, Codable {
    /// Hex-encoded `LookinObject.oid` for the returned object, prefixed
    /// with `0x` (matches the form used everywhere else on the bridge).
    public let objectIdentifier: String

    /// Pointer-formatted memory address of the returned object inside
    /// the inspected app's address space, e.g. `0x100abcd00`.
    public let memoryAddress: String

    /// Full class chain of the returned object (head is the leaf class,
    /// tail is `NSObject`). Identical shape to the
    /// `LookinObject.classChainList` produced by the inspection routes.
    public let classChainList: [String]

    /// Optional debug annotation that the in-app `lookin_specialTrace`
    /// hook may set. `nil` when the object does not opt in.
    public let specialTrace: String?
}

/// Result envelope for `invoke.method`. Always carries `returnedVoid` so
/// callers can disambiguate "method returned `nil` / `0` / empty string"
/// from "method returned void"; the two cases produce the same JSON
/// `description: null` shape on most type-erased clients otherwise.
public struct LKMCPBridgeInvocationResult: Sendable, Codable {
    /// Stringified return value. `nil` when the method returned `void`
    /// or when `secureContent` is `true`. For scalar (non-object,
    /// non-void) returns the server fills in a generic `"Method invoked."`
    /// placeholder; the bridge surfaces that string verbatim.
    public let description: String?

    /// `true` when the inspected method's return type is `void` (the
    /// server signals this via the `LOOKIN_TAG_RETURN_VALUE_VOID` marker).
    public let returnedVoid: Bool

    /// Present only when the method returned an `NSObject`. Even when
    /// `secureContent` is `true` the structural metadata stays — it
    /// carries no user secret, only the object's class chain / address /
    /// `oid` — matching the redaction philosophy of `attributes.read`
    /// (string-bearing attribute values get redacted; structural
    /// metadata does not).
    public let returnObject: LKMCPBridgeReturnedObject?

    /// `true` when the receiver display item is treated as carrying
    /// secure user content (see `LKMCPBridgeSecureContentDetector`). In
    /// that case `description` is redacted to `nil` to avoid leaking
    /// passwords / OTPs into agent transcripts. `returnObject` is kept;
    /// see its doc comment for the redaction rationale.
    public let secureContent: Bool
}

// MARK: - Modification

/// Wire envelope for an attribute value passed across the bridge in a
/// modification context: `kind` is the same string the read-side
/// `LKMCPBridgeAttributeEncoder` produces, `data` is its corresponding
/// JSON-friendly payload. The bridge consumes this in both directions:
/// requests carry it as the value to apply; responses echo it as
/// `requestedValue` so agents can compare against `effectiveAttribute`
/// without having to reconstruct the wire form.
public struct LKMCPBridgeAttributeValueWire: Sendable, Codable {
    public let kind: String
    public let data: LKMCPBridgeJSONValue?
}

/// Result envelope for `attribute.modify`. Echoes the requested value,
/// surfaces the post-layout effective attribute, and includes the
/// host-visible side-effect snapshot (frame / bounds / hidden / alpha)
/// that the server captures in `LookinDisplayItemDetail` after the
/// setter has run and a layout pass has completed.
public struct LKMCPBridgeModificationResult: Sendable, Codable {
    /// Echo of the attribute identifier the agent asked to modify.
    public let attributeIdentifier: String

    /// Echo of the wire `value` payload the agent supplied. Lets the
    /// agent diff against `effectiveAttribute.value` without re-deriving
    /// the wire shape from the encoded result.
    public let requestedValue: LKMCPBridgeAttributeValueWire

    /// Fully-encoded attribute as the host saw it AFTER the setter ran
    /// and a layout pass settled. May differ from the request (autolayout
    /// adjusts frames; some setters round to pixel boundaries; some
    /// setters are no-ops). When `secureContent` is `true` the value
    /// here is redacted in the same way `read_attributes` redacts.
    public let effectiveAttribute: LKMCPBridgeAttribute

    /// `true` when the effective wire value is structurally equal to
    /// the requested wire value. Strict equality — no float epsilon.
    /// `false` means the inspected app's layout pass / setter / autolayout
    /// constraints rejected or adjusted the requested value; agents
    /// should surface this to the user as a real signal.
    public let effectiveMatchesRequested: Bool

    /// Post-modification frame snapshot. Often differs from the previous
    /// `get_hierarchy` result when the modification touched layout.
    public let frame: LKMCPBridgeRect

    /// Post-modification bounds snapshot.
    public let bounds: LKMCPBridgeRect

    /// Post-modification `isHidden` snapshot.
    public let isHidden: Bool

    /// Post-modification composite alpha snapshot in `0.0...1.0`.
    public let alpha: Double

    /// Same secure-content semantics as `read_attributes`: when `true`,
    /// any string-bearing `effectiveAttribute.value` fields are redacted.
    public let secureContent: Bool
}

// MARK: - Details prefetch

/// One per-view entry in a `details.read` response. The shape is
/// deliberately a subset of `attributes.read`'s envelope: agents that
/// already consume `attributes.read` can reuse their `groups` parsing
/// code unchanged. The `secureContent` flag is per-item because a
/// single batch may contain both regular and secure-input views.
public struct LKMCPBridgeViewDetail: Sendable, Codable {
    public let objectIdentifier: String
    public let groups: [LKMCPBridgeAttributeGroup]
    public let secureContent: Bool
}

/// Envelope for `details.read`. Successful per-view detail goes in
/// `details`. Object identifiers that were missing from the client
/// hierarchy or returned `failureCode = -1` from the server fall
/// into `failedIdentifiers` — the call as a whole still succeeds so
/// agents can act on whatever did come back.
public struct LKMCPBridgeDetailsReadResult: Sendable, Codable {
    public let details: [LKMCPBridgeViewDetail]
    public let failedIdentifiers: [String]
}


