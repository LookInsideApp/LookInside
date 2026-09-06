// InspectionFrame.swift
//
// Newline-delimited JSON wire frames spoken on the MCPBridge Unix domain socket.
//
// The schema here is intentionally a generic inspection IPC and MUST NOT
// reference Model Context Protocol concepts (no `tools/list`,
// `resources/subscribe`, `notifications/resources/updated` field names or
// method strings). These types remain part of the GPL host; independent clients
// can implement the wire format without linking this framework.

import Foundation

// MARK: - Envelope

/// Discriminates the three frame kinds carried on the wire.
public enum InspectionFrameKind: String, Sendable, Codable {
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
public struct InspectionRequest: Sendable, Codable {
    public let kind: InspectionFrameKind
    public let identifier: String
    public let method: String
    public let parameters: [String: InspectionValue]?

    public init(kind: InspectionFrameKind = .request, identifier: String, method: String, parameters: [String: InspectionValue]? = nil) {
        self.kind = kind
        self.identifier = identifier
        self.method = method
        self.parameters = parameters
    }

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
public struct InspectionResponse: Sendable, Codable {
    public let kind: InspectionFrameKind
    public let identifier: String
    public let result: InspectionValue?
    public let error: InspectionFailure?
    public let metadata: InspectionMetadata?

    public init(kind: InspectionFrameKind = .response, identifier: String, result: InspectionValue?, error: InspectionFailure?, metadata: InspectionMetadata? = nil) {
        self.kind = kind
        self.identifier = identifier
        self.result = result
        self.error = error
        self.metadata = metadata
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case identifier = "id"
        case result
        case error
        case metadata
    }

    public static func success(identifier: String, result: InspectionValue?) -> InspectionResponse {
        return InspectionResponse(kind: .response, identifier: identifier, result: result, error: nil)
    }

    public static func failure(identifier: String, error: InspectionFailure) -> InspectionResponse {
        return InspectionResponse(kind: .response, identifier: identifier, result: nil, error: error)
    }
}

// MARK: - Event

/// An unsolicited event frame pushed by the server. The `topic` is a dotted
/// path identifying the event category (for example, `hierarchy.invalidated`,
/// `targets.attached`); the `payload` carries topic-specific structure.
public struct InspectionEvent: Sendable, Codable {
    public let kind: InspectionFrameKind
    public let topic: String
    public let payload: [String: InspectionValue]?

    public init(topic: String, payload: [String: InspectionValue]?) {
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
public struct InspectionFailure: Sendable, Codable, Error, Equatable {
    public let code: String
    public let message: String
    public let details: [String: InspectionValue]?

    public init(code: String, message: String, details: [String: InspectionValue]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }

    public static let unknownMethod = InspectionFailure(
        code: "dispatch.unknownMethod",
        message: "The requested method is not implemented by this server."
    )

    public static let invalidParameters = InspectionFailure(
        code: "dispatch.invalidParameters",
        message: "The request parameters could not be decoded into the expected shape."
    )

    public static let licenseRequired = InspectionFailure(
        code: "license.entitlementRequired",
        message: "The connected LookInside license does not include the required entitlement."
    )

    public static let internalError = InspectionFailure(
        code: "dispatch.internalError",
        message: "An unexpected internal error occurred while servicing the request."
    )
}

extension InspectionFailure: CustomNSError {
    public static var errorDomain: String {
        "com.lookinside.inspection"
    }

    public var errorCode: Int {
        Int(InspectionExitStatus.code(for: self))
    }

    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: message, "inspectionFailureCode": code]
    }
}

// MARK: - JSONValue

/// A minimal JSON value type that round-trips through Codable without requiring
/// the inspection schema to be statically typed at the wire layer. Used inside
/// request `parameters`, response `result`, and event `payload` containers so
/// the server can route opaque JSON to method-specific handlers.
public enum InspectionValue: Sendable, Codable, Equatable {
    case null
    case bool(Bool)
    case integer(Int64)
    case double(Double)
    case string(String)
    case array([InspectionValue])
    case object([String: InspectionValue])

    public init(from decoder: Decoder) throws {
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
        } else if let elements = try? container.decode([InspectionValue].self) {
            self = .array(elements)
        } else if let object = try? container.decode([String: InspectionValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Encountered a JSON value that is none of null / bool / number / string / array / object."
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
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
