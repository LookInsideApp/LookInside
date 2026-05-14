import XCTest
@testable import LookinMCPCore
import LookinCore

final class HierarchyIndexTests: XCTestCase {
    func testFlatCountMatchesRecursiveWalk() {
        let info = Fixtures.simpleScreen()
        let index = HierarchyIndex(info: info)
        var dfsCount = 0
        index.walkAll { _ in dfsCount += 1 }
        XCTAssertEqual(dfsCount, index.count)
        XCTAssertGreaterThan(dfsCount, 0)
    }

    func testFindByOidReturnsSameNodeAsDFS() {
        let info = Fixtures.simpleScreen()
        let index = HierarchyIndex(info: info)
        var collected: [(UInt, LookinDisplayItem)] = []
        index.walkAll { item in
            if let oid = HierarchyIndex.oid(of: item) { collected.append((oid, item)) }
        }
        for (oid, item) in collected {
            XCTAssertTrue(index.find(oid: oid) === item, "Lookup mismatch for oid \(oid)")
        }
    }

    func testAncestorChain() {
        let info = Fixtures.simpleScreen()
        let index = HierarchyIndex(info: info)
        // The deepest button should have a non-empty ancestor chain.
        var deepest: UInt?
        index.walkAll { item in
            if JSONShape.primaryClassName(item).hasSuffix("Button"),
               let oid = HierarchyIndex.oid(of: item) {
                deepest = oid
            }
        }
        XCTAssertNotNil(deepest)
        XCTAssertFalse(index.ancestorOids(of: deepest!).isEmpty)
    }
}
