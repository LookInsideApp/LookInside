import Foundation

struct InteractionSnapshot: Codable {
    var targets: [InteractionTarget]
    var swiftUIStatus: String
    var nativeStatus: String
    var truncated: Bool
}

struct InteractionTarget: Codable, Identifiable {
    var id: String
    var source: String
    var name: String
    var targetAddress: String
    var hostAddress: String?
    var windowAddress: String?
    var geometry: GestureCaptureGeometry
    var geometryKind: String
    var shapeKind: String?

    var usesEstimatedBounds: Bool {
        geometryKind != "contentShapeBounds"
    }
}

/// Product rules in logical points, selected from the inspected device, not the Mac host.
enum HitTargetSuggestionPlatform: String, Codable {
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

struct HitTargetSuggestion: Identifiable {
    let ruleID = "interaction.minimum-target-size"
    let target: InteractionTarget
    let minimumSize: Double
    var id: String {
        "\(ruleID):\(target.id)"
    }

    var title: String {
        target.usesEstimatedBounds ? NSLocalizedString("Potentially small hit target", comment: "") : NSLocalizedString("Small hit target", comment: "")
    }
}

enum HitTargetSuggestionRule {
    static func evaluate(_ targets: [InteractionTarget], platform: HitTargetSuggestionPlatform) -> [HitTargetSuggestion] {
        guard let minimum = platform.minimumTargetSize else { return [] }
        var seen: Set<String> = []
        return targets.compactMap { target in
            guard let width = target.geometry.width, let height = target.geometry.height,
                  LookinHitTargetSizeDeficit(width, height, minimum) > 0,
                  seen.insert(target.id).inserted else { return nil }
            return HitTargetSuggestion(target: target, minimumSize: minimum)
        }.sorted { $0.id < $1.id }
    }
}

/// Replaced by each current-page sample. Historical events never revive warnings.
struct HitTargetSuggestionReport {
    private(set) var warnings: [HitTargetSuggestion] = []
    private(set) var inspectedCount = 0
    private(set) var coverageMessage = NSLocalizedString("Start capture to inspect the current page.", comment: "")

    mutating func replace(with snapshot: InteractionSnapshot?, platform: HitTargetSuggestionPlatform, isCapturing: Bool) {
        warnings = []
        inspectedCount = 0
        guard isCapturing else {
            coverageMessage = NSLocalizedString("Start capture to inspect the current page.", comment: "")
            return
        }
        guard platform != .unsupported else {
            coverageMessage = NSLocalizedString("Target-size suggestions currently support iPhone and Mac targets.", comment: "")
            return
        }
        guard let snapshot else {
            coverageMessage = NSLocalizedString("Waiting for current interaction regions. Older Servers need an update to provide Suggestions.", comment: "")
            return
        }
        warnings = HitTargetSuggestionRule.evaluate(snapshot.targets, platform: platform)
        inspectedCount = snapshot.targets.count
        var notes = [NSLocalizedString("Checks reported interaction regions; custom hit testing and occlusion may change the effective target.", comment: "")]
        if snapshot.swiftUIStatus != "available" {
            notes.append(snapshot.swiftUIStatus == "partial"
                ? NSLocalizedString("Some SwiftUI hosts could not be inspected.", comment: "")
                : NSLocalizedString("SwiftUI whole-page regions are unavailable on this runtime.", comment: ""))
        }
        if snapshot.nativeStatus != "available" {
            notes.append(NSLocalizedString("Native controls are not inspected on this platform.", comment: ""))
        }
        if snapshot.truncated {
            notes.append(NSLocalizedString("The region limit was reached; this page is only partially inspected.", comment: ""))
        }
        coverageMessage = notes.joined(separator: " ")
    }
}
