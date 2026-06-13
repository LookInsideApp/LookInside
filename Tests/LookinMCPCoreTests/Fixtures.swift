import Foundation
import CoreGraphics
import LookinCore

/// Deterministic in-memory fixtures so tests don't need a `.lookin` archive on
/// disk. The shapes mirror what `LookinHierarchyInfo` looks like after
/// deserialization from a real device, but every field that tests touch is
/// directly set on the ObjC objects.
enum Fixtures {
    static func simpleScreen() -> LookinHierarchyInfo {
        let window = item(class: "UIWindow", frame: CGRect(x: 0, y: 0, width: 390, height: 844), oid: 1)
        let container = item(class: "UIView", frame: CGRect(x: 0, y: 88, width: 390, height: 700), oid: 2)
        let label = item(class: "UILabel", frame: CGRect(x: 16, y: 16, width: 358, height: 22), oid: 3,
                         attributes: [("text", "Hello"), ("accessibilityLabel", "Hello")])
        let smallButton = item(class: "UIButton", frame: CGRect(x: 100, y: 80, width: 20, height: 20), oid: 4,
                               attributes: [("accessibilityLabel", "")])
        let secureField = item(class: "UITextField", frame: CGRect(x: 16, y: 200, width: 358, height: 44), oid: 5,
                               attributes: [("text", "supersecret"), ("isSecureTextEntry", NSNumber(value: true))])
        let offscreen = item(class: "UILabel", frame: CGRect(x: 5000, y: 5000, width: 100, height: 22), oid: 6,
                             attributes: [("text", "Way off")])
        container.subitems = [label, smallButton, secureField, offscreen]
        window.subitems = [container]
        let info = LookinHierarchyInfo()
        info.displayItems = [window]
        info.appInfo = makeApp()
        info.serverVersion = 9
        return info
    }

    static func makeApp(name: String = "FixtureApp",
                        bundleIdentifier: String = "test.fixture") -> LookinAppInfo {
        let app = LookinAppInfo()
        app.appName = name
        app.appBundleIdentifier = bundleIdentifier
        app.deviceDescription = "iPhone 15 Pro"
        app.osDescription = "iOS 17.4"
        app.screenWidth = 390; app.screenHeight = 844; app.screenScale = 3
        app.serverVersion = 9
        return app
    }

    static func item(class className: String,
                     frame: CGRect,
                     oid: unsignedlong,
                     attributes: [(String, Any)] = []) -> LookinDisplayItem {
        let item = LookinDisplayItem()
        item.frame = frame
        item.bounds = CGRect(origin: .zero, size: frame.size)
        item.alpha = 1
        let view = LookinObject()
        view.oid = oid
        view.classChainList = [className, "UIView", "NSObject"]
        item.viewObject = view
        if !attributes.isEmpty {
            let group = LookinAttributesGroup()
            group.identifier = "lookin.fixture"
            let section = LookinAttributesSection()
            section.identifier = "fixture"
            section.attributes = attributes.map { (id, val) in
                let a = LookinAttribute()
                a.identifier = id
                a.value = val
                return a
            }
            group.attrSections = [section]
            item.attributesGroupList = [group]
        }
        return item
    }
}

// Swift can't see `unsigned long` from ObjC headers as a literal type alias; bridge it.
typealias unsignedlong = UInt
