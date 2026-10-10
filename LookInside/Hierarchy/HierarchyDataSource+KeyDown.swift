//
//  HierarchyDataSource+KeyDown.swift
//  LookInside
//
//  Created by Hares on 7/17/23.
//  Copyright © 2023 hughkli. All rights reserved.
//

import AppKit
import LookInsideHostCore

extension HierarchyDataSource {
    /// Arrow keys move the selection and expand or collapse rows. Returns
    /// whether the key was handled.
    @objc(keyDown:)
    func keyDown(_ event: NSEvent) -> Bool {
        let rows = displayingFlatItems ?? []
        let selectedRow = selectedItem.flatMap { selected in rows.firstIndex { $0 === selected } }
        let action = HierarchyKeyNavigation.action(keyCode: event.keyCode, selectedRow: selectedRow, rowCount: rows.count) { index in
            let item = rows[index]
            return HierarchyKeyNavigation.Row(
                isExpandable: item.isExpandable,
                isExpanded: item.isExpanded,
                parentRow: item.super.flatMap { parent in rows.firstIndex { $0 === parent } },
                isInHiddenHierarchy: item.inHiddenHierarchy
            )
        }
        switch action {
        case let .select(row):
            selectedItem = rows[row]
        case let .collapse(row):
            collapse(rows[row])
        case let .collapseAndSelect(row):
            collapse(rows[row])
            selectedItem = rows[row]
        case let .expand(row):
            expand(rows[row])
        case nil:
            return false
        }
        return true
    }
}
