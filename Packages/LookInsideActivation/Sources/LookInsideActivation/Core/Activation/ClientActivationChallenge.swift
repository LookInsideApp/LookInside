import Foundation

public struct ClientActivationChallenge: Codable, Sendable, Equatable {
    public let nonce: String
    public let issuedAt: Date
    public let requestedFeature: String
    public let frameworkVersion: String
    public let device: DeviceFingerprint

    public init(
        nonce: String,
        issuedAt: Date,
        requestedFeature: String,
        frameworkVersion: String,
        device: DeviceFingerprint
    ) {
        self.nonce = nonce
        self.issuedAt = issuedAt
        self.requestedFeature = requestedFeature
        self.frameworkVersion = frameworkVersion
        self.device = device
    }
}
