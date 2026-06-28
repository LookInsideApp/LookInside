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
