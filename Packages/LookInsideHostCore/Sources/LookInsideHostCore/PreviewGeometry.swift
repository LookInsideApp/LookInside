import Foundation

/// The numeric rules of the 3D preview (`LKPreviewView`): rotation
/// normalisation, the camera focal length, and how layer planes are spaced
/// along the z axis.
public enum PreviewGeometry {
    /// Maps an angle in radians into [-π, π): values at or below -π move up
    /// by 2π, then values at or above π move down by 2π (so exactly π comes
    /// back as -π).
    public static func equivalentAngle(_ angle: Double) -> Double {
        var value = angle
        while value <= -Double.pi {
            value += Double.pi * 2
        }
        while value >= Double.pi {
            value -= Double.pi * 2
        }
        return value
    }

    /// The camera focal length for a preview scale in 0...1: 20 at the
    /// smallest, 750 at the largest, growing with the square of the scale.
    public static func focalLength(forScale scale: Double) -> Double {
        20 + scale * scale * 730
    }

    /// Clamps a z interspace setting into 0...1.
    public static func clampedZInterspace(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    /// The distance between two adjacent z indexes: a hair in 2D, and
    /// 0.1...0.8 driven by the z interspace setting in 3D.
    public static func layerInterspace(is3D: Bool, zInterspace: Double) -> Double {
        is3D ? 0.1 + zInterspace * 0.7 : 0.01
    }

    /// The z position of each plane, in order, for the planes' preview z
    /// indexes.
    ///
    /// The indexes are shifted so the middle one sits at 0 (rotation then
    /// pivots around the middle of the stack). Planes that share a z index
    /// are each moved 0.0001 further forward than the previous one, so
    /// coplanar planes do not z-fight.
    public static func zPositions(zIndexes: [Int], interspace: Double) -> [Double] {
        let maxZIndex = zIndexes.reduce(0) { max($0, $1) }
        let offset = Int((Double(maxZIndex) * 0.5).rounded())
        var countByZIndex: [Int: Int] = [:]
        return zIndexes.map { zIndex in
            let adjusted = zIndex - offset
            let count = countByZIndex[adjusted, default: 0]
            countByZIndex[adjusted] = count + 1
            return Double(adjusted) * interspace + Double(count) * 0.0001
        }
    }
}

/// How `LKStaticAsyncUpdateManager` splits detail tasks into the packages
/// it sends: a package is closed before a task that would take its
/// screenshot area over `maxArea`, or once it holds `maxCount` tasks.
public enum DetailTaskPackaging {
    public static let maxArea: Double = 2_000_000
    public static let maxCount = 100

    /// The index ranges of the packages, for the tasks' screenshot areas
    /// (width × height), in order.
    ///
    /// The running area is kept as an unsigned integer, truncated after
    /// each task, as the original Objective-C did.
    public static func packageRanges(
        areas: [Double],
        maxArea: Double = maxArea,
        maxCount: Int = maxCount
    ) -> [Range<Int>] {
        var ranges: [Range<Int>] = []
        var start = 0
        var totalArea: UInt = 0
        for (index, area) in areas.enumerated() {
            let count = index - start
            if Double(totalArea) + area > maxArea || count >= maxCount {
                if count > 0 {
                    totalArea = 0
                    ranges.append(start ..< index)
                    start = index
                }
            }
            let sum = Double(totalArea) + area
            totalArea = sum > 0 ? UInt(sum) : 0
        }
        if start < areas.count {
            ranges.append(start ..< areas.count)
        }
        return ranges
    }
}
