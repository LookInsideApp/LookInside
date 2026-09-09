import Foundation

/// Version 1 of the gesture capture JSON carried by Peertalk push 306.
struct LKGestureCaptureBatch: Codable {
    var schemaVersion: Int
    var sessionID: String
    var sequence: Int
    var snapshots: [LKGestureCaptureSnapshot]
    var records: [LKGestureCaptureRecord]
    var recordCount: Int
    var redactedCount: Int
    var droppedCount: Int
    var state: String
    var message: String
    var pollDurationMS: Double
    var overlayStatus: LKGestureOverlayStatus?
}

struct LKGestureOverlayStatus: Codable {
    var mode: String
    var isEnabled: Bool
    var regionCount: Int
    var hostingViewCount: Int
}

struct LKGestureCaptureRecord: Codable, Identifiable {
    var sequence: Int
    var timestamp: TimeInterval
    var receivedAt: TimeInterval
    var threadID: String
    var subsystem: String
    var category: String
    var message: String
    var id: Int {
        sequence
    }
}

struct LKGestureCaptureSnapshot: Codable, Identifiable {
    var id: String
    var timestamp: TimeInterval
    var receivedAt: TimeInterval
    var threadID: String
    var hostAddress: String?
    var phase: String?
    var inputPhase: String?
    var eventText: String
    var hitTest: String
    var responders: [LKGestureCaptureNode]
    var gestures: [LKGestureCaptureNode]
    var bindings: [LKGestureCaptureBinding]
    var rawRecords: [LKGestureCaptureRecord]
    var complete: Bool
    var responderTreeComplete: Bool?
    var warnings: [String]

    var title: String {
        gestures.first?.typeName ?? responders.first?.typeName ?? "Event"
    }
}

struct LKGestureCaptureNode: Codable, Identifiable {
    var id: String
    var parentID: String?
    var depth: Int
    var kind: String
    var typeName: String
    var address: String?
    var attributeID: String?
    var phase: String?
    var geometry: LKGestureCaptureGeometry?
    var detail: String
    var recordSequence: Int
}

struct LKGestureCaptureGeometry: Codable {
    var x: Double?
    var y: Double?
    var width: Double?
    var height: Double?
    var source: String
    var coordinateSpace: String
}

struct LKGestureCaptureBinding: Codable {
    var eventID: String
    var responderAddresses: [String]
}

struct LKGestureCaptureArchive: Codable {
    var schemaVersion = 1
    var appName: String
    var bundleIdentifier: String
    var sessionID: String?
    var snapshots: [LKGestureCaptureSnapshot]
    var records: [LKGestureCaptureRecord]
}

struct LKGestureTreeItem: Identifiable {
    var node: LKGestureCaptureNode
    var children: [LKGestureTreeItem]?
    var id: String {
        node.id
    }

    static func roots(from nodes: [LKGestureCaptureNode]) -> [LKGestureTreeItem] {
        let grouped = Dictionary(grouping: nodes, by: \.parentID)
        func children(of parentID: String?, depth: Int) -> [LKGestureTreeItem] {
            guard depth < 64 else { return [] }
            return (grouped[parentID] ?? []).map { node in
                let nested = children(of: node.id, depth: depth + 1)
                return LKGestureTreeItem(node: node, children: nested.isEmpty ? nil : nested)
            }
        }
        return children(of: nil, depth: 0)
    }
}
