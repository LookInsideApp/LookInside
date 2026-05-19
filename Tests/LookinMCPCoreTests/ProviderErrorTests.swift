import XCTest
@testable import LookinMCPCore

final class ProviderErrorTests: XCTestCase {
    func testNoTargetAppErrorMessage() {
        let err = HierarchyProviderError.noTargetApp
        XCTAssertTrue(err.description.contains("Debug build"))
    }

    func testFileProviderReturnsUnsupportedForHighlight() {
        let info = Fixtures.simpleScreen()
        let provider = FileHierarchyProvider(info: info)
        XCTAssertThrowsError(try provider.highlight(oid: 3, durationMs: 1000)) { err in
            guard case HierarchyProviderError.unsupported = err else {
                XCTFail("Expected .unsupported, got \(err)")
                return
            }
        }
    }
}
