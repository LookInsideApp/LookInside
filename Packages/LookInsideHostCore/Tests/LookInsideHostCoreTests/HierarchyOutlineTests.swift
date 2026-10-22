import Foundation
@testable import LookInsideHostCore
import Testing

/// A stand-in for LookinDisplayItem: a class name, a parent and children.
private final class Node {
    let className: String?
    weak var parent: Node?
    var children: [Node] = []
    var isExpanded = true
    var isHidden = false

    init(_ className: String?, _ children: [Node] = []) {
        self.className = className
        self.children = children
        for child in children {
            child.parent = self
        }
    }

    var ancestors: [Node] {
        var result: [Node] = []
        var cursor = parent
        while let node = cursor {
            result.append(node)
            cursor = node.parent
        }
        return result
    }

    var selfAndDescendants: [Node] {
        [self] + children.flatMap(\.selfAndDescendants)
    }
}

private func path(_ node: Node, roots: [Node]) -> String? {
    HierarchyPathIdentifier.make(
        for: node,
        rootItems: roots,
        parent: { $0.parent },
        children: { $0.children },
        className: { $0.className }
    )
}

struct HierarchyPathIdentifierTests {
    @Test func describesTheChainFromRootToLeaf() {
        let label = Node("UILabel")
        let button = Node("UIButton")
        let content = Node("UIView", [button, label])
        let window = Node("UIWindow", [content])
        let otherWindow = Node("UIWindow")
        let roots = [otherWindow, window]

        #expect(path(window, roots: roots) == "1")
        #expect(path(content, roots: roots) == "1/UIView:0")
        #expect(path(label, roots: roots) == "1/UIView:0/UILabel:1")
    }

    @Test func rootsAreNamedByIndexOnlySoTheirClassMayBeMissing() {
        let child = Node("UIView")
        let scene = Node(nil, [child])
        #expect(path(scene, roots: [scene]) == "0")
        #expect(path(child, roots: [scene]) == "0/UIView:0")
    }

    @Test func failsWithoutAClassNameBelowTheRoot() {
        let custom = Node(nil)
        let empty = Node("")
        let window = Node("UIWindow", [custom, empty])
        #expect(path(custom, roots: [window]) == nil)
        #expect(path(empty, roots: [window]) == nil)
    }

    @Test func failsWhenTheChainDoesNotReachARoot() {
        let child = Node("UIView")
        let window = Node("UIWindow", [child])
        withExtendedLifetime(window) {
            #expect(path(child, roots: []) == nil)
            #expect(path(child, roots: [Node("UIWindow")]) == nil)
        }
    }

    @Test func failsWhenTheParentDoesNotListTheNode() {
        let window = Node("UIWindow")
        let orphan = Node("UIView")
        orphan.parent = window
        #expect(path(orphan, roots: [window]) == nil)
    }

    @Test func comparesNodesByIdentity() {
        let first = Node("UIView")
        let second = Node("UIView")
        let window = Node("UIWindow", [first, second])
        #expect(path(second, roots: [window]) == "0/UIView:1")
    }
}

struct HierarchyKeyNavigationTests {
    private typealias Row = HierarchyKeyNavigation.Row

    private static let leaf = Row(isExpandable: false, isExpanded: false, parentRow: 0, isInHiddenHierarchy: false)

    private func action(_ key: HierarchyKeyNavigation.Key, selected: Int?, rows: [Row]) -> HierarchyKeyNavigation.Action? {
        HierarchyKeyNavigation.action(keyCode: key.rawValue, selectedRow: selected, rowCount: rows.count) { rows[$0] }
    }

    @Test func upAndDownMoveWithinTheRows() {
        let rows = [Self.leaf, Self.leaf, Self.leaf]
        #expect(action(.down, selected: 0, rows: rows) == .select(row: 1))
        #expect(action(.down, selected: 2, rows: rows) == nil)
        #expect(action(.up, selected: 1, rows: rows) == .select(row: 0))
        #expect(action(.up, selected: 0, rows: rows) == nil)
    }

    @Test func nothingIsHandledWithoutAVisibleSelection() {
        #expect(action(.down, selected: nil, rows: [Self.leaf]) == nil)
        #expect(action(.down, selected: 3, rows: [Self.leaf]) == nil)
        #expect(HierarchyKeyNavigation.action(keyCode: 36, selectedRow: 0, rowCount: 1) { _ in Self.leaf } == nil)
    }

    @Test func leftCollapsesAnExpandedRowThenGoesToTheParent() {
        let parent = Row(isExpandable: true, isExpanded: true, parentRow: nil, isInHiddenHierarchy: false)
        let expandedChild = Row(isExpandable: true, isExpanded: true, parentRow: 0, isInHiddenHierarchy: false)
        let collapsedChild = Row(isExpandable: true, isExpanded: false, parentRow: 0, isInHiddenHierarchy: false)
        #expect(action(.left, selected: 1, rows: [parent, expandedChild]) == .collapse(row: 1))
        #expect(action(.left, selected: 1, rows: [parent, collapsedChild]) == .collapseAndSelect(row: 0))
        #expect(action(.left, selected: 1, rows: [parent, Self.leaf]) == .collapseAndSelect(row: 0))
    }

