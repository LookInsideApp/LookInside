import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol

@MainActor
enum InspectionSnapshotEncoder {
    static func objectIdentifier(_ item: LookinDisplayItem) -> String {
        "0x" + String(item.displayingObject()?.oid ?? 0, radix: 16)
    }

    static func node(_ item: LookinDisplayItem, remainingDepth: Int) -> InspectionValue {
        let frame = item.hasValidFrameToRoot() ? item.calculateFrameToRoot() : item.frame
        let children = item.subitems ?? []
        var result: [String: InspectionValue] = [
            "objectIdentifier": .string(objectIdentifier(item)),
            "className": .string(item.displayingObject()?.classChainList?.first ?? ""),
            "nodeKind": .string(nodeKind(item)),
            "frame": .object(["x": .double(frame.origin.x), "y": .double(frame.origin.y), "width": .double(frame.width), "height": .double(frame.height)]),
            "isHidden": .bool(item.isHidden), "alpha": .double(Double(item.alpha)), "representsKeyWindow": .bool(item.representedAsKeyWindow),
            "childObjectIdentifiers": .array(children.map { .string(objectIdentifier($0)) }),
        ]
        if remainingDepth > 1 {
            result["children"] = .array(children.map { node($0, remainingDepth: remainingDepth - 1) })
        }
        return .object(result)
    }

    static func attributes(_ item: LookinDisplayItem) throws -> InspectionValue {
        let isSecure = LKMCPBridgeSecureContentDetector.isSecure(displayItem: item)
        let groups = ((item.attributesGroupList ?? []) + (item.customAttrGroupList ?? [])).map { group in
            LKMCPBridgeAttributeGroup(identifier: group.userCustomTitle ?? group.identifier ?? "", isUserCustom: group.userCustomTitle != nil,
                                      isSwiftUIGroup: group.isSwiftUIGroup, sections: (group.attrSections ?? []).map { section in
                                          LKMCPBridgeAttributeSection(identifier: section.identifier ?? "", attributes: (section.attributes ?? []).map { attribute in
                                              LKMCPBridgeAttributeEncoder.encode(attribute, redactingSecureContent: isSecure)
                                          })
                                      })
        }
        let encodedGroups = try JSONDecoder().decode(InspectionValue.self, from: JSONEncoder().encode(groups))
        return .object(["groups": encodedGroups, "secureContent": .bool(isSecure), "detailsCached": .bool(item.attributesGroupList != nil)])
    }

    private static func nodeKind(_ item: LookinDisplayItem) -> String {
        switch item.resolvedNodeKind() {
        case .layer: "layer"
        case .viewOuterLayer: "viewOuterLayer"
        case .backingLayer: "backingLayer"
        case .view, .unspecified: "view"
        case .window: "window"
        case .windowScene: "windowScene"
        case .custom: "custom"
        case .layoutGuide: "layoutGuide"
        case .cell: "cell"
        @unknown default: "unknown"
        }
    }
}
