import Foundation
@testable import LookInsideActivation

final class RecordingPurchaseClaimResolver: PurchaseClaimResolving, @unchecked Sendable {
    private(set) var resolveCount = 0
    private(set) var lastRequest: PurchaseClaimRequest?
    var error: Error?
    var session: ActivationSession

    init(session: ActivationSession) {
        self.session = session
    }

    func resolvePurchaseClaim(_ request: PurchaseClaimRequest) async throws -> ActivationSession {
        resolveCount += 1
        lastRequest = request
        if let error {
            throw error
        }
        return session
    }
}

final class RecordingEntitlementStatusFetcher: EntitlementStatusFetching, @unchecked Sendable {
    private(set) var fetchCount = 0
    private(set) var lastRequest: EntitlementStatusRequest?
    var error: Error?
    var status: EntitlementStatus

    init(status: EntitlementStatus) {
        self.status = status
    }

    func fetchEntitlementStatus(_ request: EntitlementStatusRequest) async throws -> EntitlementStatus {
        fetchCount += 1
        lastRequest = request
        if let error {
            throw error
        }
        return status
    }
}

final class RecordingTrialIssuer: TrialIssuing, @unchecked Sendable {
    private(set) var issueCount = 0
    private(set) var lastRequest: TrialIssueRequest?
    var error: Error?
    var session: ActivationSession

    init(session: ActivationSession) {
        self.session = session
    }

    func issueTrial(_ request: TrialIssueRequest) async throws -> ActivationSession {
        issueCount += 1
        lastRequest = request
        if let error {
            throw error
        }
        return session
    }
}

final class RecordingIntermediateCertificateIssuer: IntermediateCertificateIssuing, @unchecked Sendable {
    private(set) var issueCount = 0
    private(set) var lastRequest: IntermediateCertificateIssueRequest?
    var error: Error?
    var lease: IntermediateCertificateLease

    init(lease: IntermediateCertificateLease) {
        self.lease = lease
    }

    func issueIntermediateCertificate(
        _ request: IntermediateCertificateIssueRequest
    ) async throws -> IntermediateCertificateLease {
        issueCount += 1
        lastRequest = request
        if let error {
            throw error
        }
        return lease
    }
}
