import Foundation

public struct SystemClock: Clock, Sendable {
    public init() {}

    public func now() -> Date {
        Date()
    }
}

public struct DateBoundTrustChainValidator: TrustChainValidating, Sendable {
    public let acceptedClockSkew: TimeInterval

    public init() {
        acceptedClockSkew = 30
    }

    public init(acceptedClockSkew: TimeInterval) {
        self.acceptedClockSkew = acceptedClockSkew
    }

    public func validate(_ certificateChain: CertificateChain, at now: Date) throws {
        if now.addingTimeInterval(acceptedClockSkew) < certificateChain.intermediateIssuedAt {
            throw AuthenticatorError.intermediateCertificateNotYetValid
        }

        if now > certificateChain.intermediateExpiresAt {
            throw AuthenticatorError.intermediateCertificateExpired
        }
    }
}

public struct DefaultChallengeValidator: ChallengeValidating, Sendable {
    public init() {}

    public func validate(_ challenge: ClientActivationChallenge, now: Date, policy: ActivationPolicy) throws {
        let futureThreshold = now.addingTimeInterval(policy.acceptedClockSkew)
        if challenge.issuedAt > futureThreshold {
            throw AuthenticatorError.challengeIssuedInFuture
        }

        let expirationThreshold = now.addingTimeInterval(-policy.challengeTimeToLive)
        if challenge.issuedAt < expirationThreshold {
            throw AuthenticatorError.challengeExpired
        }
    }
}

public struct DefaultSecureTimestampValidator: SecureTimestampValidating, Sendable {
    private let trustedRootsByID: [String: TrustedRootPublicKey]

    public init(trustedRoots: [TrustedRootPublicKey] = EmbeddedTrustedRoots.trusted) {
        trustedRootsByID = Dictionary(
            trustedRoots.map { ($0.certificateID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    public func validate(
        _ token: SecureTimestampToken,
        against request: SecureTimestampRequest,
        trustedRootCertificateID: String,
        now: Date,
        policy: ActivationPolicy
    ) throws {
        guard trustedRootsByID[trustedRootCertificateID] != nil else {
            throw AuthenticatorError.secureTimestampRootMismatch
        }

        if token.rootCertificateID != trustedRootCertificateID {
            throw AuthenticatorError.secureTimestampRootMismatch
        }

        if token.challengeNonce != request.challengeNonce {
            throw AuthenticatorError.secureTimestampNonceMismatch
        }

        let expirationThreshold = now.addingTimeInterval(-policy.secureTimestampTimeToLive)
        if token.signedAt < expirationThreshold {
            throw AuthenticatorError.secureTimestampExpired
        }
    }
}
