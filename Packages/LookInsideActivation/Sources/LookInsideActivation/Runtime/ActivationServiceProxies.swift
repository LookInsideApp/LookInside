import Foundation

final class PurchaseClaimResolverProxy: PurchaseClaimResolving, @unchecked Sendable {
    private let apiClient: LookInsideAuthenticatorAPIClient
    private let stateStore: ActivationStateStore

    init(apiClient: LookInsideAuthenticatorAPIClient, stateStore: ActivationStateStore) {
        self.apiClient = apiClient
        self.stateStore = stateStore
    }

    func resolvePurchaseClaim(_ request: PurchaseClaimRequest) async throws -> ActivationSession {
        try await stateStore.recordDeviceFingerprint(request.device)
        let session = try await apiClient.resolvePurchaseClaim(request)
        try await stateStore.recordActivationSession(session)
        return session
    }
}

final class TrialIssuerProxy: TrialIssuing, @unchecked Sendable {
    private let apiClient: LookInsideAuthenticatorAPIClient
    private let stateStore: ActivationStateStore

    init(apiClient: LookInsideAuthenticatorAPIClient, stateStore: ActivationStateStore) {
        self.apiClient = apiClient
        self.stateStore = stateStore
    }

    func issueTrial(_ request: TrialIssueRequest) async throws -> ActivationSession {
        try await stateStore.recordDeviceFingerprint(request.device)
        let session = try await apiClient.issueTrial(request)
        try await stateStore.recordTransientActivationSession(session)
        return session
    }
}

final class EntitlementStatusFetcherProxy: EntitlementStatusFetching, @unchecked Sendable {
    private let apiClient: LookInsideAuthenticatorAPIClient
    private let stateStore: ActivationStateStore

    init(apiClient: LookInsideAuthenticatorAPIClient, stateStore: ActivationStateStore) {
        self.apiClient = apiClient
        self.stateStore = stateStore
    }

    func fetchEntitlementStatus(_ request: EntitlementStatusRequest) async throws -> EntitlementStatus {
        let status = try await apiClient.fetchEntitlementStatus(request)
        try await stateStore.recordEntitlementStatus(status)
        return status
    }
}

final class IntermediateCertificateIssuerProxy: IntermediateCertificateIssuing, @unchecked Sendable {
    private let apiClient: LookInsideAuthenticatorAPIClient
    private let stateStore: ActivationStateStore

    init(apiClient: LookInsideAuthenticatorAPIClient, stateStore: ActivationStateStore) {
        self.apiClient = apiClient
        self.stateStore = stateStore
    }

    func issueIntermediateCertificate(
        _ request: IntermediateCertificateIssueRequest
    ) async throws -> IntermediateCertificateLease {
        let lease = try await apiClient.issueIntermediateCertificate(request)
        try await stateStore.recordIssuedLease(lease)
        return lease
    }
}
