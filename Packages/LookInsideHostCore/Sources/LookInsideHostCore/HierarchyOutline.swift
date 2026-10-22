import Foundation

// The hierarchy outline's decisions that do not need the LookinCore model:
// structural path identifiers, keyboard navigation, the filter's visibility
// pass and the color alias catalog. The Host's `LKHierarchyDataSource`
// adapts `LookinDisplayItem` to these through closures.

/// A structural identifier of a node, stable across reloads of the same
/// hierarchy, used to keep and persist expand/collapse state.
///
/// Format: `"<rootIndex>/<class>:<siblingIndex>/<class>:<siblingIndex>/..."`,
/// root first.
public enum HierarchyPathIdentifier {
    /// Returns nil when `rootItems` is empty, when a node of the chain has no
    /// class name (or an empty one), or when the chain does not lead to one
    /// of `rootItems`. Nodes are compared by identity.
    public static func make<Node: AnyObject>(
        for item: Node,
        rootItems: [Node],
        parent: (Node) -> Node?,
        children: (Node) -> [Node],
        className: (Node) -> String?
    ) -> String? {
        guard !rootItems.isEmpty else {
            return nil
        }
        // Walk up to the root, recording the segments leaf first.
        var segments: [String] = []
        var cursor = item
        while let parentNode = parent(cursor) {
            guard let siblingIndex = children(parentNode).firstIndex(where: { $0 === cursor }) else {
                return nil
            }
            guard let name = className(cursor), !name.isEmpty else {
                return nil
            }
            segments.append("\(name):\(siblingIndex)")
            cursor = parentNode
        }
        guard let rootIndex = rootItems.firstIndex(where: { $0 === cursor }) else {
            return nil
        }
        return ([String(rootIndex)] + segments.reversed()).joined(separator: "/")
    }
}

/// What an arrow key does in the hierarchy outline.
public enum HierarchyKeyNavigation {
    public enum Key: UInt16 {
        case left = 123
        case right = 124
        case down = 125
        case up = 126
    }

    public enum Action: Equatable, Sendable {
        /// Select the row.
        case select(row: Int)
        /// Collapse the selected row.
        case collapse(row: Int)
        /// Collapse the row (the selected row's parent) and select it.
        case collapseAndSelect(row: Int)
        /// Expand the selected row.
        case expand(row: Int)
    }

    /// One visible row as the outline sees it.
    public struct Row: Equatable, Sendable {
        public var isExpandable: Bool
        public var isExpanded: Bool
        /// The visible row of the node's parent; nil without a parent or
        /// when the parent is not visible.
        public var parentRow: Int?
        public var isInHiddenHierarchy: Bool

        public init(isExpandable: Bool, isExpanded: Bool, parentRow: Int?, isInHiddenHierarchy: Bool) {
            self.isExpandable = isExpandable
            self.isExpanded = isExpanded
            self.parentRow = parentRow
            self.isInHiddenHierarchy = isInHiddenHierarchy
        }
    }

    /// Returns nil when the key is not handled: no visible selection, an
    /// unknown key, or nowhere to go.
    ///
    /// - Parameter row: the visible row at an index; called only for indexes
    ///   in `0 ..< rowCount`.
    public static func action(
        keyCode: UInt16,
        selectedRow: Int?,
        rowCount: Int,
        row: (Int) -> Row
    ) -> Action? {
        guard let selectedRow, (0 ..< rowCount).contains(selectedRow), let key = Key(rawValue: keyCode) else {
            return nil
        }
        let current = row(selectedRow)
        switch key {
        case .down:
            return selectedRow + 1 < rowCount ? .select(row: selectedRow + 1) : nil
        case .up:
            return selectedRow > 0 ? .select(row: selectedRow - 1) : nil
        case .left:
            if current.isExpandable, current.isExpanded {
                return .collapse(row: selectedRow)
            }
            if let parentRow = current.parentRow {
                return .collapseAndSelect(row: parentRow)
            }
            return nil
        case .right:
            if current.isExpandable, !current.isExpanded {
                return .expand(row: selectedRow)
            }
            for next in (selectedRow + 1) ..< rowCount where !row(next).isInHiddenHierarchy {
                return .select(row: next)
            }
            return nil
        }
    }
}

