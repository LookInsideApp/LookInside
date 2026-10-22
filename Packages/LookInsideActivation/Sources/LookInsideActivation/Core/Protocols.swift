import Foundation

public protocol Clock: Sendable {
    func now() -> Date
}

public protocol TrustChainValidating: Sendable {
    func validate(_ certificateChain: CertificateChain, at now: Date) throws
}

public protocol ChallengeValidating: Sendable {
    func validate(_ challenge: ClientActivationChallenge, now: Date, policy: ActivationPolicy) throws
}

public protocol ReplayProtecting: Sendable {
    func reserve(_ nonce: String, until expiresAt: Date) throws
}

public protocol SecureTimestampFetching: Sendable {
    func fetchTimestamp(for request: SecureTimestampRequest) async throws -> SecureTimestampToken
}

public protocol SecureTimestampValidating: Sendable {
    func validate(
        _ token: SecureTimestampToken,
        against request: SecureTimestampRequest,
        trustedRootCertificateID: String,
        now: Date,
        policy: ActivationPolicy
    ) throws
}

public protocol PurchaseClaimResolving: Sendable {
    func resolvePurchaseClaim(_ request: PurchaseClaimRequest) async throws -> ActivationSession
}

public protocol TrialIssuing: Sendable {
    func issueTrial(_ request: TrialIssueRequest) async throws -> ActivationSession
}

public protocol EntitlementStatusFetching: Sendable {
    func fetchEntitlementStatus(_ request: EntitlementStatusRequest) async throws -> EntitlementStatus
}

public protocol ActivationSessionRefreshing: Sendable {
    func refreshActivationSession(
        _ request: ActivationSessionRefreshRequest
    ) async throws -> ActivationSession
}

public protocol IntermediateCertificateIssuing: Sendable {
    func issueIntermediateCertificate(
        _ request: IntermediateCertificateIssueRequest
    ) async throws -> IntermediateCertificateLease
}

public protocol ActivationMaterialIssuing: Sendable {
    func issueActivation(
        for challenge: ClientActivationChallenge,
        license: LicenseEnvelope,
        policy: ActivationPolicy,
        secureTimestamp: SecureTimestampToken?
    ) async throws -> SignedActivationEnvelope
}

public protocol RootTimestampSigning: Sendable {
    func sign(request: SecureTimestampRequest, at now: Date) async throws -> SecureTimestampToken
}
