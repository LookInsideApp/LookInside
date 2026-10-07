// LKMCPBridgeModificationService.swift
//
// Handles the `attribute.modify` bridge route: mutates one inspected
// attribute on a view in the attached target app (RPC 204
// `InbuiltAttrModification`) and returns the post-layout effective
// value alongside the value the agent requested.
//
// This is the second mutating bridge route (after `invoke.method`).
// It shares the same round-trip plumbing — selector lookup
// happens against `LookinDashboardBlueprint`; the polymorphic wire
// value is decoded into the right ObjC type by
// `LKMCPBridgeAttributeValueDecoder`; the round-trip awaits
// `LKInspectableApp.submit(_:)`;
// `LKMCPBridgeAttributeEncoder` re-encodes the effective post-layout
// attribute so the caller can compare against what they sent.
//
// The bridge does NOT pre-compute settability — it asks
// `LookinDashboardBlueprint setterWithAttrID:` for the setter SEL and
// surfaces `modify.readOnly` when the blueprint returns nil. This
// matches the host inspector's existing modification gate.

import AppKit
import CoreGraphics
import Foundation
import os

@MainActor
final class LKMCPBridgeModificationService {
    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Modification")

    init() {}

    // MARK: - Entry point

    func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
        guard request.method == "attribute.modify" else {
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
        return await handleAttributeModify(
            identifier: request.identifier,
            parameters: request.parameters
        )
    }

    // MARK: - attribute.modify

