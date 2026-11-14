//
//  LiveLayerArchive.swift
//  LookInside
//
//  One window of a live macOS session as its Server encoded it
//  (LookinRequestTypeLayerArchive, 211): the layer tree QuartzCore's
//  CAEncodeLayerTree wrote, decoded the way a `.caar` file is, checked
//  against the depth-first walk the Server made while encoding, and indexed
//  by the oids the hierarchy gave its layers. The Host draws the nodes'
//  images from it with the importers' renderer, which gets Liquid Glass,
//  materials and vibrancy right where the Server's renderInContext: cannot.
//

import AppKit
import QuartzCore

/// A window's decoded layer tree, its layers found by oid.
///
/// Built on a background queue and then used by one queue at a time: the
/// renderer moves the layers it draws into a container for the length of a
/// render.
final class LiveLayerArchive: @unchecked Sendable {
    /// Why a window's archive cannot be drawn from; its nodes keep the
    /// images the Server draws.
    enum Failure: Error, Equatable {
        /// The window has more layers than the Host let the Server encode.
        case notEncoded(layerCount: UInt)
        /// The archive did not decode.
        case undecodable
        /// The decoded tree is not the tree the Server walked: the first
        /// layer, depth first, whose sublayer count differs, or the layer
        /// count of the shorter walk.
        case shapeMismatch(layerIndex: Int)
    }

    /// The most layers the Host lets a Server encode in one main-queue turn
    /// of the inspected app: about a second of encoding (0.15–0.26 ms a
    /// layer, measured on live AppKit windows).
    static let layerLimit: UInt = 4000

    let windowOid: UInt
    /// The window's root layer (`NSCGSWindow`), titlebar included.
    let rootLayer: CALayer
    /// Every layer, depth first with sublayers in order: the walk the Server
    /// listed its oids in.
    let layers: [CALayer]
    /// The window's average colour, which a layer drawn on its own puts
    /// behind its backdrops and vibrant content (`materialStandInColor(for:)`).
    let materialStandIn: CGColor?
    private let layersByOid: [UInt: CALayer]
    private let oidsByLayer: [ObjectIdentifier: UInt]

    /// Decodes `reply`, the Server's answer for the window `windowOid`.
    init(reply: LayerArchive, windowOid: UInt) throws(Failure) {
        guard let archiveData = reply.archiveData else {
            throw .notEncoded(layerCount: reply.layerCount)
        }
        let contents: CoreAnimationArchiveContents
        do {
            contents = try CoreAnimationArchive.decodingContents(of: archiveData)
        } catch {
            throw .undecodable
        }
        let tree = CoreAnimationArchiveLayerTree(contents: contents)
        if let mismatch = Self.firstShapeMismatch(between: tree.layers, and: reply) {
            throw .shapeMismatch(layerIndex: mismatch)
        }

        var layersByOid: [UInt: CALayer] = [:]
        var oidsByLayer: [ObjectIdentifier: UInt] = [:]
        for (index, oid) in reply.layerOids.enumerated() where oid != 0 {
            let layer = tree.layers[index]
            layersByOid[oid] = layer
            oidsByLayer[ObjectIdentifier(layer)] = oid
        }

        // The renderer plays animations: an archived spinner would land in
        // whatever phase the clock is in.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        XcodeViewHierarchyPixelRecovery.removingAnimations(from: tree.rootLayer)
        CATransaction.commit()

        self.windowOid = windowOid
        rootLayer = tree.rootLayer
        layers = tree.layers
        self.layersByOid = layersByOid
        self.oidsByLayer = oidsByLayer
        materialStandIn = XcodeViewHierarchyPixelRecovery.materialStandInColor(for: tree.rootLayer)
    }

    /// The layer the hierarchy gave `oid` to, nil when the archive has none.
    func layer(withOid oid: UInt) -> CALayer? {
        layersByOid[oid]
    }

    /// The oid the hierarchy gave `layer`, 0 when it gave none.
    func oid(of layer: CALayer) -> UInt {
        oidsByLayer[ObjectIdentifier(layer)] ?? 0
    }

    /// Where the decoded tree first differs from the walk the Server listed:
    /// nil when every layer has the sublayer count the Server counted.
    static func firstShapeMismatch(between layers: [CALayer], and reply: LayerArchive) -> Int? {
        let walkLength = min(reply.sublayerCounts.count, reply.layerOids.count)
        for (index, layer) in layers.enumerated() {
            guard index < walkLength else { return index }
            if UInt32(clamping: layer.sublayers?.count ?? 0) != reply.sublayerCounts[index] {
                return index
            }
        }
        return layers.count == walkLength ? nil : layers.count
    }
}
