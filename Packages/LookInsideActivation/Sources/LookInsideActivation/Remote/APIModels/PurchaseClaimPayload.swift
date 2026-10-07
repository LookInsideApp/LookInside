struct PurchaseClaimPayload: Encodable {
    let licenseKey: String
    let email: String
    let deviceIdentifier: String
    let hardwareModel: String
    let appBundleID: String
    let requestNonce: String

    init(licenseKey: String, email: String, device: DeviceFingerprint, requestNonce: String) {
        self.licenseKey = licenseKey
        self.email = email
        deviceIdentifier = device.deviceID
        hardwareModel = device.hardwareModel
        appBundleID = device.appBundleID
        self.requestNonce = requestNonce
    }

    private enum CodingKeys: String, CodingKey {
        case licenseKey = "license_key"
        case email
        case deviceIdentifier = "device_identifier"
        case hardwareModel = "hardware_model"
        case appBundleID = "app_bundle_id"
        case requestNonce = "request_nonce"
    }
}
