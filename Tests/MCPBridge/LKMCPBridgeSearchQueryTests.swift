import Foundation

/// Coverage for the `hierarchy.find` matching core.
///
/// Search is the one bridge route whose failure mode is silent: a field
/// that never matches, or a field name that is quietly dropped, both
/// present to the caller as "nothing in this app matched" — a statement
/// about the inspected app rather than about the request. Every test here
/// exists to make one of those silent outcomes loud.
@main
struct LKMCPBridgeSearchQueryTests {
    static func main() {
        testMatchesLeafClassName()
        testClassNameDoesNotMatchAncestorClass()
        testClassChainMatchesAncestorClass()
        testMatchingIsCaseInsensitive()
        testMatchesTitleAndSubtitle()
        testMatchesPartialMemoryAddress()
        testNarrowingFieldsExcludesOtherHits()
        testMatchedFieldsReportEveryHitInCanonicalOrder()
        testEmptyFieldListMeansEveryField()
        testDuplicateFieldsAreCollapsed()
        testNoMatchReturnsEmpty()
        testAbsentStringsNeverMatch()
        testUnknownWireFieldNameIsRejected()
        testWireFieldNamesResolveInCanonicalOrder()
        print("MCPBridge search query tests passed")
    }

    // MARK: - Field semantics

    private static func testMatchesLeafClassName() {
        let query = LKMCPBridgeSearchQuery(rawQuery: "UIButton")
        expect(
            query.matches(button()),
            "a query naming the leaf class must match that node"
        )
    }

    /// `className` is the narrow field: it is what lets an agent ask for
    /// `UIView` without getting back every view in the app.
    private static func testClassNameDoesNotMatchAncestorClass() {
        let query = LKMCPBridgeSearchQuery(rawQuery: "UIControl", fields: [.className])
        expect(
            query.matchedFields(in: button()).isEmpty,
            "className must consider only the leaf class, not the rest of the chain"
        )
    }

    private static func testClassChainMatchesAncestorClass() {
        let query = LKMCPBridgeSearchQuery(rawQuery: "UIControl", fields: [.classChain])
        expect(
            query.matchedFields(in: button()) == [.classChain],
            "classChain must match any class in the chain so subclasses are findable by their base class"
        )
    }

    private static func testMatchingIsCaseInsensitive() {
        let query = LKMCPBridgeSearchQuery(rawQuery: "uibutton", fields: [.className])
        expect(
            query.matches(button()),
            "an agent should not have to reproduce the exact casing of a class name"
        )
    }

    private static func testMatchesTitleAndSubtitle() {
        let titleQuery = LKMCPBridgeSearchQuery(rawQuery: "Play", fields: [.title])
        expect(titleQuery.matches(button()), "title must be searchable")

        let subtitleQuery = LKMCPBridgeSearchQuery(rawQuery: "PlayerViewController", fields: [.subtitle])
        expect(subtitleQuery.matches(button()), "subtitle must be searchable")
    }

    /// Addresses arrive from a debugger or a crash log, where the caller
    /// often has only the tail of one.
    private static func testMatchesPartialMemoryAddress() {
        let query = LKMCPBridgeSearchQuery(rawQuery: "abc123", fields: [.memoryAddress])
        expect(
            query.matches(button()),
            "a substring of a memory address must match, not just the whole address"
        )
    }

    // MARK: - Field selection

    private static func testNarrowingFieldsExcludesOtherHits() {
        // "Play" appears in the title and in the subtitle, nowhere else.
        let query = LKMCPBridgeSearchQuery(rawQuery: "Play", fields: [.className, .classChain])
        expect(
            query.matchedFields(in: button()).isEmpty,
            "restricting matchFields must actually exclude the fields left out"
        )
    }

    private static func testMatchedFieldsReportEveryHitInCanonicalOrder() {
        // "UIButton" is the leaf class, is in the chain, and is the title.
        let query = LKMCPBridgeSearchQuery(rawQuery: "UIButton")
        let matched = query.matchedFields(in: plainButton())
        expect(
            matched == [.className, .classChain, .title],
            "matchedFields must list every hit in canonical order; got \(matched)"
        )
    }

