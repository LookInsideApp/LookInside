import Foundation
@testable import LookInsideHostCore
import Testing

/// Expected values were produced by the Objective-C categories these
/// functions replace (NSString+Score, NSColor+LookinClient,
/// LookinDisplayItem+LookinClient), so a difference is a behaviour change.
@Suite("Client display text")
struct ClientDisplayTextTests {
    struct ScoreCase: Sendable, CustomTestStringConvertible {
        let string: String
        let abbreviation: String
        let plain: Double
        let fuzzy: Double
        let favorSmaller: Double
        let reducedPenalty: Double
        var testDescription: String {
            "\(string) / \(abbreviation)"
        }
    }

    static let scoreCases: [ScoreCase] = [
        .init(string: "LKHierarchyView", abbreviation: "hv", plain: 0.056666666666666671, fuzzy: 0.056666666666666671, favorSmaller: 0.013333333333333334, reducedPenalty: 0.050000000000000003),
        .init(string: "backgroundColor", abbreviation: "bgc", plain: 0.37, fuzzy: 0.37, favorSmaller: 0.073333333333333334, reducedPenalty: 0.33333333333333337),
        .init(string: "Hello World", abbreviation: "hw", plain: 0.6227272727272728, fuzzy: 0.6227272727272728, favorSmaller: 0.14545454545454548, reducedPenalty: 0.55000000000000004),
        .init(string: "hello world", abbreviation: "Hello", plain: 0.71727272727272717, fuzzy: 0.71727272727272717, favorSmaller: 0.3545454545454545, reducedPenalty: 0.53999999999999992),
        .init(string: "frame", abbreviation: "frame", plain: 1, fuzzy: 1, favorSmaller: 1, reducedPenalty: 1),
        .init(string: "frame", abbreviation: "", plain: 0, fuzzy: 0, favorSmaller: 0, reducedPenalty: 0),
        .init(string: "alpha", abbreviation: "xyz", plain: 0, fuzzy: 0.032000000000000008, favorSmaller: 0.060000000000000012, reducedPenalty: 0.016129032444135213),
        .init(string: "Café Crème", abbreviation: "cc", plain: 0.63, fuzzy: 0.63, favorSmaller: 0.16, reducedPenalty: 0.55000000000000004),
        .init(string: "setNeedsLayout", abbreviation: "layout", plain: 0.48809523809523803, fuzzy: 0.48809523809523803, favorSmaller: 0.29285714285714282, reducedPenalty: 0.34166666666666662),
        .init(string: "isHidden", abbreviation: "hid", plain: 0.38958333333333339, fuzzy: 0.38958333333333339, favorSmaller: 0.21250000000000002, reducedPenalty: 0.28333333333333338),
        .init(string: "abc", abbreviation: "ABC", plain: 0.84999999999999987, fuzzy: 0.84999999999999987, favorSmaller: 0.69999999999999984, reducedPenalty: 0.84999999999999987),
    ]

    @Test("String score matches the Objective-C category", arguments: scoreCases)
    func stringScore(_ testCase: ScoreCase) {
        func close(_ lhs: Double, _ rhs: Double) -> Bool {
            abs(lhs - rhs) < 1e-12
        }
        #expect(close(StringScore.score(testCase.string, against: testCase.abbreviation), testCase.plain))
        #expect(close(StringScore.score(testCase.string, against: testCase.abbreviation, fuzziness: 0.5), testCase.fuzzy))
        #expect(close(StringScore.score(testCase.string, against: testCase.abbreviation, fuzziness: 0.5, options: .favorSmallerWords), testCase.favorSmaller))
        #expect(close(StringScore.score(testCase.string, against: testCase.abbreviation, fuzziness: 0.3, options: .reducedLongStringPenalty), testCase.reducedPenalty))
    }

    @Test("Colours are written as RGB tuples and lowercase hex")
    func colourText() {
        #expect(ClientDisplayText.rgbaString(red: 15 / 255.0, green: 17 / 255.0, blue: 19 / 255.0, alpha: 1) == "(15, 17, 19)")
        #expect(ClientDisplayText.hexString(red: 15 / 255.0, green: 17 / 255.0, blue: 19 / 255.0, alpha: 1) == "#0f1113")
        #expect(ClientDisplayText.rgbaString(red: 1, green: 0.5, blue: 0, alpha: 0.5) == "(255, 128, 0, 0.50)")
        #expect(ClientDisplayText.hexString(red: 1, green: 0.5, blue: 0, alpha: 0.5) == "#ff7f007f")
        #expect(ClientDisplayText.rgbaString(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.01) == "(26, 51, 76, 0.01)")
        #expect(ClientDisplayText.hexString(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.01) == "#19334c02")
    }

    @Test("Module prefixes are dropped outside generic arguments only")
    func modulePrefix() {
        #expect(ClientDisplayText.removingModulePrefix("AppKit._NSCoreHostingView<AppKit.ThemeWidgetView>") == "_NSCoreHostingView<AppKit.ThemeWidgetView>")
        #expect(ClientDisplayText.removingModulePrefix("MyApp.Outer.Inner") == "Inner")
        #expect(ClientDisplayText.removingModulePrefix("UIView") == "UIView")
        #expect(ClientDisplayText.removingModulePrefix("Array<Swift.Int>") == "Array<Swift.Int>")
    }

