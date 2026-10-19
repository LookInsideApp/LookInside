import CoreGraphics
import Foundation
@testable import LookInsideHostCore
import Testing

struct PreviewZOrderingTests {
    @Test func aPlaneSitsOneLevelAboveTheHighestPlaneItOverlaps() {
        let planes = [
            plane(CGRect(x: 0, y: 0, width: 100, height: 100), parent: .none),
            plane(CGRect(x: 10, y: 10, width: 20, height: 20), parent: .plane(index: 0)),
            plane(CGRect(x: 15, y: 15, width: 5, height: 5), parent: .plane(index: 1)),
            plane(CGRect(x: 60, y: 60, width: 10, height: 10), parent: .plane(index: 0)),
            plane(CGRect(x: 500, y: 500, width: 10, height: 10), parent: .none),
        ]
        #expect(PreviewZOrdering.zIndexes(of: planes, showsHiddenItems: false) == [0, 1, 2, 1, 0])
    }

    @Test func foldedPlanesTakeTheirParentsZIndex() {
        let planes = [
            plane(CGRect(x: 0, y: 0, width: 100, height: 100), parent: .none),
            plane(CGRect(x: 0, y: 0, width: 50, height: 50), parent: .plane(index: 0)),
            plane(CGRect(x: 0, y: 0, width: 10, height: 10), parent: .plane(index: 1), isDisplayed: false),
            plane(CGRect(x: 0, y: 0, width: 10, height: 10), parent: .outside(zIndex: 7), isDisplayed: false),
            plane(CGRect(x: 0, y: 0, width: 10, height: 10), parent: .none, isDisplayed: false),
        ]
        #expect(PreviewZOrdering.zIndexes(of: planes, showsHiddenItems: false) == [0, 1, 1, 7, 0])
    }

    @Test func coplanarOverlaysShareTheirOwnersPlane() {
        let planes = [
            plane(CGRect(x: 0, y: 0, width: 100, height: 100), parent: .none),
            plane(CGRect(x: 0, y: 0, width: 50, height: 50), parent: .plane(index: 0)),
            plane(CGRect(x: 0, y: 0, width: 50, height: 50), parent: .plane(index: 1), isCoplanarOverlay: true),
            plane(CGRect(x: 0, y: 0, width: 50, height: 50), parent: .outside(zIndex: -3), isCoplanarOverlay: true),
        ]
        #expect(PreviewZOrdering.zIndexes(of: planes, showsHiddenItems: false) == [0, 1, 1, 0])
    }

    @Test func hiddenPlanesCountOnlyWhenHiddenItemsAreShown() {
        let planes = [
            plane(CGRect(x: 0, y: 0, width: 100, height: 100), parent: .none),
            plane(CGRect(x: 0, y: 0, width: 50, height: 50), parent: .plane(index: 0), isInHiddenHierarchy: true),
            plane(CGRect(x: 0, y: 0, width: 10, height: 10), parent: .plane(index: 0)),
        ]
        #expect(PreviewZOrdering.zIndexes(of: planes, showsHiddenItems: false) == [0, 1, 1])
        #expect(PreviewZOrdering.zIndexes(of: planes, showsHiddenItems: true) == [0, 1, 2])
    }

    /// The pass the preview ran before, item by item and pair by pair, on
    /// random trees: the new pass must give every plane the same z index.
    @Test(arguments: 1 ... 40)
    func matchesTheOriginalPassOnRandomTrees(seed: UInt64) {
        var generator = SeededGenerator(seed: seed)
        let planes = randomPlanes(count: Int.random(in: 1 ... 120, using: &generator), using: &generator)
        for showsHiddenItems in [false, true] {
            #expect(PreviewZOrdering.zIndexes(of: planes, showsHiddenItems: showsHiddenItems) == originalZIndexes(of: planes, showsHiddenItems: showsHiddenItems))
        }
    }

    // MARK: - The original pass

