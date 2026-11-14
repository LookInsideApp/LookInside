import AppKit
import Foundation
import Metal
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
        testEveryImageFitsThePreviewTextureLimit()
        testVibrantContentDrawsWhereItsMaterialIsMissing()
        testVibrantImageDrawsWhereItsBackdropIsMissing()
        testEmptyContainerTakesItsSublayersPicture()
        testCancelledRecoveryThrows()
        testLayerRowsFollowTheServerTypes()
        testClassCardEndsAtCALayer()
        testAppNameComesFromTheFileName()
        MainActor.assumeIsolated {
            testViewLayersBecomeViewNodes()
            testCustomBackingLayerNamesBothClasses()
            testViewClassThisProcessLacksKeepsItsName()
            testGlassRendersAsGlassNotItsShape()
            testGlassDrawnOnItsOwnLooksAsInTheWindow()
            testGlassShapeInputsGetNoImage()
            testLayersInsideGlassShapesGetNoImage()
            testExpandedGlassPlaneDrawsTheGlass()
            testGlassContentIsOrderedWhereItsPortalDrawsIt()
            testHiddenGlassIsLeftOutOfTheImages()
        }
        testPunchOutLayersGetNoImage()
        testVibrantContentOnItsOwnLooksAsOverItsMaterial()
        testUnmarkedOrMisnamedLayersStayLayers()
        testNamedLayersShowTheirNames()
        testSublayersOfAScrolledFlippedLayerSitWhereTheyShow()
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

    /// A Dump Layer of an Xcode window held the console's content view,
    /// 256310 points of text. Its image came out 25630 pixels tall, and the
    /// preview asserts that no image it is handed is longer than
    /// `LookinNodeImageMaxLengthInPx` on a side. Every image an import files
    /// has to fit, measured as the reader loads it, and the tall layer still
    /// gets its image: a folded node shows its whole subtree in it.
    private static func testEveryImageFitsThePreviewTextureLimit() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 400, height: 300))
        rootLayer.masksToBounds = true
        let contentLayer = makingLayer(CGRect(x: 0, y: 0, width: 380, height: 256_310))
        // The console's background, so the layer draws along its whole
        // height, and a line of text at either end. A line alone shrinks to
        // less than a pixel at this scale, and draws nothing.
        contentLayer.backgroundColor = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        let firstLineLayer = makingLayer(CGRect(x: 0, y: 0, width: 380, height: 14))
        firstLineLayer.borderWidth = 1
        let lastLineLayer = makingLayer(CGRect(x: 0, y: 256_296, width: 380, height: 14))
        lastLineLayer.borderWidth = 1
        contentLayer.addSublayer(firstLineLayer)
        contentLayer.addSublayer(lastLineLayer)
        rootLayer.addSublayer(contentLayer)

        let file = convertedFile(of: rootLayer)
        let images = Array((file.soloScreenshots ?? [:]).values) + Array((file.groupScreenshots ?? [:]).values)
        for data in images {
            guard let representation = NSImage(data: data)?.representations.first else {
                fail("a filed image does not load")
            }
            let longestSide = max(representation.pixelsWide, representation.pixelsHigh)
            expect(
                Double(longestSide) <= LookinNodeImageMaxLengthInPx,
                "an image of \(representation.pixelsWide) x \(representation.pixelsHigh) pixels is past the preview's limit"
            )
        }
        guard let contentData = file.groupScreenshots?[NSNumber(value: 2)],
              let contentRepresentation = NSImage(data: contentData)?.representations.first
        else { fail("the tall layer's subtree draws, so it needs a group image") }
        expect(
            contentRepresentation.pixelsHigh > 16000,
            "the tall side should use the whole texture edge; got \(contentRepresentation.pixelsHigh)"
        )
    }

    /// Liquid Glass is a signed-distance-field layer whose shape source is a
    /// white fill that only Core Animation's own renderer turns into glass;
    /// CGContext's renderInContext draws the white fill, which is how every
    /// glass toolbar button of a dumped Xcode window came out a white
    /// lozenge. A real NSGlassEffectView over a dark window, dumped and
    /// imported, must show dark glass where the button is.
    @MainActor
    private static func testGlassRendersAsGlassNotItsShape() {
        guard #available(macOS 26.0, *) else {
            print("skipped testGlassRendersAsGlassNotItsShape: NSGlassEffectView needs macOS 26")
            return
        }
        // Without a GPU the import draws with renderInContext, glass and all;
        // with one, Core Animation's renderer must be the one drawing.
        guard MTLCreateSystemDefaultDevice() != nil else {
            print("skipped testGlassRendersAsGlassNotItsShape: no Metal device")
            return
        }
        expect(CoreAnimationLayerRenderer.shared != nil, "Core Animation's renderer did not start on a machine with a Metal device")
        let (contentView, window) = makingLayerBackedContentView()
        window.appearance = NSAppearance(named: .darkAqua)
        window.setContentSize(NSSize(width: 200, height: 100))
        contentView.layer?.backgroundColor = CGColor(srgbRed: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        // Centred, so the image's centre is the glass's.
        let glassView = NSGlassEffectView(frame: NSRect(x: 40, y: 30, width: 120, height: 40))
        glassView.cornerRadius = 20
        contentView.addSubview(glassView)
        settlingLayers(of: window)
        guard let contentLayer = contentView.layer else { fail("the content view should have a layer") }

        let file = convertedFile(of: contentLayer)
        guard let rootData = file.groupScreenshots?[NSNumber(value: 1)],
              let rootImage = NSBitmapImageRep(data: rootData),
              let centre = rootImage.colorAt(x: rootImage.pixelsWide / 2, y: rootImage.pixelsHigh / 2)?.usingColorSpace(.sRGB)
        else { fail("the window's content should render") }
        expect(
            centre.redComponent < 0.8 || centre.greenComponent < 0.8 || centre.blueComponent < 0.8,
            "the glass rendered as its white shape source: \(centre)"
        )
    }

    /// A node's image draws its subtree on its own, over transparency, and a
    /// backdrop captures whatever lies behind it there. Liquid Glass reads a
    /// partly transparent capture as if it were opaque and blows the colours
    /// in it up into a saturated block: unfolding a dumped Xcode window put a
    /// solid blue block on the toolbar's back/forward glass, from the blue
    /// project icon beside it, where the window shows dark glass. Glass over
    /// content, drawn on its own, must look as it does in the window, and its
    /// image stay clear where nothing draws.
    @MainActor
    private static func testGlassDrawnOnItsOwnLooksAsInTheWindow() {
        guard let (tree, screenshots) = importedGlassOverSquare(skipping: "testGlassDrawnOnItsOwnLooksAsInTheWindow") else {
            return
        }
        guard let containerIndex = tree.layers.firstIndex(where: { $0.bounds.size == CGSize(width: 260, height: 60) }) else {
            fail("the container should be in the archive")
        }
        // A band of the glass just left of the square, in the content view's
        // space, which is the archive root's: in the window, dark glass with
        // the square's glow coming through; drawn on its own, it was blue.
        let glassBand = CGRect(x: 108, y: 42, width: 20, height: 16)
        guard let inTheWindow = averageColor(of: glassBand, inImageOf: 1, tree: tree, screenshots: screenshots),
              let onItsOwn = averageColor(of: glassBand, inImageOf: UInt(containerIndex + 1), tree: tree, screenshots: screenshots)
        else { fail("the window and the container should both have images") }
        let largestDifference = zip(inTheWindow, onItsOwn).map { abs($0 - $1) }.max() ?? 0
        expect(
            largestDifference < 0.08,
            "the glass drawn on its own should look as it does in the window: \(onItsOwn) against \(inTheWindow)"
        )
        guard let containerData = screenshots.groupByObjectIdentifier[UInt(containerIndex + 1)],
              let containerImage = NSBitmapImageRep(data: containerData)?.cgImage
        else { fail("the container should have an image") }
        let alphas = premultipliedPixels(of: containerImage).enumerated().filter { $0.offset % 4 == 3 }.map(\.element)
        expect(alphas.contains { $0 < 5 }, "the container's image should stay clear where nothing draws")
    }

    /// Liquid Glass reads its shape from signed-distance-field layers under
    /// its backdrop (`CASDFLayer` and its `CASDFElementLayer`s). On screen
    /// they are never drawn themselves; drawn without the backdrop that
    /// reads them they come out as the raw field, a rainbow-coloured
    /// lozenge, which is what unfolding a glass control down to them showed.
    /// They get no image.
    @MainActor
    private static func testGlassShapeInputsGetNoImage() {
        guard let (tree, screenshots) = importedGlassOverSquare(skipping: "testGlassShapeInputsGetNoImage") else {
            return
        }
        let backdropLayerClass: AnyClass? = NSClassFromString("CABackdropLayer")
        let shapeInputIdentifiers = tree.layers.enumerated().compactMap { index, layer -> UInt? in
            guard NSStringFromClass(type(of: layer)).hasPrefix("CASDF") else { return nil }
            var ancestor = layer.superlayer
            while let current = ancestor {
                if let backdropLayerClass, current.isKind(of: backdropLayerClass) {
                    return UInt(index + 1)
                }
                ancestor = current.superlayer
            }
            return nil
        }
        expect(!shapeInputIdentifiers.isEmpty, "the glass should read its shape from distance-field layers under its backdrop")
        for objectIdentifier in shapeInputIdentifiers {
            expect(
                screenshots.groupByObjectIdentifier[objectIdentifier] == nil && screenshots.soloByObjectIdentifier[objectIdentifier] == nil,
                "the glass's shape input #\(objectIdentifier) should get no image"
            )
        }
    }

    /// The plain layers inside a distance-field layer under a backdrop are
    /// as much the glass's shape as the field layer itself: drawn on their
    /// own they came out as the raw field, black, green and blue blocks.
    @MainActor
    private static func testLayersInsideGlassShapesGetNoImage() {
        guard let (tree, screenshots) = importedGlassOverSquare(skipping: "testLayersInsideGlassShapesGetNoImage") else {
            return
        }
        let backdropLayerClass: AnyClass? = NSClassFromString("CABackdropLayer")
        func isInsideAGlassShape(_ layer: CALayer) -> Bool {
            var sawShapeLayer = false
            var ancestor = layer.superlayer
            while let current = ancestor {
                if let backdropLayerClass, current.isKind(of: backdropLayerClass) {
                    return sawShapeLayer
                }
                if NSStringFromClass(type(of: current)).hasPrefix("CASDF") {
                    sawShapeLayer = true
                }
                ancestor = current.superlayer
            }
            return false
        }
        let insideIdentifiers = tree.layers.enumerated().compactMap { index, layer -> UInt? in
            guard !NSStringFromClass(type(of: layer)).hasPrefix("CASDF"), isInsideAGlassShape(layer) else { return nil }
            return UInt(index + 1)
        }
        guard !insideIdentifiers.isEmpty else {
            print("skipped testLayersInsideGlassShapesGetNoImage: this system's glass keeps no plain layers inside its shape")
            return
        }
        for objectIdentifier in insideIdentifiers {
            expect(
                screenshots.groupByObjectIdentifier[objectIdentifier] == nil && screenshots.soloByObjectIdentifier[objectIdentifier] == nil,
                "#\(objectIdentifier), inside the glass's shape, should get no image"
            )
        }
    }

    /// Once its node is expanded, a glass's plane is its backdrop's own
    /// image. The glass reads its shape from the distance-field layers under
    /// the backdrop, which get no image of their own; the backdrop's image
    /// left them out too, came out empty, and fully expanded glass vanished.
    /// The backdrop's own image keeps its shape layers and shows the glass.
    @MainActor
    private static func testExpandedGlassPlaneDrawsTheGlass() {
        guard let (tree, screenshots) = importedGlassOverSquare(skipping: "testExpandedGlassPlaneDrawsTheGlass") else {
            return
        }
        guard let backdropLayerClass = NSClassFromString("CABackdropLayer"),
              let backdropIndex = tree.layers.firstIndex(where: { $0.isKind(of: backdropLayerClass) })
        else { fail("the glass should have a backdrop") }
        guard let soloData = screenshots.soloByObjectIdentifier[UInt(backdropIndex + 1)],
              let soloImage = NSBitmapImageRep(data: soloData)?.cgImage
        else { fail("the glass's backdrop should have an image of its own") }
        let pixels = premultipliedPixels(of: soloImage)
        let centre = ((soloImage.height / 2) * soloImage.width + soloImage.width / 2) * 4
        expect(pixels[centre + 3] > 200, "the backdrop's own image should show the glass, alpha \(pixels[centre + 3]) at its centre")
    }

    /// An `NSGlassEffectView` lists its content before the view that draws
    /// its glass, and draws the content over the glass through portals that
    /// hide it in place. The preview orders planes by the hierarchy, so the
    /// expanded glass covered the search field it holds. A node a portal
    /// draws that way knows the portal's node, after which the preview
    /// orders it.
    @MainActor
    private static func testGlassContentIsOrderedWhereItsPortalDrawsIt() {
        guard #available(macOS 26.0, *) else {
            print("skipped testGlassContentIsOrderedWhereItsPortalDrawsIt: NSGlassEffectView needs macOS 26")
            return
        }
        let (contentView, window) = makingLayerBackedContentView()
        window.setContentSize(NSSize(width: 300, height: 100))
        let glassView = NSGlassEffectView(frame: NSRect(x: 20, y: 30, width: 200, height: 40))
        glassView.contentView = NSTextField(labelWithString: "Filter")
        contentView.addSubview(glassView)
        settlingLayers(of: window)
        guard let contentLayer = contentView.layer else { fail("the content view should have a layer") }
        let contents = withExtendedLifetime(window) { decodedContents(of: contentLayer) }
        let tree = CoreAnimationArchiveLayerTree(contents: contents)
        let file = CoreAnimationArchiveConverter.makingHierarchyFile(
            from: CoreAnimationArchiveCapture(tree: tree, screenshots: CoreAnimationArchiveScreenshots(), origin: nil)
        )
        var itemByOid: [UInt: DisplayItem] = [:]
        for item in flattened(file.hierarchyInfo?.displayItems ?? []) {
            if let oid = item.layerObject?.oid {
                itemByOid[oid] = item
            }
        }
        // A layer two portals draw goes with the later one, drawn on top.
        var lastPortalBySource: [ObjectIdentifier: (source: CALayer, portal: CALayer)] = [:]
        for pair in XcodeViewHierarchyPixelRecovery.portalsHidingTheirSources(in: tree.layers) {
            lastPortalBySource[ObjectIdentifier(pair.source)] = pair
        }
        expect(!lastPortalBySource.isEmpty, "the glass should draw its content through a portal that hides it in place")
        for (source, portal) in lastPortalBySource.values {
            let sourceOid = tree.objectIdentifier(of: source)
            let portalItem = itemByOid[tree.objectIdentifier(of: portal)]
            expect(portalItem != nil, "the portal drawing #\(sourceOid) should have a node")
            expect(
                itemByOid[sourceOid]?.previewPortalItem === portalItem,
                "#\(sourceOid), which a portal draws over the glass, should know the portal's node"
            )
        }
    }

    /// A layer composited with `destOut` only cuts what is beneath it: a
    /// segmented control removes its plain icon where the selection is with
    /// a black rounded rectangle in such a layer. On screen nothing of the
    /// rectangle shows; drawn on its own it came out as a black capsule in
    /// front of the selection. The cutting layer and what is under it get
    /// no image; the cut stays in the group image that holds what it cuts.
    private static func testPunchOutLayersGetNoImage() {
        guard let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
              let destinationOut = filterClass.perform(
                  NSSelectorFromString("filterWithType:"), with: "destOut"
              )?.takeUnretainedValue()
        else { fail("QuartzCore should make a destOut filter") }
        let white = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 200, height: 100))
        let iconsLayer = makingLayer(CGRect(x: 0, y: 0, width: 200, height: 100))
        let selectedIcon = makingLayer(CGRect(x: 20, y: 30, width: 40, height: 40))
        selectedIcon.backgroundColor = white
        let otherIcon = makingLayer(CGRect(x: 140, y: 30, width: 40, height: 40))
        otherIcon.backgroundColor = white
        let cuttingLayer = makingLayer(CGRect(x: 0, y: 0, width: 200, height: 100))
        cuttingLayer.compositingFilter = destinationOut
        let selectionShape = makingLayer(CGRect(x: 10, y: 20, width: 60, height: 60))
        selectionShape.backgroundColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        selectionShape.cornerRadius = 12
        cuttingLayer.addSublayer(selectionShape)
        iconsLayer.addSublayer(selectedIcon)
        iconsLayer.addSublayer(otherIcon)
        iconsLayer.addSublayer(cuttingLayer)
        rootLayer.addSublayer(iconsLayer)

        let tree = CoreAnimationArchiveLayerTree(contents: decodedContents(of: rootLayer))
        let screenshots = recoveredScreenshots(of: tree)
        // Depth first: root 1, icons 2, selected icon 3, other icon 4,
        // cutting layer 5, selection shape 6.
        for objectIdentifier: UInt in [5, 6] {
            expect(
                screenshots.groupByObjectIdentifier[objectIdentifier] == nil && screenshots.soloByObjectIdentifier[objectIdentifier] == nil,
                "#\(objectIdentifier), which only cuts what is beneath it, should get no image"
            )
        }
        let cutAlpha = averageAlpha(of: CGRect(x: 30, y: 40, width: 20, height: 20), inImageOf: 2, tree: tree, screenshots: screenshots)
        let keptAlpha = averageAlpha(of: CGRect(x: 150, y: 40, width: 20, height: 20), inImageOf: 2, tree: tree, screenshots: screenshots)
        expect((cutAlpha ?? 1) < 0.05, "the icons' group image should keep the cut, alpha \(String(describing: cutAlpha)) under the selection")
        expect((keptAlpha ?? 0) > 0.95, "the icons' group image should keep the icon outside the cut, alpha \(String(describing: keptAlpha))")
    }

    /// A dark window whose transparent container holds a blue square and,
    /// drawn after it, a real NSGlassEffectView over the square's left part,
    /// dumped and imported: the container's own image has nothing behind the
    /// glass but the square. Nil, after saying the test was skipped, where
    /// there is no Liquid Glass or no GPU to draw it.
    @MainActor
    private static func importedGlassOverSquare(
        skipping testName: String
    ) -> (CoreAnimationArchiveLayerTree, CoreAnimationArchiveScreenshots)? {
        guard #available(macOS 26.0, *) else {
            print("skipped \(testName): NSGlassEffectView needs macOS 26")
            return nil
        }
        guard MTLCreateSystemDefaultDevice() != nil else {
            print("skipped \(testName): no Metal device")
            return nil
        }
        let (contentView, window) = makingLayerBackedContentView()
        window.appearance = NSAppearance(named: .darkAqua)
        window.setContentSize(NSSize(width: 300, height: 100))
        contentView.layer?.backgroundColor = CGColor(srgbRed: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        let containerView = NSView(frame: NSRect(x: 20, y: 20, width: 260, height: 60))
        containerView.wantsLayer = true
        contentView.addSubview(containerView)
        let squareView = NSView(frame: NSRect(x: 110, y: 15, width: 30, height: 30))
        squareView.wantsLayer = true
        squareView.layer?.backgroundColor = CGColor(srgbRed: 0, green: 0.4, blue: 1, alpha: 1)
        containerView.addSubview(squareView)
        let glassView = NSGlassEffectView(frame: NSRect(x: 10, y: 10, width: 120, height: 40))
        glassView.cornerRadius = 20
        containerView.addSubview(glassView)
        settlingLayers(of: window)
        guard let contentLayer = contentView.layer else { fail("the content view should have a layer") }
        // The window owns the views being dumped: kept alive until they are.
        let contents = withExtendedLifetime(window) { decodedContents(of: contentLayer) }
        let tree = CoreAnimationArchiveLayerTree(contents: contents)
        return (tree, recoveredScreenshots(of: tree))
    }

    /// Text and icons on a sidebar or a toolbar are composited through a
    /// vibrant filter onto the material behind them. A node drawn on its
    /// own leaves out whatever its ancestors draw, so a sidebar's labels
    /// vanished from every image below the sidebar's material. In the
    /// window's own image, which has nothing to stand in for a missing
    /// material, a vibrant layer with nothing drawn behind it is drawn
    /// plain; one with something behind it keeps its filter. A node drawn on
    /// its own still shows its label: there the window's colour stands in
    /// for the material (`testVibrantContentOnItsOwnLooksAsOverItsMaterial`).
    /// The filter is made at run time, as Dump Layer decodes it: AppKit sets
    /// it only in windows on screen.
    private static func testVibrantContentDrawsWhereItsMaterialIsMissing() {
        guard let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
              let vibrantFilter = filterClass.perform(
                  NSSelectorFromString("filterWithType:"), with: "vibrantColorMatrixSourceOver"
              )?.takeUnretainedValue()
        else { fail("QuartzCore should make a vibrant filter") }
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 200, height: 100))
        // A material under the left half; nothing under the right.
        let materialLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        materialLayer.backgroundColor = CGColor(srgbRed: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        let labelOnMaterial = makingLayer(CGRect(x: 30, y: 30, width: 40, height: 40))
        labelOnMaterial.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        labelOnMaterial.compositingFilter = vibrantFilter
        // Inside a sidebar row's rounded container, which draws nothing and
        // is no material.
        let roundedRowLayer = makingLayer(CGRect(x: 120, y: 20, width: 60, height: 60))
        roundedRowLayer.cornerRadius = 6
        let labelWithoutMaterial = makingLayer(CGRect(x: 10, y: 10, width: 40, height: 40))
        labelWithoutMaterial.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        labelWithoutMaterial.compositingFilter = vibrantFilter
        roundedRowLayer.addSublayer(labelWithoutMaterial)
        rootLayer.addSublayer(materialLayer)
        rootLayer.addSublayer(labelOnMaterial)
        rootLayer.addSublayer(roundedRowLayer)

        let file = convertedFile(of: rootLayer)
        guard let rootData = file.groupScreenshots?[NSNumber(value: 1)],
              let rootImage = NSBitmapImageRep(data: rootData)
        else { fail("the root's subtree draws, so it needs a group image") }
        expect(
            isRed(rootImage.colorAt(x: 150, y: 50)),
            "a vibrant layer with nothing behind it should be drawn plain; got \(String(describing: rootImage.colorAt(x: 150, y: 50)))"
        )
        expect(
            !isRed(rootImage.colorAt(x: 50, y: 50)),
            "a vibrant layer over its material should keep its filter"
        )
        guard let labelData = file.groupScreenshots?[NSNumber(value: 5)],
              let labelImage = NSBitmapImageRep(data: labelData)
        else { fail("the label drawn on its own should have an image") }
        expect(
            (labelImage.colorAt(x: 20, y: 20)?.alphaComponent ?? 0) > 0.9,
            "the label on its own should still show; got \(String(describing: labelImage.colorAt(x: 20, y: 20)))"
        )
    }

    /// SwiftUI draws the icons of a toolbar control as images through a
    /// vibrant entry in `filters` (vibrantColorMatrix, aware of the
    /// backdrop), and the control's glass, a sibling of the icons, lays the
    /// backdrop down. Without it the filter leaves nothing: unfolding the
    /// hosting view of a dumped Xcode window's navigator switcher emptied
    /// its plane, and controls whose glass an ancestor draws had no icons
    /// even folded. In the window's own image, a layer that draws an image
    /// through a vibrant filter with nothing behind it is drawn plain; one
    /// over its material keeps the filter. A fill through such a filter
    /// stays as it is: drawn plain it is an opaque lozenge where the glass
    /// shows a faint highlight. Drawn on its own, the icon still shows.
    private static func testVibrantImageDrawsWhereItsBackdropIsMissing() {
        guard let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
              let vibrantFilter = filterClass.perform(
                  NSSelectorFromString("filterWithType:"), with: "vibrantColorMatrix"
              )?.takeUnretainedValue() as? NSObject
        else { fail("QuartzCore should make a vibrant filter") }
        vibrantFilter.setValue(true, forKey: "inputBackdropAware")
        guard let redImage = makingImage(of: CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1), side: 40) else {
            fail("the icon image should draw")
        }
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 200, height: 100))
        // A material under the left half; nothing under the right.
        let materialLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        materialLayer.backgroundColor = CGColor(srgbRed: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        let iconOnMaterial = makingLayer(CGRect(x: 30, y: 30, width: 40, height: 40))
        iconOnMaterial.contents = redImage
        iconOnMaterial.filters = [vibrantFilter]
        let iconWithoutMaterial = makingLayer(CGRect(x: 110, y: 30, width: 40, height: 40))
        iconWithoutMaterial.contents = redImage
        iconWithoutMaterial.filters = [vibrantFilter]
        let highlightWithoutMaterial = makingLayer(CGRect(x: 160, y: 30, width: 30, height: 40))
        highlightWithoutMaterial.backgroundColor = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        highlightWithoutMaterial.filters = [vibrantFilter]
        rootLayer.addSublayer(materialLayer)
        rootLayer.addSublayer(iconOnMaterial)
        rootLayer.addSublayer(iconWithoutMaterial)
        rootLayer.addSublayer(highlightWithoutMaterial)

        let file = convertedFile(of: rootLayer)
        guard let rootData = file.groupScreenshots?[NSNumber(value: 1)],
              let rootImage = NSBitmapImageRep(data: rootData)
        else { fail("the root's subtree draws, so it needs a group image") }
        expect(
            isRed(rootImage.colorAt(x: 130, y: 50)),
            "an image through a vibrant filter with nothing behind it should be drawn plain; got \(String(describing: rootImage.colorAt(x: 130, y: 50)))"
        )
        expect(
            !isRed(rootImage.colorAt(x: 50, y: 50)),
            "an image through a vibrant filter over its material should keep the filter"
        )
        expect(
            (rootImage.colorAt(x: 175, y: 50)?.alphaComponent ?? 0) < 0.1,
            "a fill through a vibrant filter should not be drawn plain; got \(String(describing: rootImage.colorAt(x: 175, y: 50)))"
        )
        // Unfolded, the icon over the material is drawn without it.
        guard let iconData = file.groupScreenshots?[NSNumber(value: 3)],
              let iconImage = NSBitmapImageRep(data: iconData)
        else { fail("the icon drawn on its own should have an image") }
        expect(
            (iconImage.colorAt(x: 20, y: 20)?.alphaComponent ?? 0) > 0.9,
            "the icon on its own should still show; got \(String(describing: iconImage.colorAt(x: 20, y: 20)))"
        )
    }

    /// Vibrant content takes its colour from the material behind it: the
    /// filter acts on that material, cut to the content's shape. A node drawn
    /// on its own has none behind it; drawn plain, a disabled toolbar icon
    /// of a dumped Xcode window came out white where the window shows it
    /// grey, and the folder icons of its navigator a deeper blue. The
    /// window's colour stands in for the material, so a vibrant label, a
    /// vibrant icon and a vibrant fill in a transparent container, laid over
    /// the window's one grey material, must look in the container's own image
    /// as they do in the window's — and the fill, a sheen on its material,
    /// must not become an opaque block.
    private static func testVibrantContentOnItsOwnLooksAsOverItsMaterial() {
        guard CoreAnimationLayerRenderer.shared != nil else {
            print("skipped testVibrantContentOnItsOwnLooksAsOverItsMaterial: no Core Animation renderer")
            return
        }
        guard let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
              let compositingFilter = filterClass.perform(
                  NSSelectorFromString("filterWithType:"), with: "vibrantColorMatrixSourceOver"
              )?.takeUnretainedValue(),
              let imageFilter = filterClass.perform(
                  NSSelectorFromString("filterWithType:"), with: "vibrantColorMatrix"
              )?.takeUnretainedValue() as? NSObject
        else { fail("QuartzCore should make vibrant filters") }
        imageFilter.setValue(true, forKey: "inputBackdropAware")
        let red = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        guard let redImage = makingImage(of: red, side: 40) else { fail("the icon image should draw") }
        // The window: one opaque grey material, so its average colour is that
        // grey. The container on top is transparent: drawn on its own,
        // nothing lies behind what it holds.
        let grey: CGFloat = 0.3
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 400, height: 200))
        rootLayer.backgroundColor = CGColor(srgbRed: grey, green: grey, blue: grey, alpha: 1)
        let containerLayer = makingLayer(CGRect(x: 0, y: 0, width: 400, height: 200))
        let labelLayer = makingLayer(CGRect(x: 20, y: 20, width: 40, height: 40))
        labelLayer.backgroundColor = red
        labelLayer.compositingFilter = compositingFilter
        let iconLayer = makingLayer(CGRect(x: 80, y: 20, width: 40, height: 40))
        iconLayer.contents = redImage
        iconLayer.filters = [imageFilter]
        let fillLayer = makingLayer(CGRect(x: 140, y: 20, width: 40, height: 40))
        fillLayer.backgroundColor = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        fillLayer.filters = [imageFilter]
        containerLayer.addSublayer(labelLayer)
        containerLayer.addSublayer(iconLayer)
        containerLayer.addSublayer(fillLayer)
        rootLayer.addSublayer(containerLayer)

        let tree = CoreAnimationArchiveLayerTree(contents: decodedContents(of: rootLayer))
        let screenshots = recoveredScreenshots(of: tree)
        let greyBackground = [Double](repeating: Double(grey), count: 3)
        for (name, layer) in [("label", labelLayer), ("icon", iconLayer), ("fill", fillLayer)] {
            // The middle of the layer, in the root's space.
            let middle = layer.frame.insetBy(dx: 10, dy: 10)
            guard let inTheWindow = averageColor(of: middle, inImageOf: 1, tree: tree, screenshots: screenshots),
                  let onItsOwn = averageColor(of: middle, inImageOf: 2, tree: tree, screenshots: screenshots, over: greyBackground)
            else { fail("the window and the container should both have images where the \(name) is") }
            let largestDifference = zip(inTheWindow, onItsOwn).map { abs($0 - $1) }.max() ?? 0
            expect(
                largestDifference < 0.06,
                "the vibrant \(name) drawn on its own should look as over its material: \(onItsOwn) against \(inTheWindow)"
            )
        }
        let fillMiddle = fillLayer.frame.insetBy(dx: 10, dy: 10)
        guard let fillAlpha = averageAlpha(of: fillMiddle, inImageOf: 2, tree: tree, screenshots: screenshots) else {
            fail("the container's image should reach the fill")
        }
        expect(fillAlpha < 0.5, "the vibrant fill should stay a sheen, not an opaque block; its alpha is \(fillAlpha)")
    }

    /// A window's content layer is a container of no size that does not
    /// clip: AppKit lays the whole window out in it, outside its bounds. Cut
    /// to its own empty bounds, its image was nothing, and unfolding a dumped
    /// window showed a blank plane. Such a container's image covers what its
    /// sublayers draw, placed by its region.
    private static func testEmptyContainerTakesItsSublayersPicture() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        let contentLayer = makingLayer(.zero)
        let viewLayer = makingLayer(CGRect(x: 30, y: 30, width: 40, height: 40))
        viewLayer.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        viewLayer.borderWidth = 1
        contentLayer.addSublayer(viewLayer)
        rootLayer.addSublayer(contentLayer)

        let file = convertedFile(of: rootLayer)
        guard let containerData = file.groupScreenshots?[NSNumber(value: 2)],
              let containerImage = NSBitmapImageRep(data: containerData)
        else { fail("the empty container should show what its sublayers draw") }
        expect(
            containerImage.pixelsWide == 40 && containerImage.pixelsHigh == 40,
            "the image covers the sublayer's drawing; got \(containerImage.pixelsWide) x \(containerImage.pixelsHigh)"
        )
        let items = flattened(file.hierarchyInfo?.displayItems ?? [])
        guard items.count == 3 else { fail("the tree should have three nodes, got \(items.count)") }
        expect(
            items[1].groupScreenshotRegion == CGRect(x: 30, y: 30, width: 40, height: 40),
            "the region places the image where the sublayer is; got \(items[1].groupScreenshotRegion)"
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

    // MARK: - Views

    /// AppKit names the layer it makes for a view after the view's class and
    /// marks every layer a view installs; a view node carries that class and
    /// the layer folded in, while a layer added beside it stays a layer node.
    @MainActor
    private static func testViewLayersBecomeViewNodes() {
        let (contentView, window) = makingLayerBackedContentView()
        let markerView = CoreAnimationArchiveMarkerView(frame: NSRect(x: 10, y: 10, width: 40, height: 40))
        contentView.addSubview(markerView)
        let plainSublayer = makingLayer(CGRect(x: 0, y: 0, width: 5, height: 5))
        settlingLayers(of: window)
        markerView.layer?.addSublayer(plainSublayer)

        guard let contentLayer = contentView.layer else { fail("the content view should have a layer") }
        let items = flattened(convertedFile(of: contentLayer).hierarchyInfo?.displayItems ?? [])
        guard let contentItem = items.first,
              let markerItem = items.first(where: { $0.viewObject?.classChainList?.first == NSStringFromClass(CoreAnimationArchiveMarkerView.self) }),
              let plainItem = markerItem.subitems?.first(where: { $0.nodeKind == .layer })
        else { fail("the tree should hold the content view, the marker view and the plain sublayer, got \(items.map(\.nodeKind))") }

        expect(contentItem.nodeKind == .view, "the content view's layer should become a view node")
        expect(contentItem.viewObject?.classChainList == ["NSView", "NSResponder", "NSObject"], "AppKit's NSView should get its whole chain, got \(String(describing: contentItem.viewObject?.classChainList))")
        expect(markerItem.nodeKind == .view, "the marker view's layer should become a view node")
        expect(
            markerItem.viewObject?.classChainList == [NSStringFromClass(CoreAnimationArchiveMarkerView.self), "NSView", "NSResponder", "NSObject"],
            "a class this process has should get its whole chain, got \(String(describing: markerItem.viewObject?.classChainList))"
        )
        let classCard = attributesByIdentifier(of: markerItem)[LookinAttr_Class_Class_Class]?.value as? [[String]]
        expect(
            classCard == [[NSStringFromClass(CoreAnimationArchiveMarkerView.self), "NSView"]],
            "a view node's Class card should list the view's chain up to NSView, got \(String(describing: classCard))"
        )
        expect(markerItem.layerObject?.classChainList?.first == "CALayer", "the folded-in layer should keep its decoded class")
        expect(plainItem.viewObject == nil, "a layer the view did not install should stay a bare layer node")

        let layerObjectIdentifiers = Set(items.compactMap { $0.layerObject?.oid })
        let viewObjectIdentifiers = items.compactMap { $0.viewObject?.oid }
        expect(viewObjectIdentifiers.allSatisfy { $0 != 0 }, "every view needs an oid")
        expect(
            layerObjectIdentifiers.isDisjoint(with: viewObjectIdentifiers) && Set(viewObjectIdentifiers).count == viewObjectIdentifiers.count,
            "view oids must collide with no layer oid and no other view oid"
        )
        expect(layerObjectIdentifiers == Set(1 ... UInt(items.count)), "layers should keep their depth-first numbers")
    }

    /// A view whose `-makeBackingLayer` returns a layer of another class is
    /// named `"<layer class>: <view class>"`: the view node takes the view's
    /// class, and the folded-in layer gets back the class the archive cut.
    @MainActor
    private static func testCustomBackingLayerNamesBothClasses() {
        let (contentView, window) = makingLayerBackedContentView()
        let shapeBackedView = CoreAnimationArchiveShapeBackedView(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
        contentView.addSubview(shapeBackedView)
        settlingLayers(of: window)
        let expectedName = "CAShapeLayer: \(NSStringFromClass(CoreAnimationArchiveShapeBackedView.self))"
        expect(shapeBackedView.layer?.name == expectedName, "AppKit should have named the layer \(expectedName), got \(String(describing: shapeBackedView.layer?.name))")

        guard let contentLayer = contentView.layer else { fail("the content view should have a layer") }
        let items = flattened(convertedFile(of: contentLayer).hierarchyInfo?.displayItems ?? [])
        guard let shapeItem = items.first(where: { $0.viewObject?.classChainList?.first == NSStringFromClass(CoreAnimationArchiveShapeBackedView.self) }) else {
            fail("the shape-backed view should become a view node")
        }
        expect(shapeItem.layerObject?.classChainList == ["CAShapeLayer", "CALayer", "NSObject"], "the layer's class should come from its name, got \(String(describing: shapeItem.layerObject?.classChainList))")
    }

    /// The dumped app's own view classes are not in this process: the node
    /// keeps the class name the layer was given and claims no superclasses.
    @MainActor
    private static func testViewClassThisProcessLacksKeepsItsName() {
        let (contentView, window) = makingLayerBackedContentView()
        let appView = NSView(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
        contentView.addSubview(appView)
        settlingLayers(of: window)
        appView.layer?.name = "DumpedAppOnlyView"

        guard let contentLayer = contentView.layer else { fail("the content view should have a layer") }
        let items = flattened(convertedFile(of: contentLayer).hierarchyInfo?.displayItems ?? [])
        guard let appItem = items.first(where: { $0.viewObject?.classChainList?.first == "DumpedAppOnlyView" }) else {
            fail("a view of a class this process lacks should still become a view node")
        }
        expect(appItem.viewObject?.classChainList == ["DumpedAppOnlyView"], "an unknown class should claim no superclasses, got \(String(describing: appItem.viewObject?.classChainList))")
        let classCard = attributesByIdentifier(of: appItem)[LookinAttr_Class_Class_Class]?.value as? [[String]]
        expect(classCard == [["DumpedAppOnlyView"]], "the Class card should list just the name, got \(String(describing: classCard))")
    }

    /// Only a layer both marked by `-[NSView setLayer:]` and named like a view
    /// class is a view. The window's own layers are marked but named
    /// otherwise; layers other code names keep the default edges; a layer an
    /// app hands its view has the mark but no name.
    private static func testUnmarkedOrMisnamedLayersStayLayers() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 40, height: 40))
        let contentLayer = makingMarkedLayer(named: "NSWindow content layer")
        let windowClassLayer = makingMarkedLayer(named: "NSWindow")
        let unmarkedLayer = makingLayer(CGRect(x: 0, y: 0, width: 10, height: 10))
        unmarkedLayer.name = "NSTextField"
        let hostedLayer = makingMarkedLayer(named: nil)
        for sublayer in [contentLayer, windowClassLayer, unmarkedLayer, hostedLayer] {
            rootLayer.addSublayer(sublayer)
        }

        let items = flattened(convertedFile(of: rootLayer).hierarchyInfo?.displayItems ?? [])
        expect(items.count == 5, "the tree should have five nodes, got \(items.count)")
        expect(items.allSatisfy { $0.nodeKind == .layer && $0.viewObject == nil }, "none of these layers backed a view, got \(items.map(\.nodeKind))")
    }

    /// Layers other code named (`NSCGSWindow`, `CUIWindowFrameLayer`,
    /// `CAHostingLayer`) read by that name, as in Mica; an unnamed one by its
    /// class, and a view by its view's class.
    private static func testNamedLayersShowTheirNames() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 40, height: 40))
        rootLayer.name = "NSCGSWindow"
        let unnamedLayer = makingLayer(CGRect(x: 0, y: 0, width: 10, height: 10))
        let emptyNamedLayer = makingLayer(CGRect(x: 0, y: 0, width: 10, height: 10))
        emptyNamedLayer.name = ""
        let viewLayer = makingMarkedLayer(named: "NSTextField")
        for sublayer in [unnamedLayer, emptyNamedLayer, viewLayer] {
            rootLayer.addSublayer(sublayer)
        }

        let items = flattened(convertedFile(of: rootLayer).hierarchyInfo?.displayItems ?? [])
        guard items.count == 4 else { fail("the tree should have four nodes, got \(items.count)") }
        expect(items[0].customDisplayTitle == "NSCGSWindow", "a named layer should be titled by its name, got \(String(describing: items[0].customDisplayTitle))")
        expect(items[1].customDisplayTitle == nil, "an unnamed layer should fall back to its class")
        expect(items[2].customDisplayTitle == nil, "an empty name should fall back to the class rather than leave the row blank")
        expect(items[3].nodeKind == .view && items[3].customDisplayTitle == nil, "a view node should be titled by its view's class")
    }

    /// A scrolled or inset clip view's layer is flipped and has a bounds
    /// origin other than zero; what sits at that origin shows at its top. The
    /// marker must land there in the inspector's bottom-up root space, not
    /// one inset lower.
    private static func testSublayersOfAScrolledFlippedLayerSitWhereTheyShow() {
        let rootLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        let clipLayer = makingLayer(CGRect(x: 0, y: 0, width: 100, height: 100))
        clipLayer.isGeometryFlipped = true
        clipLayer.bounds = CGRect(x: 0, y: -30, width: 100, height: 100)
        let markerLayer = makingLayer(CGRect(x: 0, y: -30, width: 100, height: 10))
        clipLayer.addSublayer(markerLayer)
        rootLayer.addSublayer(clipLayer)

        let items = flattened(convertedFile(of: rootLayer).hierarchyInfo?.displayItems ?? [])
        guard items.count == 3 else { fail("the tree should have three nodes, got \(items.count)") }
        let markerFrame = items[2].calculateFrameToRoot()
        expect(markerFrame == CGRect(x: 0, y: 90, width: 100, height: 10), "the marker should sit at the top of the clip layer, got \(markerFrame)")
    }

    /// The Liquid Glass setting's Hide leaves the glass behind a split view
    /// item out of an import's images. A decoded archive has no `SDFLayer`
    /// to name the glass, so the glass is found by its backdrop in the view
    /// the glass view draws it in (`CoreAnimationArchiveGlass`), and the
    /// recovery leaves it out with what is under it: the glass view's image
    /// then holds no glass, the content the glass draws through its portals
    /// still shows where it is, and the glass gets no image of its own.
    @MainActor
    private static func testHiddenGlassIsLeftOutOfTheImages() {
        guard #available(macOS 26.0, *) else {
            print("skipped testHiddenGlassIsLeftOutOfTheImages: NSGlassEffectView needs macOS 26")
            return
        }
        guard MTLCreateSystemDefaultDevice() != nil else {
            print("skipped testHiddenGlassIsLeftOutOfTheImages: no Metal device")
            return
        }
        let (contentView, window) = makingLayerBackedContentView()
        window.appearance = NSAppearance(named: .darkAqua)
        window.setContentSize(NSSize(width: 300, height: 100))
        let glassView = NSGlassEffectView(frame: NSRect(x: 20, y: 30, width: 200, height: 40))
        glassView.contentView = NSTextField(labelWithString: "Filter")
        contentView.addSubview(glassView)
        settlingLayers(of: window)
        guard let contentLayer = contentView.layer else { fail("the content view should have a layer") }
        let tree = withExtendedLifetime(window) { CoreAnimationArchiveLayerTree(contents: decodedContents(of: contentLayer)) }

        let glassLayers = tree.layers.filter { CoreAnimationArchiveGlass.viewAncestorClassChains(ofGlassLayer: $0) != nil }
        guard glassLayers.count == 1, let glassLayer = glassLayers.first,
              let viewAncestorClassChains = CoreAnimationArchiveGlass.viewAncestorClassChains(ofGlassLayer: glassLayer)
        else { fail("the glass view should hold one glass layer, got \(glassLayers.count)") }
        // The view the glass is drawn in, the glass view, the content view.
        expect(
            viewAncestorClassChains.count == 3
                && !viewAncestorClassChains[0].contains("NSGlassEffectView")
                && viewAncestorClassChains[1].first == "NSGlassEffectView",
            "the glass should be drawn in a view right under the glass view, got \(viewAncestorClassChains)"
        )
        guard let glassViewIndex = tree.layers.firstIndex(where: {
            CoreAnimationArchiveViewIdentity(layer: $0)?.viewClassChain.first == "NSGlassEffectView"
        }) else { fail("the archive should hold the glass view") }

        let shown = recoveredScreenshots(of: tree)
        let hidden: CoreAnimationArchiveScreenshots
        do {
            hidden = try CoreAnimationArchivePixelRecovery.recovering(from: tree, hidingGlass: { $0 === glassLayer })
        } catch {
            fail("pixel recovery failed: \(error)")
        }
        func coverage(of screenshots: CoreAnimationArchiveScreenshots) -> (opaque: Double, visible: Double) {
            guard let data = screenshots.groupByObjectIdentifier[UInt(glassViewIndex + 1)],
                  let image = NSBitmapImageRep(data: data)?.cgImage
            else { return (0, 0) }
            let pixels = premultipliedPixels(of: image)
            var opaque = 0
            var visible = 0
            for index in stride(from: 3, to: pixels.count, by: 4) {
                if pixels[index] > 200 { opaque += 1 }
                if pixels[index] > 16 { visible += 1 }
            }
            let count = Double(image.width * image.height)
            return (Double(opaque) / count, Double(visible) / count)
        }
        let shownCoverage = coverage(of: shown)
        let hiddenCoverage = coverage(of: hidden)
        expect(shownCoverage.opaque > 0.6, "with the glass shown it should cover the view, got \(shownCoverage.opaque)")
        expect(hiddenCoverage.opaque < 0.3, "with the glass left out only the label should be opaque, got \(hiddenCoverage.opaque)")
        expect(hiddenCoverage.visible > 0.005, "the label should still show with the glass left out, got \(hiddenCoverage.visible)")
        for (index, layer) in tree.layers.enumerated() where XcodeViewHierarchyPixelRecovery.isInside(layer, anyOf: [glassLayer]) {
            let objectIdentifier = UInt(index + 1)
            expect(
                hidden.groupByObjectIdentifier[objectIdentifier] == nil && hidden.soloByObjectIdentifier[objectIdentifier] == nil,
                "#\(objectIdentifier), in the glass left out, should get no image"
            )
        }
    }

    // MARK: - Helpers

    private typealias EncodeLayerTreeFunction = @convention(c) (CALayer) -> Unmanaged<NSData>?

    /// A content view AppKit has given a layer, in a window never put on
    /// screen.
    @MainActor
    private static func makingLayerBackedContentView() -> (NSView, NSWindow) {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        guard let contentView = window.contentView else { fail("the window should have a content view") }
        contentView.wantsLayer = true
        return (contentView, window)
    }

    /// Lets AppKit build the layers of views added since the last pass.
    @MainActor
    private static func settlingLayers(of window: NSWindow) {
        window.displayIfNeeded()
        CATransaction.flush()
    }

    /// A layer carrying the mark `-[NSView setLayer:]` leaves on the layers
    /// it installs.
    private static func makingMarkedLayer(named name: String?) -> CALayer {
        let layer = makingLayer(CGRect(x: 0, y: 0, width: 10, height: 10))
        layer.edgeAntialiasingMask = []
        layer.name = name
        return layer
    }

    private static func makingLayer(_ frame: CGRect) -> CALayer {
        let layer = CALayer()
        layer.frame = frame
        return layer
    }

    /// A square image filled with `color`, `side` pixels on a side.
    private static func makingImage(of color: CGColor, side: Int) -> CGImage? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: side,
                  height: side,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return nil }
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        return context.makeImage()
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
        let capture = CoreAnimationArchiveCapture(tree: tree, screenshots: recoveredScreenshots(of: tree), origin: origin)
        return CoreAnimationArchiveConverter.makingHierarchyFile(from: capture)
    }

    private static func recoveredScreenshots(of tree: CoreAnimationArchiveLayerTree) -> CoreAnimationArchiveScreenshots {
        do {
            return try CoreAnimationArchivePixelRecovery.recovering(from: tree)
        } catch {
            fail("pixel recovery failed: \(error)")
        }
    }

    /// The pixels of the group image of node `objectIdentifier` where it
    /// shows `rect`, a rect in the archive root's space: red, green, blue and
    /// alpha, premultiplied, from 0 to 1. Nil when the node has no image
    /// there.
    private static func sampledPixels(
        of rect: CGRect,
        inImageOf objectIdentifier: UInt,
        tree: CoreAnimationArchiveLayerTree,
        screenshots: CoreAnimationArchiveScreenshots
    ) -> [[Double]]? {
        guard let data = screenshots.groupByObjectIdentifier[objectIdentifier],
              let image = NSBitmapImageRep(data: data)?.cgImage
        else { return nil }
        let layer = tree.layers[Int(objectIdentifier) - 1]
        let bounds = layer.bounds
        // The image covers its region, measured from the bounds origin, or
        // the whole bounds; its top row is the layer's top as it shows.
        let region = screenshots.groupRegionByObjectIdentifier[objectIdentifier]
            .map { $0.offsetBy(dx: bounds.origin.x, dy: bounds.origin.y) } ?? bounds
        let rectInLayer = tree.rootLayer.convert(rect, to: layer)
        let horizontalScale = CGFloat(image.width) / region.width
        let verticalScale = CGFloat(image.height) / region.height
        let top = layer.contentsAreFlipped() ? rectInLayer.minY - region.minY : region.maxY - rectInLayer.maxY
        let pixelRect = CGRect(
            x: (rectInLayer.minX - region.minX) * horizontalScale,
            y: top * verticalScale,
            width: rectInLayer.width * horizontalScale,
            height: rectInLayer.height * verticalScale
        ).integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard !pixelRect.isEmpty else { return nil }
        let pixels = premultipliedPixels(of: image)
        var sampled: [[Double]] = []
        for row in Int(pixelRect.minY) ..< Int(pixelRect.maxY) {
            for column in Int(pixelRect.minX) ..< Int(pixelRect.maxX) {
                let pixelStart = (row * image.width + column) * 4
                sampled.append((0 ..< 4).map { Double(pixels[pixelStart + $0]) / 255 })
            }
        }
        return sampled
    }

    /// The average colour, red, green and blue unpremultiplied, of where the
    /// group image of node `objectIdentifier` shows `rect`, a rect in the
    /// archive root's space; or, given `background`, the average of that
    /// image laid over it there. Nil when the node has no image there.
    private static func averageColor(
        of rect: CGRect,
        inImageOf objectIdentifier: UInt,
        tree: CoreAnimationArchiveLayerTree,
        screenshots: CoreAnimationArchiveScreenshots,
        over background: [Double]? = nil
    ) -> [Double]? {
        guard let pixels = sampledPixels(of: rect, inImageOf: objectIdentifier, tree: tree, screenshots: screenshots) else {
            return nil
        }
        if let background {
            return (0 ..< 3).map { channel in
                pixels.reduce(0) { $0 + $1[channel] + (1 - $1[3]) * background[channel] } / Double(pixels.count)
            }
        }
        let alphaSum = pixels.reduce(0) { $0 + $1[3] }
        guard alphaSum > 0 else { return nil }
        return (0 ..< 3).map { channel in pixels.reduce(0) { $0 + $1[channel] } / alphaSum }
    }

    /// The average alpha of where the group image of node `objectIdentifier`
    /// shows `rect`, a rect in the archive root's space.
    private static func averageAlpha(
        of rect: CGRect,
        inImageOf objectIdentifier: UInt,
        tree: CoreAnimationArchiveLayerTree,
        screenshots: CoreAnimationArchiveScreenshots
    ) -> Double? {
        guard let pixels = sampledPixels(of: rect, inImageOf: objectIdentifier, tree: tree, screenshots: screenshots) else {
            return nil
        }
        return pixels.reduce(0) { $0 + $1[3] } / Double(pixels.count)
    }

    /// The image's pixels as premultiplied RGBA bytes in sRGB, top row first.
    private static func premultipliedPixels(of image: CGImage) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        pixels.withUnsafeMutableBytes { buffer in
            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                      data: buffer.baseAddress,
                      width: image.width,
                      height: image.height,
                      bitsPerComponent: 8,
                      bytesPerRow: image.width * 4,
                      space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  )
            else { return }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return pixels
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

/// A view class of the test's own, which this process has but AppKit does not.
final class CoreAnimationArchiveMarkerView: NSView {}

/// A view that makes its own layer, of a class other than AppKit's
/// `NSViewBackingLayer`.
final class CoreAnimationArchiveShapeBackedView: NSView {
    override func makeBackingLayer() -> CALayer {
        CAShapeLayer()
    }
}
