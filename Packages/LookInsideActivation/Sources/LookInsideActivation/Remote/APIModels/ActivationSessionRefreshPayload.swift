struct ActivationSessionRefreshPayload: Encodable {
    let activationSessionToken: String
    let requestNonce: String

    private enum CodingKeys: String, CodingKey {
        case activationSessionToken = "activation_session_token"
        case requestNonce = "request_nonce"
    }
}
