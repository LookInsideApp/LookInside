import XCTest
@testable import LookinMCPCore

final class DiagnosticsTests: XCTestCase {
    func testSmallTapTargetFindingOnSmallButton() {
        let index = HierarchyIndex(info: Fixtures.simpleScreen())
        let layout = LayoutDiagnostics.run(on: index)
        XCTAssertTrue(layout.contains { $0.code == "layout.tap_target_small" && $0.oid == 4 },
                      "Expected small-tap-target finding on the 20×20 button.")
    }

    func testOffscreenLabelDetected() {
        let index = HierarchyIndex(info: Fixtures.simpleScreen())
        let layout = LayoutDiagnostics.run(on: index)
        XCTAssertTrue(layout.contains { $0.code == "layout.offscreen_of_parent" && $0.oid == 6 },
                      "Offscreen label at (5000,5000) should be flagged.")
    }

    func testMissingAccessibilityLabelOnButton() {
        let index = HierarchyIndex(info: Fixtures.simpleScreen())
        let a11y = AccessibilityDiagnostics.run(on: index)
        XCTAssertTrue(a11y.contains { $0.code == "a11y.missing_label" && $0.oid == 4 },
                      "Tiny button has empty label — expected a11y warning.")
    }
}