    @Test func leftAtARootDoesNothing() {
        let root = Row(isExpandable: false, isExpanded: false, parentRow: nil, isInHiddenHierarchy: false)
        #expect(action(.left, selected: 0, rows: [root]) == nil)
    }

    @Test func rightExpandsACollapsedRowElseSelectsTheNextShownRow() {
        let collapsed = Row(isExpandable: true, isExpanded: false, parentRow: nil, isInHiddenHierarchy: false)
        let expanded = Row(isExpandable: true, isExpanded: true, parentRow: nil, isInHiddenHierarchy: false)
        let hidden = Row(isExpandable: false, isExpanded: false, parentRow: 0, isInHiddenHierarchy: true)
        #expect(action(.right, selected: 0, rows: [collapsed, Self.leaf]) == .expand(row: 0))
        #expect(action(.right, selected: 0, rows: [expanded, hidden, Self.leaf]) == .select(row: 2))
        #expect(action(.right, selected: 0, rows: [expanded, hidden]) == nil)
        #expect(action(.right, selected: 1, rows: [expanded, Self.leaf]) == nil)
    }
}

struct HierarchySearchVisibilityTests {
    @Test func showsMatchesWithExpandedAncestorsAndCollapsedSubtrees() {
        let grandchild = Node("UIImageView")
        let match = Node("UILabel", [grandchild])
        let sibling = Node("UIButton")
        let content = Node("UIView", [match, sibling])
        let window = Node("UIWindow", [content])
        let flat = window.selfAndDescendants
        content.isExpanded = false

        var matched: [Node] = []
        let shown = HierarchySearchVisibility.apply(
            flatItems: flat,
            matches: { $0.className == "UILabel" },
            ancestors: { $0.ancestors },
            selfAndDescendants: { $0.selfAndDescendants },
            setExpanded: { $0.isExpanded = $1 },
            didMatch: { matched.append($0) }
        )

        #expect(shown.map(\.className) == ["UIWindow", "UIView", "UILabel", "UIImageView"])
        #expect(matched.map(\.className) == ["UILabel"])
        #expect(window.isExpanded && content.isExpanded)
        #expect(!match.isExpanded && !grandchild.isExpanded)
    }

    @Test func aLaterMatchReopensANodeAnEarlierMatchCollapsed() {
        let inner = Node("UILabel")
        let outer = Node("UILabelContainer", [inner])
        let window = Node("UIWindow", [outer])

        let shown = HierarchySearchVisibility.apply(
            flatItems: window.selfAndDescendants,
            matches: { $0.className?.hasPrefix("UILabel") == true },
            ancestors: { $0.ancestors },
            selfAndDescendants: { $0.selfAndDescendants },
            setExpanded: { $0.isExpanded = $1 },
            didMatch: { _ in }
        )

        #expect(shown.count == 3)
        // `outer` was collapsed as its own match, then expanded as the
        // ancestor of `inner`.
        #expect(outer.isExpanded)
        #expect(!inner.isExpanded)
    }

    @Test func noMatchShowsNothing() {
        let window = Node("UIWindow", [Node("UIView")])
        let shown = HierarchySearchVisibility.apply(
            flatItems: window.selfAndDescendants,
            matches: { _ in false },
            ancestors: { $0.ancestors },
            selfAndDescendants: { $0.selfAndDescendants },
            setExpanded: { $0.isExpanded = $1 },
            didMatch: { _ in }
        )
        #expect(shown.isEmpty)
        #expect(window.isExpanded)
    }
}

struct ColorAliasCatalogTests {
    private typealias Catalog = ColorAliasCatalog<String>

    @Test func namesColorsByKeyInDeclarationOrder() {
        let catalog = Catalog(
            aliases: [
                (key: "MainWhite", value: .color("white")),
                (key: "Theme", value: .group([(alias: "ThemeWhite", color: "white"), (alias: "ThemeRed", color: "red")])),
                (key: "Broken", value: .unsupported),
            ],
            colorKey: { $0 }
        )
        #expect(catalog.aliasesByColorKey == ["white": ["MainWhite", "ThemeWhite"], "red": ["ThemeRed"]])
    }

    @Test func listsColorsBeforeGroupsSortedIgnoringCase() {
        let catalog = Catalog(
            aliases: [
                (key: "zeta", value: .color("z")),
                (key: "Groups B", value: .group([(alias: "b2", color: "x"), (alias: "B1", color: "y")])),
                (key: "Alpha", value: .color("a")),
                (key: "groups a", value: .group([(alias: "only", color: "o")])),
                (key: "Empty", value: .group([])),
            ],
            colorKey: { $0 }
        )
        #expect(catalog.entries.map(\.title) == ["Alpha", "zeta", "groups a", "Groups B"])
        guard case let .section(_, items) = catalog.entries[3] else {
            Issue.record("expected a section")
            return
        }
        #expect(items.map(\.title) == ["B1", "b2"])
    }

    @Test func colorsWithoutAKeyAreListedButNotNamed() {
        let catalog = Catalog(aliases: [(key: "Odd", value: .color("?"))], colorKey: { _ in nil })
        #expect(catalog.aliasesByColorKey.isEmpty)
        #expect(catalog.entries.map(\.title) == ["Odd"])
    }
}
