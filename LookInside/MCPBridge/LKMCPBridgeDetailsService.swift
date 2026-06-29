// LKMCPBridgeDetailsService.swift
//
// Handles the `details.read` bridge route: actively triggers RPC 203
// `HierarchyDetails` for a batch of object identifiers and returns
// their attribute detail to the agent. Closes the painful "agent
// asked to read / modify a view whose detail the host has not yet
// fetched" loop that v0.4 surfaced as `modify.attributeNotFound`.
//
// Differences from `attributes.read`:
//   - `attributes.read` reads the host's cache as-is; if the host has
//     not seen the view yet, the agent gets an empty `groups` array
//     plus `detailsCached: false`.
//   - `details.read` sends RPC 203 to the inspected app, awaits the
//     full streamed response (one frame per server-side task package),
//     and surfaces every successful view's detail. The same routing
//     also writes the response through
//     `LKStaticHierarchyDataSource.modifyWithDisplayItemDetail:` so
//     subsequent `attributes.read` calls see populated cache and the
//     inspector UI reflects the new state.
//
// Scope: v0.5 only fetches attribute groups (no screenshots, no
// frame/bounds/hidden/alpha, no subitems). Screenshots get their
// own dedicated route; visual info is already in `get_hierarchy`;
// subtree changes are out of scope (agents follow up with
// `get_hierarchy` when they need to.)

import AppKit
import CoreGraphics
import Foundation
import os

@MainActor
public final class LKMCPBridgeDetailsService {

    /// Hard cap on per-call batch size. Matches the host inspector's
    /// own `packageMaxTasksCount` (see `LKStaticAsyncUpdateManager`).
    /// Larger batches are rejected at the wire boundary; agents that
    /// need more issue multiple calls.
    private static let maximumObjectIdentifiersPerCall = 100

    // MARK: - Error code constants from LookinDefines.h
    //
    // See LKMCPBridgeInvocationService for the duplication rationale.

    private static let lookinErrCodeObjectNotFound = -500
    private static let lookinErrCodeInner = -401
    private static let lookinErrCodeLicenseRequired = -408
    private static let lookinErrCodeNoConnect = -403
    private static let lookinErrCodeTimeout = -405

    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Details")

    public init() {}

    // MARK: - Entry point

    public func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
        guard request.method == "details.read" else {
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
        return await handleDetailsRead(
            identifier: request.identifier,
            parameters: request.parameters
        )
    }

    // MARK: - details.read

