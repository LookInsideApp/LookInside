import Foundation

/// The runtime's single, thread-safe `ActivationSigningPolicy`. Every use of
/// the license key goes through `perform(_:channel:renewalIsUrgent:_:)`.
///
/// Rules:
/// - Key uses run one at a time, in a queue. A user action waits only for
///   the use in progress and goes ahead of every queued automatic use.
/// - An automatic use asks the policy when it is queued and again when its
///   turn comes, so a denied prompt cancels everything queued behind it.
/// - The duration of a use is measured from its turn, not from the queue,
///   so only time spent in the keychain counts as a prompt.
/// - When a denial wait ends, a timer clears it: observers see the new
///   status (the license window notice goes away) and the channels whose
///   signing was denied may handshake again.
/// - The keychain explainer (see `ActivationSigningPolicy`) is assessed on
///   the first automatic use, and requested from the Host only when an
///   automatic use needs the key. Continue lets the held-back uses start
///   again; the first of them raises the system prompt as the user's use.
/// - The markers (`KeychainAccessMarkers`) are written for the key's
///   identity: created by the Host, signed without a prompt, explainer
///   confirmed.
final class ActivationSigningGate: @unchecked Sendable {
    typealias TimerScheduler = @Sendable (_ delay: TimeInterval, _ fire: @escaping @Sendable () -> Void) -> Void

    private let lock = NSLock()
    private let now: @Sendable () -> Date
    private let scheduleTimer: TimerScheduler
    private let markers: KeychainAccessMarkers?
    private let keyIdentity: (@Sendable () -> String?)?
    private var policy: ActivationSigningPolicy
    private var generation = 0
    private var observers: [UUID: @Sendable (ActivationSigningStatus) -> Void] = [:]
    /// `true` until the first automatic use decided whether the key needs
    /// the explainer.
    private var needsExplainerAssessment: Bool
    private var isKeyInUse = false
    private var waiters: [Waiter] = []

    private struct Waiter {
        let isUserAction: Bool
        let continuation: CheckedContinuation<Void, Never>
    }

    /// `markers` remembers, per key, what makes the explainer unnecessary;
    /// `keyIdentity` names the stored key (its public-key hash, read without
    /// using the key) or returns `nil` when there is none. Without either
    /// (test keychains) the explainer is never needed.
    init(
        launchedAt: Date,
        now: @escaping @Sendable () -> Date,
        markers: KeychainAccessMarkers? = nil,
        keyIdentity: (@Sendable () -> String?)? = nil,
        scheduleTimer: @escaping TimerScheduler = ActivationSigningGate.wallClockTimer
    ) {
        policy = ActivationSigningPolicy(launchedAt: launchedAt)
        self.now = now
        self.markers = markers
        self.keyIdentity = keyIdentity
        needsExplainerAssessment = markers != nil && keyIdentity != nil
        self.scheduleTimer = scheduleTimer
    }

    /// A gate that lets every source sign at once, for a renewer built on
    /// its own (tests, the end-to-end harness).
    static func open(now: @escaping @Sendable () -> Date = { Date() }) -> ActivationSigningGate {
        let gate = ActivationSigningGate(launchedAt: .distantPast, now: now)
        gate.noteFirstWindowShown()
        return gate
    }

    /// Fires `fire` after `delay` seconds of wall-clock time, so a Mac that
    /// slept past the end of a wait still ends it on wake.
    static let wallClockTimer: TimerScheduler = { delay, fire in
        DispatchQueue.global(qos: .utility).asyncAfter(wallDeadline: .now() + max(delay, 0), execute: fire)
    }

    var status: ActivationSigningStatus {
        lock.withLock { makeStatus() }
    }

    // MARK: Decisions

    /// `true` when `source` may use the key now. Does not ask for the
    /// explainer.
    func allowsSigning(for source: ActivationSigningSource, renewalIsUrgent: Bool = false) -> Bool {
        decision(for: source, renewalIsUrgent: renewalIsUrgent) == .allowed
    }

    /// `true` when an automatic use from `source` may use the key now. When
    /// only the explainer holds it back, asks the Host to show it.
    func admits(_ source: ActivationSigningSource, renewalIsUrgent: Bool = false) -> Bool {
        settle(decision(for: source, renewalIsUrgent: renewalIsUrgent))
    }

    /// `true` when a license handshake may start on `channel` now. When only
    /// the explainer holds it back, asks the Host to show it.
    func allowsHandshake(onChannel channel: String?) -> Bool {
        assessExplainerIfNeeded()
        let date = now()
        return settle(lock.withLock { policy.handshakeDecision(onChannel: channel, at: date) })
    }

