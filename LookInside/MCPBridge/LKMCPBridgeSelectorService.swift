// LKMCPBridgeSelectorService.swift
//
// Handles the `selectors.list` bridge route: enumerating the Objective-C
// methods a class in the target app responds to (RPC 213
// `LookinRequestTypeAllSelectorNames`).
//
// This route exists to make `invoke.method` usable. Without it an agent
// has to guess selector names from the class name and discover its
// mistakes one `invoke.invalidSelector` at a time; with it the agent can
// read the actual method table first. The two routes are kept in separate
// services because this one is read-only and `invoke.method` is not — the
// tool-level `destructive` hint on the MCP side follows that same split.
//
// Sizing note: the server walks the class chain all the way to `NSObject`
// and returns one flat, de-duplicated array. For a `UIView` subclass that
// is comfortably four digits of selectors, which is why this route
// defaults to a filtered, truncated view and always reports `totalCount`.

import AppKit
import Foundation
import LookInsideInspectionCore
import os

@MainActor
public final class LKMCPBridgeSelectorService {
    // MARK: - Constants pulled from upstream LookinDefines.h

    //
    // Re-declared rather than imported for the same reason as in
    // `LKMCPBridgeInvocationService`: pulling LookinDefines.h into the
    // bridging header would touch every Swift compilation in the target.

    /// `LookinErrCode_Inner` from `LookinDefines.h:124`. RPC 213 emits
    /// this for exactly one condition — `NSClassFromString` returned nil,
    /// i.e. the class does not exist in the target process.
    private static let lookinErrCodeInner = -401

    /// `LookinErrCode_LicenseRequired` from `LookinDefines.h:153`.
    private static let lookinErrCodeLicenseRequired = -408

    /// `LookinErrCode_NoConnect` from `LookinDefines.h:128`.
    private static let lookinErrCodeNoConnect = -403

    /// `LookinErrCode_Timeout` from `LookinDefines.h:132`.
    private static let lookinErrCodeTimeout = -405

    /// Default cap on returned selectors. Deliberately far below the
    /// thousands a framework class yields: the useful answer to "what can
    /// I call on this" is nearly always reachable with a `nameFilter`,
    /// and an unfiltered dump would cost more context than it is worth.
    private static let defaultSelectorLimit = 200

    /// Ceiling on `limit`.
    private static let maximumSelectorLimit = 2000

    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Selectors")

    public init() {}

    // MARK: - Entry point

    public func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
        guard request.method == "selectors.list" else {
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
        return await handleSelectorsList(
            identifier: request.identifier,
            parameters: request.parameters
        )
    }

    // MARK: - selectors.list

    private func handleSelectorsList(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) async -> LKMCPBridgeResponse {
        guard let parameters = parameters,
              case let .string(targetIdentifier)? = parameters["targetIdentifier"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        let requestedClassName: String?
        if case let .string(raw)? = parameters["className"] {
            requestedClassName = raw
        } else {
            requestedClassName = nil
        }

        let requestedObjectIdentifier: String?
        if case let .string(raw)? = parameters["objectIdentifier"] {
            requestedObjectIdentifier = raw
        } else {
            requestedObjectIdentifier = nil
        }

        if requestedClassName == nil, requestedObjectIdentifier == nil {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "selectors.missingSubject",
                    message: "Supply either `className` or `objectIdentifier` to name the class whose selectors you want."
                )
            )
        }

        let includeArguments: Bool
        if case let .bool(raw)? = parameters["includeArguments"] {
            includeArguments = raw
        } else {
            includeArguments = false
        }

        let nameFilter: String?
        if case let .string(raw)? = parameters["nameFilter"] {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            nameFilter = trimmed.isEmpty ? nil : trimmed
        } else {
            nameFilter = nil
        }

