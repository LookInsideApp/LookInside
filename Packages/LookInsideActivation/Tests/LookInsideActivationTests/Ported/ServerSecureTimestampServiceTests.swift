import Foundation
@testable import LookInsideActivation
import Testing

struct ServerSecureTimestampServiceTests {
    @Test func serviceValidatesTrustAndSignsTimestamp() async throws {
        let fixture = CoordinatorFixture(licenseClass: .trial)
        let service = ServerSecureTimestampService(
            clock: fixture.clock,
            trustValidator: fixture.trustValidator,
            rootTimestampSigner: fixture.rootTimestampSigner
        )

        let token = try await service.issueTimestamp(
            for: fixture.timestampRequest,
            license: fixture.request.license
        )

        #expect(token.rootCertificateID == fixture.request.license.certificateChain.rootCertificateID)
        #expect(fixture.trustValidator.validateCount == 1)
        #expect(fixture.rootTimestampSigner.signCount == 1)
        #expect(fixture.rootTimestampSigner.lastRequest == fixture.timestampRequest)
        #expect(fixture.rootTimestampSigner.lastNow == fixture.now)
    }

    @Test func trustValidationFailureStopsSigning() async throws {
        let fixture = CoordinatorFixture(licenseClass: .trial)
        fixture.trustValidator.error = AuthenticatorError.intermediateCertificateExpired
        let service = ServerSecureTimestampService(
            clock: fixture.clock,
            trustValidator: fixture.trustValidator,
            rootTimestampSigner: fixture.rootTimestampSigner
        )

        await #expect(throws: AuthenticatorError.intermediateCertificateExpired) {
            try await service.issueTimestamp(for: fixture.timestampRequest, license: fixture.request.license)
        }

        #expect(fixture.trustValidator.validateCount == 1)
        #expect(fixture.rootTimestampSigner.signCount == 0)
    }

    @Test func signerFailurePropagates() async throws {
        let fixture = CoordinatorFixture(licenseClass: .trial)
        fixture.rootTimestampSigner.error = TestFailure.signFailed
        let service = ServerSecureTimestampService(
            clock: fixture.clock,
            trustValidator: fixture.trustValidator,
            rootTimestampSigner: fixture.rootTimestampSigner
        )

        await #expect(throws: TestFailure.signFailed) {
            try await service.issueTimestamp(for: fixture.timestampRequest, license: fixture.request.license)
        }

        #expect(fixture.trustValidator.validateCount == 1)
        #expect(fixture.rootTimestampSigner.signCount == 1)
    }
}
