//
//  LKStaticHierarchyController.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit

/// The hierarchy tree of a live inspector window.
@objc(LKStaticHierarchyController)
final class LKStaticHierarchyController: LKHierarchyController {
    // MARK: - LKHierarchyViewDelegate

    @objc(hierarchyView:needToCancelPreviewOfItem:)
    func hierarchyView(_: LKHierarchyView?, needToCancelPreviewOf item: DisplayItem?) {
        item?.noPreview = true
        dataSource?.itemDidChangeNoPreview.send()
    }

    @objc(hierarchyView:needToShowPreviewOfItem:)
    func hierarchyView(_: LKHierarchyView?, needToShowPreviewOf item: DisplayItem?) {
        item?.enumerateSelfAndAncestors { item, _ in
            if item.noPreview {
                item.noPreview = false
            }
        }
        dataSource?.itemDidChangeNoPreview.send()
    }
}
