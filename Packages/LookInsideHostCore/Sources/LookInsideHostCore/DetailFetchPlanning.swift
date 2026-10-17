import Foundation

/// Which details the inspector asks the inspected app for after a reload,
/// and in which order.
///
/// A refresh used to ask for every node's group screenshot, every
/// expandable node's solo screenshot and every node's attributes at once.
/// With a 2,000-layer screen that was 6,594 tasks while 68 rows were on
/// screen; the attributes alone were two thirds of the bytes. Now the
/// inspector fetches in two kinds of request:
///
/// - **On screen**: for each displayed node, the screenshot the preview
///   shows for it (`StaticAsyncUpdateManager` mirrors
///   `DisplayItem.appropriateScreenshot()`), and its attributes when it has
///   none yet. The window shows the progress.
/// - **Prefetch**: what expanding a folded node would show — its solo
///   screenshot and its children's group screenshots — breadth first from
///   the rows on screen, so the next expand finds them ready. Never
///   attributes: a node gets those when it is displayed.
public enum DetailFetchPlanning {
    public enum Screenshot: Equatable, Sendable {
        case solo
        case group
    }

    /// One node of the hierarchy, as planning sees it.
    public struct Node: Equatable, Sendable {
        /// Indexes of the children in the same list.
        public var childIndexes: [Int]
        public var isExpandable: Bool
        public var isExpanded: Bool
        public var hasPixelBearingSubitems: Bool
        /// Not a pixelless node, not too large, not excluded by the app.
        public var mayFetchScreenshot: Bool
        /// A custom node: it has no object the inspected app can resolve.
        public var isUserCustom: Bool
        public var hasSoloScreenshot: Bool
        public var hasGroupScreenshot: Bool
        public var hasAttributes: Bool

        public init(
            childIndexes: [Int],
            isExpandable: Bool,
            isExpanded: Bool,
            hasPixelBearingSubitems: Bool,
            mayFetchScreenshot: Bool,
            isUserCustom: Bool,
            hasSoloScreenshot: Bool,
            hasGroupScreenshot: Bool,
            hasAttributes: Bool
        ) {
            self.childIndexes = childIndexes
            self.isExpandable = isExpandable
            self.isExpanded = isExpanded
            self.hasPixelBearingSubitems = hasPixelBearingSubitems
            self.mayFetchScreenshot = mayFetchScreenshot
            self.isUserCustom = isUserCustom
            self.hasSoloScreenshot = hasSoloScreenshot
            self.hasGroupScreenshot = hasGroupScreenshot
            self.hasAttributes = hasAttributes
        }

        /// The screenshot the preview shows for the node in its current
        /// state: the solo one once its children that draw something are
        /// shown on their own, the group one otherwise.
        public var shownScreenshot: Screenshot {
            isExpandable && isExpanded && hasPixelBearingSubitems ? .solo : .group
        }

        func has(_ screenshot: Screenshot) -> Bool {
            switch screenshot {
            case .solo:
                hasSoloScreenshot
            case .group:
                hasGroupScreenshot
            }
        }
    }

    /// One thing to ask for: a node's screenshot, its attributes, or both.
    public struct Request: Equatable, Sendable {
        public var nodeIndex: Int
        /// Nil for attributes alone.
        public var screenshot: Screenshot?
        public var wantsAttributes: Bool

        public init(nodeIndex: Int, screenshot: Screenshot?, wantsAttributes: Bool) {
            self.nodeIndex = nodeIndex
            self.screenshot = screenshot
            self.wantsAttributes = wantsAttributes
        }
    }

    /// What the displayed nodes miss, in display order: the screenshot the
    /// preview shows for each, and attributes for those that have none.
    public static func onScreenRequests(for nodes: [Node], displayedIndexes: [Int]) -> [Request] {
        displayedIndexes.compactMap { index in
            let node = nodes[index]
            guard !node.isUserCustom else {
                return nil
            }
            var screenshot: Screenshot?
            if node.mayFetchScreenshot, !node.has(node.shownScreenshot) {
                screenshot = node.shownScreenshot
            }
            let wantsAttributes = !node.hasAttributes
            guard screenshot != nil || wantsAttributes else {
                return nil
            }
            return Request(nodeIndex: index, screenshot: screenshot, wantsAttributes: wantsAttributes)
        }
    }

    /// What expanding the folded nodes would show, breadth first from the
    /// displayed ones: for each folded node, its solo screenshot (when it has
    /// children that draw something) and its children's group screenshots;
    /// then the same one level further down. Only screenshots the nodes do
    /// not have yet; never attributes.
    public static func prefetchRequests(for nodes: [Node], displayedIndexes: [Int]) -> [Request] {
        var requests: [Request] = []
        var foldedIndexes = displayedIndexes.filter { nodes[$0].isExpandable && !nodes[$0].isExpanded }
        var visitedIndexes = Set(foldedIndexes)
        while !foldedIndexes.isEmpty {
            var nextFoldedIndexes: [Int] = []
            for index in foldedIndexes {
                let node = nodes[index]
                if !node.isUserCustom, node.mayFetchScreenshot, node.hasPixelBearingSubitems, !node.hasSoloScreenshot {
                    requests.append(Request(nodeIndex: index, screenshot: .solo, wantsAttributes: false))
                }
                for childIndex in node.childIndexes {
                    let child = nodes[childIndex]
                    if !child.isUserCustom, child.mayFetchScreenshot, !child.hasGroupScreenshot {
                        requests.append(Request(nodeIndex: childIndex, screenshot: .group, wantsAttributes: false))
                    }
                    if child.isExpandable, visitedIndexes.insert(childIndex).inserted {
                        nextFoldedIndexes.append(childIndex)
                    }
                }
            }
            foldedIndexes = nextFoldedIndexes
        }
        return requests
    }
}