    private func handleAttributeModify(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) async -> LKMCPBridgeResponse {
        // Parameter extraction
        guard let parameters,
              case let .string(targetIdentifier)? = parameters["targetIdentifier"],
              case let .string(objectIdentifier)? = parameters["objectIdentifier"],
              case let .string(attributeIdentifier)? = parameters["attributeIdentifier"],
              case let .object(valueObject)? = parameters["value"],
              case let .string(wireKind)? = valueObject["kind"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }
        let wireData = valueObject["data"]

        // Live-document / display-item lookup
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

        // Find the attribute in the currently-cached detail
        guard let attribute = findAttribute(
            withIdentifier: attributeIdentifier,
            in: displayItem.attributesGroupList ?? []
        ) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "modify.attributeNotFound",
                    message: "Attribute \(attributeIdentifier) is not present in this view's cached detail. Open the view in the LookInside inspector (or call read_attributes first) to populate its detail, then retry."
                )
            )
        }

        // Setter lookup. `setter(withAttrID:)` returns nil for read-only
        // attributes (e.g. computed Relation, class chain, AutoLayout
        // constraint summaries).
        guard let setterSelector = LookinDashboardBlueprint.setter(withAttrID: attributeIdentifier) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "modify.readOnly",
                    message: "Attribute \(attributeIdentifier) is read-only; there is no registered setter for it."
                )
            )
        }

        // Native oid
        guard let nativeOid = displayItem.displayingObject()?.oid, nativeOid != 0 else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.objectNotFound",
                    message: "Display item \(objectIdentifier) does not carry a live object identifier."
                )
            )
        }

        // Decode wire value into the polymorphic id LookinAttributeModification expects.
        let nativeValue: Any
        do {
            nativeValue = try LKMCPBridgeAttributeValueDecoder.decode(
                wireKind: wireKind,
                wireData: wireData,
                expectedAttrType: attribute.attrType
            )
        } catch let LKMCPBridgeAttributeValueDecoder.DecodeError.unsupportedKind(kind) {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "modify.unsupportedKind",
                    message: "Wire kind '\(kind)' is not supported for modification in this release. Supported kinds: integer, double, bool, string, selector, class, point, vector, size, rect, transform, edgeInsets, offset, color, enum."
                )
            )
        } catch let LKMCPBridgeAttributeValueDecoder.DecodeError.kindMismatch(wireKind, expectedAttrType) {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "modify.valueKindMismatch",
                    message: "Wire kind '\(wireKind)' does not match attribute's declared LookinAttrType (\(expectedAttrType.rawValue))."
                )
            )
        } catch let LKMCPBridgeAttributeValueDecoder.DecodeError.shapeInvalid(reason) {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "modify.valueShapeInvalid",
                    message: reason
                )
            )
        } catch {
            Self.logger.error("Unexpected decode error: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }

        // Build the LookinAttributeModification.
        let modification = LookinAttributeModification()
        modification.targetOid = nativeOid
        modification.setterSelector = setterSelector
        modification.attrType = attribute.attrType
        modification.value = nativeValue
        modification.clientReadableVersion = LKHelper.lookinReadableVersion()

        let detail: LookinDisplayItemDetail
        do {
            detail = try await document.inspectableApp.submit(modification)
        } catch {
            return .failure(identifier: identifier, error: mapModificationError(error as NSError))
        }

        // Merge the post-modification detail back into the host's cache, the
        // same way `details.read` and `screenshot.read` do. Without this the
        // inspector window keeps showing the pre-modification value, and a
        // follow-up `attributes.read` serves the stale cached groups -- which
        // directly contradicts the `effectiveAttribute` this call is about to
        // return, with nothing to tell the agent which one is current.
        //
        // The host's own modification path additionally re-fetches a
        // screenshot (`LKDashboardViewController.m`). That is deliberately
        // not mirrored here: screenshots have their own route, and issuing
        // one per attribute write would put a render round-trip on the
        // critical path of every modification.
        document.hierarchyDataSource?.modify(with: detail)

        // Find the effective post-layout attribute in the response.
        guard let effectiveAttribute = findAttribute(
            withIdentifier: attributeIdentifier,
            in: detail.attributesGroupList ?? []
        ) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "modify.internalError",
                    message: "Effective attribute disappeared from the server's post-modification detail. This indicates a server-side bug."
                )
            )
        }

        // Encode the effective attribute through the same encoder
        // the read route uses, so its shape matches read_attributes.
        let redactSecureContent = LKMCPBridgeSecureContentDetector.isSecure(displayItem: displayItem)
        let encodedEffective = LKMCPBridgeAttributeEncoder.encode(
            effectiveAttribute,
            redactingSecureContent: redactSecureContent
        )

        let requestedWire = LKMCPBridgeAttributeValueWire(kind: wireKind, data: wireData)
        let effectiveWire = LKMCPBridgeAttributeValueWire(
            kind: encodedEffective.kind,
            data: encodedEffective.value
        )
        let matches = !redactSecureContent
            && requestedWire.kind == effectiveWire.kind
            && jsonValuesEqual(requestedWire.data, effectiveWire.data)

        let frame = (detail.frameValue?.rectValue).map { CGRect(x: $0.origin.x, y: $0.origin.y, width: $0.size.width, height: $0.size.height) } ?? .zero
        let bounds = (detail.boundsValue?.rectValue).map { CGRect(x: $0.origin.x, y: $0.origin.y, width: $0.size.width, height: $0.size.height) } ?? .zero
        let isHidden = detail.hiddenValue?.boolValue ?? false
        let alpha = detail.alphaValue?.doubleValue ?? 1.0

        let result = LKMCPBridgeModificationResult(
            attributeIdentifier: attributeIdentifier,
            requestedValue: requestedWire,
            effectiveAttribute: encodedEffective,
            effectiveMatchesRequested: matches,
            frame: LKMCPBridgeRect(cgRect: frame),
            bounds: LKMCPBridgeRect(cgRect: bounds),
            isHidden: isHidden,
            alpha: alpha,
            secureContent: redactSecureContent
        )

        do {
            let payload = try encodeAsJSONValue(result)
            return .success(identifier: identifier, result: payload)
        } catch {
            Self.logger.error("attribute.modify encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    // MARK: - Helpers

    private func findAttribute(
        withIdentifier identifier: String,
        in groups: [LookinAttributesGroup]
    ) -> LookinAttribute? {
        for group in groups {
            for section in group.attrSections ?? [] {
                for attribute in section.attributes ?? [] {
                    if attribute.identifier == identifier {
                        return attribute
                    }
                }
            }
        }
        return nil
    }

    /// Equality on `LKMCPBridgeJSONValue` by canonical JSON encoding.
    /// Uses `.sortedKeys` so object key order does not affect the result.
    /// This is intentionally strict — no float epsilon — because layout
    /// pass adjustments are a real signal we want to surface to the
    /// agent rather than absorb.
    private func jsonValuesEqual(
        _ lhs: LKMCPBridgeJSONValue?,
        _ rhs: LKMCPBridgeJSONValue?
    ) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (nil, _?), (_?, nil):
            return false
        case let (lhsValue?, rhsValue?):
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let lhsData = (try? encoder.encode(lhsValue)) ?? Data()
            let rhsData = (try? encoder.encode(rhsValue)) ?? Data()
            return lhsData == rhsData
        }
    }

    private func mapModificationError(_ error: NSError) -> LKMCPBridgeErrorPayload {
        switch error.code {
        case LookinErrCode_ObjectNotFound:
            return LKMCPBridgeErrorPayload(
                code: "modify.objectNotFound",
                message: "The target app could not find an object for this identifier. The object may have been deallocated; try reloading the inspector."
            )
        case LookinErrCode_Inner:
            return LKMCPBridgeErrorPayload(
                code: "modify.invalidSetter",
                message: "The target app rejected the modification — the setter signature was missing or the value type did not unbox cleanly."
            )
        case LookinErrCode_Exception:
            // NSException thrown by the setter; the server stuffs the
            // exception's reason into the NSLocalizedDescriptionKey.
            let reason = (error.userInfo[NSLocalizedDescriptionKey] as? String) ?? "no further detail"
            return LKMCPBridgeErrorPayload(
                code: "modify.exception",
                message: "The setter raised an NSException in the target app: \(reason)"
            )
        case LookinErrCode_LicenseRequired:
            return .licenseRequired
        case LookinErrCode_NoConnect:
            return LKMCPBridgeErrorPayload(
                code: "modify.disconnected",
                message: "The target app is no longer connected. Re-attach from the LookInside inspector and try again."
            )
        case LookinErrCode_Timeout:
            return LKMCPBridgeErrorPayload(
                code: "modify.timeout",
                message: "The target app did not respond within the request timeout. Check whether it is paused in Xcode or blocked on the main thread."
            )
        default:
            Self.logger.error("attribute.modify received unmapped error code \(error.code, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return LKMCPBridgeErrorPayload(
                code: "modify.internalError",
                message: "The target app reported an unexpected error (code \(error.code))."
            )
        }
    }

    private func encodeAsJSONValue(_ value: some Encodable) throws -> LKMCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(LKMCPBridgeJSONValue.self, from: data)
    }
}
