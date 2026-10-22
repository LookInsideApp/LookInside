import Foundation
@testable import LookInsideActivation
@testable import LookInsideActivationUI
import Testing

struct ActivationCertificateRenewerTests {
    @Test func skipsWhenNoLeasePresent() async {
        let store = makeStore()
        let mock = MockIntermediateIssuer()
        let refresherCalls = CallCounter()

        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { mock },
            csrProvider: { "csr" },
            sessionRefresher: { refresherCalls.increment() },
            now: { TestData.baseNow }
        )
        await renewer.tryRenewIfDue()
        #expect(mock.callCount == 0)
        #expect(refresherCalls.value == 0)
    }

    @Test func skipsWhenLeaseStillFarFromExpiry() async throws {
        let now = TestData.baseNow
        let store = makeStore()
        try await primeState(
            store: store,
            licenseClass: .full,
            leaseRenewAfter: now.addingTimeInterval(-3600),
            leaseExpiresAt: now.addingTimeInterval(20 * 24 * 60 * 60) // 20d > 7d threshold
        )

        let mock = MockIntermediateIssuer()
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { mock },
            csrProvider: { "csr" },
            sessionRefresher: {},
            now: { now }
        )
        await renewer.tryRenewIfDue()

        #expect(mock.callCount == 0)
        let snapshot = await store.snapshot()
        #expect(snapshot.lastRenewAttemptAt == nil)
    }

    @Test func skipsWhenRenewAfterStillInFuture() async throws {
        let now = TestData.baseNow
        let store = makeStore()
        try await primeState(
            store: store,
            licenseClass: .full,
            leaseRenewAfter: now.addingTimeInterval(3600), // not yet
            leaseExpiresAt: now.addingTimeInterval(6 * 3600)
        )

        let mock = MockIntermediateIssuer()
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { mock },
            csrProvider: { "csr" },
            sessionRefresher: {},
            now: { now }
        )
        await renewer.tryRenewIfDue()

        #expect(mock.callCount == 0)
    }

    @Test func renewsAndCallsRefresherBeforeIssuing() async throws {
        let now = TestData.baseNow
        let store = makeStore()
        try await primeState(
            store: store,
            licenseClass: .full,
            leaseRenewAfter: now.addingTimeInterval(-3600),
            leaseExpiresAt: now.addingTimeInterval(6 * 3600) // 6h < 7d threshold
        )

        let renewedLease = TestData.makeIntermediateCertificateLease(
            certificateID: "lease-renewed",
            issuedAt: now,
            expiresAt: now.addingTimeInterval(30 * 24 * 60 * 60)
        )
        let mock = MockIntermediateIssuer(result: .success(renewedLease))
        let orderLog = OrderLog()

        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { mock },
            csrProvider: {
                orderLog.append("csr")
                return "csr-pem"
            },
            sessionRefresher: { orderLog.append("refresh") },
            now: { now }
        )

        await renewer.tryRenewIfDue()

        #expect(mock.callCount == 1)
        #expect(orderLog.values == ["refresh", "csr"])
        #expect(mock.lastRequest?.certificateSigningRequestPEM == "csr-pem")

        let snapshot = await store.snapshot()
        #expect(snapshot.entitlementStatus?.currentLease?.certificateID == "lease-renewed")
        #expect(snapshot.lastRenewSucceededAt == now)
        #expect(snapshot.lastRenewFailedAt == nil)
        #expect(snapshot.lastRenewError == nil)
    }

    @Test func trialUsesTwelveHourThreshold() async throws {
        let now = TestData.baseNow
        let store = makeStore()

        try await primeState(
            store: store,
            licenseClass: .trial,
            leaseRenewAfter: now.addingTimeInterval(-60),
            leaseExpiresAt: now.addingTimeInterval(20 * 60 * 60) // 20h above 12h threshold
        )
        let mock = MockIntermediateIssuer()
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { mock },
            csrProvider: { "csr" },
            sessionRefresher: {},
            now: { now }
        )
        await renewer.tryRenewIfDue()
        #expect(mock.callCount == 0)

        try await primeState(
            store: store,
            licenseClass: .trial,
            leaseRenewAfter: now.addingTimeInterval(-60),
            leaseExpiresAt: now.addingTimeInterval(10 * 60 * 60) // 10h within 12h threshold
        )
        await renewer.tryRenewIfDue()
        #expect(mock.callCount == 1)
    }

    @Test func issueFailurePersistsLastRenewFailure() async throws {
        let now = TestData.baseNow
        let store = makeStore()
        try await primeState(
            store: store,
            licenseClass: .full,
            leaseRenewAfter: now.addingTimeInterval(-3600),
            leaseExpiresAt: now.addingTimeInterval(6 * 3600)
        )

        let mock = MockIntermediateIssuer(result: .failure(MockError.boom))
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { mock },
            csrProvider: { "csr" },
            sessionRefresher: {},
            now: { now }
        )

        await renewer.tryRenewIfDue()

        let snapshot = await store.snapshot()
        #expect(snapshot.lastRenewAttemptAt == now)
        #expect(snapshot.lastRenewFailedAt == now)
        #expect(snapshot.lastRenewSucceededAt == nil)
        #expect(snapshot.lastRenewError != nil)
    }

    @Test func sessionRefresherFailureSkipsIssueAndRecordsFailure() async throws {
        let now = TestData.baseNow
        let store = makeStore()
        try await primeState(
            store: store,
            licenseClass: .full,
            leaseRenewAfter: now.addingTimeInterval(-3600),
            leaseExpiresAt: now.addingTimeInterval(6 * 3600)
        )

        let mock = MockIntermediateIssuer()
        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { mock },
            csrProvider: { "csr" },
            sessionRefresher: { throw MockError.boom },
            now: { now }
        )
        await renewer.tryRenewIfDue()

        #expect(mock.callCount == 0)
        let snapshot = await store.snapshot()
        #expect(snapshot.lastRenewFailedAt == now)
    }

    @Test func backsOffAfterFailures() async throws {
        let baseNow = TestData.baseNow
        let store = makeStore()
        try await primeState(
            store: store,
            licenseClass: .full,
            leaseRenewAfter: baseNow.addingTimeInterval(-3600),
            leaseExpiresAt: baseNow.addingTimeInterval(6 * 24 * 3600)
        )

        let mock = MockIntermediateIssuer(result: .failure(MockError.boom))
        let clockBox = ClockBox(value: baseNow)

        let renewer = ActivationCertificateRenewer(
            stateStore: store,
            clientFactory: { mock },
            csrProvider: { "csr" },
            sessionRefresher: {},
            now: { clockBox.snapshot() }
        )

        await renewer.tryRenewIfDue()
        clockBox.set(baseNow.addingTimeInterval(70)) // the old one-minute retry
        await renewer.tryRenewIfDue()
        #expect(mock.callCount == 1)

        clockBox.set(baseNow.addingTimeInterval(5 * 60))
        await renewer.tryRenewIfDue()
        #expect(mock.callCount == 2)

        clockBox.set(baseNow.addingTimeInterval(19 * 60))
        await renewer.tryRenewIfDue()
        #expect(mock.callCount == 2)
        clockBox.set(baseNow.addingTimeInterval(20 * 60))
        await renewer.tryRenewIfDue()
        #expect(mock.callCount == 3)
    }
}

