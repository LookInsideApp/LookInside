import AppKit
import Foundation
import QuartzCore

/// Coverage for turning a decoded Core Animation archive into the
/// inspector's model: numbering, rendering and conversion together, on
/// archives written by QuartzCore's own `CAEncodeLayerTree`.
///
/// Orientation is again what a wrong answer would hide behind a plausible
/// picture. A dumped window is full of flipped subtrees, and two places read
/// the flip: the renderer, which must draw every layer upright, and the
/// node geometry, from which the inspector places each node inside its
/// parent. Both are checked against markers in known places.
@main
struct CoreAnimationArchiveConverterTests {
    static func main() {
        testEveryLayerBecomesALayerNode()
        testNodeGeometryFollowsTheLayers()
        testNodesReportTheirCumulativeFlip()
        testRootArchivedOutOfAFlippedSuperlayerRendersUpright()
        testScreenshotsAreFiledUnderTheirNodes()
        testCancelledRecoveryThrows()
        testLayerRowsFollowTheServerTypes()
        testClassCardEndsAtCALayer()
        testAppNameComesFromTheFileName()
        print("Core Animation archive converter tests passed")
    }

    // MARK: - Tree shape

    private static func testEveryLayerBecomesALayerNode() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        let firstLayer = makingLayer(CGRect(x: 0, y: 0, width: 50, height: 50))
        let secondLayer = makingLayer(CGRect(x: 50, y: 50, width: 50, height: 50))
        let nestedLayer = makingLayer(CGRect(x: 5, y: 5, width: 10, height: 10))
        firstLayer.addSublayer(nestedLayer)
        rootLayer.addSublayer(firstLayer)
        rootLayer.addSublayer(secondLayer)

