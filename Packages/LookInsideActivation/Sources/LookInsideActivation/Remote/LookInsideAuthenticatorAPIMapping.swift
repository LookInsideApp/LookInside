import Foundation

extension LookInsideAuthenticatorAPIClient {
    func fetchCurrentLeaseIfPresent(
        certificateID: String?,
        licenseID: String,
        deviceIdentifier: String
    ) async throws -> IntermediateCertificateLease? {
        guard let certificateID else {
            return nil
        }

        let response: IntermediateCertificatePayload = try await send(
            path: "/v1/intermediate-certificates/\(certificateID)",
            method: "GET"
        )

        return try makeIntermediateCertificateLease(
            from: response,
            licenseID: licenseID,
            deviceIdentifier: deviceIdentifier
        )
    }

    func makeLicenseEnvelope(
        from summary: LicenseSummaryPayload,
        currentLease: IntermediateCertificateLease?,
        deviceID: String
    ) throws -> LicenseEnvelope {
        let serviceEndsAt = try summary.servicePeriodEndAt.map {
            try Self.parseDate($0, field: "service_period_end_at")
        }
        let issuedAt = try Self.parseDate(summary.issuedAt, field: "issued_at")
        let fallbackExpiry = serviceEndsAt ?? issuedAt.addingTimeInterval(30 * 24 * 60 * 60)
        let fallbackRenewAfter = min(
            issuedAt.addingTimeInterval(24 * 60 * 60),
            fallbackExpiry
        )
        let certificateChain =
            currentLease.map(Self.makeCertificateChain(from:))
                ?? CertificateChain(
                    rootCertificateID: EmbeddedTrustedRoots.rootProd2026.certificateID,
                    intermediateCertificateID: summary.currentCertificateID ?? "pending-\(summary.licenseID)",
                    intermediateIssuedAt: issuedAt,
                    intermediateExpiresAt: fallbackExpiry,
                    renewAfter: fallbackRenewAfter,
                    boundUDID: deviceID
                )
        let nextCertificateRenewalAt =
            try currentLease?.renewAfter
                ?? summary.renewAfter.map {
                    try Self.parseDate($0, field: "renew_after")
                }

        return try LicenseEnvelope(
            licenseID: summary.licenseID,
            audience: .personal,
            licenseClass: makeLicenseClass(from: summary.licenseClass),
            lifecycleState: makeLifecycleState(from: summary.lifecycleState),
            issuedTo: summary.issuedTo,
            issuedAt: issuedAt,
            expiresAt: serviceEndsAt,
            serviceEndsAt: serviceEndsAt,
            nextCertificateRenewalAt: nextCertificateRenewalAt,
            deviceWarning: summary.deviceWarning,
            certificateChain: certificateChain
        )
    }

    func makeDeviceBinding(
        from summary: LicenseSummaryPayload,
        deviceID: String,
        lastFetchedAt: Date
    ) -> DeviceBinding {
        DeviceBinding(
            licenseID: summary.licenseID,
            udid: deviceID,
            machineName: nil,
            hardwareModel: "unknown",
            operatingSystemVersion: "unknown",
            appBundleID: "unknown",
            status: summary.deviceWarning == nil ? .active : .reviewRequired,
            firstSeenAt: lastFetchedAt,
            lastSeenAt: lastFetchedAt,
            reviewNote: summary.deviceWarning ?? summary.blockedReason
        )
    }

    func makeIntermediateCertificateLease(
        from payload: IntermediateCertificatePayload,
        licenseID: String,
        deviceIdentifier: String
    ) throws -> IntermediateCertificateLease {
        try IntermediateCertificateLease(
            certificateID: payload.certificateID,
            licenseID: licenseID,
            udid: deviceIdentifier,
            issuedAt: Self.parseDate(payload.issuedAt, field: "issued_at"),
            expiresAt: Self.parseDate(payload.expiresAt, field: "expires_at"),
            renewAfter: Self.parseDate(payload.renewAfter, field: "renew_after"),
            issuanceReason: makeIssuanceReason(from: payload.issuanceReason),
            renewalBlockedReason: payload.renewalBlockedReason,
            certificatePEM: payload.certificatePEM,
            publicKeyPEM: payload.publicKeyPEM,
            fullChainPEM: payload.fullChainPEM,
            status: makeLeaseStatus(from: payload.status)
        )
    }

