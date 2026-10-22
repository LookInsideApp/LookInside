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
        static let newInspection = NSToolbarItem.Identifier("LaunchWindow.newInspection")
        static let reload = NSToolbarItem.Identifier("LaunchWindow.reload")
    }

    let launchViewController: LaunchViewController

    init() {
        let window = AppWindow(
            contentRect: NSRect(origin: .zero, size: Self.defaultContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.title = NSLocalizedString("New Inspection", comment: "Title of the launch window")
        window.titleVisibility = .visible
        window.toolbarStyle = .unified
        window.contentMinSize = Self.minimumContentSize
        window.isReleasedWhenClosed = false

        launchViewController = LaunchViewController()
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
        let reloadTitle = NSLocalizedString("Reload", comment: "")
        let newInspectionTitle = NSLocalizedString("New Inspection", comment: "Title of the launch window")
        let newInspectionMenu = NSMenu()
        newInspectionMenu.addItem(Self.makeMenuItem(
            title: attachToRunningAppTitle,
            symbolName: "laptopcomputer",
            target: self,
            action: #selector(handleAttachToRunningApp(_:))
        ))
        newInspectionMenu.addItem(Self.makeMenuItem(
            title: attachToAppOnDeviceTitle,
            symbolName: "iphone",
            target: self,
            action: #selector(handleAttachToAppOnDevice(_:))
        ))
        newInspectionMenu.addItem(.separator())
        newInspectionMenu.addItem(Self.makeMenuItem(
            title: openFileTitle,
            symbolName: "folder",
            target: self,
            action: #selector(handleOpenFile(_:))
        ))
        // Every other way to start an inspection sits behind one + over the
        // sidebar; reloading the apps goes over the content.
        let toolbar = NSToolbar("LaunchWindowToolbar", allowsUserCustomization: false) {
            NSToolbar.box.flexibleSpace
            NSToolbar.Menu(ToolbarIdentifier.newInspection, image: Self.symbolImage("plus", description: newInspectionTitle), menu: newInspectionMenu)
                .showsIndicator(false)
                .label(newInspectionTitle)
                .toolTip(newInspectionTitle)
            NSToolbar.box.sidebarTrackingSeparator
            NSToolbar.box.flexibleSpace
            Self.makeToolbarButton(
                ToolbarIdentifier.reload,
                title: reloadTitle,
                symbolName: "arrow.clockwise",
                target: self,
                action: #selector(handleReload(_:))
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
        // Icon only: the title is the tooltip, the label in Text Only mode
        // and the overflow menu item.
        let image = symbolImage(symbolName, description: title)
        let overflowMenuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        overflowMenuItem.target = target
        return NSToolbar.Button(identifier, image: image)
            .label(title)
            .toolTip(title)
            .menuFormRepresentation(overflowMenuItem)
            .target(target, action: action)
    }

    private static func makeMenuItem(title: String, symbolName: String, target: AnyObject, action: Selector) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = target
        menuItem.image = symbolImage(symbolName, description: title)
        return menuItem
    }

    private static func symbolImage(_ symbolName: String, description: String) -> NSImage {
        NSImage(systemSymbolName: symbolName, accessibilityDescription: description) ?? NSImage()
    }

    // MARK: - Actions

    @objc private func handleAttachToRunningApp(_: Any?) {
        launchViewController.attachToRunningApp()
    }

    @objc private func handleAttachToAppOnDevice(_: Any?) {
        launchViewController.attachToAppOnDevice()
    }

    @objc private func handleReload(_: Any?) {
        launchViewController.reloadNow()
    }

    @objc private func handleOpenFile(_: Any?) {
        launchViewController.openFile()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_: Notification) {
        launchViewController.stopScanning()
    }
}
