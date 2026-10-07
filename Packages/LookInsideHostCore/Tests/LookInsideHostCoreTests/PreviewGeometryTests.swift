import Foundation
@testable import LookInsideHostCore
import Testing

struct PreviewGeometryTests {
    @Test func equivalentAngleStaysInsideOneTurn() {
        #expect(PreviewGeometry.equivalentAngle(0.6) == 0.6)
        #expect(abs(PreviewGeometry.equivalentAngle(.pi) - -Double.pi) < 1e-12)
        #expect(abs(PreviewGeometry.equivalentAngle(-Double.pi) - -Double.pi) < 1e-12)
        #expect(abs(PreviewGeometry.equivalentAngle(3 * .pi + 0.5) - (-Double.pi + 0.5)) < 1e-12)
        #expect(abs(PreviewGeometry.equivalentAngle(-5 * .pi - 0.25) - (Double.pi - 0.25)) < 1e-12)
    }

    @Test func focalLengthSpansTwentyToSevenFifty() {
        #expect(PreviewGeometry.focalLength(forScale: 0) == 20)
        #expect(PreviewGeometry.focalLength(forScale: 1) == 750)
        #expect(PreviewGeometry.focalLength(forScale: 0.5) == 20 + 0.25 * 730)
    }

    @Test func interspaceDependsOnDimension() {
        #expect(PreviewGeometry.layerInterspace(is3D: false, zInterspace: 1) == 0.01)
        #expect(PreviewGeometry.layerInterspace(is3D: true, zInterspace: 0) == 0.1)
        #expect(abs(PreviewGeometry.layerInterspace(is3D: true, zInterspace: 1) - 0.8) < 1e-12)
        #expect(PreviewGeometry.clampedZInterspace(-1) == 0)
        #expect(PreviewGeometry.clampedZInterspace(2) == 1)
        #expect(PreviewGeometry.clampedZInterspace(0.3) == 0.3)
    }

    @Test func zPositionsCentreTheStackAndSeparateCoplanarPlanes() {
        // max 3 → offset round(1.5) = 2.
        let positions = PreviewGeometry.zPositions(zIndexes: [0, 1, 1, 3, 1], interspace: 0.5)
        let expected = [-1.0, -0.5, -0.5 + 0.0001, 0.5, -0.5 + 0.0002]
        #expect(positions.count == expected.count)
        for (actual, wanted) in zip(positions, expected) {
            #expect(abs(actual - wanted) < 1e-12)
        }
    }

    @Test func zPositionsOfASinglePlaneUseOffsetRoundedAwayFromZero() {
        // max 1 → offset round(0.5) = 1, as C's round() does.
        #expect(PreviewGeometry.zPositions(zIndexes: [1, 0], interspace: 1) == [0, -1])
        #expect(PreviewGeometry.zPositions(zIndexes: [], interspace: 1) == [])
    }
}

struct DetailTaskPackagingTests {
    @Test func packagesCloseBeforeTheAreaLimit() {
        let ranges = DetailTaskPackaging.packageRanges(areas: [1_000_000, 900_000, 200_000, 50])
        #expect(ranges == [0 ..< 2, 2 ..< 4])
    }

    @Test func aTaskLargerThanTheLimitGetsItsOwnPackage() {
        let ranges = DetailTaskPackaging.packageRanges(areas: [3_000_000, 10, 3_000_000])
        #expect(ranges == [0 ..< 1, 1 ..< 2, 2 ..< 3])
    }

    @Test func packagesHoldAtMostTheTaskLimit() {
        let ranges = DetailTaskPackaging.packageRanges(areas: Array(repeating: 1, count: 250))
        #expect(ranges == [0 ..< 100, 100 ..< 200, 200 ..< 250])
    }

    @Test func runningAreaIsTruncatedLikeAnUnsignedInteger() {
        // 0.6 + 0.6 truncates to 0 then 0 each time, so 1_999_999.5 still fits.
        let ranges = DetailTaskPackaging.packageRanges(areas: [0.6, 0.6, 1_999_999.5], maxArea: 2_000_000)
        #expect(ranges == [0 ..< 3])
        #expect(DetailTaskPackaging.packageRanges(areas: []) == [])
    }
}
