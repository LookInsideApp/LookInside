// LKMCPBridgeAttributeValueDecoder.swift
//
// Symmetric inverse of LKMCPBridgeAttributeEncoder: turns the wire
// `{ kind, data }` shape that a bridge client uses to express an
// attribute write back into the polymorphic Objective-C value that
// LookinAttributeModification carries to the inspected server
// (RPC 204).
//
// Layout: one entry point (`decode(wireKind:wireData:expectedAttrType:)`)
// switches on `(kind, attrType)` and produces the right NSNumber /
// NSString / NSValue / NSArray. The function is `throws`; the thrown
// errors are mapped to structured `modify.*` wire codes by the
// invocation service so agents see precise reasons.
//
// v0.4 scope: integer / double / bool / string / selector / class /
// point / vector / size / rect / transform / edgeInsets / offset /
// color / enum. The structurally-richer kinds (shadow / json / custom)
// are deliberately rejected with `unsupportedKind`; supporting them
// safely requires a per-attribute schema that the bridge doesn't yet
// have.

import CoreGraphics
import Foundation

@MainActor
enum LKMCPBridgeAttributeValueDecoder {

    // MARK: - Errors

    enum DecodeError: Error {
        /// The wire `kind` is one of the v0.4 unsupported categories
        /// (shadow / custom / json) or a string the encoder never
        /// produces.
        case unsupportedKind(String)

        /// The wire `kind` is valid in isolation but does not match
        /// the attribute's declared `LookinAttrType`. E.g. wire says
        /// `"color"` but the attribute is `LookinAttrTypeBOOL`.
        case kindMismatch(wireKind: String, expectedAttrType: LookinAttrType)

        /// The wire `data` payload is missing required fields or
        /// carries the wrong JSON shape for its `kind` (e.g. an `int`
        /// where an object is expected).
        case shapeInvalid(reason: String)
    }

    // MARK: - Entry point

    /// Decodes a `(wireKind, wireData)` pair into the polymorphic id
    /// value that `LookinAttributeModification.value` requires,
    /// validated against `expectedAttrType`. Throws on any
    /// inconsistency; the caller turns the throw into a structured
    /// bridge error.
    static func decode(
        wireKind: String,
        wireData: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        switch wireKind {
        case "integer":
            return try decodeInteger(wireData, expectedAttrType: expectedAttrType)
        case "double":
            return try decodeDouble(wireData, expectedAttrType: expectedAttrType)
        case "bool":
            return try decodeBool(wireData, expectedAttrType: expectedAttrType)
        case "string":
            return try decodeString(wireData, expectedAttrType: expectedAttrType, allowedTypes: [.nsString])
        case "selector":
            return try decodeString(wireData, expectedAttrType: expectedAttrType, allowedTypes: [.sel])
        case "class":
            return try decodeString(wireData, expectedAttrType: expectedAttrType, allowedTypes: [.class])
        case "enum":
            return try decodeEnum(wireData, expectedAttrType: expectedAttrType)
        case "point":
            return try decodePoint(wireData, expectedAttrType: expectedAttrType)
        case "vector":
            return try decodeVector(wireData, expectedAttrType: expectedAttrType)
        case "size":
            return try decodeSize(wireData, expectedAttrType: expectedAttrType)
        case "rect":
            return try decodeRect(wireData, expectedAttrType: expectedAttrType)
        case "transform":
            return try decodeAffineTransform(wireData, expectedAttrType: expectedAttrType)
        case "edgeInsets":
            return try decodeEdgeInsets(wireData, expectedAttrType: expectedAttrType)
        case "offset":
            return try decodeOffset(wireData, expectedAttrType: expectedAttrType)
        case "color":
            return try decodeColor(wireData, expectedAttrType: expectedAttrType)
        case "shadow", "json", "custom":
            throw DecodeError.unsupportedKind(wireKind)
        default:
            throw DecodeError.unsupportedKind(wireKind)
        }
    }

    // MARK: - Numeric kinds

    private static let integerCompatibleTypes: Set<LookinAttrType> = [
        .char, .int, .short, .long, .longLong,
        .unsignedChar, .unsignedInt, .unsignedShort,
        .unsignedLong, .unsignedLongLong,
    ]

    private static func decodeInteger(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard integerCompatibleTypes.contains(expectedAttrType) else {
            throw DecodeError.kindMismatch(wireKind: "integer", expectedAttrType: expectedAttrType)
        }
        guard let data else {
            throw DecodeError.shapeInvalid(reason: "integer value missing")
        }
        switch data {
        case .integer(let value):
            return NSNumber(value: value)
        case .double(let value):
            // Tolerate Double when JSON decode coerced it; truncate.
            return NSNumber(value: Int64(value))
        default:
            throw DecodeError.shapeInvalid(reason: "integer expects a JSON number")
        }
    }

    private static let doubleCompatibleTypes: Set<LookinAttrType> = [.float, .double]

