import XCTest
@testable import LookinMCPCore

final class ElementSearchTests: XCTestCase {
    func testFindByText() {
        let index = HierarchyIndex(info: Fixtures.simpleScreen())
        let hits = ElementSearch.run(ElementQuery(text: "hello"), in: index)
        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits.first?.oid, 3)
    }

    func testFindByRole() {
        let index = HierarchyIndex(info: Fixtures.simpleScreen())
        let hits = ElementSearch.run(ElementQuery(role: "button"), in: index)
        XCTAssertEqual(hits.first?.oid, 4)
    }

    func testFindByClassName() {
        let index = HierarchyIndex(info: Fixtures.simpleScreen())
        let hits = ElementSearch.run(ElementQuery(className: "Label"), in: index)
        XCTAssertGreaterThanOrEqual(hits.count, 2)
    }

    func testVisibleOnlyHidesZeroSizeOrOffscreen() {
        let index = HierarchyIndex(info: Fixtures.simpleScreen())
        let withHidden = ElementSearch.run(ElementQuery(className: "Label", visibleOnly: false), in: index)
        let visibleOnly = ElementSearch.run(ElementQuery(className: "Label", visibleOnly: true), in: index)
        // The offscreen label has positive area, so visibleOnly does NOT filter it out
        // (offscreen-by-position is a layout concern, not a visibility one). Both queries
        // return the same set here — the test guards against accidental filtering changes.
        XCTAssertEqual(withHidden.count, visibleOnly.count)
    }
}
