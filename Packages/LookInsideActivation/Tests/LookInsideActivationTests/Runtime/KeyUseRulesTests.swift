import Foundation
@testable import LookInsideActivation
import Security
import Testing

/// For a key the 2.3.x helper created, every use raises a keychain prompt
/// until the user picks Always Allow. These tests pin the rules that keep
/// automatic uses bounded: renewal backoff and CSR reuse, the one-at-a-time
/// key queue, the end of a denial wait, and the keychain explainer.
struct KeyUseRulesTests {
    final class Clock: @unchecked Sendable {
        private let lock = NSLock()
        private var current: Date

        init(_ date: Date) {
            current = date
        }

        var now: Date {
            get { lock.withLock { current } }
            set { lock.withLock { current = newValue } }
        }
    }

    final class Log: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [String] = []

        func append(_ entry: String) {
            lock.withLock { stored.append(entry) }
        }

        var values: [String] {
            lock.withLock { stored }
        }

        func count(of entry: String) -> Int {
            values.filter { $0 == entry }.count
        }
    }

    /// An issuer that fails while `failures` is above zero, recording each
    /// CSR it receives.
    final class Issuer: IntermediateCertificateIssuing, @unchecked Sendable {
        private let lock = NSLock()
        private var remainingFailures: Int
        private var received: [String] = []

        init(failures: Int) {
            remainingFailures = failures
        }

        var csrs: [String] {
            lock.withLock { received }
        }

        func issueIntermediateCertificate(
            _ request: IntermediateCertificateIssueRequest
        ) async throws -> IntermediateCertificateLease {
            let fails: Bool = lock.withLock {
                received.append(request.certificateSigningRequestPEM)
                guard remainingFailures > 0 else { return false }
                remainingFailures -= 1
                return true
            }
            if fails {
                throw URLError(.notConnectedToInternet)
            }
            return TestData.makeIntermediateCertificateLease(
                certificateID: "renewed",
                issuedAt: TestData.baseNow,
                expiresAt: TestData.baseNow.addingTimeInterval(30 * 24 * 3600),
                renewAfter: TestData.baseNow.addingTimeInterval(20 * 24 * 3600)
            )
        }
    }

    final class Box<Value: Sendable>: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Value

        init(_ value: Value) {
            stored = value
        }

        var value: Value {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }
    }

    static let launch = TestData.baseNow
    static let afterLaunch = launch.addingTimeInterval(ActivationSigningPolicy.launchDelay)

    static func makeDueStore(
        now: Date,
        expiresIn: TimeInterval = 6 * 24 * 3600,
        lastFailureAt: Date? = nil
    ) async throws -> ActivationStateStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LookInsideActivationTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("state.json")
        let store = ActivationStateStore(url: url)
        let license = LicenseEnvelope(
            licenseID: "license-123",
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: now.addingTimeInterval(-86400),
            expiresAt: now.addingTimeInterval(365 * 86400),
            certificateChain: TestData.makeCertificateChain()
        )
        let lease = TestData.makeIntermediateCertificateLease(
            issuedAt: now.addingTimeInterval(-20 * 86400),
            expiresAt: now.addingTimeInterval(expiresIn),
            renewAfter: now.addingTimeInterval(-3600)
        )
        try await store.recordActivationSession(
            TestData.makeActivationSession(expiresAt: now.addingTimeInterval(3 * 86400))
        )
        try await store.recordEntitlementStatus(TestData.makeEntitlementStatus(license: license, currentLease: lease))
        if let lastFailureAt {
            try await store.recordRenewAttempt(success: false, error: "offline", at: lastFailureAt)
        }
        return store
    }

    // MARK: - Renewal backoff

    @Test func retryDelaysGrowAndCapAtTwelveHours() {
        let delays = (1 ... 7).map { ActivationCertificateRenewer.retryDelay(afterFailures: $0, isUrgent: false) }
        #expect(delays == [300, 900, 3600, 21600, 43200, 43200, 43200])
        let urgent = (1 ... 7).map { ActivationCertificateRenewer.retryDelay(afterFailures: $0, isUrgent: true) }
        #expect(urgent == [300, 900, 3600, 3600, 3600, 3600, 3600])
        #expect(ActivationCertificateRenewer.retryDelay(afterFailures: 0, isUrgent: false) == 0)
    }

    /// Offline: the issuer fails after the CSR was signed. Retries reuse
    /// that CSR, so a one-time-Allow user sees one prompt for the whole run.
    @Test func retriesReuseTheSignedCSRWhileTheKeyIsUnchanged() async throws {
        let clock = Clock(Self.launch)
        let store = try await Self.makeDueStore(now: Self.launch)
        let issuer = Issuer(failures: 3)
        let signings = Log()
        let identity = Box(Data([1]))
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { issuer },
            csrProvider: {
                signings.append("sign")
                return "csr-\(signings.values.count)"
            },
            keyIdentity: { identity.value },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: .open(now: { clock.now })
        )

        await renewer.tryRenewIfDue()
        for minutes in [5.0, 20, 80] {
            clock.now = Self.launch.addingTimeInterval(minutes * 60)
            await renewer.tryRenewIfDue()
        }
        #expect(signings.values.count == 1)
        #expect(issuer.csrs == ["csr-1", "csr-1", "csr-1", "csr-1"])
        #expect(await store.snapshot().lastRenewSucceededAt == clock.now)

        // The next cycle signs a new CSR.
        try await store.recordIssuedLease(
            TestData.makeIntermediateCertificateLease(
                issuedAt: Self.launch,
                expiresAt: clock.now.addingTimeInterval(3 * 86400),
                renewAfter: clock.now
            )
        )
        await renewer.tryRenewIfDue()
        #expect(signings.values.count == 2)
    }

    @Test func aChangedKeySignsAgain() async throws {
        let clock = Clock(Self.launch)
        let store = try await Self.makeDueStore(now: Self.launch)
        let issuer = Issuer(failures: 1)
        let signings = Log()
        let identity = Box(Data([1]))
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { issuer },
            csrProvider: {
                signings.append("sign")
                return "csr-\(signings.values.count)"
            },
            keyIdentity: { identity.value },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: .open(now: { clock.now })
        )

        await renewer.tryRenewIfDue()
        identity.value = Data([2])
        clock.now = Self.launch.addingTimeInterval(5 * 60)
        await renewer.tryRenewIfDue()
        #expect(issuer.csrs == ["csr-1", "csr-2"])
    }

    /// An issuer that fails once with `error`, then succeeds.
    final class FailingOnceIssuer: IntermediateCertificateIssuing, @unchecked Sendable {
        private let lock = NSLock()
        private var pending: (any Error)?
        private var received: [String] = []

        init(_ error: any Error) {
            pending = error
        }

        var csrs: [String] {
            lock.withLock { received }
        }

        func issueIntermediateCertificate(
            _ request: IntermediateCertificateIssueRequest
        ) async throws -> IntermediateCertificateLease {
            let error: (any Error)? = lock.withLock {
                received.append(request.certificateSigningRequestPEM)
                defer { pending = nil }
                return pending
            }
            if let error {
                throw error
            }
            return TestData.makeIntermediateCertificateLease(certificateID: "renewed")
        }
    }

    /// A permanent rejection (4xx) drops the cached CSR, so the retry signs
    /// a fresh one; a 5xx, a timeout or rate limiting keeps it.
    @Test(arguments: [(400, true), (422, true), (401, true), (408, false), (429, false), (500, false), (503, false)])
    func aPermanentRejectionDropsTheCachedCSR(statusCode: Int, signsAgain: Bool) async throws {
        let clock = Clock(Self.launch)
        let store = try await Self.makeDueStore(now: Self.launch)
        let issuer = FailingOnceIssuer(
            LookInsideAuthenticatorAPIClientError.api(statusCode: statusCode, code: "rejected", message: "no")
        )
        let signings = Log()
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { issuer },
            csrProvider: {
                signings.append("sign")
                return "csr-\(signings.values.count)"
            },
            keyIdentity: { Data([1]) },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: .open(now: { clock.now })
        )

        await renewer.tryRenewIfDue()
        clock.now = Self.launch.addingTimeInterval(5 * 60)
        await renewer.tryRenewIfDue()
        #expect(issuer.csrs == ["csr-1", signsAgain ? "csr-2" : "csr-1"])
        #expect(ActivationCertificateRenewer.rejectsCSRPermanently(URLError(.timedOut)) == false)
    }

    @Test func withoutAKeyIdentityEachAttemptSignsOnce() async throws {
        let clock = Clock(Self.launch)
        let store = try await Self.makeDueStore(now: Self.launch)
        let issuer = Issuer(failures: 5)
        let signings = Log()
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { issuer },
            csrProvider: {
                signings.append("sign")
                return "csr"
            },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: .open(now: { clock.now })
        )
        // Calls every 30 s for an hour: attempts at 0, 5 and 20 minutes.
        for step in 0 ... 120 {
            clock.now = Self.launch.addingTimeInterval(Double(step) * 30)
            await renewer.tryRenewIfDue()
        }
        #expect(signings.values.count == 3)
        #expect(issuer.csrs.count == 3)
    }

    @Test func inTheLastDayRetriesAreAtMostHourly() async throws {
        let clock = Clock(Self.launch)
        let store = try await Self.makeDueStore(now: Self.launch, expiresIn: 20 * 3600)
        let issuer = Issuer(failures: 100)
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { issuer },
            csrProvider: { "csr" },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: .open(now: { clock.now })
        )
        for step in 0 ... (6 * 60) {
            clock.now = Self.launch.addingTimeInterval(Double(step) * 60)
            await renewer.tryRenewIfDue()
        }
        // 0, 5 min, 20 min, 80 min, then hourly: 140, 200, 260, 320 min.
        #expect(issuer.csrs.count == 8)
    }

    @Test func aFailureFromAnEarlierLaunchDelaysTheFirstAttempt() async throws {
        let clock = Clock(Self.launch)
        let store = try await Self.makeDueStore(now: Self.launch, lastFailureAt: Self.launch.addingTimeInterval(-60))
        let issuer = Issuer(failures: 0)
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { issuer },
            csrProvider: { "csr" },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: .open(now: { clock.now })
        )
        await renewer.tryRenewIfDue()
        #expect(issuer.csrs.isEmpty)
        clock.now = Self.launch.addingTimeInterval(4 * 60)
        await renewer.tryRenewIfDue()
        #expect(issuer.csrs.count == 1)
    }

    /// A slow automatic signing was a one-time Allow: renewal does not sign
    /// again for six hours, unless the lease ends within a day.
    @Test(arguments: [false, true])
    func slowAutomaticSigningPausesRenewal(leaseEndsWithinADay: Bool) async throws {
        let clock = Clock(Self.afterLaunch)
        let store = try await Self.makeDueStore(
            now: Self.afterLaunch,
            expiresIn: leaseEndsWithinADay ? 20 * 3600 : 6 * 86400
        )
        let issuer = Issuer(failures: 0)
        let gate = ActivationSigningGate(launchedAt: Self.launch, now: { clock.now })
        gate.noteFirstWindowShown()
        gate.record(.succeeded(duration: 4), from: .licenseHandshake, channel: "c1")
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { issuer },
            csrProvider: { "csr" },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: gate
        )

        clock.now = Self.afterLaunch.addingTimeInterval(5 * 3600)
        await renewer.tryRenewIfDue()
        #expect(issuer.csrs.count == (leaseEndsWithinADay ? 1 : 0))

        clock.now = Self.afterLaunch.addingTimeInterval(6 * 3600)
        await renewer.tryRenewIfDue()
        #expect(issuer.csrs.count == 1)
    }

    @Test func aHeldBackAttemptIsNotAFailure() async throws {
        let clock = Clock(Self.launch)
        let store = try await Self.makeDueStore(now: Self.launch)
        let issuer = Issuer(failures: 0)
        let gate = ActivationSigningGate(launchedAt: Self.launch, now: { clock.now })
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { issuer },
            csrProvider: { "csr" },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: gate
        )
        await renewer.tryRenewIfDue()
        #expect(await store.snapshot().lastRenewAttemptAt == nil)

        gate.noteFirstWindowShown()
        clock.now = Self.afterLaunch
        await renewer.tryRenewIfDue()
        #expect(issuer.csrs.count == 1)
    }

    // MARK: - One key use at a time

    /// A signer that blocks until released, recording how many uses run at
    /// once.
    final class BlockingSigner: @unchecked Sendable {
        private let lock = NSLock()
        private var running = 0
        private(set) var maximumRunning = 0
        private var gates: [CheckedContinuation<Void, Never>] = []
        private var started: [String] = []

        var startedLabels: [String] {
            lock.withLock { started }
        }

        var waitingCount: Int {
            lock.withLock { gates.count }
        }

        func sign(_ label: String) async {
            lock.withLock {
                running += 1
                maximumRunning = max(maximumRunning, running)
                started.append(label)
            }
            await withCheckedContinuation { continuation in
                lock.withLock { gates.append(continuation) }
            }
            lock.withLock { running -= 1 }
        }

        /// Lets the oldest blocked use finish.
        func releaseOne() {
            let next: CheckedContinuation<Void, Never>? = lock.withLock {
                gates.isEmpty ? nil : gates.removeFirst()
            }
            next?.resume()
        }
    }

    /// Polls `condition` until it holds. The budget (30 s) only matters
    /// on a loaded machine; normally the condition holds within a few polls.
    static func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0 ..< 6000 where condition() == false {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(condition())
    }

    @Test func keyUsesRunOneAtATimeAndUserActionsGoFirst() async throws {
        let gate = ActivationSigningGate.open()
        let signer = BlockingSigner()
        let first = Task { try await gate.perform(.licenseHandshake, channel: "c1") { await signer.sign("c1") } }
        try await Self.waitUntil { signer.startedLabels == ["c1"] }

        // Each use joins the queue before the next one starts, so the
        // queue order is fixed: c2, renewal, then user jumping ahead of both.
        let second = Task { try await gate.perform(.licenseHandshake, channel: "c2") { await signer.sign("c2") } }
        try await Self.waitUntil { gate.queuedUseCount == 1 }
        let renewal = Task { try await gate.perform(.silentRenewal) { await signer.sign("renewal") } }
        try await Self.waitUntil { gate.queuedUseCount == 2 }
        let user = Task { try await gate.perform(.userAction) { await signer.sign("user") } }
        try await Self.waitUntil { gate.queuedUseCount == 3 }
        #expect(signer.startedLabels == ["c1"])

        for expected in [["c1", "user"], ["c1", "user", "c2"], ["c1", "user", "c2", "renewal"]] {
            signer.releaseOne()
            try await Self.waitUntil { signer.startedLabels == expected }
        }
        signer.releaseOne()
        for task in [first, second, renewal, user] {
            try await task.value
        }
        #expect(signer.maximumRunning == 1)
    }

    /// A denial in the use in progress cancels every automatic use queued
    /// behind it.
    @Test func aDenialCancelsTheAutomaticUsesQueuedBehindIt() async throws {
        let gate = ActivationSigningGate.open()
        let signer = BlockingSigner()
        let ran = Log()
        let denied = Task {
            try await gate.perform(.licenseHandshake, channel: "c1") {
                await signer.sign("c1")
                throw ActivationError.keychainAccessDenied(errSecUserCanceled)
            }
        }
        try await Self.waitUntil { signer.startedLabels == ["c1"] }
        let queued = [
            Task { try await gate.perform(.licenseHandshake, channel: "c2") { ran.append("c2") } },
            Task { try await gate.perform(.silentRenewal) { ran.append("renewal") } },
        ]
        try await Self.waitUntil { gate.queuedUseCount == 2 }

        signer.releaseOne()
        await #expect(throws: ActivationError.keychainAccessDenied(errSecUserCanceled)) { try await denied.value }
        for task in queued {
            await #expect(throws: ActivationError.signingDeferred) { try await task.value }
        }
        #expect(ran.values.isEmpty)
        // Try Again still asks, and clears the wait.
        try await gate.perform(.userAction) { ran.append("user") }
        try await gate.perform(.licenseHandshake, channel: "c2") { ran.append("c2") }
        #expect(ran.values == ["user", "c2"])
    }

    /// Time spent waiting in the queue is not keychain time: a fast use
    /// that waited still counts as signing without a prompt, and its
    /// measured duration leaves the wait out.
    @Test func durationIsMeasuredFromTheTurn() async throws {
        let (markers, stored) = Self.markers()
        markers.noteExplainerConfirmed("key-a")
        let gate = ActivationSigningGate(
            launchedAt: .distantPast,
            now: { Date() },
            markers: markers,
            keyIdentity: { "key-a" }
        )
        gate.noteFirstWindowShown()
        let signer = BlockingSigner()
        let blocking = Task { try await gate.perform(.userAction) { await signer.sign("user") } }
        try await Self.waitUntil { signer.startedLabels == ["user"] }
        let waiting = Task { try await gate.performMeasured(.licenseHandshake, channel: "c1") { () } }
        try await Task.sleep(for: .milliseconds(1200))
        signer.releaseOne()
        try await blocking.value
        let measured = try await waiting.value
        #expect(measured.duration < ActivationSigningPolicy.promptThreshold)
        #expect(stored.value[KeychainAccessMarkers.keySignedWithoutPromptKey] == "key-a")
    }

    // MARK: - End of a denial wait

    final class TimerRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [(TimeInterval, @Sendable () -> Void)] = []

        var scheduler: ActivationSigningGate.TimerScheduler {
            { [self] delay, fire in lock.withLock { stored.append((delay, fire)) } }
        }

        var delays: [TimeInterval] {
            lock.withLock { stored.map(\.0) }
        }

        func fireLast() {
            let fire = lock.withLock { stored.last?.1 }
            fire?()
        }
    }

    @Test func policyEndsTheWaitAndFreesOnlyDeniedChannels() {
        var policy = ActivationSigningPolicy(launchedAt: Self.launch)
        policy.noteFirstWindowShown()
        policy.record(.denied, from: .licenseHandshake, channel: "denied", at: Self.afterLaunch)
        policy.noteHandshakeFailed(onChannel: "rejected")

        policy.noteDenialWaitEnded(at: Self.afterLaunch.addingTimeInterval(59 * 60))
        #expect(policy.deniedUntil != nil)

        let end = Self.afterLaunch.addingTimeInterval(3600)
        policy.noteDenialWaitEnded(at: end)
        #expect(policy.deniedUntil == nil)
        #expect(policy.allowsHandshake(onChannel: "denied", at: end))
        #expect(policy.allowsHandshake(onChannel: "rejected", at: end) == false)
        // The count stays: the next denial waits a day.
        policy.record(.denied, from: .silentRenewal, at: end)
        #expect(policy.deniedUntil == end.addingTimeInterval(24 * 3600))
    }

    @Test func gateFiresATimerWhenTheWaitEnds() {
        let clock = Clock(Self.afterLaunch)
        let timers = TimerRecorder()
        let gate = ActivationSigningGate(launchedAt: Self.launch, now: { clock.now }, scheduleTimer: timers.scheduler)
        gate.noteFirstWindowShown()
        let statuses = Box<[ActivationSigningStatus]>([])
        let observation = gate.addObserver { status in statuses.value.append(status) }
        defer { observation.cancel() }

        gate.record(.denied, from: .licenseHandshake, channel: "c1")
        #expect(timers.delays == [3600])
        #expect(gate.allowsHandshake(onChannel: "c1") == false)

        // A timer that fires early sets itself again.
        clock.now = Self.afterLaunch.addingTimeInterval(1800)
        timers.fireLast()
        #expect(timers.delays == [3600, 1800])
        #expect(gate.status.isKeychainAccessDenied(at: clock.now))

        let generation = gate.status.handshakeGeneration
        clock.now = Self.afterLaunch.addingTimeInterval(3600)
        timers.fireLast()
        #expect(gate.status.keychainAccessDeniedUntil == nil)
        #expect(gate.status.handshakeGeneration == generation + 1)
        #expect(gate.allowsHandshake(onChannel: "c1"))
        #expect(statuses.value.last?.isKeychainAccessDenied(at: clock.now) == false)
    }

    // MARK: - Keychain explainer

    static func markers() -> (KeychainAccessMarkers, Box<[String: String]>) {
        let stored = Box<[String: String]>([:])
        let markers = KeychainAccessMarkers(
            read: { stored.value[$0] },
            write: { stored.value[$0] = $1 }
        )
        return (markers, stored)
    }

    /// A gate over a stored key named `key` (`nil`: no key), counting how
    /// often the key's identity is read in `identityReads`.
    static func explainerGate(
        clock: Clock,
        markers: KeychainAccessMarkers,
        key: String? = "key-a",
        identityReads: Log = Log()
    ) -> ActivationSigningGate {
        ActivationSigningGate(
            launchedAt: launch,
            now: { clock.now },
            markers: markers,
            keyIdentity: {
                identityReads.append("read")
                return key
            },
            scheduleTimer: { _, _ in }
        )
    }

    @Test func policyAsksForTheExplainerOnlyWhenNothingElseHoldsTheKeyBack() {
        var policy = ActivationSigningPolicy(launchedAt: Self.launch)
        policy.noteExplainerNeeded()
        #expect(policy.decision(for: .licenseHandshake, at: Self.afterLaunch) == .deferred)
        policy.noteFirstWindowShown()
        #expect(policy.decision(for: .licenseHandshake, at: Self.afterLaunch) == .needsExplainer)
        #expect(policy.decision(for: .silentRenewal, at: Self.launch) == .deferred)
        #expect(policy.decision(for: .silentRenewal, at: Self.afterLaunch) == .needsExplainer)
        #expect(policy.decision(for: .userAction, at: Self.launch) == .allowed)

        policy.declineExplainer(at: Self.afterLaunch)
        #expect(policy.decision(for: .licenseHandshake, at: Self.afterLaunch) == .deferred)
        #expect(policy.isKeychainAccessDenied(at: Self.afterLaunch))
        #expect(policy.isDenialFromExplainer)
        let later = Self.afterLaunch.addingTimeInterval(3600)
        #expect(policy.decision(for: .licenseHandshake, at: later) == .needsExplainer)

        policy.confirmExplainer()
        #expect(policy.decision(for: .licenseHandshake, at: later) == .allowed)
        #expect(policy.isContinuedUsePending)
        // The explainer shows at most once: a denial after Continue only
        // waits.
        policy.record(.denied, from: .licenseHandshake, channel: "c1", at: later)
        #expect(policy.explainer == .confirmed)
        #expect(policy.isContinuedUsePending == false)
        #expect(policy.isDenialFromExplainer == false)

        policy.record(.succeeded(duration: 0.1), from: .silentRenewal, at: later)
        #expect(policy.explainer == .notNeeded)
        policy.noteExplainerNeeded()
        #expect(policy.explainer == .notNeeded)
    }

    /// Continue does not use the key: the held-back handshake runs and is
    /// the one signing, counted as the user's. A slow answer (the user
    /// thinking over the dialog) does not mark the key as prompt-free, but
    /// the explainer does not come back in the next launch either.
    @Test func continueLetsTheHeldBackUseBeTheOnlySigning() async throws {
        let clock = Clock(Self.afterLaunch)
        let (markers, stored) = Self.markers()
        let gate = Self.explainerGate(clock: clock, markers: markers)
        let keychain = Log()

        // Nothing is assessed or requested before the first window.
        #expect(gate.allowsHandshake(onChannel: "c1") == false)
        #expect(gate.status.needsKeychainAccessExplainer == false)
        gate.noteFirstWindowShown()

        #expect(gate.allowsHandshake(onChannel: "c1") == false)
        #expect(gate.status.needsKeychainAccessExplainer)
        await #expect(throws: ActivationError.signingDeferred) {
            try await gate.perform(.silentRenewal) { keychain.append("renewal") }
        }
        #expect(keychain.values.isEmpty)

        let generation = gate.status.handshakeGeneration
        gate.confirmExplainer()
        #expect(keychain.values.isEmpty)
        #expect(gate.status.needsKeychainAccessExplainer == false)
        #expect(gate.status.handshakeGeneration == generation + 1)
        #expect(stored.value[KeychainAccessMarkers.explainerConfirmedKey] == "key-a")

        // The held-back handshake starts again and signs once.
        #expect(gate.allowsHandshake(onChannel: "c1"))
        try await gate.perform(.licenseHandshake, channel: "c1") { keychain.append("c1") }
        #expect(keychain.values == ["c1"])

        // The next launch does not show the explainer for this key.
        let next = Self.explainerGate(clock: clock, markers: markers)
        next.noteFirstWindowShown()
        #expect(next.allowsHandshake(onChannel: "c1"))
        #expect(next.status.needsKeychainAccessExplainer == false)
    }

    @Test func aSlowContinuedUseCountsAsTheUsersAndSuggestsAlwaysAllow() {
        let clock = Clock(Self.afterLaunch)
        let (markers, stored) = Self.markers()
        let gate = Self.explainerGate(clock: clock, markers: markers)
        gate.noteFirstWindowShown()
        #expect(gate.allowsHandshake(onChannel: "c1") == false)
        gate.confirmExplainer()

        // One-time Allow: slow, but the user's answer.
        gate.record(.succeeded(duration: 8), from: .licenseHandshake, channel: "c1")
        #expect(gate.status.isKeychainAccessAllowedOnce)
        #expect(KeychainAccessNotice(gate.status, at: clock.now) == .allowedOnce)
        #expect(stored.value[KeychainAccessMarkers.keySignedWithoutPromptKey] == nil)

        // The next app connects and asks again: still a one-time Allow.
        gate.record(.succeeded(duration: 6), from: .licenseHandshake, channel: "c2")
        #expect(gate.status.isKeychainAccessAllowedOnce)

        // Always Allow: the next signing is fast and the hint goes away.
        gate.record(.succeeded(duration: 0.05), from: .licenseHandshake, channel: "c3")
        #expect(gate.status.isKeychainAccessAllowedOnce == false)
        #expect(KeychainAccessNotice(gate.status, at: clock.now) == nil)
        #expect(stored.value[KeychainAccessMarkers.keySignedWithoutPromptKey] == "key-a")
    }

    @Test func aDenialAfterContinueWaitsWithoutTheExplainer() {
        let clock = Clock(Self.afterLaunch)
        let (markers, _) = Self.markers()
        let gate = Self.explainerGate(clock: clock, markers: markers)
        gate.noteFirstWindowShown()
        #expect(gate.allowsHandshake(onChannel: "c1") == false)
        gate.confirmExplainer()
        gate.record(.denied, from: .licenseHandshake, channel: "c1")
        #expect(gate.status.isKeychainAccessDenied(at: clock.now))
        #expect(KeychainAccessNotice(gate.status, at: clock.now) == .denied)

        clock.now = Self.afterLaunch.addingTimeInterval(3600)
        gate.noteDenialWaitEndedIfDue()
        #expect(gate.allowsHandshake(onChannel: "c1"))
        #expect(gate.status.needsKeychainAccessExplainer == false)
    }

    @Test func markersBelongToOneKey() {
        let clock = Clock(Self.afterLaunch)
        let (markers, _) = Self.markers()
        markers.noteExplainerConfirmed("key-a")
        markers.noteKeySignedWithoutPrompt("key-a")
        #expect(markers.mayNeedExplainer(forKey: "key-a") == false)
        #expect(markers.mayNeedExplainer(forKey: "key-b"))

        let gate = Self.explainerGate(clock: clock, markers: markers, key: "key-b")
        gate.noteFirstWindowShown()
        #expect(gate.allowsHandshake(onChannel: "c1") == false)
        #expect(gate.status.needsKeychainAccessExplainer)
    }

    @Test func notNowCountsAsADenialAndAsksAgainAfterTheWait() {
        let clock = Clock(Self.afterLaunch)
        let (markers, stored) = Self.markers()
        let gate = Self.explainerGate(clock: clock, markers: markers)
        gate.noteFirstWindowShown()
        #expect(gate.allowsHandshake(onChannel: "c1") == false)
        #expect(gate.status.needsKeychainAccessExplainer)

        gate.declineExplainer()
        #expect(gate.status.needsKeychainAccessExplainer == false)
        #expect(gate.status.isKeychainAccessDenied(at: clock.now))
        #expect(gate.status.isKeychainAccessPostponed)
        #expect(KeychainAccessNotice(gate.status, at: clock.now) == .postponed)
        #expect(gate.allowsHandshake(onChannel: "c1") == false)
        #expect(gate.status.needsKeychainAccessExplainer == false)

        clock.now = Self.afterLaunch.addingTimeInterval(3600)
        gate.noteDenialWaitEndedIfDue()
        #expect(gate.status.isKeychainAccessPostponed == false)
        #expect(gate.allowsHandshake(onChannel: "c1") == false)
        #expect(gate.status.needsKeychainAccessExplainer)
        #expect(stored.value.isEmpty)

        // Not Now is not remembered: the next launch explains again.
        let next = Self.explainerGate(clock: clock, markers: markers)
        next.noteFirstWindowShown()
        #expect(next.allowsHandshake(onChannel: "c1") == false)
        #expect(next.status.needsKeychainAccessExplainer)
    }

    @Test func noticeCopyMatchesTheReason() {
        let at = Self.afterLaunch
        func status(deniedFor: TimeInterval?, postponed: Bool = false, allowedOnce: Bool = false)
            -> ActivationSigningStatus
        {
            ActivationSigningStatus(
                keychainAccessDeniedUntil: deniedFor.map { at.addingTimeInterval($0) },
                hasShownFirstWindow: true,
                handshakeGeneration: 0,
                needsKeychainAccessExplainer: false,
                isKeychainAccessPostponed: postponed,
                isKeychainAccessAllowedOnce: allowedOnce
            )
        }
        #expect(KeychainAccessNotice(status(deniedFor: nil), at: at) == nil)
        #expect(KeychainAccessNotice(status(deniedFor: 60), at: at) == .denied)
        #expect(KeychainAccessNotice(status(deniedFor: 60, postponed: true), at: at) == .postponed)
        #expect(KeychainAccessNotice(status(deniedFor: -1, postponed: true), at: at) == nil)
        #expect(KeychainAccessNotice(status(deniedFor: nil, allowedOnce: true), at: at) == .allowedOnce)

        #expect(KeychainAccessNotice.postponed.message.contains("denied") == false)
        #expect(KeychainAccessNotice.allowedOnce.message.contains("Always Allow"))
        #expect(KeychainAccessNotice.denied.offersRetry)
        #expect(KeychainAccessNotice.postponed.offersRetry)
        #expect(KeychainAccessNotice.allowedOnce.offersRetry == false)
    }

    @Test func aSlowUserSigningConfirmsForTheLaunchOnly() {
        let clock = Clock(Self.afterLaunch)
        let (markers, stored) = Self.markers()
        let gate = Self.explainerGate(clock: clock, markers: markers)
        gate.noteFirstWindowShown()
        #expect(gate.allowsHandshake(onChannel: "c1") == false)

        gate.record(.succeeded(duration: 5), from: .userAction, channel: nil)
        #expect(gate.allowsHandshake(onChannel: "c1"))
        #expect(stored.value.isEmpty)

        let next = Self.explainerGate(clock: clock, markers: markers)
        next.noteFirstWindowShown()
        #expect(next.allowsHandshake(onChannel: "c1") == false)
    }

    @Test(arguments: [true, false])
    func hostCreatedOrMissingKeysNeverNeedTheExplainer(createdByHost: Bool) {
        let clock = Clock(Self.afterLaunch)
        let (markers, _) = Self.markers()
        if createdByHost {
            markers.noteKeyCreatedByHost("key-a")
        }
        let gate = Self.explainerGate(clock: clock, markers: markers, key: createdByHost ? "key-a" : nil)
        gate.noteFirstWindowShown()
        #expect(gate.allowsHandshake(onChannel: "c1"))
        #expect(gate.status.needsKeychainAccessExplainer == false)
    }

    @Test func theKeyIsAssessedOnlyOnce() {
        let clock = Clock(Self.afterLaunch)
        let (markers, _) = Self.markers()
        let reads = Log()
        let gate = Self.explainerGate(clock: clock, markers: markers, identityReads: reads)
        gate.noteFirstWindowShown()
        for _ in 0 ..< 3 {
            _ = gate.allowsHandshake(onChannel: "c1")
        }
        #expect(reads.values.count == 1)
    }

    @Test func aKeyCreatedDuringTheLaunchEndsTheExplainer() {
        let clock = Clock(Self.afterLaunch)
        let (markers, stored) = Self.markers()
        let gate = Self.explainerGate(clock: clock, markers: markers)
        gate.noteFirstWindowShown()
        #expect(gate.allowsHandshake(onChannel: "c1") == false)
        gate.noteKeyCreatedByHost()
        #expect(gate.allowsHandshake(onChannel: "c1"))
        #expect(gate.status.needsKeychainAccessExplainer == false)
        #expect(stored.value[KeychainAccessMarkers.keyCreatedByHostKey] == "key-a")
    }

    /// The key store reports a key it created, which sets the marker through
    /// the runtime. A test keychain never uses markers by default.
    @Test func runtimeMarksAKeyItCreates() throws {
        var interactionAllowed: DarwinBoolean = true
        SecKeychainGetUserInteractionAllowed(&interactionAllowed)
        SecKeychainSetUserInteractionAllowed(false)
        defer { SecKeychainSetUserInteractionAllowed(interactionAllowed.boolValue) }
        let keychain = try TemporaryKeychain()
        defer { keychain.delete() }
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (markers, stored) = Self.markers()
        let configuration = HelperFixtures.isolatedConfiguration(
            stateDirectoryURL: directory,
            keyStore: IntermediateKeyStoreConfiguration(
                applicationTag: "com.lookinside.activation.tests.\(UUID().uuidString)",
                keychainPath: keychain.path
            )
        )
        let runtime = ActivationRuntime(
            configuration: configuration,
            urlSession: .shared,
            now: { Self.afterLaunch },
            silentRenewalEnabled: false,
            keychainAccessMarkers: markers
        )
        _ = try runtime.keyStore.sign(message: Data("create".utf8))
        let identity = try runtime.keyStore.keyIdentity()
        #expect(identity?.count == 20)
        let hex = identity.map { $0.map { String(format: "%02x", $0) }.joined() }
        #expect(stored.value[KeychainAccessMarkers.keyCreatedByHostKey] == hex)
        _ = try runtime.keyStore.sign(message: Data("again".utf8))
        #expect(try runtime.keyStore.keyIdentity() == identity)

        let unmarked = ActivationRuntime(
            configuration: configuration,
            urlSession: .shared,
            now: { Self.afterLaunch },
            silentRenewalEnabled: false
        )
        unmarked.noteFirstWindowShown()
        #expect(unmarked.allowsLicenseHandshake(onChannel: "c1"))
    }
}
