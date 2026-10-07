public enum LicenseLifecycleState: String, Codable, Sendable, Equatable, CaseIterable {
    case active
    case canceled
    case refunded
    case expired
    case pendingReview

    public var blocksNewCertificateIssuance: Bool {
        switch self {
        case .active, .pendingReview:
            return false
        case .canceled, .refunded, .expired:
            return true
        }
    }
}
