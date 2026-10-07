//
//  LKAppMenuManager.swift
//  LookInside
//
//  Created by Li Kai on 2019/3/20.
//  https://lookin.work
//
//  Builds the main menu and handles its commands. Window commands (reload,
//  zoom, export…) go to the key window's controller through
//  LKAppMenuManagerDelegate and are enabled only when that controller
//  implements them.
//

import AppKit
import Sparkle

/// The menu sends each command to the key window's controller, and enables
/// the item only when the controller implements the method.
@objc(LKAppMenuManagerDelegate)
@MainActor
protocol LKAppMenuManagerDelegate: NSObjectProtocol {
    @objc optional func appMenuManagerDidSelectReload()
    @objc optional func appMenuManagerDidSelectDimension()
    @objc optional func appMenuManagerDidSelectZoomIn()
    @objc optional func appMenuManagerDidSelectZoomOut()
    @objc optional func appMenuManagerDidSelectDecreaseInterspace()
    @objc optional func appMenuManagerDidSelectIncreaseInterspace()
    @objc(appMenuManagerDidSelectExpansionIndex:)
    optional func appMenuManagerDidSelectExpansionIndex(_ index: UInt)
    @objc optional func appMenuManagerDidSelectFilter()

    @objc optional func appMenuManagerDidSelectExport()
    @objc optional func appMenuManagerDidSelectOpenInNewWindow()
}

@objc(LKAppMenuManager)
@MainActor
final class LKAppMenuManager: NSObject, NSMenuDelegate {
    static let shared = LKAppMenuManager()

    override private init() {
        super.init()
    }

    private enum Tag {
        static let about = 11
        static let preferences = 12
        static let checkUpdates = 13
        static let activateSwiftUISupport = 14
        static let swiftUISupportLicense = 15
        static let refreshSwiftUISupportLicense = 16
        static let purchaseSwiftUISupport = 17
        static let swiftUISupportCustomerSupport = 18
        static let swiftUISupportSubmenu = 19
        static let privateDiscriminatorSettings = 20

        static let reload = 21
        static let dimension = 22
        static let zoomIn = 23
        static let zoomOut = 24
        static let decreaseInterspace = 25
        static let increaseInterspace = 26
        static let expansion = 27
        static let filter = 28
        static let openInNewWindow = 31
        static let export = 32
        static let newInspection = 33
        static let attachToRunningApp = 34
        static let attachToAppOnDevice = 35

        static let gitHub = 57
        static let acknowledgements = 72
    }

    private static let swiftUISupportPurchaseURL = "https://lookinside-app.com/purchase"
    private static let swiftUISupportCustomerSupportURL = "mailto:support@lookinside-app.com"
    /// The title `menuNeedsUpdate(_:)` recognizes the LookInside Pro submenu by.
    private static let swiftUISupportMenuTitle = "LookInside Pro"

