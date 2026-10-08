import AppKit
import Foundation

/// Coverage for the logic of the Launch, Toolbar and Read modules.
///
/// The `.lookin` cases are the important ones. `Fixtures/legacy-host.lookin`
/// was written by the Objective-C reader's encoding call (see
/// LookinArchiveFixtureGenerator.m), so it stands for every file an older
/// host saved: it has to open, and what the Swift reader writes has to use
/// the same archive classes and keys so older hosts can open it.
@main
struct LaunchToolbarReadTests {
    static func main() {
        let arguments = CommandLine.arguments
        guard arguments.count == 2 else {
            fail("usage: \(arguments[0]) <legacy-host.lookin>")
        }
        let fixture: Data
        do {
            fixture = try Data(contentsOf: URL(fileURLWithPath: arguments[1]))
        } catch {
            fail("cannot read the fixture: \(error)")
        }

        testLegacyArchiveOpens(fixture)
        testArchiveKeepsClassesAndKeys(fixture)
        testArchiveRoundTrips(fixture)
        testUnreadableArchiveFailsAsInnerError()
        testArchiveOfAnotherClassFailsAsInnerError()
        testArchiveVersionLimits()
        testScreenshotLookupTakesBothFromOneOid()
        testToolbarIdentifiersKeepTheirValues()
        testSteppingClamps()
        testAppsPopoverCopy()
        testLaunchAutoEnter()
        testLaunchServerVersionErrors()
        print("Launch / Toolbar / Read tests passed")
    }

    // MARK: - .lookin archives

    private static func testLegacyArchiveOpens(_ fixture: Data) {
        let file = decode(fixture)
        expect(file.serverVersion == LOOKIN_SERVER_VERSION, "file server version")
        let info = file.hierarchyInfo
        expect(info?.serverVersion == LOOKIN_SERVER_VERSION, "hierarchy server version")
        expect(info?.collapsedClassList == ["UITableViewCellContentView"], "collapsed class list")
        expect(info?.colorAlias?.keys.sorted() == ["Brand"], "color alias")

        let appInfo = info?.appInfo
        expect(appInfo?.appName == "Fixture App", "app name")
        expect(appInfo?.appBundleIdentifier == "app.lookinside.fixture", "bundle identifier")
        expect(appInfo?.deviceDescription == "iPhone Simulator", "device description")
        expect(appInfo?.osDescription == "iOS 26.0", "os description")
        expect(appInfo?.deviceType == .simulator, "device type")
        expect(appInfo?.screenScale == 3, "screen scale")
        expect(appInfo?.appIcon != nil, "app icon")
        expect(appInfo?.screenshot != nil, "app screenshot")

        guard let window = info?.displayItems?.first, info?.displayItems?.count == 1 else {
            fail("one root item expected")
        }
        expect(window.windowObject?.oid == 101, "window oid")
        expect(window.layerObject?.oid == 102, "window layer oid")
        expect(window.representedAsKeyWindow, "key window flag")
        expect(window.subitems?.count == 2, "window subitems")
        let label = window.subitems?.first
        expect(label?.viewObject?.classChainList?.first == "UILabel", "label class chain")
        expect(label?.alpha == 0.5, "label alpha")
        expect(label?.frame == CGRect(x: 20, y: 100, width: 200, height: 40), "label frame")
        expect(label?.customDisplayTitle == "Hello", "label title")
        expect(window.subitems?.last?.isHidden == true, "hidden item")

        expect(Set(file.soloScreenshots?.keys.map(\.intValue) ?? []) == [102, 202], "solo screenshot oids")
        expect(Set(file.groupScreenshots?.keys.map(\.intValue) ?? []) == [102], "group screenshot oids")
        expect(NSImage(data: file.groupScreenshots?[102] ?? Data()) != nil, "group screenshot is an image")
    }

    /// Every archived object of the Swift writer has the class name and
    /// the keys the Objective-C writer used.
    private static func testArchiveKeepsClassesAndKeys(_ fixture: Data) {
        let reencoded = encode(decode(fixture))
        let legacyShape = archiveShape(fixture)
        let swiftShape = archiveShape(reencoded)
        expect(!legacyShape.isEmpty, "the fixture has archived objects")
        expect(swiftShape == legacyShape, "archive classes and keys differ:\nlegacy \(legacyShape.sorted())\nswift \(swiftShape.sorted())")
        expect(legacyShape.contains { $0.hasPrefix("LookinHierarchyFile:") }, "root class name")
        expect(
            legacyShape.contains("LookinHierarchyFile:groupScreenshots,hierarchyInfo,serverVersion,soloScreenshots"),
            "LookinHierarchyFile keys"
        )
    }

    private static func testArchiveRoundTrips(_ fixture: Data) {
        let file = decode(encode(decode(fixture)))
        expect(file.hierarchyInfo?.appInfo?.appName == "Fixture App", "round-tripped app name")
        expect(file.hierarchyInfo?.displayItems?.first?.subitems?.count == 2, "round-tripped tree")
        expect(file.soloScreenshots == decode(fixture).soloScreenshots, "round-tripped solo screenshots")
        expect(file.groupScreenshots == decode(fixture).groupScreenshots, "round-tripped group screenshots")
    }

