import Foundation

public struct SecureTimestampRequest: Codable, Sendable, Equatable {
    public let licenseID: String
    public let challengeNonce: String
    public let clientIssuedAt: Date
    public let deviceIdentifier: String
    public let requestedFeature: String

    public init(
        licenseID: String,
        challengeNonce: String,
        clientIssuedAt: Date,
        deviceIdentifier: String,
        requestedFeature: String
    ) {
        self.licenseID = licenseID
        self.challengeNonce = challengeNonce
        self.clientIssuedAt = clientIssuedAt
        self.deviceIdentifier = deviceIdentifier
        self.requestedFeature = requestedFeature
    }
}
