//
//  NavigationManager.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//
//  Opens the app's standalone windows: launch, settings, about, the JSON
//  viewer, and readers for `.lookin` files or in-memory hierarchies.
//

import AppKit
import UIFoundationSettingsUI

@MainActor
final class NavigationManager: NSObject, NSWindowDelegate {
    static let shared = NavigationManager()

    override private init() {
        super.init()
    }

    private(set) var launchWindowController: LaunchWindowController?

    /// Kept for the app's lifetime rather than dropped on close, so the
    /// window opens again on the page the user left it on.
    private(set) lazy var settingsWindowController = SettingsWindowController(
        configuration: SettingsConfiguration(
            title: String(localized: "Settings", comment: "Title of the Settings window."),
            // The sidebar is 20 points wider than UIFoundation's default so
            // "Private Discriminator" fits; the window grows by as much, so
            // the pages keep the default width.
            contentWidth: 735,
            sidebarWidth: 205,
            sidebarIconSize: 15
        ),
        pages: { SettingsPages.make() }
    )

    private(set) var aboutWindowController: AboutWindowController?
    private var jsonWindowController: JSONAttributeWindowController?

    /// Set by the hierarchy view from its top inset.
    var windowTitleBarHeight: CGFloat = 0

    func showLaunch() {
        showLaunch(allowingAutoEnter: false)
    }

    func showLaunch(allowingAutoEnter allowAutoEnter: Bool) {
        let controller = LaunchWindowController(autoEnterOnInitialReload: allowAutoEnter)
        launchWindowController = controller
        controller.showWindow(self)
    }

    func closeLaunch() {
        launchWindowController?.close()
        launchWindowController = nil
    }

    func showSettings() {
        settingsWindowController.showWindow(self)
    }

    func showAbout() {
        let controller = aboutWindowController ?? {
            let controller = AboutWindowController()
            controller.window?.delegate = self
            return controller
        }()
        aboutWindowController = controller
        controller.showWindow(self)
    }

    func showJSONWindow(_ json: String?) {
        let controller = jsonWindowController ?? {
            let controller = JSONAttributeWindowController()
            controller.window?.delegate = self
            return controller
        }()
        jsonWindowController = controller
        (controller.contentViewController as? JSONAttributeViewController)?.render(json: json)
        controller.showWindow(self)
    }

    /// The window controller of the key window, when it is one of ours.
    func currentKeyWindowController() -> WindowController? {
        NSApplication.shared.keyWindow?.windowController as? WindowController
    }

    /// Opens the file through `NSDocumentController`, so `.lookin` archives
    /// get Recent Documents, Open Recent, proxy icon dragging and the reuse
    /// of an already open file. Opening is asynchronous; an error is
    /// presented with `NSApp.presentError`, so this never throws.
    func showReader(withFilePath filePath: String) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        NSDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { document, _, openError in
            if document == nil, let openError {
                NSApp.presentError(openError)
            }
        }
    }

    /// Wraps an in-memory hierarchy in an untitled `ArchiveDocument`,
    /// so it gets the same document life cycle (Save As, Versions, Recent on
    /// save) as a file-backed archive, and shows its window.
    func showReader(with file: HierarchyFile?, title: String?) {
        let document = ArchiveDocument()
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
        if closingWindow == aboutWindowController?.window {
            aboutWindowController = nil
        }
        // Live and archive document windows belong to NSDocumentController,
        // and live windows save their own frame (`windowSizeNameStatic`),
        // so inspection windows need nothing here.
    }
}
