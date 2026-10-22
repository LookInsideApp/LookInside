struct SecureTimestampPayload: Decodable {
    let challengeNonce: String
    let signedAt: String
    let rootCertificateID: String
    let signature: String

    private enum CodingKeys: String, CodingKey {
        case challengeNonce = "challenge_nonce"
        case signedAt = "signed_at"
        case rootCertificateID = "root_certificate_id"
        case signature
    }
}
