//
//  LookinLiveDocumentController.swift
//  LookInside
//
//  The one place that opens a live document for an inspectable app: the
//  launch window, the toolbar's app picker and the debug dump all go
//  through it. Picking a different app always opens a new window; picking
//  an app whose channel already has a document brings that document's
//  window forward instead.
//

import AppKit

@objc(LookinLiveDocumentController)
@MainActor
final class LookinLiveDocumentController: NSObject {
    @objc(sharedInstance)
    static let shared = LookinLiveDocumentController()

    override private init() {
        super.init()
    }

    /// Opens a live document for `app`, or brings forward the one already
    /// open on the same channel.
    ///
    /// - Returns: the document, and whether it was already open.
    func openLiveDocument(for app: LKInspectableApp) -> (document: LookinLiveDocument, alreadyOpen: Bool) {
        if let existing = liveDocument(for: app.channel) {
            existing.showWindows()
            return (existing, true)
        }
        let document = LookinLiveDocument(inspectableApp: app)
        NSDocumentController.shared.addDocument(document)
        document.makeWindowControllers()
        document.showWindows()
        return (document, false)
    }

    /// Objective-C form of `openLiveDocument(for:)`. `completion` runs on
    /// the main thread before this returns; with a nil app it gets
    /// `LookinErr_Inner` and no document.
    @objc(openLiveDocumentForInspectableApp:completion:)
    func openLiveDocument(
        for app: LKInspectableApp?,
        completion: ((LookinLiveDocument?, Bool, NSError?) -> Void)?
    ) {
        guard let app else {
            completion?(nil, false, LKConnectionError.inner)
            return
        }
        let (document, alreadyOpen) = openLiveDocument(for: app)
        completion?(document, alreadyOpen, nil)
    }

    /// The live document whose app uses `channel`, or nil.
    @objc(liveDocumentForChannel:)
    func liveDocument(for channel: LKChannel?) -> LookinLiveDocument? {
        guard let channel else { return nil }
        return NSDocumentController.shared.documents
            .compactMap { $0 as? LookinLiveDocument }
            .first { $0.inspectableApp.channel === channel }
    }
}