    func makeLicenseClass(from rawValue: String) throws -> LicenseClass {
        guard let licenseClass = LicenseClass(rawValue: rawValue) else {
            throw LookInsideAuthenticatorAPIClientError.invalidResponse
        }

        return licenseClass
    }

    func makeLifecycleState(from rawValue: String) -> LicenseLifecycleState {
        switch rawValue {
        case "active":
            return .active
        case "canceled":
            return .canceled
        case "refunded":
            return .refunded
        case "expired":
            return .expired
        case "review":
            return .pendingReview
        default:
            return .pendingReview
        }
    }

    func makeIssuanceReason(from rawValue: String) -> IntermediateCertificateIssuanceReason {
        switch rawValue {
        case "renewal":
            return .renewal
        default:
            return .initialActivation
        }
    }

    func makeLeaseStatus(from rawValue: String) -> IntermediateCertificateLeaseStatus {
        switch rawValue {
        case "active":
            return .active
        case "expired":
            return .expired
        case "superseded":
            return .superseded
        case "blocked", "revoked":
            return .renewalBlocked
        default:
            return .renewalBlocked
        }
    }

    static func makeCertificateChain(from lease: IntermediateCertificateLease) -> CertificateChain {
        CertificateChain(
            rootCertificateID: EmbeddedTrustedRoots.rootProd2026.certificateID,
            intermediateCertificateID: lease.certificateID,
            intermediateIssuedAt: lease.issuedAt,
            intermediateExpiresAt: lease.expiresAt,
            renewAfter: lease.renewAfter,
            boundUDID: lease.udid
        )
    }

    static func makeRequestNonce(prefix: String) -> String {
        "\(prefix)-\(UUID().uuidString.lowercased())"
    }

    static func parseDate(_ rawValue: String, field: String) throws -> Date {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: rawValue) {
            return date
        }

        let internetDateFormatter = ISO8601DateFormatter()
        internetDateFormatter.formatOptions = [.withInternetDateTime]
        if let date = internetDateFormatter.date(from: rawValue) {
            return date
        }

        throw LookInsideAuthenticatorAPIClientError.invalidTimestamp(field: field, value: rawValue)
    }

    static func decodeSessionClaims(from token: String) throws -> ActivationSessionTokenClaims {
        let segments = token.split(separator: ".", omittingEmptySubsequences: false)
        guard let payload = segments.first,
              let data = decodeBase64URL(String(payload))
        else {
            throw LookInsideAuthenticatorAPIClientError.invalidSessionToken
        }

        do {
            return try JSONDecoder().decode(ActivationSessionTokenClaims.self, from: data)
        } catch {
            throw LookInsideAuthenticatorAPIClientError.invalidSessionToken
        }
    }

    static func activationSessionStub(from token: String) -> ActivationSession? {
        guard let claims = try? decodeSessionClaims(from: token),
              let issuedAt = try? parseDate(claims.issuedAt, field: "issued_at"),
              let expiresAt = try? parseDate(claims.expiresAt, field: "expires_at")
        else {
            return nil
        }

        return ActivationSession(
            sessionID: claims.sessionID,
            licenseID: claims.licenseID,
            orderID: claims.orderID,
            email: claims.email,
            deviceIdentifier: claims.deviceIdentifier,
            token: token,
            expiresAt: expiresAt,
            createdAt: issuedAt
        )
    }

    static func decodeBase64URL(_ rawValue: String) -> Data? {
        var normalized =
            rawValue
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
        let paddingLength = (4 - normalized.count % 4) % 4
        normalized.append(String(repeating: "=", count: paddingLength))
        return Data(base64Encoded: normalized)
    }
}
