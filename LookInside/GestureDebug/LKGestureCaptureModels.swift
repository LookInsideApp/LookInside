import Foundation

/// Version 1 of the gesture capture JSON carried by Peertalk push 306.
struct GestureCaptureBatch: Codable {
    var schemaVersion: Int
    var sessionID: String
    var sequence: Int
    var snapshots: [GestureCaptureSnapshot]
    var records: [GestureCaptureRecord]
    var recordCount: Int
    var redactedCount: Int
    var droppedCount: Int
    var state: String
    var message: String
    var pollDurationMS: Double
    var overlayStatus: GestureOverlayStatus?
    var nativeRegions: [NativeInteractionRegion]?
    var interactions: InteractionSnapshot?
}

struct NativeInteractionRegion: Codable, Identifiable {
    var id: String
    var source: String
    var viewClass: String
    var viewAddress: String
    var windowAddress: String
    var label: String
    var handlers: [NativeInteractionHandler]
    var geometry: GestureCaptureGeometry
    var isActive: Bool
    var geometryKind: String
}

struct NativeInteractionHandler: Codable {
    var kind: String
    var name: String
    var target: String?
    var events: UInt?
}

struct GestureOverlayStatus: Codable {
    var mode: String
    var isEnabled: Bool
    var regionCount: Int
    var hostingViewCount: Int
}

struct GestureCaptureRecord: Codable, Identifiable {
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

struct GestureCaptureSnapshot: Codable, Identifiable {
    var id: String
    var timestamp: TimeInterval
    var receivedAt: TimeInterval
    var threadID: String
    var hostAddress: String?
    var phase: String?
    var inputPhase: String?
    var eventText: String
    var hitTest: String
    var responders: [GestureCaptureNode]
    var gestures: [GestureCaptureNode]
    var bindings: [GestureCaptureBinding]
    var rawRecords: [GestureCaptureRecord]
    var complete: Bool
    var responderTreeComplete: Bool?
    var warnings: [String]

    var title: String {
        gestures.first?.typeName ?? responders.first?.typeName ?? NSLocalizedString("Event", comment: "")
    }
}

struct GestureCaptureNode: Codable, Identifiable {
    var id: String
    var parentID: String?
    var depth: Int
    var kind: String
    var typeName: String
    var address: String?
    var attributeID: String?
    var phase: String?
    var geometry: GestureCaptureGeometry?
    var contentShape: GestureContentShape?
    var detail: String
    var recordSequence: Int
}

struct GestureContentShape: Codable {
    var typeName: String
    var kind: String?
    var source: String
}

struct GestureCaptureGeometry: Codable {
    var x: Double?
    var y: Double?
    var width: Double?
    var height: Double?
    var source: String
    var coordinateSpace: String
}

struct GestureCaptureBinding: Codable {
    var eventID: String
    var responderAddresses: [String]
}

struct GestureCaptureArchive: Codable {
    var schemaVersion = 1
    var appName: String
    var bundleIdentifier: String
    var sessionID: String?
    var snapshots: [GestureCaptureSnapshot]
    var records: [GestureCaptureRecord]
    var nativeRegions: [NativeInteractionRegion]?
    var interactions: InteractionSnapshot?
    var suggestionPlatform: HitTargetSuggestionPlatform?
}

struct GestureTreeItem: Identifiable {
    var node: GestureCaptureNode
    var children: [GestureTreeItem]?
    var id: String {
        node.id
    }

    static func roots(from nodes: [GestureCaptureNode]) -> [GestureTreeItem] {
        let grouped = Dictionary(grouping: nodes, by: \.parentID)
        func children(of parentID: String?, depth: Int) -> [GestureTreeItem] {
            guard depth < 64 else { return [] }
            return (grouped[parentID] ?? []).map { node in
                let nested = children(of: node.id, depth: depth + 1)
                return GestureTreeItem(node: node, children: nested.isEmpty ? nil : nested)
            }
        }
        return children(of: nil, depth: 0)
    }
}
