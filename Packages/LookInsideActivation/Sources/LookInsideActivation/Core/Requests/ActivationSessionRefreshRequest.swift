public struct ActivationSessionRefreshRequest: Codable, Sendable, Equatable {
    public let activationSessionToken: String

    public init(activationSessionToken: String) {
        self.activationSessionToken = activationSessionToken
    }
}
