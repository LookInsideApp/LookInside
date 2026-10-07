// The geometry of the Measure panel: how the two frames are scaled into the
// panel and which distance lines are drawn between them.
//
// "Main" is the selected item, "refer" the hovered one. Lines are computed on
// the scaled frames; the numbers they show come from the original frames.

import CoreGraphics

public enum MeasureGuides {
    public struct HorizontalLine: Equatable, Sendable {
        public var startX: CGFloat
        public var endX: CGFloat
        public var y: CGFloat
        public var value: CGFloat

        public init(startX: CGFloat, endX: CGFloat, y: CGFloat, value: CGFloat) {
            self.startX = startX
            self.endX = endX
            self.y = y
            self.value = value
        }
    }

    public struct VerticalLine: Equatable, Sendable {
        public var startY: CGFloat
        public var endY: CGFloat
        public var x: CGFloat
        public var value: CGFloat

        public init(startY: CGFloat, endY: CGFloat, x: CGFloat, value: CGFloat) {
            self.startY = startY
            self.endY = endY
            self.x = x
            self.value = value
        }
    }

    /// How the two frames overlap. The panel dims the frame that contains the
    /// other, or both when they only partly overlap.
    public enum Overlap: Equatable, Sendable {
        case mainContainsRefer
        case referContainsMain
        case partial
        case disjoint

        public init(main: CGRect, refer: CGRect) {
            if main.contains(refer) {
                self = .mainContainsRefer
            } else if refer.contains(main) {
                self = .referContainsMain
            } else if main.intersects(refer) {
                self = .partial
            } else {
                self = .disjoint
            }
        }

        /// The image alphas for (main, refer).
        public var alphas: (main: CGFloat, refer: CGFloat) {
            switch self {
            case .mainContainsRefer: (0.2, 1)
            case .referContainsMain: (1, 0.2)
            case .partial: (0.2, 0.2)
            case .disjoint: (1, 1)
            }
        }
    }

    /// The width and height of the union of the two frames' extents.
    public static func extent(_ a: CGRect, _ b: CGRect) -> CGSize {
        CGSize(width: max(a.maxX, b.maxX) - min(a.minX, b.minX),
               height: max(a.maxY, b.maxY) - min(a.minY, b.minY))
    }

    /// The factor that fits both frames into `maxWidth` x `maxHeight`; 1 when
    /// the frames have no extent.
    public static func scaleFactor(main: CGRect, refer: CGRect, maxWidth: CGFloat, maxHeight: CGFloat) -> CGFloat {
        let size = extent(main, refer)
        let factor = max(size.width / maxWidth, size.height / maxHeight)
        return factor > 0 ? factor : 1
    }

    /// Both frames divided by `factor`, then moved together so their union starts at (0, 0).
    public static func scaledFrames(main: CGRect, refer: CGRect, factor: CGFloat) -> (main: CGRect, refer: CGRect) {
        let factor = factor == 0 ? 1 : factor
        func scaled(_ rect: CGRect) -> CGRect {
            CGRect(x: rect.minX / factor, y: rect.minY / factor, width: rect.width / factor, height: rect.height / factor)
        }
        let scaledMain = scaled(main)
        let scaledRefer = scaled(refer)
        let minX = min(scaledMain.minX, scaledRefer.minX)
        let minY = min(scaledMain.minY, scaledRefer.minY)
        return (scaledMain.offsetBy(dx: -minX, dy: -minY), scaledRefer.offsetBy(dx: -minX, dy: -minY))
    }

    private enum Order {
        case bigger, same, smaller

        init(_ a: CGFloat, _ b: CGFloat) {
            if abs(a - b) < 0.00001 {
                self = .same
            } else {
                self = a > b ? .bigger : .smaller
            }
        }
    }

