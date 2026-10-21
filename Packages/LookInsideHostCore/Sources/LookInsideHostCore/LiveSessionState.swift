//
//  LiveSessionState.swift
//  LookInsideHostCore
//
//  What a live inspection window knows about its app's connection, and what
//  it does when that changes: the banner it shows, reconnecting after the
//  channel ended, refreshing the hierarchy once the app is back, and
//  watching an app that went to the background. `LiveDocument` feeds it the
//  events and carries out the actions.
//

import Foundation

public struct LiveSessionState: Equatable, Sendable {
    /// The notice at the top of the window.
    public enum Banner: Equatable, Sendable {
        case none
        /// The channel ended; the window looks for the app again.
        case connectionLost
        /// The app is in the background and cannot answer; the tree stays.
        case applicationInBackground
    }

    public enum Event: Equatable, Sendable {
        /// The window started watching its app's channel: when it opened, or
        /// after a reconnect handed it a new one. `isAlive` is false when the
        /// channel was already released or ended by then.
        case watchedChannel(isAlive: Bool)
        /// The watched channel ended.
        case channelEnded
        /// The Server pushed its application's state (Servers that predate
        /// `LookinPush_ApplicationStateChanged` never do).
        case serverReportedApplicationState(isActive: Bool)
        /// The Server refused a request because its app is in the background.
        case requestRefusedInBackground
        /// A ping sent while the app was in the background was answered by an
        /// app in the foreground.
        case backgroundProbeAnswered
    }

    public enum Action: Equatable, Sendable {
        /// Scan for the app until it is found again.
        case startReconnecting
        /// Fetch the hierarchy again, without an error sheet.
        case reloadHierarchy
        /// Ping the app every few seconds until it answers from the
        /// foreground, then report `backgroundProbeAnswered`.
        case startBackgroundProbe
        case stopBackgroundProbe
    }

    public private(set) var banner: Banner = .none
    /// Whether the watched channel's Server pushed its application state;
    /// learned again for each channel. A Server that pushes says when its app
    /// is back, so the window does not ping it.
    private var serverReportsApplicationState = false
    private var isProbing = false

    public init() {}

    /// Applies `event` and returns what to do, in order.
    public mutating func handle(_ event: Event) -> [Action] {
        switch event {
        case let .watchedChannel(isAlive):
            guard isAlive else {
                return endConnection()
            }
            serverReportsApplicationState = false
            guard banner == .connectionLost else {
                return []
            }
            // A reconnect: the tree on screen is the old process's.
            banner = .none
            return [.reloadHierarchy]

        case .channelEnded:
            return endConnection()

        case let .serverReportedApplicationState(isActive):
            serverReportsApplicationState = true
            guard banner != .connectionLost else {
                return []
            }
            if isActive {
                return returnToForeground()
            }
            banner = .applicationInBackground
            return stopProbing()

        case .requestRefusedInBackground:
            guard banner == .none else {
                return []
            }
            banner = .applicationInBackground
            guard !serverReportsApplicationState else {
                return []
            }
            isProbing = true
            return [.startBackgroundProbe]

        case .backgroundProbeAnswered:
            guard banner != .connectionLost else {
                return stopProbing()
            }
            return returnToForeground()
        }
    }

    private mutating func endConnection() -> [Action] {
        banner = .connectionLost
        serverReportsApplicationState = false
        // Each reconnect attempt replaces the one before, so starting again
        // is harmless when the window was already reconnecting.
        return stopProbing() + [.startReconnecting]
    }

    /// Clears the background banner and refreshes, once.
    private mutating func returnToForeground() -> [Action] {
        let stop = stopProbing()
        guard banner == .applicationInBackground else {
            return stop
        }
        banner = .none
        return stop + [.reloadHierarchy]
    }

    private mutating func stopProbing() -> [Action] {
        guard isProbing else {
            return []
        }
        isProbing = false
        return [.stopBackgroundProbe]
    }
}