    /// The window commands: menu item tag → LKAppMenuManagerDelegate method.
    private static let delegatingSelectors: [Int: Selector] = [
        Tag.reload: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectReload),
        Tag.dimension: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectDimension),
        Tag.zoomIn: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectZoomIn),
        Tag.zoomOut: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectZoomOut),
        Tag.decreaseInterspace: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectDecreaseInterspace),
        Tag.increaseInterspace: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectIncreaseInterspace),
        Tag.expansion: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectExpansionIndex(_:)),
        Tag.export: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectExport),
        Tag.openInNewWindow: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectOpenInNewWindow),
        Tag.filter: #selector(LKAppMenuManagerDelegate.appMenuManagerDidSelectFilter),
    ]

    private var recentDocumentsMenu: NSMenu?
    private var updaterController: SPUStandardUpdaterController?

    // MARK: - Setup

    /// Starts the updater when the build can use it, and installs the main
    /// menu.
    func setup() {
        if shouldStartSparkleUpdater {
            updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        }
        installMainMenu()
    }

    /// Only the release and internal-snapshot workflows inject
    /// SPARKLE_PUBLIC_ED_KEY (both refuse to build without it). Every other
    /// build -- Debug, or a local Release build, signed or not -- leaves
    /// SUPublicEDKey empty, and Sparkle then refuses to start and puts up a
    /// modal "Unable to Check For Updates" alert on every launch. Skip the
    /// updater entirely in that case; dropping a key into
    /// Configuration/custom.xcconfig restores the real update flow locally.
    private var shouldStartSparkleUpdater: Bool {
        let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        return !(publicKey ?? "").isEmpty
    }

    private var applicationName: String {
        for key in ["CFBundleDisplayName", "CFBundleName"] {
            if let name = Bundle.main.object(forInfoDictionaryKey: key) as? String, !name.isEmpty {
                return name
            }
        }
        return ProcessInfo.processInfo.processName
    }

    private func installMainMenu() {
        let appName = applicationName
        let mainMenu = NSMenu(title: "Main Menu")
        let windowMenu = buildWindowMenu()
        let helpMenu = buildHelpMenu()

        mainMenu.addItem(Self.submenuItem(appName, buildApplicationMenu(appName: appName)))
        mainMenu.addItem(Self.submenuItem("File", buildFileMenu()))
        mainMenu.addItem(Self.submenuItem("Edit", buildEditMenu()))
        mainMenu.addItem(Self.submenuItem("View", buildViewMenu()))
        mainMenu.addItem(Self.submenuItem("Plugins", buildPluginsMenu()))
        mainMenu.addItem(Self.submenuItem("Window", windowMenu))
        mainMenu.addItem(Self.submenuItem("Help", helpMenu))

        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
        NSApp.helpMenu = helpMenu
    }

    // MARK: - Menus

    private func buildApplicationMenu(appName: String) -> NSMenu {
        let menu = NSMenu(title: appName)
        menu.autoenablesItems = false
        menu.delegate = self
        menu.addItem(item("About \(appName)", action: #selector(handleAbout), tag: Tag.about))
        menu.addItem(.separator())
        menu.addItem(item("Preferences…", action: #selector(handlePreferences), key: ",", modifiers: .command, tag: Tag.preferences))
        menu.addItem(item("Private Discriminator Settings…", action: #selector(handlePrivateDiscriminatorSettings), tag: Tag.privateDiscriminatorSettings))
        menu.addItem(.separator())
        menu.addItem(item("Check for Updates…", action: #selector(handleCheckUpdates), tag: Tag.checkUpdates))
        menu.addItem(.separator())
        menu.addItem(Self.standardItem("Hide \(appName)", action: #selector(NSApplication.hide(_:)), key: "h", modifiers: .command))
        menu.addItem(Self.standardItem("Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), key: "h", modifiers: [.command, .option]))
        menu.addItem(Self.standardItem("Show All", action: #selector(NSApplication.unhideAllApplications(_:))))
        menu.addItem(.separator())
        menu.addItem(Self.standardItem("Quit \(appName)", action: #selector(NSApplication.terminate(_:)), key: "q", modifiers: .command))
        return menu
    }

    private func buildFileMenu() -> NSMenu {
        let menu = NSMenu(title: "File")
        menu.autoenablesItems = false
        menu.delegate = self

        // New Inspection… brings up the Launch window's app picker so a fresh
        // live document can be created from any state.
        menu.addItem(item("New Inspection…", action: #selector(handleNewInspection), key: "n", modifiers: .command, tag: Tag.newInspection))
        menu.addItem(item("Attach to Running App…", action: #selector(handleAttachToRunningApp), tag: Tag.attachToRunningApp))
        // The same thing for an app on a connected iPhone or iPad. A separate
        // entry rather than a tab inside the existing picker: that picker's
        // Applications list enumerates this Mac, and showing it beside a
        // phone's process list would invite picking a pid from the wrong
        // machine.
        menu.addItem(item("Attach to App on Device…", action: #selector(handleAttachToAppOnDevice), tag: Tag.attachToAppOnDevice))
        menu.addItem(.separator())

        menu.addItem(Self.standardItem("Open…", action: #selector(NSDocumentController.openDocument(_:)), key: "o", modifiers: .command))

        let recentDocumentsMenu = NSMenu(title: "Open Recent")
        recentDocumentsMenu.autoenablesItems = false
        recentDocumentsMenu.delegate = self
        self.recentDocumentsMenu = recentDocumentsMenu
        reloadRecentDocumentsMenu()
        menu.addItem(Self.submenuItem("Open Recent", recentDocumentsMenu))

        menu.addItem(.separator())
        // Standard NSDocument actions: performClose: targets the key window,
        // saveDocumentAs: is validated against writableTypes(for:).
        menu.addItem(Self.standardItem("Close", action: #selector(NSWindow.performClose(_:)), key: "w", modifiers: .command))
        menu.addItem(Self.standardItem("Save As…", action: #selector(NSDocument.saveAs(_:)), key: "s", modifiers: [.command, .shift]))

        menu.addItem(.separator())
        menu.addItem(delegatingItem("Copy to New Window…", tag: Tag.openInNewWindow))
        menu.addItem(delegatingItem("Export…", tag: Tag.export))
        return menu
    }

    private func buildEditMenu() -> NSMenu {
        let menu = NSMenu(title: "Edit")
        menu.addItem(Self.standardItem("Cut", action: #selector(NSText.cut(_:)), key: "x", modifiers: .command))
        menu.addItem(Self.standardItem("Copy", action: #selector(NSText.copy(_:)), key: "c", modifiers: .command))
        menu.addItem(Self.standardItem("Paste", action: #selector(NSText.paste(_:)), key: "v", modifiers: .command))
        menu.addItem(Self.standardItem("Select All", action: #selector(NSText.selectAll(_:)), key: "a", modifiers: .command))
        return menu
    }

    private func buildViewMenu() -> NSMenu {
        let menu = NSMenu(title: "View")
        menu.autoenablesItems = false
        menu.delegate = self
        menu.addItem(delegatingItem("Reload", key: "r", tag: Tag.reload))
        menu.addItem(.separator())
        menu.addItem(delegatingItem("Filter", key: "f", tag: Tag.filter))
        menu.addItem(.separator())
        menu.addItem(delegatingItem("2D / 3D", key: "\\", tag: Tag.dimension))
        menu.addItem(.separator())
        menu.addItem(delegatingItem("Zoom In", key: "+", tag: Tag.zoomIn))
        menu.addItem(delegatingItem("Zoom Out", key: "-", tag: Tag.zoomOut))
        menu.addItem(.separator())
        menu.addItem(delegatingItem("Decrease Item Separation", key: "[", tag: Tag.decreaseInterspace))
        menu.addItem(delegatingItem("Increase Item Separation", key: "]", tag: Tag.increaseInterspace))
        menu.addItem(.separator())

        let expansionMenu = NSMenu(title: "Hierarchy Depth")
        let levels = ["Level 1 (Collapse All)", "Level 2", "Level 3", "Level 4", "Level 5 (Expand All)"]
        for (index, title) in levels.enumerated() {
            let levelItem = item(title, action: #selector(handleExpansion(_:)), key: "\(index + 1)", modifiers: .command, tag: 271 + index)
            levelItem.representedObject = NSNumber(value: index)
            expansionMenu.addItem(levelItem)
        }
        menu.addItem(Self.submenuItem("Hierarchy Depth", expansionMenu, tag: Tag.expansion))
        return menu
    }

    private func buildPluginsMenu() -> NSMenu {
        let menu = NSMenu(title: NSLocalizedString("Plugins", comment: ""))
        menu.autoenablesItems = false

        let swiftUIMenu = NSMenu(title: Self.swiftUISupportMenuTitle)
        swiftUIMenu.autoenablesItems = false
        swiftUIMenu.delegate = self
        populateSwiftUIPluginSubmenu(swiftUIMenu)
        menu.addItem(Self.submenuItem(NSLocalizedString("LookInside Pro", comment: ""), swiftUIMenu, tag: Tag.swiftUISupportSubmenu))
        return menu
    }

    private func populateSwiftUIPluginSubmenu(_ menu: NSMenu) {
        menu.removeAllItems()
        if LKSwiftUISupportGatekeeper.sharedInstance().activationState == .activated {
            menu.addItem(item(NSLocalizedString("LookInside Pro License…", comment: ""), action: #selector(handleSwiftUISupportLicense), tag: Tag.swiftUISupportLicense))
            menu.addItem(item(NSLocalizedString("Refresh License Status", comment: ""), action: #selector(handleRefreshSwiftUISupportLicense), tag: Tag.refreshSwiftUISupportLicense))
            menu.addItem(.separator())
            menu.addItem(item(NSLocalizedString("Customer Support…", comment: ""), action: #selector(handleSwiftUISupportCustomerSupport), tag: Tag.swiftUISupportCustomerSupport))
        } else {
            menu.addItem(item(NSLocalizedString("Activate LookInside Pro…", comment: ""), action: #selector(handleActivateSwiftUISupport), tag: Tag.activateSwiftUISupport))
            menu.addItem(.separator())
            menu.addItem(item(NSLocalizedString("Purchase…", comment: ""), action: #selector(handlePurchaseSwiftUISupport), tag: Tag.purchaseSwiftUISupport))
        }
    }

    private func buildWindowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")
        // ⌘W lives in the File menu (NSDocument convention); the Window menu
        // keeps the standard window manipulators.
        menu.addItem(Self.standardItem("Minimize", action: #selector(NSWindow.performMiniaturize(_:)), key: "m", modifiers: .command))
        menu.addItem(Self.standardItem("Zoom", action: #selector(NSWindow.performZoom(_:))))
        return menu
    }

    private func buildHelpMenu() -> NSMenu {
        let menu = NSMenu(title: "Help")
        menu.autoenablesItems = true
        menu.delegate = self
        menu.addItem(item("Source Code at GitHub", action: #selector(handleShowGitHub), tag: Tag.gitHub))
        menu.addItem(item("Acknowledgements", action: #selector(handleAcknowledgements), tag: Tag.acknowledgements))
        return menu
    }

    private func reloadRecentDocumentsMenu() {
        guard let menu = recentDocumentsMenu else { return }
        menu.removeAllItems()

        let recentURLs = NSDocumentController.shared.recentDocumentURLs
        guard !recentURLs.isEmpty else {
            let emptyItem = Self.standardItem("No Recent Documents", action: nil)
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
            return
        }

        for url in recentURLs {
            let title = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
            let recentItem = item(title, action: #selector(handleOpenRecentDocument(_:)))
            recentItem.representedObject = url
            recentItem.toolTip = url.path
            menu.addItem(recentItem)
        }

        menu.addItem(.separator())
        let clearItem = Self.standardItem("Clear Menu", action: #selector(NSDocumentController.clearRecentDocuments(_:)))
        clearItem.target = NSDocumentController.shared
        menu.addItem(clearItem)
    }

    // MARK: - Items

    /// An item with no target: AppKit sends `action` up the responder chain.
    private static func standardItem(
        _ title: String,
        action: Selector?,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = []
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    /// An item handled by this manager.
    private func item(
        _ title: String,
        action: Selector,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = [],
        tag: Int = 0
    ) -> NSMenuItem {
        let item = Self.standardItem(title, action: action, key: key, modifiers: modifiers)
        item.target = self
        item.tag = tag
        return item
    }

    /// A window command; `tag` picks its delegate method.
    private func delegatingItem(_ title: String, key: String = "", tag: Int) -> NSMenuItem {
        item(title, action: #selector(handleDelegateItem(_:)), key: key, modifiers: key.isEmpty ? [] : .command, tag: tag)
    }

    private static func submenuItem(_ title: String, _ submenu: NSMenu, tag: Int = 0) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.tag = tag
        item.submenu = submenu
        return item
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        if menu === recentDocumentsMenu {
            reloadRecentDocumentsMenu()
            return
        }

        if menu.title == Self.swiftUISupportMenuTitle {
            LKSwiftUISupportGatekeeper.sharedInstance().refreshActivationStateInBackground()
            populateSwiftUIPluginSubmenu(menu)
            return
        }

        let windowController = LKNavigationManager.shared.currentKeyWindowController()
        for menuItem in menu.items {
            if let selector = Self.delegatingSelectors[menuItem.tag] {
                menuItem.isEnabled = windowController?.responds(to: selector) ?? false
            } else if menuItem.tag == Tag.checkUpdates {
                // Nil whenever the build carries no Sparkle public key; see
                // shouldStartSparkleUpdater.
                menuItem.isEnabled = updaterController != nil
            } else if menuItem.action == #selector(NSDocument.saveAs(_:)) {
                let document = NSApp.keyWindow.flatMap { NSDocumentController.shared.document(for: $0) }
                menuItem.isEnabled = document.map { !$0.writableTypes(for: .saveAsOperation).isEmpty } ?? false
            } else if menuItem.action == #selector(NSWindow.performClose(_:)) {
                menuItem.isEnabled = NSApp.keyWindow != nil
            } else {
                menuItem.isEnabled = true
            }
        }
    }

    // MARK: - Actions

    @objc private func handleDelegateItem(_ item: NSMenuItem) {
        guard let selector = Self.delegatingSelectors[item.tag] else {
            assertionFailure("no window command for tag \(item.tag)")
            return
        }
        guard let windowController = LKNavigationManager.shared.currentKeyWindowController(),
              windowController.responds(to: selector)
        else {
            assertionFailure("the key window does not handle \(selector)")
            return
        }
        windowController.perform(selector)
    }

    @objc private func handleExpansion(_ item: NSMenuItem) {
        guard let index = (item.representedObject as? NSNumber)?.uintValue else {
            assertionFailure("expansion item without an index")
            return
        }
        guard let windowController = LKNavigationManager.shared.currentKeyWindowController(),
              let handler = (windowController as LKAppMenuManagerDelegate).appMenuManagerDidSelectExpansionIndex
        else {
            assertionFailure("the key window does not handle expansion")
            return
        }
        handler(index)
    }

    @objc private func handleOpenRecentDocument(_ item: NSMenuItem) {
        guard let url = item.representedObject as? URL else { return }
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            if let error {
                NSApp.presentError(error)
            }
        }
    }

    @objc private func handleAbout() {
        LKNavigationManager.shared.showAbout()
    }

    @objc private func handlePreferences() {
        LKNavigationManager.shared.showPreference()
    }

    @objc private func handlePrivateDiscriminatorSettings() {
        LKPrivateDiscriminatorSettingsWindowController.showSettingsWindow()
    }

    @objc private func handleCheckUpdates() {
        updaterController?.checkForUpdates(nil)
    }

    @objc private func handleActivateSwiftUISupport() {
        LKSwiftUISupportGatekeeper.sharedInstance().showActivationWindow()
    }

    @objc private func handleSwiftUISupportLicense() {
        LKSwiftUISupportGatekeeper.sharedInstance().showLicenseWindow()
    }

    @objc private func handleRefreshSwiftUISupportLicense() {
        LKSwiftUISupportGatekeeper.sharedInstance().refreshLicenseStatus()
    }

    @objc private func handlePurchaseSwiftUISupport() {
        if let url = URL(string: Self.swiftUISupportPurchaseURL) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func handleSwiftUISupportCustomerSupport() {
        if let url = URL(string: Self.swiftUISupportCustomerSupportURL) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func handleShowGitHub() {
        LKHelper.openProjectGitHubRepository()
    }

    @objc private func handleAcknowledgements() {
        LKHelper.openProjectREADME()
    }

    /// File > New Inspection… reuses the Launch window's app picker, so a
    /// fresh live document can be created from any state.
    @objc private func handleNewInspection() {
        LKNavigationManager.shared.showLaunch()
    }

    /// File > Attach to Running App… opens the running-process picker and
    /// injects LookInsideServer.framework into the chosen pid through the
    /// privileged injector daemon (LKInjectionFlow); sheets attach to the
    /// key window.
    @objc private func handleAttachToRunningApp() {
        guard LKSwiftUISupportGatekeeper.sharedInstance().allowProtectedFeatureAccess(for: NSApp.keyWindow) else {
            return
        }
        LKInjectionFlow.shared.startFromWindow(NSApp.keyWindow)
    }

    /// File > Attach to App on Device… asks the LookInside Injector running
    /// on a connected iPhone or iPad for its list of running apps and has
    /// *it* do the injecting — there is no daemon and no framework download
    /// on this side, because the device carries its own payload
    /// (LKDeviceInjectionFlow).
    @objc private func handleAttachToAppOnDevice() {
        guard LKSwiftUISupportGatekeeper.sharedInstance().allowProtectedFeatureAccess(for: NSApp.keyWindow) else {
            return
        }
        LKDeviceInjectionFlow.shared.startFromWindow(NSApp.keyWindow)
    }
}
