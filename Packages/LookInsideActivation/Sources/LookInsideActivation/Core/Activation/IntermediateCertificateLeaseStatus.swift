public enum IntermediateCertificateLeaseStatus: String, Codable, Sendable, Equatable, CaseIterable {
    case active
    case expired
    case renewalBlocked
    case superseded
}
