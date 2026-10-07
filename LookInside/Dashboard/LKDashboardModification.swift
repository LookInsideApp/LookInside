//
//  LKDashboardModification.swift
//  LookInside
//
//  The payloads the Dashboard sends when the user edits an attribute, and
//  the edited values the attribute views build. These rules decide what
//  goes over the wire, so they live apart from the views and depend only on
//  the LookinCore model: the tests compile this file with LookinCore alone.
//

import Foundation

enum LKDashboardModification {
    /// The request for an attribute the Server knows: the setter of the
    /// attribute's identifier, called on the object the attribute belongs
    /// to (view, layer, window or cell of the item). Nil when the
    /// identifier has no setter.
    static func inbuilt(attribute: LookinAttribute, newValue: Any?, clientReadableVersion: String?) -> LookinAttributeModification? {
        let modification = LookinAttributeModification()
        modification.clientReadableVersion = clientReadableVersion
        let item = attribute.targetDisplayItem
        switch LookinDashboardBlueprint.targetKind(forAttrID: attribute.identifier) {
        case .view:
            modification.targetOid = item?.viewObject?.oid ?? 0
        case .window:
            modification.targetOid = item?.windowObject?.oid ?? 0
        case .cell:
            modification.targetOid = item?.cellObject?.oid ?? 0
        case .layer:
            modification.targetOid = item?.layerObject?.oid ?? 0
        @unknown default:
            modification.targetOid = item?.layerObject?.oid ?? 0
        }
        guard let setter = LookinDashboardBlueprint.setter(withAttrID: attribute.identifier) else {
            return nil
        }
        modification.setterSelector = setter
        modification.attrType = attribute.attrType
        modification.value = newValue
        return modification
    }

    /// The request for a user-custom attribute: its setter id with the new
    /// value. Nil when the attribute has no setter (read-only rows, such as
    /// the SwiftUI attributes).
    static func custom(attribute: LookinAttribute, newValue: Any?) -> LookinCustomAttrModification? {
        guard let setterID = attribute.customSetterID, !setterID.isEmpty else {
            return nil
        }
        let modification = LookinCustomAttrModification()
        modification.customSetterID = setterID
        modification.attrType = attribute.attrType
        modification.value = newValue
        return modification
    }

    // MARK: - Edited values

    /// The attributes whose number is an opacity, kept within 0...1.
    static let clampedToUnitIdentifiers: Set<String> = [
        LookinAttr_ViewLayer_Visibility_Opacity,
        LookinAttr_ViewLayer_Shadow_Opacity,
    ]

    /// The number to submit for a number attribute, or nil when it equals
    /// the current value (nothing to submit).
    static func numberValue(_ parsed: NSNumber, for attribute: LookinAttribute) -> NSNumber? {
        var value = parsed
        if clampedToUnitIdentifiers.contains(attribute.identifier ?? "") {
            value = NSNumber(value: max(min(parsed.doubleValue, 1), 0))
        }
        if let current = attribute.value as? NSObject, value.isEqual(current) {
            return nil
        }
        return value
    }

    /// The rect with field `index` (x, y, width, height) replaced.
    static func rect(_ rect: CGRect, replacingField index: Int, with value: Double) -> CGRect? {
        var result = rect
        switch index {
        case 0: result.origin.x = value
        case 1: result.origin.y = value
        case 2: result.size.width = value
        case 3: result.size.height = value
        default: return nil
        }
        return result
    }

    /// The insets with field `index` (top, left, bottom, right) replaced.
    static func insets(_ insets: NSEdgeInsets, replacingField index: Int, with value: Double) -> NSEdgeInsets? {
        var result = insets
        switch index {
        case 0: result.top = value
        case 1: result.left = value
        case 2: result.bottom = value
        case 3: result.right = value
        default: return nil
        }
        return result
    }

    /// The point with field `index` (x, y) replaced.
    static func point(_ point: CGPoint, replacingField index: Int, with value: Double) -> CGPoint? {
        var result = point
        switch index {
        case 0: result.x = value
        case 1: result.y = value
        default: return nil
        }
        return result
    }

    /// The size with field `index` (width, height) replaced.
    static func size(_ size: CGSize, replacingField index: Int, with value: Double) -> CGSize? {
        var result = size
        switch index {
        case 0: result.width = value
        case 1: result.height = value
        default: return nil
        }
        return result
    }

    /// Whether two insets differ in any edge. `NSValue`'s equality is not
    /// reliable for insets, so the edges are compared one by one.
    static func insetsDiffer(_ lhs: NSEdgeInsets, _ rhs: NSEdgeInsets) -> Bool {
        lhs.top != rhs.top || lhs.left != rhs.left || lhs.bottom != rhs.bottom || lhs.right != rhs.right
    }

    /// Whether two rects are equal within 0.1 point on every field.
    static func rect(_ lhs: CGRect, isAlmostEqualTo rhs: CGRect) -> Bool {
        abs(lhs.origin.x - rhs.origin.x) <= 0.1
            && abs(lhs.origin.y - rhs.origin.y) <= 0.1
            && abs(lhs.size.width - rhs.size.width) <= 0.1
            && abs(lhs.size.height - rhs.size.height) <= 0.1
    }

    /// Whether a frame edit "had no effect": the app set the value back to
    /// the old rect after the Server applied the new one.
    static func rectEditWasReverted(old: CGRect, expected: CGRect, current: CGRect) -> Bool {
        rect(old, isAlmostEqualTo: current) && !rect(expected, isAlmostEqualTo: current)
    }

    /// The value of a switch: `@YES` / `@NO`.
    static func boolValue(isOn: Bool) -> NSNumber {
        NSNumber(value: isOn)
    }
}

// MARK: - Constraints

enum LKDashboardConstraintOrder {
    /// The order the constraints card lists constraints in: effective ones
    /// first, then by first item type and first attribute. The sort is
    /// stable, as `-sortedArrayUsingComparator:` is.
    static func sorted(_ constraints: [LookinAutoLayoutConstraint]) -> [LookinAutoLayoutConstraint] {
        let array = constraints as NSArray
        let sorted = array.sortedArray(options: .stable) { lhs, rhs in
            guard let lhs = lhs as? LookinAutoLayoutConstraint, let rhs = rhs as? LookinAutoLayoutConstraint else {
                return .orderedSame
            }
            if lhs.effective != rhs.effective {
                return lhs.effective ? .orderedAscending : .orderedDescending
            }
            if lhs.firstItemType.rawValue != rhs.firstItemType.rawValue {
                return lhs.firstItemType.rawValue > rhs.firstItemType.rawValue ? .orderedDescending : .orderedAscending
            }
            if lhs.firstAttribute != rhs.firstAttribute {
                return lhs.firstAttribute > rhs.firstAttribute ? .orderedDescending : .orderedAscending
            }
            return .orderedSame
        }
        return sorted.compactMap { $0 as? LookinAutoLayoutConstraint }
    }
}
