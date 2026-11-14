//
//  LayerArchiveSessionTests.swift
//  LookInsideAppTests
//
//  A live macOS session whose Server encodes layer trees
//  (LookinRequestTypeLayerArchive, 211): after a reload the window's archive
//  is fetched, and the node images come from it, while the Server is asked
//  only for the window's own screenshot and the attributes. A Server that
//  does not encode layer trees, and a window over the layer limit, keep the
//  Server's screenshots.
//

import AppKit
import Foundation
@testable import LookInside
import LookInsideHostCore
import Testing

extension HostAppTests {
    @MainActor
    struct LayerArchiveSessionTests {
        /// A window held off screen: a content view with a red and a blue
        /// subview, the hierarchy a Server would build for it, and the oids
        /// that hierarchy gives the views' layers.
        private struct InspectedWindow {
            let window: NSWindow
            let redView: NSView
            let hierarchy: HierarchyInfo
            let windowItem: DisplayItem
            let contentItem: DisplayItem
            let redItem: DisplayItem
            let blueItem: DisplayItem
            let oidsByLayer: [ObjectIdentifier: UInt]

            static let windowOid: UInt = 1000
            /// The oids of the three views, which the Server's screenshot
            /// tasks for them carry on macOS.
            static let viewOids: Set<UInt> = [10, 20, 30]
        }

        private static func makeInspectedWindow(encodesLayerTrees: Bool) -> InspectedWindow {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
            contentView.wantsLayer = true
            let redView = NSView(frame: NSRect(x: 20, y: 20, width: 100, height: 100))
            redView.wantsLayer = true
            redView.layer?.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
            let blueView = NSView(frame: NSRect(x: 160, y: 20, width: 100, height: 100))
            blueView.wantsLayer = true
            blueView.layer?.backgroundColor = CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
            contentView.addSubview(redView)
            contentView.addSubview(blueView)
            window.contentView = contentView
            window.displayIfNeeded()
            CATransaction.flush()

            func viewItem(_ view: NSView, viewOid: UInt, layerOid: UInt, subitems: [DisplayItem] = []) -> DisplayItem {
                let viewObject = InspectedObject()
                viewObject.oid = viewOid
                viewObject.classChainList = ["NSView", "NSResponder", "NSObject"]
                let layerObject = InspectedObject()
                layerObject.oid = layerOid
                layerObject.classChainList = ["_NSViewBackingLayer", "NSViewBackingLayer", "CALayer", "NSObject"]
                let item = DisplayItem()
                item.nodeKind = .view
                item.viewObject = viewObject
                item.layerObject = layerObject
                item.frame = view.frame
                item.bounds = view.bounds
                item.shouldCaptureImage = true
                item.subitems = subitems
                return item
            }
            let redItem = viewItem(redView, viewOid: 20, layerOid: 21)
            let blueItem = viewItem(blueView, viewOid: 30, layerOid: 31)
            let contentItem = viewItem(contentView, viewOid: 10, layerOid: 11, subitems: [redItem, blueItem])
            let windowObject = InspectedObject()
            windowObject.oid = InspectedWindow.windowOid
            windowObject.classChainList = ["NSWindow", "NSResponder", "NSObject"]
            let windowItem = DisplayItem()
            windowItem.nodeKind = .window
            windowItem.windowObject = windowObject
            windowItem.frame = CGRect(origin: .zero, size: window.frame.size)
            windowItem.bounds = windowItem.frame
            windowItem.shouldCaptureImage = true
            windowItem.subitems = [contentItem]

            let appInfo = InspectedAppInfo()
            appInfo.appName = "FakeApp"
            appInfo.deviceType = .mac
            appInfo.osDescription = "macOS"
            appInfo.screenScale = 2
            appInfo.serverVersion = Int32(LOOKIN_SERVER_VERSION)
            appInfo.hierarchyAcquisitionProtocolVersion = HierarchyAcquisitionSupport.requiredProtocolVersion
            appInfo.layerArchiveProtocolVersion = encodesLayerTrees ? 1 : 0
            let hierarchy = HierarchyInfo()
            hierarchy.appInfo = appInfo
            hierarchy.displayItems = [windowItem]

            var oidsByLayer: [ObjectIdentifier: UInt] = [:]
            for (view, oid) in [(contentView, UInt(11)), (redView, 21), (blueView, 31)] {
                if let layer = view.layer {
                    oidsByLayer[ObjectIdentifier(layer)] = oid
                }
            }
            return InspectedWindow(
                window: window,
                redView: redView,
                hierarchy: hierarchy,
                windowItem: windowItem,
                contentItem: contentItem,
                redItem: redItem,
                blueItem: blueItem,
                oidsByLayer: oidsByLayer
            )
        }

