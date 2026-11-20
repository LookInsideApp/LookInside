//
//  DetailScreenshotRegionTests.swift
//  LookInsideAppTests
//
//  A node of no size that does not clip draws only through its subtree,
//  outside its empty bounds — SwiftUI hosts UIKit views in 0 x 0 containers.
//  The Server's 203 detail then carries an image of what the subtree draws
//  and the region it covers (`groupScreenshotRegionValue`); the preview
//  places the image by `DisplayItem.groupScreenshotRegion`, as it does for
//  the importers. A detail without a region means the image spans the bounds.
//

import AppKit
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct DetailScreenshotRegionTests {
        private func layerItem(oid: UInt, frame: CGRect, subitems: [DisplayItem] = []) -> DisplayItem {
            let layerObject = InspectedObject()
            layerObject.oid = oid
            layerObject.classChainList = ["CALayer", "NSObject"]
            let item = DisplayItem()
            item.nodeKind = .layer
            item.layerObject = layerObject
            item.frame = frame
            item.bounds = CGRect(origin: .zero, size: frame.size)
            item.alpha = 1
            item.shouldCaptureImage = true
            item.subitems = subitems
            return item
        }

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

        private func groupScreenshotDetail(of item: DisplayItem, region: CGRect?) -> DisplayItemDetail {
            let detail = DisplayItemDetail()
            detail.displayItemOid = item.layerObject?.oid ?? 0
            detail.groupScreenshot = NSImage(size: CGSize(width: 48, height: 100))
            detail.groupScreenshotRegionValue = region.map { NSValue(rect: $0) }
            return detail
        }

        /// The floating bar's button container is 0 x 0; its buttons draw at
        /// (394, 174, 48, 100) of its space.
        @Test func detailRegionPlacesTheGroupScreenshot() {
            let container = layerItem(oid: 2, frame: .zero)
            let dataSource = loadedDataSource(root: layerItem(oid: 1, frame: CGRect(x: 0, y: 0, width: 466, height: 678), subitems: [container]))
            let region = CGRect(x: 394, y: 174, width: 48, height: 100)

            dataSource.modify(with: groupScreenshotDetail(of: container, region: region))

            #expect(container.groupScreenshot != nil)
            #expect(container.groupScreenshotRegion == region)
        }

        /// A node that grew a size, or a Server that predates the field: the
        /// image spans the bounds, so an earlier region must not stay.
        @Test func detailWithoutRegionResetsAnEarlierRegion() {
            let container = layerItem(oid: 2, frame: .zero)
            let dataSource = loadedDataSource(root: layerItem(oid: 1, frame: CGRect(x: 0, y: 0, width: 466, height: 678), subitems: [container]))
            dataSource.modify(with: groupScreenshotDetail(of: container, region: CGRect(x: 394, y: 174, width: 48, height: 100)))

            dataSource.modify(with: groupScreenshotDetail(of: container, region: nil))

            #expect(container.groupScreenshotRegion == .zero)
        }

        /// A detail that brings no group screenshot (a solo screenshot, or
        /// attributes only) leaves the region with the image it belongs to.
        @Test func detailWithoutGroupScreenshotKeepsTheRegion() {
            let container = layerItem(oid: 2, frame: .zero)
            let dataSource = loadedDataSource(root: layerItem(oid: 1, frame: CGRect(x: 0, y: 0, width: 466, height: 678), subitems: [container]))
            let region = CGRect(x: 394, y: 174, width: 48, height: 100)
            dataSource.modify(with: groupScreenshotDetail(of: container, region: region))

            let soloDetail = DisplayItemDetail()
            soloDetail.displayItemOid = 2
            soloDetail.soloScreenshot = NSImage(size: CGSize(width: 1, height: 1))
            dataSource.modify(with: soloDetail)

            #expect(container.groupScreenshotRegion == region)
        }
    }
}
