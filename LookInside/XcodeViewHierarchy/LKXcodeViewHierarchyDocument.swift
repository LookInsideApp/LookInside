// LKXcodeViewHierarchyDocument.swift
//
// The document type for Xcode-exported `.viewhierarchy` captures, and the
// import pipeline behind it.
//
// It subclasses `LookinArchiveDocument` rather than `NSDocument` directly so
// that the entire reader — window controller, hierarchy tree, preview,
// dashboard — is reused untouched. Once the import lands, the document holds
// an ordinary `LookinHierarchyFile`, indistinguishable from one that came out
// of a `.lookin` archive, and everything downstream stays unaware that Xcode
// produced it.
//
// Reading is split in two. `read(from:ofType:)` only checks that the URL is a
// capture and starts the import in the background, so the window opens at
// once on a placeholder; a large AppKit window takes tens of seconds to
// import, most of it rendering the recovered layer trees, and none of that
// belongs on the main thread. The window controller observes `hierarchyFile`
// and builds the reader in place when the import finishes.
//
// The import itself is split the same way: decoding and rendering produce an
// `LKXcodeViewHierarchyImportedCapture`, which the document keeps; shaping it
// into a tree is cheap and is redone whenever the window's show-backing-layers
// toggle flips, the way a live session reloads its hierarchy for that toggle.

import AppKit
import Foundation

/// A capture decoded and rendered, but not yet shaped into a tree: what the
/// document keeps so the tree can be rebuilt for the other setting of the
/// show-backing-layers toggle without decoding or rendering again.
struct LKXcodeViewHierarchyImportedCapture {
    let bundle: LKXcodeViewHierarchyBundle
    let screenshots: LKXcodeViewHierarchyScreenshots
}

enum LKXcodeViewHierarchyImporter {
    /// Reads a capture and recovers its pixels: the expensive half.
    ///
    /// Synchronous and not cheap; run it off the main thread. It must stay on
    /// one thread because pixel recovery mutates the decoded layer trees while
    /// rendering. `isCancelled` is polled between phases and once per rendered
    /// layer; once it answers true the import throws `CancellationError`.
    static func importingCapture(
        at url: URL,
        isCancelled: () -> Bool = { false }
    ) throws -> LKXcodeViewHierarchyImportedCapture {
        let bundle = try LKXcodeViewHierarchyBundleReader.reading(contentsOf: url)
        if isCancelled() {
            throw CancellationError()
        }
        let screenshots = LKXcodeViewHierarchyPixelRecovery.recovering(from: bundle.graph, isCancelled: isCancelled)
        if isCancelled() {
            throw CancellationError()
        }
        return LKXcodeViewHierarchyImportedCapture(bundle: bundle, screenshots: screenshots)
    }

    /// Shapes an imported capture into the inspector's model: the cheap half,
    /// repeated whenever the backing-layer toggle flips.
    static func makingHierarchyFile(
        from capture: LKXcodeViewHierarchyImportedCapture,
        showingBackingLayers: Bool
    ) throws -> LookinHierarchyFile {
        try LKXcodeViewHierarchyConverter.makingHierarchyFile(
            from: capture.bundle, screenshots: capture.screenshots, showingBackingLayers: showingBackingLayers
        )
    }

    /// Both halves in one go.
    static func importingHierarchyFile(
        at url: URL,
        showingBackingLayers: Bool = false,
        isCancelled: () -> Bool = { false }
    ) throws -> LookinHierarchyFile {
        let capture = try importingCapture(at: url, isCancelled: isCancelled)
        if isCancelled() {
            throw CancellationError()
        }
        return try makingHierarchyFile(from: capture, showingBackingLayers: showingBackingLayers)
    }
}

@objc(LKXcodeViewHierarchyDocument)
final class LKXcodeViewHierarchyDocument: LookinArchiveDocument {
    private var importTask: Task<Void, Never>?
    private var rebuildTask: Task<Void, Never>?
    /// Kept for the document's lifetime so the tree can be rebuilt when the
    /// show-backing-layers toggle flips; the layer archives themselves are
    /// not kept — the rendered images are all a rebuild needs.
    private var importedCapture: LKXcodeViewHierarchyImportedCapture?

    /// Validates the package and starts the import, returning before the
    /// import finishes so the window can open on its placeholder.
    override func read(from url: URL, ofType _: String) throws {
        try LKXcodeViewHierarchyBundleReader.validatingBundle(at: url)
        importTask?.cancel()
        importTask = Task.detached(priority: .userInitiated) { [weak self] in
            let outcome: Result<LKXcodeViewHierarchyImportedCapture, Error>
            do {
                outcome = try .success(LKXcodeViewHierarchyImporter.importingCapture(at: url) { Task.isCancelled })
            } catch {
                outcome = .failure(error)
            }
            // A closed document has nothing to show and no window to complain on.
            guard !Task.isCancelled, let document = self else { return }
            await MainActor.run { document.finishingImport(with: outcome) }
        }
    }

    override func close() {
        importTask?.cancel()
        importTask = nil
        rebuildTask?.cancel()
        rebuildTask = nil
        super.close()
    }

    override func canRebuildHierarchyFile() -> Bool {
        importedCapture != nil
    }

    /// Shapes the kept capture into a new tree off the main thread and hands
    /// it to the window through `hierarchyFile`. A flip that arrives while a
    /// rebuild is still running supersedes it.
    override func rebuildHierarchyFile(showingBackingLayers: Bool) {
        guard let importedCapture else { return }
        rebuildTask?.cancel()
        rebuildTask = Task.detached(priority: .userInitiated) { [weak self] in
            let outcome: Result<LookinHierarchyFile, Error>
            do {
                outcome = try .success(LKXcodeViewHierarchyImporter.makingHierarchyFile(
                    from: importedCapture, showingBackingLayers: showingBackingLayers
                ))
            } catch {
                outcome = .failure(error)
            }
            guard !Task.isCancelled, let document = self else { return }
            await MainActor.run { document.finishingRebuild(with: outcome) }
        }
    }

    /// The window's own preference set decides; a rebuild is only ever asked
    /// for through it, and before it exists the persisted default applies.
    @MainActor
    private var showsBackingLayersPreference: Bool {
        if let windowController = windowControllers.first as? LKReadWindowController {
            return windowController.preferenceManager.showBackingLayers.currentBOOLValue
        }
        return LKPreferenceManager.shared.showBackingLayers.currentBOOLValue
    }

    /// The task has to be created where `close()` can cancel it, on the
    /// main thread; the superclass's concurrent path would call `read` elsewhere.
    override class func canConcurrentlyReadDocuments(ofType _: String) -> Bool {
        false
    }

    @MainActor
    private func finishingImport(with outcome: Result<LKXcodeViewHierarchyImportedCapture, Error>) {
        importTask = nil
        switch outcome {
        case let .success(capture):
            importedCapture = capture
            rebuildHierarchyFile(showingBackingLayers: showsBackingLayersPreference)
        case let .failure(error):
            presentingFailure(error)
        }
    }

    @MainActor
    private func finishingRebuild(with outcome: Result<LookinHierarchyFile, Error>) {
        rebuildTask = nil
        switch outcome {
        case let .success(file):
            // The window controller observes this and builds the reader in place.
            hierarchyFile = file
        case let .failure(error):
            presentingFailure(error)
        }
    }

    @MainActor
    private func presentingFailure(_ error: Error) {
        let alert = NSAlert(error: error)
        if let window = windowForSheet {
            alert.beginSheetModal(for: window) { [weak self] _ in self?.close() }
        } else {
            close()
        }
    }
}
