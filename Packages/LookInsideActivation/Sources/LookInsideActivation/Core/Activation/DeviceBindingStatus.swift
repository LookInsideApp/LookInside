public enum DeviceBindingStatus: String, Codable, Sendable, Equatable, CaseIterable {
    case active
    case reviewRequired
    case blocked
}
