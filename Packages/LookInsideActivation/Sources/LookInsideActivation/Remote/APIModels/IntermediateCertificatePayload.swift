struct IntermediateCertificatePayload: Decodable {
    let certificateID: String
    let status: String
    let issuedAt: String
    let expiresAt: String
    let renewAfter: String
    let issuanceReason: String
    let renewalBlockedReason: String?
    let rootCertificateID: String
    let certificatePEM: String
    let publicKeyPEM: String
    let fullChainPEM: String

    private enum CodingKeys: String, CodingKey {
        case certificateID = "certificate_id"
        case status
        case issuedAt = "issued_at"
        case expiresAt = "expires_at"
        case renewAfter = "renew_after"
        case issuanceReason = "issuance_reason"
        case renewalBlockedReason = "renewal_blocked_reason"
        case rootCertificateID = "root_certificate_id"
        case certificatePEM = "certificate_pem"
        case publicKeyPEM = "public_key_pem"
        case fullChainPEM = "full_chain_pem"
    }
}
