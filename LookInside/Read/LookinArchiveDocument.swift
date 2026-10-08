//
//  LookinArchiveDocument.swift
//  LookInside
//
//  The NSDocument for a `.lookin` hierarchy archive. Archives are read-only
//  snapshots; opening them through NSDocumentController gives Recent
//  Documents, Open Recent and proxy-icon dragging. Info.plist names this
//  class for the `com.lookin.lookin` type, so its Objective-C name must not
//  change.
//

import AppKit

@objc(LookinArchiveDocument)
class LookinArchiveDocument: NSDocument {
    /// The archive's hierarchy. The window controller observes it (KVO) and
    /// builds a reader for every file assigned.
    @objc dynamic var hierarchyFile: HierarchyFile?

    override class var autosavesInPlace: Bool {
        false
    }

    override class var preservesVersions: Bool {
        false
    }

    override class var usesUbiquitousStorage: Bool {
        false
    }

    override func writableTypes(for _: NSDocument.SaveOperationType) -> [String] {
        // Archives are read-only snapshots: no Save, Save As or Duplicate.
        []
    }

    override func makeWindowControllers() {
        addWindowController(LKReadWindowController(document: self))
    }

    /// Whether the document can rebuild `hierarchyFile` for a different
    /// show-backing-layers setting. A `.lookin` archive cannot: its tree is what
    /// the server sent. An imported Xcode capture can, from the decoded capture
    /// it keeps after import.
    @objc func canRebuildHierarchyFile() -> Bool {
        false
    }

    /// Rebuilds `hierarchyFile` for the setting and assigns the new file when it
    /// is ready; the window observes the property and rebuilds its reader. A
    /// no-op unless canRebuildHierarchyFile.
    @objc(rebuildHierarchyFileShowingBackingLayers:)
    func rebuildHierarchyFile(showingBackingLayers _: Bool) {
        // An archive holds the tree the server sent; there is nothing to rebuild from.
    }

    override func data(ofType typeName: String) throws -> Data {
        guard let hierarchyFile else {
            assertionFailure("No hierarchy to save")
            throw LookinArchiveCoding.innerError
        }
        guard typeName == LookinArchiveCoding.typeIdentifier else {
            throw LookinArchiveCoding.innerError
        }
        return try LookinArchiveCoding.data(of: hierarchyFile)
    }

    override func read(from data: Data, ofType _: String) throws {
        hierarchyFile = try LookinArchiveCoding.hierarchyFile(from: data)
    }
}
