import Foundation
@testable import LookInsideActivation
import Testing

/// Silent renewal signs with the license key, which raises a login-keychain
/// prompt for a key the 2.3.x helper created. It must wait for the app to be
/// on screen and must not ask again every minute after a refusal.
struct SilentRenewalTests {
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

    private final class Switch: @unchecked Sendable {
        private let lock = NSLock()
        private var isOn: Bool

        init(_ isOn: Bool) {
            self.isOn = isOn
        }

        var value: Bool {
            get { lock.withLock { isOn } }
            set { lock.withLock { isOn = newValue } }
        }
    }

    private struct Issuer: IntermediateCertificateIssuing {
        func issueIntermediateCertificate(
            _: IntermediateCertificateIssueRequest
        ) async throws -> IntermediateCertificateLease {
            TestData.makeIntermediateCertificateLease(
                expiresAt: TestData.baseNow.addingTimeInterval(30 * 24 * 60 * 60),
                renewAfter: TestData.baseNow.addingTimeInterval(20 * 24 * 60 * 60)
            )
        }
    }

    @Test func gateWaitsForFirstWindowAndLaunchDelay() {
        let launch = TestData.baseNow
        var policy = ActivationSigningPolicy(launchedAt: launch)

        #expect(policy.allowsSigning(for: .silentRenewal, at: launch.addingTimeInterval(120)) == false)
        policy.noteFirstWindowShown()
        #expect(policy.allowsSigning(for: .silentRenewal, at: launch.addingTimeInterval(10)) == false)
        #expect(
            policy.allowsSigning(
                for: .silentRenewal,
                at: launch.addingTimeInterval(ActivationSigningPolicy.launchDelay)
            )
        )
    }

    @Test func runtimeKeepsGateClosedUntilAllowed() throws {
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let clock = Clock(TestData.baseNow)
        let runtime = ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(stateDirectoryURL: directory),
            urlSession: .shared,
            now: { clock.now }
        )

        clock.now = TestData.baseNow.addingTimeInterval(3600)
        #expect(runtime.signingGate.allowsSigning(for: .silentRenewal) == false)
        #expect(runtime.allowsLicenseHandshake(onChannel: "channel") == false)
        runtime.noteFirstWindowShown()
        #expect(runtime.signingGate.allowsSigning(for: .silentRenewal))
        #expect(runtime.allowsLicenseHandshake(onChannel: "channel"))
    }

    @Test func keychainDenialBacksOffOneHourThenOneDay() async throws {
        let start = TestData.baseNow
        let clock = Clock(start)
        let store = try await Self.makeDueStore(now: start)
        let csrRequests = Counter()
        let denies = Switch(true)
        let gate = ActivationSigningGate.open(now: { clock.now })
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { Issuer() },
            csrProvider: {
                csrRequests.increment()
                if denies.value {
                    throw ActivationError.keychainAccessDenied(-128)
                }
                return "csr"
            },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: gate
        )

        await renewer.tryRenewIfDue()
        #expect(csrRequests.value == 1)
        #expect(gate.status.isKeychainAccessDenied(at: clock.now))
        #expect(await store.snapshot().lastRenewFailedAt == start)

        // The 60-second retry would ask again; the backoff does not.
        clock.now = start.addingTimeInterval(120)
        await renewer.tryRenewIfDue()
        clock.now = start.addingTimeInterval(59 * 60)
        await renewer.tryRenewIfDue()
        #expect(csrRequests.value == 1)

        let secondAttempt = start.addingTimeInterval(60 * 60)
        clock.now = secondAttempt
        await renewer.tryRenewIfDue()
        #expect(csrRequests.value == 2)

        clock.now = secondAttempt.addingTimeInterval(23 * 60 * 60)
        await renewer.tryRenewIfDue()
        #expect(csrRequests.value == 2)

        denies.value = false
        clock.now = secondAttempt.addingTimeInterval(24 * 60 * 60)
        await renewer.tryRenewIfDue()
        #expect(csrRequests.value == 3)
        #expect(gate.status.isKeychainAccessDenied(at: clock.now) == false)
        #expect(await store.snapshot().lastRenewSucceededAt == clock.now)
    }

    @Test func otherFailuresBackOffWithoutADenialWait() async throws {
        let start = TestData.baseNow
        let clock = Clock(start)
        let store = try await Self.makeDueStore(now: start)
        let csrRequests = Counter()
        let gate = ActivationSigningGate.open(now: { clock.now })
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { Issuer() },
            csrProvider: {
                csrRequests.increment()
                throw ActivationError.keychainFailure("unrelated")
            },
            sessionRefresher: {},
            now: { clock.now },
            signingGate: gate
        )

        await renewer.tryRenewIfDue()
        clock.now = start.addingTimeInterval(61)
        await renewer.tryRenewIfDue()
        #expect(csrRequests.value == 1)
        clock.now = start.addingTimeInterval(5 * 60)
        await renewer.tryRenewIfDue()
        #expect(csrRequests.value == 2)
        #expect(gate.status.isKeychainAccessDenied(at: clock.now) == false)
    }

    @MainActor
    @Test func licenseWindowExplainsADeniedKeychain() async throws {
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(stateDirectoryURL: directory),
            urlSession: .shared,
            now: { TestData.baseNow },
            silentRenewalEnabled: false
        )

        await runtime.restoreActivationModel()
        #expect(runtime.activationModel().keychainAccessNotice == nil)

        runtime.signingGate.record(.denied, from: .silentRenewal, channel: nil)
        #expect(runtime.isKeychainAccessDenied())
        await runtime.restoreActivationModel()
        let notice = try #require(runtime.activationModel().keychainAccessNotice)
        #expect(notice.contains("Keychain"))

        runtime.signingGate.record(.succeeded(duration: 0), from: .userAction, channel: nil)
        await runtime.restoreActivationModel()
        #expect(runtime.activationModel().keychainAccessNotice == nil)
    }

    private static func makeDueStore(now: Date) async throws -> ActivationStateStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LookInsideActivationTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("state.json")
        let store = ActivationStateStore(url: url)
        let session = TestData.makeActivationSession(expiresAt: now.addingTimeInterval(3 * 24 * 60 * 60))
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
            expiresAt: now.addingTimeInterval(6 * 86400),
            renewAfter: now.addingTimeInterval(-3600)
        )
        try await store.recordActivationSession(session)
        try await store.recordEntitlementStatus(TestData.makeEntitlementStatus(license: license, currentLease: lease))
        return store
    }
}
