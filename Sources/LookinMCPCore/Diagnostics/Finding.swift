import Foundation

/// Output shape shared by every diagnostic. Keeping one type means the AI can learn
/// the format once and stay oriented across `diagnose_layout`, `diagnose_accessibility`,
/// and any future linter we bolt on.
public struct Finding: Codable {
    public enum Severity: String, Codable { case info, warning, error }
    public enum Category: String, Codable { case layout, accessibility, performance, other }

    public let oid: UInt?
    public let severity: Severity
    public let category: Category
    /// Stable machine-readable id. New checks pick a new id; renaming an existing
    /// check is a breaking change for downstream automation.
    public let code: String
    public let message: String
    public let suggestion: String?
    public let path: String?
}
