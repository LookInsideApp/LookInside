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
// Unlike it, only the file's bytes are kept after the import, mapped: the
// images are drawn again from them when the Liquid Glass setting changes what
// they leave out. An archive holds layers and no views, so the
// show-backing-layers toggle has no other shape to rebuild.

import AppKit
import Foundation
import LookInsideHostCore

enum CoreAnimationArchiveImporter {
    /// Decodes, renders and converts an archive.
    ///
    /// Synchronous and not cheap; run it off the main thread, and on one
    /// thread, because rendering detaches each layer's sublayers while it
    /// draws the layer alone. `isCancelled` is polled between phases and once
    /// per rendered layer; once it answers true the import throws
    /// `CancellationError`. `hidingSplitViewGlass` leaves the glass AppKit
    /// puts behind a split view item out of the images, as the Liquid Glass
    /// setting's Hide asks.
    static func importingHierarchyFile(
        from data: Data,
        fileName: String,
        hidingSplitViewGlass: Bool = false,
        isCancelled: () -> Bool = { false }
    ) throws -> HierarchyFile {
        let contents = try CoreAnimationArchive.decodingContents(of: data)
        if isCancelled() {
            throw CancellationError()
        }
        let tree = CoreAnimationArchiveLayerTree(contents: contents)
        let screenshots = try CoreAnimationArchivePixelRecovery.recovering(
            from: tree,
            hidingGlass: hidingSplitViewGlass ? isSplitViewBackgroundGlass : { _ in false },
            isCancelled: isCancelled
        )
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

    /// Whether a decoded layer is the glass AppKit puts behind a split view
    /// item (`PreviewGlassLayers`): a glass layer as a decoded archive shows
    /// it (`CoreAnimationArchiveGlass`), judged by the views above it the way
    /// a live session judges SwiftUI's glass layer. Both imports decode
    /// AppKit's own layers, so both judge glass this way.
    static func isSplitViewBackgroundGlass(_ layer: CALayer) -> Bool {
        guard let viewAncestorClassChains = CoreAnimationArchiveGlass.viewAncestorClassChains(ofGlassLayer: layer) else { return false }
        return PreviewGlassLayers.isSplitViewBackgroundGlass(viewAncestorClassChains: viewAncestorClassChains)
    }
}

@objc(LKCoreAnimationArchiveDocument)
final class CoreAnimationArchiveDocument: ArchiveDocument {
    private var importTask: Task<Void, Never>?
    /// The file as read, kept so the images can be drawn again when the
    /// Liquid Glass setting changes what they leave out; mapped, not copied.
    private var archiveData: Data?
    private var archiveFileName = ""

    /// Reads the file and starts the import, returning before the import
    /// finishes so the window can open on its placeholder.
    ///
    /// The file is read here rather than in the task so that a file that
    /// cannot be read fails the open the ordinary way, before any window.
    override func read(from url: URL, ofType _: String) throws {
        archiveData = try Data(contentsOf: url, options: .mappedIfSafe)
        archiveFileName = url.lastPathComponent
        startingImport(hidingSplitViewGlass: PreferenceManager.shared.glassLayerVisibility.hidesGlassDrawnByLookInside)
    }

    override func drawsImagesForGlassSetting() -> Bool {
        archiveData != nil
    }

    override func redrawingHierarchyFile(hidingSplitViewGlass: Bool) {
        startingImport(hidingSplitViewGlass: hidingSplitViewGlass)
    }

    /// Imports the file read, superseding an import still running.
    private func startingImport(hidingSplitViewGlass: Bool) {
        guard let data = archiveData else { return }
        let fileName = archiveFileName
        importTask?.cancel()
        importTask = Task.detached(priority: .userInitiated) { [weak self] in
            let outcome: Result<HierarchyFile, Error>
            do {
                outcome = try .success(CoreAnimationArchiveImporter.importingHierarchyFile(
                    from: data,
                    fileName: fileName,
                    hidingSplitViewGlass: hidingSplitViewGlass
                ) {
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
