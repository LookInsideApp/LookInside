// MCPBridgeObjectIdentifierList.swift
//
// Parses and normalizes the `objectIdentifiers` array that `details.read`
// accepts off the wire.
//
// This lives apart from MCPBridgeDetailsService for the same reason
// MCPBridgeSearchQuery lives apart from MCPBridgeSearchService: the
// service imports AppKit and the ObjC bridge, so it cannot be compiled into
// the standalone binaries that Scripts/test-mcp-bridge.sh builds, while the
// list handling itself needs nothing but Foundation.
//
// What makes it worth extracting rather than inlining: a repeated identifier
// used to reach `Dictionary(uniqueKeysWithValues:)` further down the route,
// which traps -- taking the entire host app down rather than failing the one
// request. The caller is an LLM-driven MCP client, so a list that repeats an
// identifier is an ordinary thing to receive, not a malformed request, and
// the cost of getting it wrong is far out of proportion to the mistake.

import Foundation

enum MCPBridgeObjectIdentifierList {
    /// Why a wire payload was rejected.
    enum ParseFailure: Error, Equatable {
        /// At least one entry was not a JSON string. Loose typing is fine
        /// for primitives elsewhere, but an identifier that is not a string
        /// cannot address anything, so it is rejected rather than skipped.
        case notAllStrings
        /// The array carried no entries at all.
        case empty
        /// More *distinct* identifiers than the route accepts.
        case tooMany(distinctCount: Int, limit: Int)
    }

    struct Parsed: Equatable {
        /// Distinct identifiers, in the order they were first seen. Order is
        /// preserved because the response lists details in request order and
        /// an agent correlates them positionally.
        let identifiers: [String]

        /// How many entries were dropped because an equal string had already
        /// been seen. Surfaced so the host can log it; the agent is not told,
        /// because repeating an identifier is not an error and the response
        /// it gets back is exactly what it asked for.
        let droppedDuplicateCount: Int
    }

    /// Materializes the wire array into distinct identifiers.
    ///
    /// - Parameters:
    ///   - wireValues: The raw `objectIdentifiers` array.
    ///   - limit: Maximum number of distinct identifiers the route accepts.
    static func parse(
        wireValues: [MCPBridgeJSONValue],
        limit: Int
    ) -> Result<Parsed, ParseFailure> {
        var identifiers: [String] = []
        identifiers.reserveCapacity(wireValues.count)
        var seenIdentifiers: Set<String> = []
        var droppedDuplicateCount = 0

        for entry in wireValues {
            guard case let .string(value) = entry else {
                return .failure(.notAllStrings)
            }
            if seenIdentifiers.insert(value).inserted {
                identifiers.append(value)
            } else {
                droppedDuplicateCount += 1
            }
        }

        guard identifiers.isEmpty == false else {
            return .failure(.empty)
        }

        // The cap is applied after de-duplication because it exists to bound
        // how many objects the host actually fetches from the target app. A
        // repeated identifier costs nothing downstream, so rejecting a list
        // for a length it does not really have would be a false refusal.
        guard identifiers.count <= limit else {
            return .failure(.tooMany(distinctCount: identifiers.count, limit: limit))
        }

        return .success(
            Parsed(identifiers: identifiers, droppedDuplicateCount: droppedDuplicateCount)
        )
    }
}
