//
//  LiveDocumentController.swift
//  LookInside
//
//  The one place that opens a live document for an inspectable app: the
//  launch window, the toolbar's app picker and the debug dump all go
//  through it. Picking a different app always opens a new window; picking
//  an app whose channel already has a document brings that document's
//  window forward instead.
//

import AppKit

@MainActor
final class LiveDocumentController: NSObject {
    static let shared = LiveDocumentController()

    override private init() {
        super.init()
    }

    /// Opens a live document for `app`, or brings forward the one already
    /// open on the same channel.
    ///
    /// - Returns: the document, and whether it was already open.
    func openLiveDocument(for app: InspectableApp) -> (document: LiveDocument, alreadyOpen: Bool) {
        if let existing = liveDocument(for: app.channel) {
            existing.showWindows()
            return (existing, true)
        }
        let document = LiveDocument(inspectableApp: app)
        NSDocumentController.shared.addDocument(document)
        document.makeWindowControllers()
        document.showWindows()
        // After makeWindowControllers(), so observers can reach the data
        // source, which lives on the window controller.
        NotificationCenter.default.post(name: LiveDocument.didOpenNotification, object: document)
        return (document, false)
    }

    /// The live document whose app uses `channel`, or nil.
    func liveDocument(for channel: ServerChannel?) -> LiveDocument? {
        guard let channel else { return nil }
        return NSDocumentController.shared.documents
            .compactMap { $0 as? LiveDocument }
            .first { $0.inspectableApp.channel === channel }
    }
}
