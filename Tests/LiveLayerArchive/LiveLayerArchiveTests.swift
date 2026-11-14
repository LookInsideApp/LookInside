import AppKit
import Foundation
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
