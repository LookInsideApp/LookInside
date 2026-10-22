import Foundation
@testable import LookInsideActivation

enum TestFailure: Error, Equatable {
    case fetchFailed
    case issueFailed
    case signFailed
}

enum RelativeDate {
    case secondsFromBase(TimeInterval)
    case none
}

enum TestData {
    static let baseNow = Date(timeIntervalSince1970: 1_710_000_000)
    static let embeddedRootCertificateID = EmbeddedTrustedRoots.rootProd2026.certificateID

    static func makeCertificateChain(
        rootCertificateID: String = embeddedRootCertificateID,
        intermediateCertificateID: String = "intermediate-cert",
        intermediateIssuedAt: Date = baseNow.addingTimeInterval(-60),
        intermediateExpiresAt: Date = baseNow.addingTimeInterval(3600),
        renewAfter: Date? = nil,
        boundUDID: String? = nil
    ) -> CertificateChain {
        CertificateChain(
            rootCertificateID: rootCertificateID,
            intermediateCertificateID: intermediateCertificateID,
            intermediateIssuedAt: intermediateIssuedAt,
            intermediateExpiresAt: intermediateExpiresAt,
            renewAfter: renewAfter,
            boundUDID: boundUDID
        )
    }

    static func makeChallenge(
        nonce: String = "nonce-123",
        issuedAt: Date = baseNow,
        requestedFeature: String = "swiftui.bootstrap"
    ) -> ClientActivationChallenge {
        ClientActivationChallenge(
            nonce: nonce,
            issuedAt: issuedAt,
            requestedFeature: requestedFeature,
            frameworkVersion: "1.0.0",
            device: DeviceFingerprint(
                deviceID: "device-123",
                hardwareModel: "iPhone17,1",
                operatingSystemVersion: "18.0",
                appBundleID: "com.lookinside.client"
            )
        )
    }

    static func makeTimestampRequest(
        challengeNonce: String = "nonce-123",
        clientIssuedAt: Date = baseNow
    ) -> SecureTimestampRequest {
        SecureTimestampRequest(
            licenseID: "license-123",
            challengeNonce: challengeNonce,
            clientIssuedAt: clientIssuedAt,
            deviceIdentifier: "device-123",
            requestedFeature: "swiftui.bootstrap"
        )
    }

    static func makeActivationSession(
        sessionID: String = "session-123",
        licenseID: String = "license-123",
        orderID: String? = "ord_123",
        email: String? = "user@example.com",
        deviceIdentifier: String = "device-123",
        token: String = "session-token",
        expiresAt: Date = baseNow.addingTimeInterval(900),
        createdAt: Date = baseNow
    ) -> ActivationSession {
        ActivationSession(
            sessionID: sessionID,
            licenseID: licenseID,
            orderID: orderID,
            email: email,
            deviceIdentifier: deviceIdentifier,
            token: token,
            expiresAt: expiresAt,
            createdAt: createdAt
        )
    }

    static func makeDeviceBinding(
        licenseID: String = "license-123",
        udid: String = "device-123"
    ) -> DeviceBinding {
        DeviceBinding(
            licenseID: licenseID,
            udid: udid,
            machineName: "MacBook Pro",
            hardwareModel: "Mac15,6",
            operatingSystemVersion: "macOS 15.4",
            appBundleID: "com.lookinside.app",
            firstSeenAt: baseNow.addingTimeInterval(-3600),
            lastSeenAt: baseNow
        )
    }

    static func makeIntermediateCertificateLease(
        certificateID: String = "lease-cert-001",
        licenseID: String = "license-123",
        udid: String = "device-123",
        issuedAt: Date = baseNow,
        expiresAt: Date = baseNow.addingTimeInterval(30 * 24 * 60 * 60),
        renewAfter: Date? = nil,
        issuanceReason: IntermediateCertificateIssuanceReason = .initialActivation,
        status: IntermediateCertificateLeaseStatus = .active
    ) -> IntermediateCertificateLease {
        IntermediateCertificateLease(
            certificateID: certificateID,
            licenseID: licenseID,
            udid: udid,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            renewAfter: renewAfter,
            issuanceReason: issuanceReason,
            certificatePEM: "-----BEGIN CERTIFICATE-----\nlease\n-----END CERTIFICATE-----",
            publicKeyPEM: "-----BEGIN PUBLIC KEY-----\nlease\n-----END PUBLIC KEY-----",
            fullChainPEM: "-----BEGIN CERTIFICATE-----\nchain\n-----END CERTIFICATE-----",
            status: status
        )
    }

