import Foundation
@testable import LookInsideActivation
@testable import LookInsideActivationUI
import Testing

struct ActivationChallengeSignerTests {
    @Test func validRequestProducesNonceConcatenatedMessage() throws {
        let snapshot = Self.snapshot(with: Self.makeLease())
        let request = Self.makeRequest()
        let decision = ActivationAccessDecision.allowed(statusSummary: "ok")

        let validated = try ActivationChallengeSigner.validate(
            request: request,
            snapshot: snapshot,
            decision: decision,
            evaluatedAt: TestData.baseNow
        )

        let expectedMessage = Self.expectedMessage(
            nonceHex: request.nonce,
            serverInstanceID: request.serverInstanceID
        )
        #expect(validated.message == expectedMessage)
        #expect(validated.lease.certificateID == "lease-cert-001")
        #expect(validated.certificateDER == Data([0, 0, 0]))
    }

    @Test func blockDecisionRejectsSigning() {
        let snapshot = Self.snapshot(with: Self.makeLease())
        let request = Self.makeRequest()
        let decision = ActivationAccessDecision.expired(at: TestData.baseNow)

        #expect(throws: ActivationError.self) {
            try ActivationChallengeSigner.validate(
                request: request,
                snapshot: snapshot,
                decision: decision,
                evaluatedAt: TestData.baseNow
            )
        }
    }

    @Test func expiredLeaseRejectsSigning() {
        let expiredLease = Self.makeLease(
            issuedAt: TestData.baseNow.addingTimeInterval(-3600),
            expiresAt: TestData.baseNow.addingTimeInterval(-60)
        )
        let snapshot = Self.snapshot(with: expiredLease)
        let request = Self.makeRequest()
        let decision = ActivationAccessDecision.allowed(statusSummary: "ok")

        #expect(throws: ActivationError.self) {
            try ActivationChallengeSigner.validate(
                request: request,
                snapshot: snapshot,
                decision: decision,
                evaluatedAt: TestData.baseNow
            )
        }
    }

    @Test func missingLeaseRejectsSigning() {
        var snapshot = ActivationPersistedState()
        let license = LicenseEnvelope(
            licenseID: "license-xyz",
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain()
        )
        snapshot.entitlementStatus = TestData.makeEntitlementStatus(license: license)
        let request = Self.makeRequest()
        let decision = ActivationAccessDecision.allowed(statusSummary: "ok")

        #expect(throws: ActivationError.self) {
            try ActivationChallengeSigner.validate(
                request: request,
                snapshot: snapshot,
                decision: decision,
                evaluatedAt: TestData.baseNow
            )
        }
    }

    @Test func malformedNonceRejectsSigning() {
        let snapshot = Self.snapshot(with: Self.makeLease())
        let request = ActivationSignChallengeRequest(
            nonce: "not-hex",
            serverInstanceID: "srv-instance",
            subjectUDIDHint: nil
        )
        let decision = ActivationAccessDecision.allowed(statusSummary: "ok")

        #expect(throws: ActivationError.self) {
            try ActivationChallengeSigner.validate(
                request: request,
                snapshot: snapshot,
                decision: decision,
                evaluatedAt: TestData.baseNow
            )
        }
    }

    @Test func decodesPemBodyIgnoringHeaderAndWhitespace() {
        let pem = """
        -----BEGIN CERTIFICATE-----
        AAAA
        -----END CERTIFICATE-----
        """
        let der = ActivationChallengeSigner.certificateDER(fromPEM: pem)
        #expect(der == Data([0, 0, 0]))
    }

    private static func makeLease(
        issuedAt: Date = TestData.baseNow,
        expiresAt: Date = TestData.baseNow.addingTimeInterval(3600)
    ) -> IntermediateCertificateLease {
        IntermediateCertificateLease(
            certificateID: "lease-cert-001",
            licenseID: "license-123",
            udid: "device-123",
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            issuanceReason: .initialActivation,
            certificatePEM: "-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----",
            publicKeyPEM: "-----BEGIN PUBLIC KEY-----\nAAAA\n-----END PUBLIC KEY-----",
            fullChainPEM: "-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----"
        )
    }

    private static func snapshot(with lease: IntermediateCertificateLease) -> ActivationPersistedState {
        let license = LicenseEnvelope(
            licenseID: "license-xyz",
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain()
        )
        var snapshot = ActivationPersistedState()
        snapshot.entitlementStatus = TestData.makeEntitlementStatus(
            license: license,
            currentLease: lease
        )
        return snapshot
    }

    private static func makeRequest(
        nonce: String = String(repeating: "ab", count: 32),
        serverInstanceID: String = "srv-instance"
    ) -> ActivationSignChallengeRequest {
        ActivationSignChallengeRequest(
            nonce: nonce,
            serverInstanceID: serverInstanceID,
            subjectUDIDHint: nil
        )
    }

    private static func expectedMessage(nonceHex: String, serverInstanceID: String) -> Data {
        var message = Data()
        var index = nonceHex.startIndex
        while index < nonceHex.endIndex {
            let next = nonceHex.index(index, offsetBy: 2)
            message.append(UInt8(nonceHex[index ..< next], radix: 16) ?? 0)
            index = next
        }
        message.append(contentsOf: Array(serverInstanceID.utf8))
        return message
    }
}
