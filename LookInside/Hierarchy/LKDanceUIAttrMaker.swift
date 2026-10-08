//
//  LKDanceUIAttrMaker.swift
//  LookInside
//
//  Created by likai.123 on 2023/12/21.
//  Copyright © 2023 hughkli. All rights reserved.
//

import Foundation

/// Adds the "jump to the DanceUI file" class attribute to DanceUI nodes.
enum LKDanceUIAttrMaker {
    /// Gives `item` a Class group naming the type in `source` (DanceUI's
    /// JSON), unless it already has one.
    static func makeDanceUIJumpAttribute(_ item: DisplayItem, danceSource source: String) {
        guard let className = className(fromSource: source) else {
            return
        }
        let groups = item.attributesGroupList ?? []
        if groups.contains(where: { $0.identifier == LookinAttrGroup_Class }) {
            return
        }
        let attribute = InspectedAttribute()
        attribute.identifier = LookinAttr_Class_Class_Class
        attribute.attrType = .customObj
        attribute.value = [[className]]

        let section = AttributesSection()
        section.identifier = LookinAttrSec_Class_Class
        section.attributes = [attribute]

        let group = AttributesGroup()
        group.identifier = LookinAttrGroup_Class
        group.attrSections = [section]

        item.attributesGroupList = groups + [group]
    }

    private static func className(fromSource json: String) -> String? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any]
        else {
            assertionFailure("DanceUI source is not a JSON object")
            return nil
        }
        guard let type = dictionary["type"] as? String else {
            assertionFailure("DanceUI source has no type")
            return nil
        }
        return type
    }
}