    static func makeHostActivationResponse(
        activationID: String = "activation-123",
        challengeNonce: String = "nonce-123",
        session: ActivationSession = makeActivationSession(),
        lease: IntermediateCertificateLease = makeIntermediateCertificateLease()
    ) -> HostActivationResponse {
        HostActivationResponse(
            activation: SignedActivationEnvelope(
                activationID: activationID,
                challengeNonce: challengeNonce,
                licenseID: session.licenseID,
                issuedAt: baseNow,
                expiresAt: baseNow.addingTimeInterval(3600),
                intermediateCertificateID: lease.certificateID,
                boundUDID: session.deviceIdentifier,
                artifacts: []
            ),
            path: .direct,
            secureTimestamp: nil
        )
    }

    static func makeEntitlementStatus(
        license: LicenseEnvelope,
        deviceBinding: DeviceBinding? = makeDeviceBinding(),
        currentLease: IntermediateCertificateLease? = nil,
        activationSession: ActivationSession? = nil,
        isEligibleForActivation: Bool = true,
        isEligibleForRenewal: Bool = false,
        warningMessage: String? = nil
    ) -> EntitlementStatus {
        EntitlementStatus(
            license: license,
            deviceBinding: deviceBinding,
            currentLease: currentLease,
            activationSession: activationSession,
            isEligibleForActivation: isEligibleForActivation,
            isEligibleForRenewal: isEligibleForRenewal,
            lastFetchedAt: baseNow,
            warningMessage: warningMessage
        )
    }
}

struct FixedClock: Clock {
    let currentDate: Date

    func now() -> Date {
        currentDate
    }
}

final class RecordingTrustValidator: TrustChainValidating, @unchecked Sendable {
    private(set) var validateCount = 0
    private(set) var lastCertificateChain: CertificateChain?
    private(set) var lastNow: Date?
    var error: Error?

    func validate(_ certificateChain: CertificateChain, at now: Date) throws {
        validateCount += 1
        lastCertificateChain = certificateChain
        lastNow = now
        if let error {
            throw error
        }
    }
}

final class RecordingChallengeValidator: ChallengeValidating, @unchecked Sendable {
    private(set) var validateCount = 0
    private(set) var lastChallenge: ClientActivationChallenge?
    private(set) var lastNow: Date?
    private(set) var lastPolicy: ActivationPolicy?
    var error: Error?

    func validate(_ challenge: ClientActivationChallenge, now: Date, policy: ActivationPolicy) throws {
        validateCount += 1
        lastChallenge = challenge
        lastNow = now
        lastPolicy = policy
        if let error {
            throw error
        }
    }
}

final class RecordingReplayProtector: ReplayProtecting, @unchecked Sendable {
    private(set) var reserveCount = 0
    private(set) var lastNonce: String?
    private(set) var lastExpiry: Date?
    var error: Error?

    func reserve(_ nonce: String, until expiresAt: Date) throws {
        reserveCount += 1
        lastNonce = nonce
        lastExpiry = expiresAt
        if let error {
            throw error
        }
    }
}

final class RecordingSecureTimestampFetcher: SecureTimestampFetching, @unchecked Sendable {
    private(set) var fetchCount = 0
    private(set) var lastRequest: SecureTimestampRequest?
    var error: Error?
    var token: SecureTimestampToken

    init(token: SecureTimestampToken) {
        self.token = token
    }

    func fetchTimestamp(for request: SecureTimestampRequest) async throws -> SecureTimestampToken {
        fetchCount += 1
        lastRequest = request
        if let error {
            throw error
        }
        return token
    }
}

final class RecordingSecureTimestampValidator: SecureTimestampValidating, @unchecked Sendable {
    private(set) var validateCount = 0
    private(set) var lastToken: SecureTimestampToken?
    private(set) var lastRequest: SecureTimestampRequest?
    private(set) var lastTrustedRootCertificateID: String?
    private(set) var lastNow: Date?
    private(set) var lastPolicy: ActivationPolicy?
    var error: Error?

    func validate(
        _ token: SecureTimestampToken,
        against request: SecureTimestampRequest,
        trustedRootCertificateID: String,
        now: Date,
        policy: ActivationPolicy
    ) throws {
        validateCount += 1
        lastToken = token
        lastRequest = request
        lastTrustedRootCertificateID = trustedRootCertificateID
        lastNow = now
        lastPolicy = policy
        if let error {
            throw error
        }
    }
}

final class RecordingActivationIssuer: ActivationMaterialIssuing, @unchecked Sendable {
    private(set) var issueCount = 0
    private(set) var lastChallenge: ClientActivationChallenge?
    private(set) var lastLicense: LicenseEnvelope?
    private(set) var lastPolicy: ActivationPolicy?
    private(set) var lastSecureTimestamp: SecureTimestampToken?
    var error: Error?
    var activation: SignedActivationEnvelope

