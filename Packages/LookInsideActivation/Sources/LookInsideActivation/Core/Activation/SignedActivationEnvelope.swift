import Foundation

public struct SignedActivationEnvelope: Codable, Sendable, Equatable {
    public let activationID: String
    public let challengeNonce: String
    public let licenseID: String
    public let issuedAt: Date
    public let expiresAt: Date
    public let intermediateCertificateID: String
    public let boundUDID: String
    public let artifacts: [ActivationArtifact]
    public let signature: Data

    public init(
        activationID: String,
        challengeNonce: String,
        licenseID: String,
        issuedAt: Date,
        expiresAt: Date,
        intermediateCertificateID: String,
        boundUDID: String = "",
        artifacts: [ActivationArtifact],
        signature: Data = Data()
    ) {
        self.activationID = activationID
        self.challengeNonce = challengeNonce
        self.licenseID = licenseID
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.intermediateCertificateID = intermediateCertificateID
        self.boundUDID = boundUDID
        self.artifacts = artifacts
        self.signature = signature
    }

    public var hasSignature: Bool {
        !signature.isEmpty
    }
}
