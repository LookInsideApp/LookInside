import Foundation
@testable import LookInsideActivation
import Testing

struct LicenseSummaryMappingTests {
    @Test func trialStartDateComesFromLicenseSummaryIssuedAt() throws {
        let trialStartedAt = TestData.baseNow.addingTimeInterval(-8 * 24 * 60 * 60)
        let renewedLeaseIssuedAt = TestData.baseNow
        let serviceEndsAt = trialStartedAt.addingTimeInterval(14 * 24 * 60 * 60)
        let client = LookInsideAuthenticatorAPIClient()
        let lease = TestData.makeIntermediateCertificateLease(
            licenseID: "lic_trial_mapping",
            issuedAt: renewedLeaseIssuedAt,
            expiresAt: renewedLeaseIssuedAt.addingTimeInterval(24 * 60 * 60),
            renewAfter: renewedLeaseIssuedAt,
            issuanceReason: .renewal
        )
        let summary = LicenseSummaryPayload(
            licenseID: "lic_trial_mapping",
            licenseClass: "trial",
            lifecycleState: "active",
            issuedTo: nil,
            issuedAt: AuthServerTestISO8601.string(from: trialStartedAt),
            email: nil,
            productID: "prod_test",
            servicePeriodEndAt: AuthServerTestISO8601.string(from: serviceEndsAt),
            currentCertificateID: lease.certificateID,
            renewAfter: AuthServerTestISO8601.string(from: lease.renewAfter),
            lastVerifiedAt: AuthServerTestISO8601.string(from: renewedLeaseIssuedAt),
            notices: [],
            deviceWarning: nil,
            canIssueCertificate: true,
            blockedReason: nil
        )

        let license = try client.makeLicenseEnvelope(
            from: summary,
            currentLease: lease,
            deviceID: lease.udid
        )

        #expect(license.issuedAt == trialStartedAt)
        #expect(license.serviceEndsAt == serviceEndsAt)
        #expect(license.certificateChain.intermediateIssuedAt == renewedLeaseIssuedAt)
    }
}

private enum AuthServerTestISO8601 {
    static func string(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
