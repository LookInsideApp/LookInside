import Foundation
@testable import LookInsideActivation
import Testing

struct EntitlementDisplayStateTests {
    @Test func trialReportsCeilingDaysRemaining() {
        let trialEnd = TestData.baseNow.addingTimeInterval(14 * 24 * 60 * 60)
        let license = Self.makeLicense(
            licenseClass: .trial,
            lifecycleState: .active,
            serviceEndsAt: trialEnd
        )
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.displayState == .trial(daysRemaining: 14))
        #expect(status.entitlementEndsAt == trialEnd)
    }

    @Test func trialNearExpiryRoundsUpToOneDay() {
        let trialEnd = TestData.baseNow.addingTimeInterval(60 * 60)
        let license = Self.makeLicense(
            licenseClass: .trial,
            lifecycleState: .active,
            serviceEndsAt: trialEnd
        )
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.displayState == .trial(daysRemaining: 1))
    }

    @Test func trialPastExpiryReportsZeroDays() {
        let trialEnd = TestData.baseNow.addingTimeInterval(-60)
        let license = Self.makeLicense(
            licenseClass: .trial,
            lifecycleState: .active,
            serviceEndsAt: trialEnd
        )
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.displayState == .trial(daysRemaining: 0))
    }

    @Test func fullActiveLicenseMapsToSubscriptionActive() {
        let license = Self.makeLicense(licenseClass: .full, lifecycleState: .active)
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.displayState == .subscriptionActive)
    }

    @Test func fullCanceledLicenseMapsToSubscriptionCanceled() {
        let license = Self.makeLicense(licenseClass: .full, lifecycleState: .canceled)
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.displayState == .subscriptionCanceled)
    }

    @Test func fullExpiredLicenseMapsToSubscriptionExpired() {
        let license = Self.makeLicense(licenseClass: .full, lifecycleState: .expired)
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.displayState == .subscriptionExpired)
    }

    @Test func fullRefundedLicenseMapsToSubscriptionRefunded() {
        let license = Self.makeLicense(licenseClass: .full, lifecycleState: .refunded)
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.displayState == .subscriptionRefunded)
    }

    @Test func fullPendingReviewMapsToSubscriptionInReview() {
        let license = Self.makeLicense(licenseClass: .full, lifecycleState: .pendingReview)
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.displayState == .subscriptionInReview)
    }

    @Test func effectiveAccessEndsAtPrefersEarlierOfLeaseAndEntitlement() {
        let entitlementEnd = TestData.baseNow.addingTimeInterval(14 * 24 * 60 * 60)
        let leaseEnd = TestData.baseNow.addingTimeInterval(30 * 24 * 60 * 60)
        let license = Self.makeLicense(
            licenseClass: .trial,
            lifecycleState: .active,
            serviceEndsAt: entitlementEnd
        )
        let lease = TestData.makeIntermediateCertificateLease(expiresAt: leaseEnd)
        let status = TestData.makeEntitlementStatus(license: license, currentLease: lease)

        #expect(status.effectiveAccessEndsAt == entitlementEnd)
    }

    @Test func effectiveAccessEndsAtPrefersLeaseWhenLeaseEndsFirst() {
        let entitlementEnd = TestData.baseNow.addingTimeInterval(30 * 24 * 60 * 60)
        let leaseEnd = TestData.baseNow.addingTimeInterval(14 * 24 * 60 * 60)
        let license = Self.makeLicense(
            licenseClass: .full,
            lifecycleState: .active,
            serviceEndsAt: entitlementEnd
        )
        let lease = TestData.makeIntermediateCertificateLease(expiresAt: leaseEnd)
        let status = TestData.makeEntitlementStatus(license: license, currentLease: lease)

        #expect(status.effectiveAccessEndsAt == leaseEnd)
    }

    @Test func effectiveAccessEndsAtIsNilForPerpetualWithoutLease() {
        let license = Self.makeLicense(
            licenseClass: .full,
            lifecycleState: .active,
            expiresAt: nil,
            serviceEndsAt: nil
        )
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.effectiveAccessEndsAt == nil)
    }

    @Test func certificateRenewalAtPrefersLeaseRenewAfter() {
        let leaseRenewAfter = TestData.baseNow.addingTimeInterval(24 * 60 * 60)
        let envelopeRenewalAt = TestData.baseNow.addingTimeInterval(48 * 60 * 60)
        let license = Self.makeLicense(
            licenseClass: .full,
            lifecycleState: .active,
            nextCertificateRenewalAt: envelopeRenewalAt
        )
        let lease = TestData.makeIntermediateCertificateLease(
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(30 * 24 * 60 * 60),
            renewAfter: leaseRenewAfter
        )
        let status = TestData.makeEntitlementStatus(license: license, currentLease: lease)

        #expect(status.certificateRenewalAt == leaseRenewAfter)
    }

    @Test func certificateRenewalAtFallsBackToEnvelopeWhenNoLease() {
        let envelopeRenewalAt = TestData.baseNow.addingTimeInterval(24 * 60 * 60)
        let license = Self.makeLicense(
            licenseClass: .full,
            lifecycleState: .active,
            nextCertificateRenewalAt: envelopeRenewalAt
        )
        let status = TestData.makeEntitlementStatus(license: license)

        #expect(status.certificateRenewalAt == envelopeRenewalAt)
    }

    private static func makeLicense(
        licenseClass: LicenseClass,
        lifecycleState: LicenseLifecycleState,
        expiresAt: Date? = TestData.baseNow.addingTimeInterval(3600),
        serviceEndsAt: Date? = nil,
        nextCertificateRenewalAt: Date? = nil
    ) -> LicenseEnvelope {
        LicenseEnvelope(
            licenseID: "license-xyz",
            licenseClass: licenseClass,
            lifecycleState: lifecycleState,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: expiresAt,
            serviceEndsAt: serviceEndsAt,
            nextCertificateRenewalAt: nextCertificateRenewalAt,
            certificateChain: TestData.makeCertificateChain()
        )
    }
}
