public struct DeviceFingerprint: Codable, Sendable, Equatable {
    public let deviceID: String
    public let hardwareModel: String
    public let operatingSystemVersion: String
    public let appBundleID: String

    public init(
        deviceID: String,
        hardwareModel: String,
        operatingSystemVersion: String,
        appBundleID: String
    ) {
        self.deviceID = deviceID
        self.hardwareModel = hardwareModel
        self.operatingSystemVersion = operatingSystemVersion
        self.appBundleID = appBundleID
    }
}
