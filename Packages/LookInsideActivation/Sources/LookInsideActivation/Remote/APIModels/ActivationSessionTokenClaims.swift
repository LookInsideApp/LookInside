struct ActivationSessionTokenClaims: Decodable {
    let sessionID: String
    let licenseID: String
    let licenseClass: String
    let orderID: String?
    let licenseKey: String?
    let creemCustomerID: String?
    let creemLicenseID: String?
    let email: String?
    let deviceIdentifier: String
    let servicePeriodEndAt: String?
    let issuedAt: String
    let expiresAt: String

    private enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case licenseID = "license_id"
        case licenseClass = "license_class"
        case orderID = "order_id"
        case licenseKey = "license_key"
        case creemCustomerID = "creem_customer_id"
        case creemLicenseID = "creem_license_id"
        case email
        case deviceIdentifier = "device_identifier"
        case servicePeriodEndAt = "service_period_end_at"
        case issuedAt = "issued_at"
        case expiresAt = "expires_at"
    }
}