        let file = convertedFile(of: rootLayer)
        let items = flattened(file.hierarchyInfo?.displayItems ?? [])
        expect(items.count == 4, "every layer should become a node, got \(items.count)")
        expect(items.allSatisfy { $0.nodeKind == .layer }, "every node should be a layer node")
        expect(items.allSatisfy(\.shouldCaptureImage), "every node built in memory must opt into screenshots")
        let objectIdentifiers = items.compactMap { $0.layerObject?.oid }
        expect(objectIdentifiers == [1, 2, 3, 4], "nodes should be numbered depth first from 1, got \(objectIdentifiers)")
        let root = file.hierarchyInfo?.displayItems?.first
        expect(root?.subitems?.count == 2, "the root should keep both sublayers")
        expect(root?.subitems?.first?.subitems?.count == 1, "the nested layer should stay under its parent")
    }

    private static func testNodeGeometryFollowsTheLayers() {
        let rootLayer = makingLayer(CGRect(x: 30, y: 40, width: 100, height: 80))
        let sublayer = makingLayer(CGRect(x: 10, y: 20, width: 30, height: 15))
        sublayer.bounds = CGRect(x: 2, y: 3, width: 30, height: 15)
        rootLayer.addSublayer(sublayer)

        let file = convertedFile(of: rootLayer)
        guard let root = file.hierarchyInfo?.displayItems?.first, let child = root.subitems?.first else {
            fail("the tree should have a root and a child")
        }
        expect(root.frame == CGRect(x: 0, y: 0, width: 100, height: 80), "the root should start at the origin, got \(root.frame)")
        expect(child.frame == sublayer.frame, "a node's frame should be its layer's, got \(child.frame)")
        expect(child.bounds == sublayer.bounds, "a node's bounds should be its layer's, got \(child.bounds)")
    }

    /// The inspector reads `isFlipped` as "this node's own space runs top
    /// down" when it places the node's children. A layer's own flag flips
    /// relative to its superlayer, so a flipped layer inside a flipped layer
    /// is back to bottom up: its node must say unflipped, and its child must
    /// land at the bottom of it.
    private static func testNodesReportTheirCumulativeFlip() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        let flippedLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        flippedLayer.isGeometryFlipped = true
        let flippedAgainLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        flippedAgainLayer.isGeometryFlipped = true
        let markerLayer = makingLayer(CGRect(x: 0, y: 0, width: 10, height: 10))
        flippedAgainLayer.addSublayer(markerLayer)
        flippedLayer.addSublayer(flippedAgainLayer)
        rootLayer.addSublayer(flippedLayer)

        let items = flattened(convertedFile(of: rootLayer).hierarchyInfo?.displayItems ?? [])
        guard items.count == 4 else { fail("the tree should have four nodes, got \(items.count)") }
        expect(!items[0].isFlipped, "the root runs bottom up")
        expect(items[1].isFlipped, "a flipped layer runs top down")
        expect(!items[2].isFlipped, "a flipped layer inside a flipped layer runs bottom up again")
        // Inside an unflipped 100-point node, a child at y = 0 sits at the
        // bottom in the inspector's bottom-up root space.
        let markerFrame = items[3].calculateFrameToRoot()
        expect(markerFrame.origin.y == 0, "the marker should land at the bottom of its unflipped parent, got \(markerFrame)")
    }

    /// The archive keeps none of the root's superlayers; their flip survives
    /// only as the archive's `geometryFlipped` entry. A band pinned at y = 0
    /// of a root that sat in a flipped superlayer was at the top on screen,
    /// and must be at the top of the root's image.
    private static func testRootArchivedOutOfAFlippedSuperlayerRendersUpright() {
        let flippedSuperlayer = CALayer()
        flippedSuperlayer.isGeometryFlipped = true
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        rootLayer.backgroundColor = CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
        let bandLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 20))
        bandLayer.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        rootLayer.addSublayer(bandLayer)
        flippedSuperlayer.addSublayer(rootLayer)

        let file = convertedFile(of: rootLayer)
        guard let groupImage = file.groupScreenshots?[NSNumber(value: 1)],
              let bitmap = NSBitmapImageRep(data: groupImage)
        else { fail("the root should have a group image") }
        let topColor = bitmap.colorAt(x: bitmap.pixelsWide / 2, y: 1)
        let bottomColor = bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh - 2)
        expect(isRed(topColor), "the band should be at the top of the image, found \(String(describing: topColor)) there")
        expect(isBlue(bottomColor), "the root's background should fill the bottom, found \(String(describing: bottomColor)) there")
        expect(file.hierarchyInfo?.displayItems?.first?.isFlipped == true, "the root node should keep the flip it was archived with")
    }

    // MARK: - Screenshots

    private static func testScreenshotsAreFiledUnderTheirNodes() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 60, height: 60))
        let paintedLayer = makingLayer(CGRect(x: 10, y: 10, width: 20, height: 20))
        paintedLayer.backgroundColor = CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
        paintedLayer.cornerRadius = 4
        rootLayer.addSublayer(paintedLayer)

        let file = convertedFile(of: rootLayer)
        expect(file.groupScreenshots?[NSNumber(value: 1)] != nil, "the root's subtree draws, so it needs a group image")
        expect(file.groupScreenshots?[NSNumber(value: 2)] != nil, "the painted layer needs a group image")
        expect(file.soloScreenshots?[NSNumber(value: 2)] == nil, "a layer without sublayers needs no separate solo image")
        let root = file.hierarchyInfo?.displayItems?.first
        expect(
            root?.groupScreenshotRegion == CGRect(x: 10, y: 10, width: 20, height: 20),
            "the root's image covers only where its subtree draws, got \(String(describing: root?.groupScreenshotRegion))"
        )
    }

    private static func testCancelledRecoveryThrows() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 10, height: 10))
        rootLayer.addSublayer(makingLayer(CGRect(x: 0, y: 0, width: 5, height: 5)))
        let tree = CoreAnimationArchiveLayerTree(contents: decodedContents(of: rootLayer))
        do {
            _ = try CoreAnimationArchivePixelRecovery.recovering(from: tree) { true }
            fail("a cancelled recovery should throw")
        } catch is CancellationError {
            // Expected: a cancelled import produces nothing.
        } catch {
            fail("a cancelled recovery should throw CancellationError, got \(error)")
        }
    }

    // MARK: - Dashboard

    /// The rows are typed as the server types a live layer's: a float
    /// opacity, CGFloat values as doubles, colours as RGBA arrays
    /// (`LookinAttrType.h`; the colour card asserts on anything else).
    private static func testLayerRowsFollowTheServerTypes() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 40, height: 40))
        let styledLayer = makingLayer(CGRect(x: 0, y: 0, width: 20, height: 20))
        styledLayer.opacity = 0.5
        styledLayer.cornerRadius = 6
        styledLayer.borderWidth = 2
        styledLayer.borderColor = CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
        styledLayer.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        styledLayer.masksToBounds = true
        rootLayer.addSublayer(styledLayer)

        let items = flattened(convertedFile(of: rootLayer).hierarchyInfo?.displayItems ?? [])
        guard items.count == 2 else { fail("the tree should have two nodes") }
        let attributes = attributesByIdentifier(of: items[1])

        expect(attributes[LookinAttr_ViewLayer_Visibility_Opacity]?.attrType == .float, "opacity should be a float")
        expect((attributes[LookinAttr_ViewLayer_Visibility_Opacity]?.value as? NSNumber)?.floatValue == 0.5, "opacity should be 0.5")
        expect(attributes[LookinAttr_ViewLayer_Corner_Radius]?.attrType == .double, "corner radius should be a double")
        expect(attributes[LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds]?.attrType == .BOOL, "masks to bounds should be a BOOL")
        expect(attributes[LookinAttr_Layout_Frame_Frame]?.attrType == .cgRect, "the frame should be a CGRect")
        expect(attributes[LookinAttr_Layout_Position_Position]?.attrType == .cgPoint, "the position should be a CGPoint")
        expect(attributes[LookinAttr_ViewLayer_BgColor_BgColor]?.attrType == .uiColor, "the background colour should be a colour")
        expect(
            (attributes[LookinAttr_ViewLayer_BgColor_BgColor]?.value as? [NSNumber])?.map(\.doubleValue) == [1, 0, 0, 1],
            "a colour's value should be its RGBA components"
        )
        expect(
            (attributes[LookinAttr_ViewLayer_Border_Color]?.value as? [NSNumber])?.map(\.doubleValue) == [0, 0, 1, 1],
            "the border colour should be its RGBA components"
        )
        for attribute in attributes.values {
            if attribute.attrType == .uiColor, let value = attribute.value {
                expect(value is [NSNumber], "colour row \(attribute.identifier ?? "?") must carry an RGBA array, not \(type(of: value))")
            }
        }
        for identifier in attributes.keys {
            expect(
                DashboardBlueprint.targetKind(forAttrID: identifier) == .layer,
                "\(identifier) is not a row the blueprint aims at a CALayer"
            )
        }
    }

    private static func testClassCardEndsAtCALayer() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 40, height: 40))
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        rootLayer.addSublayer(shapeLayer)

        let items = flattened(convertedFile(of: rootLayer).hierarchyInfo?.displayItems ?? [])
        guard items.count == 2 else { fail("the tree should have two nodes") }
        let classCard = attributesByIdentifier(of: items[1])[LookinAttr_Class_Class_Class]?.value as? [[String]]
        expect(classCard == [["CAShapeLayer", "CALayer"]], "the Class card should list the chain up to CALayer, got \(String(describing: classCard))")
        expect(items[1].layerObject?.classChainList == ["CAShapeLayer", "CALayer", "NSObject"], "the object's chain should run to NSObject")
    }

    private static func testAppNameComesFromTheFileName() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 10, height: 10))
        rootLayer.addSublayer(makingLayer(CGRect(x: 0, y: 0, width: 5, height: 5)))
        let origin = CoreAnimationArchiveOrigin(fileName: "RuntimeViewer-501-NSWindow-0x1234-layer-99.caar")
        let named = convertedFile(of: rootLayer, origin: origin)
        expect(named.hierarchyInfo?.appInfo?.appName == "RuntimeViewer", "the app name should come from the file name")
        expect(named.hierarchyInfo?.appInfo?.deviceType == .mac, "a Dump Layer archive comes from a Mac")
        let unnamed = convertedFile(of: rootLayer, origin: nil)
        expect(unnamed.hierarchyInfo?.appInfo?.appName?.isEmpty == false, "an archive with no origin still needs a name")
    }

    // MARK: - Helpers

    private typealias EncodeLayerTreeFunction = @convention(c) (CALayer) -> Unmanaged<NSData>?

    private static func makingLayer(_ frame: CGRect) -> CALayer {
        let layer = CALayer()
        layer.frame = frame
        return layer
    }

    /// The archive Dump Layer would write for `layer`, decoded.
    private static func decodedContents(of layer: CALayer) -> CoreAnimationArchiveContents {
        let defaultHandle = UnsafeMutableRawPointer(bitPattern: -2)
        guard let symbol = dlsym(defaultHandle, "CAEncodeLayerTree") else {
            fail("CAEncodeLayerTree is not exported by this QuartzCore")
        }
        let encodeLayerTree = unsafeBitCast(symbol, to: EncodeLayerTreeFunction.self)
        guard let data = encodeLayerTree(layer)?.takeRetainedValue() else {
            fail("CAEncodeLayerTree returned no data")
        }
        do {
            return try CoreAnimationArchive.decodingContents(of: data as Data)
        } catch {
            fail("the fixture archive failed to decode: \(error)")
        }
    }

    private static func convertedFile(of layer: CALayer, origin: CoreAnimationArchiveOrigin? = nil) -> HierarchyFile {
        let tree = CoreAnimationArchiveLayerTree(contents: decodedContents(of: layer))
        let screenshots: CoreAnimationArchiveScreenshots
        do {
            screenshots = try CoreAnimationArchivePixelRecovery.recovering(from: tree)
        } catch {
            fail("pixel recovery failed: \(error)")
        }
        let capture = CoreAnimationArchiveCapture(tree: tree, screenshots: screenshots, origin: origin)
        return CoreAnimationArchiveConverter.makingHierarchyFile(from: capture)
    }

    private static func flattened(_ items: [DisplayItem]) -> [DisplayItem] {
        items.flatMap { [$0] + flattened($0.subitems ?? []) }
    }

    private static func attributesByIdentifier(of item: DisplayItem) -> [String: InspectedAttribute] {
        var attributes: [String: InspectedAttribute] = [:]
        for group in item.attributesGroupList ?? [] {
            for section in group.attrSections ?? [] {
                for attribute in section.attributes ?? [] {
                    if let identifier = attribute.identifier {
                        attributes[identifier] = attribute
                    }
                }
            }
        }
        return attributes
    }

    /// The bitmap's own components, unconverted: the images are rendered in
    /// sRGB, and a conversion to another space would move the very values
    /// checked here.
    private static func isRed(_ color: NSColor?) -> Bool {
        guard let color, color.numberOfComponents >= 3 else { return false }
        return color.redComponent > 0.9 && color.greenComponent < 0.1 && color.blueComponent < 0.1 && color.alphaComponent > 0.9
    }

    private static func isBlue(_ color: NSColor?) -> Bool {
        guard let color, color.numberOfComponents >= 3 else { return false }
        return color.blueComponent > 0.9 && color.redComponent < 0.1 && color.greenComponent < 0.1 && color.alphaComponent > 0.9
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        Foundation.exit(1)
    }
}
