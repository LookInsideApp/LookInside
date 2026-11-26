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
    /// The edges of `trackingEdges`, top, leading, bottom, trailing in that
    /// order; empty for a constraint no tracking layout guide registered.
    var trackingEdgeNames: [String] {
        let edges: [(edge: NSDirectionalRectEdge, name: String)] = [(.top, "top"), (.leading, "leading"), (.bottom, "bottom"), (.trailing, "trailing")]
        return edges.filter { trackingEdges.contains($0.edge) }.map(\.name)
    }

    /// `trackingEdgeNames` as the constraint rows write them, "top +
    /// leading"; nil for a constraint no tracking layout guide registered.
    var trackingEdgesDescription: String? {
        let names = trackingEdgeNames
        return names.isEmpty ? nil : names.joined(separator: " + ")
    }

    static func description(withItemObject object: InspectedObject?, type: AutoLayoutConstraint.ItemType, detailed: Bool) -> String {
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

    static func description(withAttributeInt attribute: Int) -> String {
        if let name = ClientDisplayText.layoutAttributeName(attribute) {
            return name
        }
        assertionFailure("unknown layout attribute \(attribute)")
        return "unknownAttr(\(attribute))"
    }

    static func symbol(with relation: NSLayoutConstraint.Relation) -> String {
        if let symbol = ClientDisplayText.layoutRelationSymbol(relation.rawValue) {
            return symbol
        }
        assertionFailure("unknown layout relation \(relation.rawValue)")
        return "?"
    }

    static func description(with relation: NSLayoutConstraint.Relation) -> String {
        if let name = ClientDisplayText.layoutRelationName(relation.rawValue) {
            return name
        }
        assertionFailure("unknown layout relation \(relation.rawValue)")
        return "?"
    }
}
