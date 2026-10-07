import CoreGraphics
import Foundation
@testable import LookInsideHostCore
import Testing

struct ExportNamingTests {
    @Test func compressionTitlesMatchTheObjectiveCFormat() {
        #expect(ExportNaming.compressionOptions.map(ExportNaming.compressionTitle) == ["10%", "30%", "50%", "75%", "100%"])
    }

    @Test(arguments: [
        (0.1, 0), (0.3, 1), (0.5, 2), (0.75, 3), (1.0, 4),
        (0.34, 1), (0.26, 1), (0.2, nil), (0.0, nil),
    ] as [(Double, Int?)])
    func compressionIndexMatchesWithinTolerance(value: Double, index: Int?) {
        #expect(ExportNaming.compressionIndex(for: value) == index)
    }

    @Test func fileNameUsesAppMajorOSVersionAndTime() {
        let date = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14 22:13:20 UTC
        let name = ExportNaming.fileName(appName: "Demo", osDescription: "17.2.1", date: date,
                                         timeZone: TimeZone(identifier: "UTC")!,
                                         locale: Locale(identifier: "en_US_POSIX"))
        #expect(name == "Demo_ios17_11142213.lookin")
    }

    @Test func fileNamePrintsMissingValuesAsNull() {
        let date = Date(timeIntervalSince1970: 0)
        let name = ExportNaming.fileName(appName: nil, osDescription: nil, date: date,
                                         timeZone: TimeZone(identifier: "UTC")!,
                                         locale: Locale(identifier: "en_US_POSIX"))
        #expect(name == "(null)_ios(null)_01010000.lookin")
        let noDot = ExportNaming.fileName(appName: "A", osDescription: "26", date: date,
                                          timeZone: TimeZone(identifier: "UTC")!,
                                          locale: Locale(identifier: "en_US_POSIX"))
        #expect(noDot == "A_ios26_01010000.lookin")
    }

    @Test func megabytesAreDecimal() {
        #expect(ExportNaming.megabytes(46_200_000) == 46.2)
    }
}

struct ConsoleHistoryTests {
    @Test(arguments: [
        ("", ConsoleInputCheck.empty),
        ("setFrame:", .hasArguments),
        ("layer.frame", .unsupportedSyntax),
        ("a.b:", .hasArguments),
        ("description", .accepted),
    ])
    func inputCheck(text: String, expected: ConsoleInputCheck) {
        #expect(ConsoleInputCheck(text) == expected)
    }

    @Test func recentListIsNewestFirstWithoutDuplicatesAndCapped() {
        var list = ConsoleRecentList<String>(maxCount: 3)
        list.insert("a", id: 1)
        list.insert("b", id: 2)
        list.insert("c", id: 3)
        list.insert("a2", id: 1)
        #expect(list.entries.map(\.element) == ["a2", "c", "b"])
        list.insert("d", id: 4)
        #expect(list.entries.map(\.element) == ["d", "a2", "c"])
        #expect(list.entries.map(\.id) == [4, 1, 3])
    }

    @Test func recentListDefaultsToFiveEntries() {
        var list = ConsoleRecentList<Int>()
        for id in 1 ... 7 {
            list.insert(Int(id), id: UInt(id))
        }
        #expect(list.entries.map(\.element) == [7, 6, 5, 4, 3])
    }
}

struct MeasureGuidesTests {
    @Test func scaleFactorFitsTheLargerSide() {
        let main = CGRect(x: 0, y: 0, width: 400, height: 100)
        let refer = CGRect(x: 0, y: 300, width: 100, height: 100)
        // Extent 400 x 400 into 200 x 100: the height decides.
        #expect(MeasureGuides.scaleFactor(main: main, refer: refer, maxWidth: 200, maxHeight: 100) == 4)
        #expect(MeasureGuides.scaleFactor(main: .zero, refer: .zero, maxWidth: 200, maxHeight: 100) == 1)
    }

    @Test func scaledFramesStartAtTheOrigin() {
        let frames = MeasureGuides.scaledFrames(main: CGRect(x: 20, y: 40, width: 20, height: 20),
                                                refer: CGRect(x: 60, y: 20, width: 40, height: 40),
                                                factor: 2)
        #expect(frames.main == CGRect(x: 0, y: 10, width: 10, height: 10))
        #expect(frames.refer == CGRect(x: 20, y: 0, width: 20, height: 20))
    }

    @Test func overlapDimsTheOuterFrame() {
        let outer = CGRect(x: 0, y: 0, width: 100, height: 100)
        let inner = CGRect(x: 10, y: 10, width: 10, height: 10)
        #expect(MeasureGuides.Overlap(main: outer, refer: inner) == .mainContainsRefer)
        #expect(MeasureGuides.Overlap(main: inner, refer: outer) == .referContainsMain)
        #expect(MeasureGuides.Overlap(main: outer, refer: CGRect(x: 90, y: 90, width: 20, height: 20)) == .partial)
        #expect(MeasureGuides.Overlap(main: inner, refer: CGRect(x: 50, y: 50, width: 5, height: 5)) == .disjoint)
        #expect(MeasureGuides.Overlap.partial.alphas == (0.2, 0.2))
    }

    @Test func separatedFramesGetOneLineEachWay() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 30, y: 50, width: 10, height: 10)
        let originalA = CGRect(x: 0, y: 0, width: 20, height: 20)
        let originalB = CGRect(x: 60, y: 100, width: 20, height: 20)
        #expect(MeasureGuides.horizontalLines(a: a, b: b, originalA: originalA, originalB: originalB)
            == [.init(startX: 10, endX: 30, y: 5, value: 40)])
        #expect(MeasureGuides.verticalLines(a: a, b: b, originalA: originalA, originalB: originalB)
            == [.init(startY: 10, endY: 50, x: 5, value: 80)])
        // Swapped: B is left of and above A.
        #expect(MeasureGuides.horizontalLines(a: b, b: a, originalA: originalB, originalB: originalA)
            == [.init(startX: 30, endX: 10, y: 55, value: 40)])
        #expect(MeasureGuides.verticalLines(a: b, b: a, originalA: originalB, originalB: originalA)
            == [.init(startY: 10, endY: 50, x: 35, value: 80)])
    }

    @Test func containedFrameGetsLinesToEveryEdge() {
        let outer = CGRect(x: 0, y: 0, width: 100, height: 100)
        let inner = CGRect(x: 10, y: 20, width: 30, height: 40)
        let horizontal = MeasureGuides.horizontalLines(a: outer, b: inner, originalA: outer, originalB: inner)
        #expect(horizontal == [
            .init(startX: 40, endX: 100, y: 40, value: 60),
            .init(startX: 0, endX: 10, y: 40, value: 10),
        ])
        let vertical = MeasureGuides.verticalLines(a: inner, b: outer, originalA: inner, originalB: outer)
        #expect(vertical == [
            .init(startY: 0, endY: 20, x: 25, value: 20),
            .init(startY: 60, endY: 100, x: 25, value: 40),
        ])
    }

    @Test func alignedEdgesDrawNothing() {
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        #expect(MeasureGuides.horizontalLines(a: rect, b: rect, originalA: rect, originalB: rect).isEmpty)
        #expect(MeasureGuides.verticalLines(a: rect, b: rect, originalA: rect, originalB: rect).isEmpty)
    }
}
