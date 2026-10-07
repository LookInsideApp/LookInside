import Foundation
@testable import LookInsideActivation
import Security
import Testing

/// Using the license key can raise a login-keychain prompt. After the user
/// refuses it, no automatic path (handshake or silent renewal) may ask again
/// until the wait ends or the user clicks Try Again, and a channel whose
/// handshake failed must not loop.
struct SigningPolicyTests {
    private final class Clock: @unchecked Sendable {
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

    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0

        func increment() {
            lock.withLock { count += 1 }
        }

        var value: Int {
            lock.withLock { count }
        }
    }

    private static let launch = TestData.baseNow
    private static let afterLaunch = launch.addingTimeInterval(ActivationSigningPolicy.launchDelay)

    private func readyPolicy() -> ActivationSigningPolicy {
        var policy = ActivationSigningPolicy(launchedAt: Self.launch)
        policy.noteFirstWindowShown()
        return policy
    }

    // MARK: - Policy

    @Test func nothingSignsAutomaticallyBeforeTheFirstWindow() {
        var policy = ActivationSigningPolicy(launchedAt: Self.launch)
        let later = Self.launch.addingTimeInterval(3600)

        #expect(policy.allowsSigning(for: .licenseHandshake, at: later) == false)
        #expect(policy.allowsHandshake(onChannel: "c1", at: later) == false)
        #expect(policy.allowsSigning(for: .silentRenewal, at: later) == false)
        #expect(policy.allowsSigning(for: .userAction, at: Self.launch))

        policy.noteFirstWindowShown()
        // Handshakes start with the first window; renewal also waits for the
        // launch delay.
        #expect(policy.allowsHandshake(onChannel: "c1", at: Self.launch))
        #expect(policy.allowsSigning(for: .silentRenewal, at: Self.launch) == false)
        #expect(policy.allowsSigning(for: .silentRenewal, at: Self.afterLaunch))
    }

    @Test(arguments: [ActivationSigningSource.licenseHandshake, .silentRenewal])
    func denialStopsEveryAutomaticPath(from source: ActivationSigningSource) {
        var policy = readyPolicy()
        let deniedAt = Self.afterLaunch
        policy.record(.denied, from: source, channel: source == .licenseHandshake ? "c1" : nil, at: deniedAt)

        for minutes in [1.0, 30, 59] {
            let date = deniedAt.addingTimeInterval(minutes * 60)
            #expect(policy.allowsSigning(for: .licenseHandshake, at: date) == false)
            #expect(policy.allowsHandshake(onChannel: "c2", at: date) == false)
            #expect(policy.allowsSigning(for: .silentRenewal, at: date) == false)
            #expect(policy.allowsSigning(for: .userAction, at: date))
            #expect(policy.isKeychainAccessDenied(at: date))
        }
        let hourLater = deniedAt.addingTimeInterval(60 * 60)
        #expect(policy.allowsSigning(for: .silentRenewal, at: hourLater))
        #expect(policy.allowsHandshake(onChannel: "c2", at: hourLater))
        #expect(policy.isKeychainAccessDenied(at: hourLater) == false)
    }

    @Test func repeatedDenialWaitsADay() {
        var policy = readyPolicy()
        let first = Self.afterLaunch
        policy.record(.denied, from: .silentRenewal, at: first)
        let second = first.addingTimeInterval(60 * 60)
        policy.record(.denied, from: .licenseHandshake, at: second)

        #expect(policy.allowsSigning(for: .silentRenewal, at: second.addingTimeInterval(23 * 60 * 60)) == false)
        #expect(policy.allowsSigning(for: .silentRenewal, at: second.addingTimeInterval(24 * 60 * 60)))
        policy.record(.denied, from: .silentRenewal, at: second.addingTimeInterval(24 * 60 * 60))
        #expect(policy.deniedUntil == second.addingTimeInterval(48 * 60 * 60))
    }

