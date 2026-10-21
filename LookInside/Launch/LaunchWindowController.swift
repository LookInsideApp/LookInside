//
//  LaunchWindowController.swift
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

import AppKit
import UIFoundationAppKit
import UIFoundationToolbox

/// The launch window: the inspectable apps by device, the recent documents,
/// and the ways to start an inspection in its toolbar.
final class LaunchWindowController: WindowController, NSWindowDelegate {
    private static let defaultContentSize = NSSize(width: 820, height: 520)
    private static let minimumContentSize = NSSize(width: 620, height: 400)
    private static let frameAutosaveName = "LaunchWindow"

    private enum ToolbarIdentifier {
        static let attachToRunningApp = NSToolbarItem.Identifier("LaunchWindow.attachToRunningApp")
        static let attachToAppOnDevice = NSToolbarItem.Identifier("LaunchWindow.attachToAppOnDevice")
        static let openFile = NSToolbarItem.Identifier("LaunchWindow.openFile")
    }

    let launchViewController: LaunchViewController

    /// - Parameter autoEnterOnInitialReload: whether the first scan opens
    ///   the only app it finds by itself.
    init(autoEnterOnInitialReload: Bool) {
        let window = AppWindow(
            contentRect: NSRect(origin: .zero, size: Self.defaultContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.title = NSLocalizedString("New Inspection", comment: "Title of the launch window")
        window.titleVisibility = .hidden
        window.toolbarStyle = .unified
        window.contentMinSize = Self.minimumContentSize
        window.isReleasedWhenClosed = false

        launchViewController = LaunchViewController(autoEnterOnInitialReload: autoEnterOnInitialReload)
        super.init(window: window)
        window.delegate = self
        contentViewController = launchViewController
        window.toolbar = makeToolbar()

        // The content view controller sized the window to its views; put
        // back the default size, then let a saved frame replace it.
        window.setContentSize(Self.defaultContentSize)
        window.center()
        window.setFrameAutosaveName(Self.frameAutosaveName)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        launchViewController.startScanning()
    }

    private func makeToolbar() -> NSToolbar {
        let attachToRunningAppTitle = NSLocalizedString("Attach to Running App…", comment: "")
        let attachToAppOnDeviceTitle = NSLocalizedString("Attach to App on Device…", comment: "")
        let openFileTitle = NSLocalizedString("Open File…", comment: "Launch window toolbar button that opens a .lookin or .viewhierarchy file")
        let toolbar = NSToolbar("LaunchWindowToolbar", allowsUserCustomization: false) {
            NSToolbar.box.sidebarTrackingSeparator
            NSToolbar.box.flexibleSpace
            Self.makeToolbarButton(
                ToolbarIdentifier.attachToRunningApp,
                title: attachToRunningAppTitle,
                symbolName: "macwindow.badge.plus",
                target: self,
                action: #selector(handleAttachToRunningApp(_:))
            )
            Self.makeToolbarButton(
                ToolbarIdentifier.attachToAppOnDevice,
                title: attachToAppOnDeviceTitle,
                symbolName: "iphone.badge.plus",
                target: self,
                action: #selector(handleAttachToAppOnDevice(_:))
            )
            Self.makeToolbarButton(
                ToolbarIdentifier.openFile,
                title: openFileTitle,
                symbolName: "folder",
                target: self,
                action: #selector(handleOpenFile(_:))
            )
        }
        toolbar.displayMode = .iconOnly
        return toolbar
    }

    private static func makeToolbarButton(
        _ identifier: NSToolbarItem.Identifier,
        title: String,
        symbolName: String,
        target: AnyObject,
        action: Selector
    ) -> NSToolbar.Button {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) ?? NSImage()
        let overflowMenuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        overflowMenuItem.target = target
        return NSToolbar.Button(identifier, title: title, image: image)
            .label(title)
            .toolTip(title)
            .menuFormRepresentation(overflowMenuItem)
            .target(target, action: action)
    }

    // MARK: - Actions

    @objc private func handleAttachToRunningApp(_: Any?) {
        launchViewController.attachToRunningApp()
    }

    @objc private func handleAttachToAppOnDevice(_: Any?) {
        launchViewController.attachToAppOnDevice()
    }

    @objc private func handleOpenFile(_: Any?) {
        launchViewController.openFile()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_: Notification) {
        launchViewController.stopScanning()
    }
}
