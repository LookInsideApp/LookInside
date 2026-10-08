import AppKit
import Foundation
import QuartzCore

/// Coverage for recovering pixels from a capture's layer archives.
///
/// The orientation cases are the reason this file exists. Two facts about
/// Core Animation govern them: `isGeometryFlipped` is relative to the
/// superlayer, and it is ignored on whichever layer is the root of a render.
/// So a y-down (UIKit) tree needs the flag on its root only, and any layer
/// whose cumulative flip is odd needs its render context flipped when drawn
/// on its own. Getting either wrong produces an image no assertion on file
/// size or pixel count would catch: subviews in reverse order, every glyph
/// mirrored, or a flipped subtree upside down while the whole window is
/// fine. The tests below place markers in known places and check where they
/// land, which is the smallest thing that can tell those apart.
@main
struct XcodeViewHierarchyPixelRecoveryTests {
    static func main() {
        testUnflippedTreeKeepsSublayerPosition()
        testFlippedTreeInvertsSublayerPosition()
        testRecoveryAppliesTheGeometryFlipItself()
        testFlippedSubtreeRendersAsItDoesInsideItsRoot()
        testNestedLayersOfAYDownTreeKeepTheirOrderAtEveryDepth()
        testCancelledRecoveryProducesNoImages()
        testLayerImagesLeaveOutTheViewsBeneath()
        testEmptyLayerProducesNoImage()
        testZeroSizedLayerProducesNoImage()
        testLargeLayerIsScaledWithinTheCap()
        testTallLayerStaysWithinTheTextureEdge()
        testPlainColorLayersRenderNoImageOfTheirOwn()
        testSparseLayerIsRenderedOnlyWhereItDraws()
        testArchiveRoundTripsThroughDecoder()
        testMalformedArchiveIsRejected()
        print("Xcode view hierarchy pixel recovery tests passed")
    }

    // MARK: - Orientation

    /// AppKit captures are already y-up and need no correction: a band pinned
    /// at the coordinate origin occupies the *bottom* of the image, with its
    /// content the right way up.
    private static func testUnflippedTreeKeepsSublayerPosition() {
        guard let rendered = renderedFixture(applyingGeometryFlip: false, flippingContext: false) else {
            fail("unflipped render produced no image")
        }
        expect(rendered.bandIsAtBottom, "a y-up tree should put the band at the bottom")
        expect(rendered.contentIsUpright, "a y-up tree should not mirror the band's content")
    }

    /// UIKit captures are y-down, and correcting them takes both halves: the
    /// geometry flag on the root, and the context flip when rendering.
    ///
    /// The two assertions here are what tell the halves apart. Dropping the
    /// context flip leaves the band at the bottom; dropping the geometry flag
    /// leaves the band in the right place but mirrors its content, which on a
    /// real capture means every glyph reads backwards.
    private static func testFlippedTreeInvertsSublayerPosition() {
        guard let rendered = renderedFixture(applyingGeometryFlip: true, flippingContext: true) else {
            fail("flipped render produced no image")
        }
        expect(rendered.bandIsAtTop, "a y-down tree should put the band at the top")
        expect(rendered.contentIsUpright, "a y-down tree should not mirror the band's content")
    }

    /// The two previous cases prepare the tree themselves, so they would still
    /// pass if the recovery entry point stopped marking y-down trees. This one
    /// goes through `recovering(from:)` with nothing but a capture, which is
    /// the only way to catch that half going missing.
    private static func testRecoveryAppliesTheGeometryFlipItself() {
        guard let archiveData = archiveData(rootLayer: orientationFixture(), geometryFlipped: true) else {
            fail("could not build the archive fixture")
        }
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: [
            "version": NSNumber(value: 2),
            "topLevelGroups": [
                "com.apple.QuartzCore.CALayer": [
                    "groupingID": "com.apple.QuartzCore.CALayer",
                    "debugHierarchyObjects": [["objectID": "0x1", "className": "CALayer"]],
                ],
            ],
            "topLevelPropertyDescriptions": [
                "0x1.encodedPresentationLayer": [
                    "propertyName": "encodedPresentationLayer",
                    "propertyFormat": "public.data",
                    "propertyValue": archiveData.base64EncodedString(),
                    "fetchStatus": NSNumber(value: 4),
                ],
            ],
        ])