    private func decision(
        for source: ActivationSigningSource,
        renewalIsUrgent: Bool
    ) -> ActivationSigningDecision {
        if source.isAutomatic {
            assessExplainerIfNeeded()
        }
        let date = now()
        return lock.withLock { policy.decision(for: source, at: date, renewalIsUrgent: renewalIsUrgent) }
    }

    private func settle(_ decision: ActivationSigningDecision) -> Bool {
        if decision == .needsExplainer {
            update(unblocksHandshakes: false) { $0.requestExplainer() }
        }
        return decision == .allowed
    }

    // MARK: Key use

    /// Runs `body`, which uses the license key, in its turn. An automatic
    /// `source` that the policy does not allow, when queued or when its turn
    /// comes, throws `ActivationError.signingDeferred` without running.
    /// Records the outcome.
    func perform<Value: Sendable>(
        _ source: ActivationSigningSource,
        channel: String? = nil,
        renewalIsUrgent: Bool = false,
        _ body: @Sendable () async throws -> Value
    ) async throws -> Value {
        try await performMeasured(source, channel: channel, renewalIsUrgent: renewalIsUrgent, body).value
    }

    /// `perform(_:channel:renewalIsUrgent:_:)` that also returns how long
    /// `body` took in its turn: the time the keychain needed, without the
    /// time spent waiting in the queue.
    func performMeasured<Value: Sendable>(
        _ source: ActivationSigningSource,
        channel: String? = nil,
        renewalIsUrgent: Bool = false,
        _ body: @Sendable () async throws -> Value
    ) async throws -> (value: Value, duration: TimeInterval) {
        if source.isAutomatic, admits(source, renewalIsUrgent: renewalIsUrgent) == false {
            throw ActivationError.signingDeferred
        }
        await waitForTurn(isUserAction: source == .userAction)
        defer { finishTurn() }
        if source.isAutomatic, admits(source, renewalIsUrgent: renewalIsUrgent) == false {
            throw ActivationError.signingDeferred
        }
        let startedAt = Date()
        do {
            let value = try await body()
            let duration = Date().timeIntervalSince(startedAt)
            record(.succeeded(duration: duration), from: source, channel: channel)
            return (value, duration)
        } catch {
            record(ActivationSigningOutcome(error: error), from: source, channel: channel)
            throw error
        }
    }

