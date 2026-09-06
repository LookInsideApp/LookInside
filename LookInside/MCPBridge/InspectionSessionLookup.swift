// Session lookup shared by the graphical application's MCP bridge routes.
// Cached queries remain independent of NSDocument and window construction.

import AppKit
import Foundation
import LookInsideInspectionCore

@MainActor
enum InspectionSessionLookup {
    static func enumerateSessions() -> [InspectionSession] {
        InspectionSessionRegistry.shared().sessions
    }

    static func findSession(targetIdentifier: String) -> InspectionSession? {
        guard let identifierValue = UInt(targetIdentifier) else { return nil }
        let matches = enumerateSessions().filter { session in
            session.inspectableApp.appInfo?.appInfoIdentifier == identifierValue
        }
        // The legacy bridge identifier does not contain a transport component.
        // Refuse an ambiguous match instead of selecting an arbitrary device.
        return matches.count == 1 ? matches.first : nil
    }

    static func errorPayload(for error: NSError, operation: String) -> LKMCPBridgeErrorPayload? {
        guard error.domain == InspectionSessionErrorDomain else { return nil }
        let suffix: String
        switch error.code {
        case InspectionSessionErrorCode.notReady.rawValue: suffix = "notReady"
        case InspectionSessionErrorCode.staleConnection.rawValue: suffix = "disconnected"
        case InspectionSessionErrorCode.staleHierarchy.rawValue: suffix = "staleHierarchy"
        case InspectionSessionErrorCode.executionUnknown.rawValue: suffix = "executionUnknown"
        default: suffix = "internalError"
        }
        return LKMCPBridgeErrorPayload(code: "\(operation).\(suffix)", message: error.localizedDescription)
    }

    /// Breadth-first search across the supplied root display items for an
    /// item whose wire `objectIdentifier` matches `identifier`. The wire
    /// form is the hex-encoded `LookinObject.oid`, prefixed with `0x`
    /// (e.g. `0x600000abc123`).
    static func findDisplayItem(
        amongRoots roots: [LookinDisplayItem],
        matchingObjectIdentifier identifier: String
    ) -> LookinDisplayItem? {
        var queue: [LookinDisplayItem] = roots
        while queue.isEmpty == false {
            let current = queue.removeFirst()
            if objectIdentifierString(for: current) == identifier {
                return current
            }
            if let subitems = current.subitems {
                queue.append(contentsOf: subitems)
            }
        }
        return nil
    }

    static func topLevelDisplayItems(in session: InspectionSession) -> [LookinDisplayItem] {
        session.rawHierarchyInfo?.displayItems ?? []
    }

    /// Canonical hex-encoded `objectIdentifier` string for a display item.
    /// Stays in sync with the form returned by `hierarchy.read` so
    /// callers can round-trip identifiers across bridge methods.
    static func objectIdentifierString(for item: LookinDisplayItem) -> String {
        let oid = item.displayingObject()?.oid ?? 0
        return String(format: "0x%lx", oid)
    }

    /// The item's rectangle in the root coordinate space.
    ///
    /// `LookinDisplayItem.frame` is *parent*-relative -- `calculateFrameToRoot`
    /// exists precisely because composing it up the tree is non-trivial (it
    /// has to subtract each ancestor's `bounds` origin and flip for AppKit
    /// superitems). The bridge reports root-space rectangles so an agent can
    /// line a node up against a screenshot without walking the tree itself.
    ///
    /// Falls back to the raw frame when the item has no usable geometry:
    /// `hasValidFrameToRoot` is a check on `frame` itself, so in that case
    /// both values are equally meaningless and the raw one at least matches
    /// what the host inspector displays.
    static func rootSpaceFrame(for item: LookinDisplayItem) -> CGRect {
        return item.hasValidFrameToRoot() ? item.calculateFrameToRoot() : item.frame
    }
}