    private static func testEmptyFieldListMeansEveryField() {
        let query = LKMCPBridgeSearchQuery(rawQuery: "Play", fields: [])
        expect(
            query.fields == LKMCPBridgeSearchQuery.Field.allCases,
            "an empty field list must widen to every field rather than matching nothing"
        )
    }

    private static func testDuplicateFieldsAreCollapsed() {
        let query = LKMCPBridgeSearchQuery(rawQuery: "UIButton", fields: [.title, .className, .title])
        expect(
            query.fields == [.className, .title],
            "duplicates must collapse and order must be canonical; got \(query.fields)"
        )
        expect(
            query.matchedFields(in: plainButton()) == [.className, .title],
            "a repeated field must not be reported twice in matchedFields"
        )
    }

    // MARK: - Negative paths

    private static func testNoMatchReturnsEmpty() {
        let query = LKMCPBridgeSearchQuery(rawQuery: "NSTableView")
        expect(
            query.matchedFields(in: button()).isEmpty,
            "a query matching nothing must report no matched fields"
        )
    }

    /// Nodes configured through the in-app custom-debug-info hook can be
    /// missing a title, a subtitle, or any backing object at all.
    private static func testAbsentStringsNeverMatch() {
        let bare = LKMCPBridgeSearchQuery.Candidate(
            className: "",
            classChain: [],
            title: nil,
            subtitle: nil,
            memoryAddresses: []
        )
        let query = LKMCPBridgeSearchQuery(rawQuery: "anything")
        expect(
            query.matchedFields(in: bare).isEmpty,
            "a candidate with no strings at all must not match"
        )

        // An empty query would otherwise match every empty string via
        // `contains("")`, turning a search into a full tree dump.
        let emptyQuery = LKMCPBridgeSearchQuery(rawQuery: "")
        expect(
            emptyQuery.matchedFields(in: bare).isEmpty,
            "empty strings must not be considered matchable content"
        )
    }

    // MARK: - Wire field names

    private static func testUnknownWireFieldNameIsRejected() {
        expect(
            LKMCPBridgeSearchQuery.fields(fromWireNames: ["className", "classname"]) == nil,
            "a misspelled field must be rejected, not silently dropped into a no-results answer"
        )
        expect(
            LKMCPBridgeSearchQuery.firstUnrecognizedFieldName(in: ["className", "classname"]) == "classname",
            "the rejected name must be reported so the error message can quote it"
        )
        expect(
            LKMCPBridgeSearchQuery.firstUnrecognizedFieldName(in: ["className", "title"]) == nil,
            "a fully valid list must report no unrecognized name"
        )
    }

    private static func testWireFieldNamesResolveInCanonicalOrder() {
        let resolved = LKMCPBridgeSearchQuery.fields(fromWireNames: ["subtitle", "className"])
        expect(
            resolved == [.className, .subtitle],
            "wire names must resolve into canonical order; got \(String(describing: resolved))"
        )
    }

    // MARK: - Fixtures

    /// A button whose title and subtitle carry app-supplied text, so
    /// field-narrowing tests have something that matches on exactly one
    /// field at a time.
    private static func button() -> LKMCPBridgeSearchQuery.Candidate {
        return LKMCPBridgeSearchQuery.Candidate(
            className: "UIButton",
            classChain: ["UIButton", "UIControl", "UIView", "UIResponder", "NSObject"],
            title: "Play",
            subtitle: "PlayerViewController.view",
            memoryAddresses: ["0x600000abc123", "0x600000def456"]
        )
    }

    /// The default shape: title is just the demangled class name, which
    /// is what the host inspector shows for a view with no custom debug
    /// info.
    private static func plainButton() -> LKMCPBridgeSearchQuery.Candidate {
        return LKMCPBridgeSearchQuery.Candidate(
            className: "UIButton",
            classChain: ["UIButton", "UIControl", "UIView"],
            title: "UIButton",
            subtitle: "SettingsViewController.view",
            memoryAddresses: ["0x600000abc123"]
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
