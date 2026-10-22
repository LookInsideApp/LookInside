//
//  ServerVersionAlert.swift
//  LookInside
//
//  The sheet an app with an incompatible Server shows when it is clicked, in
//  the launch window or the window's app picker. It says what is wrong in one
//  sentence, who can fix it, and links to the instructions; it only ever
//  appears on a click, so the 1.5-second rescan of the launch window never
//  brings it back.
//

import AppKit

@MainActor
enum ServerVersionAlert {
    /// Shows the sheet for `app`'s version error on `window`, or opens the
    /// help page in the browser when there is no window to attach it to.
    static func present(for app: InspectableApp, error: NSError, in window: NSWindow?) {
        let helpURL = LaunchRules.serverVersionHelpURL(errorCode: error.code)
        guard let window else {
            NSWorkspace.shared.open(helpURL)
            return
        }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = LaunchRules.serverVersionAlertTitle(errorCode: error.code, appName: app.appInfo?.appName)
        alert.informativeText = LaunchRules.serverVersionAlertMessage(errorCode: error.code)
        alert.addButton(withTitle: NSLocalizedString("OK", comment: "Dismisses the Server version alert"))
        alert.addButton(withTitle: NSLocalizedString("Learn More", comment: "Opens the page on updating the Server or LookInside"))
        alert.beginSheetModal(for: window) { response in
            if response == .alertSecondButtonReturn {
                NSWorkspace.shared.open(helpURL)
            }
        }
    }
}