    @Test func failedChannelIsNotRetriedUntilItReconnects() {
        var policy = readyPolicy()
        let date = Self.afterLaunch
        // A rejected 221 or a failed signing on c1.
        policy.noteHandshakeFailed(onChannel: "c1")
        policy.record(.failed, from: .licenseHandshake, channel: "c2", at: date)

        #expect(policy.allowsHandshake(onChannel: "c1", at: date.addingTimeInterval(3600)) == false)
        #expect(policy.allowsHandshake(onChannel: "c2", at: date.addingTimeInterval(3600)) == false)
        #expect(policy.allowsHandshake(onChannel: "c3", at: date))

        policy.noteChannelEnded("c1")
        #expect(policy.allowsHandshake(onChannel: "c1", at: date))
        #expect(policy.allowsHandshake(onChannel: "c2", at: date) == false)
    }

    @Test func activationChangeLetsFailedChannelsTryAgain() {
        var policy = readyPolicy()
        policy.noteHandshakeFailed(onChannel: "c1")
        policy.noteHandshakeFailed(onChannel: "c2")

        policy.noteActivationChanged()
        #expect(policy.allowsHandshake(onChannel: "c1", at: Self.afterLaunch))
        #expect(policy.allowsHandshake(onChannel: "c2", at: Self.afterLaunch))
    }

    @Test func explicitRetryClearsTheWaitAndFailedChannels() {
        var policy = readyPolicy()
        let deniedAt = Self.afterLaunch
        policy.record(.denied, from: .licenseHandshake, channel: "c1", at: deniedAt)
        policy.record(.denied, from: .silentRenewal, at: deniedAt.addingTimeInterval(3600))

        // Try Again took long: the user answered a prompt. It still clears.
        let retriedAt = deniedAt.addingTimeInterval(7200)
        policy.record(.succeeded(duration: 8), from: .userAction, at: retriedAt)
        #expect(policy.isKeychainAccessDenied(at: retriedAt) == false)
        #expect(policy.denialCount == 0)
        #expect(policy.allowsHandshake(onChannel: "c1", at: retriedAt))
        #expect(policy.allowsSigning(for: .silentRenewal, at: retriedAt))
    }

    @Test func deniedRetryWaitsLonger() {
        var policy = readyPolicy()
        let deniedAt = Self.afterLaunch
        policy.record(.denied, from: .silentRenewal, at: deniedAt)
        policy.record(.denied, from: .userAction, at: deniedAt.addingTimeInterval(60))
        #expect(policy.deniedUntil == deniedAt.addingTimeInterval(60 + 24 * 60 * 60))
    }

    /// A one-time Allow answers the prompt, so the signing is slow: it does
    /// not count as "the key no longer prompts", and the next denial
    /// escalates. A fast signing means no prompt and resets the count.
    @Test func onlyAFastAutomaticSuccessResetsTheDenialCount() {
        var policy = readyPolicy()
        let deniedAt = Self.afterLaunch
        policy.record(.denied, from: .silentRenewal, at: deniedAt)

        let resumed = deniedAt.addingTimeInterval(3600)
        policy.record(.succeeded(duration: 6), from: .licenseHandshake, channel: "c1", at: resumed)
        #expect(policy.denialCount == 1)
        policy.record(.denied, from: .licenseHandshake, channel: "c2", at: resumed)
        #expect(policy.deniedUntil == resumed.addingTimeInterval(24 * 60 * 60))

        let later = resumed.addingTimeInterval(24 * 60 * 60)
        policy.record(.succeeded(duration: 0.05), from: .silentRenewal, at: later)
        #expect(policy.denialCount == 0)
        #expect(policy.deniedUntil == nil)
    }

    @Test func lockedKeychainIsNotADenial() {
        var policy = readyPolicy()
        let date = Self.afterLaunch
        policy.record(.interactionNotAllowed, from: .licenseHandshake, channel: "c1", at: date)

        #expect(policy.denialCount == 0)
        #expect(policy.isKeychainAccessDenied(at: date) == false)
        #expect(policy.allowsSigning(for: .silentRenewal, at: date.addingTimeInterval(60)) == false)
        // No channel memory: the same channel retries after the short pause.
        let afterPause = date.addingTimeInterval(ActivationSigningPolicy.interactionNotAllowedDelay)
        #expect(policy.allowsHandshake(onChannel: "c1", at: afterPause))
        #expect(policy.allowsSigning(for: .silentRenewal, at: afterPause))

        policy.record(.interactionNotAllowed, from: .silentRenewal, at: afterPause)
        policy.record(.interactionNotAllowed, from: .silentRenewal, at: afterPause.addingTimeInterval(300))
        #expect(policy.denialCount == 0)
        #expect(policy.pausedUntil == afterPause.addingTimeInterval(600))
    }

