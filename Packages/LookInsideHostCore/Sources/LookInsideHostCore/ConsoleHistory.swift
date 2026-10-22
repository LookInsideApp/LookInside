// The Console's pure rules: which input it refuses before asking the app,
// and the short list of objects that recent calls returned.

/// Why the Console refuses an input without sending it.
public enum ConsoleInputCheck: Equatable, Sendable {
    case accepted
    /// Nothing was typed.
    case empty
    /// The input names a method with arguments (contains ":").
    case hasArguments
    /// The input is a key path or dot syntax (contains ".").
    case unsupportedSyntax

    public init(_ text: String) {
        if text.isEmpty {
            self = .empty
        } else if text.contains(":") {
            self = .hasArguments
        } else if text.contains(".") {
            self = .unsupportedSyntax
        } else {
            self = .accepted
        }
    }
}

/// Most-recent-first list of returned objects, without duplicates (by id),
/// capped at `maxCount`.
public struct ConsoleRecentList<Element> {
    public let maxCount: Int
    public private(set) var entries: [(id: UInt, element: Element)] = []

    public init(maxCount: Int = 5) {
        self.maxCount = maxCount
    }

    /// Puts `element` first, dropping an older entry with the same id and the
    /// oldest entry when the list is over `maxCount`.
    public mutating func insert(_ element: Element, id: UInt) {
        entries.removeAll { $0.id == id }
        entries.insert((id, element), at: 0)
        if entries.count > maxCount {
            entries.removeLast()
        }
    }
}
