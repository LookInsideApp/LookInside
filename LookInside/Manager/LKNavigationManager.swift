//
//  LKNavigationManager.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//
//  Opens the app's standalone windows: launch, preferences, about, the JSON
//  viewer, and readers for `.lookin` files or in-memory hierarchies.
//

import AppKit

@objc(LKNavigationManager)
@MainActor
final class LKNavigationManager: NSObject, NSWindowDelegate {
    static let shared = LKNavigationManager()

    override private init() {
        super.init()
    }

    @objc private(set) var launchWindowController: LKLaunchWindowController?

    // Read by name (KVC) by the DEBUG UI snapshots.
    @objc private(set) var preferenceWindowController: LKPreferenceWindowController?
    @objc private(set) var aboutWindowController: LKAboutWindowController?
    private var jsonWindowController: LKJSONAttributeWindowController?

    /// Set by the hierarchy view from its top inset.
    @objc var windowTitleBarHeight: CGFloat = 0

    @objc func showLaunch() {
        showLaunch(allowingAutoEnter: false)
    }

    @objc(showLaunchAllowingAutoEnter:)
    func showLaunch(allowingAutoEnter allowAutoEnter: Bool) {
        let controller = LKLaunchWindowController(autoEnterOnInitialReload: allowAutoEnter)
        launchWindowController = controller
        controller.showWindow(self)
    }

    @objc func closeLaunch() {
        launchWindowController?.close()
        launchWindowController = nil
    }

    @objc func showPreference() {
        let controller = preferenceWindowController ?? {
            let controller = LKPreferenceWindowController()
            controller.window?.delegate = self
            return controller
        }()
        preferenceWindowController = controller
        controller.showWindow(self)
    }

    @objc func showAbout() {
        let controller = aboutWindowController ?? {
            let controller = LKAboutWindowController()
            controller.window?.delegate = self
            return controller
        }()
        aboutWindowController = controller
        controller.showWindow(self)
    }

    @objc(showJsonWindow:)
    func showJSONWindow(_ json: String?) {
        let controller = jsonWindowController ?? {
            let controller = LKJSONAttributeWindowController()
            controller.window?.delegate = self
            return controller
        }()
        jsonWindowController = controller
        (controller.contentViewController as? LKJSONAttributeViewController)?.render(json: json)
        controller.showWindow(self)
    }

    /// The window controller of the key window, when it is one of ours.
    @objc func currentKeyWindowController() -> LKWindowController? {
        NSApplication.shared.keyWindow?.windowController as? LKWindowController
    }

    /// Opens the file through `NSDocumentController`, so `.lookin` archives
    /// get Recent Documents, Open Recent, proxy icon dragging and the reuse
    /// of an already open file. Opening is asynchronous; an error is
    /// presented with `NSApp.presentError`, so this never throws.
    @objc(showReaderWithFilePath:error:)
    func showReader(withFilePath filePath: String) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        NSDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { document, _, openError in
            if document == nil, let openError {
                NSApp.presentError(openError)
            }
        }
    }

    /// Wraps an in-memory hierarchy in an untitled `LookinArchiveDocument`,
    /// so it gets the same document life cycle (Save As, Versions, Recent on
    /// save) as a file-backed archive, and shows its window.
    @objc(showReaderWithHierarchyFile:title:)
    func showReader(with file: HierarchyFile?, title: String?) {
        let document = LookinArchiveDocument()
        document.hierarchyFile = file
        NSDocumentController.shared.addDocument(document)
        document.makeWindowControllers()
        document.showWindows()

        if let title, !title.isEmpty {
            document.windowControllers.first?.window?.title = title
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        let closingWindow = notification.object as? NSWindow
        if closingWindow == preferenceWindowController?.window {
            preferenceWindowController = nil
        } else if closingWindow == aboutWindowController?.window {
            aboutWindowController = nil
        }
        // Live and archive document windows belong to NSDocumentController,
        // and live windows save their own frame (`LKWindowSizeName_Static`),
        // so inspection windows need nothing here.
    }
}
