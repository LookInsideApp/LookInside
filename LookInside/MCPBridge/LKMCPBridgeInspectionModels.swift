// LKMCPBridgeInspectionModels.swift
//
// Codable DTOs returned in MCPBridge response frames. These are deliberately
// flat, JSON-friendly value types so the wire format stays self-describing
// to any consumer (proprietary `lookinside-mcp` shim, future CI bridges,
// remote inspectors). They do not depend on AppKit / UIKit types.
//
// The naming follows the wire vocabulary: a "target" is one inspection
// session bound to a running app (one `LookinLiveDocument`); a "view node"
// is one row in a target's UI hierarchy (one `DisplayItem`).

import CoreGraphics
import Foundation

// MARK: - Rect

/// CGRect represented as JSON-friendly doubles. Origin is the root coordinate
/// space of the inspected hierarchy.
struct LKMCPBridgeRect: Sendable, Codable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(cgRect: CGRect) {
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
struct LKMCPBridgeTargetInfo: Sendable, Codable {
    /// Stable identifier for the duration of the inspection session.
    /// Derived from `InspectedAppInfo.appInfoIdentifier` (randomly generated per
    /// app launch and reused across reconnects to the same app instance).
    let targetIdentifier: String

    /// Human-readable application name, e.g. "WeRead".
    let applicationName: String?

    /// Reverse-DNS bundle identifier, e.g. "com.example.weread".
    let bundleIdentifier: String?

    /// Human-readable device description, e.g. "iPhone 15 Pro".
    let deviceDescription: String?

    /// Human-readable operating-system description, e.g. "17.4".
    let operatingSystemDescription: String?

    /// One of `simulator`, `iPad`, `device`, `mac`, `unknown`.
    let deviceKind: String

    /// Numeric `LookinServer` version reported by the connected app.
    let serverVersion: Int

    /// One of `licensed`, `trial`, `unlicensed`. V0 reports `licensed` for
    /// every entry; the entitlement gate that produces real values lands in
    /// a follow-up commit.
    let licenseState: String
}

// MARK: - ViewNode

/// One node in a target's UI hierarchy. Returned by `hierarchy.read`.
///
/// The shape is intentionally minimal for v1 — frame, identity, visibility,
/// and the immediate parent / child relationship. Per-attribute reads and
/// screenshot URIs live in separate methods to be added in subsequent
/// commits.
struct LKMCPBridgeViewNode: Sendable, Codable {
    /// Hex-encoded `InspectedObject.oid`, prefixed with `0x` (for example,
    /// `0x600000abc123`). Stable within a single connected app instance.
    let objectIdentifier: String

    /// Leaf Objective-C class name (head of `InspectedObject.classChainList`),
    /// e.g. "UIButton". May be empty if the underlying display item is
    /// configured by the in-app `lookin_customDebugInfos` hook without
    /// touching a real view / layer.
    let className: String

    /// What the node is: "view" | "layer" | "window" | "windowScene" |
    /// "layoutGuide" | "custom". Mapped from the display item's resolved
    /// node kind, so it is present for old servers too (slot derivation).
    let nodeKind: String

    /// Frame in the root coordinate space (host calls this `frameToRoot`).
    let frame: LKMCPBridgeRect

    /// `true` when the view is hidden via UIKit / AppKit visibility flags.
    let isHidden: Bool

    /// Composite alpha in `0.0 ... 1.0`.
    let alpha: Double

    /// `true` when this node represents the key `UIWindow` / `NSWindow`.
    let representsKeyWindow: Bool

    /// Object identifiers of immediate children, in source order.
    let childObjectIdentifiers: [String]

    /// Inlined child nodes when the request asked for a depth greater than
    /// one. `nil` means children were not expanded; an empty array means
    /// children were expanded and there are none.
    let children: [LKMCPBridgeViewNode]?
}

// MARK: - AttributeGroup / Section / Attribute

/// One attribute "card" in the host's inspector — a coherent bundle of
/// related attributes (Frame, View, Layer, AutoLayout, UIControl, …).
struct LKMCPBridgeAttributeGroup: Sendable, Codable {
    /// Group identifier (`LookinAttrGroupIdentifier`, e.g. `Layout`,
    /// `UIScrollView`, `NSWindow`), or the user-supplied title when the
    /// group originates from `lookin_customDebugInfos`.
    let identifier: String

