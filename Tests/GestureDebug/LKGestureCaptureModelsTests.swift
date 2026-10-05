import Foundation

@main
struct LKGestureCaptureModelsTests {
    static func main() throws {
        let legacy = Data(#"{"schemaVersion":1,"sessionID":"s","sequence":1,"snapshots":[],"records":[],"recordCount":0,"redactedCount":0,"droppedCount":0,"state":"capturing","message":"","pollDurationMS":0}"#.utf8)
        let decoder = JSONDecoder()
        var batch = try decoder.decode(LKGestureCaptureBatch.self, from: legacy)
        precondition(batch.nativeRegions == nil, "Old Servers remain compatible")
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
        print("Gesture capture model compatibility and native archive tests passed")
    }
}
