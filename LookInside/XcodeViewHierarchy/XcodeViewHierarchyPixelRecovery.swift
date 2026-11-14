// XcodeViewHierarchyPixelRecovery.swift
//
// Renders the layer trees recovered from a `.viewhierarchy` capture into the
// per-node screenshots the inspector displays.
//
// Output shape deliberately mirrors a `.lookin` archive — encoded image data
// keyed by object identifier, one solo image and one group image per node —
// so the conversion layer can hand it to the same read path that already
// serves `.lookin` documents.
//
// Orientation is the detail that decides whether the result is usable, and
// two facts about Core Animation govern it:
//
//   * `isGeometryFlipped` is relative to the superlayer. Marking a layer flips
//     the axis for its sublayers; marking a sublayer as well flips it back.
//     AppKit already writes the flag that way for flipped views, so an AppKit
//     archive is self-describing. A UIKit archive is y-down at every level and
//     carries no flags (the archive's own `geometryFlipped` says so), so the
//     root alone is marked and the whole tree inherits the y-down axis.
//     Marking every layer, as this once did, flips depth two upside down again.
//   * The flag is ignored on whichever layer is the root of a render. A layer
//     whose cumulative flip is odd — `contentsAreFlipped` — comes out mirrored
//     when rendered on its own, so its context is flipped to make its image
//     match what it looks like inside the tree. This is the rule the server
//     applies when it screenshots a live macOS layer, and the one Xcode's own
//     view debugger uses.
//
// Both halves are needed. Without the root flag a UIKit tree's sublayers stack
// in reverse; without the context flip every flipped subtree — an
// NSOutlineView, an NSTextView, a UIKit screen — reads mirrored, which is how
// an imported Xcode window once came back with its navigator upside down while
// the window as a whole rendered fine.
//
// The images are drawn by Core Animation's own renderer (CARenderer, into a
// Metal texture), the engine that puts these layers on screen. CGContext's
// renderInContext is a simplified software path: it draws Liquid Glass as the
// white fill of its shape source, leaves backdrops and vibrancy blank and
// misses some masks, which made an imported Xcode window read as white
// lozenges over a white sidebar. CARenderer honours the flag on the layer it
// is given, so instead of flipping the result, the layer is drawn inside a
// container that carries its superlayer's cumulative flip — the same picture.
// renderInContext remains the fallback where there is no Metal device.
//
// A node's image draws its subtree on its own, over transparency, and a
// backdrop — a CABackdropLayer, behind Liquid Glass, a sidebar or a scroll
// edge's blur — captures whatever lies behind it there. Its filters read a
// partly transparent capture as if it were opaque, so content near it comes
// out as saturated blocks of its colour (a blue block on Xcode's
// back/forward glass, from the project icon beside it) where the window,
// opaque behind, shows plain glass. Vibrant content — text, icons and
// highlights blended through a vibrant filter with the material behind them
// — loses that material the same way. Such a subtree is drawn a second time
// over a stand-in for the window's material, its average colour, which the
// backdrops capture and the vibrant filters act on; the stand-in is then
// taken back out of each pixel by how much of it the subtree covers in the
// first render, where vibrant content is drawn plain for its coverage. Liquid
// Glass's shape inputs, the signed-distance-field layers under its backdrop,
// get no image at all: on screen only that backdrop reads them, and drawn
// without it they come out as the raw field.

import Accelerate
import AppKit
import Foundation
import Metal
import QuartzCore

struct XcodeViewHierarchyScreenshots {
    /// PNG data for each node rendered without its sublayers.
    let soloByObjectIdentifier: [String: Data]
    /// PNG data for each node rendered with its whole subtree.
    let groupByObjectIdentifier: [String: Data]
    /// PNG data for each node rendered with its subtree minus the subtrees of
    /// the layers that back a view: what a layer node shows once the views
    /// beneath it render on nodes of their own (the server's
    /// `lks_groupScreenshotExcludingHostedSubtreesWithLowQuality:`). Present
    /// only where a hosted layer exists below the node; elsewhere the group
    /// image already is that picture.
    var groupExcludingHostedViewsByObjectIdentifier: [String: Data] = [:]
    /// Where a group image was rendered when it covers less than the layer's
    /// bounds: the region the subtree actually draws into, measured from the
    /// bounds origin. Absent when the image covers the whole bounds. A scroll
    /// view's content is mostly empty, so its region is the visible band —
    /// and that band can then be rendered at full scale rather than the
    /// whole content at whatever scale fits a texture.
    var groupRegionByObjectIdentifier: [String: CGRect] = [:]
    /// Same for `groupExcludingHostedViewsByObjectIdentifier`.
    var groupExcludingHostedViewsRegionByObjectIdentifier: [String: CGRect] = [:]
    /// Layer archives that failed to decode; the nodes below them have no pixels.
    let failedArchiveIdentifiers: [String]
    /// For each layer a portal draws elsewhere while hiding it in place, the
    /// layer of the portal's node: the portal itself, or the nearest layer
    /// above it that is a node. The preview orders the source's node there,
    /// as an `NSGlassEffectView`'s content shows over its glass.
    var portalLayerIdentifierBySourceLayerIdentifier: [String: String] = [:]
}

enum XcodeViewHierarchyPixelRecovery {
    /// Upper bound on the pixels of one rendered image.
    ///
    /// A capture holds thousands of layers; without a cap the import of a
    /// large window allocates gigabytes. Anything larger is rendered at a
    /// reduced scale rather than skipped, so the preview stays complete but
    /// coarser. Sixteen megapixels is the budget Xcode's own view debugger
    /// allows a layer image (it refuses anything bigger outright); a
    /// full-screen retina layer is about thirteen.
    static let maximumRenderedPixelCount = 16_000_000

    /// Upper bound on either side of one rendered image, in pixels.
    ///
    /// The preview puts every image on a SceneKit material, and a texture
    /// longer than this cannot be uploaded — the host asserts the same bound
    /// (`LookinNodeImageMaxLengthInPx`). A layer taller than this at its own
    /// scale is rendered coarser to fit, never dropped: a folded node's whole
    /// subtree lives in this one image, so a missing image is a hole.
    static let maximumRenderedEdgeLength: CGFloat = 16384

    /// Layers below this size carry no useful preview and are common enough
    /// (separators, hairlines, zero-size containers) to be worth skipping.
    static let minimumRenderedEdgeLength: CGFloat = 1