/// The hierarchy filter's visibility pass.
public enum HierarchySearchVisibility {
    /// Shows every match with its ancestors (expanded) and its subtree
    /// (collapsed, so the user can still open it).
    ///
    /// Matches are visited in `flatItems` order and their expansion writes
    /// apply in that order, so a later match can expand a node an earlier
    /// match collapsed as part of its subtree.
    ///
    /// - Returns: the nodes to show, in `flatItems` order.
    public static func apply<Node: AnyObject>(
        flatItems: [Node],
        matches: (Node) -> Bool,
        ancestors: (Node) -> [Node],
        selfAndDescendants: (Node) -> [Node],
        setExpanded: (Node, Bool) -> Void,
        didMatch: (Node) -> Void
    ) -> [Node] {
        var shown = Set<ObjectIdentifier>()
        for item in flatItems where matches(item) {
            didMatch(item)
            for ancestor in ancestors(item) {
                setExpanded(ancestor, true)
                shown.insert(ObjectIdentifier(ancestor))
            }
            for node in selfAndDescendants(item) {
                setExpanded(node, false)
                shown.insert(ObjectIdentifier(node))
            }
        }
        return flatItems.filter { shown.contains(ObjectIdentifier($0)) }
    }
}

/// The color aliases a hierarchy declares, for the dashboard's color menu
/// and for naming a color.
///
/// An alias entry is either a color (`alias -> color`) or a titled group of
/// them (`title -> [alias -> color]`); both kinds can be mixed.
public struct ColorAliasCatalog<Color> {
    public enum Value {
        case color(Color)
        case group([(alias: String, color: Color)])
        /// Anything else, which is ignored.
        case unsupported
    }

    public enum Entry {
        case color(title: String, color: Color)
        /// A group's items are sorted by title, ignoring case.
        case section(title: String, items: [(title: String, color: Color)])

        public var title: String {
            switch self {
            case let .color(title, _), let .section(title, _):
                return title
            }
        }
    }

    /// Alias names by color key, in the order the aliases were declared.
    public private(set) var aliasesByColorKey: [String: [String]] = [:]
    /// Single colors first, then groups; each sorted by title, ignoring case.
    /// Empty groups are left out.
    public private(set) var entries: [Entry] = []

    /// - Parameter colorKey: the key two equal colors share, or nil when the
    ///   color cannot be described (it is still listed, just not named).
    public init(aliases: [(key: String, value: Value)], colorKey: (Color) -> String?) {
        var colors: [Entry] = []
        var sections: [Entry] = []
        for (key, value) in aliases {
            switch value {
            case let .color(color):
                record(alias: key, color: color, colorKey: colorKey)
                colors.append(.color(title: key, color: color))
            case let .group(members):
                for member in members {
                    record(alias: member.alias, color: member.color, colorKey: colorKey)
                }
                if !members.isEmpty {
                    let items = members
                        .map { (title: $0.alias, color: $0.color) }
                        .sorted { Self.precedes($0.title, $1.title) }
                    sections.append(.section(title: key, items: items))
                }
            case .unsupported:
                continue
            }
        }
        entries = colors.sorted { Self.precedes($0.title, $1.title) }
            + sections.sorted { Self.precedes($0.title, $1.title) }
    }

    private mutating func record(alias: String, color: Color, colorKey: (Color) -> String?) {
        guard let key = colorKey(color) else {
            return
        }
        aliasesByColorKey[key, default: []].append(alias)
    }

    private static func precedes(_ lhs: String, _ rhs: String) -> Bool {
        lhs.caseInsensitiveCompare(rhs) == .orderedAscending
    }
}