        /// What a macOS Server answers for the window: its whole layer tree
        /// encoded by QuartzCore, with every layer's oid and sublayer count
        /// depth first; over `layerLimit` layers, the count alone.
        private static func layerArchive(of inspected: InspectedWindow, layerLimit: UInt) -> LayerArchive {
            var root = inspected.window.contentView?.superview?.layer ?? CALayer()
            while let superlayer = root.superlayer {
                root = superlayer
            }
            var layers: [CALayer] = []
            var pending = [root]
            while let layer = pending.popLast() {
                layers.append(layer)
                pending.append(contentsOf: (layer.sublayers ?? []).reversed())
            }
            let reply = LayerArchive()
            reply.layerCount = UInt(layers.count)
            guard UInt(layers.count) <= layerLimit else { return reply }
            reply.layerOids = layers.map { inspected.oidsByLayer[ObjectIdentifier($0)] ?? 0 }
            reply.sublayerCounts = layers.map { UInt32($0.sublayers?.count ?? 0) }
            reply.archiveData = encodingLayerTree(root)
            return reply
        }

        /// `root`'s layer tree as QuartzCore encodes it for a macOS Server.
        private static func encodingLayerTree(_ root: CALayer) -> Data? {
            typealias EncodeLayerTreeFunction = @convention(c) (CALayer) -> Unmanaged<NSData>?
            guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CAEncodeLayerTree") else { return nil }
            let encode = unsafeBitCast(symbol, to: EncodeLayerTreeFunction.self)
            return encode(root)?.takeRetainedValue() as Data?
        }

        /// A window whose nodes are its layers, one for every layer under
        /// `rootLayer`, as a Server lists them: oid 100 plus the layer's
        /// place in the walk, depth first.
        private struct LayerNodes {
            let rootLayer: CALayer
            let layers: [CALayer]
            let oidsByLayer: [ObjectIdentifier: UInt]
            let itemsByOid: [UInt: DisplayItem]
            let hierarchy: HierarchyInfo

            func oid(of layer: CALayer) -> UInt {
                oidsByLayer[ObjectIdentifier(layer)] ?? 0
            }

            func item(for layer: CALayer) -> DisplayItem? {
                itemsByOid[oid(of: layer)]
            }
        }

        /// The nodes of a window of `windowSize` whose layers are
        /// `rootLayer`'s tree, each node with its layer's class — SwiftUI's
        /// glass layers are what the Liquid Glass setting hides —, geometry,
        /// opacity and hidden flag. The layers in `viewClassChains` are the
        /// backing layers of views with those class chains, and their nodes
        /// view nodes, as a Server lists a view.
        private static func layerNodes(
            under rootLayer: CALayer,
            windowSize: CGSize,
            viewClassChains: [ObjectIdentifier: [String]] = [:]
        ) -> LayerNodes {
            var layers: [CALayer] = []
            var pending = [rootLayer]
            while let layer = pending.popLast() {
                layers.append(layer)
                pending.append(contentsOf: (layer.sublayers ?? []).reversed())
            }
            var oidsByLayer: [ObjectIdentifier: UInt] = [:]
            for (index, layer) in layers.enumerated() {
                oidsByLayer[ObjectIdentifier(layer)] = UInt(100 + index)
            }
            var itemsByOid: [UInt: DisplayItem] = [:]
            func item(for layer: CALayer) -> DisplayItem {
                let layerObject = InspectedObject()
                layerObject.oid = oidsByLayer[ObjectIdentifier(layer)] ?? 0
                layerObject.classChainList = [NSStringFromClass(type(of: layer)), "CALayer", "NSObject"]
                let item = DisplayItem()
                item.nodeKind = .layer
                item.layerObject = layerObject
                if let viewClassChain = viewClassChains[ObjectIdentifier(layer)] {
                    let viewObject = InspectedObject()
                    viewObject.oid = layerObject.oid + 10000
                    viewObject.classChainList = viewClassChain
                    item.nodeKind = .view
                    item.viewObject = viewObject
                }
                item.frame = layer.frame
                item.bounds = layer.bounds
                item.alpha = layer.opacity
                item.isHidden = layer.isHidden
                item.shouldCaptureImage = true
                item.subitems = (layer.sublayers ?? []).map(item(for:))
                itemsByOid[layerObject.oid] = item
                return item
            }
            let windowObject = InspectedObject()
            windowObject.oid = InspectedWindow.windowOid
            windowObject.classChainList = ["NSWindow", "NSResponder", "NSObject"]
            let windowItem = DisplayItem()
            windowItem.nodeKind = .window
            windowItem.windowObject = windowObject
            windowItem.frame = CGRect(origin: .zero, size: windowSize)
            windowItem.bounds = windowItem.frame
            windowItem.shouldCaptureImage = true
            windowItem.subitems = [item(for: rootLayer)]
            let appInfo = InspectedAppInfo()
            appInfo.appName = "FakeApp"
            appInfo.deviceType = .mac
            appInfo.osDescription = "macOS"
            appInfo.screenScale = 2
            appInfo.serverVersion = Int32(LOOKIN_SERVER_VERSION)
            appInfo.hierarchyAcquisitionProtocolVersion = HierarchyAcquisitionSupport.requiredProtocolVersion
            appInfo.layerArchiveProtocolVersion = 1
            let hierarchy = HierarchyInfo()
            hierarchy.appInfo = appInfo
            hierarchy.displayItems = [windowItem]
            return LayerNodes(rootLayer: rootLayer, layers: layers, oidsByLayer: oidsByLayer, itemsByOid: itemsByOid, hierarchy: hierarchy)
        }

