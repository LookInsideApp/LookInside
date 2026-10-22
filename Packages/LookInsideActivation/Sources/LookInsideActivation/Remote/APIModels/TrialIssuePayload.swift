struct TrialIssuePayload: Encodable {
    let deviceIdentifier: String
    let hardwareModel: String
    let appBundleID: String
    let requestNonce: String

    init(device: DeviceFingerprint, requestNonce: String) {
        deviceIdentifier = device.deviceID
        hardwareModel = device.hardwareModel
        appBundleID = device.appBundleID
        self.requestNonce = requestNonce
    }

    private enum CodingKeys: String, CodingKey {
        case deviceIdentifier = "device_identifier"
        case hardwareModel = "hardware_model"
        case appBundleID = "app_bundle_id"
        case requestNonce = "request_nonce"
    }
}
