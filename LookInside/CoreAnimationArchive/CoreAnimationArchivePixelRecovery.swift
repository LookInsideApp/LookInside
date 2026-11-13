// CoreAnimationArchivePixelRecovery.swift
//
// Renders the layers of a decoded Core Animation archive into the solo and
// group screenshots the inspector shows for each node.
//
// The rendering itself is the `.viewhierarchy` import's: the same drawing
// region estimate, texture caps, plain-colour skip and orientation rule
// (a layer whose cumulative flip is odd is rendered into a flipped context).
// What differs is the bookkeeping. A capture's layer archives have to be
// paired with the objects the capture describes; an archive from Dump Layer
// is nothing but layers, so every layer is a node and is numbered here, in
// the order both this file and the converter walk the tree.

import AppKit
import Foundation
import QuartzCore

/// A decoded archive with every layer numbered.
///
/// The number is the node's `oid`: the key its screenshots are filed under
/// and the identity the inspector selects it by. An archive carries no
/// object addresses of its own, so the numbers simply count the layers,
/// depth first with sublayers in order, starting at 1.
struct CoreAnimationArchiveLayerTree {
    let rootLayer: CALayer
    /// Every layer of the tree in numbering order; the layer at index `i`
    /// has the object identifier `i + 1`.
    let layers: [CALayer]
    private let objectIdentifiersByLayer: [ObjectIdentifier: UInt]

    /// Numbers `contents` after giving its root the orientation it had where
    /// it was archived.
    ///
    /// `geometryFlipped` is relative to the superlayer, and an archive keeps
    /// none of the root's superlayers: their flips survive only as the
    /// archive's own `geometryFlipped` entry. Setting the root's flag to that
    /// entry makes every layer's `contentsAreFlipped` — the root's flag
    /// combined with each flag below it — what it was in the dumped app,
    /// which is what both the renderer and the node geometry read.
    init(contents: CoreAnimationArchiveContents) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contents.rootLayer.isGeometryFlipped = contents.isGeometryFlipped
        CATransaction.commit()

        var layers: [CALayer] = []
        var objectIdentifiersByLayer: [ObjectIdentifier: UInt] = [:]
        func numbering(_ layer: CALayer) {
            // A layer reached twice would mean a cycle; number it once.
            guard objectIdentifiersByLayer[ObjectIdentifier(layer)] == nil else { return }
            layers.append(layer)
            objectIdentifiersByLayer[ObjectIdentifier(layer)] = UInt(layers.count)
            for sublayer in layer.sublayers ?? [] {
                numbering(sublayer)
            }
        }
        numbering(contents.rootLayer)

        rootLayer = contents.rootLayer
        self.layers = layers
        self.objectIdentifiersByLayer = objectIdentifiersByLayer
    }

    /// The node identifier of a layer of this tree; 0 for any other layer.
    func objectIdentifier(of layer: CALayer) -> UInt {
        objectIdentifiersByLayer[ObjectIdentifier(layer)] ?? 0
    }
}

/// The rendered images of an archive, keyed by node identifier.
struct CoreAnimationArchiveScreenshots {
    /// PNG data for each layer rendered without its sublayers. Absent for a
    /// layer with no sublayers, whose group image is the same picture.
    var soloByObjectIdentifier: [UInt: Data] = [:]
    /// PNG data for each layer rendered with its whole subtree.
    var groupByObjectIdentifier: [UInt: Data] = [:]
    /// Where a group image was rendered when it covers less than the layer's
    /// bounds, measured from the bounds origin.
    var groupRegionByObjectIdentifier: [UInt: CGRect] = [:]
}

enum CoreAnimationArchivePixelRecovery {
    private typealias Renderer = XcodeViewHierarchyPixelRecovery

    /// Renders every layer of `tree`.
    ///
    /// Must be called from a single thread, and not inside an explicit
    /// CATransaction: rendering a layer moves it into the renderer, and on
    /// its own detaches its sublayers, for the duration, and everything is
    /// put back before the next layer is drawn; every render commits its own
    /// transaction. The tree's animations are removed first, so the images
    /// show the layers' own values. `isCancelled` is polled once per layer;
    /// when it answers true the recovery throws `CancellationError`, since a
    /// partial set of images would read as missing pixels.
    ///
    /// Every subtree but the root's is drawn without the window behind it;
    /// its backdrops capture the window's average colour instead of that
    /// transparency (`renderingPNG`'s `backdropStandIn`).
    static func recovering(
        from tree: CoreAnimationArchiveLayerTree,
        isCancelled: () -> Bool = { false }
    ) throws -> CoreAnimationArchiveScreenshots {
        var screenshots = CoreAnimationArchiveScreenshots()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        Renderer.removingAnimations(from: tree.rootLayer)
        CATransaction.commit()
        let backdropStandIn = Renderer.backdropStandInColor(for: tree.rootLayer)

        for (index, layer) in tree.layers.enumerated() {
            if isCancelled() {
                throw CancellationError()
            }
            let objectIdentifier = UInt(index + 1)
            let isFlipped = layer.contentsAreFlipped()
            let hasSublayers = !(layer.sublayers?.isEmpty ?? true)
            // A layer that paints nothing but its background colour needs no
            // image: the inspector fills an imageless node with the node's
            // background colour. Its subtree still needs the group image.
            let paintsOnlyItsBackground = Renderer.representsPlainColorFill(layer)
            if !paintsOnlyItsBackground || hasSublayers,
               let region = Renderer.drawingRegion(of: layer, hiding: []),
               let groupImage = Renderer.renderingPNG(
                   of: layer, includingSublayers: true, region: region.rect, isFlipped: isFlipped,
                   backdropStandIn: layer === tree.rootLayer ? nil : backdropStandIn
               )
            {
                screenshots.groupByObjectIdentifier[objectIdentifier] = groupImage
                if region.isPartial {
                    screenshots.groupRegionByObjectIdentifier[objectIdentifier] = region.relativeRect
                }
            }
            guard hasSublayers, !paintsOnlyItsBackground else { continue }
            if let soloImage = Renderer.renderingPNG(of: layer, includingSublayers: false, isFlipped: isFlipped) {
                screenshots.soloByObjectIdentifier[objectIdentifier] = soloImage
            }
        }
        return screenshots
    }
}
