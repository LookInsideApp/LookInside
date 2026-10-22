import Foundation
@testable import LookInsideActivation
import Testing

struct DateBoundTrustChainValidatorTests {
    @Test func acceptsIntermediateCertificateWithinWindow() throws {
        let validator = DateBoundTrustChainValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let chain = TestData.makeCertificateChain(
            intermediateIssuedAt: now.addingTimeInterval(-60),
            intermediateExpiresAt: now.addingTimeInterval(60)
        )

        try validator.validate(chain, at: now)
    }

    @Test func rejectsIntermediateCertificateBeforeIssueTime() throws {
        let validator = DateBoundTrustChainValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let chain = TestData.makeCertificateChain(
            intermediateIssuedAt: now.addingTimeInterval(31),
            intermediateExpiresAt: now.addingTimeInterval(60)
        )

        #expect(throws: AuthenticatorError.intermediateCertificateNotYetValid) {
            try validator.validate(chain, at: now)
        }
    }

    @Test func acceptsIntermediateCertificateWithinClockSkew() throws {
        let validator = DateBoundTrustChainValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let chain = TestData.makeCertificateChain(
            intermediateIssuedAt: now.addingTimeInterval(30),
            intermediateExpiresAt: now.addingTimeInterval(60)
        )

        try validator.validate(chain, at: now)
    }

    @Test func rejectsIntermediateCertificateAfterExpiry() throws {
        let validator = DateBoundTrustChainValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let chain = TestData.makeCertificateChain(
            intermediateIssuedAt: now.addingTimeInterval(-60),
            intermediateExpiresAt: now.addingTimeInterval(-1)
        )

        #expect(throws: AuthenticatorError.intermediateCertificateExpired) {
            try validator.validate(chain, at: now)
        }
    }
}

struct DefaultChallengeValidatorTests {
    @Test func acceptsChallengeInsideFreshnessWindow() throws {
        let validator = DefaultChallengeValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let policy = ActivationPolicy(acceptedClockSkew: 30, challengeTimeToLive: 180)
        let challenge = TestData.makeChallenge(issuedAt: now.addingTimeInterval(-60))

        try validator.validate(challenge, now: now, policy: policy)
    }

    @Test func acceptsChallengeAtFutureSkewBoundary() throws {
        let validator = DefaultChallengeValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let policy = ActivationPolicy(acceptedClockSkew: 30, challengeTimeToLive: 180)
        let challenge = TestData.makeChallenge(issuedAt: now.addingTimeInterval(30))

        try validator.validate(challenge, now: now, policy: policy)
    }

    @Test func rejectsChallengeBeyondFutureSkewBoundary() throws {
        let validator = DefaultChallengeValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let policy = ActivationPolicy(acceptedClockSkew: 30, challengeTimeToLive: 180)
        let challenge = TestData.makeChallenge(issuedAt: now.addingTimeInterval(31))

        #expect(throws: AuthenticatorError.challengeIssuedInFuture) {
            try validator.validate(challenge, now: now, policy: policy)
        }
    }

    @Test func acceptsChallengeAtExpirationBoundary() throws {
        let validator = DefaultChallengeValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let policy = ActivationPolicy(acceptedClockSkew: 30, challengeTimeToLive: 180)
        let challenge = TestData.makeChallenge(issuedAt: now.addingTimeInterval(-180))

        try validator.validate(challenge, now: now, policy: policy)
    }

    @Test func rejectsExpiredChallenge() throws {
        let validator = DefaultChallengeValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let policy = ActivationPolicy(acceptedClockSkew: 30, challengeTimeToLive: 180)
        let challenge = TestData.makeChallenge(issuedAt: now.addingTimeInterval(-181))

        #expect(throws: AuthenticatorError.challengeExpired) {
            try validator.validate(challenge, now: now, policy: policy)
        }
    }
}

struct DefaultSecureTimestampValidatorTests {
    @Test func acceptsMatchingFreshToken() throws {
        let validator = DefaultSecureTimestampValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let policy = ActivationPolicy(secureTimestampTimeToLive: 120)
        let request = TestData.makeTimestampRequest(challengeNonce: "nonce-123")
        let trustedRootID = EmbeddedTrustedRoots.rootProd2026.certificateID
        let token = SecureTimestampToken(
            challengeNonce: "nonce-123",
            signedAt: now.addingTimeInterval(-119),
            rootCertificateID: trustedRootID,
            signature: Data()
        )

        try validator.validate(
            token,
            against: request,
            trustedRootCertificateID: trustedRootID,
            now: now,
            policy: policy
        )
    }

    @Test func rejectsRootMismatch() throws {
        let validator = DefaultSecureTimestampValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let request = TestData.makeTimestampRequest(challengeNonce: "nonce-123")
        let trustedRootID = EmbeddedTrustedRoots.rootProd2026.certificateID
        let token = SecureTimestampToken(
            challengeNonce: "nonce-123",
            signedAt: now,
            rootCertificateID: "other-root",
            signature: Data()
        )

        #expect(throws: AuthenticatorError.secureTimestampRootMismatch) {
            try validator.validate(
                token,
                against: request,
                trustedRootCertificateID: trustedRootID,
                now: now,
                policy: ActivationPolicy()
            )
        }
    }

    @Test func rejectsNonceMismatch() throws {
        let validator = DefaultSecureTimestampValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let request = TestData.makeTimestampRequest(challengeNonce: "nonce-123")
        let trustedRootID = EmbeddedTrustedRoots.rootProd2026.certificateID
        let token = SecureTimestampToken(
            challengeNonce: "nonce-other",
            signedAt: now,
            rootCertificateID: trustedRootID,
            signature: Data()
        )

        #expect(throws: AuthenticatorError.secureTimestampNonceMismatch) {
            try validator.validate(
                token,
                against: request,
                trustedRootCertificateID: trustedRootID,
                now: now,
                policy: ActivationPolicy()
            )
        }
    }

    @Test func acceptsTokenAtExpirationBoundary() throws {
        let validator = DefaultSecureTimestampValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let policy = ActivationPolicy(secureTimestampTimeToLive: 120)
        let request = TestData.makeTimestampRequest(challengeNonce: "nonce-123")
        let trustedRootID = EmbeddedTrustedRoots.rootProd2026.certificateID
        let token = SecureTimestampToken(
            challengeNonce: "nonce-123",
            signedAt: now.addingTimeInterval(-120),
            rootCertificateID: trustedRootID,
            signature: Data()
        )

        try validator.validate(
            token,
            against: request,
            trustedRootCertificateID: trustedRootID,
            now: now,
            policy: policy
        )
    }

    @Test func rejectsExpiredToken() throws {
        let validator = DefaultSecureTimestampValidator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let policy = ActivationPolicy(secureTimestampTimeToLive: 120)
        let request = TestData.makeTimestampRequest(challengeNonce: "nonce-123")
        let trustedRootID = EmbeddedTrustedRoots.rootProd2026.certificateID
        let token = SecureTimestampToken(
            challengeNonce: "nonce-123",
            signedAt: now.addingTimeInterval(-121),
            rootCertificateID: trustedRootID,
            signature: Data()
        )

        #expect(throws: AuthenticatorError.secureTimestampExpired) {
            try validator.validate(
                token,
                against: request,
                trustedRootCertificateID: trustedRootID,
                now: now,
                policy: policy
            )
        }
    }
}
