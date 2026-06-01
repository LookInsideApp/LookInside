import Foundation
import LookinCore
#if canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#endif

/// The seam every MCP tool talks to. Implementations: `LiveLookinClient` (connects
/// to a running Debug build over Peertalk) and `FileHierarchyProvider` (reads a
/// `.lookin` snapshot file). Adding new sources later — say a recorded test fixture
/// or a stub for unit tests — means one more conformance, nothing else changes.
public protocol HierarchyProvider: AnyObject {
    /// Top-level metadata about the connected app (or the captured snapshot).
    func appInfo() throws -> LookinAppInfo

    /// Full hierarchy tree. May be expensive — callers should cache.
    func hierarchy() throws -> LookinHierarchyInfo

    /// Per-element details (screenshot + full attribute groups) for a specific oid.
    /// `nil` if the element isn't found in the current hierarchy.
    func elementDetails(oid: UInt) throws -> ElementDetails?

    /// Tells the running app to flash a highlight overlay on the element with the
    /// given oid. Best-effort — providers without a live channel may no-op.
    func highlight(oid: UInt, durationMs: Int) throws

    /// Latest screenshot of the key window. Providers that only have a snapshot
    /// return the cached image from `appInfo.screenshot`.
    func screenshot() throws -> PlatformImage?

    /// Whether the provider is connected to a live target (vs. a snapshot file).
    var isLive: Bool { get }
}

public struct ElementDetails {
    public let item: LookinDisplayItem
    public let attributeGroups: [LookinAttributesGroup]
    public let soloScreenshot: PlatformImage?

    public init(item: LookinDisplayItem,
                attributeGroups: [LookinAttributesGroup],
                soloScreenshot: PlatformImage?) {
        self.item = item
        self.attributeGroups = attributeGroups
        self.soloScreenshot = soloScreenshot
    }
}

public enum HierarchyProviderError: Error, CustomStringConvertible {
    case noTargetApp
    case timeout(requestType: UInt32)
    case transport(underlying: Error)
    case decodeFailure(reason: String)
    case unsupported(String)

    public var description: String {
        switch self {
        case .noTargetApp:
            return "No Debug build of a LookinServer-enabled app is reachable."
        case .timeout(let t):
            return "Request \(t) timed out talking to the target app."
        case .transport(let e):
            return "Peertalk transport error: \(e.localizedDescription)"
        case .decodeFailure(let r):
            return "Response decode failed: \(r)"
        case .unsupported(let s):
            return "Unsupported operation: \(s)"
        }
    }
}
