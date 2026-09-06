// LKMCPBridgeAttributeEncoder.swift
//
// Encodes a host-side `LookinAttribute` into the wire DTO
// `LKMCPBridgeAttribute` for the `attributes.read` MCPBridge method.
//
// The host represents an attribute's payload as a polymorphic `id value`
// disambiguated by `LookinAttrType`. The wire format flattens that into a
// `kind` discriminator string plus a JSON value whose shape depends on
// kind. v1 of this encoder handles the structurally distinct kinds with
// dedicated projections (numbers, bools, strings, geometry struct types,
// colors, shadows, enums, JSON pass-through); rarer or implementation-
// specific kinds fall back to a `{ "rawDescription": "..." }` payload so
// agents can still read something meaningful instead of seeing a missing
// field. Adding more first-class encoders here is the safest place to
// extend coverage.

import CoreGraphics
import Foundation
import LookInsideInspectionCore

#if canImport(AppKit)
    import AppKit
#endif

enum LKMCPBridgeAttributeEncoder {
    /// Encodes one host-side `LookinAttribute` into the wire DTO.
    ///
    /// - Parameter redactingSecureContent: when `true`, string-valued kinds
    ///   (`string`, `selector`, `class`, `enum` string variant) are replaced
    ///   with a `kind: "redacted"` marker and a nil value before the DTO
    ///   leaves this encoder. Geometry / numeric / color projections are
    ///   not affected — they cannot reveal secret user content. The flag is
    ///   evaluated once per display item by the caller (see
    ///   `LKMCPBridgeSecureContentDetector`) and applies uniformly to every
    ///   attribute carried by that item, so a secure text field never leaks
    ///   either its `text`, its `placeholder`, or any custom-attribute
    ///   string the host might collect via `lookin_customDebugInfos`.
    static func encode(
        _ attribute: LookinAttribute,
        redactingSecureContent: Bool
    ) -> LKMCPBridgeAttribute {
        let projection = projectValue(of: attribute)
        let finalProjection = redactingSecureContent
            ? redactedIfString(projection)
            : projection
        return LKMCPBridgeAttribute(
            identifier: attribute.identifier,
            displayTitle: attribute.displayTitle,
            isUserCustom: attribute.isUserCustom(),
            kind: finalProjection.kind,
            value: finalProjection.value,
            extraValue: redactingSecureContent ? nil : encodeExtraValue(attribute),
            customSetterIdentifier: attribute.customSetterID
        )
    }

    /// When the enclosing display item is flagged as secure, swap any
    /// string-bearing projection for a redaction marker. Numeric, boolean,
    /// geometry, color, shadow, json, and custom-object projections fall
    /// through unchanged — they don't carry text values that could leak.
    private static func redactedIfString(_ projection: Projection) -> Projection {
        switch projection.kind {
        case "string", "selector", "class":
            return Projection(kind: "redacted", value: nil)
        case "enum":
            // `enum` covers both EnumInt/EnumLong (numeric) and EnumString
            // (textual). Only the latter actually carries a user-visible
            // string; the projection layer collapses them into the same
            // `kind`, so we conservatively redact both. The numeric variant
            // case is degenerate (no leak possible from an integer enum
            // value), the cost of redaction is just losing the raw int.
            return Projection(kind: "redacted", value: nil)
        default:
            return projection
        }
    }

    // MARK: - Per-type projection

    private struct Projection {
        let kind: String
        let value: LKMCPBridgeJSONValue?
    }