    /// `true` when this group comes from in-app `lookin_customDebugInfos`
    /// rather than LookinServer's built-in introspection.
    let isUserCustom: Bool

    /// `true` when this group was produced by the activation-gated SwiftUI
    /// extension; agents can use this to flag paid-feature data origin.
    let isSwiftUIGroup: Bool

    let sections: [LKMCPBridgeAttributeSection]
}

/// One sub-row inside an attribute group.
struct LKMCPBridgeAttributeSection: Sendable, Codable {
    let identifier: String
    let attributes: [LKMCPBridgeAttribute]
}

/// One inspected attribute value with a type-discriminating `kind`.
struct LKMCPBridgeAttribute: Sendable, Codable {
    /// `LookinAttrIdentifier` string (e.g. `BasicViewClass_Frame`,
    /// `BasicViewClass_Hidden`). Stable across LookinServer versions.
    let identifier: String

    /// Human-readable title set by `lookin_customDebugInfos`; empty for
    /// built-in attributes.
    let displayTitle: String?

    /// `true` when this attribute originates from `lookin_customDebugInfos`.
    let isUserCustom: Bool

    /// Type discriminator for `value`. See `LKMCPBridgeAttributeEncoder`
    /// for the full kind → JSON-shape mapping. Common values:
    /// `integer`, `double`, `bool`, `string`, `selector`, `class`,
    /// `point`, `size`, `rect`, `edgeInsets`, `offset`, `transform`,
    /// `color`, `shadow`, `enum`, `json`, `custom`, `void`,
    /// `unknown` (when the encoder cannot project the type cleanly and
    /// falls back to a `{ "rawDescription": "..." }` payload).
    let kind: String

    /// The encoded attribute value, shape-correlated with `kind`. `nil`
    /// when the source attribute carries no value (`LookinAttrTypeVoid`
    /// or genuinely empty optional fields).
    let value: LKMCPBridgeJSONValue?

    /// Auxiliary payload for select kinds. For `enum` types, this is the
    /// list of all enum case names the inspected object can hold (the
    /// host calls these `extraValue` on `InspectedAttribute`).
    let extraValue: LKMCPBridgeJSONValue?

    /// Server-side identifier of a custom-attribute setter, present only
    /// when the host can write to this attribute through a registered
    /// custom setter. Pass-through; the bridge does not interpret it.
    let customSetterIdentifier: String?
}

// MARK: - Invocation

/// Structural metadata for an `NSObject` returned by an invocation
/// (RPC 206). The receiver of an `invoke.method` response may use
/// `objectIdentifier` as a handle for a follow-up `invoke.method` call on
/// the same object — but the identifier is a fresh server-registered
/// `InspectedObject.oid` and is NOT guaranteed to appear in a subsequent
/// `hierarchy.read` (the hierarchy walks the view tree, not the server's
/// general object registry).
struct LKMCPBridgeReturnedObject: Sendable, Codable {
    /// Hex-encoded `InspectedObject.oid` for the returned object, prefixed
    /// with `0x` (matches the form used everywhere else on the bridge).
    let objectIdentifier: String

    /// Pointer-formatted memory address of the returned object inside
    /// the inspected app's address space, e.g. `0x100abcd00`.
    let memoryAddress: String

    /// Full class chain of the returned object (head is the leaf class,
    /// tail is `NSObject`). Identical shape to the
    /// `InspectedObject.classChainList` produced by the inspection routes.
    let classChainList: [String]

