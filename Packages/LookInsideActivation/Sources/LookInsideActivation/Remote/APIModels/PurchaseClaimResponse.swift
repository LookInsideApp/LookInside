struct PurchaseClaimResponse: Decodable {
    let license: LicenseSummaryPayload
    let activationSessionToken: String
    let activationSessionExpiresAt: String

    private enum CodingKeys: String, CodingKey {
        case license
        case activationSessionToken = "activation_session_token"
        case activationSessionExpiresAt = "activation_session_expires_at"
    }
}
