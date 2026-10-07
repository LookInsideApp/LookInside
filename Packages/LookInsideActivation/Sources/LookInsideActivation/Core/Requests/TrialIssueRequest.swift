public struct TrialIssueRequest: Codable, Sendable, Equatable {
    public let device: DeviceFingerprint

    public init(device: DeviceFingerprint) {
        self.device = device
    }
}