    /// `PreviewView.updateZIndex(for:)` and `highestOverlappedItem(below:)`
    /// before the change, over the same inputs.
    private func originalZIndexes(of planes: [PreviewZOrdering.Plane], showsHiddenItems: Bool) -> [Int] {
        var zIndexes = [Int](repeating: -1, count: planes.count)
        func parentZIndex(_ plane: PreviewZOrdering.Plane) -> Int? {
            switch plane.parent {
            case .none:
                nil
            case let .plane(index):
                zIndexes[index]
            case let .outside(zIndex):
                zIndex
            }
        }
        for index in planes.indices {
            let plane = planes[index]
            zIndexes[index] = -1
            if plane.isCoplanarOverlay, let parentZIndex = parentZIndex(plane) {
                zIndexes[index] = max(parentZIndex, 0)
                continue
            }
            if plane.isDisplayed {
                var targetIndex: Int?
                for otherIndex in (0 ..< index).reversed() {
                    let other = planes[otherIndex]
                    guard !other.isInHiddenHierarchy || showsHiddenItems else { continue }
                    guard plane.frameToRoot.intersects(other.frameToRoot) else { continue }
                    if let current = targetIndex, zIndexes[otherIndex] <= zIndexes[current] {
                        continue
                    }
                    targetIndex = otherIndex
                }
                zIndexes[index] = targetIndex.map { zIndexes[$0] + 1 } ?? 0
            } else if let parentZIndex = parentZIndex(plane) {
                zIndexes[index] = parentZIndex
            } else {
                zIndexes[index] = 0
            }
            if zIndexes[index] < 0 {
                zIndexes[index] = 0
            }
        }
        return zIndexes
    }

    // MARK: - Fixtures

    private func plane(
        _ frame: CGRect,
        parent: PreviewZOrdering.Parent,
        isDisplayed: Bool = true,
        isCoplanarOverlay: Bool = false,
        isInHiddenHierarchy: Bool = false
    ) -> PreviewZOrdering.Plane {
        PreviewZOrdering.Plane(
            frameToRoot: frame,
            parent: parent,
            isDisplayed: isDisplayed,
            isCoplanarOverlay: isCoplanarOverlay,
            isInHiddenHierarchy: isInHiddenHierarchy
        )
    }

    /// A random tree in hierarchy order: each plane's parent comes earlier,
    /// frames nest loosely inside their parents, flags vary, and a few
    /// parents sit outside the list.
    private func randomPlanes(count: Int, using generator: inout SeededGenerator) -> [PreviewZOrdering.Plane] {
        var planes: [PreviewZOrdering.Plane] = []
        for index in 0 ..< count {
            let parent: PreviewZOrdering.Parent
            let parentFrame: CGRect
            switch index == 0 ? 0 : Int.random(in: 0 ..< 10, using: &generator) {
            case 0:
                parent = .none
                parentFrame = CGRect(x: 0, y: 0, width: 400, height: 800)
            case 1:
                parent = .outside(zIndex: Int.random(in: -1 ... 5, using: &generator))
                parentFrame = CGRect(x: 0, y: 0, width: 400, height: 800)
            default:
                let parentIndex = Int.random(in: 0 ..< index, using: &generator)
                parent = .plane(index: parentIndex)
                parentFrame = planes[parentIndex].frameToRoot
            }
            let width = Double.random(in: 0 ... max(parentFrame.width, 1), using: &generator)
            let height = Double.random(in: 0 ... max(parentFrame.height, 1), using: &generator)
            let frame = CGRect(
                x: parentFrame.minX + Double.random(in: -20 ... max(parentFrame.width - width, 0) + 20, using: &generator),
                y: parentFrame.minY + Double.random(in: -20 ... max(parentFrame.height - height, 0) + 20, using: &generator),
                width: width,
                height: height
            )
            planes.append(PreviewZOrdering.Plane(
                frameToRoot: frame,
                parent: parent,
                isDisplayed: Int.random(in: 0 ..< 4, using: &generator) != 0,
                isCoplanarOverlay: Int.random(in: 0 ..< 8, using: &generator) == 0,
                isInHiddenHierarchy: Int.random(in: 0 ..< 6, using: &generator) == 0
            ))
        }
        return planes
    }
}

/// SplitMix64, so a failing seed reproduces.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}
