import Foundation

public struct InspectionMetadata: Codable, Sendable {
    public static let currentSchemaVersion = 1
    public let schemaVersion: Int
    public let serviceInstanceIdentifier: String?
    public let sessionIdentifier: String?
    public let connectionGeneration: UInt64?
    public let hierarchyRevision: UInt64?
    public let captureDate: Date?
    public let fromCache: Bool?
    public let requiresRefresh: Bool?

    public init(
        serviceInstanceIdentifier: String? = nil,
        sessionIdentifier: String? = nil,
        connectionGeneration: UInt64? = nil,
        hierarchyRevision: UInt64? = nil,
        captureDate: Date? = nil,
        fromCache: Bool? = nil,
        requiresRefresh: Bool? = nil
    ) {
        schemaVersion = Self.currentSchemaVersion
        self.serviceInstanceIdentifier = serviceInstanceIdentifier
        self.sessionIdentifier = sessionIdentifier
        self.connectionGeneration = connectionGeneration
        self.hierarchyRevision = hierarchyRevision
        self.captureDate = captureDate
        self.fromCache = fromCache
        self.requiresRefresh = requiresRefresh
    }
}

public enum InspectionExitStatus {
    public static func code(for failure: InspectionFailure) -> Int32 {
        switch failure.code {
        case "arguments.invalid", "output.invalid", "dispatch.invalidParameters": 2
        case "service.unavailable", "service.incompatible", "service.launchFailed",
             "service.invalidPath", "service.invalidResponse": 3
        case "target.notFound", "session.notFound", "session.disconnected", "object.notFound": 4
        case "license.entitlementRequired", "license.interactionRequired",
             "license.helperUnavailable", "license.invalidClient": 5
        case "operation.timeout": 6
        case "session.inUse", "session.stale", "service.inUse", "service.ownerConflict", "service.restarted": 7
        default: 1
        }
    }
}

public enum InspectionCapabilities {
    public static let methods = [
        "service.status", "targets.discover", "sessions.open", "sessions.list", "sessions.close",
        "hierarchy.read", "hierarchy.refresh", "views.find", "attributes.read", "screenshot.read",
        "ping", "targets.list", "targets.attach", "targets.detach", "targets.models",
        "hierarchy.find", "details.read", "selectors.list", "invoke.method", "attribute.modify",
        "sessions.retain", "sessions.release", "session.state", "session.events", "session.request",
        "session.captureOptions", "hierarchy.capture", "hierarchy.details", "hierarchy.cachedDetails",
        "transfer.begin", "transfer.append", "transfer.read", "transfer.release",
        "authorization.request",
    ]

    public static func validate(_ status: InspectionResponse, supporting method: String) throws {
        guard status.error == nil,
              let instanceIdentifier = status.metadata?.serviceInstanceIdentifier, !instanceIdentifier.isEmpty,
              let result = status.result?.objectValue,
              result["protocolVersion"]?.integerValue == Int64(InspectionMetadata.currentSchemaVersion),
              case let .array(methods) = result["methods"],
              methods.contains(.string(method))
        else {
            throw InspectionFailure(code: "service.incompatible", message: "The running service does not support this CLI command. Finish existing sessions and restart the service using the same LookInside installation.")
        }
    }
}

public extension InspectionValue {
    var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    var integerValue: Int64? {
        guard case let .integer(value) = self else { return nil }
        return value
    }

    var booleanValue: Bool? {
        guard case let .bool(value) = self else { return nil }
        return value
    }

    var objectValue: [String: InspectionValue]? {
        guard case let .object(value) = self else { return nil }
        return value
    }
}
