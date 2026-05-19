import Foundation

/// Public surface of LookinMCPCore — a headless, Swift wrapper over LookInside's
/// existing inspection plumbing for use by external clients (the MCP server, future
/// CLI tools, tests). Live target-app inspection talks to `LookinServer` instances
/// running in Debug builds; offline analysis works against `.lookin` snapshot files.
///
/// Threading: everything in this module is `Sendable`-friendly. The `LiveLookinClient`
/// dispatches network I/O on a private serial queue; results are delivered on the queue
/// the call originated from.
public enum LookinMCP {
    /// Marketing version printed by `lookinside-mcp --version` and surfaced in
    /// `health_check`. Bump alongside any tool-schema-affecting change.
    public static let version = "0.1.0"
}
