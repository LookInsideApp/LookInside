@testable import LookInsideHostCore
import Testing

struct LiveSessionStateTests {
    /// The probe for a Server that pushes its application state, and the
    /// one for a Server that does not.
    private let slowProbe = LiveSessionState.Action.startBackgroundProbe(interval: .seconds(5))
    private let fastProbe = LiveSessionState.Action.startBackgroundProbe(interval: .seconds(2))

    /// A window open on a live channel.
    private func openWindow() -> LiveSessionState {
        var state = LiveSessionState()
        _ = state.handle(.watchedChannel(isAlive: true))
        return state
    }

    // MARK: - Reconnecting

    @Test("a window that opens on a live channel shows nothing and does nothing")
    func openingOnALiveChannelIsQuiet() {
        var state = LiveSessionState()
        #expect(state.handle(.watchedChannel(isAlive: true)) == [])
        #expect(state.banner == .none)
    }

    @Test("an ended channel shows the connection-loss banner and starts reconnecting")
    func anEndedChannelStartsReconnecting() {
        var state = openWindow()
        #expect(state.handle(.channelEnded) == [.startReconnecting])
        #expect(state.banner == .connectionLost)
    }

    /// The tree on screen belongs to the process that went away; after a
    /// relaunch none of its object identifiers is valid any more.
    @Test("a reconnect clears the banner and fetches the hierarchy again")
    func aReconnectRefreshesTheHierarchy() {
        var state = openWindow()
        _ = state.handle(.channelEnded)
        #expect(state.handle(.watchedChannel(isAlive: true)) == [.reloadHierarchy])
        #expect(state.banner == .none)
    }

    /// The channel is held weakly: it can be released, or end, before the
    /// window starts watching it. Until now the window then watched nothing
    /// and never reconnected.
    @Test("a channel already gone when the window starts watching it counts as ended", arguments: [false, true])
    func aChannelGoneBeforeWatchingCountsAsEnded(afterAReconnect: Bool) {
        var state = afterAReconnect ? openWindow() : LiveSessionState()
        if afterAReconnect {
            _ = state.handle(.channelEnded)
        }
        #expect(state.handle(.watchedChannel(isAlive: false)) == [.startReconnecting])
        #expect(state.banner == .connectionLost)
    }

    // MARK: - Background, Servers that push their state

    /// The push that would clear the banner never arrives over a usbmuxd
    /// channel that went silent without ending; only a ping that times out
    /// lets the liveness check close it.
    @Test("a Server that reports its app inactive shows the background banner, keeps the tree and pings slowly")
    func aBackgroundPushShowsTheBannerAndProbes() {
        var state = openWindow()
        #expect(state.handle(.serverReportedApplicationState(isActive: false)) == [slowProbe])
        #expect(state.banner == .applicationInBackground)
    }

    @Test("a Server that reports its app active again clears the banner, stops pinging and refreshes")
    func aForegroundPushRefreshes() {
        var state = openWindow()
        _ = state.handle(.serverReportedApplicationState(isActive: false))
        #expect(state.handle(.serverReportedApplicationState(isActive: true)) == [.stopBackgroundProbe, .reloadHierarchy])
        #expect(state.banner == .none)
        // The probe answering late refreshes nothing more.
        #expect(state.handle(.backgroundProbeAnswered) == [])
    }

    /// The probe and the push both report the return; the hierarchy is
    /// fetched once.
    @Test("a ping answered before the foreground push refreshes once")
    func aProbeAnsweredBeforeTheForegroundPushRefreshesOnce() {
        var state = openWindow()
        _ = state.handle(.serverReportedApplicationState(isActive: false))
        #expect(state.handle(.backgroundProbeAnswered) == [.stopBackgroundProbe, .reloadHierarchy])
        #expect(state.handle(.serverReportedApplicationState(isActive: true)) == [])
        #expect(state.banner == .none)
    }

    @Test("a channel that the probe closes after a background push stops pinging and reconnects")
    func aChannelEndedAfterABackgroundPushReconnects() {
        var state = openWindow()
        _ = state.handle(.serverReportedApplicationState(isActive: false))
        #expect(state.handle(.channelEnded) == [.stopBackgroundProbe, .startReconnecting])
        #expect(state.banner == .connectionLost)
    }

    /// Refused before its first push (the Host connected while the app was
    /// inactive), then the push arrives.
    @Test("a background push while pinging fast slows the ping down")
    func aBackgroundPushWhileProbingSlowsTheProbe() {
        var state = openWindow()
        #expect(state.handle(.requestRefusedInBackground) == [fastProbe])
        #expect(state.handle(.serverReportedApplicationState(isActive: false)) == [slowProbe])
        #expect(state.handle(.serverReportedApplicationState(isActive: false)) == [])
        #expect(state.banner == .applicationInBackground)
    }

    @Test("an active report while the app was not in the background does nothing")
    func aForegroundPushWithoutABackgroundIsQuiet() {
        var state = openWindow()
        #expect(state.handle(.serverReportedApplicationState(isActive: true)) == [])
        #expect(state.banner == .none)
    }

