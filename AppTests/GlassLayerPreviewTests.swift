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

        private func makeGlassTree() -> GlassTree {
            let shapeSource = layerItem(classChain: ["CALayer", "NSObject"], oid: 4)
            let glassLayer = layerItem(classChain: ["SwiftUI.SDFLayer", "CALayer", "NSObject"], oid: 3, subitems: [shapeSource])
            let content = layerItem(classChain: ["CALayer", "NSObject"], oid: 2)
            let root = layerItem(classChain: ["CALayer", "NSObject"], oid: 1, subitems: [content, glassLayer])
            let info = HierarchyInfo()
            info.displayItems = [root]
            let file = HierarchyFile()
            file.hierarchyInfo = info
            return GlassTree(file: file, content: content, glassLayer: glassLayer, shapeSource: shapeSource)
        }

        /// A document window's preference set, with the setting as given.
        private func documentPreferences(hidingGlassLayers hidesGlassLayers: Bool) -> PreferenceManager {
            let preferences = PreferenceManager()
            preferences.hidesGlassLayersInPreview = hidesGlassLayers
            return preferences
        }

        @Test func glassLayersStayOutOfThePreviewWhileTheSettingIsOn() {
            let tree = makeGlassTree()
            let dataSource = ReadHierarchyDataSource(file: tree.file, preferenceManager: documentPreferences(hidingGlassLayers: true))

            #expect(tree.glassLayer.inNoPreviewHierarchy)
            #expect(tree.shapeSource.inNoPreviewHierarchy, "the white shape source goes with its glass layer")
            #expect(!tree.content.inNoPreviewHierarchy)
            withExtendedLifetime(dataSource) {}
        }

        @Test func glassLayersStayInThePreviewWhileTheSettingIsOff() {
            let tree = makeGlassTree()
            let dataSource = ReadHierarchyDataSource(file: tree.file, preferenceManager: documentPreferences(hidingGlassLayers: false))

            #expect(!tree.glassLayer.inNoPreviewHierarchy)
            #expect(!tree.shapeSource.inNoPreviewHierarchy)
            withExtendedLifetime(dataSource) {}
        }

        @Test func turningTheSettingOnHidesTheGlassOfALoadedTree() {
            let tree = makeGlassTree()
            let preferences = documentPreferences(hidingGlassLayers: false)
            let dataSource = ReadHierarchyDataSource(file: tree.file, preferenceManager: preferences)
            var previewRebuildCount = 0
            let subscription = dataSource.itemDidChangeNoPreview.observe { _ in
                previewRebuildCount += 1
            }

            preferences.hidesGlassLayersInPreview = true

            #expect(tree.glassLayer.inNoPreviewHierarchy)
            #expect(tree.shapeSource.inNoPreviewHierarchy)
            #expect(previewRebuildCount == 1, "the preview rebuilds once, without a refresh")
            withExtendedLifetime(subscription) {}
        }

        @Test func turningTheSettingOffShowsOnlyTheGlassAgain() {
            let tree = makeGlassTree()
            let preferences = documentPreferences(hidingGlassLayers: true)
            let dataSource = ReadHierarchyDataSource(file: tree.file, preferenceManager: preferences)
            tree.content.noPreview = true

            preferences.hidesGlassLayersInPreview = false

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

            #expect(glassLayerHiddenWhenThePreviewRenders == PreferenceManager.shared.hidesGlassLayersInPreview)
            #expect(glassLayer.noPreview == PreferenceManager.shared.hidesGlassLayersInPreview)
            withExtendedLifetime(subscription) {}
        }
    }
}