        /// The topmost layer of `layer`'s tree: a window's whole tree, from
        /// the layer of one of its views.
        private static func rootLayer(above layer: CALayer) -> CALayer {
            var root = layer
            while let superlayer = root.superlayer {
                root = superlayer
            }
            return root
        }

        /// Answers the window's archive request with `nodes`' whole layer
        /// tree.
        private static func answeringLayerArchive(of nodes: LayerNodes, on server: FakeServer) {
            server.responders[UInt32(LookinRequestTypeLayerArchive)] = { _ in
                let reply = LayerArchive()
                reply.layerCount = UInt(nodes.layers.count)
                reply.layerOids = nodes.layers.map(nodes.oid(of:))
                reply.sublayerCounts = nodes.layers.map { UInt32($0.sublayers?.count ?? 0) }
                reply.archiveData = encodingLayerTree(nodes.rootLayer)
                return reply
            }
        }

        /// A detail for every task, without a screenshot: enough for the Host
        /// to count each task answered.
        private static func emptyDetails(for data: Any?) -> Any? {
            let packages = data as? [StaticAsyncUpdateTasksPackage] ?? []
            return packages.flatMap { $0.tasks ?? [] }.map { task in
                let detail = DisplayItemDetail()
                detail.displayItemOid = task.oid
                return detail
            } as NSArray
        }

        /// The oids the Server was asked to screenshot.
        private static func screenshotTaskOids(in server: FakeServer) -> Set<UInt> {
            var oids: Set<UInt> = []
            for request in server.receivedRequests where request.type == UInt32(LookinRequestTypeHierarchyDetails) {
                for package in request.data as? [StaticAsyncUpdateTasksPackage] ?? [] {
                    for task in package.tasks ?? [] where task.taskType != .noScreenshot {
                        oids.insert(task.oid)
                    }
                }
            }
            return oids
        }

        /// The colour at the middle of `image`.
        private static func middleColour(of image: NSImage?) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
            guard let image, let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            guard let colour = bitmap.colorAt(x: cgImage.width / 2, y: cgImage.height / 2)?.usingColorSpace(.sRGB) else { return nil }
            return (colour.redComponent, colour.greenComponent, colour.blueComponent)
        }

        /// What a test holds for the length of a session: the app and the
        /// update manager hold their channel and data source weakly.
        private struct Session {
            let channel: ServerChannel
            let app: InspectableApp
            let dataSource: StaticHierarchyDataSource
            let manager: StaticAsyncUpdateManager
        }

        /// Connects a document's update manager to `server` and loads the
        /// window's hierarchy; returns once every window's archive settled.
        /// The manager is built the way a live window builds it: without an
        /// app, which the window sets before it loads a hierarchy.
        private static func loadingSession(_ inspected: InspectedWindow, on server: FakeServer) async -> Session {
            await loadingSession(inspected.hierarchy, on: server)
        }

        /// Loads `hierarchy` into `dataSource` — one with a settings set of
        /// its own, or one a test watches from before the load — as
        /// `loadingSession(_:on:)` loads a window's.
        private static func loadingSession(
            _ hierarchy: HierarchyInfo,
            on server: FakeServer,
            into dataSource: StaticHierarchyDataSource = StaticHierarchyDataSource()
        ) async -> Session {
            server.responders[UInt32(LookinRequestTypeHierarchyDetails)] = { emptyDetails(for: $0) }
            let channel = server.connectChannel()
            let app = InspectableApp()
            app.appInfo = hierarchy.appInfo
            app.channel = channel
            let manager = StaticAsyncUpdateManager(hierarchyDataSource: dataSource, inspectableApp: nil)
            manager.inspectableApp = app
            dataSource.reload(with: hierarchy, keepState: false)
            _ = await waitUntil { !manager.layerArchiveStore.hasPendingArchives }
            return Session(channel: channel, app: app, dataSource: dataSource, manager: manager)
        }

        private static func fetchingWholeTree(_ manager: StaticAsyncUpdateManager) async -> Bool {
            var isFinished = false
            manager.fetchWholeTree { isFinished = true }
            return await waitUntil(timeout: .seconds(20)) { isFinished }
        }

