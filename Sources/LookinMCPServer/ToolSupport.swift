import Foundation
import MCP

/// Helpers shared by every tool. Reach for `JSON` whenever you need to build a
/// response object — Codable + JSONEncoder gives us a stable, ordered shape that
/// the agent can rely on. Building literals here keeps tool implementations terse.
enum JSON {
    /// Encodes any Codable value as a compact JSON string with sorted keys.
    static func encode<T: Encodable>(_ value: T) throws -> String {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        let data = try enc.encode(value)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

enum Schema {
    /// Inline JSON Schema builders. Keeping these short makes tool definitions
    /// readable at a glance.
    static let object = "object"
    static let string = "string"
    static let integer = "integer"
    static let boolean = "boolean"

    static func obj(_ properties: [String: Value], required: [String] = []) -> Value {
        var dict: [String: Value] = [
            "type": .string(object),
            "properties": .object(properties),
        ]
        if !required.isEmpty {
            dict["required"] = .array(required.map { .string($0) })
        }
        return .object(dict)
    }

    static func prop(_ type: String, description: String? = nil, enumValues: [String]? = nil) -> Value {
        var dict: [String: Value] = ["type": .string(type)]
        if let d = description { dict["description"] = .string(d) }
        if let e = enumValues { dict["enum"] = .array(e.map { .string($0) }) }
        return .object(dict)
    }

    static let empty: Value = .object(["type": .string(object), "properties": .object([:])])
}

extension Value {
    func asString() -> String? { if case .string(let s) = self { return s }; return nil }
    func asInt() -> Int? {
        switch self {
        case .int(let i): return i
        case .double(let d): return Int(d)
        case .string(let s): return Int(s)
        default: return nil
        }
    }
    func asBool() -> Bool? { if case .bool(let b) = self { return b }; return nil }
    func asUInt() -> UInt? { asInt().flatMap { $0 >= 0 ? UInt($0) : nil } }
}
