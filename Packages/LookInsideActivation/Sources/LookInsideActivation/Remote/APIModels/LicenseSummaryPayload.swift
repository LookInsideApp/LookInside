struct LicenseSummaryPayload: Decodable {
    let licenseID: String
    let licenseClass: String
    let lifecycleState: String
    let issuedTo: String?
    let issuedAt: String
    let email: String?
    let productID: String
    let servicePeriodEndAt: String?
    let currentCertificateID: String?
    let renewAfter: String?
    let lastVerifiedAt: String
    let notices: [String]
    let deviceWarning: String?
    let canIssueCertificate: Bool
    let blockedReason: String?

    private enum CodingKeys: String, CodingKey {
        case licenseID = "license_id"
        case licenseClass = "license_class"
        case lifecycleState = "lifecycle_state"
        case issuedTo = "issued_to"
        case issuedAt = "issued_at"
        case email
        case productID = "product_id"
        case servicePeriodEndAt = "service_period_end_at"
        case currentCertificateID = "current_certificate_id"
        case renewAfter = "renew_after"
        case lastVerifiedAt = "last_verified_at"
        case notices
        case deviceWarning = "device_warning"
        case canIssueCertificate = "can_issue_certificate"
        case blockedReason = "blocked_reason"
    }
}
