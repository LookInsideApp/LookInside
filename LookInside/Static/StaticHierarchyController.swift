//
//  StaticHierarchyController.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/4.
//  https://lookin.work
//

import AppKit

/// The hierarchy tree of a live inspector window.
final class StaticHierarchyController: HierarchyController {
    // MARK: - HierarchyViewDelegate

    override func hierarchyView(_: HierarchyView, needToCancelPreviewOf item: DisplayItem) {
        item.noPreview = true
        dataSource.itemDidChangeNoPreview.send()
    }

    override func hierarchyView(_: HierarchyView, needToShowPreviewOf item: DisplayItem) {
        item.enumerateSelfAndAncestors { item, _ in
            if item.noPreview {
                item.noPreview = false
            }
        }
        dataSource.itemDidChangeNoPreview.send()
    }
}