    private static func projectValue(of attribute: LookinAttribute) -> Projection {
        let rawValue: Any? = attribute.value
        switch attribute.attrType {
        case .none, .void:
            return Projection(kind: "void", value: nil)

        case .char, .int, .short, .long, .longLong,
             .unsignedChar, .unsignedInt, .unsignedShort,
             .unsignedLong, .unsignedLongLong,
             .enumInt, .enumLong:
            // EnumInt / EnumLong land here because the actual stored value
            // is an NSNumber; the enum case-name table travels in `extraValue`.
            let kind: String
            switch attribute.attrType {
            case .enumInt, .enumLong:
                kind = "enum"
            default:
                kind = "integer"
            }
            return Projection(kind: kind, value: encodeNumberAsInteger(rawValue))

        case .float, .double:
            return Projection(kind: "double", value: encodeNumberAsDouble(rawValue))

        case .BOOL:
            // ObjC `LookinAttrTypeBOOL` keeps its uppercase initialism after
            // the importer strips the type prefix.
            return Projection(kind: "bool", value: .bool((rawValue as? NSNumber)?.boolValue ?? false))

        case .sel:
            return Projection(kind: "selector", value: encodeAsString(rawValue))

        case .class:
            return Projection(kind: "class", value: encodeAsString(rawValue))

        case .nsString:
            return Projection(kind: "string", value: encodeAsString(rawValue))

        case .enumString:
            return Projection(kind: "enum", value: encodeAsString(rawValue))

        case .cgPoint:
            return Projection(kind: "point", value: encodePoint(rawValue))

        case .cgVector:
            return Projection(kind: "vector", value: encodeVector(rawValue))

        case .cgSize:
            return Projection(kind: "size", value: encodeSize(rawValue))

        case .cgRect:
            return Projection(kind: "rect", value: encodeRect(rawValue))

        case .cgAffineTransform:
            return Projection(kind: "transform", value: encodeAffineTransform(rawValue))

        case .uiEdgeInsets:
            return Projection(kind: "edgeInsets", value: encodeEdgeInsets(rawValue))

        case .uiOffset:
            return Projection(kind: "offset", value: encodeOffset(rawValue))

        case .uiColor:
            return Projection(kind: "color", value: encodeColor(rawValue))

        case .shadow:
            return Projection(kind: "shadow", value: encodeShadow(rawValue))

        case .json:
            return Projection(kind: "json", value: encodeArbitraryJSON(rawValue))

        case .customObj:
            if let constraints = rawValue as? [LookinAutoLayoutConstraint], constraints.isEmpty == false {
                return Projection(kind: "constraints", value: encodeConstraints(constraints))
            }
            return Projection(kind: "custom", value: encodeCustomObject(rawValue))

        @unknown default:
            return Projection(kind: "unknown", value: encodeFallbackDescription(rawValue))
        }
    }

    // MARK: - extraValue

    private static func encodeExtraValue(_ attribute: LookinAttribute) -> LKMCPBridgeJSONValue? {
        guard let extra = attribute.extraValue else { return nil }
        // For LookinAttrTypeEnumString, `extraValue` is the array of all
        // possible enum case names — surface it directly. Other attribute
        // kinds rarely populate `extraValue`; when they do, just pass the
        // object through `encodeArbitraryJSON` which falls back to a
        // description-string if the type cannot be projected losslessly.
        if let strings = extra as? [String] {
            return .array(strings.map(LKMCPBridgeJSONValue.string))
        }
        return encodeArbitraryJSON(extra)
    }

    // MARK: - Number helpers

    private static func encodeNumberAsInteger(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let number = raw as? NSNumber else { return nil }
        return .integer(Int64(truncatingIfNeeded: number.int64Value))
    }

    private static func encodeNumberAsDouble(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let number = raw as? NSNumber else { return nil }
        return .double(number.doubleValue)
    }

    private static func encodeAsString(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let text = raw as? String else { return nil }
        return .string(text)
    }

    // MARK: - Geometry helpers

    private static func cgFloatValue(_ raw: Any?) -> Double? {
        guard let number = raw as? NSNumber else { return nil }
        return number.doubleValue
    }

    private static func encodePoint(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let nsValue = raw as? NSValue else { return nil }
        var point = CGPoint.zero
        nsValue.getValue(&point, size: MemoryLayout<CGPoint>.size)
        return .object([
            "x": .double(Double(point.x)),
            "y": .double(Double(point.y)),
        ])
    }

    private static func encodeVector(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let nsValue = raw as? NSValue else { return nil }
        var vector = CGVector.zero
        nsValue.getValue(&vector, size: MemoryLayout<CGVector>.size)
        return .object([
            "dx": .double(Double(vector.dx)),
            "dy": .double(Double(vector.dy)),
        ])
    }

