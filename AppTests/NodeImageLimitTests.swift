//
//  NodeImageLimitTests.swift
//  LookInsideAppTests
//
//  The nodes of a live session the preview takes no image of: those without
//  pixels of their own, and those larger than an image may be
//  (`LookinNodeImageMaxLengthInPx`). A reload marks them; a detail that
//  changes a node's frame, or brings new nodes, marks them the same way.
//

import AppKit
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct NodeImageLimitTests {
        private func layerItem(oid: UInt, size: CGSize, subitems: [DisplayItem] = []) -> DisplayItem {
            let layerObject = InspectedObject()
            layerObject.oid = oid
            layerObject.classChainList = ["CALayer", "NSObject"]
            let item = DisplayItem()
            item.nodeKind = .layer
            item.layerObject = layerObject
            item.frame = CGRect(origin: .zero, size: size)
            item.bounds = item.frame
            item.alpha = 1
            item.shouldCaptureImage = true
            item.subitems = subitems
            return item
        }

        /// A live session's tree holding `root`, from a Server on a screen of
        /// scale 2: at most 8142 points on a side for an image.
        private func loadedDataSource(root: DisplayItem) -> StaticHierarchyDataSource {
            let dataSource = StaticHierarchyDataSource()
            let appInfo = InspectedAppInfo()
            appInfo.screenScale = 2
            let info = HierarchyInfo()
            info.appInfo = appInfo
            info.displayItems = [root]
            dataSource.reload(with: info, keepState: false)
            return dataSource
        }

        private func detail(of item: DisplayItem, size: CGSize) -> DisplayItemDetail {
            let detail = DisplayItemDetail()
            detail.displayItemOid = item.layerObject?.oid ?? 0
            detail.frameValue = NSValue(rect: CGRect(origin: .zero, size: size))
            detail.boundsValue = NSValue(rect: CGRect(origin: .zero, size: size))
            return detail
        }

        /// The Server's screenshots of a node that grows past the limit show
        /// it at its old size: a detail that grows it takes them away and
        /// marks it too large, as a reload would have; one that shrinks it to
        /// fit lets the Server's screenshots be asked for again.
        @Test func detailThatGrowsANodePastTheLimitTakesItsScreenshotsAway() {
            let item = layerItem(oid: 2, size: CGSize(width: 100, height: 100))
            let dataSource = loadedDataSource(root: layerItem(oid: 1, size: CGSize(width: 400, height: 400), subitems: [item]))
            #expect(item.doNotFetchScreenshotReason == .fetchScreenshotPermitted)
            item.groupScreenshot = NSImage(size: CGSize(width: 100, height: 100))
            item.soloScreenshot = NSImage(size: CGSize(width: 100, height: 100))

            dataSource.modify(with: detail(of: item, size: CGSize(width: 100, height: 9000)))
            #expect(item.doNotFetchScreenshotReason == .doNotFetchScreenshotForTooLarge)
            #expect(item.groupScreenshot == nil)
            #expect(item.soloScreenshot == nil)

            dataSource.modify(with: detail(of: item, size: CGSize(width: 100, height: 100)))
            #expect(item.doNotFetchScreenshotReason == .fetchScreenshotPermitted)
        }

        /// The nodes a detail brings — an item reloaded with its children —
        /// were never checked: a guide got screenshot tasks that drew its
        /// view a second time, and a node too large for an image got one.
        /// They are marked as a reload marks them.
        @Test func nodesADetailBringsAreMarkedAsAReloadMarksThem() {
            let root = layerItem(oid: 1, size: CGSize(width: 400, height: 400))
            let dataSource = loadedDataSource(root: root)

            let guide = DisplayItem()
            guide.nodeKind = .layoutGuide
            guide.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            guide.alpha = 1
            guide.shouldCaptureImage = true
            let tall = layerItem(oid: 3, size: CGSize(width: 100, height: 9000))
            let small = layerItem(oid: 4, size: CGSize(width: 50, height: 50))
            let detail = DisplayItemDetail()
            detail.displayItemOid = 1
            detail.subitems = [guide, tall, small]
            dataSource.modify(with: detail)

            #expect(guide.doNotFetchScreenshotReason == .doNotFetchScreenshotForNoPixels)
            #expect(tall.doNotFetchScreenshotReason == .doNotFetchScreenshotForTooLarge)
            #expect(small.doNotFetchScreenshotReason == .fetchScreenshotPermitted)
        }
    }
}
