import AppKit
import Foundation

/// Coverage for the Dashboard rules that decide what is sent to the
/// inspected app and what the cards show, compiled with LookinCore alone.
///
/// The modification payloads are compared, as keyed archives (the bytes
/// that go over the wire), with payloads built the way the Objective-C
/// `DashboardViewController` built them before the Swift rewrite. The
/// enum lists are compared with a dump of the Objective-C
/// `EnumListRegistry` (`Fixtures/enum-list-registry.json`).
@main
struct DashboardTests {
    static func main() {
        let fixturesDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Fixtures", isDirectory: true)

        testInbuiltPayloadForEveryBlueprintAttribute()
        testInbuiltPayloadWithoutSetter()
        testCustomPayload()
        testCustomPayloadWithoutSetter()
        testEditedGeometryValues()
        testNumberValueClampsOpacity()
        testRectEditRevertDetection()
        testConstraintOrder()
        testEnumListRegistryMatchesObjectiveC(fixturesDirectory: fixturesDirectory)
        testJSONAttributeTree()
        print("Dashboard tests passed")
    }

    // MARK: - Modification payloads

    private static let clientVersion = "2.4.0"

    private static func makeItem() -> DisplayItem {
        func object(_ oid: UInt) -> InspectedObject {
            let object = InspectedObject()
            object.oid = oid
            return object
        }
        let item = DisplayItem()
        item.viewObject = object(11)
        item.layerObject = object(22)
        item.windowObject = object(33)
        item.cellObject = object(44)
        return item
    }

    /// `-[LKDashboardViewController modifyInbuiltAttribute:newValue:]`
    /// before the rewrite.
    private static func objectiveCInbuiltPayload(attribute: InspectedAttribute, newValue: Any?) -> AttributeModification {
        let modifyingItem = attribute.targetDisplayItem!
        let modification = AttributeModification()
        modification.clientReadableVersion = clientVersion
        switch DashboardBlueprint.targetKind(forAttrID: attribute.identifier) {
        case .view:
            modification.targetOid = modifyingItem.viewObject?.oid ?? 0
        case .window:
            modification.targetOid = modifyingItem.windowObject?.oid ?? 0
        case .cell:
            modification.targetOid = modifyingItem.cellObject?.oid ?? 0
        case .layer:
            modification.targetOid = modifyingItem.layerObject?.oid ?? 0
        @unknown default:
            fail("unknown target kind")
        }
        modification.setterSelector = DashboardBlueprint.setter(withAttrID: attribute.identifier)
        modification.attrType = attribute.attrType
        modification.value = newValue
        return modification
    }

