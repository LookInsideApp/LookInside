import Foundation
@testable import LookInsideActivation
@testable import LookInsideActivationUI
import Testing

struct ActivationAccessEvaluatorTests {
    @Test func emptyStateRequiresActivation() {
        let decision = ActivationAccessEvaluator.decision(
            from: ActivationPersistedState(),
            evaluatedAt: TestData.baseNow
        )
        #expect(decision.decision == .block)
        #expect(decision.title == ActivationAccessDecision.activationRequired.title)
    }

    @Test func expiredLicenseBlocksAccess() {
        let license = Self.makeLicense(
            expiresAt: TestData.baseNow.addingTimeInterval(-10)
        )
        let status = TestData.makeEntitlementStatus(license: license)
        var state = ActivationPersistedState()
        state.entitlementStatus = status

        let decision = ActivationAccessEvaluator.decision(
            from: state,
            evaluatedAt: TestData.baseNow
        )

        #expect(decision.decision == .block)
        #expect(decision.title == String(localized: "License Expired"))
    }

    @Test func warningMessagePromotesAllowToAllowWithWarning() {
        let license = Self.makeLicense()
        let status = TestData.makeEntitlementStatus(
            license: license,
            warningMessage: "Review the license terms"
        )
        var state = ActivationPersistedState()
        state.entitlementStatus = status

        let decision = ActivationAccessEvaluator.decision(
            from: state,
            evaluatedAt: TestData.baseNow
        )

        #expect(decision.decision == .allowWithWarning)
        #expect(decision.message == "Review the license terms")
    }

    @Test func connectivityWarningTakesPriorityOverGenericWarning() {
        let now = TestData.baseNow
        let endsAt = now.addingTimeInterval(3 * 24 * 60 * 60)
        let license = Self.makeLicense(expiresAt: endsAt)
        let lease = TestData.makeIntermediateCertificateLease(
            issuedAt: now.addingTimeInterval(-30 * 24 * 60 * 60),
            expiresAt: endsAt,
            renewAfter: now.addingTimeInterval(-29 * 24 * 60 * 60)
        )
        let status = TestData.makeEntitlementStatus(
            license: license,
            currentLease: lease,
            warningMessage: "Review the license terms"
        )
        var state = ActivationPersistedState()
        state.entitlementStatus = status
        state.lastRenewSucceededAt = now.addingTimeInterval(-7 * 24 * 60 * 60)
        state.lastRenewFailedAt = now.addingTimeInterval(-60)

        let decision = ActivationAccessEvaluator.decision(from: state, evaluatedAt: now)

        #expect(decision.decision == .allowWithWarning)
        #expect(decision.message != "Review the license terms")
        let dateString = endsAt.formatted(date: .abbreviated, time: .omitted)
        #expect(decision.message.contains(dateString))
    }

    @Test func freshLicenseAllowsAccess() {
        let license = Self.makeLicense()
        let status = TestData.makeEntitlementStatus(license: license)
        var state = ActivationPersistedState()
        state.entitlementStatus = status

        let decision = ActivationAccessEvaluator.decision(
            from: state,
            evaluatedAt: TestData.baseNow
        )

        #expect(decision.decision == .allow)
        #expect(decision.title == ActivationAccessDecision.allowedTitle)
    }

    @Test func refundedLifecycleBlocksAccess() {
        let license = Self.makeLicense(lifecycleState: .refunded)
        let status = TestData.makeEntitlementStatus(license: license)
        var state = ActivationPersistedState()
        state.entitlementStatus = status

        let decision = ActivationAccessEvaluator.decision(
            from: state,
            evaluatedAt: TestData.baseNow
        )

        #expect(decision.decision == .block)
        #expect(decision.title == String(localized: "License Expired"))
    }

    @Test func expiredLifecycleBlocksAccessEvenWithFutureExpiry() {
        let license = Self.makeLicense(
            lifecycleState: .expired,
            expiresAt: TestData.baseNow.addingTimeInterval(3600)
        )
        let status = TestData.makeEntitlementStatus(license: license)
        var state = ActivationPersistedState()
        state.entitlementStatus = status

        let decision = ActivationAccessEvaluator.decision(
            from: state,
            evaluatedAt: TestData.baseNow
        )

        #expect(decision.decision == .block)
        #expect(decision.title == String(localized: "License Expired"))
    }

    @Test func pendingReviewLifecycleRequiresReactivation() {
        let license = Self.makeLicense(lifecycleState: .pendingReview)
        let status = TestData.makeEntitlementStatus(license: license)
        var state = ActivationPersistedState()
        state.entitlementStatus = status

        let decision = ActivationAccessEvaluator.decision(
            from: state,
            evaluatedAt: TestData.baseNow
        )

        #expect(decision.decision == .block)
        #expect(decision.title == ActivationAccessDecision.activationRequired.title)
    }