    @Test func outcomesMapFromKeychainErrors() {
        #expect(ActivationSigningOutcome(error: ActivationError.keychainAccessDenied(errSecUserCanceled)) == .denied)
        #expect(ActivationSigningOutcome(error: ActivationError.keychainAccessDenied(errSecAuthFailed)) == .denied)
        #expect(
            ActivationSigningOutcome(error: ActivationError.keychainAccessDenied(errSecInteractionNotAllowed))
                == .interactionNotAllowed
        )
        #expect(ActivationSigningOutcome(error: ActivationError.keychainFailure("x")) == .failed)
        #expect(ActivationSigningOutcome(error: URLError(.notConnectedToInternet)) == .failed)
    }

    // MARK: - Gate

    @Test func gateRunsNothingWhileWaiting() async throws {
        let clock = Clock(Self.afterLaunch)
        let gate = ActivationSigningGate.open(now: { clock.now })
        let keychainCalls = Counter()

        await #expect(throws: ActivationError.keychainAccessDenied(errSecUserCanceled)) {
            try await gate.perform(.licenseHandshake, channel: "c1") {
                keychainCalls.increment()
                throw ActivationError.keychainAccessDenied(errSecUserCanceled)
            }
        }
        // The slow-signing retry, another channel and renewal all stop
        // before the keychain.
        for source in [ActivationSigningSource.licenseHandshake, .silentRenewal] {
            await #expect(throws: ActivationError.signingDeferred) {
                try await gate.perform(source, channel: "c2") {
                    keychainCalls.increment()
                }
            }
        }
        #expect(keychainCalls.value == 1)
        #expect(gate.allowsHandshake(onChannel: "c3") == false)

        // Try Again is the only way to ask during the wait.
        try await gate.perform(.userAction) {
            keychainCalls.increment()
        }
        #expect(keychainCalls.value == 2)
        #expect(gate.allowsHandshake(onChannel: "c1"))
    }

    @Test func gateTellsObserversWhenHeldBackHandshakesMayStart() {
        let clock = Clock(Self.afterLaunch)
        let gate = ActivationSigningGate(launchedAt: Self.launch, now: { clock.now })
        let statuses = StatusRecorder()
        let observation = gate.addObserver { statuses.append($0) }
        defer { observation.cancel() }

        gate.noteFirstWindowShown()
        gate.record(.denied, from: .silentRenewal, channel: nil)
        gate.noteHandshakeFailed(onChannel: "c1")
        gate.noteChannelEnded("c1")
        gate.record(.succeeded(duration: 3), from: .userAction, channel: nil)

        let recorded = statuses.values
        #expect(recorded.map(\.handshakeGeneration) == [0, 1, 1, 2])
        #expect(recorded.map { $0.isKeychainAccessDenied(at: clock.now) } == [false, false, true, false])
    }

    private final class StatusRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [ActivationSigningStatus] = []

        func append(_ status: ActivationSigningStatus) {
            lock.withLock { stored.append(status) }
        }

        var values: [ActivationSigningStatus] {
            lock.withLock { stored }
        }
    }

    // MARK: - Runtime

    private func makeRuntime(directory: URL, clock: Clock, keyStore: IntermediateKeyStoreConfiguration? = nil)
        -> ActivationRuntime
    {
        ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(stateDirectoryURL: directory, keyStore: keyStore),
            urlSession: .shared,
            now: { clock.now },
            silentRenewalEnabled: false
        )
    }

    /// `signChallenge` reaches the keychain only when the policy allows it.
    /// The isolated keychain path does not exist, so a call that reaches the
    /// key store fails with `.keychainFailure`; `.signingDeferred` proves the
    /// keychain was never touched.
    @Test func runtimeHandshakeSigningFollowsThePolicy() async throws {
        let input = try HelperFixtures.challengeInput()
        let directory = try HelperFixtures.makeStateDirectory(copying: "helper-state-full.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let clock = Clock(input.evaluatedAt)
        let runtime = makeRuntime(directory: directory, clock: clock)

        await #expect(throws: ActivationError.signingDeferred) {
            try await runtime.signChallenge(nonce: input.nonce, serverInstanceID: "srv", channel: "c1")
        }

        runtime.noteFirstWindowShown()
        await #expect {
            try await runtime.signChallenge(nonce: input.nonce, serverInstanceID: "srv", channel: "c1")
        } throws: { error in
            guard case .keychainFailure = error as? ActivationError else { return false }
            return true
        }
        // The failed signing is remembered for c1 only.
        #expect(runtime.allowsLicenseHandshake(onChannel: "c1") == false)
        #expect(runtime.allowsLicenseHandshake(onChannel: "c2"))
        runtime.noteLicenseHandshakeChannelEnded("c1")
        #expect(runtime.allowsLicenseHandshake(onChannel: "c1"))

        runtime.signingGate.record(.denied, from: .silentRenewal, channel: nil)
        await #expect(throws: ActivationError.signingDeferred) {
            try await runtime.signChallenge(nonce: input.nonce, serverInstanceID: "srv", channel: "c2")
        }
        #expect(runtime.isKeychainAccessDenied())
    }

    @Test func runtimeActivationChangeResetsChannelMemory() async throws {
        let input = try HelperFixtures.challengeInput()
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let clock = Clock(input.evaluatedAt)
        let runtime = makeRuntime(directory: directory, clock: clock)
        runtime.noteFirstWindowShown()

        runtime.noteLicenseHandshakeFailed(onChannel: "c1")
        await runtime.currentDecision()
        #expect(runtime.allowsLicenseHandshake(onChannel: "c1") == false)

        // Another process activates this Mac.
        try HelperFixtures.data("helper-state-full.json")
            .write(to: directory.appendingPathComponent("state.json"), options: .atomic)
        #expect(await runtime.currentDecision().grantsAccess)
        #expect(runtime.allowsLicenseHandshake(onChannel: "c1"))
    }

    @MainActor
    @Test func runtimeTryAgainClearsTheWaitAndUpdatesTheLicenseWindow() async throws {
        var interactionAllowed: DarwinBoolean = true
        SecKeychainGetUserInteractionAllowed(&interactionAllowed)
        SecKeychainSetUserInteractionAllowed(false)
        defer { SecKeychainSetUserInteractionAllowed(interactionAllowed.boolValue) }
        let keychain = try TemporaryKeychain()
        defer { keychain.delete() }
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let clock = Clock(Self.afterLaunch)
        let runtime = makeRuntime(
            directory: directory,
            clock: clock,
            keyStore: IntermediateKeyStoreConfiguration(
                applicationTag: "com.lookinside.activation.tests.\(UUID().uuidString)",
                keychainPath: keychain.path
            )
        )
        runtime.noteFirstWindowShown()
        let model = runtime.activationModel()

        // No key yet: Try Again never creates one.
        await #expect(throws: ActivationError.self) {
            try await runtime.retryKeychainAccess()
        }
        #expect(runtime.keyStore.hasPrivateKey() == false)

        _ = try runtime.keyStore.sign(message: Data("create".utf8))
        runtime.signingGate.record(.denied, from: .licenseHandshake, channel: "c1")
        try await waitUntil { model.keychainAccessNotice != nil }
        let generation = runtime.signingStatus.handshakeGeneration

        await model.retryKeychainAccess()
        #expect(runtime.isKeychainAccessDenied() == false)
        #expect(runtime.allowsLicenseHandshake(onChannel: "c1"))
        #expect(runtime.signingStatus.handshakeGeneration == generation + 1)
        try await waitUntil { model.keychainAccessNotice == nil }
    }

    @MainActor
    private func waitUntil(_ condition: @MainActor () -> Bool) async throws {
        // 30 s budget for a loaded machine; normally a few polls suffice.
        for _ in 0 ..< 1500 where condition() == false {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(condition())
    }
}