    private static func testUnreadableArchiveFailsAsInnerError() {
        expectError(Data("not an archive".utf8), code: LookinErrCode_Inner, "garbage data")
        expectError(Data(), code: LookinErrCode_Inner, "empty data")
    }

    private static func testArchiveOfAnotherClassFailsAsInnerError() {
        let data = try! NSKeyedArchiver.archivedData(withRootObject: "text" as NSString, requiringSecureCoding: true)
        expectError(data, code: LookinErrCode_Inner, "a string archive")
    }

    private static func testArchiveVersionLimits() {
        for (version, code) in [
            (Int32(0), LookinErrCode_ServerVersionTooLow),
            (LOOKIN_SUPPORTED_SERVER_MIN - 1, LookinErrCode_ServerVersionTooLow),
            (LOOKIN_SUPPORTED_SERVER_MAX + 1, LookinErrCode_ServerVersionTooHigh),
        ] {
            let file = HierarchyFile()
            file.serverVersion = version
            file.hierarchyInfo = HierarchyInfo()
            expectError(encode(file), code: code, "server version \(version)")
        }
        let file = HierarchyFile()
        file.serverVersion = LOOKIN_SUPPORTED_SERVER_MIN
        file.hierarchyInfo = HierarchyInfo()
        expect(decode(encode(file)).serverVersion == LOOKIN_SUPPORTED_SERVER_MIN, "oldest supported version opens")
    }

    // MARK: - Reader screenshots

    private static func testScreenshotLookupTakesBothFromOneOid() {
        let soloA = Data([1]), groupB = Data([2]), soloB = Data([3])
        var result = LKReadScreenshotLookup.screenshots(
            forOids: [1, 2], solo: [1: soloA, 2: soloB], group: [2: groupB]
        )
        expect(result.solo == soloA && result.group == nil, "first oid with a screenshot wins, alone")

        result = LKReadScreenshotLookup.screenshots(forOids: [3, 2], solo: [1: soloA, 2: soloB], group: [2: groupB])
        expect(result.solo == soloB && result.group == groupB, "both screenshots of the matching oid")

        result = LKReadScreenshotLookup.screenshots(forOids: [9], solo: [1: soloA], group: nil)
        expect(result.solo == nil && result.group == nil, "no screenshot")

        result = LKReadScreenshotLookup.screenshots(forOids: [2], solo: nil, group: [2: groupB])
        expect(result.solo == nil && result.group == groupB, "group only")
    }

    // MARK: - Toolbar

    private static func testToolbarIdentifiersKeepTheirValues() {
        let identifiers: [(String, String)] = [
            (LKToolBarIdentifier_Dimension, "0"), (LKToolBarIdentifier_Scale, "1"),
            (LKToolBarIdentifier_Setting, "2"), (LKToolBarIdentifier_Reload, "3"),
            (LKToolBarIdentifier_App, "5"), (LKToolBarIdentifier_AppInReadMode, "12"),
            (LKToolBarIdentifier_Add, "13"), (LKToolBarIdentifier_Remove, "14"),
            (LKToolBarIdentifier_Console, "15"), (LKToolBarIdentifier_Rotation, "16"),
            (LKToolBarIdentifier_Measure, "17"), (LKToolBarIdentifier_Message, "18"),
            (LKToolBarIdentifier_FastMode, "19"), (LKToolBarIdentifier_SwiftUIMode, "20"),
        ]
        for (identifier, value) in identifiers {
            expect(identifier == value, "toolbar identifier \(value)")
        }
    }

    private static func testSteppingClamps() {
        expect(abs(LKToolbarRules.stepped(0.5, by: LKToolbarRules.step, lower: 0, upper: 1) - 0.6) < 1e-9, "step up")
        expect(LKToolbarRules.stepped(0.95, by: LKToolbarRules.step, lower: 0, upper: 1) == 1, "clamped high")
        expect(LKToolbarRules.stepped(0.05, by: -LKToolbarRules.step, lower: 0, upper: 1) == 0, "clamped low")
        expect(LKToolbarRules.stepped(3, by: 0.1, lower: 0, upper: 1) == 1, "out of range value comes back in range")
    }

    private static func testAppsPopoverCopy() {
        var copy = LKToolbarRules.appsPopoverCopy(source: .reloadButton, appCount: 0)
        expect(copy.title == "Connection lost" && copy.subtitle == "And no inspectable app was found", "reload, no apps")
        copy = LKToolbarRules.appsPopoverCopy(source: .noConnectionTips, appCount: 1)
        expect(copy.title == "Connection lost" && copy.subtitle == "Click the screenshot below to Change App", "tips, one app")
        copy = LKToolbarRules.appsPopoverCopy(source: .reloadButton, appCount: 3)
        expect(copy.subtitle == "Other 3 apps were found", "reload, several apps")
        copy = LKToolbarRules.appsPopoverCopy(source: .appButton, appCount: 0)
        expect(copy.title == "No inspectable app was found" && copy.subtitle == nil, "app button, no apps")
        copy = LKToolbarRules.appsPopoverCopy(source: .appButton, appCount: 1)
        expect(copy.title == "1 active app was found" && copy.subtitle == "Click the screenshot below to inspect", "app button, one app")
        copy = LKToolbarRules.appsPopoverCopy(source: .appButton, appCount: 2)
        expect(copy.title == "2 active apps were found", "app button, several apps")
    }

