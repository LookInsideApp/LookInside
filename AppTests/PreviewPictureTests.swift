//
//  PreviewPictureTests.swift
//  LookInsideAppTests
//
//  A preview plane holds its node's picture only while the node shows.
//  SceneKit uploads the texture of a plane at opacity 0 all the same, so with
//  every node holding its image a dumped Xcode window cost 1.5 GB of
//  textures in the preview while the folded tree showed one of them.
//

import AppKit
@testable import LookInside
import SceneKit
import Testing

extension HostAppTests {
    @MainActor
    struct PreviewPictureTests {
        private func makingImage() -> NSImage {
            NSImage(size: NSSize(width: 4, height: 4), flipped: false) { rect in
                NSColor.red.setFill()
                rect.fill()
                return true
            }
        }

        private func layerItem(oid: UInt, subitems: [DisplayItem] = []) -> DisplayItem {
            let layerObject = InspectedObject()
            layerObject.oid = oid
            layerObject.classChainList = ["CALayer", "NSObject"]
            let item = DisplayItem()
            item.nodeKind = .layer
            item.layerObject = layerObject
            item.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            item.bounds = item.frame
            // Visible, as the Server sends it: an alpha of 0 puts the node in a
            // hidden hierarchy, which the preview does not show.
            item.alpha = 1
            // As the Server sends it; false means the app asked for no
            // screenshot of this node.
            item.shouldCaptureImage = true
            item.groupScreenshot = makingImage()
            item.subitems = subitems
            return item
        }

        /// What the node's own plane is given to draw.
        private func picture(on node: DisplayItemNode) -> NSImage? {
            node.childNode(withName: "screenshot", recursively: false)?.geometry?.firstMaterial?.diffuse.contents as? NSImage
        }

        @Test func aPlaneHoldsItsPictureOnlyWhileItsNodeShows() {
            let child = layerItem(oid: 2)
            let root = layerItem(oid: 1, subitems: [child])
            let info = HierarchyInfo()
            info.displayItems = [root]
            let file = HierarchyFile()
            file.hierarchyInfo = info
            let dataSource = ReadHierarchyDataSource(file: file, preferenceManager: PreferenceManager())
            root.isExpanded = false
            #expect(root.displayingInHierarchy)
            #expect(!child.displayingInHierarchy)

            let rootNode = DisplayItemNode(dataSource: dataSource)
            rootNode.displayItem = root
            let childNode = DisplayItemNode(dataSource: dataSource)
            childNode.displayItem = child

            #expect(picture(on: rootNode) === root.groupScreenshot, "the folded root shows its group image")
            #expect(picture(on: childNode) == nil, "a node folded away holds no picture")

            root.isExpanded = true
            #expect(picture(on: childNode) === child.groupScreenshot, "unfolding the root shows the child's picture")

            root.isExpanded = false
            #expect(picture(on: childNode) == nil, "folding it again lets the child's picture go")
            withExtendedLifetime(dataSource) {}
        }

        /// A node the preview stops using is kept for reuse; it must not keep
        /// its picture meanwhile.
        @Test func aNodeTakenOutOfTheSceneLetsItsPictureGo() {
            let root = layerItem(oid: 1)
            let info = HierarchyInfo()
            info.displayItems = [root]
            let file = HierarchyFile()
            file.hierarchyInfo = info
            let dataSource = ReadHierarchyDataSource(file: file, preferenceManager: PreferenceManager())
            let node = DisplayItemNode(dataSource: dataSource)
            node.displayItem = root
            #expect(picture(on: node) === root.groupScreenshot)

            node.releasingPicture()
            #expect(picture(on: node) == nil)
            withExtendedLifetime(dataSource) {}
        }
    }
}
