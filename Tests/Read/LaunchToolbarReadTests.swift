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
        testLaunchDeviceGrouping()
        testLaunchDeviceSelection()
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
        var result = ReadScreenshotLookup.screenshots(
            forOids: [1, 2], solo: [1: soloA, 2: soloB], group: [2: groupB]
        )
        expect(result.solo == soloA && result.group == nil, "first oid with a screenshot wins, alone")

        result = ReadScreenshotLookup.screenshots(forOids: [3, 2], solo: [1: soloA, 2: soloB], group: [2: groupB])
        expect(result.solo == soloB && result.group == groupB, "both screenshots of the matching oid")

        result = ReadScreenshotLookup.screenshots(forOids: [9], solo: [1: soloA], group: nil)
        expect(result.solo == nil && result.group == nil, "no screenshot")

        result = ReadScreenshotLookup.screenshots(forOids: [2], solo: nil, group: [2: groupB])
        expect(result.solo == nil && result.group == groupB, "group only")
    }

    // MARK: - Toolbar

    private static func testToolbarIdentifiersKeepTheirValues() {
        let identifiers: [(String, String)] = [
            (toolbarIdentifierDimension, "0"), (toolbarIdentifierScale, "1"),
            (toolbarIdentifierSetting, "2"), (toolbarIdentifierReload, "3"),
            (toolbarIdentifierApp, "5"), (toolbarIdentifierAppInReadMode, "12"),
            (toolbarIdentifierAdd, "13"), (toolbarIdentifierRemove, "14"),
            (toolbarIdentifierConsole, "15"), (toolbarIdentifierRotation, "16"),
            (toolbarIdentifierMeasure, "17"), (toolbarIdentifierMessage, "18"),
            (toolbarIdentifierFastMode, "19"), (toolbarIdentifierSwiftUIMode, "20"),
        ]
        for (identifier, value) in identifiers {
            expect(identifier == value, "toolbar identifier \(value)")
        }
    }

    private static func testSteppingClamps() {
        expect(abs(ToolbarRules.stepped(0.5, by: ToolbarRules.step, lower: 0, upper: 1) - 0.6) < 1e-9, "step up")
        expect(ToolbarRules.stepped(0.95, by: ToolbarRules.step, lower: 0, upper: 1) == 1, "clamped high")
        expect(ToolbarRules.stepped(0.05, by: -ToolbarRules.step, lower: 0, upper: 1) == 0, "clamped low")
        expect(ToolbarRules.stepped(3, by: 0.1, lower: 0, upper: 1) == 1, "out of range value comes back in range")
    }

    private static func testAppsPopoverCopy() {
        var copy = ToolbarRules.appsPopoverCopy(source: .reloadButton, appCount: 0)
        expect(copy.title == "Connection lost" && copy.subtitle == "And no inspectable app was found", "reload, no apps")
        copy = ToolbarRules.appsPopoverCopy(source: .noConnectionTips, appCount: 1)
        expect(copy.title == "Connection lost" && copy.subtitle == "Click the screenshot below to Change App", "tips, one app")
        copy = ToolbarRules.appsPopoverCopy(source: .reloadButton, appCount: 3)
        expect(copy.subtitle == "Other 3 apps were found", "reload, several apps")
        copy = ToolbarRules.appsPopoverCopy(source: .appButton, appCount: 0)
        expect(copy.title == "No inspectable app was found" && copy.subtitle == nil, "app button, no apps")
        copy = ToolbarRules.appsPopoverCopy(source: .appButton, appCount: 1)
        expect(copy.title == "1 active app was found" && copy.subtitle == "Click the screenshot below to inspect", "app button, one app")
        copy = ToolbarRules.appsPopoverCopy(source: .appButton, appCount: 2)
        expect(copy.title == "2 active apps were found", "app button, several apps")
    }

    // MARK: - Launch

    private static func testLaunchAutoEnter() {
        expect(LaunchRules.canAutoEnter(requested: true, appCount: 1, onlyAppHasServerVersionError: false, isActivated: true), "auto enter")
        expect(!LaunchRules.canAutoEnter(requested: false, appCount: 1, onlyAppHasServerVersionError: false, isActivated: true), "not requested")
        expect(!LaunchRules.canAutoEnter(requested: true, appCount: 2, onlyAppHasServerVersionError: false, isActivated: true), "two apps")
        expect(!LaunchRules.canAutoEnter(requested: true, appCount: 0, onlyAppHasServerVersionError: false, isActivated: true), "no apps")
        expect(!LaunchRules.canAutoEnter(requested: true, appCount: 1, onlyAppHasServerVersionError: true, isActivated: true), "version error")
        expect(!LaunchRules.canAutoEnter(requested: true, appCount: 1, onlyAppHasServerVersionError: false, isActivated: false), "not activated")
    }

    private static func testLaunchServerVersionErrors() {
        // Learn More opens a page that exists: the in-app link helper only
        // shows a "links are disabled" alert, which 3.1.0 shipped with.
        expect(LaunchRules.serverVersionHelpURL(errorCode: LookinErrCode_ServerVersionTooLow).absoluteString == "https://lookinside-app.com/docs/update-server", "too low page")
        expect(LaunchRules.serverVersionHelpURL(errorCode: LookinErrCode_ServerVersionTooHigh).absoluteString == "https://lookinside-app.com/#cta", "too high page")
        expect(LaunchRules.serverVersionHelpURL(errorCode: LookinErrCode_Inner).absoluteString == "https://lookinside-app.com/#cta", "other errors use the too high page")
        expect(
            LaunchRules.serverVersionErrorTitle(errorCode: LookinErrCode_ServerVersionTooLow, localizedDescription: "x")
                == "Update LookInside Server to inspect this app.",
            "too low title"
        )
        expect(
            LaunchRules.serverVersionErrorTitle(errorCode: LookinErrCode_ServerVersionTooHigh, localizedDescription: "x")
                == "Update LookInside to inspect this app.",
            "too high title"
        )
        expect(LaunchRules.serverVersionAlertTitle(errorCode: LookinErrCode_ServerVersionTooLow, appName: "Notes") == "“Notes” uses an older LookInside Server.", "too low alert title")
        expect(LaunchRules.serverVersionAlertTitle(errorCode: LookinErrCode_ServerVersionTooHigh, appName: nil) == "This app uses a newer LookInside Server.", "too high alert title, no name")
        expect(LaunchRules.serverVersionErrorTitle(errorCode: -1, localizedDescription: "Custom") == "Custom", "own description")
        expect(LaunchRules.serverVersionErrorTitle(errorCode: -1, localizedDescription: "") == "Unable to inspect this app.", "fallback title")
    }

    // MARK: - Launch devices

    private static let iPhone = LaunchDeviceIdentity.reported(deviceDescription: "iPhone 17 Pro", osDescription: "iOS 26.4", deviceType: .simulator)
    private static let iPad = LaunchDeviceIdentity.reported(deviceDescription: "iPad Air", osDescription: "iPadOS 26.4", deviceType: .simulator)
    private static let mac = LaunchDeviceIdentity.reported(deviceDescription: "MacBook Pro", osDescription: "macOS 26.5", deviceType: .mac)
    private static let phoneOnUSB = LaunchDeviceIdentity.reported(deviceDescription: "Kai's iPhone", osDescription: "iOS 26.4", deviceType: .others)

    private static func entry(
        _ app: String,
        on device: LaunchDeviceIdentity?,
        origin: String,
        isConnectable: Bool = true
    ) -> LaunchDeviceListEntry<String> {
        LaunchDeviceListEntry(app: app, reportedDevice: device, originGroupKey: origin, isConnectable: isConnectable)
    }

    private static func groups(_ entries: [LaunchDeviceListEntry<String>]) -> [LaunchDeviceGroup<String>] {
        LaunchDeviceGrouping.groups(of: entries)
    }

    private static func testLaunchDeviceGrouping() {
        let byDevice = groups([
            entry("Notes", on: iPhone, origin: "simulator"),
            entry("Finder", on: mac, origin: "mac"),
            entry("Maps", on: iPhone, origin: "simulator", isConnectable: false),
        ])
        expect(byDevice.map(\.identity) == [iPhone, mac], "devices in the order their first app was found")
        expect(byDevice.first?.apps == ["Notes", "Maps"], "apps of one device stay together, in scan order")
        expect(byDevice.first?.connectableAppCount == 1, "only apps a click opens count as connectable")

        let sameNameOtherSystem = groups([
            entry("Notes", on: iPhone, origin: "simulator"),
            entry("Notes", on: .reported(deviceDescription: "iPhone 17 Pro", osDescription: "iOS 27.0", deviceType: .simulator), origin: "simulator"),
        ])
        expect(sameNameOtherSystem.count == 2, "the same device name on another OS is another device")

        let backgroundOnUSB = groups([
            entry("Mail", on: phoneOnUSB, origin: "usb:3"),
            entry("(background)", on: nil, origin: "usb:3", isConnectable: false),
        ])
        expect(backgroundOnUSB.count == 1 && backgroundOnUSB.first?.apps == ["Mail", "(background)"], "an app without info joins the only device on its origin")

        let twoSimulators = groups([
            entry("Notes", on: iPhone, origin: "simulator"),
            entry("Files", on: iPad, origin: "simulator"),
            entry("(background)", on: nil, origin: "simulator", isConnectable: false),
        ])
        expect(twoSimulators.map(\.identity) == [iPhone, iPad, .unidentified(originGroupKey: "simulator")], "an app without info gets its own device when its origin has several")

        let onlyUnknown = groups([
            entry("(background)", on: nil, origin: "usb:3", isConnectable: false),
            entry("(version error)", on: nil, origin: "usb:3", isConnectable: false),
            entry("(other device)", on: nil, origin: "usb:4", isConnectable: false),
        ])
        expect(onlyUnknown.map(\.identity) == [.unidentified(originGroupKey: "usb:3"), .unidentified(originGroupKey: "usb:4")], "apps without info are grouped per origin")

        expect(groups([]).isEmpty, "no apps, no devices")
    }

    private static func testLaunchDeviceSelection() {
        var selection = LaunchDeviceSelection()
        selection.update(with: groups([]))
        expect(selection.selectedDevice == nil, "nothing to select")

        selection.update(with: groups([
            entry("(background)", on: iPhone, origin: "simulator", isConnectable: false),
            entry("Finder", on: mac, origin: "mac"),
        ]))
        expect(selection.selectedDevice == mac, "the first device with an app a click opens is selected")

        selection.update(with: groups([
            entry("Notes", on: iPhone, origin: "simulator"),
            entry("Finder", on: mac, origin: "mac"),
        ]))
        expect(selection.selectedDevice == mac, "a device appearing earlier does not take the selection")

        var onlyBackground = LaunchDeviceSelection()
        onlyBackground.update(with: groups([entry("(background)", on: iPhone, origin: "simulator", isConnectable: false)]))
        expect(onlyBackground.selectedDevice == iPhone, "with no app a click opens, the first device is selected")

        let threeDevices = groups([
            entry("Notes", on: iPhone, origin: "simulator"),
            entry("Files", on: iPad, origin: "simulator"),
            entry("Finder", on: mac, origin: "mac"),
        ])
        var userChoice = LaunchDeviceSelection()
        userChoice.update(with: threeDevices)
        userChoice.userDidSelect(iPad)
        userChoice.update(with: threeDevices)
        expect(userChoice.selectedDevice == iPad, "the user's device stays selected across scans")

        userChoice.update(with: groups([
            entry("Notes", on: iPhone, origin: "simulator"),
            entry("Finder", on: mac, origin: "mac"),
        ]))
        expect(userChoice.selectedDevice == mac, "the device after a vanished one takes over")

        userChoice.update(with: threeDevices)
        expect(userChoice.selectedDevice == iPad, "the user's device is selected again when it comes back")

        var lastVanishes = LaunchDeviceSelection()
        lastVanishes.update(with: threeDevices)
        lastVanishes.userDidSelect(mac)
        lastVanishes.update(with: groups([
            entry("Notes", on: iPhone, origin: "simulator"),
            entry("Files", on: iPad, origin: "simulator"),
        ]))
        expect(lastVanishes.selectedDevice == iPad, "when the last device vanishes, the one before it takes over")

        var everythingVanishes = LaunchDeviceSelection()
        everythingVanishes.update(with: threeDevices)
        everythingVanishes.update(with: groups([]))
        expect(everythingVanishes.selectedDevice == nil, "no devices left, nothing selected")
        everythingVanishes.update(with: groups([entry("Finder", on: mac, origin: "mac")]))
        expect(everythingVanishes.selectedDevice == mac, "a device found after an empty scan is selected")
    }

    // MARK: - Helpers

    private static func decode(_ data: Data) -> HierarchyFile {
        do {
            return try ArchiveCoding.hierarchyFile(from: data)
        } catch {
            fail("decode failed: \(error)")
        }
    }

    private static func encode(_ file: HierarchyFile) -> Data {
        do {
            return try ArchiveCoding.data(of: file)
        } catch {
            fail("encode failed: \(error)")
        }
    }

    private static func expectError(_ data: Data, code: Int, _ message: String) {
        do {
            _ = try ArchiveCoding.hierarchyFile(from: data)
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
