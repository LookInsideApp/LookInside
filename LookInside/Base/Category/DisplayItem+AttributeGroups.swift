//
//  DisplayItem+AttributeGroups.swift
//  LookInside
//
//  Which attribute groups a node holds. A refresh brings the displayed rows
//  only their extension and custom groups; the selected node, and every
//  node written into a file, get the blueprint groups too
//  (selected-node-attributes-plan.md). Depends on LookinCoreImpl alone, so
//  the MCP bridge's standalone tests compile it.
//

import Foundation

extension DisplayItem {
    /// The group identifiers of the blueprint catalog, both platforms'.
    static let blueprintGroupIdentifiers = Set(DashboardBlueprintTables.catalog.map(\.identifier))

    /// Whether `group` is one of the blueprint's: the dashboard's groups, as
    /// opposed to an extension group (SwiftUI's, say) or a custom one.
    static func isBlueprintGroup(_ group: AttributesGroup) -> Bool {
        group.identifier.map(blueprintGroupIdentifiers.contains) ?? false
    }

    /// Whether the node has its blueprint attribute groups. An older Server
    /// sends them with every displayed row.
    var hasBlueprintAttributes: Bool {
        (attributesGroupList ?? []).contains(where: Self.isBlueprintGroup)
    }

    /// Whether the node has every attribute group the inspected app can
    /// send: its blueprint groups, or for a custom node any detail's groups.
    var hasEveryAttributeGroup: Bool {
        customInfo != nil ? attributesGroupList != nil || customAttrGroupList != nil : hasBlueprintAttributes
    }
}
