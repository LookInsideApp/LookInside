// LKMCPBridgeSearchService.swift
//
// Handles the `hierarchy.find` bridge route: locating views in an
// attached target by class name, label, or memory address.
//
// Entirely cache-resident. Unlike `details.read` / `screenshot.read`,
// this route issues no Peertalk RPC — it walks the flat display-item list
// the host already holds. That makes it the cheapest way for an agent to
// go from "somewhere in this app there is a play button" to an object
// identifier it can hand to `attributes.read` / `invoke.method`, without
// first dumping a few thousand nodes of `hierarchy.read` into its context.
//
// It deliberately does NOT call the host's own
// `-[LKHierarchyDataSource searchWithString:]`. That method drives the
// inspector UI: it flips the data source into its search state, expands
// every ancestor of every hit, clears the user's current selection, and
// republishes the visible row list. Running it for a bridge request would
// reach through the socket and rearrange the window the user is looking
// at. Only the pure per-item predicate is reused in spirit, reimplemented
// over a wider field set in `LKMCPBridgeSearchQuery`.

import AppKit
import Foundation
import LookInsideInspectionCore
import os

@MainActor
public final class LKMCPBridgeSearchService {
    /// Default number of matches returned when the caller doesn't ask.
    /// Sized so a typical response stays well inside an agent's context
    /// budget while still showing enough of a broad query (say, every
    /// `UILabel`) for the agent to judge whether to narrow it.
    private static let defaultMatchLimit = 50

    /// Ceiling on `limit`. A caller that wants more than this is really
    /// asking for the whole tree and should use `hierarchy.read`.
    private static let maximumMatchLimit = 500

    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Search")

    public init() {}

    // MARK: - Entry point

    public func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
        guard request.method == "hierarchy.find" else {
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
        return handleHierarchyFind(
            identifier: request.identifier,
            parameters: request.parameters
        )
    }

    // MARK: - hierarchy.find

