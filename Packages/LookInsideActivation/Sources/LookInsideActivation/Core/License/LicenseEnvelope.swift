import Foundation

public struct LicenseEnvelope: Codable, Sendable, Equatable {
    public let licenseID: String
    public let audience: LicenseAudience
    public let licenseClass: LicenseClass
    public let lifecycleState: LicenseLifecycleState
    public let issuedTo: String?
    public let issuedAt: Date
    public let expiresAt: Date?
    public let serviceEndsAt: Date?
    public let nextCertificateRenewalAt: Date?
    public let deviceWarning: String?
    public let certificateChain: CertificateChain

    public init(
        licenseID: String,
        audience: LicenseAudience = .personal,
        licenseClass: LicenseClass,
        lifecycleState: LicenseLifecycleState = .active,
        issuedTo: String?,
        issuedAt: Date,
        expiresAt: Date?,
        serviceEndsAt: Date? = nil,
        nextCertificateRenewalAt: Date? = nil,
        deviceWarning: String? = nil,
        certificateChain: CertificateChain
    ) {
        self.licenseID = licenseID
        self.audience = audience
        self.licenseClass = licenseClass
        self.lifecycleState = lifecycleState
        self.issuedTo = issuedTo
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.serviceEndsAt = serviceEndsAt
        self.nextCertificateRenewalAt = nextCertificateRenewalAt
        self.deviceWarning = deviceWarning
        self.certificateChain = certificateChain
    }

    public var trustedRootCertificateID: String {
        certificateChain.rootCertificateID
    }
}
