import AppKit
import Foundation
import Metal
import QuartzCore

/// Coverage for a live session's window archive: the reply a macOS Server
/// sends for `LookinRequestTypeLayerArchive`, decoded and checked against the
/// walk the Server listed. The archives are written by QuartzCore's own
/// `CAEncodeLayerTree`, the function the Server calls.
@main
struct LiveLayerArchiveTests {
    static func main() {
        testLayersAreFoundByTheirOids()
        testTreeOfAnotherShapeIsRefused()
        testWalkThatEndsEarlyIsRefused()
        testWindowOverTheLimitIsNotDrawnFrom()
        testUndecodableArchiveIsRefused()
        testWindowColourIsMeasured()
        testGroupImageLeavesOutOnlyNodesOutsideItsSubtree()
        testSoloImageKeepsWhatNoNodeOwns()
        testImagesDrawWhatTheyKeep()
        testGlassShapeGetsNoImage()
        testBackdropKeepsItsGlassShape()
        testPunchOutGetsNoImage()
        print("LiveLayerArchive tests passed")
    }

    // MARK: - Tests

    private static func testLayersAreFoundByTheirOids() {
        let root = makingTree()
        let walk = walking(root)
        let archive = decoding(reply(for: root))
        expect(archive.windowOid == 7, "the archive should keep its window's oid")
        expect(archive.layers.count == walk.count, "every layer should decode, got \(archive.layers.count) of \(walk.count)")
        for (index, layer) in walk.enumerated() {
            let oid = oid(of: layer, at: index)
            guard oid != 0 else {
                expect(archive.oid(of: archive.layers[index]) == 0, "a layer without a node should have no oid")
                continue
            }
            let decoded = archive.layer(withOid: oid)
            expect(decoded?.name == layer.name, "oid \(oid) should find \(layer.name ?? "?"), got \(decoded?.name ?? "nothing")")
            expect(decoded.map(archive.oid(of:)) == oid, "the layer found by oid \(oid) should report it back")
        }
        expect(archive.layer(withOid: 999) == nil, "an oid the Server did not list should find nothing")
    }

    private static func testTreeOfAnotherShapeIsRefused() {
        let reply = reply(for: makingTree())
        // "blue", fifth in the walk, has one sublayer; claim two.
        reply.sublayerCounts[4] = 2
        expectFailure(.shapeMismatch(layerIndex: 4), decodingReply: reply)
    }

    private static func testWalkThatEndsEarlyIsRefused() {
        let reply = reply(for: makingTree())
        reply.sublayerCounts.removeLast()
        reply.layerOids.removeLast()
        expectFailure(.shapeMismatch(layerIndex: 5), decodingReply: reply)
    }

    private static func testWindowOverTheLimitIsNotDrawnFrom() {
        let reply = LayerArchive()
        reply.layerCount = 9000
        expectFailure(.notEncoded(layerCount: 9000), decodingReply: reply)
    }

    private static func testUndecodableArchiveIsRefused() {
        let reply = reply(for: makingTree())
        reply.archiveData = Data("not a layer archive".utf8)
        expectFailure(.undecodable, decodingReply: reply)
    }

    private static func testWindowColourIsMeasured() {
        let archive = decoding(reply(for: makingTree()))
        guard let colour = archive.materialStandIn,
              let components = colour.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?.components,
              components.count >= 3
        else {
            fail("the window should have an average colour")
        }
        // Grey with a red and a blue square, a white dot in the blue one:
        // red 0.45, green 0.38, blue 0.45.
        expect(components[0] > components[1] + 0.03, "the red square should warm the average, got \(components)")
        expect(abs(components[0] - 0.45) < 0.08, "the average should be near the window's, got \(components)")
    }

    // MARK: - Images

