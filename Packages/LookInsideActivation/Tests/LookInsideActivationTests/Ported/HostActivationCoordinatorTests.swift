import Foundation
@testable import LookInsideActivation
import Testing

struct HostActivationCoordinatorTests {
    @Test func fullLicenseUsesDirectPathAndSkipsTimestampFetch() async throws {
        let fixture = CoordinatorFixture(licenseClass: .full)
        let sut = fixture.makeHostCoordinator()

        let response = try await sut.activate(fixture.request)

        #expect(response.path == .direct)
        #expect(response.secureTimestamp == nil)
        #expect(fixture.timestampFetcher.fetchCount == 0)
        #expect(fixture.timestampValidator.validateCount == 0)
        #expect(fixture.activationIssuer.issueCount == 1)
        #expect(fixture.activationIssuer.lastSecureTimestamp == nil)
    }

    @Test func trialLicenseFetchesAndValidatesTimestampBeforeIssuingActivation() async throws {
        let fixture = CoordinatorFixture(licenseClass: .trial)
        let sut = fixture.makeHostCoordinator()

        let response = try await sut.activate(fixture.request)

        #expect(response.path == .timeAnchored)
        #expect(response.secureTimestamp?.challengeNonce == fixture.request.challenge.nonce)
        #expect(fixture.timestampFetcher.fetchCount == 1)
        #expect(fixture.timestampValidator.validateCount == 1)
        #expect(fixture.activationIssuer.issueCount == 1)
        #expect(fixture.activationIssuer.lastSecureTimestamp?.challengeNonce == fixture.request.challenge.nonce)
        #expect(fixture.replayProtector.reserveCount == 1)
    }

    @Test func trialLicenseFailsWithoutTimestampProvider() async throws {
        let fixture = CoordinatorFixture(licenseClass: .trial)
        let sut = HostActivationCoordinator(
            policy: fixture.policy,
            clock: fixture.clock,
            trustValidator: fixture.trustValidator,
            challengeValidator: fixture.challengeValidator,
            replayProtector: fixture.replayProtector,
            activationIssuer: fixture.activationIssuer
        )

        await #expect(throws: AuthenticatorError.secureTimestampProviderUnavailable) {
            try await sut.activate(fixture.request)
        }

        #expect(fixture.activationIssuer.issueCount == 0)
    }

    @Test func expiredLicenseStopsActivationBeforeIssue() async throws {
        let fixture = CoordinatorFixture(licenseClass: .full, licenseExpiresAt: .secondsFromBase(-1))
        let sut = fixture.makeHostCoordinator()

        await #expect(throws: AuthenticatorError.licenseExpired) {
            try await sut.activate(fixture.request)
        }

        #expect(fixture.trustValidator.validateCount == 0)
        #expect(fixture.activationIssuer.issueCount == 0)
    }

    @Test func trustValidationFailureStopsActivation() async throws {
        let fixture = CoordinatorFixture(licenseClass: .full)
        fixture.trustValidator.error = AuthenticatorError.intermediateCertificateExpired
        let sut = fixture.makeHostCoordinator()

        await #expect(throws: AuthenticatorError.intermediateCertificateExpired) {
            try await sut.activate(fixture.request)
        }

        #expect(fixture.trustValidator.validateCount == 1)
        #expect(fixture.challengeValidator.validateCount == 0)
        #expect(fixture.activationIssuer.issueCount == 0)
    }

    @Test func challengeValidationFailureStopsActivation() async throws {
        let fixture = CoordinatorFixture(licenseClass: .full)
        fixture.challengeValidator.error = AuthenticatorError.challengeExpired
        let sut = fixture.makeHostCoordinator()

        await #expect(throws: AuthenticatorError.challengeExpired) {
            try await sut.activate(fixture.request)
        }

        #expect(fixture.challengeValidator.validateCount == 1)
        #expect(fixture.replayProtector.reserveCount == 0)
        #expect(fixture.activationIssuer.issueCount == 0)
    }

    @Test func replayProtectionFailureStopsActivation() async throws {
        let fixture = CoordinatorFixture(licenseClass: .full)
        fixture.replayProtector.error = AuthenticatorError.replayDetected
        let sut = fixture.makeHostCoordinator()

        await #expect(throws: AuthenticatorError.replayDetected) {
            try await sut.activate(fixture.request)
        }

        #expect(fixture.replayProtector.reserveCount == 1)
        #expect(fixture.activationIssuer.issueCount == 0)
    }

    @Test func timestampFetchFailureStopsActivation() async throws {
        let fixture = CoordinatorFixture(licenseClass: .trial)
        fixture.timestampFetcher.error = TestFailure.fetchFailed
        let sut = fixture.makeHostCoordinator()

        await #expect(throws: TestFailure.fetchFailed) {
            try await sut.activate(fixture.request)
        }

        #expect(fixture.timestampFetcher.fetchCount == 1)
        #expect(fixture.timestampValidator.validateCount == 0)
        #expect(fixture.activationIssuer.issueCount == 0)
    }

    @Test func timestampValidationFailureStopsActivation() async throws {
        let fixture = CoordinatorFixture(licenseClass: .trial)
        fixture.timestampValidator.error = AuthenticatorError.secureTimestampRootMismatch
        let sut = fixture.makeHostCoordinator()

        await #expect(throws: AuthenticatorError.secureTimestampRootMismatch) {
            try await sut.activate(fixture.request)
        }

        #expect(fixture.timestampFetcher.fetchCount == 1)
        #expect(fixture.timestampValidator.validateCount == 1)
        #expect(fixture.activationIssuer.issueCount == 0)
    }

    @Test func activationIssuerFailurePropagates() async throws {
        let fixture = CoordinatorFixture(licenseClass: .full)
        fixture.activationIssuer.error = TestFailure.issueFailed
        let sut = fixture.makeHostCoordinator()

        await #expect(throws: TestFailure.issueFailed) {
            try await sut.activate(fixture.request)
        }

        #expect(fixture.activationIssuer.issueCount == 1)
    }

    @Test func perpetualLicenseWithoutExpiryIsAccepted() async throws {
        let fixture = CoordinatorFixture(licenseClass: .full, licenseExpiresAt: .none)
        let sut = fixture.makeHostCoordinator()

        let response = try await sut.activate(fixture.request)

        #expect(response.activation.licenseID == fixture.request.license.licenseID)
        #expect(fixture.activationIssuer.issueCount == 1)
    }
}
