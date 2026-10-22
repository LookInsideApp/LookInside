//
//  ReadHierarchyController.swift
//  Lookin
//
//  Created by Li Kai on 2019/5/13.
//  https://lookin.work
//

import AppKit

/// The reader's hierarchy list. Hiding or showing an item's preview only
/// changes the in-memory tree; there is no app to tell.
final class ReadHierarchyController: HierarchyController {
    override func hierarchyView(_: HierarchyView, needToCancelPreviewOf item: DisplayItem) {
        item.noPreview = true
        notifyNoPreviewDidChange()
    }

    override func hierarchyView(_: HierarchyView, needToShowPreviewOf item: DisplayItem) {
        // A preview shows only when none of its ancestors hides theirs.
        item.enumerateSelfAndAncestors { item, _ in
            if item.noPreview {
                item.noPreview = false
            }
        }
        notifyNoPreviewDidChange()
    }

    private func notifyNoPreviewDidChange() {
        dataSource.itemDidChangeNoPreview.send()
    }
}
