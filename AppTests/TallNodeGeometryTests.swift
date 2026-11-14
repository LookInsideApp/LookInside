//
//  TallNodeGeometryTests.swift
//  LookInsideAppTests
//
//  A node taller than 100 000 points: RuntimeViewer's sidebar outline is
//  107 829 points tall with its groups expanded. A Server from before the
//  fix leaves its frame out of the hierarchy, and a detail brings the real
//  one. The host took a frame past 100 000 points as unusable: the outline
//  had no plane in the preview, and its rows sat below the window.
//

import AppKit
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct TallNodeGeometryTests {
        private func viewItem(
            oid: UInt,
            frame: CGRect,
            bounds: CGRect? = nil,
            isFlipped: Bool = false,
            subitems: [DisplayItem] = []
        ) -> DisplayItem {
            let viewObject = InspectedObject()
            viewObject.oid = oid
            viewObject.classChainList = ["NSView", "NSResponder", "NSObject"]
            let item = DisplayItem()
            item.nodeKind = .view
            item.viewObject = viewObject
            item.frame = frame
            item.bounds = bounds ?? CGRect(origin: .zero, size: frame.size)
            item.isFlipped = isFlipped
            item.alpha = 1
            item.shouldCaptureImage = true
            item.subitems = subitems
            return item
        }

        @Test func rowsOfAnOutlineTallerThanAHundredThousandPointsStayInTheClipView() {
            let outlineSize = CGSize(width: 364.5, height: 107_829)
            let firstRow = viewItem(oid: 4, frame: CGRect(x: 0, y: 19, width: 364.5, height: 24))
            let outline = viewItem(
                oid: 3,
                frame: .zero,
                bounds: CGRect(origin: .zero, size: outlineSize),
                isFlipped: true,
                subitems: [firstRow]
            )
            // Inset 88 below a toolbar.
            let clipView = viewItem(
                oid: 2,
                frame: CGRect(x: 0, y: 0, width: 364.5, height: 1007),
                bounds: CGRect(x: 0, y: -88, width: 364.5, height: 1007),
                isFlipped: true,
                subitems: [outline]
            )
            let root = viewItem(oid: 1, frame: CGRect(x: 0, y: 0, width: 381.5, height: 1007), subitems: [clipView])
            let appInfo = InspectedAppInfo()
            appInfo.screenScale = 2
            let info = HierarchyInfo()
            info.appInfo = appInfo
            info.displayItems = [root]
            let dataSource = StaticHierarchyDataSource()
            dataSource.reload(with: info, keepState: false)

            let detail = DisplayItemDetail()
            detail.displayItemOid = 3
            detail.frameValue = NSValue(rect: CGRect(origin: .zero, size: outlineSize))
            detail.boundsValue = NSValue(rect: CGRect(origin: .zero, size: outlineSize))
            dataSource.modify(with: detail)

            // The clip view's top edge is at 1007; the outline starts 88 below
            // it and the first row 19 further down.
            #expect(outline.calculateFrameToRoot() == CGRect(x: 0, y: 919 - 107_829, width: 364.5, height: 107_829))
            #expect(firstRow.calculateFrameToRoot() == CGRect(x: 0, y: 919 - 19 - 24, width: 364.5, height: 24))
            #expect(outline.doNotFetchScreenshotReason == .doNotFetchScreenshotForTooLarge, "the preview shows it red")
        }
    }
}
