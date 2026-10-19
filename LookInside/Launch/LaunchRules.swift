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

    /// The page Learn More opens for a Server version error: how to update
    /// the Server when it is too old, the download when LookInside is.
    static func serverVersionHelpURL(errorCode: Int) -> URL {
        errorCode == LookinErrCode_ServerVersionTooLow
            ? URL(string: "https://lookinside-app.com/docs/update-server")!
            : URL(string: "https://lookinside-app.com/#cta")!
    }

    /// The text an app card shows for a Server version error: what to do,
    /// in one short sentence.
    static func serverVersionErrorTitle(errorCode: Int, localizedDescription: String) -> String {
        if errorCode == LookinErrCode_ServerVersionTooLow {
            return NSLocalizedString("Update LookInside Server to inspect this app.", comment: "App card: the app's embedded Server is too old")
        }
        if errorCode == LookinErrCode_ServerVersionTooHigh {
            return NSLocalizedString("Update LookInside to inspect this app.", comment: "App card: the app's embedded Server is newer than this LookInside")
        }
        return localizedDescription.isEmpty ? NSLocalizedString("Unable to inspect this app.", comment: "") : localizedDescription
    }

    /// The title of the sheet a click on such a card shows: what is wrong,
    /// naming the app when its name is known.
    static func serverVersionAlertTitle(errorCode: Int, appName: String?) -> String {
        let isServerTooNew = errorCode == LookinErrCode_ServerVersionTooHigh
        guard let appName, !appName.isEmpty else {
            return isServerTooNew
                ? NSLocalizedString("This app uses a newer LookInside Server.", comment: "Server version alert title, app name unknown")
                : NSLocalizedString("This app uses an older LookInside Server.", comment: "Server version alert title, app name unknown")
        }
        let format = isServerTooNew
            ? NSLocalizedString("“%@” uses a newer LookInside Server.", comment: "Server version alert title; %@ is the app name")
            : NSLocalizedString("“%@” uses an older LookInside Server.", comment: "Server version alert title; %@ is the app name")
        return String(format: format, appName)
    }

    /// The sheet's message: why it matters and who can fix it.
    static func serverVersionAlertMessage(errorCode: Int) -> String {
        if errorCode == LookinErrCode_ServerVersionTooHigh {
            return NSLocalizedString(
                "The app was built with a newer LookInside Server than this version of LookInside supports. Update LookInside to inspect it.",
                comment: "Server version alert message: update the Host"
            )
        }
        return NSLocalizedString(
            "This version of LookInside loads large and SwiftUI-heavy screens without stalling the app, which needs a newer LookInside Server. Ask the app’s developer to update the LookInside Server package, then run the app again.",
            comment: "Server version alert message: the app's developer updates the Server"
        )
    }
}
