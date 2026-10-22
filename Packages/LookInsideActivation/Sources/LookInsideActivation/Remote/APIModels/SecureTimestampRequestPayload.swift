import Foundation

struct SecureTimestampRequestPayload: Encodable {
    let licenseID: String
    let challengeNonce: String
    let clientIssuedAt: String
    let deviceIdentifier: String
    let requestedFeature: String

    init(
        licenseID: String,
        challengeNonce: String,
        clientIssuedAt: Date,
        deviceIdentifier: String,
        requestedFeature: String
    ) {
        self.licenseID = licenseID
        self.challengeNonce = challengeNonce
        self.clientIssuedAt = ISO8601DateFormatter.string(
            from: clientIssuedAt,
            timeZone: .gmt,
            formatOptions: [.withInternetDateTime, .withFractionalSeconds]
        )
        self.deviceIdentifier = deviceIdentifier
        self.requestedFeature = requestedFeature
    }

    private enum CodingKeys: String, CodingKey {
        case licenseID = "license_id"
        case challengeNonce = "challenge_nonce"
        case clientIssuedAt = "client_issued_at"
        case deviceIdentifier = "device_identifier"
        case requestedFeature = "requested_feature"
    }
}