// MARK: - Helpers

private enum MockError: Error { case boom }

private final class CallCounter: @unchecked Sendable {
    private(set) var value = 0
    func increment() {
        value += 1
    }
}

private final class OrderLog: @unchecked Sendable {
    private(set) var values: [String] = []
    func append(_ entry: String) {
        values.append(entry)
    }
}

private final class ClockBox: @unchecked Sendable {
    private var current: Date
    init(value: Date) {
        current = value
    }

    func set(_ value: Date) {
        current = value
    }

    func snapshot() -> Date {
        current
    }
}

private final class MockIntermediateIssuer: IntermediateCertificateIssuing, @unchecked Sendable {
    private(set) var callCount = 0
    private(set) var lastRequest: IntermediateCertificateIssueRequest?
    var result: Result<IntermediateCertificateLease, Error>

    init(
        result: Result<IntermediateCertificateLease, Error> = .success(
            TestData.makeIntermediateCertificateLease()
        )
    ) {
        self.result = result
    }

    func issueIntermediateCertificate(
        _ request: IntermediateCertificateIssueRequest
    ) async throws -> IntermediateCertificateLease {
        callCount += 1
        lastRequest = request
        return try result.get()
    }
}

private func makeStore() -> ActivationStateStore {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("LookInsideAuthServerTests-\(UUID().uuidString)", isDirectory: true)
        .appendingPathComponent("state.json")
    return ActivationStateStore(url: url)
}

private func primeState(
    store: ActivationStateStore,
    licenseClass: LicenseClass,
    leaseRenewAfter: Date,
    leaseExpiresAt: Date
) async throws {
    let session = TestData.makeActivationSession(
        expiresAt: TestData.baseNow.addingTimeInterval(3 * 24 * 60 * 60)
    )
    let license = LicenseEnvelope(
        licenseID: "license-123",
        licenseClass: licenseClass,
        lifecycleState: .active,
        issuedTo: "Acme",
        issuedAt: TestData.baseNow.addingTimeInterval(-86400),
        expiresAt: TestData.baseNow.addingTimeInterval(365 * 86400),
        certificateChain: TestData.makeCertificateChain()
    )
    let lease = TestData.makeIntermediateCertificateLease(
        issuedAt: leaseRenewAfter.addingTimeInterval(-86400),
        expiresAt: leaseExpiresAt,
        renewAfter: leaseRenewAfter
    )
    let status = TestData.makeEntitlementStatus(license: license, currentLease: lease)
    try await store.recordActivationSession(session)
    try await store.recordEntitlementStatus(status)
}
