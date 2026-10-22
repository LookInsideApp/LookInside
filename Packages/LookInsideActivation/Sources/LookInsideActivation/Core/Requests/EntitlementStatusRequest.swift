public struct EntitlementStatusRequest: Codable, Sendable, Equatable {
    public let licenseID: String
    public let deviceID: String
    public let forceRefresh: Bool
    public let activationSessionToken: String?

    public init(
        licenseID: String,
        deviceID: String,
        forceRefresh: Bool = false,
        activationSessionToken: String? = nil
    ) {
        self.licenseID = licenseID
        self.deviceID = deviceID
        self.forceRefresh = forceRefresh
        self.activationSessionToken = activationSessionToken
    }
}
