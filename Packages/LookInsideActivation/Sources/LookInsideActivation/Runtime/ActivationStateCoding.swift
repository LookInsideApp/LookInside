import Foundation

/// JSON and date coding shared with the 2.3.x Auth helper.
///
/// `state.json` is read and written by both the helper and the Host, so the
/// encoder settings here (ISO 8601 dates without fractional seconds, sorted
/// keys, no pretty printing) must not change.
enum ActivationStateCoding {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    nonisolated(unsafe) static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