    /// Optional debug annotation that the in-app `lookin_specialTrace`
    /// hook may set. `nil` when the object does not opt in.
    let specialTrace: String?
}

/// Result envelope for `invoke.method`. Always carries `returnedVoid` so
/// callers can disambiguate "method returned `nil` / `0` / empty string"
/// from "method returned void"; the two cases produce the same JSON
/// `description: null` shape on most type-erased clients otherwise.
struct LKMCPBridgeInvocationResult: Sendable, Codable {
    /// Stringified return value. `nil` when the method returned `void`
    /// or when `secureContent` is `true`. For scalar (non-object,
    /// non-void) returns the server fills in a generic `"Method invoked."`
    /// placeholder; the bridge surfaces that string verbatim.
    let description: String?

    /// `true` when the inspected method's return type is `void` (the
    /// server signals this via the `LOOKIN_TAG_RETURN_VALUE_VOID` marker).
    let returnedVoid: Bool

    /// Present only when the method returned an `NSObject`. Even when
    /// `secureContent` is `true` the structural metadata stays — it
    /// carries no user secret, only the object's class chain / address /
    /// `oid` — matching the redaction philosophy of `attributes.read`
    /// (string-bearing attribute values get redacted; structural
    /// metadata does not).
    let returnObject: LKMCPBridgeReturnedObject?

    /// `true` when the receiver display item is treated as carrying
    /// secure user content (see `LKMCPBridgeSecureContentDetector`). In
    /// that case `description` is redacted to `nil` to avoid leaking
    /// passwords / OTPs into agent transcripts. `returnObject` is kept;
    /// see its doc comment for the redaction rationale.
    let secureContent: Bool
}

// MARK: - Modification

/// Wire envelope for an attribute value passed across the bridge in a
/// modification context: `kind` is the same string the read-side
/// `LKMCPBridgeAttributeEncoder` produces, `data` is its corresponding
/// JSON-friendly payload. The bridge consumes this in both directions:
/// requests carry it as the value to apply; responses echo it as
/// `requestedValue` so agents can compare against `effectiveAttribute`
/// without having to reconstruct the wire form.
struct LKMCPBridgeAttributeValueWire: Sendable, Codable {
    let kind: String
    let data: LKMCPBridgeJSONValue?
}

/// Result envelope for `attribute.modify`. Echoes the requested value,
/// surfaces the post-layout effective attribute, and includes the
/// host-visible side-effect snapshot (frame / bounds / hidden / alpha)
/// that the server captures in `DisplayItemDetail` after the
/// setter has run and a layout pass has completed.
struct LKMCPBridgeModificationResult: Sendable, Codable {
    /// Echo of the attribute identifier the agent asked to modify.
    let attributeIdentifier: String

    /// Echo of the wire `value` payload the agent supplied. Lets the
    /// agent diff against `effectiveAttribute.value` without re-deriving
    /// the wire shape from the encoded result.
    let requestedValue: LKMCPBridgeAttributeValueWire

    /// Fully-encoded attribute as the host saw it AFTER the setter ran
    /// and a layout pass settled. May differ from the request (autolayout
    /// adjusts frames; some setters round to pixel boundaries; some
    /// setters are no-ops). When `secureContent` is `true` the value
    /// here is redacted in the same way `read_attributes` redacts.
    let effectiveAttribute: LKMCPBridgeAttribute

    /// `true` when the effective wire value is structurally equal to
    /// the requested wire value. Strict equality — no float epsilon.
    /// `false` means the inspected app's layout pass / setter / autolayout
    /// constraints rejected or adjusted the requested value; agents
    /// should surface this to the user as a real signal.
    let effectiveMatchesRequested: Bool

    /// Post-modification frame snapshot. Often differs from the previous
    /// `get_hierarchy` result when the modification touched layout.
    let frame: LKMCPBridgeRect

    /// Post-modification bounds snapshot.
    let bounds: LKMCPBridgeRect

    /// Post-modification `isHidden` snapshot.
    let isHidden: Bool

    /// Post-modification composite alpha snapshot in `0.0...1.0`.
    let alpha: Double

