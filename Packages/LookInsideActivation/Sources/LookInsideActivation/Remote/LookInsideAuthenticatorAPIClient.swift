import Foundation

public enum LookInsideAuthenticatorAPIClientError: Error, Sendable, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case invalidTimestamp(field: String, value: String)
    case invalidSessionToken
    case invalidTimestampSignature
    case api(statusCode: Int, code: String, message: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidURL(path):
            return "The authenticator service URL is invalid for path \(path)."
        case .invalidResponse:
            return "The authenticator service returned an unreadable response."
        case let .invalidTimestamp(field, value):
            return "The authenticator service returned an invalid timestamp for \(field): \(value)"
        case .invalidSessionToken:
            return "The activation session token payload is invalid."
        case .invalidTimestampSignature:
            return "The secure timestamp signature could not be decoded."
        case let .api(statusCode, code, message):
            return "The authenticator service returned \(statusCode) \(code): \(message)"
        }
    }
}

public struct LookInsideAuthenticatorAPIClient:
    Sendable,
    PurchaseClaimResolving,
    TrialIssuing,
    EntitlementStatusFetching,
    ActivationSessionRefreshing,
    IntermediateCertificateIssuing,
    SecureTimestampFetching
{
    public static let serviceBaseURL = URL(string: "https://lookinside-app.com")!

    let urlSession: URLSession
    let baseURL: URL

    public init(urlSession: URLSession = .shared, baseURL: URL = LookInsideAuthenticatorAPIClient.serviceBaseURL) {
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    public func resolvePurchaseClaim(_ request: PurchaseClaimRequest) async throws -> ActivationSession {
        let payload = PurchaseClaimPayload(
            licenseKey: request.licenseKey,
            email: request.email,
            device: request.device,
            requestNonce: Self.makeRequestNonce(prefix: "purchase-claim")
        )
        let response: PurchaseClaimResponse = try await send(
            path: "/v1/purchase-claims/resolve",
            method: "POST",
            body: payload
        )
        return try makeActivationSession(from: response)
    }

    public func issueTrial(_ request: TrialIssueRequest) async throws -> ActivationSession {
        let payload = TrialIssuePayload(
            device: request.device,
            requestNonce: Self.makeRequestNonce(prefix: "trial-issue")
        )
        let response: PurchaseClaimResponse = try await send(
            path: "/v1/trials",
            method: "POST",
            body: payload
        )
        return try makeActivationSession(from: response)
    }

    public func fetchEntitlementStatus(_ request: EntitlementStatusRequest) async throws -> EntitlementStatus {
        guard let sessionToken = request.activationSessionToken, !sessionToken.isEmpty else {
            throw LookInsideAuthenticatorAPIClientError.invalidSessionToken
        }
        let payload = LicenseSummaryRequestPayload(activationSessionToken: sessionToken)
        let summary: LicenseSummaryPayload = try await send(
            path: "/v1/licenses/\(request.licenseID)",
            method: "POST",
            body: payload
        )
        let currentLease = try await fetchCurrentLeaseIfPresent(
            certificateID: summary.currentCertificateID,
            licenseID: summary.licenseID,
            deviceIdentifier: request.deviceID
        )
        let lastFetchedAt = Date()

        return try EntitlementStatus(
            license: makeLicenseEnvelope(
                from: summary,
                currentLease: currentLease,
                deviceID: request.deviceID
            ),
            deviceBinding: makeDeviceBinding(
                from: summary,
                deviceID: request.deviceID,
                lastFetchedAt: lastFetchedAt
            ),
            currentLease: currentLease,
            activationSession: request.activationSessionToken.flatMap(Self.activationSessionStub),
            isEligibleForActivation: summary.canIssueCertificate || currentLease != nil,
            isEligibleForRenewal: currentLease != nil && summary.canIssueCertificate,
            requiresLiveRefresh: false,
            lastFetchedAt: Self.parseDate(summary.lastVerifiedAt, field: "last_verified_at"),
            informationalMessage: summary.notices.isEmpty ? nil : summary.notices.joined(separator: "\n"),
            warningMessage: summary.deviceWarning ?? summary.blockedReason
        )
    }

    public func refreshActivationSession(
        _ request: ActivationSessionRefreshRequest
    ) async throws -> ActivationSession {
        let payload = ActivationSessionRefreshPayload(
            activationSessionToken: request.activationSessionToken,
            requestNonce: Self.makeRequestNonce(prefix: "session-refresh")
        )
        let response: PurchaseClaimResponse = try await send(
            path: "/v1/activation-sessions/refresh",
            method: "POST",
            body: payload
        )
        return try makeActivationSession(from: response)
    }

    public func issueIntermediateCertificate(
        _ request: IntermediateCertificateIssueRequest
    ) async throws -> IntermediateCertificateLease {
        let payload = IntermediateCertificateIssuePayload(
            activationSessionToken: request.activationSessionToken,
            deviceIdentifier: request.deviceIdentifier,
            certificateSigningRequestPEM: request.certificateSigningRequestPEM,
            requestNonce: Self.makeRequestNonce(prefix: "certificate-issue")
        )
        let response: IntermediateCertificatePayload = try await send(
            path: "/v1/intermediate-certificates",
            method: "POST",
            body: payload
        )
        let claims = try Self.decodeSessionClaims(from: request.activationSessionToken)

        return try makeIntermediateCertificateLease(
            from: response,
            licenseID: claims.licenseID,
            deviceIdentifier: request.deviceIdentifier
        )
    }

    public func fetchTimestamp(for request: SecureTimestampRequest) async throws -> SecureTimestampToken {
        let payload = SecureTimestampRequestPayload(
            licenseID: request.licenseID,
            challengeNonce: request.challengeNonce,
            clientIssuedAt: request.clientIssuedAt,
            deviceIdentifier: request.deviceIdentifier,
            requestedFeature: request.requestedFeature
        )
        let response: SecureTimestampPayload = try await send(
            path: "/v1/secure-timestamps",
            method: "POST",
            body: payload
        )

        guard let signature = Data(base64Encoded: response.signature) else {
            throw LookInsideAuthenticatorAPIClientError.invalidTimestampSignature
        }

        return try SecureTimestampToken(
            challengeNonce: response.challengeNonce,
            signedAt: Self.parseDate(response.signedAt, field: "signed_at"),
            rootCertificateID: response.rootCertificateID,
            signature: signature
        )
    }

    private func makeActivationSession(from response: PurchaseClaimResponse) throws -> ActivationSession {
        let claims = try Self.decodeSessionClaims(from: response.activationSessionToken)
        return try ActivationSession(
            sessionID: claims.sessionID,
            licenseID: claims.licenseID,
            orderID: claims.orderID,
            email: claims.email,
            deviceIdentifier: claims.deviceIdentifier,
            token: response.activationSessionToken,
            expiresAt: Self.parseDate(
                response.activationSessionExpiresAt,
                field: "activation_session_expires_at"
            ),
            createdAt: Self.parseDate(claims.issuedAt, field: "issued_at")
        )
    }
}
