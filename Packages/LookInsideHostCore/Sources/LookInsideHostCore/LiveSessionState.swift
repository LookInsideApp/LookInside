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
        /// Ping the app every `interval` until it answers from the
        /// foreground, then report `backgroundProbeAnswered`. Replaces a probe
        /// already running.
        case startBackgroundProbe(interval: Duration)
        case stopBackgroundProbe
    }

    /// How often a window pings its app in the background when the Server
    /// does not push its application state: the answer is the only sign
    /// that the app is back.
    public static let backgroundProbeInterval: Duration = .seconds(2)

    /// How often a window pings its app in the background when the Server
    /// pushes its application state. The push says when the app is back; the
    /// ping keeps the channel checked. Over usbmuxd a channel can go silent
    /// without ending, the push that would clear the banner then never
    /// arrives, and only a ping that times out lets the liveness check
    /// (`ChannelLivenessPolicy`) close the channel so the window reconnects.
    public static let pushingServerBackgroundProbeInterval: Duration = .seconds(5)

    public private(set) var banner: Banner = .none
    /// Whether the watched channel's Server pushed its application state;
    /// learned again for each channel. Such a Server is pinged less often.
    private var serverReportsApplicationState = false
    /// The interval of the background probe running, or nil.
    private var probeInterval: Duration?

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
            return startProbing()

        case .requestRefusedInBackground:
            guard banner == .none else {
                return []
            }
            banner = .applicationInBackground
            return startProbing()

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

    /// Probes while the background banner shows, at the interval that
    /// suits the Server; a probe already running at that interval goes on.
    private mutating func startProbing() -> [Action] {
        let interval = serverReportsApplicationState ? Self.pushingServerBackgroundProbeInterval : Self.backgroundProbeInterval
        guard probeInterval != interval else {
            return []
        }
        probeInterval = interval
        return [.startBackgroundProbe(interval: interval)]
    }

    private mutating func stopProbing() -> [Action] {
        guard probeInterval != nil else {
            return []
        }
        probeInterval = nil
        return [.stopBackgroundProbe]
    }
}

/// Whether a refresh a live window starts on its own (`reloadHierarchy`:
/// after a reconnect, after its app came back) is tried again.
///
/// The window refuses a refresh while a hierarchy fetch or the detail sync
/// is running. Dropping the automatic refresh then left the old tree on
/// screen, after a reconnect even one whose object identifiers belong to a
/// process that is gone. A refused refresh is tried again every
/// `retryInterval`, up to `maximumRetries` times, so it starts once the
/// fetch that blocked it is over. Any other failure is not retried: a
/// manual reload would meet it as well.
public struct AutomaticRefreshRetryPolicy: Equatable, Sendable {
    /// How one attempt ended.
    public enum Outcome: Equatable, Sendable {
        case succeeded
        /// The window refused to start it: a hierarchy fetch or the detail
        /// sync was running.
        case refusedWhileBusy
        /// Any other failure: the app's, the channel's, or the window's.
        case failed
    }

    public static let defaultRetryInterval: Duration = .milliseconds(500)
    /// A minute at the default interval: longer than a large tree's
    /// hierarchy fetch, and a detail sync running longer than that is not
    /// worth waiting out.
    public static let defaultMaximumRetries = 120

    public let retryInterval: Duration
    public let maximumRetries: Int

    public init(retryInterval: Duration = Self.defaultRetryInterval, maximumRetries: Int = Self.defaultMaximumRetries) {
        self.retryInterval = retryInterval
        self.maximumRetries = maximumRetries
    }

    /// How long to wait before trying again after an attempt that ended
    /// with `outcome`, when the refresh was already retried
    /// `retriesSoFar` times; nil to stop.
    public func delayBeforeRetry(after outcome: Outcome, retriesSoFar: Int) -> Duration? {
        guard outcome == .refusedWhileBusy, retriesSoFar < maximumRetries else {
            return nil
        }
        return retryInterval
    }
}
