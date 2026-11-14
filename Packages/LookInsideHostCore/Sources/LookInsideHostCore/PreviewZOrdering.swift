import CoreGraphics
import Foundation

/// How the 3D preview stacks its planes: the z index of every plane, from
/// the planes' frames and states.
///
/// The rule (`PreviewView.updateZPosition()`): planes are visited in
/// hierarchy order, parents before children.
/// - A plane drawn on its owner's plane (a layout guide, a cell) takes the
///   owner's z index, at least 0.
/// - A plane shown in the hierarchy sits one level above the highest plane
///   it overlaps among those visited before it, or at 0 when it overlaps
///   none. Planes in a hidden part of the hierarchy count only when hidden
///   items are shown.
/// - A plane not shown (inside a folded node) takes its parent's z index,
///   or 0 without a parent.
///
/// Every input frame is the plane's frame in root coordinates, computed
/// once per pass; the preview used to recompute it, up the whole ancestor
/// chain, for every pair of planes it compared.
public enum PreviewZOrdering {
    /// Where a plane's parent is, for the planes that follow it.
    public enum Parent: Equatable, Sendable {
        /// A top-level plane.
        case none
        /// The parent is the plane at this index in the same list, earlier
        /// in it.
        case plane(index: Int)
        /// The parent is not in the list (it has no preview of its own);
        /// its last known z index.
        case outside(zIndex: Int)
    }

    public struct Plane: Equatable, Sendable {
        public var frameToRoot: CGRect
        public var parent: Parent
        /// Shown in the hierarchy (not inside a folded node).
        public var isDisplayed: Bool
        /// Drawn on its owner's plane rather than on one of its own.
        public var isCoplanarOverlay: Bool
        public var isInHiddenHierarchy: Bool

        public init(frameToRoot: CGRect, parent: Parent, isDisplayed: Bool, isCoplanarOverlay: Bool, isInHiddenHierarchy: Bool) {
            self.frameToRoot = frameToRoot
            self.parent = parent
            self.isDisplayed = isDisplayed
            self.isCoplanarOverlay = isCoplanarOverlay
            self.isInHiddenHierarchy = isInHiddenHierarchy
        }
    }

    /// The z index of each plane, in order.
    public static func zIndexes(of planes: [Plane], showsHiddenItems: Bool) -> [Int] {
        var zIndexes = [Int](repeating: 0, count: planes.count)
        for (index, plane) in planes.enumerated() {
            let zIndex: Int
            if plane.isCoplanarOverlay, let parentZIndex = parentZIndex(of: plane, in: zIndexes) {
                zIndex = max(parentZIndex, 0)
            } else if plane.isDisplayed {
                zIndex = highestOverlappedZIndex(before: index, in: planes, zIndexes: zIndexes, showsHiddenItems: showsHiddenItems).map { $0 + 1 } ?? 0
            } else {
                zIndex = parentZIndex(of: plane, in: zIndexes) ?? 0
            }
            zIndexes[index] = max(zIndex, 0)
        }
        return zIndexes
    }

    private static func parentZIndex(of plane: Plane, in zIndexes: [Int]) -> Int? {
        switch plane.parent {
        case .none:
            nil
        case let .plane(parentIndex):
            zIndexes[parentIndex]
        case let .outside(zIndex):
            zIndex
        }
    }

    /// The highest z index among the planes before `index` that overlap it;
    /// nil when none does.
    private static func highestOverlappedZIndex(before index: Int, in planes: [Plane], zIndexes: [Int], showsHiddenItems: Bool) -> Int? {
        let frame = planes[index].frameToRoot
        var highest: Int?
        for otherIndex in 0 ..< index {
            let other = planes[otherIndex]
            if other.isInHiddenHierarchy, !showsHiddenItems {
                continue
            }
            if let highest, zIndexes[otherIndex] <= highest {
                continue
            }
            if frame.intersects(other.frameToRoot) {
                highest = zIndexes[otherIndex]
            }
        }
        return highest
    }
}

// MARK: - Planes a portal draws elsewhere

public extension PreviewZOrdering {
    /// The order the pass visits the planes in, and the parent each counts
    /// there, when portals draw some of them elsewhere on screen.
    ///
    /// `parents` lists the planes in hierarchy order, each with its parent's
    /// index (an earlier one) or nil. `drawnAtPortals` maps a plane that a
    /// portal draws while hiding it in place (`CAPortalLayer`'s
    /// `hidesSourceLayer`) to the portal's plane. Such a plane, with
    /// everything under it, is visited as the portal's last child — right
    /// after the portal and what is under it — so it comes out in front of
    /// whatever the portal is drawn over, as an `NSGlassEffectView`'s content
    /// is drawn over its glass. A portal inside what it draws is left alone.
    /// With no portals the order is the hierarchy's.
    static func visitingOrder(parents: [Int?], drawnAtPortals: [Int: Int]) -> (order: [Int], parents: [Int?]) {
        guard !drawnAtPortals.isEmpty else {
            return (Array(parents.indices), parents)
        }
        var visitingParents = parents
        var children = [[Int]](repeating: [], count: parents.count)
        var roots: [Int] = []
        for (index, parent) in parents.enumerated() {
            if let parent, children.indices.contains(parent) {
                children[parent].append(index)
            } else {
                roots.append(index)
            }
        }
        func isAncestor(_ candidate: Int, of index: Int) -> Bool {
            var current: Int? = index
            while let step = current {
                if step == candidate { return true }
                current = visitingParents[step]
            }
            return false
        }
        for (source, portal) in drawnAtPortals.sorted(by: { $0.key < $1.key }) {
            guard parents.indices.contains(source), parents.indices.contains(portal),
                  !isAncestor(source, of: portal)
            else { continue }
            if let parent = visitingParents[source], children.indices.contains(parent) {
                children[parent].removeAll { $0 == source }
            } else {
                roots.removeAll { $0 == source }
            }
            children[portal].append(source)
            visitingParents[source] = portal
        }
        var order: [Int] = []
        order.reserveCapacity(parents.count)
        var pending = Array(roots.reversed())
        while let index = pending.popLast() {
            order.append(index)
            pending.append(contentsOf: children[index].reversed())
        }
        return (order, visitingParents)
    }
}
