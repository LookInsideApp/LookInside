//
//  AppDelegate.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit
import FoundationToolbox

@Loggable(subsystem: "com.lookinside.app")
@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appearanceObservation: NSKeyValueObservation?
    /// Set once Quit goes ahead, so the windows closing on the way out do
    /// not bring the launch window back.
    private var isTerminating = false

    /// The app's entry point. There is no main nib: the delegate is set
    /// here, and kept alive for the run since NSApplication holds it weakly.
    /// (A main.swift instead makes WMO Release builds put each file's code
    /// in the next file's object, which the release-clean check reads as
    /// DEBUG-only code shipping.)
    static func main() {
        #if DEBUG
            // Before the delegate is set, so the dump observes the end of
            // launching ahead of it, as its Objective-C +load did.
            DebugE2EDump.installIfRequested()
        #endif
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        withExtendedLifetime(delegate) {
            NSApplication.shared.run()
        }
    }

    func applicationWillFinishLaunching(_: Notification) {
        AppMenuManager.shared.setup()

        appearanceObservation = PreferenceManager.shared.observe(\.appearanceType, options: [.initial, .new]) { manager, _ in
            MainActor.assumeIsolated {
                Self.applyAppearance(manager.appearanceType)
            }
        }
    }

    private static func applyAppearance(_ type: PreferredAppearanceType) {
        switch type {
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        default:
            NSApp.appearance = nil
        }
    }

    func applicationDidFinishLaunching(_: Notification) {
        _ = ConnectionManager.shared
        if !Self.isHostingUnitTests {
            MCPBridgeServer.sharedInstance.start()
            // Documents opened during launch (Finder double-click, Open
            // With…) are registered with NSDocumentController by now, so "no
            // documents ⇒ show Launch" covers both cold-start cases.
            if NSDocumentController.shared.documents.isEmpty {
                NavigationManager.shared.showLaunch()
            }

            installActivationStateObserver()
        }

        // When the last window closes, bring Launch back. Closing Launch
        // itself leaves the app in the Dock with no window.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )

        #if DEBUG
            Self.checkDashboardBlueprintIdentifiers()
        #endif
    }

    /// Whether this process hosts the `LookInsideAppTests` bundle: the tests
    /// start with no window and no MCP socket, and build what they need.
    /// Always false in Release.
    private static var isHostingUnitTests: Bool {
        #if DEBUG
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        #else
            false
        #endif
    }

    @objc private func handleWindowWillClose(_ notification: Notification) {
        guard !isTerminating,
              let closingWindow = notification.object as? NSWindow,
              Self.isAppWindow(closingWindow),
              closingWindow != NavigationManager.shared.launchWindowController?.window
        else {
            return
        }
        // Defer one tick: the closing window is still on screen while its
        // close notification is delivered.
        DispatchQueue.main.async {
            self.showLaunchIfNoWindows()
        }
    }

    private func showLaunchIfNoWindows() {
        guard !isTerminating, Self.openAppWindows().isEmpty else {
            return
        }
        NavigationManager.shared.showLaunch()
    }

    /// A window the user sees as one of the app's: a titled window of its
    /// own, not a panel, popover or sheet.
    private static func isAppWindow(_ window: NSWindow) -> Bool {
        !(window is NSPanel) && window.styleMask.contains(.titled) && window.sheetParent == nil
    }

    /// The app's windows that are on screen or minimized to the Dock.
    private static func openAppWindows() -> [NSWindow] {
        NSApp.windows.filter { isAppWindow($0) && ($0.isVisible || $0.isMiniaturized) }
    }

    private func installActivationStateObserver() {
        let gatekeeper = SwiftUISupportGatekeeper.sharedInstance()
        #log(.default, "[LK-Activation] initial state=\(gatekeeper.activationState.rawValue, privacy: .public) (re-evaluated every 60s in process)")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activationStateDidChange(_:)),
            name: NSNotification.Name(SwiftUISupportGatekeeper.activationStateDidChangeNotificationName as String),
            object: nil
        )
    }

    @objc private func activationStateDidChange(_ notification: Notification) {
        let state = notification.userInfo?["activationState"] as? NSNumber
        let label: String
        switch state.flatMap({ SwiftUISupportActivationState(rawValue: $0.intValue) }) {
        case .unknown: label = "unknown"
        case .notActivated: label = "notActivated"
        case .activated: label = "activated"
        default: label = "(null)"
        }
        #log(.default, "[LK-Activation] state changed -> \(label, privacy: .public) (raw=\(state?.description ?? "(null)", privacy: .public))")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        // Keep the app alive after the last window closes so the Launch
        // window can come back instead of quitting. Quit goes through Cmd-Q.
        false
    }

    func applicationShouldOpenUntitledFile(_: NSApplication) -> Bool {
        // There is no meaningful "untitled" document in this app. New
        // Inspection / Open are explicit user actions; suppress the macOS
        // default that would create one on activation.
        false
    }

    func applicationOpenUntitledFile(_: NSApplication) -> Bool {
        false
    }

    /// A Dock click or a second launch from Finder. With a window on screen
    /// this only activates the app; otherwise it brings back a minimized
    /// window, and with none left it shows the launch window.
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            return true
        }
        let openWindows = Self.openAppWindows()
        if let onScreenWindow = openWindows.first(where: \.isVisible) {
            onScreenWindow.makeKeyAndOrderFront(nil)
        } else if let minimizedWindow = openWindows.first(where: \.isMiniaturized) {
            minimizedWindow.deminiaturize(nil)
            minimizedWindow.makeKeyAndOrderFront(nil)
        } else {
            NavigationManager.shared.showLaunch()
        }
        // Handled here, so AppKit does not deminiaturize a second window.
        return false
    }

    func application(_: NSApplication, open urls: [URL]) {
        // Routed through NSDocumentController so .lookin archives get Recent
        // Documents, proxy icon dragging, Save As, and the reuse of an
        // already open file.
        for url in urls {
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { document, _, error in
                if document == nil, let error {
                    NSApp.presentError(error)
                }
            }
        }
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        isTerminating = true
        SwiftUISupportGatekeeper.sharedInstance().shutdownRuntime()
        MCPBridgeServer.sharedInstance.stop()

        // 清理打开 UIImageView 的图片时创建的临时文件
        for path in AppHelper.sharedInstance().tempImageFiles {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                assertionFailure("could not remove the temporary image file \(path): \(error)")
            }
        }
        return .terminateNow
    }

    #if DEBUG
        /// The dashboard blueprint's group, section and attribute identifiers
        /// must each be unique.
        private static func checkDashboardBlueprintIdentifiers() {
            let groupIDs = DashboardBlueprint.groupIDs()
            assert(Set(groupIDs).count == groupIDs.count, "duplicate LookinAttrGroupIdentifier")

            let sectionIDs = groupIDs.flatMap { DashboardBlueprint.sectionIDs(forGroupID: $0) ?? [] }
            assert(Set(sectionIDs).count == sectionIDs.count, "duplicate LookinAttrSectionIdentifier")

            let attrIDs = sectionIDs.flatMap { DashboardBlueprint.attrIDs(forSectionID: $0) ?? [] }
            assert(Set(attrIDs).count == attrIDs.count, "duplicate LookinAttrIdentifier")
        }
    #endif
}
