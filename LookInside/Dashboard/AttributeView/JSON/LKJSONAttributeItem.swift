//
//  LKJSONAttributeItem.swift
//  LookInside
//
//  Created by likai.123 on 2023/12/4.
//
//  The tree model of a JSON attribute: an array of
//  {"title", "desc", "details": [...]} objects. Foundation only, so the
//  tests can compile it on its own.
//

import Foundation

final class LKJSONAttributeItem {
    var titleText: String?
    var desc: String?
    var expanded = true
    var indentation = 0
    var subItems: [LKJSONAttributeItem] = []

    /// The item, then (when expanded) its sub-items' flat items, each one
    /// indented one level deeper than its parent.
    func flatItems() -> [LKJSONAttributeItem] {
        var array = [self]
        if expanded {
            for item in subItems {
                item.indentation = indentation + 1
                array.append(contentsOf: item.flatItems())
            }
        }
        return array
    }

    /// The root items of `json`; nil when it is nil, not valid JSON, or not
    /// an array. Entries that are not objects are skipped.
    static func rootItems(fromJSON json: String?) -> [LKJSONAttributeItem]? {
        guard let json else { return nil }
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: Data(json.utf8))
        } catch {
            NSLog("转换失败: %@", String(describing: error))
            assertionFailure()
            return nil
        }
        return items(from: object)
    }

    private static func items(from rawArray: Any?) -> [LKJSONAttributeItem]? {
        guard let rawArray = rawArray as? [Any] else { return nil }
        return rawArray.compactMap { element in
            guard let dict = element as? [String: Any] else { return nil }
            let item = LKJSONAttributeItem()
            item.titleText = dict["title"] as? String
            item.desc = dict["desc"] as? String
            item.expanded = true
            item.subItems = items(from: dict["details"]) ?? []
            return item
        }
    }

    /// The rows to show for `rootItems`.
    static func flatItems(of rootItems: [LKJSONAttributeItem]?) -> [LKJSONAttributeItem] {
        (rootItems ?? []).flatMap { $0.flatItems() }
    }
}