    /// Renders every node the capture has pixels for.
    ///
    /// Must be called from a single thread, and not inside an explicit
    /// CATransaction: it mutates the decoded layer trees while rendering
    /// (moving each layer into the renderer, detaching sublayers for the solo
    /// pass) and restores them before returning, and every render commits
    /// its own transaction, which an enclosing one would hold back.
    ///
    /// `isCancelled` is polled once per layer. When it answers true the render
    /// stops and nothing is returned: a partial set of images would read as
    /// missing pixels rather than as an abandoned import.
    static func recovering(
        from graph: XcodeViewHierarchyObjectGraph,
        isCancelled: () -> Bool = { false }
    ) -> XcodeViewHierarchyScreenshots {
        let (trees, failedIdentifiers) = XcodeViewHierarchyLayerArchive.decodingLayerTrees(in: graph)
        let alignment = XcodeViewHierarchyLayerAlignment.aligning(trees: trees, graph: graph)
        let topology = XcodeViewHierarchyLayerTopology(graph: graph)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for tree in trees {
            if tree.isGeometryFlipped {
                // A y-down capture: the root carries the axis and the subtree
                // inherits it. The flip of the render's container in
                // renderingPNG is the other half.
                tree.rootLayer.isGeometryFlipped = true
            }
            removingAnimations(from: tree.rootLayer)
        }
        CATransaction.commit()

        // What stands in for the window's material behind a subtree drawn on
        // its own — its backdrops capture it, its vibrant content acts on
        // it: the average colour of the window it belongs to. A root's own
        // image is the window itself and needs none.
        var materialStandInsByRoot: [ObjectIdentifier: CGColor] = [:]
        for tree in trees {
            materialStandInsByRoot[ObjectIdentifier(tree.rootLayer)] = materialStandInColor(for: tree.rootLayer)
        }
        func materialStandIn(for layer: CALayer) -> CGColor? {
            var rootLayer = layer
            while let superlayer = rootLayer.superlayer {
                rootLayer = superlayer
            }
            return rootLayer === layer ? nil : materialStandInsByRoot[ObjectIdentifier(rootLayer)]
        }

        var soloByObjectIdentifier: [String: Data] = [:]
        var groupByObjectIdentifier: [String: Data] = [:]
        var groupExcludingHostedViewsByObjectIdentifier: [String: Data] = [:]
        var groupRegionByObjectIdentifier: [String: CGRect] = [:]
        var groupExcludingHostedViewsRegionByObjectIdentifier: [String: CGRect] = [:]

        for (objectIdentifier, layer) in alignment {
            if isCancelled() {
                return XcodeViewHierarchyScreenshots(
                    soloByObjectIdentifier: [:], groupByObjectIdentifier: [:], failedArchiveIdentifiers: failedIdentifiers
                )
            }
            // Liquid Glass's shape inputs, and layers that only cut what is
            // beneath them, show nothing of their own on screen.
            guard !isGlassShapeInput(layer), !cutsWhatIsBeneath(layer) else { continue }
            let isFlipped = layer.contentsAreFlipped()
            let hasSublayers = !(layer.sublayers?.isEmpty ?? true)
            // A layer that paints nothing but its background colour needs no
            // image of its own: the inspector fills a node that has no image
            // with the node's background colour, which is the same picture
            // for a fraction of the memory and import time. Its subtree
            // still needs the group image.
            let paintsOnlyItsBackground = representsPlainColorFill(layer)
            let layerMaterialStandIn = materialStandIn(for: layer)
            if !paintsOnlyItsBackground || hasSublayers,
               let region = drawingRegion(of: layer, hiding: []),
               let groupImage = renderingPNG(
                   of: layer, includingSublayers: true, region: region.rect, isFlipped: isFlipped,
                   materialStandIn: layerMaterialStandIn
               )
            {
                groupByObjectIdentifier[objectIdentifier] = groupImage
                if region.isPartial {
                    groupRegionByObjectIdentifier[objectIdentifier] = region.relativeRect
                }
            }
            // The views beneath a layer node render on planes of their own;
            // a layer node's group therefore leaves their subtrees out.
            let hostedDescendants = topology.hostedDescendantIdentifiers(of: objectIdentifier, graph: graph)
                .compactMap { alignment[$0] }
            if !hostedDescendants.isEmpty,
               let region = drawingRegion(of: layer, hiding: hostedDescendants),
               let excludingImage = renderingPNG(
                   of: layer, includingSublayers: true, hiding: hostedDescendants, region: region.rect, isFlipped: isFlipped,
                   materialStandIn: layerMaterialStandIn
               )
            {
                groupExcludingHostedViewsByObjectIdentifier[objectIdentifier] = excludingImage
                if region.isPartial {
                    groupExcludingHostedViewsRegionByObjectIdentifier[objectIdentifier] = region.relativeRect
                }
            }
            // A node with no sublayers renders identically either way; storing
            // the second copy would double the memory for no visible gain.
            guard hasSublayers, !paintsOnlyItsBackground else { continue }
            if let soloImage = renderingOwnPNG(of: layer, isFlipped: isFlipped, materialStandIn: layerMaterialStandIn) {
                soloByObjectIdentifier[objectIdentifier] = soloImage
            }
        }

        return XcodeViewHierarchyScreenshots(
            soloByObjectIdentifier: soloByObjectIdentifier,
            groupByObjectIdentifier: groupByObjectIdentifier,
            groupExcludingHostedViewsByObjectIdentifier: groupExcludingHostedViewsByObjectIdentifier,
            groupRegionByObjectIdentifier: groupRegionByObjectIdentifier,
            groupExcludingHostedViewsRegionByObjectIdentifier: groupExcludingHostedViewsRegionByObjectIdentifier,
            failedArchiveIdentifiers: failedIdentifiers,
            portalLayerIdentifierBySourceLayerIdentifier: portalLayerIdentifiers(in: trees, alignment: alignment)
        )
    }

    /// `XcodeViewHierarchyScreenshots.portalLayerIdentifierBySourceLayerIdentifier`
    /// for `trees`, whose layers `alignment` names.
    private static func portalLayerIdentifiers(
        in trees: [XcodeViewHierarchyLayerTree],
        alignment: [String: CALayer]
    ) -> [String: String] {
        var identifierByLayer: [ObjectIdentifier: String] = [:]
        for (objectIdentifier, layer) in alignment {
            identifierByLayer[ObjectIdentifier(layer)] = objectIdentifier
        }
        var portalIdentifiers: [String: String] = [:]
        for tree in trees {
            var layers: [CALayer] = []
            var pending = [tree.rootLayer]
            while let layer = pending.popLast() {
                layers.append(layer)
                pending.append(contentsOf: (layer.sublayers ?? []).reversed())
            }
            for (source, portal) in portalsHidingTheirSources(in: layers) {
                guard let sourceIdentifier = identifierByLayer[ObjectIdentifier(source)] else { continue }
                var holder: CALayer? = portal
                while let candidate = holder, identifierByLayer[ObjectIdentifier(candidate)] == nil {
                    holder = candidate.superlayer
                }
                guard let holder, let portalIdentifier = identifierByLayer[ObjectIdentifier(holder)],
                      portalIdentifier != sourceIdentifier
                else { continue }
                portalIdentifiers[sourceIdentifier] = portalIdentifier
            }
        }
        return portalIdentifiers
    }

    // MARK: - Drawing region

    /// Where a subtree draws, in its root layer's bounds space.
    struct DrawingRegion {
        /// The part of the root's bounds to render.
        let rect: CGRect
        /// The same rect measured from the bounds origin.
        let relativeRect: CGRect
        /// Whether the rect is smaller than the bounds.
        let isPartial: Bool
    }

    /// The part of `layer.bounds` that `layer` and its sublayers draw into,
    /// or nil when nothing below it draws at all. `hiddenLayers` are treated
    /// as hidden, as they will be for the render.
    ///
    /// A layer's drawing is taken to fill its bounds, plus a shadow's spread
    /// and a shape layer's path, and a `masksToBounds` layer clips what is
    /// below it. Hidden and fully transparent layers count for nothing. The
    /// estimate errs on the large side: it can include blank space, never
    /// cut drawing off.
    ///
    /// A container with no area that does not clip — a window's content
    /// layer is 0 × 0, with the whole window laid out in it — draws only
    /// through its sublayers, wherever they are; its region is theirs, and
    /// may lie outside its empty bounds. Cut to those bounds it was nothing.
    static func drawingRegion(of layer: CALayer, hiding hiddenLayers: [CALayer]) -> DrawingRegion? {
        let bounds = layer.bounds
        let hidden = Set(hiddenLayers.map(ObjectIdentifier.init))
        let drawsOutsideItsBounds = !layer.masksToBounds && (bounds.width <= 0 || bounds.height <= 0)
        let clip = drawsOutsideItsBounds ? CGRect.infinite : bounds
        let union = drawingUnion(of: layer, in: layer, clip: clip, hiddenLayers: hidden)
        guard !union.isNull else { return nil }
        let rect = (drawsOutsideItsBounds ? union : union.intersection(bounds)).integral
        guard !rect.isEmpty else { return nil }
        let isPartial = rect != bounds.integral
        return DrawingRegion(
            rect: rect,
            relativeRect: rect.offsetBy(dx: -bounds.origin.x, dy: -bounds.origin.y),
            isPartial: isPartial
        )
    }

    private static func drawingUnion(
        of layer: CALayer,
        in root: CALayer,
        clip: CGRect,
        hiddenLayers: Set<ObjectIdentifier>
    ) -> CGRect {
        guard !layer.isHidden, layer.opacity > 0, !hiddenLayers.contains(ObjectIdentifier(layer)) else { return .null }
        var union = CGRect.null
        if drawsSomething(layer) {
            var own = layer.bounds
            if let shapeLayer = layer as? CAShapeLayer, let path = shapeLayer.path {
                // A path is not clipped to the layer's bounds.
                own = own.union(path.boundingBoxOfPath.insetBy(dx: -shapeLayer.lineWidth, dy: -shapeLayer.lineWidth))
            }
            if layer.shadowOpacity > 0 {
                let spread = layer.shadowRadius * 2 + max(abs(layer.shadowOffset.width), abs(layer.shadowOffset.height))
                own = own.insetBy(dx: -spread, dy: -spread)
            }
            union = layer.convert(own, to: root).intersection(clip)
        }
        let childClip = layer.masksToBounds ? layer.convert(layer.bounds, to: root).intersection(clip) : clip
        guard !childClip.isNull, !childClip.isEmpty else { return union }
        for sublayer in layer.sublayers ?? [] {
            union = union.union(drawingUnion(of: sublayer, in: root, clip: childClip, hiddenLayers: hiddenLayers))
        }
        return union
    }

