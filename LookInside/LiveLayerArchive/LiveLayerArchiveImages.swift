//
//  LiveLayerArchiveImages.swift
//  LookInside
//
//  Which layers of a live window's archive a node's image holds, and the
//  image itself.
//
//  The Server, drawing with renderInContext:, needed special cases to keep
//  one set of pixels on one node: a backing layer with no contents draws no
//  solo image, the drawing container AppKit puts a view's drawing in is a
//  node of its own only with the backing layers shown, and a BackingLayer
//  node's group image leaves the subviews out. renderInContext: makes AppKit
//  redraw a view offscreen, which is where the duplicates came from. An
//  archive holds what the window already drew, so one rule, read off the
//  node tree, covers all of them: an image leaves out the layers that belong
//  to nodes it does not show.
//

import AppKit
import QuartzCore

extension LiveLayerArchive {
    /// The two images the preview shows a node with: its whole subtree while
    /// it is folded, its own drawing once its children are shown on their
    /// own.
    enum ImageKind: Hashable, Sendable {
        case group
        case solo
    }

    /// The node tree as an image needs it: which layers belong to the node,
    /// to the nodes below it and to the window's nodes at all.
    struct NodeLayers: Sendable {
        /// The layer of the node whose image is drawn.
        let layerOid: UInt
        /// The layers of the node and of every node below it.
        let subtreeLayerOids: Set<UInt>
        /// The layers of every node of the window.
        let windowNodeLayerOids: Set<UInt>
    }

    /// The layers under the node's layer that its image leaves out, each
    /// with its sublayers:
    /// - group: the layers of nodes outside the node's subtree. With the
    ///   backing layers shown, a BackingLayer node's subtree holds no
    ///   subview, so its image holds none either.
    /// - solo: the layers of every node but this one. What no node owns
    ///   stays, such as the drawing container AppKit puts a view's drawing
    ///   in: since macOS 15 a backing layer holds no drawing of its own. A
    ///   backdrop keeps the glass shape layers under it: they are nodes that
    ///   draw nothing themselves and give the glass its shape, so an
    ///   expanded glass's plane shows the glass.
    func layersLeftOut(of kind: ImageKind, for nodes: NodeLayers) -> [CALayer] {
        guard let layer = layer(withOid: nodes.layerOid) else { return [] }
        let keepsGlassShape = kind == .solo && XcodeViewHierarchyPixelRecovery.isBackdrop(layer)
        var leftOut: [CALayer] = []
        var pending = Array((layer.sublayers ?? []).reversed())
        while let sublayer = pending.popLast() {
            let sublayerOid = oid(of: sublayer)
            let belongsToANode = sublayerOid != 0 && nodes.windowNodeLayerOids.contains(sublayerOid)
            let isLeftOut = switch kind {
            case .group:
                belongsToANode && !nodes.subtreeLayerOids.contains(sublayerOid)
            case .solo:
                belongsToANode && !(keepsGlassShape && XcodeViewHierarchyPixelRecovery.isGlassShapeInput(sublayer))
            }
            if isLeftOut {
                leftOut.append(sublayer)
            } else {
                pending.append(contentsOf: (sublayer.sublayers ?? []).reversed())
            }
        }
        return leftOut
    }

    /// The node's image, drawn the way the importers draw theirs: the
    /// window's colour behind backdrops and vibrant content of a layer drawn
    /// on its own, nothing for a glass shape or a layer that only cuts what
    /// is beneath it. Nil when the archive has no layer for the node or the
    /// image would be empty.
    ///
    /// Not to be called inside an explicit CATransaction, nor on two threads
    /// at once: the renderer moves the layer into a container while it draws.
    func image(of kind: ImageKind, for nodes: NodeLayers) -> CGImage? {
        guard let layer = layer(withOid: nodes.layerOid),
              !XcodeViewHierarchyPixelRecovery.isGlassShapeInput(layer),
              !XcodeViewHierarchyPixelRecovery.cutsWhatIsBeneath(layer)
        else { return nil }
        return XcodeViewHierarchyPixelRecovery.renderingImage(
            of: layer,
            includingSublayers: true,
            hiding: layersLeftOut(of: kind, for: nodes),
            isFlipped: layer.contentsAreFlipped(),
            materialStandIn: layer === rootLayer ? nil : materialStandIn
        )
    }
}
