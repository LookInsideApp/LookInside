//
//  AutoLayoutConstraint+LookinClient.swift
//  LookInside
//
//  How constraints are written in the Dashboard's constraint rows and
//  popover. Attributes use the iOS NSLayoutAttribute numbering; see
//  ClientDisplayText.layoutAttributeName(_:).
//

import AppKit
import LookInsideHostCore

extension AutoLayoutConstraint {
    @objc(descriptionWithItemObject:type:detailed:)
    static func description(withItemObject object: InspectedObject?, type: LookinConstraintItemType, detailed: Bool) -> String {
        switch type {
        case .`nil`:
            return detailed ? "Nil" : "nil"
        case .`self`:
            return detailed ? "Self" : "self"
        case .`super`:
            return detailed ? "Superview" : "super"
        case .view, .layoutGuide:
            return detailed
                ? "<\(object?.rawClassName() ?? "(null)"): \(object?.memoryAddress ?? "(null)")>"
                : "(\(object?.simpleDemangledClassName() ?? "(null)")*)"
        default:
            assertionFailure("unknown constraint item type \(type.rawValue)")
            return detailed
                ? "<\(object?.rawClassName() ?? "(null)"): \(object?.memoryAddress ?? "(null)")>"
                : "(\(object?.rawClassName() ?? "(null)")*)"
        }
    }

    @objc(descriptionWithAttributeInt:)
    static func description(withAttributeInt attribute: Int) -> String {
        if let name = ClientDisplayText.layoutAttributeName(attribute) {
            return name
        }
        assertionFailure("unknown layout attribute \(attribute)")
        return "unknownAttr(\(attribute))"
    }

    @objc(symbolWithRelation:)
    static func symbol(with relation: NSLayoutConstraint.Relation) -> String {
        if let symbol = ClientDisplayText.layoutRelationSymbol(relation.rawValue) {
            return symbol
        }
        assertionFailure("unknown layout relation \(relation.rawValue)")
        return "?"
    }

    @objc(descriptionWithRelation:)
    static func description(with relation: NSLayoutConstraint.Relation) -> String {
        if let name = ClientDisplayText.layoutRelationName(relation.rawValue) {
            return name
        }
        assertionFailure("unknown layout relation \(relation.rawValue)")
        return "?"
    }
}
