//
//  AppDelegate.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit

@main
@objc(AppDelegate)
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appearanceObservation: NSKeyValueObservation?

    /// The app's entry point. There is no main nib: the delegate is set
    /// here, and kept alive for the run since NSApplication holds it weakly.
    /// (A main.swift instead makes WMO Release builds put each file's code
    /// in the next file's object, which the release-clean check reads as
    /// DEBUG-only code shipping.)
    static func main() {
        #if DEBUG
            // Before the delegate is set, so the dump observes the end of
            // launching ahead of it, as its Objective-C +load did.
            LKDebugE2EDump.installIfRequested()
        #endif
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        withExtendedLifetime(delegate) {
            NSApplication.shared.run()
        }
    }

    func applicationWillFinishLaunching(_: Notification) {
        LKAppMenuManager.shared.setup()

        appearanceObservation = LKPreferenceManager.shared.observe(\.appearanceType, options: [.initial, .new]) { manager, _ in
            MainActor.assumeIsolated {
                Self.applyAppearance(manager.appearanceType)
            }
        }
    }

    private static func applyAppearance(_ type: LookinPreferredAppeanranceType) {
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
        _ = LKConnectionManager.shared
        LKMCPBridgeServer.sharedInstance.start()
        // Documents opened during launch (Finder double-click, Open With…)
        // are registered with NSDocumentController by now, so "no documents
        // ⇒ show Launch" covers both cold-start cases.
        if NSDocumentController.shared.documents.isEmpty {
            var allowAutoEnter = true
            #if DEBUG
                // The end-to-end dump (LKDebugE2EDump.swift) opens the app itself; an
                // activated Host's auto-enter would fetch the same hierarchy
                // alongside it.
                allowAutoEnter = (ProcessInfo.processInfo.environment["LOOKINSIDE_DEBUG_E2E_DUMP_DIR"] ?? "").isEmpty
            #endif
            LKNavigationManager.shared.showLaunch(allowingAutoEnter: allowAutoEnter)
        }

        installActivationStateObserver()

        // When the last document closes, bring Launch back so the app never
        // sits without any visible UI.
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

    @objc private func handleWindowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow.windowController is LKWindowController
        else {
            return
        }
        // Closing the Launch window itself shouldn't re-spawn Launch; only
        // document (live / archive) windows trigger the "no docs left" reopen.
        if closingWindow == LKNavigationManager.shared.launchWindowController?.window {
            return
        }
        // Defer one tick so NSDocumentController has finished removing the doc.
        DispatchQueue.main.async {
            self.showLaunchIfNoDocuments()
        }
    }

    private func showLaunchIfNoDocuments() {
        guard NSDocumentController.shared.documents.isEmpty else {
            return
        }
        if LKNavigationManager.shared.launchWindowController?.window?.isVisible == true {
            return
        }
        LKNavigationManager.shared.showLaunch()
    }

    private func installActivationStateObserver() {
        let gatekeeper = LKSwiftUISupportGatekeeper.sharedInstance()
        NSLog("[LK-Activation] initial state=%ld (re-evaluated every 60s in process)", gatekeeper.activationState.rawValue)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activationStateDidChange(_:)),
            name: NSNotification.Name(LKSwiftUISupportGatekeeper.activationStateDidChangeNotificationName as String),
            object: nil
        )
    }

    @objc private func activationStateDidChange(_ notification: Notification) {
        let state = notification.userInfo?["activationState"] as? NSNumber
        let label: String
        switch state.flatMap({ LKSwiftUISupportActivationState(rawValue: $0.intValue) }) {
        case .unknown: label = "unknown"
        case .notActivated: label = "notActivated"
        case .activated: label = "activated"
        default: label = "(null)"
        }
        NSLog("[LK-Activation] state changed -> %@ (raw=%@)", label, state?.description ?? "(null)")
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

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Dock-icon click after closing all windows: bring Launch back.
        if !flag {
            showLaunchIfNoDocuments()
        }
        return true
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
        LKSwiftUISupportGatekeeper.sharedInstance().shutdownRuntime()
        LKMCPBridgeServer.sharedInstance.stop()

        // 清理打开 UIImageView 的图片时创建的临时文件
        for path in LKHelper.sharedInstance().tempImageFiles {
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
