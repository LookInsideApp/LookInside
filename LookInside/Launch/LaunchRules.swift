//
//  LaunchRules.swift
//  LookInside
//
//  The decisions of the launch window, kept free of AppKit views so they can
//  be tested on their own.
//

import Foundation

enum LaunchRules {
    /// Whether the launch window opens the only app it found by itself.
    ///
    /// Only the first scan after the window opens may do this, only with
    /// exactly one app, only when that app's Server version is supported and
    /// only when the activation is in place.
    static func canAutoEnter(requested: Bool, appCount: Int, onlyAppHasServerVersionError: Bool, isActivated: Bool) -> Bool {
        requested && appCount == 1 && !onlyAppHasServerVersionError && isActivated
    }

    /// The website page that explains a Server version error.
    static func serverVersionHelpPath(errorCode: Int) -> String {
        errorCode == LookinErrCode_ServerVersionTooLow ? "faq/server-version-too-low/" : "faq/server-version-too-high/"
    }

    /// The text an app card shows for a Server version error.
    static func serverVersionErrorTitle(errorCode: Int, localizedDescription: String) -> String {
        if errorCode == LookinErrCode_ServerVersionTooLow {
            return NSLocalizedString("The version of LookinServer linked with this iOS App is too low.", comment: "")
        }
        if errorCode == LookinErrCode_ServerVersionTooHigh {
            return NSLocalizedString("Unable to inspect this iOS App. Current version of LookInside app is too low.", comment: "")
        }
        return localizedDescription.isEmpty ? NSLocalizedString("Unable to inspect this app.", comment: "") : localizedDescription
    }
}
