// LKMCPBridgeFrame.swift
//
// Newline-delimited JSON wire frames spoken on the MCPBridge Unix domain socket.
//
// The schema here is intentionally a generic inspection IPC and MUST NOT
// reference Model Context Protocol concepts (no `tools/list`,
// `resources/subscribe`, `notifications/resources/updated` field names or
// method strings). Keeping this layer generic preserves GPL compatibility for
// reuse by other proprietary or open consumers (CI bridge, remote inspector,
// automation runners).

import Foundation

// MARK: - Envelope

/// Discriminates the three frame kinds carried on the wire.
enum MCPBridgeFrameKind: String, Sendable, Codable {
    case request
    case response
    case event
}

// MARK: - Request

/// A request frame originating from a connected client.
///
/// `identifier` correlates request and response frames; it is opaque to the
/// server and echoed back verbatim. `method` selects an inspection verb on the
/// server side (for example, `targets.list`, `hierarchy.read`).
struct MCPBridgeRequest: Sendable, Codable {
    let kind: MCPBridgeFrameKind
    let identifier: String
    let method: String
    let parameters: [String: MCPBridgeJSONValue]?

    enum CodingKeys: String, CodingKey {
        case kind
        case identifier = "id"
        case method
        case parameters = "params"
    }
}

// MARK: - Response

/// A response frame returned to the client for a previously received request.
///
/// Exactly one of `result` or `error` is set. The server MUST echo the
/// request's `identifier` verbatim.
struct MCPBridgeResponse: Sendable, Codable {
    let kind: MCPBridgeFrameKind
    let identifier: String
    let result: MCPBridgeJSONValue?
    let error: MCPBridgeErrorPayload?

    enum CodingKeys: String, CodingKey {
        case kind
        case identifier = "id"
        case result
        case error
    }

    static func success(identifier: String, result: MCPBridgeJSONValue?) -> MCPBridgeResponse {
        return MCPBridgeResponse(kind: .response, identifier: identifier, result: result, error: nil)
    }

    static func failure(identifier: String, error: MCPBridgeErrorPayload) -> MCPBridgeResponse {
        return MCPBridgeResponse(kind: .response, identifier: identifier, result: nil, error: error)
    }
}

// MARK: - Event

/// An unsolicited event frame pushed by the server. The `topic` is a dotted
/// path identifying the event category (for example, `hierarchy.invalidated`,
/// `targets.attached`); the `payload` carries topic-specific structure.
struct MCPBridgeEvent: Sendable, Codable {
    let kind: MCPBridgeFrameKind
    let topic: String
    let payload: [String: MCPBridgeJSONValue]?

    init(topic: String, payload: [String: MCPBridgeJSONValue]?) {
        kind = .event
        self.topic = topic
        self.payload = payload
    }
}

// MARK: - Error payload

/// A structured error returned in a response frame. Error codes follow a
/// dotted-namespace convention (for example, `dispatch.unknownMethod`,
/// `license.entitlementRequired`); free-form messages may be present for
/// debuggability but must not be relied on for programmatic dispatch.
struct MCPBridgeErrorPayload: Sendable, Codable, Error {
    let code: String
    let message: String

    static let unknownMethod = MCPBridgeErrorPayload(
        code: "dispatch.unknownMethod",
        message: "The requested method is not implemented by this server."
    )

    static let invalidParameters = MCPBridgeErrorPayload(
        code: "dispatch.invalidParameters",
        message: "The request parameters could not be decoded into the expected shape."
    )

    static let licenseRequired = MCPBridgeErrorPayload(
        code: "license.entitlementRequired",
        message: "The connected LookInside license does not include the required entitlement."
    )

    static let internalError = MCPBridgeErrorPayload(
        code: "dispatch.internalError",
        message: "An unexpected internal error occurred while servicing the request."
    )
}

// MARK: - JSONValue

/// A minimal JSON value type that round-trips through Codable without requiring
/// the inspection schema to be statically typed at the wire layer. Used inside
/// request `parameters`, response `result`, and event `payload` containers so
/// the server can route opaque JSON to method-specific handlers.
enum MCPBridgeJSONValue: Sendable, Codable {
    case null
    case bool(Bool)
    case integer(Int64)
    case double(Double)
    case string(String)
    case array([MCPBridgeJSONValue])
    case object([String: MCPBridgeJSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let boolean = try? container.decode(Bool.self) {
            self = .bool(boolean)
        } else if let integer = try? container.decode(Int64.self) {
            self = .integer(integer)
        } else if let floating = try? container.decode(Double.self) {
            self = .double(floating)
        } else if let text = try? container.decode(String.self) {
            self = .string(text)
        } else if let elements = try? container.decode([MCPBridgeJSONValue].self) {
            self = .array(elements)
        } else if let object = try? container.decode([String: MCPBridgeJSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Encountered a JSON value that is none of null / bool / number / string / array / object."
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case let .bool(boolean):
            try container.encode(boolean)
        case let .integer(integer):
            try container.encode(integer)
        case let .double(floating):
            try container.encode(floating)
        case let .string(text):
            try container.encode(text)
        case let .array(elements):
            try container.encode(elements)
        case let .object(object):
            try container.encode(object)
        }
    }
}