        let screenshots = XcodeViewHierarchyPixelRecovery.recovering(from: builder.build())
        guard let groupImage = screenshots.groupByObjectIdentifier["0x1"] else {
            fail("recovery produced no image for the captured layer")
        }
        guard let bitmap = NSBitmapImageRep(data: groupImage) else { fail("recovered data was not a bitmap") }
        let rendered = measuring(bitmap)
        expect(rendered.bandIsAtTop, "recovery must put a y-down capture's band at the top")
        expect(rendered.contentIsUpright, "recovery must not leave a y-down capture's content mirrored")
    }

    /// AppKit marks a flipped view's layer geometry-flipped *relative to its
    /// superlayer*, and Core Animation ignores that flag on whichever layer is
    /// the root of a render. A flipped subtree rendered on its own therefore
    /// comes out mirrored unless the context is flipped for it — which is how
    /// every outline view, text view and split view of an imported Xcode
    /// window came back upside down while the window as a whole rendered
    /// fine. The contract: a layer's own image looks exactly like its region
    /// of the root's image.
    private static func testFlippedSubtreeRendersAsItDoesInsideItsRoot() {
        let root = CALayer()
        root.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let flippedChild = CALayer()
        flippedChild.bounds = CGRect(x: 0, y: 0, width: 100, height: 40)
        markingAsDrawingEverywhere(flippedChild)
        flippedChild.anchorPoint = .zero
        flippedChild.position = CGPoint(x: 0, y: 60) // the top 40 rows of the root
        flippedChild.isGeometryFlipped = true
        let band = CALayer()
        band.bounds = CGRect(x: 0, y: 0, width: 100, height: 20)
        band.anchorPoint = .zero
        band.position = .zero
        band.contents = twoToneImage()
        band.contentsGravity = .resize
        flippedChild.addSublayer(band)
        root.addSublayer(flippedChild)

        guard let rootData = XcodeViewHierarchyPixelRecovery.renderingPNG(
            of: root, includingSublayers: true, isFlipped: false
        ), let rootImage = NSBitmapImageRep(data: rootData)?.cgImage,
        let childRegion = rootImage.cropping(
            to: CGRect(x: 0, y: 0, width: rootImage.width, height: rootImage.height * 40 / 100)
        ) else { fail("could not render the root fixture") }
        let insideRoot = measuring(NSBitmapImageRep(cgImage: childRegion))

        guard let archiveData = archiveData(rootLayer: root, geometryFlipped: false) else {
            fail("could not build the archive fixture")
        }
        let screenshots = XcodeViewHierarchyPixelRecovery.recovering(
            from: layerCapture(archiveData: archiveData, tree: LayerNodeFixture("0x1", [LayerNodeFixture("0x2")]))
        )
        guard let childData = screenshots.groupByObjectIdentifier["0x2"],
              let childBitmap = NSBitmapImageRep(data: childData)
        else { fail("recovery produced no image for the flipped child") }
        let onItsOwn = measuring(childBitmap)

        expect(onItsOwn.bandIsAtTop == insideRoot.bandIsAtTop && onItsOwn.bandIsAtBottom == insideRoot.bandIsAtBottom,
               "the flipped child's band moved: inside the root it is at the \(insideRoot.bandIsAtTop ? "top" : "bottom"), on its own at the \(onItsOwn.bandIsAtTop ? "top" : "bottom")")
        expect(onItsOwn.contentIsUpright == insideRoot.contentIsUpright,
               "the flipped child's content is mirrored relative to how it renders inside the root")
    }

    /// `isGeometryFlipped` is relative to the superlayer, so marking every
    /// layer of a y-down tree flips each level back and forth: depth one
    /// comes out right, depth two upside down again. Only the root may carry
    /// the flag; every layer then inherits the y-down axis, and each layer's
    /// own render is flipped exactly when its cumulative parity is odd.
    private static func testNestedLayersOfAYDownTreeKeepTheirOrderAtEveryDepth() {
        // Positions as UIKit archives them: y measured downwards.
        let root = coloredLayer(width: 100, height: 100, at: .zero, color: .white)
        let levelOne = coloredLayer(width: 100, height: 40, at: .zero, color: .blue) // top of the root
        let bandOne = coloredLayer(width: 100, height: 10, at: .zero, color: .red) // top of level one
        let levelTwo = coloredLayer(width: 100, height: 20, at: CGPoint(x: 0, y: 20), color: .yellow) // lower half of level one
        let bandTwo = coloredLayer(width: 100, height: 5, at: .zero, color: .green) // top of level two
        levelTwo.addSublayer(bandTwo)
        levelOne.addSublayer(bandOne)
        levelOne.addSublayer(levelTwo)
        root.addSublayer(levelOne)

        guard let archiveData = archiveData(rootLayer: root, geometryFlipped: true) else {
            fail("could not build the archive fixture")
        }
        let capture = layerCapture(archiveData: archiveData, tree: LayerNodeFixture("0x1", [
            LayerNodeFixture("0x2", [
                LayerNodeFixture("0x3"),
                LayerNodeFixture("0x4", [LayerNodeFixture("0x5")]),
            ]),
        ]))
        let screenshots = XcodeViewHierarchyPixelRecovery.recovering(from: capture)

        expectRows(screenshots, "0x1", "the root", [(5, "red"), (15, "blue"), (22, "green"), (30, "yellow"), (50, "white")])
        expectRows(screenshots, "0x2", "level one", [(5, "red"), (15, "blue"), (22, "green"), (30, "yellow")])
        expectRows(screenshots, "0x4", "level two", [(2, "green"), (10, "yellow")])
    }

    // MARK: - Views beneath a layer

    /// A layer node's group image must leave out the subtrees of the layers
    /// that back a view — those render on nodes of their own — while the
    /// node's plain group image, which a merged view node shows folded, keeps
    /// them. The root here has one sublayer a view owns (a red band on top)
    /// and one orphan (a blue band at the bottom).
    private static func testLayerImagesLeaveOutTheViewsBeneath() {
        let root = coloredLayer(width: 100, height: 100, at: .zero, color: .white)
        let hosted = coloredLayer(width: 100, height: 40, at: CGPoint(x: 0, y: 60), color: .red)
        hosted.borderWidth = 1 // draws more than a plain fill, so it keeps an image of its own
        let orphan = coloredLayer(width: 100, height: 40, at: .zero, color: .blue)
        root.addSublayer(hosted)
        root.addSublayer(orphan)
        guard let archiveData = archiveData(rootLayer: root, geometryFlipped: false) else {
            fail("could not build the archive fixture")
        }
        let capture = layerCapture(
            archiveData: archiveData,
            tree: LayerNodeFixture("0x1", [LayerNodeFixture("0x2"), LayerNodeFixture("0x3")]),
            hostedLayerIdentifiers: ["0x2"]
        )
        let screenshots = XcodeViewHierarchyPixelRecovery.recovering(from: capture)
        expectRows(screenshots, "0x1", "the root's group", [(10, "red"), (90, "blue")])
        guard let excludingData = screenshots.groupExcludingHostedViewsByObjectIdentifier["0x1"],
              let excludingBitmap = NSBitmapImageRep(data: excludingData)
        else { fail("recovery produced no image of the root without its hosted subtree") }
        let column = excludingBitmap.pixelsWide / 2
        let actual = [colorName(excludingBitmap, x: column, y: 10), colorName(excludingBitmap, x: column, y: 90)]
        expect(actual == ["white", "blue"], "the root without its hosted subtree: expected [white, blue], got \(actual)")
        expect(screenshots.groupExcludingHostedViewsByObjectIdentifier["0x3"] == nil,
               "a layer with no view beneath it needs no second image")
        expect(screenshots.groupByObjectIdentifier["0x2"] != nil, "the hosted layer still renders on its own")
    }

    // MARK: - Drawing region

    /// A scroll view's content layer is tens of thousands of points tall but
    /// only the visible band holds anything (a table view materialises rows
    /// as they scroll into view). Rendering the whole bounds spends the
    /// texture budget on blank space; rendering the region that draws keeps
    /// full resolution, and the region tells the preview where the image
    /// belongs. A layer that draws all over its bounds gets no region.
    private static func testSparseLayerIsRenderedOnlyWhereItDraws() {
        let content = CALayer()
        content.bounds = CGRect(x: 0, y: 0, width: 200, height: 4000)
        content.anchorPoint = .zero
        content.position = .zero
        let visibleRow = coloredLayer(width: 50, height: 50, at: CGPoint(x: 10, y: 3950), color: .red)
        visibleRow.borderWidth = 1
        content.addSublayer(visibleRow)
        let opaque = coloredLayer(width: 200, height: 100, at: .zero, color: .blue)
        opaque.borderWidth = 1
        let root = CALayer()
        root.bounds = CGRect(x: 0, y: 0, width: 200, height: 4000)
        root.addSublayer(content)
        root.addSublayer(opaque)
        guard let archiveData = archiveData(rootLayer: root, geometryFlipped: false) else {
            fail("could not build the archive fixture")
        }
        let capture = layerCapture(
            archiveData: archiveData,
            tree: LayerNodeFixture("0x1", [LayerNodeFixture("0x2", [LayerNodeFixture("0x3")]), LayerNodeFixture("0x4")])
        )
        let screenshots = XcodeViewHierarchyPixelRecovery.recovering(from: capture)
        guard let contentData = screenshots.groupByObjectIdentifier["0x2"],
              let contentBitmap = NSBitmapImageRep(data: contentData)
        else { fail("the sparse content layer should still render") }
        expect(contentBitmap.pixelsWide == 50 && contentBitmap.pixelsHigh == 50,
               "only the drawn region is rendered; got \(contentBitmap.pixelsWide)x\(contentBitmap.pixelsHigh)")
        expect(screenshots.groupRegionByObjectIdentifier["0x2"] == CGRect(x: 10, y: 3950, width: 50, height: 50),
               "the region records where the image belongs; got \(String(describing: screenshots.groupRegionByObjectIdentifier["0x2"]))")
        expect(screenshots.groupRegionByObjectIdentifier["0x4"] == nil, "a layer drawing all over its bounds needs no region")
        expect(screenshots.groupRegionByObjectIdentifier["0x1"] == nil,
               "the root draws from its bottom band to its top row, so its region is the whole bounds")
    }

    // MARK: - Cancellation

    /// The document cancels a running import when its window closes, and the
    /// recovery is the phase that takes the time, so it has to notice.
    private static func testCancelledRecoveryProducesNoImages() {
        guard let archiveData = archiveData(rootLayer: orientationFixture(), geometryFlipped: false) else {
            fail("could not build the archive fixture")
        }
        let capture = layerCapture(archiveData: archiveData, tree: LayerNodeFixture("0x1", [LayerNodeFixture("0x2")]))
        let cancelled = XcodeViewHierarchyPixelRecovery.recovering(from: capture, isCancelled: { true })
        expect(cancelled.groupByObjectIdentifier.isEmpty && cancelled.soloByObjectIdentifier.isEmpty,
               "a cancelled recovery must not hand back images")
        let completed = XcodeViewHierarchyPixelRecovery.recovering(from: capture)
        expect(!completed.groupByObjectIdentifier.isEmpty, "the same capture renders when not cancelled")
    }

    // MARK: - Skipping

    /// Most layers in a capture draw nothing. Keeping their empty images would
    /// multiply a document's memory for no visible gain.
    private static func testEmptyLayerProducesNoImage() {
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        expect(XcodeViewHierarchyPixelRecovery.renderingPNG(
            of: layer, includingSublayers: true, isFlipped: false
        ) == nil, "a fully transparent layer should not produce an image")
    }

    private static func testZeroSizedLayerProducesNoImage() {
        let layer = CALayer()
        layer.bounds = .zero
        layer.backgroundColor = NSColor.red.cgColor
        expect(XcodeViewHierarchyPixelRecovery.renderingPNG(
            of: layer, includingSublayers: true, isFlipped: false
        ) == nil, "a zero-sized layer should not produce an image")
    }

    /// A full-screen retina layer is already megapixels and a capture holds
    /// thousands; without the cap a large window costs gigabytes to import.
    private static func testLargeLayerIsScaledWithinTheCap() {
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: 6000, height: 4000)
        layer.contentsScale = 2
        layer.backgroundColor = NSColor.red.cgColor
        layer.borderWidth = 1 // something to draw, so the plain-colour skip does not apply
        guard let data = XcodeViewHierarchyPixelRecovery.renderingPNG(
            of: layer, includingSublayers: true, isFlipped: false
        ) else { fail("a large opaque layer should still render") }
        guard let image = NSBitmapImageRep(data: data) else { fail("rendered data was not a bitmap") }
        let renderedPixelCount = image.pixelsWide * image.pixelsHigh
        expect(renderedPixelCount <= XcodeViewHierarchyPixelRecovery.maximumRenderedPixelCount,
               "rendered \(renderedPixelCount) pixels, above the cap")
        expect(image.pixelsWide > 4000, "the cap should reduce the scale, not the usefulness")
    }

    /// A folded node's image covers its whole subtree, and a scroll view's
    /// content can be tens of thousands of points tall. The preview cannot
    /// upload a texture longer than 16384 pixels on a side, so such a layer
    /// renders coarser to fit — never dropped, which would leave a hole.
    private static func testTallLayerStaysWithinTheTextureEdge() {
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: 600, height: 21530)
        layer.contentsScale = 2
        layer.backgroundColor = NSColor.red.cgColor
        layer.borderWidth = 1
        let scale = XcodeViewHierarchyPixelRecovery.renderingScale(for: layer)
        expect(abs(scale - 16384.0 / 21530.0) < 0.001, "the longest side sets the scale; got \(scale)")
        guard let data = XcodeViewHierarchyPixelRecovery.renderingPNG(
            of: layer, includingSublayers: true, isFlipped: false
        ) else { fail("a tall layer should still render") }
        guard let image = NSBitmapImageRep(data: data) else { fail("rendered data was not a bitmap") }
        expect(image.pixelsHigh <= 16384, "a side longer than the texture limit; got \(image.pixelsHigh)")
        expect(image.pixelsHigh > 16000, "the tall side should use the whole texture edge; got \(image.pixelsHigh)")
    }

    /// A plain CALayer with nothing but a background colour needs no image:
    /// the inspector paints the node's colour where an image is missing.
    /// Its subtree still gets a group image, and a layer that draws anything
    /// else (a border here) keeps its own.
    private static func testPlainColorLayersRenderNoImageOfTheirOwn() {
        let root = coloredLayer(width: 60, height: 60, at: .zero, color: .red)
        let plainChild = coloredLayer(width: 20, height: 20, at: .zero, color: .blue)
        let borderedChild = coloredLayer(width: 20, height: 20, at: CGPoint(x: 40, y: 40), color: .green)
        borderedChild.borderWidth = 2
        root.addSublayer(plainChild)
        root.addSublayer(borderedChild)
        guard let archiveData = archiveData(rootLayer: root, geometryFlipped: false) else {
            fail("could not build the archive fixture")
        }
        let capture = layerCapture(
            archiveData: archiveData,
            tree: LayerNodeFixture("0x1", [LayerNodeFixture("0x2"), LayerNodeFixture("0x3")])
        )
        let screenshots = XcodeViewHierarchyPixelRecovery.recovering(from: capture)
        expect(screenshots.groupByObjectIdentifier["0x1"] != nil, "a plain layer with sublayers still needs its group image")
        expect(screenshots.soloByObjectIdentifier["0x1"] == nil, "a plain layer's own picture is its background colour: no solo")
        expect(screenshots.groupByObjectIdentifier["0x2"] == nil, "a plain leaf layer needs no image at all")
        expect(screenshots.groupByObjectIdentifier["0x3"] != nil, "a layer that draws a border keeps its image")
    }

    // MARK: - Archive decoding

    /// The archive's root is a dictionary, not the layer itself; reading it as
    /// a layer yields nothing at all.
    private static func testArchiveRoundTripsThroughDecoder() {
        let root = orientationFixture()
        guard let archiveData = archiveData(rootLayer: root, geometryFlipped: true) else {
            fail("could not build the archive fixture")
        }
        guard let tree = XcodeViewHierarchyLayerArchive.decodingLayerTree(
            from: archiveData, rootObjectIdentifier: "0x1"
        ) else { fail("archive did not decode") }
        expect(tree.rootObjectIdentifier == "0x1", "root identifier should be carried through")
        expect(tree.isGeometryFlipped, "the geometryFlipped flag should survive the round trip")
        expect(tree.rootLayer.sublayers?.count == 1, "the sublayer should survive the round trip")
    }

    private static func testMalformedArchiveIsRejected() {
        let garbage = Data("not an archive".utf8)
        expect(XcodeViewHierarchyLayerArchive.decodingLayerTree(
            from: garbage, rootObjectIdentifier: "0x1"
        ) == nil, "a malformed archive must be rejected rather than trapping")
    }

    // MARK: - Fixtures

    /// A 100×100 root holding a 100×20 band pinned at the coordinate origin,
    /// whose contents image is red across its first rows and green across its
    /// last.
    ///
    /// Both asymmetries are needed. The band's *placement* reveals whether the
    /// render context was flipped; the *order of its colours* reveals whether
    /// the layers were marked geometry-flipped. A plain single-colour marker
    /// only shows the first, which is how a missing geometry flip once passed
    /// a test that was supposed to catch it.
    private static func orientationFixture() -> CALayer {
        let root = CALayer()
        root.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        markingAsDrawingEverywhere(root)

        let band = CALayer()
        band.bounds = CGRect(x: 0, y: 0, width: 100, height: 20)
        band.anchorPoint = .zero
        band.position = .zero
        band.contents = twoToneImage()
        band.contentsGravity = .resize
        root.addSublayer(band)
        return root
    }

    /// An image that is red across its first rows and green across its last.
    private static func twoToneImage() -> CGImage {
        let width = 100
        let height = 20
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { fail("could not build the two-tone fixture image") }
        // Core Graphics fills from the bottom, so the image's first rows are
        // the ones with the larger y.
        context.setFillColor(NSColor.green.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height / 2))
        context.setFillColor(NSColor.red.cgColor)
        context.fill(CGRect(x: 0, y: height / 2, width: width, height: height / 2))
        guard let image = context.makeImage() else { fail("could not rasterise the fixture image") }
        return image
    }

    private struct LayerNodeFixture {
        let identifier: String
        let children: [LayerNodeFixture]

        init(_ identifier: String, _ children: [LayerNodeFixture] = []) {
            self.identifier = identifier
            self.children = children
        }
    }

    /// A capture whose CALayer group mirrors `tree`, with the archive on its
    /// root. Each of `hostedLayerIdentifiers` gets a view that owns it.
    private static func layerCapture(
        archiveData: Data,
        tree: LayerNodeFixture,
        hostedLayerIdentifiers: [String] = []
    ) -> XcodeViewHierarchyObjectGraph {
        func describing(_ node: LayerNodeFixture) -> [String: Any] {
            var object: [String: Any] = ["objectID": node.identifier, "className": "CALayer"]
            if !node.children.isEmpty {
                object["childGroup"] = [
                    "groupingID": "com.apple.QuartzCore.CALayer",
                    "debugHierarchyObjects": node.children.map(describing),
                ]
            }
            return object
        }
        var topLevelGroups: [String: Any] = [
            "com.apple.QuartzCore.CALayer": [
                "groupingID": "com.apple.QuartzCore.CALayer",
                "debugHierarchyObjects": [describing(tree)],
            ],
        ]
        if !hostedLayerIdentifiers.isEmpty {
            topLevelGroups["com.apple.AppKit.NSView"] = [
                "groupingID": "com.apple.AppKit.NSView",
                "debugHierarchyObjects": hostedLayerIdentifiers.enumerated().map { index, layerIdentifier in
                    [
                        "objectID": "0xv\(index)",
                        "className": "NSView",
                        "additionalGroups": [[
                            "groupingID": "com.apple.QuartzCore.CALayer",
                            "debugHierarchyObjects": [["objectID": layerIdentifier]],
                        ]],
                    ] as [String: Any]
                },
            ]
        }
        let builder = XcodeViewHierarchyObjectGraphBuilder()
        builder.ingesting(response: [
            "version": NSNumber(value: 2),
            "topLevelGroups": topLevelGroups,
            "topLevelPropertyDescriptions": [
                "\(tree.identifier).encodedPresentationLayer": [
                    "propertyName": "encodedPresentationLayer",
                    "propertyFormat": "public.data",
                    "propertyValue": archiveData.base64EncodedString(),
                    "fetchStatus": NSNumber(value: 4),
                ],
            ],
        ])
        return builder.build()
    }

    /// Keeps a transparent fixture layer's drawing region at its whole
    /// bounds, so the orientation samples below stay where they were before
    /// recovery started rendering only the region a layer draws into: a
    /// border counts as drawing, and a clear one leaves every pixel as is.
    private static func markingAsDrawingEverywhere(_ layer: CALayer) {
        layer.borderWidth = 1
        layer.borderColor = NSColor.clear.cgColor
    }

    private static func coloredLayer(width: CGFloat, height: CGFloat, at position: CGPoint, color: NSColor) -> CALayer {
        let layer = CALayer()
        layer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        layer.anchorPoint = .zero
        layer.position = position
        layer.backgroundColor = color.cgColor
        return layer
    }

    /// Samples the middle column of a recovered image at the given rows,
    /// counted from the top, and names the colour found.
    private static func expectRows(
        _ screenshots: XcodeViewHierarchyScreenshots,
        _ objectIdentifier: String,
        _ label: String,
        _ expectations: [(row: Int, color: String)]
    ) {
        guard let data = screenshots.groupByObjectIdentifier[objectIdentifier],
              let bitmap = NSBitmapImageRep(data: data)
        else { fail("recovery produced no image for \(label)") }
        let column = bitmap.pixelsWide / 2
        let actual = expectations.map { colorName(bitmap, x: column, y: $0.row) }
        let expected = expectations.map(\.color)
        expect(actual == expected, "\(label) rows \(expectations.map(\.row)): expected \(expected), got \(actual)")
    }

    private static func archiveData(rootLayer: CALayer, geometryFlipped: Bool) -> Data? {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.encode(
            ["rootLayer": rootLayer, "geometryFlipped": NSNumber(value: geometryFlipped)] as NSDictionary,
            forKey: NSKeyedArchiveRootObjectKey
        )
        archiver.finishEncoding()
        return archiver.encodedData
    }

    private struct RenderedOrientation {
        let bandIsAtTop: Bool
        let bandIsAtBottom: Bool
        /// True when the band's red half precedes its green half, reading down.
        let contentIsUpright: Bool
    }

    private static func renderedFixture(
        applyingGeometryFlip shouldApplyGeometryFlip: Bool,
        flippingContext: Bool
    ) -> RenderedOrientation? {
        let root = orientationFixture()
        if shouldApplyGeometryFlip {
            applyGeometryFlip(to: root)
        }
        guard let data = XcodeViewHierarchyPixelRecovery.renderingPNG(
            of: root, includingSublayers: true, isFlipped: flippingContext
        ), let bitmap = NSBitmapImageRep(data: data) else { return nil }
        return measuring(bitmap)
    }

    /// Samples the two tenths at each end of the image.
    ///
    /// `NSBitmapImageRep` addresses rows from the top, so "top" and "bottom"
    /// here mean what someone looking at the image would say.
    private static func measuring(_ bitmap: NSBitmapImageRep) -> RenderedOrientation {
        let height = bitmap.pixelsHigh
        let column = bitmap.pixelsWide / 2
        let nearTop = colorName(bitmap, x: column, y: height * 5 / 100)
        let belowTop = colorName(bitmap, x: column, y: height * 15 / 100)
        let aboveBottom = colorName(bitmap, x: column, y: height * 85 / 100)
        let nearBottom = colorName(bitmap, x: column, y: height * 95 / 100)

        let bandIsAtTop = nearTop != "clear" && belowTop != "clear"
        let bandIsAtBottom = aboveBottom != "clear" && nearBottom != "clear"
        let contentIsUpright: Bool
        if bandIsAtTop {
            contentIsUpright = nearTop == "red" && belowTop == "green"
        } else if bandIsAtBottom {
            contentIsUpright = aboveBottom == "red" && nearBottom == "green"
        } else {
            contentIsUpright = false
        }
        return RenderedOrientation(
            bandIsAtTop: bandIsAtTop,
            bandIsAtBottom: bandIsAtBottom,
            contentIsUpright: contentIsUpright
        )
    }

    private static func colorName(_ bitmap: NSBitmapImageRep, x: Int, y: Int) -> String {
        guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB), color.alphaComponent > 0.5 else {
            return "clear"
        }
        let (red, green, blue) = (color.redComponent > 0.5, color.greenComponent > 0.5, color.blueComponent > 0.5)
        switch (red, green, blue) {
        case (true, true, true): return "white"
        case (true, true, false): return "yellow"
        case (true, false, false): return "red"
        case (false, true, false): return "green"
        case (false, false, true): return "blue"
        default: return "other"
        }
    }

    /// The flag is relative to the superlayer, so the root alone carries it
    /// and the subtree inherits the y-down axis.
    private static func applyGeometryFlip(to layer: CALayer) {
        layer.isGeometryFlipped = true
    }

    // MARK: - Helpers

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