    @Test func canceledLifecycleAllowsAccessUntilPeriodEnd() {
        let license = Self.makeLicense(lifecycleState: .canceled)
        let status = TestData.makeEntitlementStatus(license: license)
        var state = ActivationPersistedState()
        state.entitlementStatus = status

        let decision = ActivationAccessEvaluator.decision(
            from: state,
            evaluatedAt: TestData.baseNow
        )

        #expect(decision.decision == .allow)
    }

    @Test func connectivityWarningTriggersWhenRenewerHasFailedAndExpiryIsNear() {
        let now = TestData.baseNow
        let endsAt = now.addingTimeInterval(3 * 24 * 60 * 60) // 3d < 7d full threshold
        let license = Self.makeLicense(expiresAt: endsAt)
        let lease = TestData.makeIntermediateCertificateLease(
            issuedAt: now.addingTimeInterval(-30 * 24 * 60 * 60),
            expiresAt: endsAt,
            renewAfter: now.addingTimeInterval(-29 * 24 * 60 * 60)
        )
        let status = TestData.makeEntitlementStatus(license: license, currentLease: lease)
        var state = ActivationPersistedState()
        state.entitlementStatus = status
        state.lastRenewSucceededAt = now.addingTimeInterval(-7 * 24 * 60 * 60)
        state.lastRenewFailedAt = now.addingTimeInterval(-60)

        let decision = ActivationAccessEvaluator.decision(from: state, evaluatedAt: now)

        #expect(decision.decision == .allowWithWarning)
        #expect(decision.title == String(localized: "License Review Warning"))
        // The localized template embeds the formatted access-end date.
        let dateString = endsAt.formatted(date: .abbreviated, time: .omitted)
        #expect(decision.message.contains(dateString))
    }

    @Test func connectivityWarningSuppressedWhenLastRenewSucceeded() {
        let now = TestData.baseNow
        let endsAt = now.addingTimeInterval(3 * 24 * 60 * 60)
        let license = Self.makeLicense(expiresAt: endsAt)
        let lease = TestData.makeIntermediateCertificateLease(
            issuedAt: now.addingTimeInterval(-30 * 24 * 60 * 60),
            expiresAt: endsAt,
            renewAfter: now.addingTimeInterval(-29 * 24 * 60 * 60)
        )
        let status = TestData.makeEntitlementStatus(license: license, currentLease: lease)
        var state = ActivationPersistedState()
        state.entitlementStatus = status
        state.lastRenewFailedAt = now.addingTimeInterval(-3600)
        state.lastRenewSucceededAt = now.addingTimeInterval(-60)

        let decision = ActivationAccessEvaluator.decision(from: state, evaluatedAt: now)

        #expect(decision.decision == .allow)
    }

    @Test func leaseExpiringBeforeEntitlementCapsAccessWindow() {
        let entitlementEnd = TestData.baseNow.addingTimeInterval(30 * 24 * 60 * 60)
        let leaseEnd = TestData.baseNow.addingTimeInterval(-60)
        let license = Self.makeLicense(expiresAt: entitlementEnd)
        let status = TestData.makeEntitlementStatus(
            license: license,
            currentLease: TestData.makeIntermediateCertificateLease(expiresAt: leaseEnd)
        )
        var state = ActivationPersistedState()
        state.entitlementStatus = status

        let decision = ActivationAccessEvaluator.decision(
            from: state,
            evaluatedAt: TestData.baseNow
        )

        #expect(decision.decision == .block)
        #expect(decision.title == String(localized: "License Expired"))
    }

    @Test func ensureSessionFreshSwallowsRefreshWindowNotOpen() async throws {
        let now = TestData.baseNow
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LookInsideAuthServerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("state.json")
        let store = ActivationStateStore(url: url)
        let session = TestData.makeActivationSession(
            token: "old-token",
            expiresAt: now.addingTimeInterval(12 * 60 * 60) // within 1d refresh window
        )
        try await store.recordActivationSession(session)

        let mock = StubEvaluatorClient(
            refreshResult: .failure(
                LookInsideAuthenticatorAPIClientError.api(
                    statusCode: 409,
                    code: "refresh_window_not_open",
                    message: "too early"
                )
            )
        )
        let evaluator = ActivationAccessEvaluator(
            stateStore: store,
            apiClientFactory: { mock },
            now: { now }
        )

        try await evaluator.ensureSessionFresh()

        #expect(mock.refreshCalls == 1)
        let snapshot = await store.snapshot()
        #expect(snapshot.activationSession?.token == "old-token") // unchanged
    }

