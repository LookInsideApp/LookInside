// MCPBridgeRecoveryHint.swift
//
// What a bridge error tells the agent to do next.
//
// The agent acts on these sentences as written, so a hint that names a
// tool which cannot help costs it a call and the same error back. Every
// hint here once did: the stale-object errors said "refresh via
// get_hierarchy" and the missing-attribute error said "call
// read_attributes first", yet both tools only read what the host already
// holds. The tools that fetch from the app, `refresh_hierarchy` and
// `read_view_details`, landed after or alongside those messages, which
// were never updated.
//
// The hints name MCP tools (`refresh_hierarchy`, not the bridge route
// `hierarchy.refresh`) because the CLI hands error messages to the agent
// unchanged; that is also why they live here rather than in the generic
// wire schema of MCPBridgeFrame.swift. Foundation-only, so
// `Tests/MCPBridge/MCPBridgeRecoveryHintTests.swift` can compile it
// standalone, the same reason `MCPBridgeSearchQuery` was split out.

import Foundation

enum MCPBridgeRecoveryHint {
    /// For an object the target app no longer has. The host's tree keeps
    /// listing it until the hierarchy is fetched again, so reading that
    /// tree with `get_hierarchy` or `find_views` finds the same stale entry.
    static let objectIsGone = "Call refresh_hierarchy to fetch the current tree, then locate views again with find_views or get_hierarchy; identifiers from before the refresh may no longer resolve."

    /// For an identifier that is not in the host's current tree: it came
    /// from an older tree, or the view appeared after the host last
    /// fetched one.
    static let identifierIsUnknown = "Locate views again with find_views or get_hierarchy; if the app's screen has changed since the host last fetched its tree, call refresh_hierarchy first."

    /// The message for a modification whose attribute is not among the
    /// attributes the host holds for the view. The host fetches attributes
    /// only for the rows its inspector has shown, and `read_attributes`
    /// returns only what is already there.
    static func attributeNotFoundMessage(attributeIdentifier: String, viewDetailsFetched: Bool) -> String {
        if viewDetailsFetched {
            return "Attribute \(attributeIdentifier) is not one of this view's attributes. Call read_attributes to list the ones it has."
        }
        return "Attribute \(attributeIdentifier) cannot be found because the host has not fetched this view's attributes yet. Call read_view_details with this object identifier to fetch them, then retry."
    }
}