    private static func encodeSize(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let nsValue = raw as? NSValue else { return nil }
        var size = CGSize.zero
        nsValue.getValue(&size, size: MemoryLayout<CGSize>.size)
        return .object([
            "width": .double(Double(size.width)),
            "height": .double(Double(size.height)),
        ])
    }

    private static func encodeRect(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let nsValue = raw as? NSValue else { return nil }
        var rect = CGRect.zero
        nsValue.getValue(&rect, size: MemoryLayout<CGRect>.size)
        return .object([
            "x": .double(Double(rect.origin.x)),
            "y": .double(Double(rect.origin.y)),
            "width": .double(Double(rect.size.width)),
            "height": .double(Double(rect.size.height)),
        ])
    }

    private static func encodeAffineTransform(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let nsValue = raw as? NSValue else { return nil }
        var transform = CGAffineTransform.identity
        nsValue.getValue(&transform, size: MemoryLayout<CGAffineTransform>.size)
        return .object([
            "a": .double(Double(transform.a)),
            "b": .double(Double(transform.b)),
            "c": .double(Double(transform.c)),
            "d": .double(Double(transform.d)),
            "tx": .double(Double(transform.tx)),
            "ty": .double(Double(transform.ty)),
        ])
    }

    private static func encodeEdgeInsets(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let nsValue = raw as? NSValue else { return nil }
        // UIKit's UIEdgeInsets and AppKit's NSEdgeInsets share the same
        // memory layout: top / left / bottom / right CGFloats.
        var insets: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        nsValue.getValue(&insets, size: MemoryLayout.size(ofValue: insets))
        return .object([
            "top": .double(Double(insets.0)),
            "left": .double(Double(insets.1)),
            "bottom": .double(Double(insets.2)),
            "right": .double(Double(insets.3)),
        ])
    }

    private static func encodeOffset(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let nsValue = raw as? NSValue else { return nil }
        var offset: (CGFloat, CGFloat) = (0, 0)
        nsValue.getValue(&offset, size: MemoryLayout.size(ofValue: offset))
        return .object([
            "horizontal": .double(Double(offset.0)),
            "vertical": .double(Double(offset.1)),
        ])
    }

    // MARK: - Color / Shadow

    private static func encodeColor(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        // LookinServer encodes UIColor as @[NSNumber, NSNumber, NSNumber, NSNumber]
        // in RGBA, components in 0...1. Surface as a named-key object for
        // agent readability while still preserving the underlying numbers.
        guard let components = raw as? [NSNumber], components.count >= 4 else {
            return nil
        }
        return .object([
            "red": .double(components[0].doubleValue),
            "green": .double(components[1].doubleValue),
            "blue": .double(components[2].doubleValue),
            "alpha": .double(components[3].doubleValue),
        ])
    }

    private static func encodeShadow(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        // Server-side shape (LKS_CustomAttrGroupsMaker.m): NSDictionary with
        // keys offset (NSValue<CGSize>), opacity (NSNumber), radius
        // (NSNumber), color ([NSNumber] RGBA).
        guard let dictionary = raw as? [String: Any] else { return nil }
        var encoded: [String: LKMCPBridgeJSONValue] = [:]
        if let offset = encodeSize(dictionary["offset"]) {
            encoded["offset"] = offset
        }
        if let opacity = dictionary["opacity"] as? NSNumber {
            encoded["opacity"] = .double(opacity.doubleValue)
        }
        if let radius = dictionary["radius"] as? NSNumber {
            encoded["radius"] = .double(radius.doubleValue)
        }
        if let color = encodeColor(dictionary["color"]) {
            encoded["color"] = color
        }
        return .object(encoded)
    }

    // MARK: - Custom / JSON / fallback

