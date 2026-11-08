import Foundation

struct GestureCapturePointCloud: Codable, Identifiable {
    struct Point: Codable {
        var x: Double
        var y: Double
    }

    struct Sample: Codable {
        var x: Double
        var y: Double
        var weight: Double
    }

    var eventID: String
    var inputKind: String
    var center: Point
    var reportedRadius: Double
    var samplingRadius: Double
    var points: [Sample]
    var responderAddresses: [String]
    var source: String
    var coordinateSpace: String
    var id: String {
        eventID
    }

    var canDraw: Bool {
        source == "reconstructed" && coordinateSpace == "swiftUIGlobal"
            && center.x.isFinite && center.y.isFinite && reportedRadius.isFinite
            && samplingRadius.isFinite && (0 ... 60).contains(samplingRadius)
            && (1 ... 61).contains(points.count)
            && points.allSatisfy {
                $0.x.isFinite && $0.y.isFinite && $0.weight.isFinite && $0.weight > 0 && $0.weight <= 24
                    && hypot($0.x - center.x, $0.y - center.y) <= samplingRadius + 0.001
            }
    }
}
