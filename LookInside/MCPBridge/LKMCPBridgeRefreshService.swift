// LKMCPBridgeRefreshService.swift
//
// Handles the `hierarchy.refresh` bridge route: re-fetching the target
// app's whole view tree (RPC 202) and handing it to the host's data
// source, which is exactly what the inspector's toolbar reload button
// does.
//
// Why this needs to exist at all: LookInside is a manual-refresh
// inspector by design. Nothing polls the target and nothing pushes "the
// UI changed" — the host's tree is whatever the last fetch produced. A
// human closes that gap by clicking reload; before this route an agent
// had no equivalent and could only read a snapshot that silently went
// stale the moment the app navigated.
//
// This service is deliberately NOT folded into `LKMCPBridgeInspectionService`.
// That service is pure cached reads with no RPC; refresh round-trips to
// the target and mutates host state, and merging them would quietly
// retire the "the read surface never emits RPC" property.
//
// The actual reload is not reimplemented here. It runs through
// `LKStaticWindowController.reloadHierarchy(initiator:)`, the same method
// the toolbar button calls, so both paths share one re-entrancy gate
// and one fetch chain. Duplicating the chain in Swift would have left two
// copies to drift apart, and writing the window controller's private
// `isFetchingHierarchy` flag from here would have meant this service
// silently driving the host's toolbar enablement.

import AppKit
import Foundation
import os

@MainActor
final class LKMCPBridgeRefreshService {
    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Refresh")

    init() {}

    // MARK: - Entry point

    func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
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

        guard let document = LKMCPBridgeLiveDocumentLookup.findLiveDocument(targetIdentifier: targetIdentifier) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.targetNotFound",
                    message: "No live inspection document found for target identifier \(targetIdentifier)."
                )
            )
        }

        guard let windowController = document.staticWindowController else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.notReady",
                    message: "Live document has no inspector window yet."
                )
            )
        }

        // Read the old size before starting: the data source is replaced
        // in place during the reload, so after the fact there is nothing
        // left to compare against.
        let previousNodeCount = document.hierarchyDataSource?.rawFlatItems?.count ?? 0

        let startInstant = ContinuousClock.now
        do {
            // Stamps `lastReloadInitiator` on the window controller, which
            // is what lets the event publisher label the resulting
            // `hierarchy.reloaded` event as the caller's own echo rather
            // than as news about the app.
            //
            // The value is discarded: by the time it arrives the window
            // controller has already handed it to the data source, and
            // everything reported below is read back from there so the
            // response describes the host's settled state rather than the
            // wire payload.
            _ = try await windowController.reloadHierarchy(initiator: .agent)
        } catch {
            return .failure(identifier: identifier, error: mapRefreshError(error as NSError))
        }
        let elapsedComponents = (ContinuousClock.now - startInstant).components
        let durationMilliseconds = Int(elapsedComponents.seconds) * 1000
            + Int(elapsedComponents.attoseconds / 1_000_000_000_000_000)

        let rootIdentifiers = LKMCPBridgeLiveDocumentLookup
            .topLevelDisplayItems(in: document)
            .map { LKMCPBridgeLiveDocumentLookup.objectIdentifierString(for: $0) }

        let result = LKMCPBridgeRefreshResult(
            targetIdentifier: targetIdentifier,
            rootObjectIdentifiers: rootIdentifiers,
            nodeCount: document.hierarchyDataSource?.rawFlatItems?.count ?? 0,
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
        // Two domains reach here. The window controller's own domain means
        // the host declined to start; `LookinErrorDomain` means the target
        // app failed the fetch. Keeping them apart matters to the caller:
        // the first is worth retrying in a moment, the second usually is
        // not.
        typealias ReloadError = LKStaticWindowController.ReloadError
        if error.domain == ReloadError.domain {
            switch error.code {
            case ReloadError.alreadyInProgress:
                return LKMCPBridgeErrorPayload(
                    code: "refresh.alreadyInProgress",
                    message: "A hierarchy reload is already running for this target — either a user clicked reload or another refresh call is still in flight. Retry once it settles."
                )
            case ReloadError.detailSyncInProgress:
                return LKMCPBridgeErrorPayload(
                    code: "refresh.detailSyncInProgress",
                    message: "The inspector is still syncing view details. Reloading now would discard that work; wait for it to finish."
                )
            case ReloadError.noInspectableApp:
                return LKMCPBridgeErrorPayload(
                    code: "refresh.notAttached",
                    message: "The inspector window is not attached to an app. Attach a target in LookInside and try again."
                )
            case ReloadError.windowClosed:
                return LKMCPBridgeErrorPayload(
                    code: "refresh.windowClosed",
                    message: "The inspector window closed while the hierarchy was being fetched, so the result was discarded."
                )
            case ReloadError.noResponse:
                return LKMCPBridgeErrorPayload(
                    code: "refresh.disconnected",
                    message: "The target app finished the hierarchy request without returning a hierarchy. The channel may have been closed mid-request."
                )
            default:
                Self.logger.error("hierarchy.refresh received unmapped host refusal \(error.code, privacy: .public)")
                return LKMCPBridgeErrorPayload(
                    code: "refresh.internalError",
                    message: "The inspector declined the reload for an unexpected reason (code \(error.code))."
                )
            }
        }

        switch error.code {
        case LookinErrCode_LicenseRequired:
            return .licenseRequired
        case LookinErrCode_NoConnect:
            return LKMCPBridgeErrorPayload(
                code: "refresh.disconnected",
                message: "The target app is no longer connected. Re-attach from the LookInside inspector and try again."
            )
        case LookinErrCode_Timeout:
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
