import Foundation

/// Coverage for what bridge errors tell the agent to do next.
///
/// An agent follows these hints as written. A hint that sends it to a
/// cache-only read for data only a fetch can supply brings back the same
/// error, and nothing in that response says the advice was wrong. Each
/// test pins which tool one hint has to name.
@main
struct MCPBridgeRecoveryHintTests {
    static func main() {
        testAGoneObjectAsksForAFreshTree()
        testAnUnknownIdentifierAsksForALookUpOrAFreshTree()
        testUnfetchedAttributesAskForReadViewDetails()
        testAMissingAttributeOnAFetchedViewAsksForNoSecondFetch()
        print("MCPBridge recovery hint tests passed")
    }

    // MARK: - The tree

    /// `get_hierarchy` and `find_views` read the host's tree, which still
    /// lists an object the app has released; only a refresh drops it.
    private static func testAGoneObjectAsksForAFreshTree() {
        let hint = MCPBridgeRecoveryHint.objectIsGone
        expect(
            hint.contains("refresh_hierarchy"),
            "an object the app no longer has must send the agent to refresh_hierarchy, got: \(hint)"
        )
    }

    /// An identifier from an older tree is found again by searching the
    /// current one; a view newer than the host's tree needs a refresh first.
    private static func testAnUnknownIdentifierAsksForALookUpOrAFreshTree() {
        let hint = MCPBridgeRecoveryHint.identifierIsUnknown
        expect(
            hint.contains("find_views") && hint.contains("refresh_hierarchy"),
            "an identifier missing from the tree must send the agent to find_views, and to refresh_hierarchy for a changed screen, got: \(hint)"
        )
    }

    // MARK: - Attributes

    private static func testUnfetchedAttributesAskForReadViewDetails() {
        let message = MCPBridgeRecoveryHint.attributeNotFoundMessage(
            attributeIdentifier: "BasicViewClass_BackgroundColor",
            viewDetailsFetched: false
        )
        expect(
            message.contains("read_view_details"),
            "attributes the host has not fetched must send the agent to read_view_details, got: \(message)"
        )
        expect(
            message.contains("read_attributes") == false,
            "read_attributes only returns what the host holds, so it cannot fetch the attributes, got: \(message)"
        )
    }

    /// Fetching a view's attributes again returns the same list, so once
    /// they are in, a missing attribute is one this view does not have.
    private static func testAMissingAttributeOnAFetchedViewAsksForNoSecondFetch() {
        let message = MCPBridgeRecoveryHint.attributeNotFoundMessage(
            attributeIdentifier: "ThisAttrDoesNotExist",
            viewDetailsFetched: true
        )
        expect(
            message.contains("read_view_details") == false,
            "a view whose attributes are in must not send the agent to fetch them again, got: \(message)"
        )
        expect(
            message.contains("ThisAttrDoesNotExist"),
            "the message must name the attribute the view does not have, got: \(message)"
        )
    }

    // MARK: - Helpers

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        Foundation.exit(1)
    }
}