    private func waitForTurn(isUserAction: Bool) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let runsNow: Bool = lock.withLock {
                guard isKeyInUse else {
                    isKeyInUse = true
                    return true
                }
                let waiter = Waiter(isUserAction: isUserAction, continuation: continuation)
                if isUserAction, let index = waiters.firstIndex(where: { $0.isUserAction == false }) {
                    waiters.insert(waiter, at: index)
                } else {
                    waiters.append(waiter)
                }
                return false
            }
            if runsNow {
                continuation.resume()
            }
        }
    }

    /// How many uses are queued behind the one holding the key. Tests wait
    /// on it to know a use has joined the queue.
    var queuedUseCount: Int {
        lock.withLock { waiters.count }
    }

    /// Hands the key to the next queued use, or marks it free.
    private func finishTurn() {
        let next: Waiter? = lock.withLock {
            guard waiters.isEmpty == false else {
                isKeyInUse = false
                return nil
            }
            return waiters.removeFirst()
        }
        next?.continuation.resume()
    }

    // MARK: Events

    func record(_ outcome: ActivationSigningOutcome, from source: ActivationSigningSource, channel: String?) {
        let date = now()
        if outcome == .denied || outcome == .interactionNotAllowed {
            ActivationLogger.runtime.error(
                "license key use from \(String(describing: source), privacy: .public) refused: \(String(describing: outcome), privacy: .public)"
            )
        }
        if case let .succeeded(duration) = outcome, duration < ActivationSigningPolicy.promptThreshold,
           let markers, let identity = keyIdentity?()
        {
            markers.noteKeySignedWithoutPrompt(identity)
        }
        update(unblocksHandshakes: source == .userAction) {
            $0.record(outcome, from: source, channel: channel, at: date)
        }
    }

    func noteFirstWindowShown() {
        update(unblocksHandshakes: true) { $0.noteFirstWindowShown() }
    }

    func noteHandshakeFailed(onChannel channel: String) {
        update(unblocksHandshakes: false) { $0.noteHandshakeFailed(onChannel: channel) }
    }

    func noteChannelEnded(_ channel: String) {
        update(unblocksHandshakes: false) { $0.noteChannelEnded(channel) }
    }

    func noteActivationChanged() {
        update(unblocksHandshakes: true) { $0.noteActivationChanged() }
    }

    /// The Host created a new key: its access list lists the Host, so it
    /// never needs the explainer.
    func noteKeyCreatedByHost() {
        if let markers, let identity = keyIdentity?() {
            markers.noteKeyCreatedByHost(identity)
        }
        update(unblocksHandshakes: false) { $0.noteKeySignsWithoutPrompt() }
    }

    /// Continue in the keychain explainer: remembers it for the stored key,
    /// so the explainer does not come back for that key in a later launch,
    /// and lets the held-back uses start. The first of them raises the system
    /// prompt and counts as the user's use; Continue itself does not sign.
    func confirmExplainer() {
        if let markers, let identity = keyIdentity?() {
            markers.noteExplainerConfirmed(identity)
        }
        update(unblocksHandshakes: true) { $0.confirmExplainer() }
    }

    /// Not Now in the keychain explainer: a denial without a system prompt.
    func declineExplainer() {
        let date = now()
        update(unblocksHandshakes: false) { $0.declineExplainer(at: date) }
    }

    /// Ends the denial wait when it is over. The timer set at each denial
    /// calls it; a call before the end only sets the timer again.
    func noteDenialWaitEndedIfDue() {
        let date = now()
        let remaining: TimeInterval? = lock.withLock {
            guard let deniedUntil = policy.deniedUntil, date < deniedUntil else { return nil }
            return deniedUntil.timeIntervalSince(date)
        }
        if let remaining {
            scheduleTimer(remaining) { [weak self] in self?.noteDenialWaitEndedIfDue() }
            return
        }
        update(unblocksHandshakes: true) { $0.noteDenialWaitEnded(at: date) }
    }

    func addObserver(_ handler: @escaping @Sendable (ActivationSigningStatus) -> Void) -> ActivationObservation {
        let identifier = UUID()
        let initial: ActivationSigningStatus = lock.withLock {
            observers[identifier] = handler
            return makeStatus()
        }
        handler(initial)
        return ActivationObservation { [weak self] in
            self?.lock.withLock { _ = self?.observers.removeValue(forKey: identifier) }
        }
    }

    // MARK: State

    /// Runs the explainer assessment once, outside the lock: it reads the
    /// key's identity (attributes only, never a prompt). A stored key needs
    /// the explainer unless a marker covers it.
    private func assessExplainerIfNeeded() {
        let assesses: Bool = lock.withLock {
            defer { needsExplainerAssessment = false }
            return needsExplainerAssessment
        }
        guard assesses, let markers, let identity = keyIdentity?(), markers.mayNeedExplainer(forKey: identity)
        else { return }
        update(unblocksHandshakes: false) { $0.noteExplainerNeeded() }
    }

    /// Applies `change` and tells observers when the status changed. With
    /// `unblocksHandshakes`, the generation moves when the change lets a
    /// held-back handshake start: the first window appeared, the activation
    /// changed, Continue confirmed the explainer, a user action cleared a
    /// denial wait and failed channels, or the denial wait ended. A new
    /// denial wait sets the timer that ends it.
    private func update(unblocksHandshakes: Bool, _ change: (inout ActivationSigningPolicy) -> Void) {
        let result: (ActivationSigningStatus?, [@Sendable (ActivationSigningStatus) -> Void], Date?) =
            lock.withLock {
                let before = policy
                let statusBefore = makeStatus()
                change(&policy)
                guard before != policy else { return (nil, [], nil) }
                let deniedUntilChanged = before.deniedUntil != policy.deniedUntil
                let unblocked =
                    unblocksHandshakes
                        && (before.hasShownFirstWindow != policy.hasShownFirstWindow
                            || deniedUntilChanged
                            || before.explainer != policy.explainer
                            || before.failedHandshakeChannels != policy.failedHandshakeChannels)
                if unblocked {
                    generation += 1
                }
                let newWait = deniedUntilChanged ? policy.deniedUntil : nil
                let status = makeStatus()
                guard status != statusBefore else { return (nil, [], newWait) }
                return (status, Array(observers.values), newWait)
            }
        let (status, handlers, newWait) = result
        if let newWait {
            scheduleTimer(newWait.timeIntervalSince(now())) { [weak self] in self?.noteDenialWaitEndedIfDue() }
        }
        guard let status else { return }
        for handler in handlers {
            handler(status)
        }
    }

    private func makeStatus() -> ActivationSigningStatus {
        ActivationSigningStatus(
            keychainAccessDeniedUntil: policy.deniedUntil,
            hasShownFirstWindow: policy.hasShownFirstWindow,
            handshakeGeneration: generation,
            needsKeychainAccessExplainer: policy.isExplainerRequested,
            isKeychainAccessPostponed: policy.isDenialFromExplainer,
            isKeychainAccessAllowedOnce: policy.isKeyAllowedOnce
        )
    }
}
