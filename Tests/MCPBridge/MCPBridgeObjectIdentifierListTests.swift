import Foundation

/// Coverage for the `details.read` object-identifier list.
///
/// The failure this guards against is not a wrong answer but a dead host:
/// a repeated identifier used to resolve twice to the same display item and
/// then reach `Dictionary(uniqueKeysWithValues:)`, which traps. The caller is
/// an LLM-driven MCP client, so a list carrying the same identifier twice is
/// routine input. Every de-duplication test here stands in for that crash.
@main
struct MCPBridgeObjectIdentifierListTests {
    static func main() {
        testRepeatedIdentifierIsCollapsed()
        testEveryEntryIdenticalCollapsesToOne()
        testFirstSeenOrderIsPreserved()
        testDistinctIdentifiersAreAllKept()
        testDroppedDuplicateCountIsReported()
        testNonStringEntryIsRejected()
        testEmptyArrayIsRejected()
        testCapAppliesToDistinctCountNotRawCount()
        testTooManyDistinctIdentifiersIsRejected()
        print("MCPBridge object identifier list tests passed")
    }

    // MARK: - De-duplication (the crash this file exists for)

    /// The direct reproduction: the exact payload shape that used to take
    /// down LookInside.app.
    private static func testRepeatedIdentifierIsCollapsed() {
        let parsed = expectSuccess(
            parse(["0x600000abc123", "0x600000abc123", "0x600000def456"])
        )
        expect(
            parsed.identifiers == ["0x600000abc123", "0x600000def456"],
            "a repeated identifier must appear exactly once, got \(parsed.identifiers)"
        )
    }

    private static func testEveryEntryIdenticalCollapsesToOne() {
        let parsed = expectSuccess(
            parse(["0xabc", "0xabc", "0xabc", "0xabc"])
        )
        expect(
            parsed.identifiers == ["0xabc"],
            "four copies of one identifier must collapse to one, got \(parsed.identifiers)"
        )
    }

    /// Responses list details in request order and agents correlate them
    /// positionally, so de-duplication must not reshuffle the survivors.
    private static func testFirstSeenOrderIsPreserved() {
        let parsed = expectSuccess(
            parse(["0xcc", "0xaa", "0xcc", "0xbb", "0xaa"])
        )
        expect(
            parsed.identifiers == ["0xcc", "0xaa", "0xbb"],
            "survivors must stay in first-seen order, got \(parsed.identifiers)"
        )
    }

    private static func testDistinctIdentifiersAreAllKept() {
        let parsed = expectSuccess(parse(["0xaa", "0xbb", "0xcc"]))
        expect(
            parsed.identifiers == ["0xaa", "0xbb", "0xcc"],
            "a list with no repeats must pass through unchanged, got \(parsed.identifiers)"
        )
        expect(
            parsed.droppedDuplicateCount == 0,
            "nothing should be reported dropped, got \(parsed.droppedDuplicateCount)"
        )
    }

    private static func testDroppedDuplicateCountIsReported() {
        let parsed = expectSuccess(parse(["0xaa", "0xaa", "0xaa", "0xbb"]))
        expect(
            parsed.droppedDuplicateCount == 2,
            "two entries were duplicates, got \(parsed.droppedDuplicateCount)"
        )
    }

    // MARK: - Rejection

    private static func testNonStringEntryIsRejected() {
        let result = MCPBridgeObjectIdentifierList.parse(
            wireValues: [.string("0xaa"), .integer(7)],
            limit: 100
        )
        expect(
            failure(of: result) == .notAllStrings,
            "an identifier that is not a string cannot address anything and must be rejected"
        )
    }

    private static func testEmptyArrayIsRejected() {
        let result = MCPBridgeObjectIdentifierList.parse(wireValues: [], limit: 100)
        expect(
            failure(of: result) == .empty,
            "an empty identifier array must be rejected"
        )
    }

    // MARK: - Cap

    /// The cap bounds how many objects the host fetches from the target app.
    /// Duplicates cost nothing downstream, so a list that only *looks* too
    /// long must not be refused.
    private static func testCapAppliesToDistinctCountNotRawCount() {
        let wireValues = (0 ..< 6).map { _ in MCPBridgeJSONValue.string("0xaa") }
            + [MCPBridgeJSONValue.string("0xbb")]
        let result = MCPBridgeObjectIdentifierList.parse(wireValues: wireValues, limit: 3)
        let parsed = expectSuccess(result)
        expect(
            parsed.identifiers == ["0xaa", "0xbb"],
            "seven raw entries holding two distinct ids must pass a cap of three, got \(parsed.identifiers)"
        )
    }

    private static func testTooManyDistinctIdentifiersIsRejected() {
        let wireValues = (0 ..< 5).map { MCPBridgeJSONValue.string("0x\($0)") }
        let result = MCPBridgeObjectIdentifierList.parse(wireValues: wireValues, limit: 3)
        expect(
            failure(of: result) == .tooMany(distinctCount: 5, limit: 3),
            "five distinct identifiers must be rejected against a cap of three"
        )
    }

    // MARK: - Helpers

    private static func parse(
        _ identifiers: [String]
    ) -> Result<MCPBridgeObjectIdentifierList.Parsed, MCPBridgeObjectIdentifierList.ParseFailure> {
        return MCPBridgeObjectIdentifierList.parse(
            wireValues: identifiers.map(MCPBridgeJSONValue.string),
            limit: 100
        )
    }

    private static func expectSuccess(
        _ result: Result<MCPBridgeObjectIdentifierList.Parsed, MCPBridgeObjectIdentifierList.ParseFailure>
    ) -> MCPBridgeObjectIdentifierList.Parsed {
        switch result {
        case let .success(parsed):
            return parsed
        case let .failure(parseFailure):
            fail("expected success, got failure \(parseFailure)")
        }
    }

    private static func failure(
        of result: Result<MCPBridgeObjectIdentifierList.Parsed, MCPBridgeObjectIdentifierList.ParseFailure>
    ) -> MCPBridgeObjectIdentifierList.ParseFailure? {
        switch result {
        case .success:
            return nil
        case let .failure(parseFailure):
            return parseFailure
        }
    }

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
