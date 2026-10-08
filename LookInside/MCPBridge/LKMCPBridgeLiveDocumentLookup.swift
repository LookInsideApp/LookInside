// LKMCPBridgeLiveDocumentLookup.swift
//
// Shared lookup helpers that translate the bridge wire identifiers
// (`targetIdentifier`, `objectIdentifier`) into the host's live runtime
// objects (`LookinLiveDocument`, `DisplayItem`). Both the inspection
// service (read-only queries) and the invocation service (round-trips to
// the server over the connection channel) share this surface so the wire shape — hex
// `oid` strings, decimal `appInfoIdentifier` strings — stays one
// canonical implementation.
//
// All entry points are `@MainActor`: `NSDocumentController` and
// `LookinLiveDocument` require main-thread isolation, and the bridge
// connection handlers already hop here before invoking lookup.

import AppKit
import Foundation

@MainActor
enum LKMCPBridgeLiveDocumentLookup {
    /// Enumerates every currently-open `LookinLiveDocument` known to the
    /// host. Static (archived `.lookin`) documents are excluded because
    /// they have no attached app to inspect / invoke against.
    static func enumerateLiveDocuments() -> [LookinLiveDocument] {
        let allDocuments = NSDocumentController.shared.documents
        return allDocuments.compactMap { $0 as? LookinLiveDocument }
    }

    /// Resolves a wire `targetIdentifier` (decimal string form of
    /// `InspectedAppInfo.appInfoIdentifier`) to the matching
    /// `LookinLiveDocument`. Returns `nil` when the string is not a valid
    /// unsigned integer or no open live document carries that
    /// `appInfoIdentifier`.
    static func findLiveDocument(targetIdentifier: String) -> LookinLiveDocument? {
        guard let identifierValue = UInt(targetIdentifier) else { return nil }
        return enumerateLiveDocuments().first { document in
            document.inspectableApp.appInfo?.appInfoIdentifier == identifierValue
        }
    }

    /// Breadth-first search across the supplied root display items for an
    /// item whose wire `objectIdentifier` matches `identifier`. The wire
    /// form is the hex-encoded `InspectedObject.oid`, prefixed with `0x`
    /// (e.g. `0x600000abc123`).
    static func findDisplayItem(
        amongRoots roots: [DisplayItem],
        matchingObjectIdentifier identifier: String
    ) -> DisplayItem? {
        var queue: [DisplayItem] = roots
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

    /// Top-level display items (windows / scenes) inside a live document.
    /// These are the seed points for `findDisplayItem(amongRoots:matchingObjectIdentifier:)`
    /// when the caller didn't pre-narrow the search space.
    static func topLevelDisplayItems(in document: LookinLiveDocument) -> [DisplayItem] {
        guard let dataSource = document.hierarchyDataSource,
              let flatItems = dataSource.rawFlatItems
        else { return [] }
        // Top-level items (UIWindow / NSWindow) report indentLevel == 0;
        // every nested view has indentLevel >= 1. We avoid `superItem`
        // here because the Objective-C importer renames it into a Swift
        // keyword collision.
        return flatItems.filter { $0.indentLevel() == 0 }
    }

    /// Canonical hex-encoded `objectIdentifier` string for a display item.
    /// Stays in sync with the form returned by `hierarchy.read` so
    /// callers can round-trip identifiers across bridge methods.
    static func objectIdentifierString(for item: DisplayItem) -> String {
        let oid = item.displayingObject()?.oid ?? 0
        return String(format: "0x%lx", oid)
    }

    /// The item's rectangle in the root coordinate space.
    ///
    /// `DisplayItem.frame` is *parent*-relative -- `calculateFrameToRoot`
    /// exists precisely because composing it up the tree is non-trivial (it
    /// has to subtract each ancestor's `bounds` origin and flip for AppKit
    /// superitems). The bridge reports root-space rectangles so an agent can
    /// line a node up against a screenshot without walking the tree itself.
    ///
    /// Falls back to the raw frame when the item has no usable geometry:
    /// `hasValidFrameToRoot` is a check on `frame` itself, so in that case
    /// both values are equally meaningless and the raw one at least matches
    /// what the host inspector displays.
    static func rootSpaceFrame(for item: DisplayItem) -> CGRect {
        return item.hasValidFrameToRoot() ? item.calculateFrameToRoot() : item.frame
    }
}