    private static func decodeDouble(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard doubleCompatibleTypes.contains(expectedAttrType) else {
            throw DecodeError.kindMismatch(wireKind: "double", expectedAttrType: expectedAttrType)
        }
        guard let data else {
            throw DecodeError.shapeInvalid(reason: "double value missing")
        }
        switch data {
        case .double(let value):
            return NSNumber(value: value)
        case .integer(let value):
            return NSNumber(value: Double(value))
        default:
            throw DecodeError.shapeInvalid(reason: "double expects a JSON number")
        }
    }

    private static func decodeBool(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard expectedAttrType == .BOOL else {
            throw DecodeError.kindMismatch(wireKind: "bool", expectedAttrType: expectedAttrType)
        }
        guard case .bool(let value)? = data else {
            throw DecodeError.shapeInvalid(reason: "bool expects a JSON boolean")
        }
        return NSNumber(value: value)
    }

    // MARK: - String-ish kinds

    private static func decodeString(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType,
        allowedTypes: Set<LookinAttrType>
    ) throws -> Any {
        guard allowedTypes.contains(expectedAttrType) else {
            let wireKind: String
            switch allowedTypes.first {
            case .nsString: wireKind = "string"
            case .sel:      wireKind = "selector"
            case .class:    wireKind = "class"
            default:        wireKind = "string"
            }
            throw DecodeError.kindMismatch(wireKind: wireKind, expectedAttrType: expectedAttrType)
        }
        guard case .string(let value)? = data else {
            throw DecodeError.shapeInvalid(reason: "string-kind value expects a JSON string")
        }
        return value as NSString
    }

    // MARK: - Enums

    private static let enumNumericTypes: Set<LookinAttrType> = [.enumInt, .enumLong]

    private static func decodeEnum(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        switch expectedAttrType {
        case .enumInt, .enumLong:
            // Numeric enum: wire data is an integer (raw case value).
            guard let data else {
                throw DecodeError.shapeInvalid(reason: "enum value missing")
            }
            switch data {
            case .integer(let value):
                return NSNumber(value: value)
            case .double(let value):
                return NSNumber(value: Int64(value))
            default:
                throw DecodeError.shapeInvalid(reason: "numeric enum expects a JSON integer")
            }
        case .enumString:
            guard case .string(let value)? = data else {
                throw DecodeError.shapeInvalid(reason: "string enum expects a JSON string case name")
            }
            return value as NSString
        default:
            throw DecodeError.kindMismatch(wireKind: "enum", expectedAttrType: expectedAttrType)
        }
    }

    // MARK: - Geometry

    private static func decodePoint(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard expectedAttrType == .cgPoint else {
            throw DecodeError.kindMismatch(wireKind: "point", expectedAttrType: expectedAttrType)
        }
        let object = try requireObject(data, fieldName: "point")
        let x = try requireDouble(object["x"], fieldName: "point.x")
        let y = try requireDouble(object["y"], fieldName: "point.y")
        return NSValue(point: CGPoint(x: x, y: y))
    }

    private static func decodeVector(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard expectedAttrType == .cgVector else {
            throw DecodeError.kindMismatch(wireKind: "vector", expectedAttrType: expectedAttrType)
        }
        let object = try requireObject(data, fieldName: "vector")
        let dx = try requireDouble(object["dx"], fieldName: "vector.dx")
        let dy = try requireDouble(object["dy"], fieldName: "vector.dy")
        return boxStruct(CGVector(dx: dx, dy: dy), objCType: "{CGVector=dd}")
    }

    private static func decodeSize(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard expectedAttrType == .cgSize else {
            throw DecodeError.kindMismatch(wireKind: "size", expectedAttrType: expectedAttrType)
        }
        let object = try requireObject(data, fieldName: "size")
        let width = try requireDouble(object["width"], fieldName: "size.width")
        let height = try requireDouble(object["height"], fieldName: "size.height")
        return NSValue(size: CGSize(width: width, height: height))
    }

    private static func decodeRect(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard expectedAttrType == .cgRect else {
            throw DecodeError.kindMismatch(wireKind: "rect", expectedAttrType: expectedAttrType)
        }
        let object = try requireObject(data, fieldName: "rect")
        let x = try requireDouble(object["x"], fieldName: "rect.x")
        let y = try requireDouble(object["y"], fieldName: "rect.y")
        let width = try requireDouble(object["width"], fieldName: "rect.width")
        let height = try requireDouble(object["height"], fieldName: "rect.height")
        return NSValue(rect: CGRect(x: x, y: y, width: width, height: height))
    }