    private static func encodeArbitraryJSON(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let raw else { return nil }
        // Try to round-trip through Foundation's JSONSerialization. This
        // handles dictionaries, arrays, NSNumber, NSString, NSNull cleanly
        // and lets us reuse the existing JSONValue decoder.
        if JSONSerialization.isValidJSONObject(raw) {
            do {
                let data = try JSONSerialization.data(withJSONObject: raw, options: [.fragmentsAllowed])
                return try JSONDecoder().decode(LKMCPBridgeJSONValue.self, from: data)
            } catch {
                // Fall through to description fallback.
            }
        }
        return encodeFallbackDescription(raw)
    }

    // MARK: - Constraints

    private static func constraintItemTypeString(_ itemType: LookinConstraintItemType) -> String {
        switch itemType {
        case .nil: return "nil"
        case .view: return "view"
        case .`self`: return "self"
        case .super: return "super"
        case .layoutGuide: return "layoutGuide"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }

    private static func constraintRelationString(_ relation: NSLayoutConstraint.Relation) -> String {
        switch relation {
        case .lessThanOrEqual: return "lessThanOrEqual"
        case .equal: return "equal"
        case .greaterThanOrEqual: return "greaterThanOrEqual"
        @unknown default: return "unknown"
        }
    }

    private static func encodeConstraintEndpoint(_ endpointObject: LookinObject?, itemType: LookinConstraintItemType) -> LKMCPBridgeJSONValue {
        var fields: [String: LKMCPBridgeJSONValue] = [
            "itemType": .string(constraintItemTypeString(itemType)),
        ]
        if let endpointObject, endpointObject.oid != 0 {
            fields["objectIdentifier"] = .string(String(format: "0x%lx", endpointObject.oid))
        }
        if let className = endpointObject?.classChainList?.first {
            fields["className"] = .string(className)
        }
        return .object(fields)
    }

    /// Structured projection of an AutoLayout constraints list — previously
    /// this fell into the description-string fallback and lost every field.
    /// The attribute numbers stay raw NSInteger values: UIKit and AppKit
    /// assign different numbers to NSLayoutAttribute cases, and the bridge
    /// does not know which platform produced the data.
    private static func encodeConstraints(_ constraints: [LookinAutoLayoutConstraint]) -> LKMCPBridgeJSONValue {
        let encodedConstraints: [LKMCPBridgeJSONValue] = constraints.map { constraint in
            var fields: [String: LKMCPBridgeJSONValue] = [
                "firstItem": encodeConstraintEndpoint(constraint.firstItem, itemType: constraint.firstItemType),
                "firstAttributeRawValue": .integer(Int64(constraint.firstAttribute)),
                "relation": .string(constraintRelationString(constraint.relation)),
                "secondItem": encodeConstraintEndpoint(constraint.secondItem, itemType: constraint.secondItemType),
                "secondAttributeRawValue": .integer(Int64(constraint.secondAttribute)),
                "multiplier": .double(Double(constraint.multiplier)),
                "constant": .double(Double(constraint.constant)),
                "priority": .double(Double(constraint.priority)),
                "isActive": .bool(constraint.active),
                "isEffective": .bool(constraint.effective),
            ]
            if constraint.constraintOid != 0 {
                // The same constraint appears in both endpoints' lists; this
                // identifier is what lets an agent deduplicate the copies.
                fields["constraintObjectIdentifier"] = .string(String(format: "0x%lx", constraint.constraintOid))
            }
            if let identifier = constraint.identifier, identifier.isEmpty == false {
                fields["identifier"] = .string(identifier)
            }
            return .object(fields)
        }
        return .array(encodedConstraints)
    }

    private static func encodeCustomObject(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        // Custom objects don't have a fixed shape; surface their class name
        // and a description so agents have something to render. Bridge
        // consumers that need a typed projection should use the attribute
        // identifier to know what they're looking at.
        guard let raw else { return nil }
        let object = raw as AnyObject
        let className = String(describing: type(of: object))
        let descriptionText = String(describing: object)
        return .object([
            "className": .string(className),
            "description": .string(descriptionText),
        ])
    }

    private static func encodeFallbackDescription(_ raw: Any?) -> LKMCPBridgeJSONValue? {
        guard let raw else { return nil }
        return .object([
            "rawDescription": .string(String(describing: raw)),
        ])
    }
}