    /// Whether a layer puts any pixels of its own on screen.
    static func drawsSomething(_ layer: CALayer) -> Bool {
        guard representsPlainColorFill(layer) else { return true }
        return (layer.backgroundColor?.alpha ?? 0) > 0
    }

    // MARK: - Vibrancy

    /// The layers of `root`'s subtree that draw an image or text through a
    /// vibrant filter (`drawsThroughRemovableVibrantFilter`) with nothing
    /// drawn behind them inside the subtree.
    ///
    /// Text and icons on a sidebar or a toolbar blend through such a filter
    /// with the material behind them: AppKit's as a compositing filter
    /// (`vibrantColorMatrixSourceOver`), SwiftUI's controls as an entry in
    /// `filters` (`vibrantColorMatrix`, aware of the backdrop). The filter's
    /// matrix acts on that material, cut to the content's shape. A subtree
    /// drawn on its own leaves the material out whenever an ancestor or a
    /// sibling draws it, and without it the content vanishes. Over
    /// transparency such a layer is therefore drawn plain, which gives its
    /// coverage; over a material stand-in it keeps its filter and takes the
    /// colour the filter makes of the stand-in. What counts as behind a
    /// layer is the material (`providesMaterial`) drawn before it in
    /// painter's order — ancestors included — where it overlaps the layer.
    /// Hidden layers count for nothing.
    static func vibrantLayersWithNothingBehind(in root: CALayer) -> [CALayer] {
        layersWithNothingBehind(in: root, matching: drawsThroughRemovableVibrantFilter)
    }

    /// The layers of `root`'s subtree that only fill through a vibrant
    /// filter (`isVibrantFill`) with nothing drawn behind them inside the
    /// subtree, measured as `vibrantLayersWithNothingBehind` measures.
    ///
    /// They are the selection highlights of SwiftUI's controls and the
    /// sheens of Liquid Glass, faint against their material; drawn plain
    /// they are opaque white lozenges. So they keep their filter in both
    /// renders: over transparency they leave nothing, and over a material
    /// stand-in what they make of it — a little lighter or darker — is kept
    /// (`removingMaterialStandIn`'s `uncoveredRegions`).
    static func vibrantFillsWithNothingBehind(in root: CALayer) -> [CALayer] {
        layersWithNothingBehind(in: root, matching: isVibrantFill)
    }

    private static func layersWithNothingBehind(
        in root: CALayer,
        matching isCandidate: (CALayer) -> Bool
    ) -> [CALayer] {
        var materialRects: [CGRect] = []
        var layersWithNothingBehind: [CALayer] = []
        func visiting(_ layer: CALayer) {
            guard !layer.isHidden, layer.opacity > 0 else { return }
            let rect = layer.convert(layer.bounds, to: root)
            if isCandidate(layer), !materialRects.contains(where: { $0.intersects(rect) }) {
                layersWithNothingBehind.append(layer)
            }
            if providesMaterial(layer) {
                materialRects.append(rect)
            }
            for sublayer in layer.sublayers ?? [] {
                visiting(sublayer)
            }
        }
        visiting(root)
        return layersWithNothingBehind
    }

    /// Whether a layer's own drawing goes through a vibrant filter that can
    /// be taken off it for a render: its compositing filter, or a vibrant
    /// entry in `filters` on a layer that draws an image (`contents`).
    /// A layer that only fills keeps its filter (`isVibrantFill`).
    static func drawsThroughRemovableVibrantFilter(_ layer: CALayer) -> Bool {
        if isVibrant(layer.compositingFilter) {
            return true
        }
        guard layer.contents != nil else { return false }
        return (layer.filters ?? []).contains { isVibrant($0) }
    }

    /// Whether a layer only fills through a vibrant entry in `filters`: it
    /// draws no image and has no vibrant compositing filter. Signed-distance-
    /// field layers are left out: their vibrant filter shapes the glass from
    /// the raw field, which no stand-in can take the place of.
    static func isVibrantFill(_ layer: CALayer) -> Bool {
        guard layer.contents == nil,
              !isVibrant(layer.compositingFilter),
              !NSStringFromClass(type(of: layer)).hasPrefix("CASDF")
        else { return false }
        return (layer.filters ?? []).contains { isVibrant($0) }
    }

    /// Whether a layer lays down something a vibrant layer above it can blend
    /// with: a backdrop (the blur of a visual effect view or of glass), a
    /// window's chameleon background, or a fill at least half opaque.
    ///
    /// Unlike `drawsSomething`, which errs on the large side to bound a
    /// drawing region, this errs on the small side: a sidebar row's rounded
    /// container draws nothing, and counting it hid every label above it.
    static func providesMaterial(_ layer: CALayer) -> Bool {
        let className = NSStringFromClass(type(of: layer))
        if className.contains("Backdrop") || className.contains("Chameleon") {
            return true
        }
        return (layer.backgroundColor?.alpha ?? 0) >= 0.5
    }

    /// Whether `filter`, as a layer holds it, is one of Core Animation's
    /// vibrant filters: a CAFilter whose type says so, or a filter name.
    static func isVibrant(_ filter: Any?) -> Bool {
        guard let filter else { return false }
        if let name = filter as? String {
            return name.range(of: "vibrant", options: .caseInsensitive) != nil
        }
        guard let object = filter as? NSObject,
              object.responds(to: NSSelectorFromString("type")),
              let type = object.value(forKey: "type") as? String
        else { return false }
        return type.range(of: "vibrant", options: .caseInsensitive) != nil
    }

    // MARK: - The material behind a subtree drawn on its own

    /// Longest side, in pixels, of the picture a window's average colour is
    /// taken from.
    static let materialStandInSampleLength: CGFloat = 256

    /// What stands in for the material behind a subtree drawn on its own:
    /// its backdrops capture it where the render is transparent, and its
    /// vibrant content acts on it. The average colour of `rootLayer`'s
    /// picture, opaque, each pixel weighted by how much of it is covered —
    /// the window behind, as near as one colour comes. Nil without Core
    /// Animation's renderer (renderInContext draws neither backdrops nor
    /// vibrancy) or when the root draws nothing.
    static func materialStandInColor(for rootLayer: CALayer) -> CGColor? {
        guard let renderer = CoreAnimationLayerRenderer.shared,
              let region = drawingRegion(of: rootLayer, hiding: [])?.rect
        else { return nil }
        let scale = min(1, materialStandInSampleLength / max(region.width, region.height))
        let request = RenderRequest(
            layer: rootLayer,
            includingSublayers: true,
            hiddenLayers: [],
            region: region,
            scale: scale,
            pixelWidth: max(1, Int((region.width * scale).rounded(.down))),
            pixelHeight: max(1, Int((region.height * scale).rounded(.down))),
            isFlipped: rootLayer.contentsAreFlipped(),
            materialStandIn: nil
        )
        return renderer.averageColor(of: request)
    }

    /// Whether `layer` is a backdrop, a layer that draws what lies behind it
    /// through its filters. CABackdropLayer is QuartzCore's, outside the SDK.
    static func isBackdrop(_ layer: CALayer) -> Bool {
        guard let backdropLayerClass = NSClassFromString("CABackdropLayer") else { return false }
        return layer.isKind(of: backdropLayerClass)
    }

    /// Whether `layer` is part of a Liquid Glass shape: a signed-distance-
    /// field layer (`CASDFLayer`, `CASDFElementLayer`) under a backdrop,
    /// whose glass filter reads it as the shape, or any layer inside one.
    /// Such a layer is never drawn on screen itself, and drawn without the
    /// backdrop above it comes out as the raw field — a rainbow-coloured
    /// lozenge, or black, green and blue blocks for the plain layers inside;
    /// it gets no image.
    static func isGlassShapeInput(_ layer: CALayer) -> Bool {
        var isInsideShapeLayer = false
        var current: CALayer? = layer
        while let candidate = current {
            // A backdrop is the glass itself; the shape is below it.
            if isBackdrop(candidate) {
                return isInsideShapeLayer
            }
            if NSStringFromClass(type(of: candidate)).hasPrefix("CASDF") {
                isInsideShapeLayer = true
            }
            current = candidate.superlayer
        }
        return false
    }