    init(activation: SignedActivationEnvelope) {
        self.activation = activation
    }

    func issueActivation(
        for challenge: ClientActivationChallenge,
        license: LicenseEnvelope,
        policy: ActivationPolicy,
        secureTimestamp: SecureTimestampToken?
    ) async throws -> SignedActivationEnvelope {
        issueCount += 1
        lastChallenge = challenge
        lastLicense = license
        lastPolicy = policy
        lastSecureTimestamp = secureTimestamp
        if let error {
            throw error
        }
        return activation
    }
}

final class RecordingRootTimestampSigner: RootTimestampSigning, @unchecked Sendable {
    private(set) var signCount = 0
    private(set) var lastRequest: SecureTimestampRequest?
    private(set) var lastNow: Date?
    var error: Error?
    var token: SecureTimestampToken

    init(token: SecureTimestampToken) {
        self.token = token
    }

    func sign(request: SecureTimestampRequest, at now: Date) async throws -> SecureTimestampToken {
        signCount += 1
        lastRequest = request
        lastNow = now
        if let error {
            throw error
        }
        return token
    }
}

struct CoordinatorFixture {
    let now: Date
    let licenseClass: LicenseClass
    let policy: ActivationPolicy
    let clock: FixedClock
    let trustValidator: RecordingTrustValidator
    let challengeValidator: RecordingChallengeValidator
    let replayProtector: RecordingReplayProtector
    let timestampFetcher: RecordingSecureTimestampFetcher
    let timestampValidator: RecordingSecureTimestampValidator
    let activationIssuer: RecordingActivationIssuer
    let rootTimestampSigner: RecordingRootTimestampSigner
    let request: HostActivationRequest
    let timestampRequest: SecureTimestampRequest

    init(
        licenseClass: LicenseClass,
        licenseExpiresAt: RelativeDate = .secondsFromBase(3600),
        requiresSecureTimestampForTrial: Bool = true
    ) {
        now = TestData.baseNow
        self.licenseClass = licenseClass
        policy = ActivationPolicy(
            acceptedClockSkew: 30,
            challengeTimeToLive: 180,
            secureTimestampTimeToLive: 120,
            activationLifetime: 600,
            requiresSecureTimestampForTrial: requiresSecureTimestampForTrial
        )
        clock = FixedClock(currentDate: now)
        trustValidator = RecordingTrustValidator()
        challengeValidator = RecordingChallengeValidator()
        replayProtector = RecordingReplayProtector()

        let challenge = TestData.makeChallenge(issuedAt: now)
        let certificateChain = TestData.makeCertificateChain()
        let expiresAt: Date? =
            switch licenseExpiresAt {
            case let .secondsFromBase(interval):
                now.addingTimeInterval(interval)
            case .none:
                nil
            }
        let license = LicenseEnvelope(
            licenseID: "license-123",
            licenseClass: licenseClass,
            issuedTo: "Acme",
            issuedAt: now,
            expiresAt: expiresAt,
            certificateChain: certificateChain
        )
        request = HostActivationRequest(challenge: challenge, license: license)
        timestampRequest = request.secureTimestampRequest

        let secureTimestamp = SecureTimestampToken(
            challengeNonce: challenge.nonce,
            signedAt: now,
            rootCertificateID: certificateChain.rootCertificateID,
            signature: Data()
        )
        timestampFetcher = RecordingSecureTimestampFetcher(token: secureTimestamp)
        timestampValidator = RecordingSecureTimestampValidator()

        let activation = SignedActivationEnvelope(
            activationID: "activation-123",
            challengeNonce: challenge.nonce,
            licenseID: license.licenseID,
            issuedAt: now,
            expiresAt: now.addingTimeInterval(policy.activationLifetime),
            intermediateCertificateID: certificateChain.intermediateCertificateID,
            boundUDID: challenge.device.deviceID,
            artifacts: [
                ActivationArtifact(
                    name: "swiftui.bundle",
                    payload: Data("signed-material".utf8),
                    digest: "digest-123"
                ),
            ],
            signature: Data()
        )
        activationIssuer = RecordingActivationIssuer(activation: activation)
        rootTimestampSigner = RecordingRootTimestampSigner(token: secureTimestamp)
    }

    func makeHostCoordinator() -> HostActivationCoordinator {
        HostActivationCoordinator(
            policy: policy,
            clock: clock,
            trustValidator: trustValidator,
            challengeValidator: challengeValidator,
            replayProtector: replayProtector,
            secureTimestampFetcher: timestampFetcher,
            secureTimestampValidator: timestampValidator,
            activationIssuer: activationIssuer
        )
    }
}