    /// A view whose drawing sits in a container layer no node owns (as
    /// AppKit's drawing containers do), a subview, and a layer the hierarchy
    /// lists as a layer node:
    ///
    ///     window (no node)
    ///       view (oid 10)         200 × 100, nothing of its own
    ///         container (no node) red, the left half
    ///         subview (oid 20)    blue, the right half
    ///           mark (no node)    green, inside the subview
    ///         extra (oid 30)      yellow, the left quarter
    private static func makingViewTree() -> (root: CALayer, oids: [String: UInt]) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        func layer(_ name: String, _ frame: CGRect, _ colour: CGColor?) -> CALayer {
            let layer = CALayer()
            layer.name = name
            layer.frame = frame
            layer.backgroundColor = colour
            return layer
        }
        let window = layer("window", CGRect(x: 0, y: 0, width: 200, height: 100), nil)
        let view = layer("view", CGRect(x: 0, y: 0, width: 200, height: 100), nil)
        let container = layer("container", CGRect(x: 0, y: 0, width: 100, height: 100), CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        let subview = layer("subview", CGRect(x: 100, y: 0, width: 100, height: 100), CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1))
        let mark = layer("mark", CGRect(x: 40, y: 40, width: 20, height: 20), CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1))
        let extra = layer("extra", CGRect(x: 0, y: 0, width: 50, height: 100), CGColor(srgbRed: 1, green: 1, blue: 0, alpha: 1))
        subview.addSublayer(mark)
        view.addSublayer(container)
        view.addSublayer(subview)
        view.addSublayer(extra)
        window.addSublayer(view)
        return (window, ["view": 10, "subview": 20, "extra": 30])
    }

    private static func decodingViewTree() -> LiveLayerArchive {
        let (root, oids) = makingViewTree()
        let walk = walking(root)
        let reply = LayerArchive()
        reply.archiveData = encoding(root)
        reply.layerOids = walk.map { oids[$0.name ?? ""] ?? 0 }
        reply.sublayerCounts = walk.map { UInt32($0.sublayers?.count ?? 0) }
        reply.layerCount = UInt(walk.count)
        return decoding(reply)
    }

    private static let viewTreeNodeLayerOids: Set<UInt> = [10, 20, 30]

    private static func leftOutNames(_ kind: LiveLayerArchive.ImageKind, layerOid: UInt, subtree: Set<UInt>, in archive: LiveLayerArchive) -> [String] {
        let nodes = LiveLayerArchive.NodeLayers(layerOid: layerOid, subtreeLayerOids: subtree, windowNodeLayerOids: viewTreeNodeLayerOids)
        return archive.layersLeftOut(of: kind, for: nodes).map { $0.name ?? "?" }
    }

    private static func testGroupImageLeavesOutOnlyNodesOutsideItsSubtree() {
        let archive = decodingViewTree()
        let viewGroup = leftOutNames(.group, layerOid: 10, subtree: [10, 20, 30], in: archive)
        expect(viewGroup.isEmpty, "the view's group image should keep its whole subtree, left out \(viewGroup)")
        // Backing layers shown: the BackingLayer node shares the view's layer
        // but holds no subview.
        let backingLayerGroup = leftOutNames(.group, layerOid: 10, subtree: [10, 30], in: archive)
        expect(backingLayerGroup == ["subview"], "a BackingLayer node's group image should leave the subview out, left out \(backingLayerGroup)")
    }

    private static func testSoloImageKeepsWhatNoNodeOwns() {
        let archive = decodingViewTree()
        let viewSolo = leftOutNames(.solo, layerOid: 10, subtree: [10, 20, 30], in: archive)
        expect(viewSolo == ["subview", "extra"], "the view's solo image should leave out the other nodes and keep its drawing, left out \(viewSolo)")
        let subviewSolo = leftOutNames(.solo, layerOid: 20, subtree: [20], in: archive)
        expect(subviewSolo.isEmpty, "the subview's solo image should keep its own drawing, left out \(subviewSolo)")
    }

    private static func testImagesDrawWhatTheyKeep() {
        guard MTLCreateSystemDefaultDevice() != nil else {
            print("skipped testImagesDrawWhatTheyKeep: no Metal device")
            return
        }
        let archive = decodingViewTree()
        func image(_ kind: LiveLayerArchive.ImageKind, subtree: Set<UInt>) -> CGImage? {
            archive.image(of: kind, for: LiveLayerArchive.NodeLayers(layerOid: 10, subtreeLayerOids: subtree, windowNodeLayerOids: viewTreeNodeLayerOids))
        }
        // Sampled across the middle row, which no flip moves.
        guard let group = image(.group, subtree: [10, 20, 30]) else { fail("the view should have a group image") }
        expect(colour(of: group, atX: 25) == .yellow, "the group image should show the extra layer")
        expect(colour(of: group, atX: 75) == .red, "the group image should show the view's drawing")
        expect(colour(of: group, atX: 180) == .blue, "the group image should show the subview")
        guard let solo = image(.solo, subtree: [10, 20, 30]) else { fail("the view should have a solo image") }
        expect(colour(of: solo, atX: 25) == .red, "the solo image should show the drawing under the extra layer, not the layer")
        expect(colour(of: solo, atX: 75) == .red, "the solo image should show the view's drawing")
        expect(colour(of: solo, atX: 180) == .clear, "the solo image should leave the subview out")
        guard let backingLayerGroup = image(.group, subtree: [10, 30]) else { fail("the BackingLayer node should have a group image") }
        expect(colour(of: backingLayerGroup, atX: 180) == .clear, "a BackingLayer node's group image should leave the subview out")
    }

    private static func testGlassShapeGetsNoImage() {
        guard let backdropClass = NSClassFromString("CABackdropLayer") as? CALayer.Type,
              let shapeClass = NSClassFromString("CASDFLayer") as? CALayer.Type
        else {
            print("skipped testGlassShapeGetsNoImage: no backdrop or distance-field layer class")
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let root = CALayer()
        root.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let backdrop = backdropClass.init()
        backdrop.frame = root.bounds
        let shape = shapeClass.init()
        shape.frame = root.bounds
        let inside = CALayer()
        inside.frame = CGRect(x: 10, y: 10, width: 40, height: 40)
        inside.backgroundColor = CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
        shape.addSublayer(inside)
        backdrop.addSublayer(shape)
        root.addSublayer(backdrop)
        CATransaction.commit()
        let walk = walking(root)
        let reply = LayerArchive()
        reply.archiveData = encoding(root)
        reply.layerOids = walk.indices.map { UInt(200 + $0) }
        reply.sublayerCounts = walk.map { UInt32($0.sublayers?.count ?? 0) }
        let archive = decoding(reply)
        // root 200, backdrop 201, shape 202, inside 203.
        for layerOid: UInt in [202, 203] {
            let nodes = LiveLayerArchive.NodeLayers(layerOid: layerOid, subtreeLayerOids: [layerOid], windowNodeLayerOids: Set(200 ... 203))
            expect(archive.image(of: .group, for: nodes) == nil, "the glass's shape, oid \(layerOid), should get no image")
        }
    }

    /// Expanded, a glass's plane is its backdrop's own image. The shape the
    /// glass reads lies in distance-field layers under the backdrop, nodes
    /// that never get an image of their own; leaving them out of the
    /// backdrop's image too left it empty, and fully expanded glass vanished.
    private static func testBackdropKeepsItsGlassShape() {
        guard let backdropClass = NSClassFromString("CABackdropLayer") as? CALayer.Type,
              let shapeClass = NSClassFromString("CASDFLayer") as? CALayer.Type,
              let elementClass = NSClassFromString("CASDFElementLayer") as? CALayer.Type
        else {
            print("skipped testBackdropKeepsItsGlassShape: no backdrop or distance-field layer class")
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let root = CALayer()
        root.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let backdrop = backdropClass.init()
        backdrop.frame = root.bounds
        let shape = shapeClass.init()
        shape.frame = root.bounds
        let element = elementClass.init()
        element.frame = CGRect(x: 10, y: 10, width: 80, height: 30)
        let content = CALayer()
        content.frame = CGRect(x: 20, y: 60, width: 20, height: 20)
        content.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        shape.addSublayer(element)
        backdrop.addSublayer(shape)
        backdrop.addSublayer(content)
        root.addSublayer(backdrop)
        CATransaction.commit()
        let walk = walking(root)
        let reply = LayerArchive()
        reply.archiveData = encoding(root)
        reply.layerOids = walk.indices.map { UInt(300 + $0) }
        reply.sublayerCounts = walk.map { UInt32($0.sublayers?.count ?? 0) }
        let archive = decoding(reply)
        // root 300, backdrop 301, shape 302, element 303, content 304: every
        // layer a node, as the Server lists them.
        let nodes = LiveLayerArchive.NodeLayers(layerOid: 301, subtreeLayerOids: Set(301 ... 304), windowNodeLayerOids: Set(300 ... 304))
        let leftOut = archive.layersLeftOut(of: .solo, for: nodes).map { archive.oid(of: $0) }
        expect(leftOut == [304], "the backdrop's own image should keep its glass shape and leave the other node out, left out \(leftOut)")
    }

    /// A layer composited with `destOut` only cuts what is beneath it, as a
    /// segmented control cuts its plain icon where the selection is with a
    /// black rounded rectangle. On its own it came out as a black capsule.
    /// Neither it nor what is under it gets an image; the cut stays in the
    /// group image of what it cuts.
    private static func testPunchOutGetsNoImage() {
        guard let filterClass = NSClassFromString("CAFilter") as? NSObject.Type,
              let destinationOut = filterClass.perform(NSSelectorFromString("filterWithType:"), with: "destOut")?.takeUnretainedValue()
        else { fail("QuartzCore should make a destOut filter") }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let root = CALayer()
        root.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let icons = CALayer()
        icons.frame = root.bounds
        let selectedIcon = CALayer()
        selectedIcon.frame = CGRect(x: 20, y: 30, width: 40, height: 40)
        selectedIcon.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let otherIcon = CALayer()
        otherIcon.frame = CGRect(x: 140, y: 30, width: 40, height: 40)
        otherIcon.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let cutting = CALayer()
        cutting.frame = root.bounds
        cutting.compositingFilter = destinationOut
        let selection = CALayer()
        selection.frame = CGRect(x: 10, y: 20, width: 60, height: 60)
        selection.backgroundColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        cutting.addSublayer(selection)
        icons.addSublayer(selectedIcon)
        icons.addSublayer(otherIcon)
        icons.addSublayer(cutting)
        root.addSublayer(icons)
        CATransaction.commit()
        let walk = walking(root)
        let reply = LayerArchive()
        reply.archiveData = encoding(root)
        reply.layerOids = walk.indices.map { UInt(400 + $0) }
        reply.sublayerCounts = walk.map { UInt32($0.sublayers?.count ?? 0) }
        let archive = decoding(reply)
        // root 400, icons 401, selected icon 402, other icon 403, cutting 404,
        // selection 405.
        let every = Set<UInt>(400 ... 405)
        for layerOid: UInt in [404, 405] {
            for kind in [LiveLayerArchive.ImageKind.solo, .group] {
                let nodes = LiveLayerArchive.NodeLayers(layerOid: layerOid, subtreeLayerOids: layerOid == 404 ? [404, 405] : [405], windowNodeLayerOids: every)
                expect(archive.image(of: kind, for: nodes) == nil, "oid \(layerOid), which only cuts, should get no \(kind) image")
            }
        }
        guard MTLCreateSystemDefaultDevice() != nil else {
            print("skipped the cut check of testPunchOutGetsNoImage: no Metal device")
            return
        }
        guard let group = archive.image(of: .group, for: LiveLayerArchive.NodeLayers(
            layerOid: 401, subtreeLayerOids: Set(401 ... 405), windowNodeLayerOids: every
        )) else { fail("the icons should have a group image") }
        expect(colour(of: group, atX: 40) == .clear, "the icons' group image should keep the cut under the selection")
        expect(colour(of: group, atX: 160) == .red, "the icons' group image should keep the icon outside the cut")
    }

    private enum SampledColour {
        case red, blue, yellow, clear, other
    }

    /// The colour across the middle row of `image` at `x` points, the image
    /// drawn at one pixel a point.
    private static func colour(of image: CGImage, atX x: Int) -> SampledColour {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return .other }
        let column = x * width / 200
        let start = ((height / 2) * width + column) * 4
        let red = Int(pixels[start]), green = Int(pixels[start + 1]), blue = Int(pixels[start + 2]), alpha = Int(pixels[start + 3])
        if alpha < 20 { return .clear }
        if alpha > 235, red > 220, green < 40, blue < 40 { return .red }
        if alpha > 235, red < 40, green < 40, blue > 220 { return .blue }
        if alpha > 235, red > 220, green > 220, blue < 40 { return .yellow }
        return .other
    }

    // MARK: - Fixture

    private typealias EncodeLayerTreeFunction = @convention(c) (CALayer) -> Unmanaged<NSData>?

    /// QuartzCore's encoder, the one the Server links. The caller owns what
    /// it returns.
    private static func encoding(_ layer: CALayer) -> Data {
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CAEncodeLayerTree") else {
            fail("CAEncodeLayerTree is missing")
        }
        let encode = unsafeBitCast(symbol, to: EncodeLayerTreeFunction.self)
        guard let archive = encode(layer)?.takeRetainedValue() else {
            fail("CAEncodeLayerTree returned nothing")
        }
        return archive as Data
    }

    /// A window-like tree: a grey root holding a titlebar strip and a
    /// content layer with a red and a blue square, a white dot in the blue.
    private static func makingTree() -> CALayer {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        func layer(_ name: String, _ frame: CGRect, _ colour: CGColor?) -> CALayer {
            let layer = CALayer()
            layer.name = name
            layer.frame = frame
            layer.backgroundColor = colour
            return layer
        }
        let root = layer("root", CGRect(x: 0, y: 0, width: 200, height: 120), CGColor(srgbRed: 0.4, green: 0.4, blue: 0.4, alpha: 1))
        let titlebar = layer("titlebar", CGRect(x: 0, y: 100, width: 200, height: 20), CGColor(srgbRed: 0.6, green: 0.6, blue: 0.6, alpha: 1))
        let content = layer("content", CGRect(x: 0, y: 0, width: 200, height: 100), nil)
        let red = layer("red", CGRect(x: 10, y: 10, width: 40, height: 40), CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        let blue = layer("blue", CGRect(x: 60, y: 10, width: 40, height: 40), CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1))
        let dot = layer("dot", CGRect(x: 5, y: 5, width: 10, height: 10), CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
        blue.addSublayer(dot)
        content.addSublayer(red)
        content.addSublayer(blue)
        root.addSublayer(titlebar)
        root.addSublayer(content)
        return root
    }

    /// The Server's walk: depth first, sublayers in order.
    private static func walking(_ root: CALayer) -> [CALayer] {
        var layers: [CALayer] = []
        var pending = [root]
        while let layer = pending.popLast() {
            layers.append(layer)
            pending.append(contentsOf: (layer.sublayers ?? []).reversed())
        }
        return layers
    }

    /// The oid the fixture's hierarchy gives a layer: 100 plus its place in
    /// the walk, none for the titlebar.
    private static func oid(of layer: CALayer, at index: Int) -> UInt {
        layer.name == "titlebar" ? 0 : UInt(100 + index)
    }

    /// What a Server answers for a window whose root is `root`.
    private static func reply(for root: CALayer) -> LayerArchive {
        let walk = walking(root)
        let reply = LayerArchive()
        reply.archiveData = encoding(root)
        reply.layerOids = walk.enumerated().map { oid(of: $1, at: $0) }
        reply.sublayerCounts = walk.map { UInt32($0.sublayers?.count ?? 0) }
        reply.layerCount = UInt(walk.count)
        return reply
    }

    private static func decoding(_ reply: LayerArchive) -> LiveLayerArchive {
        do {
            return try LiveLayerArchive(reply: reply, windowOid: 7)
        } catch {
            fail("the archive should decode, got \(error)")
        }
    }

    private static func expectFailure(_ failure: LiveLayerArchive.Failure, decodingReply reply: LayerArchive) {
        do {
            _ = try LiveLayerArchive(reply: reply, windowOid: 7)
            fail("the reply should be refused with \(failure)")
        } catch {
            expect(error == failure, "the reply should be refused with \(failure), got \(error)")
        }
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
