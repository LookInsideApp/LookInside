// MCPBridgeDetailsService.swift
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
//     `StaticHierarchyDataSource.modifyWithDisplayItemDetail:` so
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
import FoundationToolbox

@Loggable(subsystem: "com.lookinside.app", category: "MCPBridge.Details")
@MainActor
final class MCPBridgeDetailsService {
    /// Hard cap on per-call batch size. Matches the host inspector's
    /// own `packageMaxTasksCount` (see `StaticAsyncUpdateManager`).
    /// Larger batches are rejected at the wire boundary; agents that
    /// need more issue multiple calls.
    private static let maximumObjectIdentifiersPerCall = 100


    init() {}

    // MARK: - Entry point

    func handle(request: MCPBridgeRequest) async -> MCPBridgeResponse {
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
        parameters: [String: MCPBridgeJSONValue]?
    ) async -> MCPBridgeResponse {
        // Parameter extraction
        guard let parameters,
              case let .string(targetIdentifier)? = parameters["targetIdentifier"],
              case let .array(identifierWireValues)? = parameters["objectIdentifiers"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        // Materialize the identifier list as distinct Swift strings. The
        // de-duplication is load-bearing, not tidiness: two equal identifiers
        // resolve to the same display item and therefore the same oid, and
        // the oid-keyed index built below traps on a duplicate key, which
        // would take down the whole host app rather than fail this request.
        let requestedIdentifiers: [String]
        switch MCPBridgeObjectIdentifierList.parse(
            wireValues: identifierWireValues,
            limit: Self.maximumObjectIdentifiersPerCall
        ) {
        case let .success(parsed):
            requestedIdentifiers = parsed.identifiers
            if parsed.droppedDuplicateCount > 0 {
                #log(.debug, 
                    "details.read collapsed \(parsed.droppedDuplicateCount, privacy: .public) duplicate object identifier(s)"
                )
            }
        case .failure(.notAllStrings), .failure(.empty):
            return .failure(identifier: identifier, error: .invalidParameters)
        case let .failure(.tooMany(distinctCount, limit)):
            return .failure(
                identifier: identifier,
                error: MCPBridgeErrorPayload(
                    code: "dispatch.tooMany",
                    message: "details.read accepts at most \(limit) object identifiers per call; received \(distinctCount) distinct. Split into multiple calls."
                )
            )
        }

        let includeUserCustom: Bool
        if case let .bool(raw)? = parameters["includeUserCustom"] {
            includeUserCustom = raw
        } else {
            includeUserCustom = true
        }

        // Live-document lookup
        guard let document = MCPBridgeLiveDocumentLookup.findLiveDocument(targetIdentifier: targetIdentifier) else {
            return .failure(
                identifier: identifier,
                error: MCPBridgeErrorPayload(
                    code: "hierarchy.targetNotFound",
                    message: "No live inspection document found for target identifier \(targetIdentifier)."
                )
            )
        }

        guard document.hierarchyDataSource != nil else {
            return .failure(
                identifier: identifier,
                error: MCPBridgeErrorPayload(
                    code: "hierarchy.notReady",
                    message: "Live document has not loaded a hierarchy yet."
                )
            )
        }

        // Resolve each requested identifier to a display item. Missing
        // identifiers go into failedIdentifiers and skip the server
        // round-trip; the agent learns which oids vanished without the
        // request blowing up entirely.
        let roots = MCPBridgeLiveDocumentLookup.topLevelDisplayItems(in: document)
        var resolvedItems: [(identifier: String, displayItem: DisplayItem, nativeOid: UInt)] = []
        resolvedItems.reserveCapacity(requestedIdentifiers.count)
        var failedIdentifiers: [String] = []

        for requested in requestedIdentifiers {
            guard let displayItem = MCPBridgeLiveDocumentLookup.findDisplayItem(
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
                error: MCPBridgeErrorPayload(
                    code: "details.objectNotFound",
                    message: "None of the requested object identifiers are present in this target's hierarchy. Refresh the hierarchy via get_hierarchy and retry."
                )
            )
        }

        // Build the RPC 203 task package. Single package — we already
        // cap the batch at 100 entries, so the host inspector's own
        // pixel/count packing thresholds never need to come into play.
        let clientReadableVersion = AppHelper.readableVersion()
        let tasks = resolvedItems.map { resolved -> StaticAsyncUpdateTask in
            let task = StaticAsyncUpdateTask()
            task.oid = resolved.nativeOid
            task.taskType = .noScreenshot
            task.attrRequest = .need
            task.needBasisVisualInfo = false
            task.needSubitems = false
            task.clientReadableVersion = clientReadableVersion
            return task
        }
        let package = StaticAsyncUpdateTasksPackage()
        package.tasks = tasks

        // RPC 203 streams one frame per package; with a single package we
        // expect exactly one frame. Collect them all anyway so the route
        // stays correct if batching here ever splits into packages. A
        // stream that ends without a frame leaves every requested
        // identifier in `failedIdentifiers` below.
        var allDetails: [DisplayItemDetail] = []
        allDetails.reserveCapacity(resolvedItems.count)
        do {
            for try await frame in document.inspectableApp.hierarchyDetails(packages: [package]) {
                allDetails.append(contentsOf: frame)
            }
        } catch {
            return .failure(identifier: identifier, error: mapDetailsError(error as NSError))
        }

        // Index resolved items by native oid so we can match incoming
        // details back to the display item (needed for secureContent
        // detection and for downstream cache merging).
        //
        // Keep-first on collision rather than `uniqueKeysWithValues:`. The
        // identifier list is already de-duplicated, so a collision here would
        // mean two *different* identifier strings resolved to one object --
        // impossible today, since identifiers are generated from the oid and
        // matched by exact equality. Trapping on it anyway would turn a future
        // change in identifier syntax into a host crash, which is far worse
        // than serving the first of two equivalent entries.
        let itemsByOid: [UInt: (identifier: String, displayItem: DisplayItem, nativeOid: UInt)] = Dictionary(
            resolvedItems.map { ($0.nativeOid, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // Resolve the concrete data source once. We thread it through
        // the per-detail loop rather than walking back from each
        // display item, because DisplayItem has no back-reference
        // to its owning document.
        let staticDataSource = document.hierarchyDataSource

        var emittedDetails: [MCPBridgeViewDetail] = []
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
            let redactSecureContent = MCPBridgeSecureContentDetector.isSecure(displayItem: resolved.displayItem)
            var rawGroups: [AttributesGroup] = []
            if let inbuiltGroups = detail.attributesGroupList {
                rawGroups.append(contentsOf: inbuiltGroups)
            }
            if includeUserCustom, let customGroups = detail.customAttrGroupList {
                rawGroups.append(contentsOf: customGroups)
            }
            let encodedGroups = rawGroups.map { group -> MCPBridgeAttributeGroup in
                let sections = (group.attrSections ?? []).map { section -> MCPBridgeAttributeSection in
                    let attributes = (section.attributes ?? []).map { attribute in
                        MCPBridgeAttributeEncoder.encode(
                            attribute,
                            redactingSecureContent: redactSecureContent
                        )
                    }
                    return MCPBridgeAttributeSection(
                        identifier: section.identifier ?? "",
                        attributes: attributes
                    )
                }
                let groupIdentifier = group.userCustomTitle ?? group.identifier ?? ""
                return MCPBridgeAttributeGroup(
                    identifier: groupIdentifier,
                    isUserCustom: group.userCustomTitle != nil,
                    isSwiftUIGroup: group.isSwiftUIGroup,
                    sections: sections
                )
            }

            emittedDetails.append(MCPBridgeViewDetail(
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
        details: [MCPBridgeViewDetail],
        failedIdentifiers: [String]
    ) -> MCPBridgeResponse {
        let result = MCPBridgeDetailsReadResult(
            details: details,
            failedIdentifiers: failedIdentifiers
        )
        do {
            let payload = try encodeAsJSONValue(result)
            return .success(identifier: identifier, result: payload)
        } catch {
            #log(.error, "details.read encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    private func mapDetailsError(_ error: NSError) -> MCPBridgeErrorPayload {
        switch error.code {
        case LookinErrCode_ObjectNotFound:
            return MCPBridgeErrorPayload(
                code: "details.objectNotFound",
                message: "The target app could not find one or more of the requested objects. They may have been deallocated; refresh via get_hierarchy and retry."
            )
        case LookinErrCode_Inner:
            return MCPBridgeErrorPayload(
                code: "details.internalError",
                message: "The target app rejected the details request with a generic inner error."
            )
        case LookinErrCode_LicenseRequired:
            return .licenseRequired
        case LookinErrCode_NoConnect:
            return MCPBridgeErrorPayload(
                code: "details.disconnected",
                message: "The target app is no longer connected. Re-attach from the LookInside inspector and try again."
            )
        case LookinErrCode_Timeout:
            return MCPBridgeErrorPayload(
                code: "details.timeout",
                message: "The target app did not respond within the request timeout. Reduce the batch size or check whether the target is paused in Xcode."
            )
        default:
            #log(.error, "details.read received unmapped error code \(error.code, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return MCPBridgeErrorPayload(
                code: "details.internalError",
                message: "The target app reported an unexpected error (code \(error.code))."
            )
        }
    }

    private func encodeAsJSONValue(_ value: some Encodable) throws -> MCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(MCPBridgeJSONValue.self, from: data)
    }
}
