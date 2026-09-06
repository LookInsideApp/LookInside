// Refreshes the shared inspection session. Its complete hierarchy replaces the
// cache before a response is returned; graphical clients subscribe independently.

import AppKit
import Foundation
import LookInsideInspectionCore
import os

@MainActor
public final class LKMCPBridgeRefreshService {
    // MARK: - Constants pulled from upstream LookinDefines.h

    //
    // Re-declared rather than imported, matching the other RPC-emitting
    // services: pulling LookinDefines.h into the bridging header would
    // touch every Swift compilation in the target.

    /// `LookinErrCode_NoConnect` from `LookinDefines.h:128`.
    private static let lookinErrCodeNoConnect = -403

    /// `LookinErrCode_Timeout` from `LookinDefines.h:132`.
    private static let lookinErrCodeTimeout = -405

    /// `LookinErrCode_LicenseRequired` from `LookinDefines.h:153`.
    private static let lookinErrCodeLicenseRequired = -408

    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Refresh")

    public init() {}

    // MARK: - Entry point

    public func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
        guard request.method == "hierarchy.refresh" else {
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
        return await handleHierarchyRefresh(
            identifier: request.identifier,
            parameters: request.parameters
        )
    }

    // MARK: - hierarchy.refresh

    private func handleHierarchyRefresh(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) async -> LKMCPBridgeResponse {
        guard let parameters = parameters,
              case let .string(targetIdentifier)? = parameters["targetIdentifier"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        guard let session = InspectionSessionLookup.findSession(targetIdentifier: targetIdentifier) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.targetNotFound",
                    message: "No inspection session found for target identifier \(targetIdentifier)."
                )
            )
        }

        // Compare against the previous complete session snapshot.
        let previousNodeCount = session.rawFlatItems?.count ?? 0

        let signal = session.refreshHierarchy(initiator: "agent")

        let startInstant = ContinuousClock.now
        do {
            // Completion means the session committed a complete snapshot.
            _ = try await LKMCPBridgeRACBridge.awaitFirstValue(of: signal, as: AnyObject.self)
        } catch RACBridgeError.completedWithoutValue {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "refresh.disconnected",
                    message: "The target app did not return a hierarchy. The channel may have been closed mid-request."
                )
            )
        } catch RACBridgeError.cancelled {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "refresh.cancelled",
                    message: "The refresh was cancelled before the target app produced a hierarchy."
                )
            )
        } catch let error as NSError {
            // Must stay below the RACBridgeError clauses. Every Swift error
            // bridges to NSError, so this pattern matches everything -- above
            // them it silently swallows both, and they become dead code.
            return .failure(identifier: identifier, error: mapRefreshError(error))
        } catch {
            Self.logger.error("hierarchy.refresh bridge error: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
        let elapsedComponents = (ContinuousClock.now - startInstant).components
        let durationMilliseconds = Int(elapsedComponents.seconds) * 1000
            + Int(elapsedComponents.attoseconds / 1_000_000_000_000_000)

        let rootIdentifiers = InspectionSessionLookup
            .topLevelDisplayItems(in: session)
            .map { InspectionSessionLookup.objectIdentifierString(for: $0) }

        let result = LKMCPBridgeRefreshResult(
            targetIdentifier: targetIdentifier,
            rootObjectIdentifiers: rootIdentifiers,
            nodeCount: session.rawFlatItems?.count ?? 0,
            previousNodeCount: previousNodeCount,
            durationMilliseconds: durationMilliseconds
        )

        do {
            let payload = try encodeAsJSONValue(result)
            return .success(identifier: identifier, result: payload)
        } catch {
            Self.logger.error("hierarchy.refresh encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    // MARK: - Error mapping

    private func mapRefreshError(_ error: NSError) -> LKMCPBridgeErrorPayload {
        if let sessionError = InspectionSessionLookup.errorPayload(for: error, operation: "refresh") {
            return sessionError
        }
        // Session errors above describe local state; these are remote errors.
        switch error.code {
        case Self.lookinErrCodeLicenseRequired:
            return .licenseRequired
        case Self.lookinErrCodeNoConnect:
            return LKMCPBridgeErrorPayload(
                code: "refresh.disconnected",
                message: "The target app is no longer connected. Re-attach from the LookInside inspector and try again."
            )
        case Self.lookinErrCodeTimeout:
            return LKMCPBridgeErrorPayload(
                code: "refresh.timeout",
                message: "The target app did not return its hierarchy within the request timeout. Check whether it is paused in Xcode or blocked on the main thread."
            )
        default:
            Self.logger.error("hierarchy.refresh received unmapped error code \(error.code, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return LKMCPBridgeErrorPayload(
                code: "refresh.internalError",
                message: "The target app reported an unexpected error (code \(error.code))."
            )
        }
    }

    // MARK: - Encoding helper (duplicated from InspectionService)

    private func encodeAsJSONValue(_ value: some Encodable) throws -> LKMCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(LKMCPBridgeJSONValue.self, from: data)
    }
}
