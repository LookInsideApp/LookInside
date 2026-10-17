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
