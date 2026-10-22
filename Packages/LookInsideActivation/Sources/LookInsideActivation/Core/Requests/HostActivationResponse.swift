public struct HostActivationResponse: Codable, Sendable, Equatable {
    public let activation: SignedActivationEnvelope
    public let path: ActivationPath
    public let secureTimestamp: SecureTimestampToken?

    public init(
        activation: SignedActivationEnvelope,
        path: ActivationPath,
        secureTimestamp: SecureTimestampToken?
    ) {
        self.activation = activation
        self.path = path
        self.secureTimestamp = secureTimestamp
    }
}
