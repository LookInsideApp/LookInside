import Foundation

public struct CertificateChain: Codable, Sendable, Equatable {
    public let rootCertificateID: String
    public let intermediateCertificateID: String
    public let intermediateIssuedAt: Date
    public let intermediateExpiresAt: Date
    public let renewAfter: Date
    public let boundUDID: String?

    public init(
        rootCertificateID: String,
        intermediateCertificateID: String,
        intermediateIssuedAt: Date,
        intermediateExpiresAt: Date,
        renewAfter: Date? = nil,
        boundUDID: String? = nil
    ) {
        self.rootCertificateID = rootCertificateID
        self.intermediateCertificateID = intermediateCertificateID
        self.intermediateIssuedAt = intermediateIssuedAt
        self.intermediateExpiresAt = intermediateExpiresAt
        self.renewAfter =
            renewAfter
                ?? min(intermediateIssuedAt.addingTimeInterval(24 * 60 * 60), intermediateExpiresAt)
        self.boundUDID = boundUDID
    }
}
