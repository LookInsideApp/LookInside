struct IntermediateCertificateIssuePayload: Encodable {
    let activationSessionToken: String
    let deviceIdentifier: String
    let certificateSigningRequestPEM: String
    let requestNonce: String

    private enum CodingKeys: String, CodingKey {
        case activationSessionToken = "activation_session_token"
        case deviceIdentifier = "device_identifier"
        case certificateSigningRequestPEM = "csr_pem"
        case requestNonce = "request_nonce"
    }
}
