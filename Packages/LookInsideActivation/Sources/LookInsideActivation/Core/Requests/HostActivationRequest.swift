import Foundation

public struct HostActivationRequest: Codable, Sendable, Equatable {
    public let challenge: ClientActivationChallenge
    public let license: LicenseEnvelope

    public init(challenge: ClientActivationChallenge, license: LicenseEnvelope) {
        self.challenge = challenge
        self.license = license
    }

    public var secureTimestampRequest: SecureTimestampRequest {
        SecureTimestampRequest(
            licenseID: license.licenseID,
            challengeNonce: challenge.nonce,
            clientIssuedAt: challenge.issuedAt,
            deviceIdentifier: challenge.device.deviceID,
            requestedFeature: challenge.requestedFeature
        )
    }
}
