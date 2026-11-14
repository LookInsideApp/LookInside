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
        private static func loadingSession(_ inspected: InspectedWindow, on server: FakeServer) async -> Session {
            server.responders[UInt32(LookinRequestTypeHierarchyDetails)] = { emptyDetails(for: $0) }
            let channel = server.connectChannel()
            let app = InspectableApp()
            app.appInfo = inspected.hierarchy.appInfo
            app.channel = channel
            let dataSource = StaticHierarchyDataSource()
            let manager = StaticAsyncUpdateManager(hierarchyDataSource: dataSource, inspectableApp: app)
            dataSource.reload(with: inspected.hierarchy, keepState: false)
            _ = await waitUntil { !manager.layerArchiveStore.hasPendingArchives }
            return Session(channel: channel, app: app, dataSource: dataSource, manager: manager)
        }

        private static func fetchingWholeTree(_ manager: StaticAsyncUpdateManager) async -> Bool {
            var isFinished = false
            manager.fetchWholeTree { isFinished = true }
            return await waitUntil(timeout: .seconds(20)) { isFinished }
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
