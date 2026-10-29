// MCPBridgeLiveDocumentLookup.swift
//
// Shared lookup helpers that translate the bridge wire identifiers
// (`targetIdentifier`, `objectIdentifier`) into the host's live runtime
// objects (`LiveDocument`, `DisplayItem`). The services share one canonical
// implementation for native and virtual node handles and decimal target IDs.
//
// All entry points are `@MainActor`: `NSDocumentController` and
// `LiveDocument` require main-thread isolation, and the bridge
// connection handlers already hop here before invoking lookup.

import AppKit
import Foundation

@MainActor
enum MCPBridgeLiveDocumentLookup {
    /// Enumerates every currently-open `LiveDocument` known to the
    /// host. Static (archived `.lookin`) documents are excluded because
    /// they have no attached app to inspect / invoke against.
    static func enumerateLiveDocuments() -> [LiveDocument] {
        let allDocuments = NSDocumentController.shared.documents
        return allDocuments.compactMap { $0 as? LiveDocument }
    }

    /// Resolves a wire `targetIdentifier` (decimal string form of
    /// `InspectedAppInfo.appInfoIdentifier`) to the matching
    /// `LiveDocument`. Returns `nil` when the string is not a valid
    /// unsigned integer or no open live document carries that
    /// `appInfoIdentifier`.
    static func findLiveDocument(targetIdentifier: String) -> LiveDocument? {
        guard let identifierValue = UInt(targetIdentifier) else { return nil }
        return enumerateLiveDocuments().first { document in
            document.inspectableApp.appInfo?.appInfoIdentifier == identifierValue
        }
    }

    /// Breadth-first search across the supplied root display items for an
    /// item whose wire `objectIdentifier` matches `identifier`. The wire
    /// form is an opaque native or virtual node handle returned by this bridge.
    static func findDisplayItem(
        amongRoots roots: [DisplayItem],
        matchingObjectIdentifier identifier: String
    ) -> DisplayItem? {
        MCPBridgeDisplayItemAccess.find(in: roots, identifier: identifier)
    }

    /// Top-level display items (windows / scenes) inside a live document.
    /// These are the seed points for `findDisplayItem(amongRoots:matchingObjectIdentifier:)`
    /// when the caller didn't pre-narrow the search space.
    static func topLevelDisplayItems(in document: LiveDocument) -> [DisplayItem] {
        guard let dataSource = document.hierarchyDataSource,
              let flatItems = dataSource.rawFlatItems
        else { return [] }
        // Top-level items (UIWindow / NSWindow) report indentLevel == 0;
        // every nested view has indentLevel >= 1. We avoid `superItem`
        // here because the Objective-C importer renames it into a Swift
        // keyword collision.
        return flatItems.filter { $0.indentLevel() == 0 }
    }

    /// Canonical `objectIdentifier` for native and virtual display items.
    /// Stays in sync with the form returned by `hierarchy.read` so
    /// callers can round-trip identifiers across bridge methods.
    static func objectIdentifierString(for item: DisplayItem) -> String {
        MCPBridgeDisplayItemAccess.objectIdentifier(for: item)
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
        item.hasValidFrameToRoot() ? item.calculateFrameToRoot() : item.frame
    }
}