    /// The layers that portals among `layers` draw elsewhere while hiding
    /// them in place (`CAPortalLayer`'s `hidesSourceLayer`), each with its
    /// portal. An `NSGlassEffectView` draws its content over its glass this
    /// way, twice over: a portal draws the content holder into a group of
    /// layers, and a SwiftUI portal after the backdrop draws that group. The
    /// preview orders such a source's plane where its portal draws it; a
    /// source two portals draw goes with the later one in `layers`, drawn on
    /// top of the other. The pairs come in the order of `layers`.
    static func portalsHidingTheirSources(in layers: [CALayer]) -> [(source: CALayer, portal: CALayer)] {
        guard let portalLayerClass = NSClassFromString("CAPortalLayer") else { return [] }
        return layers.compactMap { layer in
            guard layer.isKind(of: portalLayerClass),
                  (layer.value(forKey: "hidesSourceLayer") as? Bool) == true,
                  let source = layer.value(forKey: "sourceLayer") as? CALayer,
                  source !== layer
            else { return nil }
            return (source, layer)
        }
    }

    /// The compositing filters that keep none of a layer's own pixels and
    /// only cut what lies beneath it.
    static let cuttingCompositingFilterTypes: Set<String> = ["destOut", "destIn"]

    /// Whether `layer` only cuts what is beneath it: it, or a layer above
    /// it, composites through `destOut` or `destIn`. A segmented control
    /// cuts its plain icon out where the selection is with a black shape in
    /// such a layer; on screen none of the shape shows, drawn on its own it
    /// is a black block. Such a layer gets no image, and the cut stays in
    /// the group image that holds what it cuts.
    static func cutsWhatIsBeneath(_ layer: CALayer) -> Bool {
        var current: CALayer? = layer
        while let candidate = current {
            if let type = filterType(of: candidate.compositingFilter), cuttingCompositingFilterTypes.contains(type) {
                return true
            }
            current = candidate.superlayer
        }
        return false
    }

    /// The type of a filter as a layer holds it: a filter name, or a
    /// CAFilter's type.
    static func filterType(of filter: Any?) -> String? {
        guard let filter else { return nil }
        if let name = filter as? String {
            return name
        }
        guard let object = filter as? NSObject, object.responds(to: NSSelectorFromString("type")) else { return nil }
        return object.value(forKey: "type") as? String
    }

    /// A node's own image: the layer without its sublayers. A backdrop keeps
    /// the glass shape layers under it — they draw nothing themselves and
    /// give the glass its shape — so an expanded glass's plane shows the
    /// glass; its other sublayers stay out.
    static func renderingOwnPNG(of layer: CALayer, isFlipped: Bool, materialStandIn: CGColor?) -> Data? {
        guard isBackdrop(layer) else {
            return renderingPNG(of: layer, includingSublayers: false, isFlipped: isFlipped, materialStandIn: materialStandIn)
        }
        let otherSublayers = (layer.sublayers ?? []).filter { !isGlassShapeInput($0) }
        return renderingPNG(
            of: layer, includingSublayers: true, hiding: otherSublayers, isFlipped: isFlipped, materialStandIn: materialStandIn
        )
    }

    /// Whether a backdrop in `root`'s subtree captures transparency when the
    /// subtree is drawn on its own over `region` (in `root`'s bounds space):
    /// a visible backdrop whose capture — its bounds widened by its margin,
    /// within the region — no opaque fill drawn before it in painter's order
    /// covers. `hiddenLayers` count as hidden.
    ///
    /// Errs towards yes. Only a plain rectangular fill counts as cover, and
    /// only one that covers a whole capture by itself: a wrong yes costs a
    /// second render, a wrong no leaves a backdrop's colours blown up. A
    /// window's background covers every backdrop in it, so the subtrees
    /// holding that background are drawn once.
    static func hasBackdropCapturingTransparency(
        in root: CALayer,
        region: CGRect,
        hiding hiddenLayers: [CALayer] = []
    ) -> Bool {
        let hidden = Set(hiddenLayers.map(ObjectIdentifier.init))
        var opaqueRects: [CGRect] = []
        func visiting(_ layer: CALayer, clip: CGRect, drawsPlainly: Bool) -> Bool {
            guard !layer.isHidden, layer.opacity > 0, !hidden.contains(ObjectIdentifier(layer)) else { return false }
            let rect = layer.convert(layer.bounds, to: root)
            let layerIsBackdrop = isBackdrop(layer)
            if layerIsBackdrop {
                let margin = (layer.value(forKey: "marginWidth") as? NSNumber).map { CGFloat($0.doubleValue) } ?? 0
                let capture = rect.insetBy(dx: -margin, dy: -margin).intersection(region)
                if !capture.isEmpty, !opaqueRects.contains(where: { $0.contains(capture) }) {
                    return true
                }
            }
            // A fill is opaque only if nothing between it and the root fades,
            // masks, filters or blends it.
            let layerDrawsPlainly = drawsPlainly
                && layer.opacity >= 1
                && layer.mask == nil
                && layer.compositingFilter == nil
                && (layer.filters?.isEmpty ?? true)
            if layerDrawsPlainly, !layerIsBackdrop, layer.cornerRadius <= 0,
               let backgroundColor = layer.backgroundColor, backgroundColor.alpha >= 1
            {
                opaqueRects.append(rect.intersection(clip))
            }
            let sublayerClip = layer.masksToBounds ? rect.intersection(clip) : clip
            for sublayer in layer.sublayers ?? [] {
                if visiting(sublayer, clip: sublayerClip, drawsPlainly: layerDrawsPlainly) {
                    return true
                }
            }
            return false
        }
        return visiting(root, clip: .infinite, drawsPlainly: true)
    }

    /// An opaque colour as the 8-bit sRGB components the renderer writes.
    struct OpaqueColorBytes: Equatable {
        let red: UInt8
        let green: UInt8
        let blue: UInt8

        init(red: UInt8, green: UInt8, blue: UInt8) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        /// `color` in sRGB, its alpha ignored; nil when it does not convert.
        init?(_ color: CGColor) {
            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let components = color.converted(to: colorSpace, intent: .defaultIntent, options: nil)?.components,
                  components.count >= 3
            else { return nil }
            func byte(_ component: CGFloat) -> UInt8 {
                UInt8((min(max(component, 0), 1) * 255).rounded())
            }
            self.init(red: byte(components[0]), green: byte(components[1]), blue: byte(components[2]))
        }
    }

    /// What drawing a render over a material stand-in calls for.
    struct MaterialStandInUse {
        /// Where vibrant fills with nothing behind them lie, in the render's
        /// pixels, top row first (`removingMaterialStandIn`'s
        /// `uncoveredRegions`).
        let vibrantFillRegions: [CGRect]
        /// The blur materials in the render (`materialBackdrops(in:hiding:)`),
        /// whose part of the stand-in stays.
        let materialBackdrops: [CALayer]
    }

    /// The blur materials in `root`'s subtree as it is drawn: the visible
    /// backdrops that draw what they capture — not capture-only, not
    /// disabled — and are no glass. On screen a material covers what lies
    /// behind it with the blur of it; drawn on its own it captures the
    /// stand-in, the window's tone, and that part of the stand-in stays in
    /// the picture rather than coming back out, so an expanded toolbar or
    /// scroll edge plane is the band it is on screen. Glass gets its shape
    /// from the distance-field layers under it and keeps what its filter
    /// draws. `hiddenLayers` count as hidden.
    static func materialBackdrops(in root: CALayer, hiding hiddenLayers: [CALayer] = []) -> [CALayer] {
        let hidden = Set(hiddenLayers.map(ObjectIdentifier.init))
        var backdrops: [CALayer] = []
        var pending = [root]
        while let layer = pending.popLast() {
            guard !layer.isHidden, layer.opacity > 0, !hidden.contains(ObjectIdentifier(layer)) else { continue }
            if isBackdrop(layer), drawsMaterial(layer) {
                backdrops.append(layer)
            }
            pending.append(contentsOf: layer.sublayers ?? [])
        }
        return backdrops
    }

    /// Whether `backdrop` draws a blur material: it draws what it captures
    /// (`enabled`, not `captureOnly`) and holds no glass shape.
    private static func drawsMaterial(_ backdrop: CALayer) -> Bool {
        if (backdrop.value(forKey: "captureOnly") as? Bool) == true || (backdrop.value(forKey: "enabled") as? Bool) == false {
            return false
        }
        return !(backdrop.sublayers ?? []).contains { NSStringFromClass(type(of: $0)).hasPrefix("CASDF") }
    }

