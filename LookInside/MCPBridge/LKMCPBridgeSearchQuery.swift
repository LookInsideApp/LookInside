// LKMCPBridgeSearchQuery.swift
//
// Pure matching core behind the `hierarchy.find` bridge route.
//
// Deliberately kept free of AppKit and of the Objective-C hierarchy model:
// which fields a query looks at, and how a hit is reported back, is the
// part of search whose correctness is invisible at the call site (a field
// silently never matching looks exactly like "nothing in the tree matched").
// Splitting it out lets `Tests/MCPBridge/LKMCPBridgeSearchQueryTests.swift`
// compile it standalone under the host repo's `swiftc`-single-binary test
// pattern, the same reason `LKMCPBridgeListenSocket` was split out.
//
// Matching is case-insensitive substring containment. That is intentionally
// dumber than the host inspector's own search: an agent issues a query it
// composed from a class name it already read out of `hierarchy.read`, so
// fuzzy scoring would trade predictability for a relevance ranking nobody
// asked for. Callers that want precision narrow `fields` instead.

import Foundation

struct LKMCPBridgeSearchQuery: Sendable {
    // MARK: - Fields

    /// The searchable projections of a hierarchy node. Wire names are the
    /// raw values; `hierarchy.find` rejects anything outside this set
    /// rather than silently ignoring a misspelled field.
    enum Field: String, Sendable, Codable, CaseIterable {
        /// Leaf class only — the head of the class chain. Use this to
        /// avoid matching every `UIView` subclass on a query of "UIView".
        case className

        /// Any entry in the class chain, so a query of "UIControl"
        /// also finds `UIButton` instances.
        case classChain

        /// The row label the host inspector shows, usually the demangled
        /// class name but overridable by the in-app `lookin_customDebugInfos`
        /// hook.
        case title

        /// The host inspector's secondary label: owning view controller,
        /// ivar trace, or a custom subtitle.
        case subtitle

        /// Hex memory address of the underlying view / layer / window
        /// object, so an address copied out of a crash log or the Xcode
        /// debugger can be located in the tree.
        case memoryAddress
    }

    /// One hierarchy node reduced to the strings this type knows how to
    /// match. Built by the service layer so this type never touches
    /// `DisplayItem`.
    struct Candidate: Sendable {
        let className: String
        let classChain: [String]
        let title: String?
        let subtitle: String?
        let memoryAddresses: [String]

        init(
            className: String,
            classChain: [String],
            title: String?,
            subtitle: String?,
            memoryAddresses: [String]
        ) {
            self.className = className
            self.classChain = classChain
            self.title = title
            self.subtitle = subtitle
            self.memoryAddresses = memoryAddresses
        }
    }

    // MARK: - State

    /// The query exactly as the caller supplied it, kept for echoing back
    /// in the response.
    let rawQuery: String

    /// Fields to consider, in canonical `Field.allCases` order regardless
    /// of the order the caller listed them, so `matchedFields` is stable
    /// across requests that ask for the same set.
    let fields: [Field]

    private let normalizedQuery: String

    // MARK: - Construction

    /// - Parameters:
    ///   - rawQuery: caller-supplied needle. Callers are responsible for
    ///     rejecting the empty string; an empty query here matches
    ///     everything, which is a legitimate thing for a test to assert
    ///     but never a useful thing for an agent to ask for.
    ///   - fields: which projections to search. Duplicates are collapsed;
    ///     an empty array means every field.
    init(rawQuery: String, fields: [Field] = Field.allCases) {
        self.rawQuery = rawQuery
        normalizedQuery = rawQuery.lowercased()
        let requested = Set(fields.isEmpty ? Field.allCases : fields)
        self.fields = Field.allCases.filter { requested.contains($0) }
    }

    /// Translates wire field names into `Field` values, preserving the
    /// canonical order. Returns `nil` for the first unrecognized name so
    /// the caller can name it in the error message — silently dropping it
    /// would turn a typo into "no results found", which reads as a fact
    /// about the app rather than as a mistake in the request.
    static func fields(fromWireNames names: [String]) -> [Field]? {
        var resolved: Set<Field> = []
        for name in names {
            guard let field = Field(rawValue: name) else { return nil }
            resolved.insert(field)
        }
        return Field.allCases.filter { resolved.contains($0) }
    }

    /// The first wire name in `names` that is not a valid field, for use
    /// in the caller's error message.
    static func firstUnrecognizedFieldName(in names: [String]) -> String? {
        return names.first { Field(rawValue: $0) == nil }
    }

    // MARK: - Matching

    /// Every field of `candidate` that contains the query, in canonical
    /// order. Empty means no match.
    ///
    /// The list — rather than a bare `Bool` — is what lets the response
    /// tell an agent *why* a node came back. A hit on `memoryAddress` and
    /// a hit on `title` warrant very different follow-up actions, and
    /// without the reason the agent has to re-derive it by inspecting
    /// each result.
    func matchedFields(in candidate: Candidate) -> [Field] {
        return fields.filter { field in
            switch field {
            case .className:
                return contains(candidate.className)
            case .classChain:
                return candidate.classChain.contains(where: contains)
            case .title:
                return contains(candidate.title)
            case .subtitle:
                return contains(candidate.subtitle)
            case .memoryAddress:
                return candidate.memoryAddresses.contains(where: contains)
            }
        }
    }

    /// Convenience predicate for callers that only need a yes / no.
    func matches(_ candidate: Candidate) -> Bool {
        return matchedFields(in: candidate).isEmpty == false
    }

    private func contains(_ haystack: String?) -> Bool {
        guard let haystack, haystack.isEmpty == false else { return false }
        return haystack.lowercased().contains(normalizedQuery)
    }
}
