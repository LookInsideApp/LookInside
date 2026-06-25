import XCTest
@testable import LookinMCPCore
import LookinCore

final class JSONShapeTests: XCTestCase {
    func testSecureFieldTextIsRedacted() {
        let info = Fixtures.simpleScreen()
        let index = HierarchyIndex(info: info)
        let secure = index.find(oid: 5)!
        let node = JSONShape.node(secure, index: index, maxDepth: 0, includeOffscreen: true)
        XCTAssertEqual(node.className, "UITextField")
        XCTAssertNil(node.text, "Secure text field contents must never leak into JSONShape output.")
    }

    func testNonSecureLabelTextSurvives() {
        let info = Fixtures.simpleScreen()
        let index = HierarchyIndex(info: info)
        let label = index.find(oid: 3)!
        let node = JSONShape.node(label, index: index, maxDepth: 0, includeOffscreen: true)
        XCTAssertEqual(node.text, "Hello")
    }

    func testRoleInferenceForCommonClasses() {
        XCTAssertEqual(JSONShape.inferRole(className: "UIButton"), "button")
        XCTAssertEqual(JSONShape.inferRole(className: "MyFancyButton"), "button")
        XCTAssertEqual(JSONShape.inferRole(className: "UILabel"), "label")
        XCTAssertNil(JSONShape.inferRole(className: "RandomView"))
    }
}
