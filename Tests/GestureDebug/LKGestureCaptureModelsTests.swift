import Foundation

@main
struct LKGestureCaptureModelsTests {
    static func main() throws {
        let legacy = Data(#"{"schemaVersion":1,"sessionID":"s","sequence":1,"snapshots":[],"records":[],"recordCount":0,"redactedCount":0,"droppedCount":0,"state":"capturing","message":"","pollDurationMS":0}"#.utf8)
        let decoder = JSONDecoder()
        var batch = try decoder.decode(LKGestureCaptureBatch.self, from: legacy)
        precondition(batch.nativeRegions == nil, "Old Servers remain compatible")
        precondition(batch.interactions == nil)
        batch.nativeRegions = [LKNativeInteractionRegion(
            id: "0x1", source: "listSelection", viewClass: "SwiftUI.ListCollectionViewCell", viewAddress: "0x1", windowAddress: "0x2",
            label: "List row 0:1", handlers: [LKNativeInteractionHandler(kind: "listSelection", name: "selectionBehavior.onSelect")],
            geometry: LKGestureCaptureGeometry(x: 20, y: 40, width: 320, height: 44, source: "nativeViewBounds", coordinateSpace: "window"),
            isActive: false, geometryKind: "viewBounds"
        )]
        let current = try decoder.decode(LKGestureCaptureBatch.self, from: JSONEncoder().encode(batch))
        precondition(current.nativeRegions?.first?.handlers.first?.name == "selectionBehavior.onSelect")
        precondition(current.nativeRegions?.first?.geometry.width == 320)
        let archive = LKGestureCaptureArchive(appName: "Fixture", bundleIdentifier: "fixture", sessionID: "s", snapshots: [], records: [], nativeRegions: current.nativeRegions)
        let roundTrip = try decoder.decode(LKGestureCaptureArchive.self, from: JSONEncoder().encode(archive))
        precondition(roundTrip.nativeRegions?.first?.id == "0x1", "Native-only captures can be exported")
        batch.nativeRegions = []
        let cleared = try decoder.decode(LKGestureCaptureBatch.self, from: JSONEncoder().encode(batch))
        precondition(cleared.nativeRegions?.isEmpty == true)
        try testSuggestions()
        print("Gesture capture model compatibility and native archive tests passed")
    }

    static func testSuggestions() throws {
        func target(_ width: Double, _ height: Double, id: String = "target", kind: String = "contentShapeBounds") -> LKInteractionTarget {
            LKInteractionTarget(id: id, source: "swiftUI", name: "Test", targetAddress: "0x1",
                                geometry: LKGestureCaptureGeometry(x: 0, y: 0, width: width, height: height,
                                                                   source: kind, coordinateSpace: "window"),
                                geometryKind: kind, shapeKind: "rectangle")
        }
        for (platform, threshold) in [(LKSuggestionPlatform.iPhone, 44.0), (.mac, 28.0)] {
            for (width, height, warning) in [(threshold, threshold, false), (threshold - 0.1, threshold, true),
                                             (threshold.nextDown, threshold, false), (threshold, threshold.nextDown, false),
                                             (threshold - 0.0001, threshold, true),
                                             (threshold, threshold - 0.1, true), (80, threshold - 1, true),
                                             (100, 100, false), (0, 20, false), (-1, 20, false),
                                             (Double.nan, 20, false), (20, Double.infinity, false)]
            {
                precondition(LKHitTargetSuggestionRule.evaluate([target(width, height)], platform: platform).isEmpty != warning,
                             "\(platform) \(width) x \(height)")
            }
        }
        precondition(LKHitTargetSuggestionRule.evaluate([target(40, 40)], platform: .iPhone).count == 1)
        precondition(LKHitTargetSuggestionRule.evaluate([target(44, 43.99999999999994)], platform: .iPhone).isEmpty,
                     "Real fixture geometry after window-coordinate conversion must not warn at 44 pt")
        precondition(LKHitTargetSuggestionRule.evaluate([target(40, 40)], platform: .mac).isEmpty)
        precondition(LKHitTargetSuggestionRule.evaluate([target(20, 20)], platform: .unsupported).isEmpty)
        precondition(LKHitTargetSuggestionRule.evaluate([target(20, 20), target(20, 20)], platform: .iPhone).count == 1)
        precondition(LKHitTargetSuggestionRule.evaluate([target(20, 20, kind: "nativeViewBounds")], platform: .iPhone).first?.target.usesEstimatedBounds == true)
        precondition(LKHitTargetSuggestionRule.evaluate([target(20, 20)], platform: .iPhone).first?.target.usesEstimatedBounds == false)
        precondition(LKSuggestionPlatform.resolve(deviceType: 0, model: "iPhone17,3", deviceName: "Test", os: "iOS 18.5") == .iPhone)
        precondition(LKSuggestionPlatform.resolve(deviceType: 0, model: "", deviceName: "iPhone 16 Pro", os: "iOS 18.5") == .iPhone)
        precondition(LKSuggestionPlatform.resolve(deviceType: 4, model: "Mac16,12", deviceName: "Mac", os: "iOS") == .mac)
        precondition(LKSuggestionPlatform.resolve(deviceType: 3, model: "", deviceName: "Test", os: "") == .mac)
        precondition(LKSuggestionPlatform.resolve(deviceType: 0, model: "iPad16,1", deviceName: "iPad", os: "iOS") == .unsupported)
        precondition(LKSuggestionPlatform.resolve(deviceType: 0, model: "", deviceName: "Test", os: "iOS") == .unsupported)

        let snapshot = LKInteractionSnapshot(targets: [target(24, 24)], swiftUIStatus: "available", nativeStatus: "available", truncated: false)
        var report = LKSuggestionReport()
        report.replace(with: snapshot, platform: .iPhone, isCapturing: true)
        let id = report.warnings.first?.id
        for _ in 0 ..< 3 {
            report.replace(with: snapshot, platform: .iPhone, isCapturing: true)
        }
        precondition(report.warnings.count == 1 && report.warnings.first?.id == id, "Heartbeats replace warnings without duplicates")
        var nextPage = snapshot
        nextPage.targets = [target(60, 60)]
        report.replace(with: nextPage, platform: .iPhone, isCapturing: true)
        precondition(report.warnings.isEmpty, "Page changes remove old warnings")
        report.replace(with: snapshot, platform: .iPhone, isCapturing: false)
        precondition(report.warnings.isEmpty && report.inspectedCount == 0, "Stop and disconnect clear current warnings")
        report.replace(with: nil, platform: .iPhone, isCapturing: true)
        precondition(report.warnings.isEmpty && report.coverageMessage.contains("Older Servers"))
        nextPage.swiftUIStatus = "unavailable"
        nextPage.nativeStatus = "unavailable"
        nextPage.truncated = true
        report.replace(with: nextPage, platform: .mac, isCapturing: true)
        precondition(report.coverageMessage.contains("unavailable") && report.coverageMessage.contains("partially"))
        let archive = LKGestureCaptureArchive(appName: "Test", bundleIdentifier: "test", snapshots: [], records: [],
                                              interactions: snapshot, suggestionPlatform: .iPhone)
        let decoded = try JSONDecoder().decode(LKGestureCaptureArchive.self, from: JSONEncoder().encode(archive))
        precondition(decoded.interactions?.targets.first?.geometry.width == 24 && decoded.suggestionPlatform == .iPhone)
        print("Hit target rule boundaries, device selection, lifecycle and export tests passed")
    }
}