    /// Whether `request` is to be drawn over a material stand-in as well,
    /// and what for; nil when the render over transparency is already the
    /// picture: no backdrop in it captures transparency
    /// (`hasBackdropCapturingTransparency`) and no vibrant content in it
    /// lacks its material.
    static func materialStandInUse(for request: RenderRequest) -> MaterialStandInUse? {
        let layer = request.layer
        let vibrantFills: [CALayer]
        let needsStandIn: Bool
        var capturingMaterials: [CALayer] = []
        if request.includingSublayers {
            vibrantFills = vibrantFillsWithNothingBehind(in: layer)
            let capturesTransparency = hasBackdropCapturingTransparency(in: layer, region: request.region, hiding: request.hiddenLayers)
            needsStandIn = !vibrantFills.isEmpty
                || !vibrantLayersWithNothingBehind(in: layer).isEmpty
                || capturesTransparency
            if capturesTransparency {
                capturingMaterials = materialBackdrops(in: layer, hiding: request.hiddenLayers)
            }
        } else {
            // Drawn without its sublayers, a layer has nothing behind it.
            vibrantFills = !layer.isHidden && isVibrantFill(layer) ? [layer] : []
            needsStandIn = !vibrantFills.isEmpty || drawsThroughRemovableVibrantFilter(layer)
        }
        guard needsStandIn else { return nil }
        return MaterialStandInUse(
            vibrantFillRegions: vibrantFills.compactMap { pixelRegion(of: $0, in: request) },
            materialBackdrops: capturingMaterials
        )
    }

    /// Where `sublayer` — `request.layer` itself or a layer of its subtree —
    /// lies in the render's pixels, top row first, widened by a pixel for an
    /// antialiased edge; nil when it lies outside the render.
    private static func pixelRegion(of sublayer: CALayer, in request: RenderRequest) -> CGRect? {
        let rectInLayer = sublayer === request.layer
            ? sublayer.bounds
            : sublayer.convert(sublayer.bounds, to: request.layer)
        let visibleRect = rectInLayer.intersection(request.region)
        guard !visibleRect.isNull, !visibleRect.isEmpty else { return nil }
        // The image's top row is the layer's top as it shows: the region's
        // low edge when the layer's space runs downwards, its high edge
        // otherwise.
        let distanceFromTop = request.isFlipped
            ? visibleRect.minY - request.region.minY
            : request.region.maxY - visibleRect.maxY
        let pixelRect = CGRect(
            x: (visibleRect.minX - request.region.minX) * request.scale,
            y: distanceFromTop * request.scale,
            width: visibleRect.width * request.scale,
            height: visibleRect.height * request.scale
        ).integral.insetBy(dx: -1, dy: -1)
        let clippedRect = pixelRect.intersection(CGRect(x: 0, y: 0, width: request.pixelWidth, height: request.pixelHeight))
        return clippedRect.isNull || clippedRect.isEmpty ? nil : clippedRect
    }

    /// A difference from the stand-in this small, in 8-bit steps, is the
    /// renderer's own noise between two renders, not a vibrant fill.
    static let vibrantFillNoiseLevel = 2

    /// Lays what vibrant fills made of the stand-in over the pixels of one
    /// region that the subtree leaves clear over transparency
    /// (`removingMaterialStandIn`'s `uncoveredRegions`). `overStandIn` holds
    /// the region's pixels of the render over the stand-in, row after row;
    /// `pixels` and `coverage` are the whole render, `width` pixels wide.
    ///
    /// Written with plain loops over raw pointers: a fill can span a sidebar
    /// and turn up in many renders, and the iterators of an unoptimised
    /// build made this the import's slowest step.
    private static func keepingVibrantFillSheens(
        in pixels: UnsafeMutablePointer<UInt8>,
        overStandIn: UnsafePointer<UInt8>,
        coverage: UnsafePointer<UInt8>,
        width: Int,
        columns: Range<Int>,
        rows: Range<Int>,
        standIn: OpaqueColorBytes
    ) {
        // Memory order: blue, green, red.
        let standInBlue = Int(standIn.blue), standInGreen = Int(standIn.green), standInRed = Int(standIn.red)
        func lighteningScale(_ component: Int) -> Double { component < 255 ? 1 / Double(255 - component) : 0 }
        func darkeningScale(_ component: Int) -> Double { component > 0 ? 1 / Double(component) : 0 }
        let lighteningBlue = lighteningScale(standInBlue), darkeningBlue = darkeningScale(standInBlue)
        let lighteningGreen = lighteningScale(standInGreen), darkeningGreen = darkeningScale(standInGreen)
        let lighteningRed = lighteningScale(standInRed), darkeningRed = darkeningScale(standInRed)
        let noise = vibrantFillNoiseLevel
        // The alpha a white (lighter) or black (darker) overlay needs for
        // one channel's change.
        func overlayAlpha(_ difference: Int, lightening: Double, darkening: Double) -> Double {
            if difference > noise { return Double(difference) * lightening }
            if difference < -noise { return Double(-difference) * darkening }
            return 0
        }
        func premultiplied(_ overStandIn: UInt8, standInComponent: Int, alpha: Int) -> UInt8 {
            let value = Int(overStandIn) - ((255 - alpha) * standInComponent + 127) / 255
            if value < 0 { return 0 }
            return UInt8(value > alpha ? alpha : value)
        }
        let copiedRowByteCount = columns.count * 4
        var row = rows.lowerBound
        var copiedRowStart = 0
        while row < rows.upperBound {
            var column = columns.lowerBound
            var pixelStart = (row * width + column) * 4
            var copiedStart = copiedRowStart
            while column < columns.upperBound {
                if coverage[pixelStart + 3] == 0 {
                    let blueDifference = Int(overStandIn[copiedStart]) - standInBlue
                    let greenDifference = Int(overStandIn[copiedStart + 1]) - standInGreen
                    let redDifference = Int(overStandIn[copiedStart + 2]) - standInRed
                    var alpha = overlayAlpha(blueDifference, lightening: lighteningBlue, darkening: darkeningBlue)
                    let greenAlpha = overlayAlpha(greenDifference, lightening: lighteningGreen, darkening: darkeningGreen)
                    if greenAlpha > alpha { alpha = greenAlpha }
                    let redAlpha = overlayAlpha(redDifference, lightening: lighteningRed, darkening: darkeningRed)
                    if redAlpha > alpha { alpha = redAlpha }
                    if alpha > 0 {
                        var alphaByte = Int(alpha * 255 + 0.5)
                        if alphaByte > 255 { alphaByte = 255 }
                        pixels[pixelStart] = premultiplied(overStandIn[copiedStart], standInComponent: standInBlue, alpha: alphaByte)
                        pixels[pixelStart + 1] = premultiplied(overStandIn[copiedStart + 1], standInComponent: standInGreen, alpha: alphaByte)
                        pixels[pixelStart + 2] = premultiplied(overStandIn[copiedStart + 2], standInComponent: standInRed, alpha: alphaByte)
                        pixels[pixelStart + 3] = UInt8(alphaByte)
                    }
                }
                column += 1
                pixelStart += 4
                copiedStart += 4
            }
            row += 1
            copiedRowStart += copiedRowByteCount
        }
    }

