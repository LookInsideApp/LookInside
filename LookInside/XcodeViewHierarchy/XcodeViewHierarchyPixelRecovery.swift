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
            let isFlipped = layer.contentsAreFlipped()
            let hasSublayers = !(layer.sublayers?.isEmpty ?? true)
            // A layer that paints nothing but its background colour needs no
            // image of its own: the inspector fills a node that has no image
            // with the node's background colour, which is the same picture
            // for a fraction of the memory and import time. Its subtree
            // still needs the group image.
            let paintsOnlyItsBackground = representsPlainColorFill(layer)
            if !paintsOnlyItsBackground || hasSublayers,
               let region = drawingRegion(of: layer, hiding: []),
               let groupImage = renderingPNG(
                   of: layer, includingSublayers: true, region: region.rect, isFlipped: isFlipped
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
                   of: layer, includingSublayers: true, hiding: hostedDescendants, region: region.rect, isFlipped: isFlipped
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
            if let soloImage = renderingPNG(of: layer, includingSublayers: false, isFlipped: isFlipped) {
                soloByObjectIdentifier[objectIdentifier] = soloImage
            }
        }

        return XcodeViewHierarchyScreenshots(
            soloByObjectIdentifier: soloByObjectIdentifier,
            groupByObjectIdentifier: groupByObjectIdentifier,
            groupExcludingHostedViewsByObjectIdentifier: groupExcludingHostedViewsByObjectIdentifier,
            groupRegionByObjectIdentifier: groupRegionByObjectIdentifier,
            groupExcludingHostedViewsRegionByObjectIdentifier: groupExcludingHostedViewsRegionByObjectIdentifier,
            failedArchiveIdentifiers: failedIdentifiers
        )
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
    static func drawingRegion(of layer: CALayer, hiding hiddenLayers: [CALayer]) -> DrawingRegion? {
        let bounds = layer.bounds
        let hidden = Set(hiddenLayers.map(ObjectIdentifier.init))
        let union = drawingUnion(of: layer, in: layer, clip: bounds, hiddenLayers: hidden)
        guard !union.isNull else { return nil }
        let rect = union.intersection(bounds).integral
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

    /// The layers of `root`'s subtree that are composited through a vibrant
    /// filter with nothing drawn behind them inside the subtree.
    ///
    /// Text and icons on a sidebar or a toolbar blend through such a filter
    /// (`vibrantColorMatrixSourceOver`) with the material behind them. A
    /// subtree drawn on its own leaves that material out whenever an
    /// ancestor draws it, and the content vanishes with it, so for that
    /// render such a layer is drawn plain. What counts as behind a layer is
    /// the material (`providesMaterial`) drawn before it in painter's order —
    /// ancestors included — where it overlaps the layer. Hidden layers count
    /// for nothing.
    ///
    /// Vibrant `filters`, as opposed to compositing filters, are left alone:
    /// the layers carrying them are the insides of Liquid Glass, whose white
    /// shape sources would come back as white lozenges.
    static func vibrantLayersWithNothingBehind(in root: CALayer) -> [CALayer] {
        var materialRects: [CGRect] = []
        var layersWithNothingBehind: [CALayer] = []
        func visiting(_ layer: CALayer) {
            guard !layer.isHidden, layer.opacity > 0 else { return }
            let rect = layer.convert(layer.bounds, to: root)
            if isVibrant(layer.compositingFilter), !materialRects.contains(where: { $0.intersects(rect) }) {
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
    }

    /// `hiddenLayers` are hidden for the duration of the render and restored
    /// afterwards; they must be descendants of `layer`. `region`, a rect in
    /// the layer's bounds space, limits the render to that part of the
    /// bounds; the image then covers exactly the region. `isFlipped` is the
    /// layer's cumulative flip in its tree, and the image shows the layer the
    /// way it looks there.
    ///
    /// Not to be called inside an explicit CATransaction: the render commits
    /// its own, which an enclosing one would hold back.
    static func renderingPNG(
        of layer: CALayer,
        includingSublayers: Bool,
        hiding hiddenLayers: [CALayer] = [],
        region: CGRect? = nil,
        isFlipped: Bool
    ) -> Data? {
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
            isFlipped: isFlipped
        )
        let renderedImage = if let renderer = CoreAnimationLayerRenderer.shared {
            renderer.rendering(request)
        } else {
            renderingWithCoreGraphics(request)
        }
        guard let renderedImage else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: renderedImage)
        return bitmap.representation(using: .png, properties: [:])
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
    func rendering(_ request: XcodeViewHierarchyPixelRecovery.RenderRequest) -> CGImage? {
        lock.lock()
        defer { lock.unlock() }
        guard let pixels = renderingPixels(request), Self.containsVisiblePixels(pixels) else { return nil }
        return Self.makingImage(pixels, width: request.pixelWidth, height: request.pixelHeight)
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
            isFlipped: false
        )
        guard let pixels = renderingPixels(request) else { return false }
        // Blue, green, red, alpha.
        return pixels[0] < 16 && pixels[1] < 16 && pixels[2] > 240 && pixels[3] > 240
    }

    /// BGRA, premultiplied, top row first.
    private func renderingPixels(_ request: XcodeViewHierarchyPixelRecovery.RenderRequest) -> [UInt8]? {
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
        // Vibrant content whose material an ancestor draws would vanish with
        // it; for this render it is drawn plain.
        let plainVibrantLayers = XcodeViewHierarchyPixelRecovery.vibrantLayersWithNothingBehind(in: layer)
        let vibrantFilters = plainVibrantLayers.map(\.compositingFilter)
        for vibrantLayer in plainVibrantLayers {
            vibrantLayer.compositingFilter = nil
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
        layer.transform = originalTransform
        layer.anchorPoint = originalAnchorPoint
        layer.position = originalPosition
        if let detachedSublayers {
            layer.sublayers = detachedSublayers
        }
        for hiddenLayer in request.hiddenLayers {
            hiddenLayer.isHidden = false
        }
        for (vibrantLayer, vibrantFilter) in zip(plainVibrantLayers, vibrantFilters) {
            vibrantLayer.compositingFilter = vibrantFilter
        }
        if let originalSuperlayer, let originalIndex {
            originalSuperlayer.insertSublayer(layer, at: UInt32(originalIndex))
        }
        CATransaction.commit()
        CATransaction.flush()

        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        pixels.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
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
        }
        return pixels
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
