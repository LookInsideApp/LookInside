import Foundation
import IOKit
@testable import LookInsideActivation
import Testing

/// The in-process facade that replaces the helper's socket RPCs. Every
/// runtime here uses a temporary state directory, a test-only key tag in a
/// keychain path that does not exist, and an unreachable local service URL.
struct ActivationRuntimeTests {
    private final class DecisionRecorder: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [ActivationAccessDecision] = []

        func append(_ decision: ActivationAccessDecision) {
            lock.withLock { stored.append(decision) }
        }

        var decisions: [ActivationAccessDecision] {
            lock.withLock { stored }
        }
    }

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

    private func makeRuntime(
        fixture: String?,
        clock: Clock
    ) throws -> (ActivationRuntime, URL) {
        let directory = try HelperFixtures.makeStateDirectory(copying: fixture)
        let runtime = ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(stateDirectoryURL: directory),
            urlSession: .shared,
            now: { clock.now },
            silentRenewalEnabled: false
        )
        return (runtime, directory)
    }

    @Test func emptyStateIsNotActivatedAndBlocks() async throws {
        let (runtime, directory) = try makeRuntime(fixture: nil, clock: Clock(HelperFixtureValues.base))
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(runtime.activationState == .notActivated)
        let decision = await runtime.currentDecision()
        #expect(decision == .activationRequired)
        #expect(await runtime.hasLicenseMaterial() == false)
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("state.json").path) == false)
    }

    @Test func helperStateIsActivatedBeforeFirstAsyncCall() async throws {
        let input = try HelperFixtures.challengeInput()
        let (runtime, directory) = try makeRuntime(
            fixture: "helper-state-full.json",
            clock: Clock(input.evaluatedAt)
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(runtime.activationState == .activated)
        let decision = await runtime.currentDecision()
        #expect(
            try ActivationStateCoding.encoder.encode(decision)
                == (HelperFixtures.data("helper-check-access.json"))
        )
        #expect(await runtime.hasLicenseMaterial())
        let snapshot = await runtime.snapshot()
        #expect(snapshot.activationResponse?.activation.licenseID == "lic_fixture_full")
    }

    /// Offline behaviour: access holds until the lease ends, then blocks.
    @Test func decisionFollowsTheClockOfflineAndPublishesChanges() async throws {
        let input = try HelperFixtures.challengeInput()
        let clock = Clock(input.evaluatedAt)
        let (runtime, directory) = try makeRuntime(fixture: "helper-state-full.json", clock: clock)
        defer { try? FileManager.default.removeItem(at: directory) }

        let recorder = DecisionRecorder()
        let observation = runtime.addDecisionObserver { recorder.append($0) }
        defer { observation.cancel() }
        #expect(recorder.decisions.map(\.decision) == [.allow])

        await runtime.currentDecision()
        #expect(recorder.decisions.count == 1)

        clock.now = input.expiredAt
        let expired = await runtime.currentDecision()
        #expect(expired.decision == .block)
        #expect(runtime.activationState == .notActivated)
        #expect(recorder.decisions.map(\.decision) == [.allow, .block])

        observation.cancel()
        clock.now = input.evaluatedAt
        await runtime.currentDecision()
        #expect(recorder.decisions.count == 2)
        #expect(runtime.activationState == .activated)
    }

    @Test func decisionStreamStartsWithCurrentDecision() async throws {
        let input = try HelperFixtures.challengeInput()
        let (runtime, directory) = try makeRuntime(
            fixture: "helper-state-full.json",
            clock: Clock(input.evaluatedAt)
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        var iterator = runtime.decisionUpdates().makeAsyncIterator()
        let first = await iterator.next()
        #expect(first?.decision == .allow)
    }

    @Test func signChallengeRejectsMalformedInputLikeHelper() async throws {
        let input = try HelperFixtures.challengeInput()
        let (runtime, directory) = try makeRuntime(
            fixture: "helper-state-full.json",
            clock: Clock(input.evaluatedAt)
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        await #expect(throws: ActivationError.invalidRequest("`nonce` must be 32 hex-encoded bytes.")) {
            try await runtime.signChallenge(nonce: Data(count: 16), serverInstanceID: "srv")
        }
        await #expect(
            throws: ActivationError.invalidRequest("`server_instance_id` must be a non-empty UTF-8 string.")
        ) {
            try await runtime.signChallenge(nonce: input.nonce, serverInstanceID: "")
        }
    }

    @Test func signChallengeRefusesWithoutActivation() async throws {
        let (runtime, directory) = try makeRuntime(fixture: nil, clock: Clock(HelperFixtureValues.base))
        defer { try? FileManager.default.removeItem(at: directory) }

        do {
            _ = try await runtime.signChallenge(nonce: Data(count: 32), serverInstanceID: "srv")
            Issue.record("expected a refusal")
        } catch let error as ActivationError {
            #expect(error.errorCode == "license_not_activated")
        }
    }

    /// `currentDecision()` schedules the silent renewal once the lease is in
    /// its renewal window and the Host allowed renewal after its first
    /// window; a failed attempt (unreachable local service) is recorded in
    /// `state.json` for the connectivity warning.
    @Test func currentDecisionSchedulesSilentRenewal() async throws {
        let input = try HelperFixtures.challengeInput()
        let directory = try HelperFixtures.makeStateDirectory(copying: "helper-state-full.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let renewalTime = input.evaluatedAt.addingTimeInterval(22 * HelperFixtureValues.day)
        let clock = Clock(renewalTime)
        let runtime = ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(stateDirectoryURL: directory),
            urlSession: .shared,
            now: { clock.now }
        )

        // Launching: no window yet, so no renewal (and no keychain prompt).
        let storedAttempt = await runtime.snapshot().lastRenewAttemptAt
        await runtime.currentDecision()
        try await Task.sleep(for: .milliseconds(300))
        #expect(await runtime.snapshot().lastRenewAttemptAt == storedAttempt)

        runtime.noteFirstWindowShown()
        await runtime.currentDecision()
        try await Task.sleep(for: .milliseconds(300))
        #expect(await runtime.snapshot().lastRenewAttemptAt == storedAttempt)

        let launchDelayLater = renewalTime.addingTimeInterval(ActivationSigningPolicy.launchDelay)
        clock.now = launchDelayLater
        await runtime.currentDecision()
        var recorded: Date?
        for _ in 0 ..< 100 {
            recorded = await runtime.snapshot().lastRenewFailedAt
            if recorded == launchDelayLater {
                break
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(recorded == launchDelayLater)
        let onDisk = ActivationStateStore.loadState(from: directory.appendingPathComponent("state.json"))
        #expect(onDisk.lastRenewFailedAt == launchDelayLater)
        #expect(onDisk.lastRenewAttemptAt == launchDelayLater)
    }

    /// A trial lives in memory only; a new runtime over the same directory
    /// does not see it, like a relaunched helper.
    @Test func trialStateDoesNotSurviveRuntimeRestart() async throws {
        let directory = try HelperFixtures.makeStateDirectory(copying: "helper-state-trial.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(stateDirectoryURL: directory),
            urlSession: .shared,
            now: { HelperFixtureValues.base },
            silentRenewalEnabled: false
        )

        #expect(runtime.activationState == .notActivated)
        let snapshot = await runtime.snapshot()
        #expect(snapshot.deviceFingerprint == HelperFixtureValues.fingerprint)
        #expect(snapshot.entitlementStatus == nil)
    }

    /// `ActivationDeviceFingerprint` reads the same IOPlatformUUID the helper
    /// used as the device identifier. The value is compared, never printed.
    @Test func fingerprintUsesIOPlatformUUID() throws {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        try #require(service != 0)
        defer { IOObjectRelease(service) }
        let expected =
            IORegistryEntryCreateCFProperty(
                service,
                kIOPlatformUUIDKey as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? String

        let fingerprint = try ActivationDeviceFingerprint.current()
        #expect(fingerprint.deviceID == expected)
        #expect(fingerprint.appBundleID == "app.lookinside.LookInsideAuthServer")
        #expect(fingerprint.operatingSystemVersion == ProcessInfo.processInfo.operatingSystemVersionString)
    }

    #if DEBUG
        @Test func debugOverridesRedirectServiceAndAddTrustedRoot() {
            let testRoot = TrustedRootPublicKey(
                certificateID: "root_test_activation",
                publicKeyPEM: "-----BEGIN PUBLIC KEY-----\nAA==\n-----END PUBLIC KEY-----\n",
                publicKeySHA256: ""
            )
            let url = URL(string: "http://127.0.0.1:8787")!
            ActivationDebugOverrides.serviceBaseURL = url
            ActivationDebugOverrides.additionalTrustedRoot = testRoot
            defer {
                ActivationDebugOverrides.serviceBaseURL = nil
                ActivationDebugOverrides.additionalTrustedRoot = nil
            }

            #expect(ActivationConfiguration.standard.serviceBaseURL == url)
            #expect(EmbeddedTrustedRoots.publicKey(for: "root_test_activation") == testRoot)
            #expect(EmbeddedTrustedRoots.publicKey(for: "root_prod_2026") == EmbeddedTrustedRoots.rootProd2026)
        }

        @Test func debugOverridesRedirectStateDirectoryAndKeychain() {
            let standard = ActivationConfiguration.standard
            #expect(standard.stateDirectoryURL == ActivationConfiguration.standardStateDirectoryURL)
            #expect(standard.keyStore == .standard)

            let stateDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("activation-debug-override-\(UUID().uuidString)", isDirectory: true)
            let keychainPath = stateDirectory.appendingPathComponent("test.keychain-db").path
            ActivationDebugOverrides.stateDirectoryURL = stateDirectory
            ActivationDebugOverrides.keychainPath = keychainPath
            defer {
                ActivationDebugOverrides.stateDirectoryURL = nil
                ActivationDebugOverrides.keychainPath = nil
            }

            let redirected = ActivationConfiguration.standard
            #expect(redirected.stateDirectoryURL == stateDirectory)
            #expect(redirected.stateFileURL.deletingLastPathComponent() == stateDirectory)
            #expect(redirected.keyStore.keychainPath == keychainPath)
            #expect(redirected.keyStore.applicationTag == ActivationDebugOverrides.testKeyApplicationTag)
            #expect(redirected.keyStore.applicationTag != IntermediateKeyStoreConfiguration.helperApplicationTag)
            #expect(redirected.keyStore.trustedApplicationPaths.isEmpty)
        }
    #endif
}