    private static func decodeAffineTransform(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard expectedAttrType == .cgAffineTransform else {
            throw DecodeError.kindMismatch(wireKind: "transform", expectedAttrType: expectedAttrType)
        }
        let object = try requireObject(data, fieldName: "transform")
        let a = try requireDouble(object["a"], fieldName: "transform.a")
        let b = try requireDouble(object["b"], fieldName: "transform.b")
        let c = try requireDouble(object["c"], fieldName: "transform.c")
        let d = try requireDouble(object["d"], fieldName: "transform.d")
        let tx = try requireDouble(object["tx"], fieldName: "transform.tx")
        let ty = try requireDouble(object["ty"], fieldName: "transform.ty")
        let transform = CGAffineTransform(a: CGFloat(a), b: CGFloat(b), c: CGFloat(c), d: CGFloat(d), tx: CGFloat(tx), ty: CGFloat(ty))
        return boxStruct(transform, objCType: "{CGAffineTransform=dddddd}")
    }

    private static func decodeEdgeInsets(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard expectedAttrType == .uiEdgeInsets else {
            throw DecodeError.kindMismatch(wireKind: "edgeInsets", expectedAttrType: expectedAttrType)
        }
        let object = try requireObject(data, fieldName: "edgeInsets")
        let top    = try requireDouble(object["top"],    fieldName: "edgeInsets.top")
        let left   = try requireDouble(object["left"],   fieldName: "edgeInsets.left")
        let bottom = try requireDouble(object["bottom"], fieldName: "edgeInsets.bottom")
        let right  = try requireDouble(object["right"],  fieldName: "edgeInsets.right")
        // UIEdgeInsets and NSEdgeInsets share memory layout: top / left
        // / bottom / right as four CGFloats. The server-side handler
        // reads back via a cross-platform `InsetsValue` helper that
        // accepts either objCType string.
        var insets: (CGFloat, CGFloat, CGFloat, CGFloat) = (CGFloat(top), CGFloat(left), CGFloat(bottom), CGFloat(right))
        return withUnsafeBytes(of: &insets) { rawBuffer -> NSValue in
            return NSValue(bytes: rawBuffer.baseAddress!, objCType: "{UIEdgeInsets=dddd}")
        }
    }

    private static func decodeOffset(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard expectedAttrType == .uiOffset else {
            throw DecodeError.kindMismatch(wireKind: "offset", expectedAttrType: expectedAttrType)
        }
        let object = try requireObject(data, fieldName: "offset")
        let horizontal = try requireDouble(object["horizontal"], fieldName: "offset.horizontal")
        let vertical   = try requireDouble(object["vertical"],   fieldName: "offset.vertical")
        // UIOffset layout: two CGFloats.
        var offset: (CGFloat, CGFloat) = (CGFloat(horizontal), CGFloat(vertical))
        return withUnsafeBytes(of: &offset) { rawBuffer -> NSValue in
            return NSValue(bytes: rawBuffer.baseAddress!, objCType: "{UIOffset=dd}")
        }
    }

    // MARK: - Color

    private static func decodeColor(
        _ data: LKMCPBridgeJSONValue?,
        expectedAttrType: LookinAttrType
    ) throws -> Any {
        guard expectedAttrType == .uiColor else {
            throw DecodeError.kindMismatch(wireKind: "color", expectedAttrType: expectedAttrType)
        }
        let object = try requireObject(data, fieldName: "color")
        let red   = try requireDouble(object["red"],   fieldName: "color.red")
        let green = try requireDouble(object["green"], fieldName: "color.green")
        let blue  = try requireDouble(object["blue"],  fieldName: "color.blue")
        let alpha = try requireDouble(object["alpha"], fieldName: "color.alpha")
        // Server reconstructs the platform-specific color via
        // `+[LookinColor lks_colorFromRGBAComponents:]`, which expects
        // an NSArray<NSNumber*> in RGBA order, components in 0.0...1.0.
        return [
            NSNumber(value: red),
            NSNumber(value: green),
            NSNumber(value: blue),
            NSNumber(value: alpha),
        ] as NSArray
    }

    // MARK: - Helpers

    private static func requireObject(
        _ data: LKMCPBridgeJSONValue?,
        fieldName: String
    ) throws -> [String: LKMCPBridgeJSONValue] {
        guard case .object(let object)? = data else {
            throw DecodeError.shapeInvalid(reason: "\(fieldName) expects a JSON object")
        }
        return object
    }

    private static func requireDouble(
        _ data: LKMCPBridgeJSONValue?,
        fieldName: String
    ) throws -> Double {
        guard let data else {
            throw DecodeError.shapeInvalid(reason: "\(fieldName) is missing")
        }
        switch data {
        case .double(let value):
            return value
        case .integer(let value):
            return Double(value)
        default:
            throw DecodeError.shapeInvalid(reason: "\(fieldName) expects a JSON number")
        }
    }

    private static func boxStruct<StructType>(
        _ value: StructType,
        objCType: String
    ) -> NSValue {
        var copy = value
        return withUnsafeBytes(of: &copy) { rawBuffer -> NSValue in
            return NSValue(bytes: rawBuffer.baseAddress!, objCType: objCType)
        }
    }
}
