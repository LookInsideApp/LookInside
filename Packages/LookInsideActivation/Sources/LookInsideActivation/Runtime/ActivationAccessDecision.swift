import Foundation

/// The access decision the 2.3.x Auth helper returned for `license.check_access`
/// and `license.refresh_status`.
///
/// The coding keys and the optional `status_summary` match the helper's
/// payload, so an encoded decision is the same JSON the helper sent.
public struct ActivationAccessDecision: Codable, Equatable, Sendable {
    public enum Decision: String, Codable, Sendable {
        case allow
        case allowWithWarning = "allow_with_warning"
        case block
    }

    public let decision: Decision
    public let title: String
    public let message: String
    public let statusSummary: String?

    public init(decision: Decision, title: String, message: String, statusSummary: String?) {
        self.decision = decision
        self.title = title
        self.message = message
        self.statusSummary = statusSummary
    }

    /// `true` for `.allow` and `.allowWithWarning`.
    public var grantsAccess: Bool {
        decision != .block
    }

    private enum CodingKeys: String, CodingKey {
        case decision
        case title
        case message
        case statusSummary = "status_summary"
    }
}
