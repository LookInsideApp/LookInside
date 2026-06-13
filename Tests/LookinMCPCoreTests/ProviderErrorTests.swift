import XCTest
import LookinCore
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

    func testLiveClientDecodesLegacyServerResponseArchive() throws {
        let attachment = LookinConnectionResponseAttachment()
        attachment.data = Fixtures.simpleScreen()
        let selector = NSSelectorFromString("archivedDataWithRootObject:")
        let unmanaged = NSKeyedArchiver.perform(selector, with: attachment)
        let data = try XCTUnwrap(unmanaged?.takeUnretainedValue() as? Data)

        let decoded = try LiveLookinClient.decodeResponse(from: data)

        XCTAssertTrue(decoded.data is LookinHierarchyInfo)
    }

    func testLiveClientSelectsRequestedBundleWhenMultipleAppsAreReachable() {
        let first = Fixtures.makeApp(name: "Other", bundleIdentifier: "com.example.other")
        let second = Fixtures.makeApp(name: "Demo", bundleIdentifier: "cn.vanjay.LookInsideDemo")
        let apps = [
            LiveLookinClient.DiscoveredApp(port: 47164, platform: "simulator", appInfo: first),
            LiveLookinClient.DiscoveredApp(port: 47165, platform: "simulator", appInfo: second),
        ]

        let selected = LiveLookinClient.selectPreferredApp(apps, bundleIdentifier: "cn.vanjay.LookInsideDemo")

        XCTAssertEqual(selected?.appInfo.appName, "Demo")
    }
}