    private static func archive(_ object: Any) -> Data {
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
        } catch {
            fail("cannot archive \(object): \(error)")
        }
    }

    private static func sampleValue(for type: LookinAttrType) -> Any {
        switch type {
        case .cgRect: return NSValue(rect: NSRect(x: 1, y: 2, width: 3, height: 4))
        case .cgSize: return NSValue(size: NSSize(width: 5, height: 6))
        case .cgPoint: return NSValue(point: NSPoint(x: 7, y: 8))
        case .uiEdgeInsets: return NSValue(edgeInsets: NSEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
        case .uiColor: return [NSNumber(value: 0.1), NSNumber(value: 0.2), NSNumber(value: 0.3), NSNumber(value: 1)]
        case .nsString: return "text"
        case .BOOL: return NSNumber(value: true)
        default: return NSNumber(value: 2.5)
        }
    }

    /// Every attribute the blueprint knows a setter for gets the same
    /// payload as before: target object by kind, setter, type and value.
    private static func testInbuiltPayloadForEveryBlueprintAttribute() {
        // The attributes hold the item weakly; it lives to the end of the test.
        let item = makeItem()
        defer { withExtendedLifetime(item) {} }
        var checked = 0
        var kinds = Set<Int>()
        for groupID in DashboardBlueprint.groupIDs() ?? [] {
            for sectionID in DashboardBlueprint.sectionIDs(forGroupID: groupID) ?? [] {
                for attrID in DashboardBlueprint.attrIDs(forSectionID: sectionID) ?? [] {
                    guard DashboardBlueprint.setter(withAttrID: attrID) != nil else { continue }
                    let attribute = InspectedAttribute()
                    attribute.identifier = attrID
                    attribute.attrType = DashboardBlueprint.objectAttrType(withAttrID: attrID)
                    attribute.targetDisplayItem = item
                    let newValue = sampleValue(for: attribute.attrType)

                    guard let payload = DashboardModification.inbuilt(attribute: attribute, newValue: newValue, clientReadableVersion: clientVersion) else {
                        fail("\(attrID) has a setter but no payload")
                    }
                    let expected = objectiveCInbuiltPayload(attribute: attribute, newValue: newValue)
                    expect(archive(payload) == archive(expected), "\(attrID): payload differs from the Objective-C one")
                    expect(payload.targetOid != 0, "\(attrID): no target object")
                    kinds.insert(DashboardBlueprint.targetKind(forAttrID: attrID).rawValue)
                    checked += 1
                }
            }
        }
        expect(checked > 50, "only \(checked) editable attributes found in the blueprint")
        expect(kinds.contains(LookinAttrTargetKind.view.rawValue) && kinds.contains(LookinAttrTargetKind.layer.rawValue),
               "the editable attributes cover neither views nor layers: \(kinds)")
    }

    private static func testInbuiltPayloadWithoutSetter() {
        let attribute = InspectedAttribute()
        attribute.identifier = LookinAttr_Class_Class_Class
        attribute.attrType = .customObj
        attribute.targetDisplayItem = makeItem()
        expect(DashboardModification.inbuilt(attribute: attribute, newValue: nil, clientReadableVersion: clientVersion) == nil,
               "an attribute without a setter must not be sent")
    }

    private static func testCustomPayload() {
        let attribute = InspectedAttribute()
        attribute.identifier = LookinAttr_UserCustom
        attribute.attrType = .double
        attribute.customSetterID = "setter-7"
        let newValue = NSNumber(value: 3.25)

        guard let payload = DashboardModification.custom(attribute: attribute, newValue: newValue) else {
            fail("a custom attribute with a setter has no payload")
        }
        // -[LKDashboardViewController modifyCustomAttribute:newValue:]
        let expected = CustomAttributeModification()
        expected.customSetterID = attribute.customSetterID
        expected.attrType = attribute.attrType
        expected.value = newValue
        expect(archive(payload) == archive(expected), "custom payload differs from the Objective-C one")
    }

    private static func testCustomPayloadWithoutSetter() {
        let attribute = InspectedAttribute()
        attribute.identifier = LookinAttr_UserCustom
        attribute.attrType = .nsString
        expect(DashboardModification.custom(attribute: attribute, newValue: "x") == nil,
               "a read-only custom attribute must not be sent")
        attribute.customSetterID = ""
        expect(DashboardModification.custom(attribute: attribute, newValue: "x") == nil,
               "an empty setter id must not be sent")
    }

    // MARK: - Edited values

    private static func testEditedGeometryValues() {
        let rect = NSRect(x: 1, y: 2, width: 3, height: 4)
        expect(DashboardModification.rect(rect, replacingField: 0, with: 9) == NSRect(x: 9, y: 2, width: 3, height: 4), "rect x")
        expect(DashboardModification.rect(rect, replacingField: 1, with: 9) == NSRect(x: 1, y: 9, width: 3, height: 4), "rect y")
        expect(DashboardModification.rect(rect, replacingField: 2, with: 9) == NSRect(x: 1, y: 2, width: 9, height: 4), "rect width")
        expect(DashboardModification.rect(rect, replacingField: 3, with: 9) == NSRect(x: 1, y: 2, width: 3, height: 9), "rect height")
        expect(DashboardModification.rect(rect, replacingField: 4, with: 9) == nil, "rect field out of range")

        let insets = NSEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        let edited = DashboardModification.insets(insets, replacingField: 2, with: 7)
        expect(edited.map { $0.top == 1 && $0.left == 2 && $0.bottom == 7 && $0.right == 4 } == true, "insets bottom")
        expect(edited.map { DashboardModification.insetsDiffer(insets, $0) } == true, "edited insets differ")
        expect(!DashboardModification.insetsDiffer(insets, insets), "equal insets do not differ")

        expect(DashboardModification.point(NSPoint(x: 1, y: 2), replacingField: 1, with: 5) == NSPoint(x: 1, y: 5), "point y")
        expect(DashboardModification.size(NSSize(width: 1, height: 2), replacingField: 0, with: 5) == NSSize(width: 5, height: 2), "size width")

        // The value sent for a rect edit is the NSValue the Objective-C view
        // built with +valueWithRect:.
        // The attribute holds its item weakly; keep the item alive.
        let item = makeItem()
        withExtendedLifetime(item) {
            let attribute = InspectedAttribute()
            attribute.identifier = LookinAttr_Layout_Frame_Frame
            attribute.attrType = .cgRect
            attribute.targetDisplayItem = item
            let newRect = DashboardModification.rect(rect, replacingField: 2, with: 30)!
            let payload = DashboardModification.inbuilt(attribute: attribute, newValue: NSValue(rect: newRect), clientReadableVersion: clientVersion)!
            let expected = objectiveCInbuiltPayload(attribute: attribute, newValue: NSValue(rect: NSRect(x: 1, y: 2, width: 30, height: 4)))
            expect(payload.targetOid != 0, "frame edit has no target")
            expect(archive(payload) == archive(expected), "frame edit payload differs from the Objective-C one")
        }

        expect(DashboardModification.boolValue(isOn: true) == NSNumber(value: true), "switch on")
        expect(DashboardModification.boolValue(isOn: false) == NSNumber(value: false), "switch off")
    }

    private static func testNumberValueClampsOpacity() {
        let opacity = InspectedAttribute()
        opacity.identifier = LookinAttr_ViewLayer_Visibility_Opacity
        opacity.value = NSNumber(value: 0.5)
        expect(DashboardModification.numberValue(NSNumber(value: 1.7), for: opacity) == NSNumber(value: 1.0), "opacity above 1")
        expect(DashboardModification.numberValue(NSNumber(value: -0.2), for: opacity) == NSNumber(value: 0.0), "opacity below 0")
        expect(DashboardModification.numberValue(NSNumber(value: 0.5), for: opacity) == nil, "unchanged opacity")

        let shadowOpacity = InspectedAttribute()
        shadowOpacity.identifier = LookinAttr_ViewLayer_Shadow_Opacity
        shadowOpacity.value = NSNumber(value: 1.0)
        expect(DashboardModification.numberValue(NSNumber(value: 4), for: shadowOpacity) == nil, "shadow opacity clamps to the unchanged 1")

        let radius = InspectedAttribute()
        radius.identifier = LookinAttr_ViewLayer_Corner_Radius
        radius.value = NSNumber(value: 4)
        expect(DashboardModification.numberValue(NSNumber(value: 12), for: radius) == NSNumber(value: 12), "radius is not clamped")
        expect(DashboardModification.numberValue(NSNumber(value: 4), for: radius) == nil, "unchanged radius")
    }

    private static func testRectEditRevertDetection() {
        let old = NSRect(x: 0, y: 0, width: 10, height: 10)
        let expected = NSRect(x: 0, y: 0, width: 20, height: 10)
        expect(DashboardModification.rectEditWasReverted(old: old, expected: expected, current: NSRect(x: 0.05, y: 0, width: 10, height: 10)),
               "the app set the frame back")
        expect(!DashboardModification.rectEditWasReverted(old: old, expected: expected, current: expected), "the edit held")
        expect(!DashboardModification.rectEditWasReverted(old: old, expected: old, current: old), "an edit to the same rect")
    }

    // MARK: - Constraints

    private static func testConstraintOrder() {
        func constraint(effective: Bool, type: LookinConstraintItemType, attribute: Int, constant: CGFloat) -> AutoLayoutConstraint {
            let constraint = AutoLayoutConstraint()
            constraint.effective = effective
            constraint.firstItemType = type
            constraint.firstAttribute = attribute
            constraint.constant = constant
            return constraint
        }
        let a = constraint(effective: false, type: .view, attribute: 1, constant: 1)
        let b = constraint(effective: true, type: .layoutGuide, attribute: 2, constant: 2)
        let c = constraint(effective: true, type: .view, attribute: 7, constant: 3)
        let d = constraint(effective: true, type: .view, attribute: 3, constant: 4)
        let e = constraint(effective: true, type: .view, attribute: 3, constant: 5)
        let sorted = DashboardConstraintOrder.sorted([a, b, c, d, e]).map(\.constant)
        expect(sorted == [4, 5, 3, 2, 1], "constraint order: \(sorted)")
    }

    // MARK: - Enum lists

    private static func testEnumListRegistryMatchesObjectiveC(fixturesDirectory: URL) {
        let url = fixturesDirectory.appendingPathComponent("enum-list-registry.json")
        guard let data = try? Data(contentsOf: url),
              let fixture = try? JSONSerialization.jsonObject(with: data) as? [String: [[Any]]]
        else {
            fail("cannot read \(url.path)")
        }
        let registry = EnumListRegistry.shared
        expect(Set(registry.allEnumNames) == Set(fixture.keys),
               "enum list names differ: \(Set(registry.allEnumNames).symmetricDifference(fixture.keys).sorted())")
        for (name, expectedItems) in fixture {
            let items = registry.items(forEnumName: name) ?? []
            let actual = items.map { [$0.desc, $0.value, $0.availableOSVersion] as [AnyHashable] }
            let expected = expectedItems.map { item in
                [item[0] as! String, (item[1] as! NSNumber).intValue, (item[2] as! NSNumber).intValue] as [AnyHashable]
            }
            expect(actual == expected, "\(name) differs from the Objective-C list")
        }
        expect(registry.desc(forEnumName: "NSLineBreakStrategy", value: 0xFFFF) == "NSLineBreakStrategyStandard", "hex value")
        expect(registry.desc(forEnumName: "NSWindowLevel", value: 3) == "NSFloatingWindowLevel", "first case wins for a shared value")
        expect(registry.desc(forEnumName: "NSWindowLevel", value: 999) == nil, "unknown value")
        expect(registry.items(forEnumName: "NoSuchEnum") == nil, "unknown list")
    }

    // MARK: - JSON attribute

    private static func testJSONAttributeTree() {
        let json = #"[{"title":"a","desc":"1","details":[{"title":"a.1"},{"title":"a.2","details":[{"title":"a.2.x"}]}]},{"title":"b"},7]"#
        guard let roots = JSONAttributeItem.rootItems(fromJSON: json) else {
            fail("valid JSON gave no items")
        }
        expect(roots.count == 2, "non-object entries are skipped")
        var flat = JSONAttributeItem.flatItems(of: roots)
        expect(flat.map { $0.titleText ?? "" } == ["a", "a.1", "a.2", "a.2.x", "b"], "flat order")
        expect(flat.map(\.indentation) == [0, 1, 1, 2, 0], "indentation")
        expect(flat[0].desc == "1" && flat[1].desc == nil, "descriptions")

        flat[2].expanded = false
        flat = JSONAttributeItem.flatItems(of: roots)
        expect(flat.map { $0.titleText ?? "" } == ["a", "a.1", "a.2", "b"], "collapsed item hides its details")

        expect(JSONAttributeItem.rootItems(fromJSON: nil) == nil, "nil JSON")
        expect(JSONAttributeItem.rootItems(fromJSON: #"{"title":"a"}"#) == nil, "a JSON object is not a list")
    }

    // MARK: - Helpers

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}