    private func handleHierarchyFind(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) -> LKMCPBridgeResponse {
        guard let parameters = parameters,
              case let .string(targetIdentifier)? = parameters["targetIdentifier"],
              case let .string(rawQuery)? = parameters["query"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        // An empty needle matches every node, which would silently turn a
        // search into a full tree dump — the exact outcome this route
        // exists to avoid.
        let trimmedQuery = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "search.emptyQuery",
                    message: "`query` must be a non-empty search string. To list the tree instead of searching it, use hierarchy.read."
                )
            )
        }

        let fields: [LKMCPBridgeSearchQuery.Field]
        if case let .array(rawFields)? = parameters["matchFields"] {
            let names: [String] = rawFields.compactMap { value in
                if case let .string(name) = value {
                    return name
                }
                return nil
            }
            guard names.count == rawFields.count else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "search.invalidMatchField",
                        message: "`matchFields` must be an array of strings. Valid values: \(Self.validFieldList)."
                    )
                )
            }
            guard let resolved = LKMCPBridgeSearchQuery.fields(fromWireNames: names) else {
                let unrecognized = LKMCPBridgeSearchQuery.firstUnrecognizedFieldName(in: names) ?? "?"
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "search.invalidMatchField",
                        message: "`\(unrecognized)` is not a searchable field. Valid values: \(Self.validFieldList)."
                    )
                )
            }
            fields = resolved.isEmpty ? LKMCPBridgeSearchQuery.Field.allCases : resolved
        } else {
            fields = LKMCPBridgeSearchQuery.Field.allCases
        }

        let matchLimit: Int
        switch parameters["limit"] {
        case let .integer(raw)?:
            matchLimit = Int(raw)
        case let .double(raw)?:
            matchLimit = Int(raw)
        case nil:
            matchLimit = Self.defaultMatchLimit
        default:
            return .failure(identifier: identifier, error: .invalidParameters)
        }
        guard matchLimit >= 1, matchLimit <= Self.maximumMatchLimit else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "search.invalidLimit",
                    message: "`limit` must be between 1 and \(Self.maximumMatchLimit); received \(matchLimit)."
                )
            )
        }

        let includeHidden: Bool
        if case let .bool(raw)? = parameters["includeHidden"] {
            includeHidden = raw
        } else {
            includeHidden = true
        }

        let scopeObjectIdentifier: String?
        if case let .string(raw)? = parameters["rootObjectIdentifier"] {
            scopeObjectIdentifier = raw
        } else {
            scopeObjectIdentifier = nil
        }

        guard let session = InspectionSessionLookup.findSession(targetIdentifier: targetIdentifier) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.targetNotFound",
                    message: "No inspection session found for target identifier \(targetIdentifier)."
                )
            )
        }

        guard let allItems = session.rawFlatItems
        else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.notReady",
                    message: "Live session has not loaded a hierarchy yet."
                )
            )
        }

        let searchScope: [LookinDisplayItem]
        if let scopeObjectIdentifier {
            guard let scopeRoot = InspectionSessionLookup.findDisplayItem(
                amongRoots: allItems,
                matchingObjectIdentifier: scopeObjectIdentifier
            ) else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "hierarchy.objectNotFound",
                        message: "Object identifier \(scopeObjectIdentifier) is not present in this target's hierarchy."
                    )
                )
            }
            var subtree: [LookinDisplayItem] = [scopeRoot]
            var cursor = 0
            while cursor < subtree.count {
                subtree.insert(contentsOf: subtree[cursor].subitems ?? [], at: cursor + 1)
                cursor += 1
            }
            searchScope = subtree
        } else {
            searchScope = allItems
        }

        let query = LKMCPBridgeSearchQuery(rawQuery: trimmedQuery, fields: fields)

        // The whole scope is scanned even after `limit` is reached: an
        // agent that only learns "here are 50" cannot tell a complete
        // answer from the tip of an iceberg, and the scan is a cheap
        // in-memory string compare over a list the host already holds.
        var matches: [LKMCPBridgeSearchMatch] = []
        var totalMatchCount = 0
        var searchedNodeCount = 0

        for item in searchScope {
            if includeHidden == false, item.isHidden {
                continue
            }
            searchedNodeCount += 1
            let matchedFields = query.matchedFields(in: makeCandidate(from: item))
            if matchedFields.isEmpty {
                continue
            }
            totalMatchCount += 1
            if matches.count < matchLimit {
                matches.append(makeMatch(from: item, matchedFields: matchedFields))
            }
        }

        let result = LKMCPBridgeSearchResult(
            matches: matches,
            totalMatchCount: totalMatchCount,
            truncated: matches.count < totalMatchCount,
            searchedNodeCount: searchedNodeCount,
            searchedFields: fields.map(\.rawValue)
        )

        do {
            let payload = try encodeAsJSONValue(result)
            return .success(identifier: identifier, result: payload)
        } catch {
            Self.logger.error("hierarchy.find encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    // MARK: - Candidate / match construction

    private func makeCandidate(from item: LookinDisplayItem) -> LKMCPBridgeSearchQuery.Candidate {
        let displayingObject = item.displayingObject()
        let classChain = displayingObject?.classChainList ?? []

        // Every object flavour the item can represent contributes its
        // address, mirroring the host's own search: an address copied out
        // of a debugger may name the layer even when the row represents
        // the view, and vice versa.
        var memoryAddresses: [String] = []
        for candidateObject in [item.viewObject, item.layerObject, item.windowObject, item.kindObject] {
            if let address = candidateObject?.memoryAddress, address.isEmpty == false {
                memoryAddresses.append(address)
            }
        }

        return LKMCPBridgeSearchQuery.Candidate(
            className: classChain.first ?? "",
            classChain: classChain,
            title: InspectionNodeText.title(for: item),
            subtitle: InspectionNodeText.subtitle(for: item),
            memoryAddresses: memoryAddresses
        )
    }

    private func makeMatch(
        from item: LookinDisplayItem,
        matchedFields: [LKMCPBridgeSearchQuery.Field]
    ) -> LKMCPBridgeSearchMatch {
        // Titles and subtitles can carry app-supplied strings through the
        // in-app `lookin_customDebugInfos` hook, so they go through the
        // same redaction gate as `attributes.read`'s textual values.
        let redactSecureContent = LKMCPBridgeSecureContentDetector.isSecure(displayItem: item)
        let title = redactSecureContent ? nil : InspectionNodeText.title(for: item)
        let subtitle = redactSecureContent ? nil : InspectionNodeText.subtitle(for: item)

        var ancestorIdentifiers: [String] = []
        var ancestorTitles: [String] = []
        var nextAncestor = item.super
        while let ancestor = nextAncestor {
            ancestorIdentifiers.append(InspectionSessionLookup.objectIdentifierString(for: ancestor))
            ancestorTitles.append(Self.pathComponentTitle(for: ancestor))
            nextAncestor = ancestor.super
        }
        // `enumerateAncestors` walks upward; the wire order is root first
        // so the list reads like a path.
        ancestorIdentifiers.reverse()
        ancestorTitles.reverse()

        let pathComponents = ancestorTitles + [Self.pathComponentTitle(for: item)]

        return LKMCPBridgeSearchMatch(
            objectIdentifier: InspectionSessionLookup.objectIdentifierString(for: item),
            className: item.displayingObject()?.classChainList?.first ?? "",
            title: title,
            subtitle: subtitle,
            frame: LKMCPBridgeRect(cgRect: InspectionSessionLookup.rootSpaceFrame(for: item)),
            isHidden: item.isHidden,
            alpha: Double(item.alpha),
            depth: ancestorIdentifiers.count,
            ancestorObjectIdentifiers: ancestorIdentifiers,
            pathDescription: pathComponents.joined(separator: " > "),
            matchedFields: matchedFields.map(\.rawValue),
            secureContent: redactSecureContent
        )
    }

    /// Path components use the class name rather than the display title:
    /// the title can be an app-supplied custom string, and a path is for
    /// orientation, not for reading back app content.
    private static func pathComponentTitle(for item: LookinDisplayItem) -> String {
        let className = item.displayingObject()?.classChainList?.first ?? ""
        return className.isEmpty ? "?" : className
    }

    private static let validFieldList: String = LKMCPBridgeSearchQuery.Field.allCases
        .map(\.rawValue)
        .joined(separator: ", ")

    // MARK: - Encoding helper (duplicated from InspectionService)

    private func encodeAsJSONValue(_ value: some Encodable) throws -> LKMCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(LKMCPBridgeJSONValue.self, from: data)
    }
}
