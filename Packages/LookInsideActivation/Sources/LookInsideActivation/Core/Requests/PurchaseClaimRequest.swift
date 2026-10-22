public struct PurchaseClaimRequest: Codable, Sendable, Equatable {
    public let licenseKey: String
    public let email: String
    public let device: DeviceFingerprint

    public init(licenseKey: String, email: String, device: DeviceFingerprint) {
        self.licenseKey = licenseKey
        self.email = email
        self.device = device
    }
}