        let selectorLimit: Int
        switch parameters["limit"] {
        case let .integer(raw)?:
            selectorLimit = Int(raw)
        case let .double(raw)?:
            selectorLimit = Int(raw)
        case nil:
            selectorLimit = Self.defaultSelectorLimit
        default:
            return .failure(identifier: identifier, error: .invalidParameters)
        }
        guard selectorLimit >= 1, selectorLimit <= Self.maximumSelectorLimit else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "selectors.invalidLimit",
                    message: "`limit` must be between 1 and \(Self.maximumSelectorLimit); received \(selectorLimit)."
                )
            )
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

        // Resolve the subject class. `objectIdentifier` wins when both are
        // present: it is the more specific request, and it lets the
        // response carry the object's whole class chain.
        let resolvedClassName: String
        let resolvedClassChain: [String]?
        if let requestedObjectIdentifier {
            guard session.captureDate != nil else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "hierarchy.notReady",
                        message: "Live session has not loaded a hierarchy yet."
                    )
                )
            }
            guard let displayItem = InspectionSessionLookup.findDisplayItem(
                amongRoots: InspectionSessionLookup.topLevelDisplayItems(in: session),
                matchingObjectIdentifier: requestedObjectIdentifier
            ) else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "hierarchy.objectNotFound",
                        message: "Object identifier \(requestedObjectIdentifier) is not present in this target's hierarchy."
                    )
                )
            }
            let classChain = displayItem.displayingObject()?.classChainList ?? []
            guard let leafClassName = classChain.first, leafClassName.isEmpty == false else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "selectors.classNotFound",
                        message: "Display item \(requestedObjectIdentifier) does not report a class name."
                    )
                )
            }
            resolvedClassName = leafClassName
            resolvedClassChain = classChain
        } else {
            let className = requestedClassName ?? ""
            guard className.isEmpty == false else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "selectors.missingSubject",
                        message: "`className` must be a non-empty class name."
                    )
                )
            }
            resolvedClassName = className
            resolvedClassChain = nil
        }

        // `hasArg` on the wire means "do not filter out selectors that
        // take arguments", so it maps straight onto `includeArguments`.
        guard let signal = session.inspectableApp.fetchSelectorNames(
            withClass: resolvedClassName,
            hasArg: includeArguments
        ) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "selectors.internalError",
                    message: "The target's inspectable app returned no signal for the selector query."
                )
            )
        }

        let rawSelectors: NSArray
        do {
            rawSelectors = try await LKMCPBridgeRACBridge.awaitFirstValue(of: signal, as: NSArray.self)
        } catch RACBridgeError.completedWithoutValue {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "selectors.disconnected",
                    message: "The target app did not return a selector list. The channel may have been closed mid-request."
                )
            )
        } catch RACBridgeError.cancelled {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "selectors.cancelled",
                    message: "The selector query was cancelled before the target app produced a result."
                )
            )
        } catch let error as NSError {
            // Must stay below the RACBridgeError clauses. Every Swift error
            // bridges to NSError, so this pattern matches everything -- above
            // them it silently swallows both, and they become dead code.
            return .failure(
                identifier: identifier,
                error: mapSelectorError(error, className: resolvedClassName)
            )
        } catch {
            Self.logger.error("selectors.list bridge error: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }

        // Server order is class-chain order, most-derived first (it walks
        // `superclass` upward and de-duplicates on first sight). Preserved
        // rather than sorted: position is the only hint about which class
        // a selector came from, and alphabetizing would bury the app's own
        // overrides among NSObject's. Measured on NSClipView (1554
        // zero-argument selectors): its own land in the first 4%,
        // NSObject's in the last 20%. Within one class the order is
        // whatever `class_copyMethodList` returns, so this is a coarse
        // ranking rather than an attribution.
        var selectorNames = rawSelectors.compactMap { $0 as? String }
        if let nameFilter {
            let normalizedFilter = nameFilter.lowercased()
            selectorNames = selectorNames.filter { $0.lowercased().contains(normalizedFilter) }
        }
        let totalCount = selectorNames.count
        let truncatedSelectors = Array(selectorNames.prefix(selectorLimit))

        let result = LKMCPBridgeSelectorListResult(
            className: resolvedClassName,
            selectors: truncatedSelectors,
            totalCount: totalCount,
            truncated: truncatedSelectors.count < totalCount,
            includesArguments: includeArguments,
            classChain: resolvedClassChain
        )

        do {
            let payload = try encodeAsJSONValue(result)
            return .success(identifier: identifier, result: payload)
        } catch {
            Self.logger.error("selectors.list encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    // MARK: - Error mapping

    private func mapSelectorError(_ error: NSError, className: String) -> LKMCPBridgeErrorPayload {
        switch error.code {
        case Self.lookinErrCodeInner:
            // RPC 213's only `Inner` path is a failed NSClassFromString,
            // so this is specific enough to name the cause outright.
            return LKMCPBridgeErrorPayload(
                code: "selectors.classNotFound",
                message: "The target app has no class named `\(className)`. Swift types need their module prefix (for example `MyApp.ContentView`); check the `classChain` reported by hierarchy.read."
            )
        case Self.lookinErrCodeLicenseRequired:
            return .licenseRequired
        case Self.lookinErrCodeNoConnect:
            return LKMCPBridgeErrorPayload(
                code: "selectors.disconnected",
                message: "The target app is no longer connected. Re-attach from the LookInside inspector and try again."
            )
        case Self.lookinErrCodeTimeout:
            return LKMCPBridgeErrorPayload(
                code: "selectors.timeout",
                message: "The target app did not respond within the request timeout. Check whether it is paused in Xcode or blocked on the main thread."
            )
        default:
            Self.logger.error("selectors.list received unmapped error code \(error.code, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return LKMCPBridgeErrorPayload(
                code: "selectors.internalError",
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
