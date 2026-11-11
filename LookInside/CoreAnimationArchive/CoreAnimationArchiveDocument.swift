// CoreAnimationArchiveDocument.swift
//
// The document type for Core Animation archives (`.caar`), and the import
// behind it.
//
// Like the `.viewhierarchy` document it subclasses `ArchiveDocument`, so the
// whole reader — window, hierarchy, preview, dashboard — is reused as is:
// once the import lands, the document holds an ordinary `HierarchyFile`.
// And like it, `read(from:ofType:)` only reads the file and starts the import
// in the background, so the window opens at once on its placeholder;
// rendering a whole window's layers is not work for the main thread.
//
// Unlike it, nothing is kept after the import. An archive holds layers and no
// views, so the show-backing-layers toggle has no other shape to rebuild.

import AppKit
import Foundation

enum CoreAnimationArchiveImporter {
    /// Decodes, renders and converts an archive.
    ///
    /// Synchronous and not cheap; run it off the main thread, and on one
    /// thread, because rendering detaches each layer's sublayers while it
    /// draws the layer alone. `isCancelled` is polled between phases and once
    /// per rendered layer; once it answers true the import throws
    /// `CancellationError`.
    static func importingHierarchyFile(
        from data: Data,
        fileName: String,
        isCancelled: () -> Bool = { false }
    ) throws -> HierarchyFile {
        let contents = try CoreAnimationArchive.decodingContents(of: data)
        if isCancelled() {
            throw CancellationError()
        }
        let tree = CoreAnimationArchiveLayerTree(contents: contents)
        let screenshots = try CoreAnimationArchivePixelRecovery.recovering(from: tree, isCancelled: isCancelled)
        if isCancelled() {
            throw CancellationError()
        }
        let capture = CoreAnimationArchiveCapture(
            tree: tree,
            screenshots: screenshots,
            origin: CoreAnimationArchiveOrigin(fileName: fileName)
        )
        return CoreAnimationArchiveConverter.makingHierarchyFile(from: capture)
    }
}

@objc(LKCoreAnimationArchiveDocument)
final class CoreAnimationArchiveDocument: ArchiveDocument {
    private var importTask: Task<Void, Never>?

    /// Reads the file and starts the import, returning before the import
    /// finishes so the window can open on its placeholder.
    ///
    /// The file is read here rather than in the task so that a file that
    /// cannot be read fails the open the ordinary way, before any window.
    override func read(from url: URL, ofType _: String) throws {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        let fileName = url.lastPathComponent
        importTask?.cancel()
        importTask = Task.detached(priority: .userInitiated) { [weak self] in
            let outcome: Result<HierarchyFile, Error>
            do {
                outcome = try .success(CoreAnimationArchiveImporter.importingHierarchyFile(from: data, fileName: fileName) {
                    Task.isCancelled
                })
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
        super.close()
    }

    /// The task has to be created where `close()` can cancel it, on the main
    /// thread; the superclass's concurrent path would call `read` elsewhere.
    override class func canConcurrentlyReadDocuments(ofType _: String) -> Bool {
        false
    }

    @MainActor
    private func finishingImport(with outcome: Result<HierarchyFile, Error>) {
        importTask = nil
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
