struct LicenseSummaryRequestPayload: Encodable {
    let activationSessionToken: String

    private enum CodingKeys: String, CodingKey {
        case activationSessionToken = "activation_session_token"
    }
}
