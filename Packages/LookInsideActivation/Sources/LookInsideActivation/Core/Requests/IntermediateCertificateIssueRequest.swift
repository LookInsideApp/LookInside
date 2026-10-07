public struct IntermediateCertificateIssueRequest: Codable, Sendable, Equatable {
    public let activationSessionToken: String
    public let deviceIdentifier: String
    public let certificateSigningRequestPEM: String

    public init(
        activationSessionToken: String,
        deviceIdentifier: String,
        certificateSigningRequestPEM: String
    ) {
        self.activationSessionToken = activationSessionToken
        self.deviceIdentifier = deviceIdentifier
        self.certificateSigningRequestPEM = certificateSigningRequestPEM
    }
}