    /// Same secure-content semantics as `read_attributes`: when `true`,
    /// any string-bearing `effectiveAttribute.value` fields are redacted.
    let secureContent: Bool
}

// MARK: - Details prefetch

/// One per-view entry in a `details.read` response. The shape is
/// deliberately a subset of `attributes.read`'s envelope: agents that
/// already consume `attributes.read` can reuse their `groups` parsing
/// code unchanged. The `secureContent` flag is per-item because a
/// single batch may contain both regular and secure-input views.
struct LKMCPBridgeViewDetail: Sendable, Codable {
    let objectIdentifier: String
    let groups: [LKMCPBridgeAttributeGroup]
    let secureContent: Bool
}

/// Envelope for `details.read`. Successful per-view detail goes in
/// `details`. Object identifiers that were missing from the client
/// hierarchy or returned `failureCode = -1` from the server fall
/// into `failedIdentifiers` — the call as a whole still succeeds so
/// agents can act on whatever did come back.
struct LKMCPBridgeDetailsReadResult: Sendable, Codable {
    let details: [LKMCPBridgeViewDetail]
    let failedIdentifiers: [String]
}

// MARK: - Screenshot

/// Result envelope for `screenshot.read`. Carries the image inline as
/// base64 rather than as a URI: the bridge has no static file server,
/// and the consuming MCP shim needs the bytes anyway to build an image
/// content block.
struct LKMCPBridgeScreenshotResult: Sendable, Codable {
    /// The object actually captured. Differs from the request when the
    /// caller omitted `objectIdentifier` and the service resolved the
    /// key window on their behalf.
    let objectIdentifier: String

    /// `solo` (view alone, subviews hidden) or `group` (view plus its
    /// whole subtree). Echoed so callers that relied on the default can
    /// see which one they got.
    let mode: String

    /// Base64-encoded image bytes.
    let imageData: String

    /// IANA media type for `imageData`. Always `image/png` today.
    let mimeType: String

    /// Pixel dimensions of the returned image, after any downscale.
    let pixelWidth: Int
    let pixelHeight: Int

    /// Pixel dimensions as captured, before any downscale. Equal to
    /// `pixelWidth` / `pixelHeight` when no downscale was applied.
    /// Agents can compare the two to know whether fine detail was lost
    /// and re-request with a larger `maximumPixelDimension`.
    let sourcePixelWidth: Int
    let sourcePixelHeight: Int

    /// Decoded (pre-base64) size of `imageData`, in bytes.
    let byteCount: Int

    /// Frame of the captured view in the hierarchy's root coordinate
    /// space, in points. Lets an agent map pixel coordinates in the
    /// image back onto the coordinates `hierarchy.read` reports.
    let frame: LKMCPBridgeRect

    /// `true` when the image came from the host's existing cache rather
    /// than a fresh render in the target app. Cached images can lag
    /// behind the live UI — notably right after `attribute.modify`.
    let servedFromCache: Bool

    /// `true` when the captured region includes a view the secure-content
    /// detector flags (for `group`, anywhere in the subtree).
    ///
    /// Screenshots are NOT redacted: unlike attribute strings, there is
    /// no way to blank a value without destroying the picture. This flag
    /// is the honest signal that the returned pixels may show sensitive
    /// user input, so the caller can decide whether to keep it.
    let containsSecureContent: Bool
}

// MARK: - Hierarchy search

/// One hit in a `hierarchy.find` response.
///
/// Carries enough context to act on the result without a follow-up
/// `hierarchy.read`: the identifier for subsequent calls, the ancestor
/// chain for orientation, and the fields that matched so the caller can
/// tell a class-name hit apart from an incidental substring in a subtitle.
struct LKMCPBridgeSearchMatch: Sendable, Codable {
    let objectIdentifier: String

    /// Leaf Objective-C class name, matching `hierarchy.read`'s field of
    /// the same name.
    let className: String

    /// The host inspector's row label. `null` when the secure-content
    /// detector flagged this view.
    let title: String?

    /// The host inspector's secondary label. `null` when the
    /// secure-content detector flagged this view.
    let subtitle: String?

    /// Frame in the hierarchy's root coordinate space, in points.
    let frame: LKMCPBridgeRect