    /// Takes an opaque stand-in back out of a render drawn over it, in
    /// place.
    ///
    /// `pixels` holds a subtree drawn over `standIn` and becomes the result;
    /// `coverage` is the same subtree drawn over transparency, whose alpha
    /// says how much of each pixel the subtree covers. Both are premultiplied
    /// BGRA, `width` by `height`, as the renderer reads them back. Content
    /// composited normally comes out over the stand-in as
    /// content + (1 − alpha) × stand-in, so taking the second term away
    /// leaves the content exactly — drawn with backdrops that captured the
    /// stand-in and vibrant filters that acted on it. The result has the
    /// coverage's alpha, and no colour component above it.
    ///
    /// In `uncoveredRegions` (pixel rects, top row first), a pixel the
    /// subtree leaves clear over transparency keeps what vibrant fills made
    /// of the stand-in there: the faintest white or black that, laid over
    /// the stand-in, gives the pixel — a highlight's sheen or a shade.
    ///
    /// Returns false when vImage fails, `pixels` then being of no use: the
    /// render over transparency is the picture to keep.
    static func removingMaterialStandIn(
        _ standIn: OpaqueColorBytes,
        from pixels: inout [UInt8],
        coverage: [UInt8],
        width: Int,
        height: Int,
        uncoveredRegions: [CGRect] = []
    ) -> Bool {
        let byteCount = width * height * 4
        guard width > 0, height > 0, pixels.count == byteCount, coverage.count == byteCount else { return false }
        let flags = vImage_Flags(kvImageNoFlags)

        // The vibrant fills' part of the render over the stand-in, kept
        // aside before the stand-in comes off everywhere.
        let fillRegions = uncoveredRegions.compactMap { region -> (columns: Range<Int>, rows: Range<Int>)? in
            let columns = max(0, Int(region.minX)) ..< min(width, Int(region.maxX))
            let rows = max(0, Int(region.minY)) ..< min(height, Int(region.maxY))
            return columns.isEmpty || rows.isEmpty ? nil : (columns, rows)
        }
        let fillPixelsOverStandIn = fillRegions.map { region in
            let rowByteCount = region.columns.count * 4
            return [UInt8](unsafeUninitializedCapacity: rowByteCount * region.rows.count) { buffer, initializedCount in
                pixels.withUnsafeBytes { source in
                    guard let destination = buffer.baseAddress, let sourceStart = source.baseAddress else { return }
                    for (copiedRow, row) in region.rows.enumerated() {
                        memcpy(
                            destination + copiedRow * rowByteCount,
                            sourceStart + (row * width + region.columns.lowerBound) * 4,
                            rowByteCount
                        )
                    }
                }
                initializedCount = rowByteCount * region.rows.count
            }
        }

        // The coverage's alpha, as a plane.
        var extractedCoverageAlpha = false
        let coverageAlpha = [UInt8](unsafeUninitializedCapacity: width * height) { buffer, initializedCount in
            coverage.withUnsafeBytes { coverageBytes in
                var coverageBuffer = vImage_Buffer(
                    data: UnsafeMutableRawPointer(mutating: coverageBytes.baseAddress),
                    height: vImagePixelCount(height),
                    width: vImagePixelCount(width),
                    rowBytes: width * 4
                )
                var alphaBuffer = vImage_Buffer(
                    data: buffer.baseAddress,
                    height: vImagePixelCount(height),
                    width: vImagePixelCount(width),
                    rowBytes: width
                )
                // Channel 3 is the last of the four, the alpha of BGRA.
                extractedCoverageAlpha = vImageExtractChannel_ARGB8888(&coverageBuffer, &alphaBuffer, 3, flags) == kvImageNoError
            }
            initializedCount = extractedCoverageAlpha ? width * height : 0
        }
        guard extractedCoverageAlpha else { return false }

        // Channel by channel in memory order (blue, green, red, alpha), each
        // output channel takes the input channels times one matrix row:
        //   colour = (255 × colour + stand-in × alpha − 255 × stand-in) / 255
        //   alpha  = alpha
        let standInComponents = [Int32(standIn.blue), Int32(standIn.green), Int32(standIn.red)]
        let matrix: [Int16] = [
            255, 0, 0, 0,
            0, 255, 0, 0,
            0, 0, 255, 0,
            Int16(standIn.blue), Int16(standIn.green), Int16(standIn.red), 255,
        ]
        let rounding: Int32 = 127
        let postBias: [Int32] = standInComponents.map { -255 * $0 + rounding } + [rounding]
        let tookStandInOut = coverageAlpha.withUnsafeBytes { coverageAlphaBytes in
            pixels.withUnsafeMutableBytes { pixelBytes in
                var alphaBuffer = vImage_Buffer(
                    data: UnsafeMutableRawPointer(mutating: coverageAlphaBytes.baseAddress),
                    height: vImagePixelCount(height),
                    width: vImagePixelCount(width),
                    rowBytes: width
                )
                var pixelBuffer = vImage_Buffer(
                    data: pixelBytes.baseAddress,
                    height: vImagePixelCount(height),
                    width: vImagePixelCount(width),
                    rowBytes: width * 4
                )
                // The coverage's alpha into the last channel (copy mask 0x1
                // names the last of the four), the matrix, then no colour
                // above alpha (vImageClipToAlpha_BGRA8888 is a macro Swift
                // does not see).
                return vImageOverwriteChannels_ARGB8888(&alphaBuffer, &pixelBuffer, &pixelBuffer, 0x1, flags) == kvImageNoError
                    && vImageMatrixMultiply_ARGB8888(&pixelBuffer, &pixelBuffer, matrix, 255, nil, postBias, flags) == kvImageNoError
                    && vImageClipToAlpha_RGBA8888(&pixelBuffer, &pixelBuffer, flags) == kvImageNoError
            }
        }
        guard tookStandInOut else { return false }

        pixels.withUnsafeMutableBufferPointer { resultPixels in
            coverage.withUnsafeBufferPointer { coveragePixels in
                guard let resultStart = resultPixels.baseAddress, let coverageStart = coveragePixels.baseAddress else { return }
                for (regionIndex, region) in fillRegions.enumerated() {
                    fillPixelsOverStandIn[regionIndex].withUnsafeBufferPointer { overStandInPixels in
                        guard let overStandInStart = overStandInPixels.baseAddress else { return }
                        keepingVibrantFillSheens(
                            in: resultStart,
                            overStandIn: overStandInStart,
                            coverage: coverageStart,
                            width: width,
                            columns: region.columns,
                            rows: region.rows,
                            standIn: standIn
                        )
                    }
                }
            }
        }
        return true
    }

    // MARK: - Rendering

    /// What one render draws.
    struct RenderRequest {
        let layer: CALayer
        let includingSublayers: Bool
        /// Hidden for the duration of the render; descendants of `layer`.
        let hiddenLayers: [CALayer]
        /// The part of the layer's bounds the image covers.
        let region: CGRect
        let scale: CGFloat
        let pixelWidth: Int
        let pixelHeight: Int
        /// The layer's cumulative flip in its tree (`contentsAreFlipped`).
        let isFlipped: Bool
        /// What stands in for the material behind the layer
        /// (`materialStandInColor(for:)`); nil to draw it as it is.
        let materialStandIn: CGColor?
    }

