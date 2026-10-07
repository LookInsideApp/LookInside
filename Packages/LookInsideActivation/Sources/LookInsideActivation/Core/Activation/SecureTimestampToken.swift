import Foundation

public struct SecureTimestampToken: Codable, Sendable, Equatable {
    public let challengeNonce: String
    public let signedAt: Date
    public let rootCertificateID: String
    public let signature: Data

    public init(
        challengeNonce: String,
        signedAt: Date,
        rootCertificateID: String,
        signature: Data = Data()
    ) {
        self.challengeNonce = challengeNonce
        self.signedAt = signedAt
        self.rootCertificateID = rootCertificateID
        self.signature = signature
    }

    public var hasSignature: Bool {
        !signature.isEmpty
    }
}