    @Test("Class chain entries match without their module prefix")
    func classChainMatch() {
        #expect(ClientDisplayText.classChainEntry("SwiftUI.HostingView", matches: "HostingView"))
        #expect(ClientDisplayText.classChainEntry("UIView", matches: "UIView"))
        #expect(!ClientDisplayText.classChainEntry("UIViewController", matches: "UIView"))
    }

    @Test("SwiftUI hosting classes are recognised by name")
    func swiftUISupportNames() {
        #expect(ClientDisplayText.looksLikeSwiftUISupport("_UIHostingView<ContentView>"))
        #expect(ClientDisplayText.looksLikeSwiftUISupport("SwiftUI.PlatformViewHost<X>"))
        #expect(!ClientDisplayText.looksLikeSwiftUISupport("UILabel"))
        #expect(!ClientDisplayText.looksLikeSwiftUISupport(""))
        #expect(!ClientDisplayText.looksLikeSwiftUISupport(nil))
    }

    @Test("Display-list IDs are read from decimal and hex tokens")
    func displayListIDs() {
        #expect(ClientDisplayText.swiftUIDisplayListIDs(in: "12, 0x1F; 12 abc 0 4294967295 4294967294") == [12, 31, 4_294_967_294])
        #expect(ClientDisplayText.swiftUIDisplayListIDs(in: "0xZZ 1e3 -7") == [7])
        #expect(ClientDisplayText.swiftUIDisplayListIDs(in: "").isEmpty)
    }

    @Test("The first hex address is taken out of an object description")
    func memoryAddresses() {
        #expect(ClientDisplayText.memoryAddress(inObjectDescription: "<CALayer: 0x6000ABcd12; frame>") == "0x6000abcd12")
        #expect(ClientDisplayText.memoryAddress(inObjectDescription: "0X1f") == "0x1f")
        #expect(ClientDisplayText.memoryAddress(inObjectDescription: "<CALayer: 0x>") == nil)
        #expect(ClientDisplayText.memoryAddress(inObjectDescription: "no address") == nil)
        #expect(ClientDisplayText.memoryAddress(inObjectDescription: "") == nil)
    }

    @Test("Constraint attributes and relations use the iOS numbering")
    func constraintText() {
        #expect(ClientDisplayText.layoutAttributeName(0) == "notAnAttribute")
        #expect(ClientDisplayText.layoutAttributeName(5) == "leading")
        #expect(ClientDisplayText.layoutAttributeName(20) == "centerYWithinMargins")
        #expect(ClientDisplayText.layoutAttributeName(37) == "maxY")
        #expect(ClientDisplayText.layoutAttributeName(21) == nil)
        #expect(ClientDisplayText.layoutRelationSymbol(-1) == "<=")
        #expect(ClientDisplayText.layoutRelationSymbol(1) == ">=")
        #expect(ClientDisplayText.layoutRelationSymbol(2) == nil)
        #expect(ClientDisplayText.layoutRelationName(0) == "Equal")
        #expect(ClientDisplayText.layoutRelationName(-1) == "LessThanOrEqual")
    }

    @Test("Group screenshots replace nearly empty solo screenshots")
    func groupScreenshotFallback() {
        #expect(!ClientDisplayText.prefersGroupScreenshot(soloVisibleRatio: { nil }, groupVisibleRatio: { 1 }, hasGroupScreenshot: false))
        #expect(ClientDisplayText.prefersGroupScreenshot(soloVisibleRatio: { nil }, groupVisibleRatio: { 0 }, hasGroupScreenshot: true))
        #expect(!ClientDisplayText.prefersGroupScreenshot(soloVisibleRatio: { 0.02 }, groupVisibleRatio: { 1 }, hasGroupScreenshot: true))
        #expect(ClientDisplayText.prefersGroupScreenshot(soloVisibleRatio: { 0.01 }, groupVisibleRatio: { 0.06 }, hasGroupScreenshot: true))
        #expect(!ClientDisplayText.prefersGroupScreenshot(soloVisibleRatio: { 0.015 }, groupVisibleRatio: { 0.059 }, hasGroupScreenshot: true))
        #expect(!ClientDisplayText.prefersGroupScreenshot(soloVisibleRatio: { 0 }, groupVisibleRatio: { 0.05 }, hasGroupScreenshot: true))
    }

    @Test("Visible pixels are those with alpha above 12")
    func visiblePixelRatio() {
        let pixels: [UInt8] = [0, 0, 0, 13, 0, 0, 0, 12, 255, 255, 255, 255, 0, 0, 0, 0]
        #expect(ClientDisplayText.visiblePixelRatio(rgbaPixels: pixels) == 0.5)
        #expect(ClientDisplayText.visiblePixelRatio(rgbaPixels: []) == 0)
    }
}
