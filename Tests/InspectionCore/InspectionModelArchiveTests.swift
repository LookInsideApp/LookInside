import AppKit
import LookInsideInspectionCore
import Testing

@MainActor
struct InspectionModelArchiveTests {
    @Test func `full hierarchy preserves pixels object identities attributes and node relationships`() throws {
        let windowObject = object(identifier: 101, className: "NSWindow")
        let viewObject = object(identifier: 202, className: "NSButton")
        let layerObject = object(identifier: 303, className: "CALayer")
        let guideObject = object(identifier: 404, className: "NSLayoutGuide")
        let root = LookinDisplayItem()
        root.nodeKind = .window
        root.windowObject = windowObject
        root.representedAsKeyWindow = true
        root.frame = CGRect(x: 0, y: 0, width: 400, height: 300)
        root.bounds = CGRect(x: 7, y: 9, width: 400, height: 300)
        root.isFlipped = true
        root.backgroundColor = NSColor(srgbRed: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        let child = LookinDisplayItem()
        child.nodeKind = .view
        child.viewObject = viewObject
        child.layerObject = layerObject
        child.hostWindowControllerObject = windowObject
        child.frame = CGRect(x: 20, y: 40, width: 80, height: 30)
        child.bounds = CGRect(x: 2, y: 3, width: 80, height: 30)
        child.alpha = 0.5
        child.soloScreenshot = try image()
        child.groupScreenshot = child.soloScreenshot
        child.customDisplayTitle = "Action"
        child.danceuiSource = "Example.swift:42"
        let guide = LookinDisplayItem()
        guide.nodeKind = .layoutGuide
        guide.kindObject = guideObject
        guide.representsSystemManagedNode = true
        let cell = LookinDisplayItem()
        cell.nodeKind = .cell
        cell.kindObject = object(identifier: 505, className: "NSButtonCell")
        let virtualNode = LookinDisplayItem()
        virtualNode.nodeKind = .custom
        virtualNode.customInfo = LookinCustomDisplayItemInfo()
        virtualNode.customInfo.isSwiftUI = true
        virtualNode.customInfo.swiftUIDisplayItemID = "swiftui:202:1"
        virtualNode.customInfo.frameInWindow = NSValue(rect: child.frame)
        virtualNode.customInfo.title = "Text"
        child.subitems = [guide, cell, virtualNode]
        root.subitems = [child]
        let constraint = LookinAutoLayoutConstraint()
        constraint.constraintOid = 606
        constraint.firstItem = viewObject
        constraint.firstItemType = .view
        constraint.secondItem = guideObject
        constraint.secondItemType = .layoutGuide
        constraint.constant = 17
        let attribute = LookinAttribute()
        attribute.identifier = "layout.constraints"
        attribute.value = [constraint]
        attribute.extraValue = ["mode": "required"]
        attribute.customSetterID = "setter:202"
        let section = LookinAttributesSection()
        section.identifier = "layout"
        section.attributes = [attribute]
        let group = LookinAttributesGroup()
        group.identifier = "constraints"
        group.attrSections = [section]
        group.isSwiftUIGroup = true
        child.attributesGroupList = [group]
        let event = LookinEventHandler()
        event.recognizerOid = 707
        event.gestureRecognizerIsEnabled = true
        event.eventName = "Tap"
        child.eventHandlers = [event]
        let hierarchy = LookinHierarchyInfo()
        hierarchy.displayItems = [root]
        hierarchy.appInfo = LookinAppInfo()
        hierarchy.appInfo.appInfoIdentifier = 808
        hierarchy.appInfo.processIdentifier = 12345
        hierarchy.appInfo.processStartIdentifier = "1700000000:123456"
        child.soloScreenshotRegion = CGRect(x: 1, y: 2, width: 6, height: 4)
        child.groupScreenshotRegion = CGRect(x: 3, y: 4, width: 8, height: 5)
        hierarchy.serverVersion = 900
        hierarchy.colorAlias = ["accent": [0.2, 0.4, 0.6, 0.8]]
        hierarchy.collapsedClassList = ["NSButton"]

        let originalImageData = try #require(child.soloScreenshot.tiffRepresentation)
        let originalPixels = try #require(NSBitmapImageRep(data: originalImageData))
        #expect(originalPixels.colorAt(x: 3, y: 2)?.redComponent == 1)
        let archive = try InspectionModelArchive.encode(hierarchy)
        let decoded = try #require(InspectionModelArchive.decode(archive) as? LookinHierarchyInfo)
        let decodedRoot = try #require(decoded.displayItems.first)
        let decodedChild = try #require(decodedRoot.subitems.first)
        let decodedGuide = try #require(decodedChild.subitems.first)
        let decodedAttribute = try #require(decodedChild.attributesGroupList.first?.attrSections.first?.attributes.first)
        let decodedConstraint = try #require((decodedAttribute.value as? [LookinAutoLayoutConstraint])?.first)
        #expect(decodedRoot !== root)
        #expect(decodedChild.super === decodedRoot)
        #expect(decodedGuide.super === decodedChild)
        #expect(decodedAttribute.targetDisplayItem === decodedChild)
        #expect(decodedConstraint.firstItem === decodedChild.viewObject)
        #expect(decodedConstraint.secondItem === decodedGuide.kindObject)
        #expect(decodedChild.hostWindowControllerObject === decodedRoot.windowObject)
        #expect(decodedRoot.isFlipped)
        #expect(decodedRoot.bounds == root.bounds)
        #expect(decodedRoot.backgroundColor.usingColorSpace(.sRGB)?.alphaComponent == 0.8)
        #expect(decodedChild.calculateFrameToRoot() == child.calculateFrameToRoot())
        #expect(decodedChild.layerObject.oid == 303)
        #expect(decodedGuide.kindObject.oid == 404)
        #expect(decodedChild.subitems[1].resolvedNodeKind() == .cell)
        #expect(decodedChild.subitems[2].customInfo.swiftUIDisplayItemID == "swiftui:202:1")
        #expect(decodedChild.subitems[2].customInfo.isSwiftUI)
        #expect(decodedConstraint.constraintOid == 606)
        #expect(decodedConstraint.constant == 17)
        #expect(decodedAttribute.customSetterID == "setter:202")
        #expect(decodedChild.eventHandlers.first?.recognizerOid == 707)
        #expect(decodedChild.attributesGroupList.first?.isSwiftUIGroup == true)
        #expect(decodedChild.danceuiSource == "Example.swift:42")
        #expect(decoded.appInfo.appInfoIdentifier == 808)
        #expect(decoded.appInfo.processIdentifier == 12345)
        #expect(decoded.appInfo.processStartIdentifier == "1700000000:123456")
        #expect(decodedChild.soloScreenshotRegion == child.soloScreenshotRegion)
        #expect(decodedChild.groupScreenshotRegion == child.groupScreenshotRegion)
        #expect(decoded.collapsedClassList == ["NSButton"])
        #expect(decoded.serverVersion == 900)
        let decodedImageData = try #require(decodedChild.soloScreenshot.tiffRepresentation)
        let decodedPixels = try #require(NSBitmapImageRep(data: decodedImageData))
        #expect(decodedPixels.pixelsWide == 8)
        #expect(decodedPixels.pixelsHigh == 6)
        #expect(decodedPixels.colorAt(x: 3, y: 2)?.redComponent == 1)
        #expect(decodedChild.groupScreenshot != nil)
        #expect(child.screenshotEncodeType == .none)
        #expect(NSApp == nil)
    }

    @Test func `invalid archives fail without publishing a partial model`() {
        #expect(throws: (any Error).self) {
            try InspectionModelArchive.decode(Data("not an archive".utf8))
        }
    }

    private func object(identifier: UInt, className: String) -> LookinObject {
        let object = LookinObject()
        object.oid = identifier
        object.classChainList = [className, "NSObject"]
        return object
    }

    private func image() throws -> NSImage {
        let pixels = try #require(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 8, pixelsHigh: 6,
                                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        for rowIndex in 0 ..< 6 {
            for columnIndex in 0 ..< 8 {
                pixels.setColor(NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1), atX: columnIndex, y: rowIndex)
            }
        }
        let result = NSImage(size: NSSize(width: 8, height: 6))
        result.addRepresentation(pixels)
        return result
    }
}
