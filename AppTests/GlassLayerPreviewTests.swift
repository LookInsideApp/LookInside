//
//  GlassLayerPreviewTests.swift
//  LookInsideAppTests
//
//  Liquid Glass layers (SwiftUI's SDFLayer) stay out of the preview while
//  Settings asks for it: a capture of them is only their white shape source.
//  Most trees load through a document's data source, which reads the setting
//  from the window's own preference set; that set never writes user
//  defaults, so the tests cannot change the app's settings.
//

import Foundation
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct GlassLayerPreviewTests {
        /// What AppKit builds for an NSGlassEffectView on macOS 26 and later,
        /// cut down: the content, and beside it the glass layer with its white
        /// shape source.
        private struct GlassTree {
            let file: HierarchyFile
            let content: DisplayItem
            let glassLayer: DisplayItem
            let shapeSource: DisplayItem
        }

        private func layerItem(classChain: [String], oid: UInt, subitems: [DisplayItem] = []) -> DisplayItem {
            let layerObject = InspectedObject()
            layerObject.oid = oid
            layerObject.classChainList = classChain
            let item = DisplayItem()
            item.nodeKind = .layer
            item.layerObject = layerObject
            item.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            // As the Server sends it; false means the app asked for no
            // screenshot of this node.
            item.shouldCaptureImage = true
            item.subitems = subitems
            return item
        }

        private func makeGlassTree(drawnFromLayerArchives: Bool = false) -> GlassTree {
            let shapeSource = layerItem(classChain: ["CALayer", "NSObject"], oid: 4)
            let glassLayer = layerItem(classChain: ["SwiftUI.SDFLayer", "CALayer", "NSObject"], oid: 3, subitems: [shapeSource])
            let content = layerItem(classChain: ["CALayer", "NSObject"], oid: 2)
            let root = layerItem(classChain: ["CALayer", "NSObject"], oid: 1, subitems: [content, glassLayer])
            let info = HierarchyInfo()
            info.displayItems = [root]
            if drawnFromLayerArchives {
                let appInfo = InspectedAppInfo()
                appInfo.layerArchiveProtocolVersion = 1
                info.appInfo = appInfo
            }
            let file = HierarchyFile()
            file.hierarchyInfo = info
            return GlassTree(file: file, content: content, glassLayer: glassLayer, shapeSource: shapeSource)
        }

        private func viewItem(classChain: [String], oid: UInt, subitems: [DisplayItem] = []) -> DisplayItem {
            let viewObject = InspectedObject()
            viewObject.oid = oid
            viewObject.classChainList = classChain
            let item = DisplayItem()
            item.nodeKind = .view
            item.viewObject = viewObject
            item.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            item.shouldCaptureImage = true
            item.subitems = subitems
            return item
        }

        /// The glass AppKit puts behind a split view's sidebar, in the item's
        /// wrapper view, beside a control's glass elsewhere in the window.
        private struct SplitViewGlassTree {
            let file: HierarchyFile
            let sidebarGlass: DisplayItem
            let controlGlass: DisplayItem
        }

        private func makeSplitViewGlassTree(drawnFromLayerArchives: Bool) -> SplitViewGlassTree {
            let glassViewChain = ["NSGlassEffectView", "NSView", "NSResponder", "NSObject"]
            let sidebarGlass = layerItem(classChain: ["SwiftUI.SDFLayer", "CALayer", "NSObject"], oid: 13)
            let sidebarHostingView = viewItem(classChain: ["_NSCoreHostingView", "NSView", "NSResponder", "NSObject"], oid: 12, subitems: [sidebarGlass])
            let sidebarGlassView = viewItem(classChain: glassViewChain, oid: 11, subitems: [sidebarHostingView])
            let wrapper = viewItem(classChain: ["_NSSplitViewItemViewWrapper", "NSView", "NSResponder", "NSObject"], oid: 10, subitems: [sidebarGlassView])
            let controlGlass = layerItem(classChain: ["SwiftUI.SDFLayer", "CALayer", "NSObject"], oid: 21)
            let controlGlassView = viewItem(classChain: glassViewChain, oid: 20, subitems: [controlGlass])
            let root = layerItem(classChain: ["CALayer", "NSObject"], oid: 1, subitems: [wrapper, controlGlassView])
            let info = HierarchyInfo()
            info.displayItems = [root]
            if drawnFromLayerArchives {
                let appInfo = InspectedAppInfo()
                appInfo.layerArchiveProtocolVersion = 1
                info.appInfo = appInfo
            }
            let file = HierarchyFile()
            file.hierarchyInfo = info
            return SplitViewGlassTree(file: file, sidebarGlass: sidebarGlass, controlGlass: controlGlass)
        }

        /// A document window's preference set, with the setting as given.
        private func documentPreferences(_ visibility: GlassLayerVisibility) -> PreferenceManager {
            let preferences = PreferenceManager()
            preferences.glassLayerVisibility = visibility
            return preferences
        }

        @Test func glassLayersStayOutOfThePreviewWhileTheSettingIsOn() {
            let tree = makeGlassTree()
            let dataSource = ReadHierarchyDataSource(file: tree.file, preferenceManager: documentPreferences(.hide))

            #expect(tree.glassLayer.inNoPreviewHierarchy)
            #expect(tree.shapeSource.inNoPreviewHierarchy, "the white shape source goes with its glass layer")
            #expect(!tree.content.inNoPreviewHierarchy)
            withExtendedLifetime(dataSource) {}
        }

        @Test func glassLayersStayInThePreviewWhileTheSettingIsOff() {
            let tree = makeGlassTree()
            let dataSource = ReadHierarchyDataSource(file: tree.file, preferenceManager: documentPreferences(.show))

            #expect(!tree.glassLayer.inNoPreviewHierarchy)
            #expect(!tree.shapeSource.inNoPreviewHierarchy)
            withExtendedLifetime(dataSource) {}
        }

        @Test func turningTheSettingOnHidesTheGlassOfALoadedTree() {
            let tree = makeGlassTree()
            let preferences = documentPreferences(.show)
            let dataSource = ReadHierarchyDataSource(file: tree.file, preferenceManager: preferences)
            var previewRebuildCount = 0
            let subscription = dataSource.itemDidChangeNoPreview.observe { _ in
                previewRebuildCount += 1
            }

            preferences.glassLayerVisibility = .hide

            #expect(tree.glassLayer.inNoPreviewHierarchy)
            #expect(tree.shapeSource.inNoPreviewHierarchy)
            #expect(previewRebuildCount == 1, "the preview rebuilds once, without a refresh")
            withExtendedLifetime(subscription) {}
        }

        @Test func turningTheSettingOffShowsOnlyTheGlassAgain() {
            let tree = makeGlassTree()
            let preferences = documentPreferences(.hide)
            let dataSource = ReadHierarchyDataSource(file: tree.file, preferenceManager: preferences)
            tree.content.noPreview = true

            preferences.glassLayerVisibility = .show

            #expect(!tree.glassLayer.inNoPreviewHierarchy)
            #expect(!tree.shapeSource.inNoPreviewHierarchy)
            #expect(tree.content.inNoPreviewHierarchy, "a node the user hid stays hidden")
            withExtendedLifetime(dataSource) {}
        }

        /// A live window reads Settings itself, and the tests must not change
        /// the app's settings; whatever this machine holds, a glass layer that
        /// arrives in a reloaded subtree follows it. It must already do so
        /// when the reload is announced: the preview renders right then.
        @Test func aGlassLayerInAReloadedSubtreeFollowsTheSettingWhenThePreviewRenders() {
            let dataSource = StaticHierarchyDataSource()
            let info = HierarchyInfo()
            info.displayItems = [layerItem(classChain: ["CALayer", "NSObject"], oid: 1)]
            let appInfo = InspectedAppInfo()
            appInfo.screenScale = 2
            info.appInfo = appInfo
            dataSource.reload(with: info, keepState: false)

            let shapeSource = layerItem(classChain: ["CALayer", "NSObject"], oid: 3)
            let glassLayer = layerItem(classChain: ["SwiftUI.SDFLayer", "CALayer", "NSObject"], oid: 2, subitems: [shapeSource])
            var glassLayerHiddenWhenThePreviewRenders: Bool?
            let subscription = dataSource.didReloadHierarchyInfo.observe { _ in
                glassLayerHiddenWhenThePreviewRenders = glassLayer.inNoPreviewHierarchy
            }
            let detail = DisplayItemDetail()
            detail.displayItemOid = 1
            detail.subitems = [glassLayer]
            dataSource.modify(with: detail)

            // The app info says nothing of layer archives: the Server takes
            // the images.
            let hidesGlass = PreferenceManager.shared.glassLayerVisibility.hidesGlassLayer(isDrawnByLookInside: false, isSplitViewBackground: false)
            #expect(glassLayerHiddenWhenThePreviewRenders == hidesGlass)
            #expect(glassLayer.noPreview == hidesGlass)
            withExtendedLifetime(subscription) {}
        }

        @Test func byDefaultGlassStaysOutOnlyWhereTheServerTakesTheImages() {
            let serverTree = makeGlassTree()
            let serverDataSource = ReadHierarchyDataSource(file: serverTree.file, preferenceManager: documentPreferences(.hideWhereNotDrawn))
            #expect(serverTree.glassLayer.inNoPreviewHierarchy, "a Server's capture of the glass is a white block")

            let drawnTree = makeGlassTree(drawnFromLayerArchives: true)
            let drawnDataSource = ReadHierarchyDataSource(file: drawnTree.file, preferenceManager: documentPreferences(.hideWhereNotDrawn))
            #expect(!drawnTree.glassLayer.inNoPreviewHierarchy, "glass drawn from a layer archive stays in the preview")
            #expect(!drawnTree.shapeSource.inNoPreviewHierarchy)
            withExtendedLifetime((serverDataSource, drawnDataSource)) {}
        }

        /// Hide is for the glass AppKit puts behind a split view's sidebar or
        /// inspector, which covers the item's content in the preview. Where
        /// LookInside draws glass it left out every piece, a toolbar button's
        /// or a filter field's capsule too; now only that background glass
        /// goes. Where LookInside cannot draw glass, every piece is a white
        /// block and all of it goes.
        @Test func hideLeavesOutOnlyTheSplitViewGlassWhereLookInsideDrawsGlass() {
            let drawn = makeSplitViewGlassTree(drawnFromLayerArchives: true)
            let drawnDataSource = ReadHierarchyDataSource(file: drawn.file, preferenceManager: documentPreferences(.hide))
            #expect(drawn.sidebarGlass.inNoPreviewHierarchy, "the glass behind the sidebar goes")
            #expect(!drawn.controlGlass.inNoPreviewHierarchy, "a control's glass stays")

            let captured = makeSplitViewGlassTree(drawnFromLayerArchives: false)
            let capturedDataSource = ReadHierarchyDataSource(file: captured.file, preferenceManager: documentPreferences(.hide))
            #expect(captured.sidebarGlass.inNoPreviewHierarchy)
            #expect(captured.controlGlass.inNoPreviewHierarchy, "the Server's capture of a control's glass is a white block")
            withExtendedLifetime((drawnDataSource, capturedDataSource)) {}
        }

        @Test func aWindowLeftWithoutItsArchiveHidesItsGlassAgain() {
            let shapeSource = layerItem(classChain: ["CALayer", "NSObject"], oid: 4)
            let glassLayer = layerItem(classChain: ["SwiftUI.SDFLayer", "CALayer", "NSObject"], oid: 3, subitems: [shapeSource])
            let windowObject = InspectedObject()
            windowObject.oid = 1000
            windowObject.classChainList = ["NSWindow", "NSResponder", "NSObject"]
            let window = DisplayItem()
            window.nodeKind = .window
            window.windowObject = windowObject
            window.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            window.shouldCaptureImage = true
            window.subitems = [glassLayer]
            let appInfo = InspectedAppInfo()
            appInfo.layerArchiveProtocolVersion = 1
            let info = HierarchyInfo()
            info.appInfo = appInfo
            info.displayItems = [window]
            let file = HierarchyFile()
            file.hierarchyInfo = info
            let dataSource = ReadHierarchyDataSource(file: file, preferenceManager: documentPreferences(.hideWhereNotDrawn))
            #expect(!glassLayer.inNoPreviewHierarchy)

            dataSource.setWindowsWithoutLayerArchive([1000])

            #expect(glassLayer.inNoPreviewHierarchy, "the window's glass is the Server's white block again")
        }

        @Test func theChoiceCarriesOverFromTheSwitchItReplaced() throws {
            func visibility(storedSwitch: Bool?, storedChoice: GlassLayerVisibility? = nil) throws -> (GlassLayerVisibility, Int?) {
                let suiteName = "LookInsideAppTests.GlassLayerVisibility.\(UUID().uuidString)"
                let defaults = try #require(UserDefaults(suiteName: suiteName))
                defer { defaults.removePersistentDomain(forName: suiteName) }
                if let storedSwitch {
                    defaults.set(storedSwitch, forKey: "hideGlassLayersInPreview")
                }
                if let storedChoice {
                    defaults.set(storedChoice.rawValue, forKey: "glassLayerVisibility")
                }
                let visibility = PreferenceManager.storedGlassLayerVisibility(defaults)
                return (visibility, defaults.object(forKey: "glassLayerVisibility") as? Int)
            }
            let (fresh, writtenBack) = try visibility(storedSwitch: nil)
            #expect(fresh == .hideWhereNotDrawn, "nothing stored: hide where the glass cannot be drawn")
            #expect(writtenBack == GlassLayerVisibility.hideWhereNotDrawn.rawValue, "the choice is written back")
            #expect(try visibility(storedSwitch: true).0 == .hideWhereNotDrawn, "the switch on: hide where the glass cannot be drawn")
            #expect(try visibility(storedSwitch: false).0 == .show, "the switch off: show the glass")
            #expect(try visibility(storedSwitch: false, storedChoice: .hide).0 == .hide, "a stored choice wins over the old switch")
        }
    }
}