    // MARK: - Launch

    private static func testLaunchAutoEnter() {
        expect(LKLaunchRules.canAutoEnter(requested: true, appCount: 1, onlyAppHasServerVersionError: false, isActivated: true), "auto enter")
        expect(!LKLaunchRules.canAutoEnter(requested: false, appCount: 1, onlyAppHasServerVersionError: false, isActivated: true), "not requested")
        expect(!LKLaunchRules.canAutoEnter(requested: true, appCount: 2, onlyAppHasServerVersionError: false, isActivated: true), "two apps")
        expect(!LKLaunchRules.canAutoEnter(requested: true, appCount: 0, onlyAppHasServerVersionError: false, isActivated: true), "no apps")
        expect(!LKLaunchRules.canAutoEnter(requested: true, appCount: 1, onlyAppHasServerVersionError: true, isActivated: true), "version error")
        expect(!LKLaunchRules.canAutoEnter(requested: true, appCount: 1, onlyAppHasServerVersionError: false, isActivated: false), "not activated")
    }

    private static func testLaunchServerVersionErrors() {
        expect(LKLaunchRules.serverVersionHelpPath(errorCode: LookinErrCode_ServerVersionTooLow) == "faq/server-version-too-low/", "too low page")
        expect(LKLaunchRules.serverVersionHelpPath(errorCode: LookinErrCode_ServerVersionTooHigh) == "faq/server-version-too-high/", "too high page")
        expect(LKLaunchRules.serverVersionHelpPath(errorCode: LookinErrCode_Inner) == "faq/server-version-too-high/", "other errors use the too high page")
        expect(
            LKLaunchRules.serverVersionErrorTitle(errorCode: LookinErrCode_ServerVersionTooLow, localizedDescription: "x")
                == "The version of LookinServer linked with this iOS App is too low.",
            "too low title"
        )
        expect(
            LKLaunchRules.serverVersionErrorTitle(errorCode: LookinErrCode_ServerVersionTooHigh, localizedDescription: "x")
                == "Unable to inspect this iOS App. Current version of LookInside app is too low.",
            "too high title"
        )
        expect(LKLaunchRules.serverVersionErrorTitle(errorCode: -1, localizedDescription: "Custom") == "Custom", "own description")
        expect(LKLaunchRules.serverVersionErrorTitle(errorCode: -1, localizedDescription: "") == "Unable to inspect this app.", "fallback title")
    }

    // MARK: - Helpers

    private static func decode(_ data: Data) -> HierarchyFile {
        do {
            return try LookinArchiveCoding.hierarchyFile(from: data)
        } catch {
            fail("decode failed: \(error)")
        }
    }

    private static func encode(_ file: HierarchyFile) -> Data {
        do {
            return try LookinArchiveCoding.data(of: file)
        } catch {
            fail("encode failed: \(error)")
        }
    }

    private static func expectError(_ data: Data, code: Int, _ message: String) {
        do {
            _ = try LookinArchiveCoding.hierarchyFile(from: data)
            fail("\(message): decoding should fail")
        } catch {
            let error = error as NSError
            expect(error.domain == LookinErrorDomain && error.code == code, "\(message): got \(error.domain) \(error.code)")
        }
    }

    /// "ClassName:key1,key2" for every archived object, keys sorted.
    private static func archiveShape(_ data: Data) -> Set<String> {
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              plist["$archiver"] as? String == "NSKeyedArchiver",
              let top = plist["$top"] as? [String: Any], top["root"] != nil,
              let objects = plist["$objects"] as? [Any]
        else {
            fail("not a keyed archive")
        }
        var shape = Set<String>()
        for case let object as [String: Any] in objects {
            guard let classReference = object["$class"] else { continue }
            guard let index = archiverUIDValue(classReference),
                  index < objects.count,
                  let classInfo = objects[index] as? [String: Any], let name = classInfo["$classname"] as? String
            else {
                fail("class reference without a name")
            }
            let keys = object.keys.filter { $0 != "$class" }.sorted().joined(separator: ",")
            shape.insert("\(name):\(keys)")
        }
        return shape
    }

    /// The index a keyed-archive UID refers to. The UID type has no public
    /// accessor; its description reads "<CFKeyedArchiverUID 0x…>{value = N}".
    private static func archiverUIDValue(_ uid: Any) -> Int? {
        let description = String(describing: uid)
        guard description.contains("CFKeyedArchiverUID"),
              let range = description.range(of: "value = ")
        else { return nil }
        return Int(description[range.upperBound...].prefix { $0.isNumber })
    }

    private static func expect(_ condition: Bool, _ message: String) {
        if !condition {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}
