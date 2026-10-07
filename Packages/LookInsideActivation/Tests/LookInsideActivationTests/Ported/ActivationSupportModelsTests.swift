import Foundation
@testable import LookInsideActivation
import Testing

struct ActivationSupportModelsTests {
    @Test func certificateChainDefaultsRenewAfterToOneDayAfterIssuance() {
        let expiresAt = TestData.baseNow.addingTimeInterval(30 * 24 * 60 * 60)
        let chain = CertificateChain(
            rootCertificateID: TestData.embeddedRootCertificateID,
            intermediateCertificateID: "ic_host_cn_001",
            intermediateIssuedAt: TestData.baseNow,
            intermediateExpiresAt: expiresAt
        )

        #expect(chain.renewAfter == TestData.baseNow.addingTimeInterval(24 * 60 * 60))
    }

    @Test func certificateChainClampsRenewAfterToExpiryForShortValidity() {
        let expiresAt = TestData.baseNow.addingTimeInterval(6 * 60 * 60)
        let chain = CertificateChain(
            rootCertificateID: TestData.embeddedRootCertificateID,
            intermediateCertificateID: "ic_host_cn_001",
            intermediateIssuedAt: TestData.baseNow,
            intermediateExpiresAt: expiresAt
        )

        #expect(chain.renewAfter == expiresAt)
    }

    @Test func licenseEnvelopePersistsCanceledLifecycleAndDeviceWarning() {
        let license = LicenseEnvelope(
            licenseID: "license-123",
            audience: .personal,
            licenseClass: .full,
            lifecycleState: .canceled,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            serviceEndsAt: TestData.baseNow.addingTimeInterval(1800),
            deviceWarning: "This license has been activated on multiple devices. Usage may be reviewed manually.",
            certificateChain: TestData.makeCertificateChain()
        )

        #expect(license.lifecycleState == .canceled)
        #expect(license.audience == .personal)
        #expect(license.deviceWarning?.isEmpty == false)
    }

    @Test func signedActivationEnvelopeCarriesBoundUDID() {
        let envelope = SignedActivationEnvelope(
            activationID: "activation-123",
            challengeNonce: "nonce-123",
            licenseID: "license-123",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            intermediateCertificateID: "lease-cert-001",
            boundUDID: "device-123",
            artifacts: []
        )

        #expect(envelope.boundUDID == "device-123")
    }

    @Test func applyingLeaseUpdatesCertificateChainBindingAndRenewalWindow() {
        let license = LicenseEnvelope(
            licenseID: "license-123",
            licenseClass: .full,
            lifecycleState: .refunded,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain()
        )
        let lease = TestData.makeIntermediateCertificateLease(
            certificateID: "lease-cert-002",
            expiresAt: TestData.baseNow.addingTimeInterval(45 * 24 * 60 * 60)
        )

        let updated = license.applying(lease: lease)

        #expect(updated.lifecycleState == LicenseLifecycleState.refunded)
        #expect(updated.certificateChain.intermediateCertificateID == "lease-cert-002")
        #expect(updated.certificateChain.boundUDID == lease.udid)
        #expect(updated.certificateChain.renewAfter == lease.renewAfter)
    }
}
