import Foundation

struct LKInteractionSnapshot: Codable {
    var targets: [LKInteractionTarget]
    var swiftUIStatus: String
    var nativeStatus: String
    var truncated: Bool
}

struct LKInteractionTarget: Codable, Identifiable {
    var id: String
    var source: String
    var name: String
    var targetAddress: String
    var hostAddress: String?
    var windowAddress: String?
    var geometry: LKGestureCaptureGeometry
    var geometryKind: String
    var shapeKind: String?

    var usesEstimatedBounds: Bool {
        geometryKind != "contentShapeBounds"
    }
}

/// Product rules in logical points, selected from the inspected device, not the Mac host.
enum LKSuggestionPlatform: String, Codable {
    case iPhone, mac, unsupported

    var minimumTargetSize: Double? {
        switch self {
        case .iPhone: LookinMinimumIPhoneTargetSize
        case .mac: LookinMinimumMacTargetSize
        case .unsupported: nil
        }
    }

    static func resolve(deviceType: Int, model: String, deviceName: String, os: String) -> Self {
        if deviceType == 3 || deviceType == 4 {
            return .mac
        }
        let model = model.lowercased()
        if model.hasPrefix("iphone") {
            return .iPhone
        }
        if deviceType == 1 || model.hasPrefix("ipad") {
            return .unsupported
        }
        if deviceType == 0 {
            return deviceName.lowercased().hasPrefix("iphone") ? .iPhone : .unsupported
        }
        if os.lowercased().hasPrefix("macos") {
            return .mac
        }
        // The legacy Others device enum represents a physical iPhone.
        return deviceType == 2 && (model.isEmpty || model.hasPrefix("iphone")) ? .iPhone : .unsupported
    }
}

struct LKSuggestion: Identifiable {
    let ruleID = "interaction.minimum-target-size"
    let target: LKInteractionTarget
    let minimumSize: Double
    var id: String {
        "\(ruleID):\(target.id)"
    }

    var title: String {
        target.usesEstimatedBounds ? "Potentially small hit target" : "Small hit target"
    }
}

enum LKHitTargetSuggestionRule {
    static func evaluate(_ targets: [LKInteractionTarget], platform: LKSuggestionPlatform) -> [LKSuggestion] {
        guard let minimum = platform.minimumTargetSize else { return [] }
        var seen: Set<String> = []
        return targets.compactMap { target in
            guard let width = target.geometry.width, let height = target.geometry.height,
                  LookinHitTargetSizeDeficit(width, height, minimum) > 0,
                  seen.insert(target.id).inserted else { return nil }
            return LKSuggestion(target: target, minimumSize: minimum)
        }.sorted { $0.id < $1.id }
    }
}

/// Replaced by each current-page sample. Historical events never revive warnings.
struct LKSuggestionReport {
    private(set) var warnings: [LKSuggestion] = []
    private(set) var inspectedCount = 0
    private(set) var coverageMessage = "Start capture to inspect the current page."

    mutating func replace(with snapshot: LKInteractionSnapshot?, platform: LKSuggestionPlatform, isCapturing: Bool) {
        warnings = []
        inspectedCount = 0
        guard isCapturing else {
            coverageMessage = "Start capture to inspect the current page."
            return
        }
        guard platform != .unsupported else {
            coverageMessage = "Target-size suggestions currently support iPhone and Mac targets."
            return
        }
        guard let snapshot else {
            coverageMessage = "Waiting for current interaction regions. Older Servers need an update to provide Suggestions."
            return
        }
        warnings = LKHitTargetSuggestionRule.evaluate(snapshot.targets, platform: platform)
        inspectedCount = snapshot.targets.count
        var notes = ["Checks reported interaction regions; custom hit testing and occlusion may change the effective target."]
        if snapshot.swiftUIStatus != "available" {
            notes.append(snapshot.swiftUIStatus == "partial"
                ? "Some SwiftUI hosts could not be inspected."
                : "SwiftUI whole-page regions are unavailable on this runtime.")
        }
        if snapshot.nativeStatus != "available" {
            notes.append("Native controls are not inspected on this platform.")
        }
        if snapshot.truncated {
            notes.append("The region limit was reached; this page is only partially inspected.")
        }
        coverageMessage = notes.joined(separator: " ")
    }
}
