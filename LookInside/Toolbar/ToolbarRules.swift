//
//  ToolbarRules.swift
//  LookInside
//
//  The decisions behind the window toolbars and their popovers, kept free of
//  AppKit views so they can be tested on their own.
//

import Foundation

// Toolbar item identifiers. The values are stored in the toolbar
// configuration; never change them.
let LKToolBarIdentifier_Dimension = "0"
let LKToolBarIdentifier_Scale = "1"
let LKToolBarIdentifier_Setting = "2"
let LKToolBarIdentifier_Reload = "3"
let LKToolBarIdentifier_App = "5"
let LKToolBarIdentifier_AppInReadMode = "12"
let LKToolBarIdentifier_Add = "13"
let LKToolBarIdentifier_Remove = "14"
let LKToolBarIdentifier_Console = "15"
let LKToolBarIdentifier_Rotation = "16"
let LKToolBarIdentifier_Measure = "17"
let LKToolBarIdentifier_Message = "18"
let LKToolBarIdentifier_FastMode = "19"
let LKToolBarIdentifier_SwiftUIMode = "20"
let LKToolBarIdentifier_GestureDebug = "21"

/// What opened the apps popover.
@objc enum MenuPopoverAppsListControllerEventSource: Int {
    case reloadButton
    case noConnectionTips
    case appButton
}

enum ToolbarRules {
    /// The step the zoom buttons, the zoom menu items and the separation
    /// menu items move by.
    static let step = 0.1

    /// `value` moved by `delta`, then clamped to `lower...upper`.
    static func stepped(_ value: Double, by delta: Double, lower: Double, upper: Double) -> Double {
        min(max(value + delta, lower), upper)
    }

    /// The title and subtitle of the apps popover.
    ///
    /// The reload button and the connection-lost tips say the connection is
    /// lost; the app button counts the apps found.
    static func appsPopoverCopy(
        source: MenuPopoverAppsListControllerEventSource,
        appCount: Int
    ) -> (title: String?, subtitle: String?) {
        switch source {
        case .reloadButton, .noConnectionTips:
            let title = NSLocalizedString("Connection lost", comment: "")
            let subtitle: String
            if appCount == 0 {
                subtitle = NSLocalizedString("And no inspectable app was found", comment: "")
            } else if appCount == 1 {
                subtitle = NSLocalizedString("Click the screenshot below to Change App", comment: "")
            } else {
                subtitle = String(format: NSLocalizedString("Other %@ apps were found", comment: ""), NSNumber(value: appCount))
            }
            return (title, subtitle)
        case .appButton:
            guard appCount > 0 else {
                return (NSLocalizedString("No inspectable app was found", comment: ""), nil)
            }
            let title: String
            if appCount == 1 {
                title = NSLocalizedString("1 active app was found", comment: "")
            } else {
                title = String(format: NSLocalizedString("%@ active apps were found", comment: ""), NSNumber(value: appCount))
            }
            return (title, NSLocalizedString("Click the screenshot below to inspect", comment: ""))
        @unknown default:
            assertionFailure("Unknown apps popover source \(source.rawValue)")
            return (nil, nil)
        }
    }
}