    /// `hiddenLayers` are hidden for the duration of the render and restored
    /// afterwards; they must be descendants of `layer`. `region`, a rect in
    /// the layer's bounds space, limits the render to that part of the
    /// bounds; the image then covers exactly the region. `isFlipped` is the
    /// layer's cumulative flip in its tree, and the image shows the layer the
    /// way it looks there. `materialStandIn` stands in for the material
    /// behind the layer (`materialStandInColor(for:)`): where a backdrop in
    /// the render would capture transparency or vibrant content would lack
    /// its material (`materialStandInUse(for:)`), the layer is drawn a second
    /// time over it, and it is taken back out. Pass nil for a window's root,
    /// whose image is the window.
    ///
    /// Not to be called inside an explicit CATransaction: the render commits
    /// its own, which an enclosing one would hold back.
    static func renderingPNG(
        of layer: CALayer,
        includingSublayers: Bool,
        hiding hiddenLayers: [CALayer] = [],
        region: CGRect? = nil,
        isFlipped: Bool,
        materialStandIn: CGColor? = nil
    ) -> Data? {
        guard let renderedImage = renderingImage(
            of: layer,
            includingSublayers: includingSublayers,
            hiding: hiddenLayers,
            region: region,
            isFlipped: isFlipped,
            materialStandIn: materialStandIn
        ) else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: renderedImage)
        return bitmap.representation(using: .png, properties: [:])
    }

    /// `renderingPNG`'s picture before it is encoded: for a live session,
    /// which hands it to the preview at once and has no file to write.
    static func renderingImage(
        of layer: CALayer,
        includingSublayers: Bool,
        hiding hiddenLayers: [CALayer] = [],
        region: CGRect? = nil,
        isFlipped: Bool,
        materialStandIn: CGColor? = nil
    ) -> CGImage? {
        let bounds = region ?? layer.bounds
        guard bounds.width >= minimumRenderedEdgeLength, bounds.height >= minimumRenderedEdgeLength,
              bounds.width.isFinite, bounds.height.isFinite
        else { return nil }

        // A group image holds the whole subtree, so it is as sharp as the
        // sharpest layer in it: a window's root layer never draws and keeps a
        // contentsScale of 1 while the views inside draw at 2x. A solo image
        // is the layer's own drawing, at the layer's own scale.
        let contentsScale = includingSublayers ? sharpestContentsScale(in: layer) : layer.contentsScale
        let scale = renderingScale(contentsScale: contentsScale, size: bounds.size)
        // Rounded down so a layer sitting exactly at a cap cannot creep past
        // it by a row of pixels.
        let pixelWidth = Int((bounds.width * scale).rounded(.down))
        let pixelHeight = Int((bounds.height * scale).rounded(.down))
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        let request = RenderRequest(
            layer: layer,
            includingSublayers: includingSublayers,
            hiddenLayers: hiddenLayers.filter { !$0.isHidden },
            region: bounds,
            scale: scale,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            isFlipped: isFlipped,
            materialStandIn: materialStandIn
        )
        return if let renderer = CoreAnimationLayerRenderer.shared {
            renderer.rendering(request)
        } else {
            renderingWithCoreGraphics(request)
        }
    }

    /// The largest `contentsScale` in `layer`'s subtree, the layer's own
    /// included.
    static func sharpestContentsScale(in layer: CALayer) -> CGFloat {
        var sharpestScale = layer.contentsScale
        for sublayer in layer.sublayers ?? [] {
            sharpestScale = max(sharpestScale, sharpestContentsScale(in: sublayer))
        }
        return sharpestScale
    }

    /// Strips the animations off a decoded tree, so that Core Animation's
    /// renderer, which plays them, draws the layers' own values as
    /// renderInContext did — an archived blink or spinner would otherwise
    /// land in whatever phase the clock is in.
    static func removingAnimations(from layer: CALayer) {
        layer.removeAllAnimations()
        layer.mask.map(removingAnimations(from:))
        for sublayer in layer.sublayers ?? [] {
            removingAnimations(from: sublayer)
        }
    }

    /// The software path, for a machine without a Metal device: CGContext's
    /// renderInContext. It ignores the flag on the layer it draws, so a layer
    /// whose cumulative flip is odd has its context mirrored instead.
    private static func renderingWithCoreGraphics(_ request: RenderRequest) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: request.pixelWidth,
            height: request.pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceSRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let layer = request.layer
        let detachedSublayers = request.includingSublayers ? nil : layer.sublayers.flatMap { $0.isEmpty ? nil : $0 }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if detachedSublayers != nil {
            layer.sublayers = nil
        }
        for hiddenLayer in request.hiddenLayers {
            hiddenLayer.isHidden = true
        }
        CATransaction.commit()
        defer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if let detachedSublayers {
                layer.sublayers = detachedSublayers
            }
            for hiddenLayer in request.hiddenLayers {
                hiddenLayer.isHidden = false
            }
            CATransaction.commit()
        }

        let bounds = request.region
        context.scaleBy(x: request.scale, y: request.scale)
        if request.isFlipped {
            context.translateBy(x: 0, y: bounds.height)
            context.scaleBy(x: 1, y: -1)
        }
        context.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
        layer.render(in: context)

        guard let renderedImage = context.makeImage(), containsVisiblePixels(context) else { return nil }
        return renderedImage
    }

    /// Scale that keeps the layer's own resolution without exceeding either
    /// cap: first the longest side, then the pixel budget.
    ///
    /// Both caps are hard limits, so the scale has no floor. A floor of 0.1
    /// once let anything longer than ten texture edges — the console of a
    /// dumped Xcode window, 256310 points of text — render past the edge,
    /// and the preview asserts on such an image.
    static func renderingScale(for layer: CALayer) -> CGFloat {
        renderingScale(contentsScale: layer.contentsScale, size: layer.bounds.size)
    }

    static func renderingScale(contentsScale: CGFloat, size: CGSize) -> CGFloat {
        var scale = contentsScale > 0 ? contentsScale : 1
        let longestSide = max(size.width, size.height)
        if longestSide * scale > maximumRenderedEdgeLength {
            scale = maximumRenderedEdgeLength / longestSide
        }
        let pixelCount = size.width * scale * size.height * scale
        if pixelCount > CGFloat(maximumRenderedPixelCount) {
            scale *= (CGFloat(maximumRenderedPixelCount) / pixelCount).squareRoot()
        }
        return scale
    }

    /// Xcode's `-[DBGViewSurface _needsImageSnapshot]`, negated: a plain
    /// CALayer whose only drawing is a solid background colour. Anything that
    /// draws more — contents, a mask, a border, rounded corners, a shadow, a
    /// filter, a subclass with its own drawing, a pattern colour — needs a
    /// real render.
    static func representsPlainColorFill(_ layer: CALayer) -> Bool {
        guard type(of: layer) == CALayer.self,
              layer.contents == nil,
              layer.mask == nil,
              layer.borderWidth <= 0,
              layer.cornerRadius <= 0,
              layer.shadowOpacity <= 0,
              layer.compositingFilter == nil,
              layer.filters?.isEmpty ?? true,
              layer.backgroundFilters?.isEmpty ?? true
        else { return false }
        if let backgroundColor = layer.backgroundColor,
           let colorSpace = backgroundColor.colorSpace,
           colorSpace.model == .pattern
        {
            return false
        }
        return true
    }

    /// True when anything was drawn.
    ///
    /// Most layers in a capture are transparent containers. Storing their empty
    /// images would multiply the document's memory for nothing — the inspector
    /// already falls back to the node's background colour when an image is
    /// absent.
    private static func containsVisiblePixels(_ context: CGContext) -> Bool {
        guard let pixels = context.data else { return false }
        let width = context.width
        let height = context.height
        let bytesPerRow = context.bytesPerRow
        let buffer = pixels.bindMemory(to: UInt8.self, capacity: bytesPerRow * height)

        for row in 0 ..< height {
            let rowStart = row * bytesPerRow
            for column in 0 ..< width where buffer[rowStart + column * 4 + 3] != 0 {
                return true
            }
        }
        return false
    }

    private static func CGColorSpaceSRGB() -> CGColorSpace {
        CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    }
}

// MARK: - Core Animation's renderer

/// Draws layers with Core Animation's own renderer into Metal textures: the
/// engine that puts them on screen, so glass, backdrops, portals and masks
/// come out as they look there.
///
/// One per process. CARenderer and the container it draws are not thread
/// safe, and two imports can run at once, so renders take turns.
final class CoreAnimationLayerRenderer: @unchecked Sendable {
    /// Nil where there is no Metal device, or where a test render does not
    /// come back right; renders then fall back to CGContext.
    static let shared: CoreAnimationLayerRenderer? = CoreAnimationLayerRenderer()

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let renderer: CARenderer
    /// The root of every render: the layer being drawn is moved in for the
    /// render and put back in its tree afterwards.
    private let containerLayer = CALayer()
    private let lock = NSLock()

    private init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let placeholderTexture = Self.makingTexture(on: device, width: 1, height: 1)
        else { return nil }
        self.device = device
        self.commandQueue = commandQueue
        renderer = CARenderer(mtlTexture: placeholderTexture, options: [
            kCARendererMetalCommandQueue: commandQueue,
            kCARendererColorSpace: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
        ])
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        containerLayer.anchorPoint = .zero
        containerLayer.position = .zero
        renderer.layer = containerLayer
        CATransaction.commit()