    let isHidden: Bool
    let alpha: Double

    /// Nesting level, `0` for a window / scene root. Equal to the number
    /// of entries in `ancestorObjectIdentifiers`.
    let depth: Int

    /// Ancestor identifiers ordered root first, parent last. Feed any of
    /// them to `hierarchy.read`'s `rootObjectIdentifier` to inspect the
    /// surrounding subtree.
    let ancestorObjectIdentifiers: [String]

    /// Human-readable ancestry, e.g. `NSWindow > NSView > NSButton`,
    /// ending with this node. For orientation in a log or a reply; do not
    /// parse it — use `ancestorObjectIdentifiers`.
    let pathDescription: String

    /// Which searchable fields contained the query, in canonical order.
    /// Never empty for a returned match.
    let matchedFields: [String]

    /// `true` when the secure-content detector flagged this view, which
    /// is also why `title` / `subtitle` may be `null`.
    let secureContent: Bool
}

/// Envelope for `hierarchy.find`.
///
/// `totalMatchCount` counts every hit in the searched scope, so a caller
/// that receives `truncated: true` knows how much it is not seeing and
/// can narrow the query rather than paginate blindly.
struct LKMCPBridgeSearchResult: Sendable, Codable {
    let matches: [LKMCPBridgeSearchMatch]

    /// Hits found before `limit` was applied.
    let totalMatchCount: Int

    /// `true` when `matches.count < totalMatchCount`.
    let truncated: Bool

    /// Nodes examined. Equals the whole tree unless the caller scoped the
    /// search with `rootObjectIdentifier`.
    let searchedNodeCount: Int

    /// The fields actually searched, after defaulting.
    let searchedFields: [String]
}

// MARK: - Selector listing

/// Envelope for `selectors.list`.
///
/// The server walks the entire class chain up to `NSObject`, so
/// `totalCount` on a UIKit / AppKit view runs into four digits. Callers
/// are expected to narrow with `nameFilter` rather than raise `limit`.
struct LKMCPBridgeSelectorListResult: Sendable, Codable {
    /// The class actually queried. Differs from the request when the
    /// caller passed `objectIdentifier` and the service resolved the leaf
    /// class on their behalf.
    let className: String

    /// Selector names in the order the target app produced them: by
    /// class, most-derived first. Not sorted alphabetically — position is
    /// the only signal about where a method came from. Coarse rather than
    /// exact: within a single class the order is arbitrary.
    let selectors: [String]

    /// Matching selectors before `limit` was applied.
    let totalCount: Int

    /// `true` when `selectors.count < totalCount`.
    let truncated: Bool

    /// `true` when selectors taking arguments were included. When
    /// `false`, every entry is callable through `invoke.method`.
    let includesArguments: Bool

    /// The resolved object's full class chain, present only when the
    /// caller passed `objectIdentifier`. Tells the caller which classes
    /// the flat `selectors` list spans.
    let classChain: [String]?
}

// MARK: - Hierarchy refresh

/// Envelope for `hierarchy.refresh`.
///
/// The interesting field is `previousNodeCount`: LookInside only learns the
/// target's UI changed when someone asks it to look, so a caller has no way
/// to tell a refresh that found a whole new screen from one that found the
/// same screen it already had. Reporting both counts answers that without a
/// follow-up `hierarchy.read`.
struct LKMCPBridgeRefreshResult: Sendable, Codable {
    /// Echo of the requested target.
    let targetIdentifier: String

    /// Top-level windows / scenes after the reload. Usable directly as
    /// `hierarchy.read`'s `rootObjectIdentifier`.
    let rootObjectIdentifiers: [String]

    /// Nodes in the tree after the reload.
    let nodeCount: Int

    /// Nodes in the tree before it. Equal counts do not prove the UI is
    /// unchanged — the same number of views can be an entirely different
    /// screen — but a difference does prove it changed.
    let previousNodeCount: Int

    /// Wall-clock cost of the round-trip, so callers can judge how
    /// expensive repeating this would be.
    let durationMilliseconds: Int
}
