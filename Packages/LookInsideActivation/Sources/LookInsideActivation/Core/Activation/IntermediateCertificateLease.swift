import Foundation

public struct IntermediateCertificateLease: Codable, Sendable, Equatable {
    public let certificateID: String
    public let licenseID: String
    public let udid: String
    public let issuedAt: Date
    public let expiresAt: Date
    public let renewAfter: Date
    public let issuanceReason: IntermediateCertificateIssuanceReason
    public let renewalBlockedReason: String?
    public let certificatePEM: String
    public let publicKeyPEM: String
    public let fullChainPEM: String
    public let status: IntermediateCertificateLeaseStatus

    public init(
        certificateID: String,
        licenseID: String,
        udid: String,
        issuedAt: Date,
        expiresAt: Date,
        renewAfter: Date? = nil,
        issuanceReason: IntermediateCertificateIssuanceReason,
        renewalBlockedReason: String? = nil,
        certificatePEM: String,
        publicKeyPEM: String,
        fullChainPEM: String,
        status: IntermediateCertificateLeaseStatus = .active
    ) {
        self.certificateID = certificateID
        self.licenseID = licenseID
        self.udid = udid
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.renewAfter =
            renewAfter
                ?? min(issuedAt.addingTimeInterval(24 * 60 * 60), expiresAt)
        self.issuanceReason = issuanceReason
        self.renewalBlockedReason = renewalBlockedReason
        self.certificatePEM = certificatePEM
        self.publicKeyPEM = publicKeyPEM
        self.fullChainPEM = fullChainPEM
        self.status = status
    }

    public var isInsideRenewalWindow: Bool {
        renewAfter <= expiresAt
    }
}
