// Reads inspection-session snapshots and converts them to bridge payloads.
// The main actor owns every session; no document or window is required.

import AppKit
import CoreGraphics
import Foundation
import LookInsideInspectionCore
import os

@MainActor
public final class LKMCPBridgeInspectionService {
    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Inspection")

    public init() {}

    /// Routes a decoded request frame to the appropriate inspection method.
    /// Falls through to `dispatch.unknownMethod` for any verb the host does
    /// not implement so the wire layer behaves predictably for new clients.
    public func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
        switch request.method {
        case "targets.list":
            return handleTargetsList(identifier: request.identifier)
        case "hierarchy.read":
            return handleHierarchyRead(identifier: request.identifier, parameters: request.parameters)
        case "attributes.read":
            return handleAttributesRead(identifier: request.identifier, parameters: request.parameters)
        default:
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
    }

    // MARK: - targets.list

    private func handleTargetsList(identifier: String) -> LKMCPBridgeResponse {
        let sessions = InspectionSessionLookup.enumerateSessions()
        let infos = sessions.compactMap(makeTargetInfo(for:))
        do {
            let payload = try encodeAsJSONValue(infos)
            return .success(identifier: identifier, result: .object(["targets": payload]))
        } catch {
            Self.logger.error("targets.list encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    private func makeTargetInfo(for session: InspectionSession) -> LKMCPBridgeTargetInfo? {
        guard let appInfo = session.inspectableApp.appInfo else { return nil }
        return LKMCPBridgeTargetInfo(
            targetIdentifier: String(appInfo.appInfoIdentifier),
            applicationName: appInfo.appName,
            bundleIdentifier: appInfo.appBundleIdentifier,
            deviceDescription: appInfo.deviceDescription,
            operatingSystemDescription: appInfo.osDescription,
            deviceKind: deviceKindString(for: appInfo.deviceType),
            serverVersion: Int(appInfo.serverVersion),
            licenseState: "licensed"
        )
    }

    private func deviceKindString(for kind: LookinAppInfoDevice) -> String {
        switch kind {
        case .simulator: return "simulator"
        case .iPad: return "iPad"
        case .others: return "device"
        case .mac: return "mac"
        case .macCatalyst: return "macCatalyst"
        @unknown default: return "unknown"
        }
    }

    // MARK: - hierarchy.read

    private func handleHierarchyRead(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) -> LKMCPBridgeResponse {
        guard let parameters = parameters,
              case let .string(targetIdentifier)? = parameters["targetIdentifier"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        let rootObjectIdentifier: String?
        if case let .string(raw)? = parameters["rootObjectIdentifier"] {
            rootObjectIdentifier = raw
        } else {
            rootObjectIdentifier = nil
        }

        let depth: Int?
        if case let .integer(raw)? = parameters["depth"] {
            depth = Int(raw)
        } else if case let .double(raw)? = parameters["depth"] {
            depth = Int(raw)
        } else {
            depth = nil
        }

        let includeLayoutGuides: Bool
        if case let .bool(raw)? = parameters["includeLayoutGuides"] {
            includeLayoutGuides = raw
        } else {
            includeLayoutGuides = false
        }

        let includeCells: Bool
        if case let .bool(raw)? = parameters["includeCells"] {
            includeCells = raw
        } else {
            includeCells = false
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

        guard session.captureDate != nil else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.notReady",
                    message: "Live session has not loaded a hierarchy yet."
                )
            )
        }

        let rootItems: [LookinDisplayItem]
        if let rootObjectIdentifier {
            guard let scopedRoot = InspectionSessionLookup.findDisplayItem(
                amongRoots: session.rawFlatItems ?? [],
                matchingObjectIdentifier: rootObjectIdentifier
            ) else {
                return .failure(
                    identifier: identifier,
                    error: LKMCPBridgeErrorPayload(
                        code: "hierarchy.objectNotFound",
                        message: "Object identifier \(rootObjectIdentifier) is not present in this target's hierarchy."
                    )
                )
            }
            rootItems = [scopedRoot]
        } else {
            rootItems = InspectionSessionLookup.topLevelDisplayItems(in: session)
        }

        let nodes = rootItems.map { makeViewNode(from: $0, remainingDepth: depth, includeLayoutGuides: includeLayoutGuides, includeCells: includeCells) }
        do {
            let payload = try encodeAsJSONValue(nodes)
            return .success(identifier: identifier, result: .object(["roots": payload]))
        } catch {
            Self.logger.error("hierarchy.read encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    private static func nodeKindString(for item: LookinDisplayItem) -> String {
        switch item.resolvedNodeKind() {
        case .layer: return "layer"
        case .view: return "view"
        case .window: return "window"
        case .windowScene: return "windowScene"
        case .custom: return "custom"
        case .layoutGuide: return "layoutGuide"
        case .cell: return "cell"
        case .unspecified: return "view"
        @unknown default: return "view"
        }
    }

    private func makeViewNode(from item: LookinDisplayItem, remainingDepth: Int?, includeLayoutGuides: Bool, includeCells: Bool) -> LKMCPBridgeViewNode {
        let identity = InspectionSessionLookup.objectIdentifierString(for: item)
        let className = item.displayingObject()?.classChainList?.first ?? ""
        let frame = LKMCPBridgeRect(cgRect: InspectionSessionLookup.rootSpaceFrame(for: item))
        var subitems = item.subitems ?? []
        if includeLayoutGuides == false {
            // Default-off so existing agents' structural paths and snapshot
            // diff baselines do not drift when guide nodes enter the tree.
            subitems = subitems.filter { $0.resolvedNodeKind() != .layoutGuide }
        }
        if includeCells == false {
            // Same reasoning as includeLayoutGuides, for cell nodes.
            subitems = subitems.filter { $0.resolvedNodeKind() != .cell }
        }
        let childIdentifiers = subitems.map(InspectionSessionLookup.objectIdentifierString(for:))

        let inlinedChildren: [LKMCPBridgeViewNode]?
        if let remainingDepth, remainingDepth <= 1 {
            inlinedChildren = nil
        } else {
            let nextDepth = remainingDepth.map { $0 - 1 }
            inlinedChildren = subitems.map { makeViewNode(from: $0, remainingDepth: nextDepth, includeLayoutGuides: includeLayoutGuides, includeCells: includeCells) }
        }

        return LKMCPBridgeViewNode(
            objectIdentifier: identity,
            className: className,
            nodeKind: Self.nodeKindString(for: item),
            frame: frame,
            isHidden: item.isHidden,
            alpha: Double(item.alpha),
            representsKeyWindow: item.representedAsKeyWindow,
            childObjectIdentifiers: childIdentifiers,
            children: inlinedChildren
        )
    }

    // MARK: - attributes.read

    private func handleAttributesRead(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) -> LKMCPBridgeResponse {
        guard let parameters = parameters,
              case let .string(targetIdentifier)? = parameters["targetIdentifier"],
              case let .string(objectIdentifier)? = parameters["objectIdentifier"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        let includeUserCustom: Bool
        if case let .bool(raw)? = parameters["includeUserCustom"] {
            includeUserCustom = raw
        } else {
            includeUserCustom = true
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

        var rawGroups: [LookinAttributesGroup] = []
        if let inbuiltGroups = displayItem.attributesGroupList {
            rawGroups.append(contentsOf: inbuiltGroups)
        }
        if includeUserCustom, let customGroups = displayItem.customAttrGroupList {
            rawGroups.append(contentsOf: customGroups)
        }

        // Evaluate the secure-content gate once per display item so every
        // attribute we emit for this view shares the same redaction
        // decision (a UITextField/NSSecureTextField can't have its
        // `placeholder` leak when its `text` is redacted, for example).
        let redactSecureContent = LKMCPBridgeSecureContentDetector.isSecure(displayItem: displayItem)

        let encodedGroups = rawGroups.map { group in
            encodeGroup(group, redactingSecureContent: redactSecureContent)
        }

        do {
            let payload = try encodeAsJSONValue(encodedGroups)
            // Annotate whether the host has actually fetched per-item
            // details for this view. v2 reads the cache as-is; agents that
            // see an empty `groups` array should know to ask the user to
            // open this view in the host inspector first. `secureContent`
            // tells the agent why textual values may be `null` here.
            let hasCachedDetails = displayItem.attributesGroupList?.isEmpty == false
            return .success(
                identifier: identifier,
                result: .object([
                    "groups": payload,
                    "detailsCached": .bool(hasCachedDetails),
                    "secureContent": .bool(redactSecureContent),
                ])
            )
        } catch {
            Self.logger.error("attributes.read encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    private func encodeGroup(
        _ group: LookinAttributesGroup,
        redactingSecureContent: Bool
    ) -> LKMCPBridgeAttributeGroup {
        let identifier = group.userCustomTitle ?? group.identifier
        let sections = (group.attrSections ?? []).map { section in
            encodeSection(section, redactingSecureContent: redactingSecureContent)
        }
        return LKMCPBridgeAttributeGroup(
            identifier: identifier ?? "",
            isUserCustom: group.userCustomTitle != nil,
            isSwiftUIGroup: group.isSwiftUIGroup,
            sections: sections
        )
    }

    private func encodeSection(
        _ section: LookinAttributesSection,
        redactingSecureContent: Bool
    ) -> LKMCPBridgeAttributeSection {
        let attributes = (section.attributes ?? []).map { attribute in
            LKMCPBridgeAttributeEncoder.encode(
                attribute,
                redactingSecureContent: redactingSecureContent
            )
        }
        return LKMCPBridgeAttributeSection(
            identifier: section.identifier ?? "",
            attributes: attributes
        )
    }

    // MARK: - Encoding helpers

    /// Encodes any `Encodable` value into the loose `LKMCPBridgeJSONValue`
    /// tree used inside response frame `result` containers. Round-trips
    /// through `JSONEncoder` / `JSONDecoder` so non-trivial nested types
    /// (arrays, optionals, etc.) preserve their wire shape.
    private func encodeAsJSONValue(_ value: some Encodable) throws -> LKMCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(LKMCPBridgeJSONValue.self, from: data)
    }
}
