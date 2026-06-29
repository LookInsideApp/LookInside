// LKMCPBridgeInvocationService.swift
//
// Handles the `invoke.method` bridge route: arbitrary zero-argument
// Objective-C selector invocation on a view in an attached target app.
// This is the bridge's first mutating route — it goes over Peertalk
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
public final class LKMCPBridgeInvocationService {

    // MARK: - Constants pulled from upstream LookinDefines.h
    //
    // These are intentionally re-declared here rather than imported via
    // the bridging header: pulling LookinDefines.h into the bridging
    // header would touch every Swift compilation in the host target.
    // The values are part of the wire contract and changing them
    // requires bumping LookinServer's RPC compatibility band, so the
    // duplication cost is low and the blast-radius cost of importing is
    // much higher.

    /// `LookinErrCode_ObjectNotFound` from `LookinDefines.h:139`.
    /// Server returns this when (a) the oid is no longer in
    /// `LKS_ObjectRegistry`, (b) the selector string did not bind, or
    /// (c) the target object does not respond to the selector.
    private static let lookinErrCodeObjectNotFound = -500

    /// `LookinErrCode_Inner` from `LookinDefines.h:124`. For
    /// `invoke.method` specifically the server emits this when the
    /// selector exists but has arguments or has no method signature.
    private static let lookinErrCodeInner = -401

    /// `LookinErrCode_LicenseRequired` from `LookinDefines.h:153`.
    private static let lookinErrCodeLicenseRequired = -408

    /// `LookinErrCode_NoConnect` from `LookinDefines.h:128`.
    private static let lookinErrCodeNoConnect = -403

    /// `LookinErrCode_Timeout` from `LookinDefines.h:132`.
    private static let lookinErrCodeTimeout = -405

    /// `LookinStringFlag_VoidReturn` from `LookinDefines.h:115`.
    /// Server-side sentinel placed in the response's `description` key
    /// when the invoked method's declared return type is `void`. The
    /// bridge translates this into `returnedVoid: true, description: nil`.
    private static let lookinVoidReturnMarker = "LOOKIN_TAG_RETURN_VALUE_VOID"

    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Invocation")

    public init() {}

    // MARK: - Entry point

    public func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
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
              case .string(let targetIdentifier)? = parameters["targetIdentifier"],
              case .string(let objectIdentifier)? = parameters["objectIdentifier"],
              case .string(let selector)? = parameters["selector"]
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

        // Run the RPC. `rawInvokeMethod(withOid:text:)` keeps the raw
        // server-side error codes intact (no localized NSError remap),
        // so the catch block below can build precise bridge error codes.
        // The ObjC implementation itself returns `LookinErr_NoConnect`
        // when `channel` is nil, which we map to `invoke.disconnected`
        // below — so we don't pre-check the channel from Swift (the
        // property is wrapped via FrameworkToolbox @dynamicMemberLookup
        // and isn't reachable on a key-path that we own).
        guard let signal = document.inspectableApp.rawInvokeMethod(withOid: nativeOid, text: selector) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "invoke.internalError",
                    message: "The target's inspectable app returned no signal for the invocation."
                )
            )
        }
        let rawDictionary: NSDictionary
        do {
            rawDictionary = try await LKMCPBridgeRACBridge.awaitFirstValue(of: signal, as: NSDictionary.self)
        } catch let error as NSError {
            return .failure(identifier: identifier, error: mapInvocationError(error))
        } catch RACBridgeError.completedWithoutValue {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "invoke.disconnected",
                    message: "The target app did not return a response. The channel may have been closed mid-invocation."
                )
            )
        } catch RACBridgeError.cancelled {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "invoke.cancelled",
                    message: "The invocation was cancelled before the target app produced a result."
                )
            )
        } catch {
            Self.logger.error("invoke.method bridge error: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
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
        let returnedVoid = rawDescription == Self.lookinVoidReturnMarker

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
        case Self.lookinErrCodeObjectNotFound:
            return LKMCPBridgeErrorPayload(
                code: "invoke.objectNotFound",
                message: "The target app could not find an object for this identifier or it does not respond to the selector. The object may have been deallocated; try reloading the inspector."
            )
        case Self.lookinErrCodeInner:
            return LKMCPBridgeErrorPayload(
                code: "invoke.invalidSelector",
                message: "The target app rejected the selector — most likely it requires arguments or has no method signature. Only zero-argument selectors are supported."
            )
        case Self.lookinErrCodeLicenseRequired:
            return .licenseRequired
        case Self.lookinErrCodeNoConnect:
            return LKMCPBridgeErrorPayload(
                code: "invoke.disconnected",
                message: "The target app is no longer connected. Re-attach from the LookInside inspector and try again."
            )
        case Self.lookinErrCodeTimeout:
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
