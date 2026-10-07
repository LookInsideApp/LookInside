// LKMCPBridgeInvocationService.swift
//
// Handles the `invoke.method` bridge route: arbitrary zero-argument
// Objective-C selector invocation on a view in an attached target app.
// This is the bridge's first mutating route — it goes over the connection channel
// (RPC 206 `LookinRequestType_InvokeMethod`) and can change the
// inspected app's state. Read-only inspection routes live in
// `LKMCPBridgeInspectionService`; they share the live-document /
// display-item lookup through `LKMCPBridgeLiveDocumentLookup`.
//
// Selector blacklist mirrors `LKConsoleDataSource` (rejects selectors
// containing `:` and `.`). The server enforces a hard zero-argument
// limit on top of that. Anything else — method visibility, naming
// conventions, side-effect ack — is left to the agent and tool-level
// `destructive` hint.

import AppKit
import Foundation
import os

@MainActor
final class LKMCPBridgeInvocationService {
    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Invocation")

    init() {}

    // MARK: - Entry point

    func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
        guard request.method == "invoke.method" else {
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
        return await handleInvokeMethod(
            identifier: request.identifier,
            parameters: request.parameters
        )
    }

    // MARK: - invoke.method

    private func handleInvokeMethod(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) async -> LKMCPBridgeResponse {
        guard let parameters = parameters,
              case let .string(targetIdentifier)? = parameters["targetIdentifier"],
              case let .string(objectIdentifier)? = parameters["objectIdentifier"],
              case let .string(selector)? = parameters["selector"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        if selector.isEmpty {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        // Mirror LKConsoleDataSource's selector blacklist (rejects
        // anything that wouldn't go through RPC 206's zero-argument
        // gate on the server side). Centralizing this here gives a
        // single explicit error code with a hint instead of relying on
        // the server's generic `LookinErrCode_Inner`.
        if selector.contains(":") {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "invoke.unsupportedSelector",
                    message: "Multi-argument selectors (containing ':') are not supported in this release. Use a zero-argument selector or wait for a future bridge method."
                )
            )
        }
        if selector.contains(".") {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "invoke.unsupportedSelector",
                    message: "Dotted access (containing '.') is not supported; pass a single method or property name."
                )
            )
        }

        guard let document = LKMCPBridgeLiveDocumentLookup.findLiveDocument(targetIdentifier: targetIdentifier) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.targetNotFound",
                    message: "No live inspection document found for target identifier \(targetIdentifier)."
                )
            )
        }

        guard document.hierarchyDataSource != nil else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.notReady",
                    message: "Live document has not loaded a hierarchy yet."
                )
            )
        }

        guard let displayItem = LKMCPBridgeLiveDocumentLookup.findDisplayItem(
            amongRoots: LKMCPBridgeLiveDocumentLookup.topLevelDisplayItems(in: document),
            matchingObjectIdentifier: objectIdentifier
        ) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.objectNotFound",
                    message: "Object identifier \(objectIdentifier) is not present in this target's hierarchy."
                )
            )
        }

        // The wire oid is hex-encoded; LKInspectableApp accepts the raw
        // unsigned-long value. Re-derive it from the display item we
        // just resolved so we don't have to parse the wire string —
        // the display item already holds the canonical numeric oid.
        guard let nativeOid = displayItem.displayingObject()?.oid, nativeOid != 0 else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.objectNotFound",
                    message: "Display item \(objectIdentifier) does not carry a live object identifier."
                )
            )
        }

        let redactSecureContent = LKMCPBridgeSecureContentDetector.isSecure(displayItem: displayItem)

        // Sent through `response(type:data:as:)` rather than
        // `invokeMethod(oid:text:)`: that one replaces the Server's
        // void-return marker with a localized sentence, and the marker is
        // what `returnedVoid` is decided from. A missing channel throws
        // `LookinErr_NoConnect`, mapped to `invoke.disconnected` below.
        let rawDictionary: NSDictionary
        do {
            rawDictionary = try await document.inspectableApp.response(
                type: UInt32(LookinRequestTypeInvokeMethod),
                data: LKInspectableApp.invokeMethodParameters(oid: nativeOid, text: selector),
                as: NSDictionary.self
            )
        } catch {
            return .failure(identifier: identifier, error: mapInvocationError(error as NSError))
        }

        let invocationResult = makeInvocationResult(
            from: rawDictionary,
            redactSecureContent: redactSecureContent
        )

        do {
            let payload = try encodeAsJSONValue(invocationResult)
            return .success(identifier: identifier, result: payload)
        } catch {
            Self.logger.error("invoke.method encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    // MARK: - Response shaping

    private func makeInvocationResult(
        from dictionary: NSDictionary,
        redactSecureContent: Bool
    ) -> LKMCPBridgeInvocationResult {
        let rawDescription = dictionary["description"] as? String
        let returnedVoid = rawDescription == LookinStringFlag_VoidReturn

        let surfacedDescription: String?
        if redactSecureContent {
            surfacedDescription = nil
        } else if returnedVoid {
            surfacedDescription = nil
        } else {
            surfacedDescription = rawDescription
        }

        let returnObject = makeReturnedObject(from: dictionary["object"])

        return LKMCPBridgeInvocationResult(
            description: surfacedDescription,
            returnedVoid: returnedVoid,
            returnObject: returnObject,
            secureContent: redactSecureContent
        )
    }

    private func makeReturnedObject(from rawObject: Any?) -> LKMCPBridgeReturnedObject? {
        guard let lookinObject = rawObject as? LookinObject else { return nil }
        let oidString = String(format: "0x%lx", lookinObject.oid)
        return LKMCPBridgeReturnedObject(
            objectIdentifier: oidString,
            memoryAddress: lookinObject.memoryAddress ?? "",
            classChainList: lookinObject.classChainList ?? [],
            specialTrace: lookinObject.specialTrace
        )
    }

    // MARK: - Error mapping

    private func mapInvocationError(_ error: NSError) -> LKMCPBridgeErrorPayload {
        switch error.code {
        case LookinErrCode_ObjectNotFound:
            return LKMCPBridgeErrorPayload(
                code: "invoke.objectNotFound",
                message: "The target app could not find an object for this identifier or it does not respond to the selector. The object may have been deallocated; try reloading the inspector."
            )
        case LookinErrCode_Inner:
            return LKMCPBridgeErrorPayload(
                code: "invoke.invalidSelector",
                message: "The target app rejected the selector — most likely it requires arguments or has no method signature. Only zero-argument selectors are supported."
            )
        case LookinErrCode_LicenseRequired:
            return .licenseRequired
        case LookinErrCode_NoConnect:
            return LKMCPBridgeErrorPayload(
                code: "invoke.disconnected",
                message: "The target app is no longer connected. Re-attach from the LookInside inspector and try again."
            )
        case LookinErrCode_Timeout:
            return LKMCPBridgeErrorPayload(
                code: "invoke.timeout",
                message: "The target app did not respond within the request timeout. Check whether it is paused in Xcode or blocked on the main thread."
            )
        default:
            Self.logger.error("invoke.method received unmapped error code \(error.code, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return LKMCPBridgeErrorPayload(
                code: "invoke.internalError",
                message: "The target app reported an unexpected error (code \(error.code))."
            )
        }
    }

    // MARK: - Encoding helper (duplicated from InspectionService)

    //
    // The two services share the same JSON round-trip helper but they
    // belong to different actor-isolated types, so we keep one copy per
    // service rather than introducing a shared protocol just for two
    // identical four-line helpers.

    private func encodeAsJSONValue(_ value: some Encodable) throws -> LKMCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(LKMCPBridgeJSONValue.self, from: data)
    }
}