    private func handleDetailsRead(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) async -> LKMCPBridgeResponse {
        // Parameter extraction
        guard let parameters,
              case .string(let targetIdentifier)? = parameters["targetIdentifier"],
              case .array(let identifierWireValues)? = parameters["objectIdentifiers"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        // Materialize the identifier list as Swift strings; reject if
        // any entry is not a JSON string (loose typing across the wire
        // is fine for primitives but identifiers are critical).
        var requestedIdentifiers: [String] = []
        requestedIdentifiers.reserveCapacity(identifierWireValues.count)
        for entry in identifierWireValues {
            guard case .string(let value) = entry else {
                return .failure(identifier: identifier, error: .invalidParameters)
            }
            requestedIdentifiers.append(value)
        }
        guard requestedIdentifiers.isEmpty == false else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }
        guard requestedIdentifiers.count <= Self.maximumObjectIdentifiersPerCall else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "dispatch.tooMany",
                    message: "details.read accepts at most \(Self.maximumObjectIdentifiersPerCall) object identifiers per call; received \(requestedIdentifiers.count). Split into multiple calls."
                )
            )
        }

        let includeUserCustom: Bool
        if case .bool(let raw)? = parameters["includeUserCustom"] {
            includeUserCustom = raw
        } else {
            includeUserCustom = true
        }

        // Live-document lookup
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

        // Resolve each requested identifier to a display item. Missing
        // identifiers go into failedIdentifiers and skip the server
        // round-trip; the agent learns which oids vanished without the
        // request blowing up entirely.
        let roots = LKMCPBridgeLiveDocumentLookup.topLevelDisplayItems(in: document)
        var resolvedItems: [(identifier: String, displayItem: LookinDisplayItem, nativeOid: UInt)] = []
        resolvedItems.reserveCapacity(requestedIdentifiers.count)
        var failedIdentifiers: [String] = []

        for requested in requestedIdentifiers {
            guard let displayItem = LKMCPBridgeLiveDocumentLookup.findDisplayItem(
                amongRoots: roots,
                matchingObjectIdentifier: requested
            ),
                  let nativeOid = displayItem.displayingObject()?.oid,
                  nativeOid != 0
            else {
                failedIdentifiers.append(requested)
                continue
            }
            resolvedItems.append((identifier: requested, displayItem: displayItem, nativeOid: nativeOid))
        }

        // If everything is gone, surface a structured error instead of
        // an empty success response — the agent likely passed stale oids.
        if resolvedItems.isEmpty {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "details.objectNotFound",
                    message: "None of the requested object identifiers are present in this target's hierarchy. Refresh the hierarchy via get_hierarchy and retry."
                )
            )
        }

        // Build the RPC 203 task package. Single package — we already
        // cap the batch at 100 entries, so the host inspector's own
        // pixel/count packing thresholds never need to come into play.
        let clientReadableVersion = LKHelper.lookinReadableVersion()
        let tasks = resolvedItems.map { resolved -> LookinStaticAsyncUpdateTask in
            let task = LookinStaticAsyncUpdateTask()
            task.oid = resolved.nativeOid
            task.taskType = .noScreenshot
            task.attrRequest = .need
            task.needBasisVisualInfo = false
            task.needSubitems = false
            task.clientReadableVersion = clientReadableVersion
            return task
        }
        let package = LookinStaticAsyncUpdateTasksPackage()
        package.tasks = tasks

        // Round-trip through Peertalk. RPC 203 streams one frame per
        // package; with a single package we expect exactly one frame.
        // Still go through awaitAllValues so the bridge stays robust
        // to future multi-package batching here without touching
        // the await semantics.
        guard let signal = document.inspectableApp.rawFetchHierarchyDetail(withTaskPackages: [package]) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "details.internalError",
                    message: "The target's inspectable app returned no signal for the fetch."
                )
            )
        }

        let frames: [NSArray]
        do {
            frames = try await LKMCPBridgeRACBridge.awaitAllValues(of: signal, as: NSArray.self)
        } catch let error as NSError {
            return .failure(identifier: identifier, error: mapDetailsError(error))
        } catch RACBridgeError.completedWithoutValue {
            // Empty success (server completed before any frame) → treat
            // as zero successful details, all requested identifiers
            // surface as failed.
            return successResponse(
                identifier: identifier,
                details: [],
                failedIdentifiers: requestedIdentifiers
            )
        } catch RACBridgeError.cancelled {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "details.cancelled",
                    message: "The fetch was cancelled before the target app finished streaming details."
                )
            )
        } catch {
            Self.logger.error("details.read bridge error: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }

        // Flatten the per-package arrays into a single ordered list of
        // detail objects.
        var allDetails: [LookinDisplayItemDetail] = []
        allDetails.reserveCapacity(resolvedItems.count)
        for frame in frames {
            for entry in frame {
                if let detail = entry as? LookinDisplayItemDetail {
                    allDetails.append(detail)
                }
            }
        }

        // Index resolved items by native oid so we can match incoming
        // details back to the display item (needed for secureContent
        // detection and for downstream cache merging).
        let itemsByOid: [UInt: (identifier: String, displayItem: LookinDisplayItem, nativeOid: UInt)] = Dictionary(
            uniqueKeysWithValues: resolvedItems.map { ($0.nativeOid, $0) }
        )

        // Resolve the concrete data source once. We thread it through
        // the per-detail loop rather than walking back from each
        // display item, because LookinDisplayItem has no back-reference
        // to its owning document.
        let staticDataSource = document.hierarchyDataSource as? LKStaticHierarchyDataSource

        var emittedDetails: [LKMCPBridgeViewDetail] = []
        emittedDetails.reserveCapacity(allDetails.count)
        var seenOids: Set<UInt> = []

        for detail in allDetails {
            seenOids.insert(detail.displayItemOid)

            // Server-side failure surface: failureCode == -1 means the
            // server couldn't resolve the oid (probably deallocated
            // mid-request). Push it to failedIdentifiers and skip.
            if detail.failureCode == -1 {
                if let resolved = itemsByOid[detail.displayItemOid] {
                    failedIdentifiers.append(resolved.identifier)
                }
                continue
            }

            guard let resolved = itemsByOid[detail.displayItemOid] else {
                // The server emitted a detail for an oid we did not
                // request. Defensive: ignore it.
                continue
            }

            // Merge the detail into the host's cache so the inspector
            // UI reflects the update and a follow-up attributes.read
            // hits the same data without re-fetching.
            staticDataSource?.modify(with: detail)

            // Encode the attribute groups carried in this detail
            // through the read-side encoder so the wire shape matches
            // attributes.read.
            let redactSecureContent = LKMCPBridgeSecureContentDetector.isSecure(displayItem: resolved.displayItem)
            var rawGroups: [LookinAttributesGroup] = []
            if let inbuiltGroups = detail.attributesGroupList {
                rawGroups.append(contentsOf: inbuiltGroups)
            }
            if includeUserCustom, let customGroups = detail.customAttrGroupList {
                rawGroups.append(contentsOf: customGroups)
            }
            let encodedGroups = rawGroups.map { group -> LKMCPBridgeAttributeGroup in
                let sections = (group.attrSections ?? []).map { section -> LKMCPBridgeAttributeSection in
                    let attributes = (section.attributes ?? []).map { attribute in
                        LKMCPBridgeAttributeEncoder.encode(
                            attribute,
                            redactingSecureContent: redactSecureContent
                        )
                    }
                    return LKMCPBridgeAttributeSection(
                        identifier: section.identifier ?? "",
                        attributes: attributes
                    )
                }
                let groupIdentifier = group.userCustomTitle ?? group.identifier ?? ""
                return LKMCPBridgeAttributeGroup(
                    identifier: groupIdentifier,
                    isUserCustom: group.userCustomTitle != nil,
                    isSwiftUIGroup: group.isSwiftUIGroup,
                    sections: sections
                )
            }

            emittedDetails.append(LKMCPBridgeViewDetail(
                objectIdentifier: resolved.identifier,
                groups: encodedGroups,
                secureContent: redactSecureContent
            ))
        }

        // Any resolved oid we never saw a detail for (server omitted it
        // from the stream, despite no failureCode) joins failedIdentifiers
        // so the agent gets an honest accounting.
        for resolved in resolvedItems where seenOids.contains(resolved.nativeOid) == false {
            failedIdentifiers.append(resolved.identifier)
        }

        return successResponse(
            identifier: identifier,
            details: emittedDetails,
            failedIdentifiers: failedIdentifiers
        )
    }

    // MARK: - Helpers

    private func successResponse(
        identifier: String,
        details: [LKMCPBridgeViewDetail],
        failedIdentifiers: [String]
    ) -> LKMCPBridgeResponse {
        let result = LKMCPBridgeDetailsReadResult(
            details: details,
            failedIdentifiers: failedIdentifiers
        )
        do {
            let payload = try encodeAsJSONValue(result)
            return .success(identifier: identifier, result: payload)
        } catch {
            Self.logger.error("details.read encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    private func mapDetailsError(_ error: NSError) -> LKMCPBridgeErrorPayload {
        switch error.code {
        case Self.lookinErrCodeObjectNotFound:
            return LKMCPBridgeErrorPayload(
                code: "details.objectNotFound",
                message: "The target app could not find one or more of the requested objects. They may have been deallocated; refresh via get_hierarchy and retry."
            )
        case Self.lookinErrCodeInner:
            return LKMCPBridgeErrorPayload(
                code: "details.internalError",
                message: "The target app rejected the details request with a generic inner error."
            )
        case Self.lookinErrCodeLicenseRequired:
            return .licenseRequired
        case Self.lookinErrCodeNoConnect:
            return LKMCPBridgeErrorPayload(
                code: "details.disconnected",
                message: "The target app is no longer connected. Re-attach from the LookInside inspector and try again."
            )
        case Self.lookinErrCodeTimeout:
            return LKMCPBridgeErrorPayload(
                code: "details.timeout",
                message: "The target app did not respond within the request timeout. Reduce the batch size or check whether the target is paused in Xcode."
            )
        default:
            Self.logger.error("details.read received unmapped error code \(error.code, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return LKMCPBridgeErrorPayload(
                code: "details.internalError",
                message: "The target app reported an unexpected error (code \(error.code))."
            )
        }
    }

    private func encodeAsJSONValue(_ value: some Encodable) throws -> LKMCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(LKMCPBridgeJSONValue.self, from: data)
    }
}
