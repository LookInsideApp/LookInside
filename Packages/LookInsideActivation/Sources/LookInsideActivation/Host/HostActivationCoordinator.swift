import Foundation

public struct HostActivationCoordinator: Sendable {
    private let policy: ActivationPolicy
    private let clock: any Clock
    private let trustValidator: any TrustChainValidating
    private let challengeValidator: any ChallengeValidating
    private let replayProtector: any ReplayProtecting
    private let secureTimestampFetcher: (any SecureTimestampFetching)?
    private let secureTimestampValidator: any SecureTimestampValidating
    private let activationIssuer: any ActivationMaterialIssuing

    public init(
        policy: ActivationPolicy = .init(),
        clock: any Clock = SystemClock(),
        trustValidator: any TrustChainValidating = DateBoundTrustChainValidator(),
        challengeValidator: any ChallengeValidating = DefaultChallengeValidator(),
        replayProtector: any ReplayProtecting,
        secureTimestampFetcher: (any SecureTimestampFetching)? = nil,
        secureTimestampValidator: any SecureTimestampValidating = DefaultSecureTimestampValidator(),
        activationIssuer: any ActivationMaterialIssuing
    ) {
        self.policy = policy
        self.clock = clock
        self.trustValidator = trustValidator
        self.challengeValidator = challengeValidator
        self.replayProtector = replayProtector
        self.secureTimestampFetcher = secureTimestampFetcher
        self.secureTimestampValidator = secureTimestampValidator
        self.activationIssuer = activationIssuer
    }

    public func activate(_ request: HostActivationRequest) async throws -> HostActivationResponse {
        let now = clock.now()

        try validateLicenseWindow(request.license, now: now)
        try trustValidator.validate(request.license.certificateChain, at: now)
        try challengeValidator.validate(request.challenge, now: now, policy: policy)
        try replayProtector.reserve(
            request.challenge.nonce,
            until: now.addingTimeInterval(policy.challengeTimeToLive)
        )

        let activationPath = policy.activationPath(for: request.license.licenseClass)
        let secureTimestamp = try await loadSecureTimestampIfNeeded(
            activationPath: activationPath,
            request: request,
            now: now
        )

        let activation = try await activationIssuer.issueActivation(
            for: request.challenge,
            license: request.license,
            policy: policy,
            secureTimestamp: secureTimestamp
        )

        return HostActivationResponse(
            activation: activation,
            path: activationPath,
            secureTimestamp: secureTimestamp
        )
    }

    private func validateLicenseWindow(_ license: LicenseEnvelope, now: Date) throws {
        guard let expiresAt = license.expiresAt else {
            return
        }

        guard now <= expiresAt else {
            throw AuthenticatorError.licenseExpired
        }
    }

    private func loadSecureTimestampIfNeeded(
        activationPath: ActivationPath,
        request: HostActivationRequest,
        now: Date
    ) async throws -> SecureTimestampToken? {
        guard activationPath == .timeAnchored else {
            return nil
        }

        guard let secureTimestampFetcher else {
            throw AuthenticatorError.secureTimestampProviderUnavailable
        }

        let timestampRequest = request.secureTimestampRequest

        let token = try await secureTimestampFetcher.fetchTimestamp(for: timestampRequest)
        try secureTimestampValidator.validate(
            token,
            against: timestampRequest,
            trustedRootCertificateID: request.license.trustedRootCertificateID,
            now: now,
            policy: policy
        )
        return token
    }
}
