public enum IntermediateCertificateIssuanceReason: String, Codable, Sendable, Equatable, CaseIterable {
    case initialActivation
    case renewal
    case replacement
}
