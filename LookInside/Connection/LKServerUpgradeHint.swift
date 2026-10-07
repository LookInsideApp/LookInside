//
//  LKServerUpgradeHint.swift
//  LookInside
//
//  The one-time hint that the inspected app's Server is old (0.2.9 or
//  earlier, which does not report its release in the 220 reply). The
//  handshake records the reported release on the channel; the inspector
//  window shows the hint, at most once per inspected app per Host launch.
//  It is a reminder only, never a security boundary.
//

import Foundation
import LookInsideHostCore

@MainActor
enum LKServerUpgradeHint {
    /// Posted on the main thread when a channel's 220 reply arrived; the
    /// object is the channel.
    static let releaseDidArriveNotification = Notification.Name("LKServerUpgradeHintReleaseDidArrive")

    private static let ledger = ServerUpgradeHintLedger()

    /// Records the release `channel`'s Server reported.
    static func noteRelease(_ release: ServerRelease, on channel: LKChannel) {
        channel.connectionState.serverRelease = release
        NotificationCenter.default.post(name: releaseDidArriveNotification, object: channel)
    }

    /// `true` when the hint should be shown now for `app`: its Server
    /// reported an old release and no window showed the hint for this app
    /// during this launch. Answering `true` records the hint as shown.
    static func shouldShowHint(for app: LKInspectableApp?) -> Bool {
        guard let app,
              let release = app.channel?.connectionState.serverRelease,
              let appKey = appKey(for: app.appInfo)
        else {
            return false
        }
        return ledger.shouldShowHint(for: release, appKey: appKey)
    }

    /// The app's bundle identifier, which stays the same across relaunches
    /// and reconnections of that app.
    private static func appKey(for appInfo: LookinAppInfo?) -> String? {
        guard let bundleIdentifier = appInfo?.appBundleIdentifier, !bundleIdentifier.isEmpty else {
            return nil
        }
        return bundleIdentifier
    }
}
