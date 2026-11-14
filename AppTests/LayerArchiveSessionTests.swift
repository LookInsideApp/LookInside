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
            typealias EncodeLayerTreeFunction = @convention(c) (CALayer) -> Unmanaged<NSData>?
            if let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CAEncodeLayerTree") {
                let encode = unsafeBitCast(symbol, to: EncodeLayerTreeFunction.self)
                reply.archiveData = encode(root)?.takeRetainedValue() as Data?
            }
            return reply
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
            server.responders[UInt32(LookinRequestTypeHierarchyDetails)] = { emptyDetails(for: $0) }
            let channel = server.connectChannel()
            let app = InspectableApp()
            app.appInfo = inspected.hierarchy.appInfo
            app.channel = channel
            let dataSource = StaticHierarchyDataSource()
            let manager = StaticAsyncUpdateManager(hierarchyDataSource: dataSource, inspectableApp: nil)
            manager.inspectableApp = app
            dataSource.reload(with: inspected.hierarchy, keepState: false)
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

            // A node for every layer, as a Server lists them: oid 100 plus the
            // layer's place in the walk.
            guard var root = contentView.layer else {
                Issue.record("the content view should have a layer")
                return
            }
            while let superlayer = root.superlayer {
                root = superlayer
            }
            var layers: [CALayer] = []
            var pending = [root]
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
                layerObject.classChainList = ["CALayer", "NSObject"]
                let item = DisplayItem()
                item.nodeKind = .layer
                item.layerObject = layerObject
                item.frame = layer.frame
                item.bounds = layer.bounds
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
            windowItem.frame = CGRect(origin: .zero, size: window.frame.size)
            windowItem.bounds = windowItem.frame
            windowItem.shouldCaptureImage = true
            windowItem.subitems = [item(for: root)]
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

            let server = FakeServer()
            defer { server.shutDown() }
            server.responders[UInt32(LookinRequestTypeLayerArchive)] = { _ in
                let reply = LayerArchive()
                reply.layerCount = UInt(layers.count)
                reply.layerOids = layers.map { oidsByLayer[ObjectIdentifier($0)] ?? 0 }
                reply.sublayerCounts = layers.map { UInt32($0.sublayers?.count ?? 0) }
                typealias EncodeLayerTreeFunction = @convention(c) (CALayer) -> Unmanaged<NSData>?
                if let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CAEncodeLayerTree") {
                    let encode = unsafeBitCast(symbol, to: EncodeLayerTreeFunction.self)
                    reply.archiveData = encode(root)?.takeRetainedValue() as Data?
                }
                return reply
            }
            server.responders[UInt32(LookinRequestTypeHierarchyDetails)] = { Self.emptyDetails(for: $0) }
            let channel = server.connectChannel()
            let app = InspectableApp()
            app.appInfo = appInfo
            app.channel = channel
            let dataSource = StaticHierarchyDataSource()
            let manager = StaticAsyncUpdateManager(hierarchyDataSource: dataSource, inspectableApp: nil)
            manager.inspectableApp = app
            var orderChanges = 0
            let subscription = dataSource.previewOrderDidChange.observe { _ in orderChanges += 1 }
            dataSource.reload(with: hierarchy, keepState: false)
            #expect(await waitUntil { !manager.layerArchiveStore.hasPendingArchives })

            // A layer two portals draw goes with the later one, drawn on top.
            var lastPortalBySource: [ObjectIdentifier: (source: CALayer, portal: CALayer)] = [:]
            for pair in XcodeViewHierarchyPixelRecovery.portalsHidingTheirSources(in: layers) {
                lastPortalBySource[ObjectIdentifier(pair.source)] = pair
            }
            #expect(!lastPortalBySource.isEmpty, "the glass should draw its content through a portal that hides it in place")
            for (source, portal) in lastPortalBySource.values {
                let sourceItem = itemsByOid[oidsByLayer[ObjectIdentifier(source)] ?? 0]
                let portalItem = itemsByOid[oidsByLayer[ObjectIdentifier(portal)] ?? 0]
                let linked = sourceItem?.previewPortalItem?.layerObject?.oid
                #expect(
                    portalItem != nil && sourceItem?.previewPortalItem === portalItem,
                    "\(NSStringFromClass(type(of: source))) #\(oidsByLayer[ObjectIdentifier(source)] ?? 0), drawn by \(NSStringFromClass(type(of: portal))) #\(oidsByLayer[ObjectIdentifier(portal)] ?? 0), should know the portal's node; linked to \(String(describing: linked))"
                )
            }
            #expect(orderChanges > 0, "the preview should hear that its order changed")
            withExtendedLifetime((channel, app, dataSource, manager, subscription)) {}
        }

        /// With the Liquid Glass setting on Hide, AppKit's glass — a split
        /// view's sidebar glass included — stayed in every image drawn from
        /// the archive that holds it: hiding the glass layer nodes took only
        /// their own planes away. Those images now leave the glass out, the
        /// content still showing where it is, and changing the setting draws
        /// them again.
        @Test func hiddenGlassLeavesTheGlassViewsContentInPlace() async {
            guard #available(macOS 26.0, *) else { return }
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            window.appearance = NSAppearance(named: .darkAqua)
            defer { window.close() }
            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
            contentView.wantsLayer = true
            let glassView = NSGlassEffectView(frame: NSRect(x: 20, y: 30, width: 200, height: 40))
            glassView.contentView = NSTextField(labelWithString: "Filter")
            contentView.addSubview(glassView)
            window.contentView = contentView
            window.displayIfNeeded()
            CATransaction.flush()

            guard var root = contentView.layer, let glassViewLayer = glassView.layer else {
                Issue.record("the views should have layers")
                return
            }
            while let superlayer = root.superlayer {
                root = superlayer
            }
            var layers: [CALayer] = []
            var pending = [root]
            while let layer = pending.popLast() {
                layers.append(layer)
                pending.append(contentsOf: (layer.sublayers ?? []).reversed())
            }
            var oidsByLayer: [ObjectIdentifier: UInt] = [:]
            for (index, layer) in layers.enumerated() {
                oidsByLayer[ObjectIdentifier(layer)] = UInt(100 + index)
            }
            var itemsByOid: [UInt: DisplayItem] = [:]
            // A node for every layer, with its class: SwiftUI's glass layers
            // are what the setting hides.
            func item(for layer: CALayer) -> DisplayItem {
                let layerObject = InspectedObject()
                layerObject.oid = oidsByLayer[ObjectIdentifier(layer)] ?? 0
                layerObject.classChainList = [NSStringFromClass(type(of: layer)), "CALayer", "NSObject"]
                let item = DisplayItem()
                item.nodeKind = .layer
                item.layerObject = layerObject
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
            windowItem.frame = CGRect(origin: .zero, size: window.frame.size)
            windowItem.bounds = windowItem.frame
            windowItem.shouldCaptureImage = true
            windowItem.subitems = [item(for: root)]
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

            let server = FakeServer()
            defer { server.shutDown() }
            server.responders[UInt32(LookinRequestTypeLayerArchive)] = { _ in
                let reply = LayerArchive()
                reply.layerCount = UInt(layers.count)
                reply.layerOids = layers.map { oidsByLayer[ObjectIdentifier($0)] ?? 0 }
                reply.sublayerCounts = layers.map { UInt32($0.sublayers?.count ?? 0) }
                typealias EncodeLayerTreeFunction = @convention(c) (CALayer) -> Unmanaged<NSData>?
                if let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CAEncodeLayerTree") {
                    let encode = unsafeBitCast(symbol, to: EncodeLayerTreeFunction.self)
                    reply.archiveData = encode(root)?.takeRetainedValue() as Data?
                }
                return reply
            }
            server.responders[UInt32(LookinRequestTypeHierarchyDetails)] = { Self.emptyDetails(for: $0) }
            let channel = server.connectChannel()
            let app = InspectableApp()
            app.appInfo = appInfo
            app.channel = channel
            // A settings set of the test's own: the app's must not change.
            let preferences = PreferenceManager()
            preferences.glassLayerVisibility = .hide
            let dataSource = StaticHierarchyDataSource(preferenceManager: preferences)
            let manager = StaticAsyncUpdateManager(hierarchyDataSource: dataSource, inspectableApp: nil)
            manager.inspectableApp = app
            dataSource.reload(with: hierarchy, keepState: false)
            #expect(await waitUntil { !manager.layerArchiveStore.hasPendingArchives })
            guard let glassViewItem = itemsByOid[oidsByLayer[ObjectIdentifier(glassViewLayer)] ?? 0] else {
                Issue.record("the glass view should have a node")
                return
            }

            guard case let .image(withGlassHidden)? = await manager.layerArchiveImage(.group, of: glassViewItem) else {
                Issue.record("the glass view should have a group image with its glass hidden")
                return
            }
            let hiddenCoverage = Self.coverage(of: withGlassHidden)
            #expect(hiddenCoverage.opaque < 0.3, "with the glass hidden only the label should be opaque, got \(hiddenCoverage.opaque)")
            #expect(hiddenCoverage.visible > 0.005, "the label should still show with the glass hidden, got \(hiddenCoverage.visible)")

            preferences.glassLayerVisibility = .show
            guard case let .image(withGlassShown)? = await manager.layerArchiveImage(.group, of: glassViewItem) else {
                Issue.record("the glass view should have a group image with its glass shown")
                return
            }
            let shownCoverage = Self.coverage(of: withGlassShown)
            #expect(shownCoverage.opaque > 0.6, "with the glass shown the glass should cover the view, got \(shownCoverage.opaque)")
            withExtendedLifetime((channel, app, dataSource, manager)) {}
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