        /// An `NSGlassEffectView` lists its content before the view that
        /// draws its glass, and draws the content over the glass through
        /// portals that hide it in place; the preview ordered the planes by
        /// the hierarchy, and the expanded glass hid its content. Once the
        /// window's archive arrives, each node a portal draws that way knows
        /// the portal's node, and the preview hears that its order changed.
        @Test func glassContentIsOrderedWhereItsPortalDrawsIt() async {
            guard #available(macOS 26.0, *) else { return }
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            defer { window.close() }
            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            contentView.wantsLayer = true
            let glassView = NSGlassEffectView(frame: NSRect(x: 20, y: 30, width: 200, height: 40))
            glassView.contentView = NSTextField(labelWithString: "Filter")
            contentView.addSubview(glassView)
            window.contentView = contentView
            window.displayIfNeeded()
            CATransaction.flush()
            guard let contentLayer = contentView.layer else {
                Issue.record("the content view should have a layer")
                return
            }
            let nodes = Self.layerNodes(under: Self.rootLayer(above: contentLayer), windowSize: window.frame.size)

            let server = FakeServer()
            defer { server.shutDown() }
            Self.answeringLayerArchive(of: nodes, on: server)
            let dataSource = StaticHierarchyDataSource()
            var orderChanges = 0
            let subscription = dataSource.previewOrderDidChange.observe { _ in orderChanges += 1 }
            let session = await Self.loadingSession(nodes.hierarchy, on: server, into: dataSource)
            #expect(!session.manager.layerArchiveStore.hasPendingArchives)

            // A layer two portals draw goes with the later one, drawn on top.
            var lastPortalBySource: [ObjectIdentifier: (source: CALayer, portal: CALayer)] = [:]
            for pair in XcodeViewHierarchyPixelRecovery.portalsHidingTheirSources(in: nodes.layers) {
                lastPortalBySource[ObjectIdentifier(pair.source)] = pair
            }
            #expect(!lastPortalBySource.isEmpty, "the glass should draw its content through a portal that hides it in place")
            for (source, portal) in lastPortalBySource.values {
                let sourceItem = nodes.item(for: source)
                let portalItem = nodes.item(for: portal)
                let linked = sourceItem?.previewPortalItem?.layerObject?.oid
                #expect(
                    portalItem != nil && sourceItem?.previewPortalItem === portalItem,
                    "\(NSStringFromClass(type(of: source))) #\(nodes.oid(of: source)), drawn by \(NSStringFromClass(type(of: portal))) #\(nodes.oid(of: portal)), should know the portal's node; linked to \(String(describing: linked))"
                )
            }
            #expect(orderChanges > 0, "the preview should hear that its order changed")
            withExtendedLifetime((session, subscription)) {}
        }

        /// With the Liquid Glass setting on Hide, AppKit's glass stayed in
        /// every image drawn from the archive that holds it: hiding the glass
        /// layer nodes took only their own planes away. Those images now
        /// leave out the glass Hide is for, the glass AppKit puts behind a
        /// split view item, which covered the sidebar's content — the content
        /// still showing where it is. A control's glass, a filter field's
        /// capsule, stays as on screen. Changing the setting draws the images
        /// again.
        @Test func hideLeavesOutTheSplitViewGlassButNotAControlsGlass() async {
            guard #available(macOS 26.0, *) else { return }
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            window.appearance = NSAppearance(named: .darkAqua)
            defer { window.close() }
            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
            contentView.wantsLayer = true
            // Stands for the wrapper a split view puts around an item.
            let wrapperView = NSView(frame: NSRect(x: 0, y: 100, width: 300, height: 100))
            wrapperView.wantsLayer = true
            let sidebarGlassView = NSGlassEffectView(frame: NSRect(x: 20, y: 30, width: 200, height: 40))
            sidebarGlassView.contentView = NSTextField(labelWithString: "Filter")
            wrapperView.addSubview(sidebarGlassView)
            let controlGlassView = NSGlassEffectView(frame: NSRect(x: 20, y: 30, width: 200, height: 40))
            controlGlassView.contentView = NSTextField(labelWithString: "Search")
            contentView.addSubview(wrapperView)
            contentView.addSubview(controlGlassView)
            window.contentView = contentView
            window.displayIfNeeded()
            CATransaction.flush()

            guard let contentLayer = contentView.layer, let wrapperLayer = wrapperView.layer,
                  let sidebarGlassLayer = sidebarGlassView.layer, let controlGlassLayer = controlGlassView.layer
            else {
                Issue.record("the views should have layers")
                return
            }
            let glassViewClassChain = ["NSGlassEffectView", "NSView", "NSResponder", "NSObject"]
            let nodes = Self.layerNodes(
                under: Self.rootLayer(above: contentLayer),
                windowSize: window.frame.size,
                viewClassChains: [
                    ObjectIdentifier(wrapperLayer): ["_NSSplitViewItemViewWrapper", "NSView", "NSResponder", "NSObject"],
                    ObjectIdentifier(sidebarGlassLayer): glassViewClassChain,
                    ObjectIdentifier(controlGlassLayer): glassViewClassChain,
                ]
            )

            let server = FakeServer()
            defer { server.shutDown() }
            Self.answeringLayerArchive(of: nodes, on: server)
            // A settings set of the test's own: the app's must not change.
            let preferences = PreferenceManager()
            preferences.glassLayerVisibility = .hide
            let session = await Self.loadingSession(
                nodes.hierarchy,
                on: server,
                into: StaticHierarchyDataSource(preferenceManager: preferences)
            )
            #expect(!session.manager.layerArchiveStore.hasPendingArchives)
            let manager = session.manager
            guard let sidebarGlassItem = nodes.item(for: sidebarGlassLayer), let controlGlassItem = nodes.item(for: controlGlassLayer) else {
                Issue.record("the glass views should have nodes")
                return
            }

            guard case let .image(sidebarWithGlassHidden)? = await manager.layerArchiveImage(.group, of: sidebarGlassItem) else {
                Issue.record("the sidebar's glass view should have a group image with its glass hidden")
                return
            }
            let hiddenCoverage = Self.coverage(of: sidebarWithGlassHidden)
            #expect(hiddenCoverage.opaque < 0.3, "with the glass hidden only the label should be opaque, got \(hiddenCoverage.opaque)")
            #expect(hiddenCoverage.visible > 0.005, "the label should still show with the glass hidden, got \(hiddenCoverage.visible)")
            guard case let .image(controlImage)? = await manager.layerArchiveImage(.group, of: controlGlassItem) else {
                Issue.record("the control's glass view should have a group image")
                return
            }
            let controlCoverage = Self.coverage(of: controlImage)
            #expect(controlCoverage.opaque > 0.6, "a control's glass should stay with Hide, got \(controlCoverage.opaque)")

            preferences.glassLayerVisibility = .show
            guard case let .image(sidebarWithGlassShown)? = await manager.layerArchiveImage(.group, of: sidebarGlassItem) else {
                Issue.record("the sidebar's glass view should have a group image with its glass shown")
                return
            }
            let shownCoverage = Self.coverage(of: sidebarWithGlassShown)
            #expect(shownCoverage.opaque > 0.6, "with the glass shown the glass should cover the view, got \(shownCoverage.opaque)")
            withExtendedLifetime(session) {}
        }

        /// The share of `image`'s pixels that are opaque and that show at all.
        private static func coverage(of image: NSImage) -> (opaque: Double, visible: Double) {
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return (0, 0) }
            let width = cgImage.width
            let height = cgImage.height
            var pixels = [UInt8](repeating: 0, count: width * height * 4)
            pixels.withUnsafeMutableBytes { buffer in
                guard let context = CGContext(
                    data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ) else { return }
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            var opaque = 0
            var visible = 0
            for index in stride(from: 3, to: pixels.count, by: 4) {
                if pixels[index] > 200 { opaque += 1 }
                if pixels[index] > 16 { visible += 1 }
            }
            let count = Double(width * height)
            return (Double(opaque) / count, Double(visible) / count)
        }

        /// RuntimeViewer's sidebar, cut down: a clip view's layer 1007 points
        /// tall holding the outline's, 364.5 × 107829 points with every group
        /// expanded, with one row drawn. The hierarchy has the outline as
        /// tall as the clip view, as when the Server listed the tree before
        /// the outline grew.
        private static func makeSidebar() -> (nodes: LayerNodes, outlineItem: DisplayItem)? {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let root = CALayer()
            root.frame = CGRect(x: 0, y: 0, width: 400, height: 1007)
            let clip = CALayer()
            clip.frame = CGRect(x: 0, y: 0, width: 364.5, height: 1007)
            clip.masksToBounds = true
            let outline = CALayer()
            outline.frame = CGRect(x: 0, y: 0, width: 364.5, height: 107_829)
            outline.backgroundColor = CGColor(gray: 1, alpha: 1)
            outline.contentsScale = 2
            let row = CALayer()
            row.frame = CGRect(x: 10, y: 50, width: 200, height: 20)
            row.backgroundColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
            row.contentsScale = 2
            outline.addSublayer(row)
            clip.addSublayer(outline)
            root.addSublayer(clip)
            CATransaction.commit()
            let nodes = layerNodes(under: root, windowSize: root.bounds.size)
            guard let outlineItem = nodes.item(for: outline) else { return nil }
            outlineItem.frame = clip.bounds
            outlineItem.bounds = clip.bounds
            return (nodes, outlineItem)
        }

        /// A detail that gives RuntimeViewer's outline `height`.
        private static func outlineDetail(of outlineItem: DisplayItem, height: CGFloat) -> DisplayItemDetail {
            let detail = DisplayItemDetail()
            detail.displayItemOid = outlineItem.layerObject?.oid ?? 0
            detail.frameValue = NSValue(rect: CGRect(x: 0, y: 0, width: 364.5, height: height))
            detail.boundsValue = NSValue(rect: CGRect(x: 0, y: 0, width: 364.5, height: height))
            return detail
        }

        /// RuntimeViewer's sidebar outline grew to 364.5 × 107829 points.
        /// Its image from the archive is shrunk to fit
        /// `LookinNodeImageMaxLengthInPx`, but was wrapped as though it held
        /// the full size at the screen's scale, and the preview's check that
        /// no image is longer than that stopped the Host. The image holds the
        /// pixels it has, at the layer's size in points.
        @Test func imageOfALayerTallerThanTheLimitHoldsThePixelsItHas() async {
            guard let sidebar = Self.makeSidebar() else {
                Issue.record("the outline should have a node")
                return
            }
            let server = FakeServer()
            defer { server.shutDown() }
            Self.answeringLayerArchive(of: sidebar.nodes, on: server)
            let session = await Self.loadingSession(sidebar.nodes.hierarchy, on: server)
            guard case let .image(image)? = await session.manager.layerArchiveImage(.group, of: sidebar.outlineItem) else {
                Issue.record("the outline should have a group image")
                return
            }
            #expect(sidebar.outlineItem.groupScreenshot === image, "the outline fit when the hierarchy listed it: the preview shows the image")
            let representation = image.representations.first
            let longestSide = max(representation?.pixelsWide ?? 0, representation?.pixelsHigh ?? 0)
            #expect(
                longestSide > 0 && Double(longestSide) <= LookinNodeImageMaxLengthInPx,
                "the image should be no longer than the preview takes, got \(representation?.pixelsWide ?? 0) × \(representation?.pixelsHigh ?? 0) pixels"
            )
            #expect(image.size == CGSize(width: 364.5, height: 107_829), "the image should keep the layer's size in points, got \(image.size)")
            withExtendedLifetime(session) {}
        }

        /// A detail that grows a node past `LookinNodeImageMaxLengthInPx`
        /// takes its images away — they showed it at its old size — and, as
        /// after a reload, the preview takes none of it: an image drawn from
        /// the archive for another caller stays off the node. A detail that
        /// shrinks it to fit gives it its images back.
        @Test func nodeThatGrowsPastTheLimitHoldsNoImageUntilItFitsAgain() async {
            guard let sidebar = Self.makeSidebar() else {
                Issue.record("the outline should have a node")
                return
            }
            let outlineItem = sidebar.outlineItem
            let server = FakeServer()
            defer { server.shutDown() }
            Self.answeringLayerArchive(of: sidebar.nodes, on: server)
            let session = await Self.loadingSession(sidebar.nodes.hierarchy, on: server)
            _ = await session.manager.layerArchiveImage(.group, of: outlineItem)
            #expect(outlineItem.groupScreenshot != nil, "the outline fit when the hierarchy listed it")

            session.dataSource.modify(with: Self.outlineDetail(of: outlineItem, height: 107_829))
            #expect(outlineItem.doNotFetchScreenshotReason == .doNotFetchScreenshotForTooLarge)
            #expect(outlineItem.groupScreenshot == nil, "the image showed the outline at its old size")
            guard case .image? = await session.manager.layerArchiveImage(.group, of: outlineItem) else {
                Issue.record("another caller should still get an image of the outline")
                return
            }
            #expect(outlineItem.groupScreenshot == nil, "the preview takes no image of a node too large for one")

            session.dataSource.modify(with: Self.outlineDetail(of: outlineItem, height: 1007))
            #expect(outlineItem.doNotFetchScreenshotReason == .fetchScreenshotPermitted)
            guard case let .image(image)? = await session.manager.layerArchiveImage(.group, of: outlineItem) else {
                Issue.record("the outline should have a group image again")
                return
            }
            #expect(outlineItem.groupScreenshot === image, "the outline fits again: the preview shows its image")
            withExtendedLifetime(session) {}
        }

        @Test func imagesComeFromTheWindowsLayerArchive() async {
            let inspected = Self.makeInspectedWindow(encodesLayerTrees: true)
            defer { inspected.window.close() }
            let server = FakeServer()
            defer { server.shutDown() }
            var archiveRequest: NSDictionary?
            server.responders[UInt32(LookinRequestTypeLayerArchive)] = { data in
                archiveRequest = data as? NSDictionary
                return Self.layerArchive(of: inspected, layerLimit: 4000)
            }

            let session = await Self.loadingSession(inspected, on: server)
            #expect((archiveRequest?[LookinParam_LayerArchiveWindowOid] as? NSNumber)?.uintValue == InspectedWindow.windowOid)
            #expect((archiveRequest?[LookinParam_LayerArchiveLayerLimit] as? NSNumber)?.uintValue == LiveLayerArchive.layerLimit)
            #expect(session.manager.layerArchiveStore.isActive)

            #expect(await Self.fetchingWholeTree(session.manager), "the whole tree should be fetched")
            let red = Self.middleColour(of: inspected.redItem.groupScreenshot)
            let blue = Self.middleColour(of: inspected.blueItem.groupScreenshot)
            #expect(red.map { $0.red > 0.8 && $0.green < 0.2 && $0.blue < 0.2 } == true, "the red view's image should be drawn from the archive, got \(String(describing: red))")
            #expect(blue.map { $0.blue > 0.8 && $0.red < 0.2 && $0.green < 0.2 } == true, "the blue view's image should be drawn from the archive, got \(String(describing: blue))")
            #expect(inspected.contentItem.groupScreenshot != nil, "the content view's image should be drawn from the archive")
            #expect(
                Self.screenshotTaskOids(in: server) == [InspectedWindow.windowOid],
                "only the window's own screenshot should be asked of the Server, asked for \(Self.screenshotTaskOids(in: server))"
            )
            withExtendedLifetime(session) {}
        }

        private static func isRed(_ colour: (red: CGFloat, green: CGFloat, blue: CGFloat)?) -> Bool {
            colour.map { $0.red > 0.8 && $0.green < 0.2 && $0.blue < 0.2 } == true
        }

        private static func isGreen(_ colour: (red: CGFloat, green: CGFloat, blue: CGFloat)?) -> Bool {
            colour.map { $0.green > 0.8 && $0.red < 0.2 && $0.blue < 0.2 } == true
        }

        private static func isBlue(_ colour: (red: CGFloat, green: CGFloat, blue: CGFloat)?) -> Bool {
            colour.map { $0.blue > 0.8 && $0.red < 0.2 && $0.green < 0.2 } == true
        }

        @Test func editFetchesTheArchiveAgainAndRedrawsWhatIsShown() async {
            let inspected = Self.makeInspectedWindow(encodesLayerTrees: true)
            defer { inspected.window.close() }
            let server = FakeServer()
            defer { server.shutDown() }
            server.responders[UInt32(LookinRequestTypeLayerArchive)] = { _ in
                Self.layerArchive(of: inspected, layerLimit: 4000)
            }
            let session = await Self.loadingSession(inspected, on: server)
            // On screen: the window and the content view expanded, the red
            // view shown with its group image.
            inspected.windowItem.isExpanded = true
            inspected.contentItem.isExpanded = true
            session.dataSource.buildDisplayingFlatItems()
            #expect(await Self.fetchingWholeTree(session.manager), "the whole tree should be fetched")
            #expect(Self.isRed(Self.middleColour(of: inspected.redItem.groupScreenshot)), "the red view should start red")

            // What the edit did in the app.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            inspected.redView.layer?.backgroundColor = CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1)
            CATransaction.commit()
            CATransaction.flush()
            let progress = StreamCollector(session.manager.modifyingUpdates.subscribe())
            defer { progress.stop() }
            session.manager.updateAfterModifyingDisplayItem(inspected.redItem)

            #expect(
                await waitUntil(timeout: .seconds(10)) { Self.isGreen(Self.middleColour(of: inspected.redItem.groupScreenshot)) },
                "the red view's image on screen should be drawn again from the new archive"
            )
            #expect(server.receivedRequestTypes.filter { $0 == UInt32(LookinRequestTypeLayerArchive) }.count == 2, "the edit should fetch the window's archive again")
            var patchedOids = Set<UInt>()
            for request in server.receivedRequests where request.type == UInt32(LookinRequestTypeAttrModificationPatch) {
                for task in request.data as? [StaticAsyncUpdateTask] ?? [] {
                    patchedOids.insert(task.oid)
                }
            }
            #expect(patchedOids == [InspectedWindow.windowOid], "only the window's own screenshot should be patched by the Server, patched \(patchedOids)")
            #expect(
                await waitUntil {
                    guard case let .progress(received, total)? = progress.elements.last else { return false }
                    return total > 0 && received >= total
                },
                "the progress should reach its end, got \(progress.elements)"
            )
            withExtendedLifetime(session) {}
        }

        @Test func imageForAnotherCallerIsDrawnFromTheArchive() async {
            let inspected = Self.makeInspectedWindow(encodesLayerTrees: true)
            defer { inspected.window.close() }
            let server = FakeServer()
            defer { server.shutDown() }
            server.responders[UInt32(LookinRequestTypeLayerArchive)] = { _ in
                Self.layerArchive(of: inspected, layerLimit: 4000)
            }
            let session = await Self.loadingSession(inspected, on: server)

            guard case let .image(image)? = await session.manager.layerArchiveImage(.group, of: inspected.blueItem) else {
                Issue.record("the blue view's image should come from the archive")
                return
            }
            #expect(Self.isBlue(Self.middleColour(of: image)))
            #expect(inspected.blueItem.groupScreenshot === image, "the image should also be put on the node")
            #expect(await session.manager.layerArchiveImage(.group, of: inspected.windowItem) == nil, "the window's own image is the Server's")
            withExtendedLifetime(session) {}
        }

        /// The MCP bridge asks for a node's image and waits for its drawing.
        /// A drawing still waiting when the app changed — redrawing from the
        /// new archive drops the images off screen — or when a refresh
        /// replaced the tree was dropped with whoever waited on it, and the
        /// bridge's request never came back. Whoever asked now hears that it
        /// was dropped, and the bridge asks again.
        @Test func aDroppedDrawingTellsWhoeverAskedForIt() async {
            let inspected = Self.makeInspectedWindow(encodesLayerTrees: true)
            defer { inspected.window.close() }
            let server = FakeServer()
            defer { server.shutDown() }
            server.responders[UInt32(LookinRequestTypeLayerArchive)] = { _ in
                Self.layerArchive(of: inspected, layerLimit: 4000)
            }
            let session = await Self.loadingSession(inspected, on: server)
            let store = session.manager.layerArchiveStore
            guard case let .archive(redArchive, redNodes) = store.imageSource(.group, of: inspected.redItem),
                  case let .archive(blueArchive, blueNodes) = store.imageSource(.group, of: inspected.blueItem)
            else {
                Issue.record("both views should be drawn from the archive")
                return
            }
            var heard: [String] = []
            func asking(for name: String) -> @MainActor (LiveLayerArchiveStore.DrawingOutcome) -> Void {
                { outcome in
                    if case .dropped = outcome {
                        heard.append("\(name) dropped")
                    } else {
                        heard.append("\(name) drawn")
                    }
                }
            }
            // In one turn: the red view's drawing goes first, the blue one's
            // waits behind it.
            store.drawImage(.group, of: inspected.redItem, archive: redArchive, nodes: redNodes, priority: .shown, again: true, completion: asking(for: "red"))
            store.drawImage(.group, of: inspected.blueItem, archive: blueArchive, nodes: blueNodes, priority: .shown, again: true, completion: asking(for: "blue"))
            store.forgetImage(.group, of: inspected.blueItem)
            #expect(await waitUntil { heard.contains("blue dropped") && heard.contains("red drawn") }, "heard \(heard)")

            heard.removeAll()
            store.drawImage(.group, of: inspected.redItem, archive: redArchive, nodes: redNodes, priority: .shown, again: true, completion: asking(for: "red"))
            store.drawImage(.group, of: inspected.blueItem, archive: blueArchive, nodes: blueNodes, priority: .shown, again: true, completion: asking(for: "blue"))
            session.dataSource.reload(with: inspected.hierarchy, keepState: false)
            #expect(
                await waitUntil { heard.contains("blue dropped") && heard.contains("red dropped") },
                "a refresh should drop both, the one drawing and the one waiting, heard \(heard)"
            )
            withExtendedLifetime(session) {}
        }

        @Test func imageForAnotherCallerWaitsForTheArchive() async {
            let inspected = Self.makeInspectedWindow(encodesLayerTrees: true)
            defer { inspected.window.close() }
            let server = FakeServer()
            defer { server.shutDown() }
            server.heldRequestTypes = [UInt32(LookinRequestTypeLayerArchive)]
            server.responders[UInt32(LookinRequestTypeHierarchyDetails)] = { Self.emptyDetails(for: $0) }
            let channel = server.connectChannel()
            let app = InspectableApp()
            app.appInfo = inspected.hierarchy.appInfo
            app.channel = channel
            let dataSource = StaticHierarchyDataSource()
            let manager = StaticAsyncUpdateManager(hierarchyDataSource: dataSource, inspectableApp: nil)
            manager.inspectableApp = app
            dataSource.reload(with: inspected.hierarchy, keepState: false)
            #expect(await waitUntil { server.receivedRequestTypes.contains(UInt32(LookinRequestTypeLayerArchive)) })
            #expect(manager.layerArchiveStore.hasPendingArchives)

            var result: StaticAsyncUpdateManager.LayerArchiveImage?
            var hasResult = false
            Task { @MainActor in
                result = await manager.layerArchiveImage(.group, of: inspected.redItem)
                hasResult = true
            }
            try? await Task.sleep(for: .milliseconds(200))
            #expect(!hasResult, "the image should wait for the archive")
            let attachment = ConnectionResponseAttachment()
            attachment.lookinServerVersion = Int32(LOOKIN_SERVER_VERSION)
            attachment.data = Self.layerArchive(of: inspected, layerLimit: 4000)
            server.answerHeldRequests(with: attachment)
            #expect(await waitUntil(timeout: .seconds(10)) { hasResult })
            if case let .image(image)? = result {
                #expect(Self.isRed(Self.middleColour(of: image)))
            } else {
                Issue.record("the red view's image should come from the archive once it arrives, got \(String(describing: result))")
            }
            withExtendedLifetime((channel, app, dataSource, manager)) {}
        }

        @Test func serverThatDoesNotEncodeLayerTreesKeepsTakingTheScreenshots() async {
            let inspected = Self.makeInspectedWindow(encodesLayerTrees: false)
            defer { inspected.window.close() }
            let server = FakeServer()
            defer { server.shutDown() }

            let session = await Self.loadingSession(inspected, on: server)
            #expect(!session.manager.layerArchiveStore.isActive)
            #expect(await Self.fetchingWholeTree(session.manager), "the whole tree should be fetched")
            #expect(!server.receivedRequestTypes.contains(UInt32(LookinRequestTypeLayerArchive)), "an older Server must not be sent the request")
            #expect(Self.screenshotTaskOids(in: server).isSuperset(of: InspectedWindow.viewOids), "the views' screenshots should be asked of the Server")
            withExtendedLifetime(session) {}
        }

        @Test func windowOverTheLimitKeepsTheServersScreenshots() async {
            let inspected = Self.makeInspectedWindow(encodesLayerTrees: true)
            defer { inspected.window.close() }
            let server = FakeServer()
            defer { server.shutDown() }
            server.responders[UInt32(LookinRequestTypeLayerArchive)] = { _ in
                Self.layerArchive(of: inspected, layerLimit: 2)
            }

            let session = await Self.loadingSession(inspected, on: server)
            #expect(await Self.fetchingWholeTree(session.manager), "the whole tree should be fetched")
            #expect(Self.screenshotTaskOids(in: server).isSuperset(of: InspectedWindow.viewOids), "a window the Server did not encode keeps its screenshots")
            #expect(inspected.redItem.groupScreenshot == nil, "nothing should be drawn from an archive that is not there")
            withExtendedLifetime(session) {}
        }
    }
}