    /// The horizontal distance lines between the scaled frames `a` (main) and
    /// `b` (refer), labelled with distances between `originalA` and `originalB`.
    public static func horizontalLines(a: CGRect, b: CGRect, originalA: CGRect, originalB: CGRect) -> [HorizontalLine] {
        var lines: [HorizontalLine] = []
        func add(_ startX: CGFloat, _ endX: CGFloat, _ y: CGFloat, _ value: CGFloat) {
            lines.append(HorizontalLine(startX: startX, endX: endX, y: y, value: value))
        }
        switch Order(a.minX, b.minX) {
        case .smaller:
            if Order(a.maxX, b.minX) == .smaller {
                // A's right edge to B's left edge.
                add(a.maxX, b.minX, a.midY, originalB.minX - originalA.maxX)
            } else {
                switch Order(a.maxX, b.maxX) {
                case .smaller:
                    add(a.maxX, b.maxX, a.midY, originalB.maxX - originalA.maxX)
                case .same:
                    break
                case .bigger:
                    add(b.maxX, a.maxX, b.midY, originalA.maxX - originalB.maxX)
                    add(a.minX, b.minX, b.midY, originalB.minX - originalA.minX)
                }
            }
        case .same:
            switch Order(a.maxX, b.maxX) {
            case .smaller:
                add(a.maxX, b.maxX, a.midY, originalB.maxX - originalA.maxX)
            case .same:
                break
            case .bigger:
                add(b.maxX, a.maxX, b.midY, originalA.maxX - originalB.maxX)
            }
        case .bigger:
            if Order(a.minX, b.maxX) == .bigger {
                // A's left edge to B's right edge.
                add(a.minX, b.maxX, a.midY, originalA.minX - originalB.maxX)
            } else {
                add(b.minX, a.minX, a.midY, originalA.minX - originalB.minX)
                if Order(a.maxX, b.maxX) == .smaller {
                    add(a.maxX, b.maxX, a.midY, originalB.maxX - originalA.maxX)
                }
            }
        }
        return lines
    }

    /// The vertical counterpart of `horizontalLines`.
    public static func verticalLines(a: CGRect, b: CGRect, originalA: CGRect, originalB: CGRect) -> [VerticalLine] {
        var lines: [VerticalLine] = []
        func add(_ startY: CGFloat, _ endY: CGFloat, _ x: CGFloat, _ value: CGFloat) {
            lines.append(VerticalLine(startY: startY, endY: endY, x: x, value: value))
        }
        switch Order(a.minY, b.minY) {
        case .smaller:
            if Order(a.maxY, b.minY) == .smaller {
                // A's bottom edge to B's top edge.
                add(a.maxY, b.minY, a.midX, originalB.minY - originalA.maxY)
            } else {
                switch Order(a.maxY, b.maxY) {
                case .smaller:
                    add(a.maxY, b.maxY, a.midX, originalB.maxY - originalA.maxY)
                case .same:
                    break
                case .bigger:
                    add(b.maxY, a.maxY, b.midX, originalA.maxY - originalB.maxY)
                    add(a.minY, b.minY, b.midX, originalB.minY - originalA.minY)
                }
            }
        case .same:
            switch Order(a.maxY, b.maxY) {
            case .smaller:
                add(a.maxY, b.maxY, a.midX, originalB.maxY - originalA.maxY)
            case .same:
                break
            case .bigger:
                add(b.maxY, a.maxY, b.midX, originalA.maxY - originalB.maxY)
            }
        case .bigger:
            if Order(a.minY, b.maxY) == .bigger {
                // A's top edge to B's bottom edge.
                add(b.maxY, a.minY, a.midX, originalA.minY - originalB.maxY)
            } else {
                add(b.minY, a.minY, a.midX, originalA.minY - originalB.minY)
                if Order(a.maxY, b.maxY) == .smaller {
                    add(a.maxY, b.maxY, a.midX, originalB.maxY - originalA.maxY)
                }
            }
        }
        return lines
    }
}