    @Test("a refusal from a Server that pushes its state does not start another probe")
    func aRefusalFromAPushingServerDoesNotProbeAgain() {
        var state = openWindow()
        _ = state.handle(.serverReportedApplicationState(isActive: false))
        #expect(state.handle(.requestRefusedInBackground) == [])
        #expect(state.banner == .applicationInBackground)
    }

    // MARK: - Background, older Servers

    @Test("a refusal from a Server that does not push shows the banner and starts pinging")
    func aRefusalFromAnOlderServerProbes() {
        var state = openWindow()
        #expect(state.handle(.requestRefusedInBackground) == [fastProbe])
        #expect(state.banner == .applicationInBackground)
        // Further refusals, the probe's own included, change nothing.
        #expect(state.handle(.requestRefusedInBackground) == [])
    }

    @Test("an answered ping clears the banner, stops pinging and refreshes")
    func anAnsweredProbeRefreshes() {
        var state = openWindow()
        _ = state.handle(.requestRefusedInBackground)
        #expect(state.handle(.backgroundProbeAnswered) == [.stopBackgroundProbe, .reloadHierarchy])
        #expect(state.banner == .none)
    }

    /// A Server that pushes and was refused before its first push (the
    /// Host connected while the app was inactive): the push and the probe
    /// can both report the return; the hierarchy is fetched once.
    @Test("a foreground push while pinging stops the ping and refreshes once")
    func aForegroundPushWhileProbingRefreshesOnce() {
        var state = openWindow()
        _ = state.handle(.requestRefusedInBackground)
        #expect(state.handle(.serverReportedApplicationState(isActive: true)) == [.stopBackgroundProbe, .reloadHierarchy])
        #expect(state.handle(.backgroundProbeAnswered) == [])
        #expect(state.banner == .none)
    }

    // MARK: - Background, then the channel ends

    @Test("a channel that ends while the app is in the background stops pinging and reconnects")
    func anEndedChannelInTheBackgroundReconnects() {
        var state = openWindow()
        _ = state.handle(.requestRefusedInBackground)
        #expect(state.handle(.channelEnded) == [.stopBackgroundProbe, .startReconnecting])
        #expect(state.banner == .connectionLost)
    }

    @Test("background reports about a lost connection are ignored")
    func backgroundReportsWhileReconnectingAreIgnored() {
        var state = openWindow()
        _ = state.handle(.channelEnded)
        #expect(state.handle(.requestRefusedInBackground) == [])
        #expect(state.handle(.serverReportedApplicationState(isActive: false)) == [])
        #expect(state.banner == .connectionLost)
    }

    /// A new channel may come from a Server of another version: whether it
    /// pushes its state is learned again.
    @Test("after a reconnect to an older Server, a refusal pings again")
    func aReconnectForgetsThatTheServerPushed() {
        var state = openWindow()
        _ = state.handle(.serverReportedApplicationState(isActive: false))
        _ = state.handle(.channelEnded)
        _ = state.handle(.watchedChannel(isAlive: true))
        #expect(state.handle(.requestRefusedInBackground) == [fastProbe])
    }
}

struct AutomaticRefreshRetryPolicyTests {
    /// The refresh after a reconnect or a return from the background was
    /// dropped when a fetch was running, and the tree stayed stale.
    @Test("a refresh refused while a fetch or the detail sync runs is tried again after the interval")
    func aRefusedRefreshIsRetried() {
        let policy = AutomaticRefreshRetryPolicy()
        #expect(policy.delayBeforeRetry(after: .refusedWhileBusy, retriesSoFar: 0) == .milliseconds(500))
        #expect(policy.delayBeforeRetry(after: .refusedWhileBusy, retriesSoFar: 10) == .milliseconds(500))
    }

    @Test("a refresh that succeeded or failed for another reason is not tried again", arguments: [AutomaticRefreshRetryPolicy.Outcome.succeeded, .failed])
    func otherOutcomesAreNotRetried(outcome: AutomaticRefreshRetryPolicy.Outcome) {
        #expect(AutomaticRefreshRetryPolicy().delayBeforeRetry(after: outcome, retriesSoFar: 0) == nil)
    }

    @Test("a refresh refused again and again stops after the last retry")
    func retriesAreBounded() {
        let policy = AutomaticRefreshRetryPolicy(retryInterval: .seconds(1), maximumRetries: 3)
        let delays = (0 ... 3).map { retriesSoFar in
            policy.delayBeforeRetry(after: .refusedWhileBusy, retriesSoFar: retriesSoFar)
        }
        #expect(delays == [.seconds(1), .seconds(1), .seconds(1), nil])
    }

    @Test("by default a refused refresh waits for the blocking fetch for a minute")
    func theDefaultWaitsAMinute() {
        let policy = AutomaticRefreshRetryPolicy()
        #expect(policy.retryInterval * policy.maximumRetries == .seconds(60))
    }
}
