// LKXcodeViewHierarchyBundleReader.swift
//
// Reads an Xcode-exported `.viewhierarchy` document off disk into an object graph.
//
// The document is a package directory, not a file:
//
//     Something.viewhierarchy/
//       metadata                  XML plist: DocumentVersion, RunnableDisplayName, RunnablePID
//       RequestResponses/
//         Response_0 … Response_N one captured request/response round trip each,
//                                 JSON, gzipped when the capture asked for it
//
// Two details decide whether the result is right:
//
//  * **Entries must be merged in numeric order**, not the lexicographic order a
//    directory listing gives. `Response_10` sorts before `Response_2` as text,
//    and since later responses refine earlier ones, that ordering silently
//    reverses refinements on any capture with ten or more entries.
//  * **A response carrying only its `request` key is a failed capture.** Xcode
//    marks that round trip failed rather than reading it as an empty hierarchy;
//    so does this reader, otherwise a partial export looks like an app with no
//    views.

import Foundation

struct LKXcodeViewHierarchyBundleMetadata {
    let documentVersion: String?
    let runnableDisplayName: String?
    let runnableProcessIdentifier: Int?
}

struct LKXcodeViewHierarchyBundle {
    let metadata: LKXcodeViewHierarchyBundleMetadata
    let graph: LKXcodeViewHierarchyObjectGraph
    /// Number of response entries that were present but unusable.
    let failedResponseCount: Int
    let succeededResponseCount: Int
}

enum LKXcodeViewHierarchyBundleReadingError: Error, CustomStringConvertible {
    case notADirectory(URL)
    case missingResponses(URL)
    case noUsableResponses(URL)

    var description: String {
        switch self {
        case let .notADirectory(url):
            return "\(url.lastPathComponent) is not a view hierarchy package"
        case let .missingResponses(url):
            return "\(url.lastPathComponent) has no RequestResponses directory"
        case let .noUsableResponses(url):
            return "\(url.lastPathComponent) contains no readable capture responses"
        }
    }
}

enum LKXcodeViewHierarchyBundleReader {
    static let responseDirectoryName = "RequestResponses"
    static let metadataFileName = "metadata"
    private static let responseFilePrefix = "Response_"

    static func reading(contentsOf bundleURL: URL) throws -> LKXcodeViewHierarchyBundle {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: bundleURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else { throw LKXcodeViewHierarchyBundleReadingError.notADirectory(bundleURL) }

        let responseURLs = try orderedResponseURLs(inBundleAt: bundleURL)

        let builder = LKXcodeViewHierarchyObjectGraphBuilder()
        var failedResponseCount = 0
        var succeededResponseCount = 0

        for responseURL in responseURLs {
            guard let response = try? readingResponse(at: responseURL),
                  describesCapturedContent(response)
            else {
                failedResponseCount += 1
                continue
            }
            builder.ingesting(response: response)
            succeededResponseCount += 1
        }

        guard succeededResponseCount > 0 else {
            throw LKXcodeViewHierarchyBundleReadingError.noUsableResponses(bundleURL)
        }

        return LKXcodeViewHierarchyBundle(
            metadata: readingMetadata(inBundleAt: bundleURL),
            graph: builder.build(),
            failedResponseCount: failedResponseCount,
            succeededResponseCount: succeededResponseCount
        )
    }

    /// The checks `reading(contentsOf:)` makes before it starts decoding, on
    /// their own: enough to reject something that is not a capture at open
    /// time, cheap enough to run before the window appears.
    static func validatingBundle(at bundleURL: URL) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: bundleURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else { throw LKXcodeViewHierarchyBundleReadingError.notADirectory(bundleURL) }
        guard try !orderedResponseURLs(inBundleAt: bundleURL).isEmpty else {
            throw LKXcodeViewHierarchyBundleReadingError.noUsableResponses(bundleURL)
        }
    }

    // MARK: Responses

    /// Response entries sorted by their numeric suffix, so refinements apply in
    /// capture order rather than in the order a text sort happens to give.
    static func orderedResponseURLs(inBundleAt bundleURL: URL) throws -> [URL] {
        let responsesURL = bundleURL.appendingPathComponent(responseDirectoryName)
        guard let fileNames = try? FileManager.default.contentsOfDirectory(atPath: responsesURL.path) else {
            throw LKXcodeViewHierarchyBundleReadingError.missingResponses(bundleURL)
        }
        return fileNames
            .filter { $0.hasPrefix(responseFilePrefix) }
            .sorted { leadingName, trailingName in
                let leadingIndex = responseIndex(fromFileName: leadingName)
                let trailingIndex = responseIndex(fromFileName: trailingName)
                if leadingIndex != trailingIndex {
                    return leadingIndex < trailingIndex
                }
                return leadingName < trailingName
            }
            .map { responsesURL.appendingPathComponent($0) }
    }

    /// Numeric suffix of `Response_12`; unparsable names sort last but stay readable.
    static func responseIndex(fromFileName fileName: String) -> Int {
        let suffix = fileName.dropFirst(responseFilePrefix.count)
        return Int(suffix) ?? Int.max
    }

    private static func readingResponse(at responseURL: URL) throws -> [String: Any]? {
        let rawData = try Data(contentsOf: responseURL)
        let inflatedData = try LKXcodeViewHierarchyGzip.inflatingIfNeeded(rawData)
        let parsed = try JSONSerialization.jsonObject(with: inflatedData)
        return parsed as? [String: Any]
    }

    /// False when the round trip failed and the entry carries only its request.
    private static func describesCapturedContent(_ response: [String: Any]) -> Bool {
        if response["topLevelGroups"] != nil || response["topLevelPropertyDescriptions"] != nil {
            return true
        }
        return response.keys.contains { $0 != "request" }
    }

    // MARK: Metadata

    static func readingMetadata(inBundleAt bundleURL: URL) -> LKXcodeViewHierarchyBundleMetadata {
        let metadataURL = bundleURL.appendingPathComponent(metadataFileName)
        guard let metadataData = try? Data(contentsOf: metadataURL),
              let parsed = try? PropertyListSerialization.propertyList(from: metadataData, format: nil),
              let metadata = parsed as? [String: Any]
        else {
            return LKXcodeViewHierarchyBundleMetadata(
                documentVersion: nil, runnableDisplayName: nil, runnableProcessIdentifier: nil
            )
        }
        return LKXcodeViewHierarchyBundleMetadata(
            documentVersion: stringValue(metadata["DocumentVersion"]),
            runnableDisplayName: stringValue(metadata["RunnableDisplayName"]),
            runnableProcessIdentifier: (metadata["RunnablePID"] as? NSNumber)?.intValue
        )
    }

    /// `DocumentVersion` ships as a string, but a plist rewrite could make it a
    /// number; accept either rather than lose the field.
    private static func stringValue(_ rawValue: Any?) -> String? {
        if let text = rawValue as? String {
            return text
        }
        if let number = rawValue as? NSNumber {
            return number.stringValue
        }
        return nil
    }
}

/// Shown by the document when an import fails, so the wording must be the
/// user-facing one rather than "The operation couldn't be completed".
extension LKXcodeViewHierarchyBundleReadingError: LocalizedError {
    var errorDescription: String? {
        description
    }
}