        guard rendersATestLayer() else { return nil }
    }

    /// The image `request` describes, or nil when it drew nothing.
    ///
    /// With a material stand-in, a layer whose backdrops would capture
    /// transparency or whose vibrant content would lack its material
    /// (`materialStandInUse(for:)`) is drawn twice — over transparency for
    /// each pixel's coverage, vibrant content drawn plain; over the stand-in
    /// for its colour, vibrant filters acting on it — and the stand-in is
    /// taken back out (`removingMaterialStandIn`), except where a blur
    /// material lies: its coverage comes from a third render, with every
    /// material filled.
    func rendering(_ request: XcodeViewHierarchyPixelRecovery.RenderRequest) -> CGImage? {
        lock.lock()
        defer { lock.unlock() }
        guard var pixels = renderingPixels(request) else { return nil }
        if let materialStandIn = request.materialStandIn,
           let standInUse = XcodeViewHierarchyPixelRecovery.materialStandInUse(for: request),
           let standInBytes = XcodeViewHierarchyPixelRecovery.OpaqueColorBytes(materialStandIn),
           var pixelsOverStandIn = renderingPixels(request, background: materialStandIn),
           XcodeViewHierarchyPixelRecovery.removingMaterialStandIn(
               standInBytes,
               from: &pixelsOverStandIn,
               coverage: standInUse.materialBackdrops.isEmpty
                   ? pixels
                   : renderingPixels(request, filling: standInUse.materialBackdrops) ?? pixels,
               width: request.pixelWidth,
               height: request.pixelHeight,
               uncoveredRegions: standInUse.vibrantFillRegions
           )
        {
            pixels = pixelsOverStandIn
        }
        guard Self.containsVisiblePixels(pixels) else { return nil }
        return Self.makingImage(pixels, width: request.pixelWidth, height: request.pixelHeight)
    }

    /// The average colour of what `request` draws, opaque, each pixel
    /// weighted by its alpha; nil when it draws nothing.
    func averageColor(of request: XcodeViewHierarchyPixelRecovery.RenderRequest) -> CGColor? {
        lock.lock()
        defer { lock.unlock() }
        guard let pixels = renderingPixels(request) else { return nil }
        // Blue, green, red and alpha; premultiplied, so the colour sums over
        // the alpha sum are the coverage-weighted average.
        var sums = [Double](repeating: 0, count: 4)
        var pixelStart = 0
        while pixelStart + 3 < pixels.count {
            for channel in 0 ..< 4 {
                sums[channel] += Double(pixels[pixelStart + channel])
            }
            pixelStart += 4
        }
        guard sums[3] > 0 else { return nil }
        return CGColor(
            srgbRed: CGFloat(sums[2] / sums[3]),
            green: CGFloat(sums[1] / sums[3]),
            blue: CGFloat(sums[0] / sums[3]),
            alpha: 1
        )
    }

    /// A small red layer, drawn and read back: proof that this machine's
    /// renderer works before an import depends on it.
    private func rendersATestLayer() -> Bool {
        let testLayer = CALayer()
        testLayer.bounds = CGRect(x: 0, y: 0, width: 4, height: 4)
        testLayer.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
        let request = XcodeViewHierarchyPixelRecovery.RenderRequest(
            layer: testLayer,
            includingSublayers: true,
            hiddenLayers: [],
            region: testLayer.bounds,
            scale: 1,
            pixelWidth: 4,
            pixelHeight: 4,
            isFlipped: false,
            materialStandIn: nil
        )
        guard let pixels = renderingPixels(request) else { return false }
        // Blue, green, red, alpha.
        return pixels[0] < 16 && pixels[1] < 16 && pixels[2] > 240 && pixels[3] > 240
    }

    /// BGRA, premultiplied, top row first. `background`, when given, fills
    /// the render behind the layer and stands in for the material of its
    /// vibrant content; without it, vibrant images and text with nothing
    /// behind them are drawn plain.
    /// `request` drawn over `background`, or over transparency. `filledLayers`
    /// get an opaque background for the render, which says how much of each
    /// pixel they cover however little they draw.
    private func renderingPixels(
        _ request: XcodeViewHierarchyPixelRecovery.RenderRequest,
        background: CGColor? = nil,
        filling filledLayers: [CALayer] = []
    ) -> [UInt8]? {
        let width = request.pixelWidth
        let height = request.pixelHeight
        guard let texture = Self.makingTexture(on: device, width: width, height: height) else { return nil }

        let layer = request.layer
        let originalSuperlayer = layer.superlayer
        let originalIndex = originalSuperlayer?.sublayers?.firstIndex { $0 === layer }
        let originalPosition = layer.position
        let originalAnchorPoint = layer.anchorPoint
        let originalTransform = layer.transform
        let detachedSublayers = request.includingSublayers ? nil : layer.sublayers.flatMap { $0.isEmpty ? nil : $0 }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.removeFromSuperlayer()
        if detachedSublayers != nil {
            layer.sublayers = nil
        }
        for hiddenLayer in request.hiddenLayers {
            hiddenLayer.isHidden = true
        }
        let filledLayerBackgrounds = filledLayers.map(\.backgroundColor)
        let fillColor = CGColor(gray: 0, alpha: 1)
        for filledLayer in filledLayers {
            filledLayer.backgroundColor = fillColor
        }
        // Vibrant images and text whose material an ancestor or a sibling
        // draws would vanish with it. Over transparency their vibrant
        // filters come off for this render; over a background they stay and
        // act on it.
        let plainVibrantLayers = background == nil
            ? XcodeViewHierarchyPixelRecovery.vibrantLayersWithNothingBehind(in: layer)
            : []
        let vibrantCompositingFilters = plainVibrantLayers.map(\.compositingFilter)
        let vibrantFilterLists = plainVibrantLayers.map(\.filters)
        for vibrantLayer in plainVibrantLayers {
            if XcodeViewHierarchyPixelRecovery.isVibrant(vibrantLayer.compositingFilter) {
                vibrantLayer.compositingFilter = nil
            }
            if let filters = vibrantLayer.filters {
                vibrantLayer.filters = filters.filter { !XcodeViewHierarchyPixelRecovery.isVibrant($0) }
            }
        }
        // Only the layer's bounds space is drawn, as renderInContext draws
        // it: its position and transform belong to its superlayer's picture.
        // The region goes to the container's origin. A layer flipped by its
        // own flag lays its bounds space out from its top edge down, so
        // there the region's top, not its bottom, lines up with the
        // container's.
        layer.transform = CATransform3DIdentity
        layer.anchorPoint = .zero
        let regionOffsetY = layer.isGeometryFlipped
            ? request.region.maxY - layer.bounds.maxY
            : layer.bounds.origin.y - request.region.origin.y
        layer.position = CGPoint(x: layer.bounds.origin.x - request.region.origin.x, y: regionOffsetY)
        // The container stands in for the superlayer's cumulative flip, so
        // the subtree lies as it does in its tree.
        containerLayer.isGeometryFlipped = request.isFlipped != layer.isGeometryFlipped
        containerLayer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        containerLayer.sublayerTransform = CATransform3DMakeScale(request.scale, request.scale, 1)
        containerLayer.backgroundColor = background
        containerLayer.addSublayer(layer)
        renderer.setDestination(texture)
        renderer.bounds = containerLayer.bounds
        CATransaction.commit()
        CATransaction.flush()

        renderer.beginFrame(atTime: CACurrentMediaTime(), timeStamp: nil)
        renderer.addUpdate(renderer.bounds)
        renderer.render()
        renderer.endFrame()
        // Work committed after the renderer's on the same queue finishes
        // after it; a managed texture is copied back for the CPU on the way.
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            if texture.storageMode == .managed, let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                blitEncoder.synchronize(resource: texture)
                blitEncoder.endEncoding()
            }
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.removeFromSuperlayer()
        containerLayer.backgroundColor = nil
        layer.transform = originalTransform
        layer.anchorPoint = originalAnchorPoint
        layer.position = originalPosition
        if let detachedSublayers {
            layer.sublayers = detachedSublayers
        }
        for hiddenLayer in request.hiddenLayers {
            hiddenLayer.isHidden = false
        }
        for (index, filledLayer) in filledLayers.enumerated() {
            filledLayer.backgroundColor = filledLayerBackgrounds[index]
        }
        for (index, vibrantLayer) in plainVibrantLayers.enumerated() {
            vibrantLayer.compositingFilter = vibrantCompositingFilters[index]
            vibrantLayer.filters = vibrantFilterLists[index]
        }
        if let originalSuperlayer, let originalIndex {
            originalSuperlayer.insertSublayer(layer, at: UInt32(originalIndex))
        }
        CATransaction.commit()
        CATransaction.flush()

        let bytesPerRow = width * 4
        // Read straight into uninitialised storage: every byte is written,
        // and filling a large array with zeros first is slow in an
        // unoptimised build.
        return [UInt8](unsafeUninitializedCapacity: bytesPerRow * height) { buffer, initializedCount in
            guard let baseAddress = buffer.baseAddress else {
                initializedCount = 0
                return
            }
            // The texture's first row is the bottom of the picture; an
            // image's first row is its top.
            for row in 0 ..< height {
                texture.getBytes(
                    baseAddress + (height - 1 - row) * bytesPerRow,
                    bytesPerRow: bytesPerRow,
                    from: MTLRegionMake2D(0, row, width, 1),
                    mipmapLevel: 0
                )
            }
            initializedCount = bytesPerRow * height
        }
    }

    private static func makingTexture(on device: MTLDevice, width: Int, height: Int) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        // Read back on the CPU: shared where the GPU shares memory with it,
        // managed on a discrete GPU.
        descriptor.storageMode = device.hasUnifiedMemory ? .shared : .managed
        return device.makeTexture(descriptor: descriptor)
    }

    private static func containsVisiblePixels(_ pixels: [UInt8]) -> Bool {
        pixels.withUnsafeBufferPointer { buffer in
            var alphaIndex = 3
            while alphaIndex < buffer.count {
                if buffer[alphaIndex] != 0 {
                    return true
                }
                alphaIndex += 4
            }
            return false
        }
    }

    private static func makingImage(_ pixels: [UInt8], width: Int, height: Int) -> CGImage? {
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(
                rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