    @Test func ensureSessionFreshPersistsRefreshedSession() async throws {
        let now = TestData.baseNow
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LookInsideAuthServerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("state.json")
        let store = ActivationStateStore(url: url)
        let session = TestData.makeActivationSession(
            token: "old-token",
            expiresAt: now.addingTimeInterval(12 * 60 * 60)
        )
        try await store.recordActivationSession(session)

        let refreshed = TestData.makeActivationSession(
            token: "new-token",
            expiresAt: now.addingTimeInterval(3 * 24 * 60 * 60)
        )
        let mock = StubEvaluatorClient(refreshResult: .success(refreshed))
        let evaluator = ActivationAccessEvaluator(
            stateStore: store,
            apiClientFactory: { mock },
            now: { now }
        )

        try await evaluator.ensureSessionFresh()

        let snapshot = await store.snapshot()
        #expect(snapshot.activationSession?.token == "new-token")
    }

    @Test func refreshedDecisionFetchesWithRefreshedSession() async throws {
        let now = TestData.baseNow
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LookInsideAuthServerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("state.json")
        let store = ActivationStateStore(url: url)
        let oldSession = TestData.makeActivationSession(
            token: "old-token",
            expiresAt: now.addingTimeInterval(12 * 60 * 60)
        )
        let refreshed = TestData.makeActivationSession(
            token: "new-token",
            expiresAt: now.addingTimeInterval(3 * 24 * 60 * 60)
        )
        let license = Self.makeLicense()
        let status = TestData.makeEntitlementStatus(license: license)
        try await store.recordActivationSession(oldSession)
        try await store.recordDeviceFingerprint(TestData.makeChallenge().device)

        let mock = StubEvaluatorClient(
            refreshResult: .success(refreshed),
            fetchResult: .success(status)
        )
        let evaluator = ActivationAccessEvaluator(
            stateStore: store,
            apiClientFactory: { mock },
            now: { now }
        )

        let decision = try await evaluator.refreshedDecision()

        #expect(decision.decision == .allow)
        #expect(mock.refreshCalls == 1)
        #expect(mock.fetchCalls == 1)
        #expect(mock.lastFetchRequest?.activationSessionToken == "new-token")
    }

    @Test func ensureSessionFreshSkipsWhenSessionNotNearExpiry() async throws {
        let now = TestData.baseNow
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LookInsideAuthServerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("state.json")
        let store = ActivationStateStore(url: url)
        let session = TestData.makeActivationSession(
            token: "old-token",
            expiresAt: now.addingTimeInterval(2 * 24 * 60 * 60) // 2d > 1d window
        )
        try await store.recordActivationSession(session)

        let mock = StubEvaluatorClient(refreshResult: .success(session))
        let evaluator = ActivationAccessEvaluator(
            stateStore: store,
            apiClientFactory: { mock },
            now: { now }
        )

        try await evaluator.ensureSessionFresh()
        #expect(mock.refreshCalls == 0)
    }

    private static func makeLicense(
        lifecycleState: LicenseLifecycleState = .active,
        expiresAt: Date = TestData.baseNow.addingTimeInterval(3600)
    ) -> LicenseEnvelope {
        LicenseEnvelope(
            licenseID: "license-xyz",
            licenseClass: .full,
            lifecycleState: lifecycleState,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: expiresAt,
            certificateChain: TestData.makeCertificateChain(
                intermediateExpiresAt: expiresAt
            )
        )
    }
}

private final class StubEvaluatorClient: ActivationEvaluatorClient, @unchecked Sendable {
    private(set) var refreshCalls = 0
    private(set) var fetchCalls = 0
    private(set) var lastFetchRequest: EntitlementStatusRequest?
    var refreshResult: Result<ActivationSession, Error>
    var fetchResult: Result<EntitlementStatus, Error>?

    init(
        refreshResult: Result<ActivationSession, Error>,
        fetchResult: Result<EntitlementStatus, Error>? = nil
    ) {
        self.refreshResult = refreshResult
        self.fetchResult = fetchResult
    }

    func refreshActivationSession(
        _: ActivationSessionRefreshRequest
    ) async throws -> ActivationSession {
        refreshCalls += 1
        return try refreshResult.get()
    }

    func fetchEntitlementStatus(
        _ request: EntitlementStatusRequest
    ) async throws -> EntitlementStatus {
        fetchCalls += 1
        lastFetchRequest = request
        guard let fetchResult else {
            throw TestFailure.fetchFailed
        }
        return try fetchResult.get()
    }
}
