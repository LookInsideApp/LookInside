// MCPBridgeInspectionService.swift
//
// Routes MCPBridge inspection requests to the host's per-window
// `LiveDocument` instances and converts the results to wire DTOs.
//
// All access to `NSDocumentController` and `LiveDocument` happens on
// the main thread; the entry point is `@MainActor` so the bridge
// connection handlers can `await` it from a background queue and get the
// hop for free.

import AppKit
import CoreGraphics
import Foundation
import os

@MainActor
final class MCPBridgeInspectionService {
    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Inspection")

    init() {}

    /// Routes a decoded request frame to the appropriate inspection method.
    /// Falls through to `dispatch.unknownMethod` for any verb the host does
    /// not implement so the wire layer behaves predictably for new clients.
    func handle(request: MCPBridgeRequest) async -> MCPBridgeResponse {
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

    private func handleTargetsList(identifier: String) -> MCPBridgeResponse {
        let documents = MCPBridgeLiveDocumentLookup.enumerateLiveDocuments()
        let infos = documents.compactMap(makeTargetInfo(for:))
        do {
            let payload = try encodeAsJSONValue(infos)
            return .success(identifier: identifier, result: .object(["targets": payload]))
        } catch {
            Self.logger.error("targets.list encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    private func makeTargetInfo(for document: LiveDocument) -> MCPBridgeTargetInfo? {
        guard let appInfo = document.inspectableApp.appInfo else { return nil }
        return MCPBridgeTargetInfo(
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
        parameters: [String: MCPBridgeJSONValue]?
    ) -> MCPBridgeResponse {
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

        guard let document = MCPBridgeLiveDocumentLookup.findLiveDocument(targetIdentifier: targetIdentifier) else {
            return .failure(
                identifier: identifier,
                error: MCPBridgeErrorPayload(
                    code: "hierarchy.targetNotFound",
                    message: "No live inspection document found for target identifier \(targetIdentifier)."
                )
            )
        }

        guard let dataSource = document.hierarchyDataSource else {
            return .failure(
                identifier: identifier,
                error: MCPBridgeErrorPayload(
                    code: "hierarchy.notReady",
                    message: "Live document has not loaded a hierarchy yet."
                )
            )
        }

        let rootItems: [DisplayItem]
        if let rootObjectIdentifier {
            guard let scopedRoot = MCPBridgeLiveDocumentLookup.findDisplayItem(
                amongRoots: dataSource.rawFlatItems ?? [],
                matchingObjectIdentifier: rootObjectIdentifier
            ) else {
                return .failure(
                    identifier: identifier,
                    error: MCPBridgeErrorPayload(
                        code: "hierarchy.objectNotFound",
                        message: "Object identifier \(rootObjectIdentifier) is not present in this target's hierarchy."
                    )
                )
            }
            rootItems = [scopedRoot]
        } else {
            rootItems = MCPBridgeLiveDocumentLookup.topLevelDisplayItems(in: document)
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

    private static func nodeKindString(for item: DisplayItem) -> String {
        switch item.resolvedNodeKind() {
        // The client's vocabulary has no separate kinds for these two; both
        // are layers.
        case .layer, .viewOuterLayer, .backingLayer: return "layer"
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

    private func makeViewNode(from item: DisplayItem, remainingDepth: Int?, includeLayoutGuides: Bool, includeCells: Bool) -> MCPBridgeViewNode {
        let identity = MCPBridgeLiveDocumentLookup.objectIdentifierString(for: item)
        let className = item.displayingObject()?.classChainList?.first ?? ""
        let frame = MCPBridgeRect(cgRect: MCPBridgeLiveDocumentLookup.rootSpaceFrame(for: item))
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
        let childIdentifiers = subitems.map(MCPBridgeLiveDocumentLookup.objectIdentifierString(for:))

        let inlinedChildren: [MCPBridgeViewNode]?
        if let remainingDepth, remainingDepth <= 1 {
            inlinedChildren = nil
        } else {
            let nextDepth = remainingDepth.map { $0 - 1 }
            inlinedChildren = subitems.map { makeViewNode(from: $0, remainingDepth: nextDepth, includeLayoutGuides: includeLayoutGuides, includeCells: includeCells) }
        }

        return MCPBridgeViewNode(
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
        parameters: [String: MCPBridgeJSONValue]?
    ) -> MCPBridgeResponse {
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

        guard let displayItem = MCPBridgeLiveDocumentLookup.findDisplayItem(
            amongRoots: MCPBridgeLiveDocumentLookup.topLevelDisplayItems(in: document),
            matchingObjectIdentifier: objectIdentifier
        ) else {
            return .failure(
                identifier: identifier,
                error: MCPBridgeErrorPayload(
                    code: "hierarchy.objectNotFound",
                    message: "Object identifier \(objectIdentifier) is not present in this target's hierarchy."
                )
            )
        }

        var rawGroups: [AttributesGroup] = []
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
        let redactSecureContent = MCPBridgeSecureContentDetector.isSecure(displayItem: displayItem)

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
        _ group: AttributesGroup,
        redactingSecureContent: Bool
    ) -> MCPBridgeAttributeGroup {
        let identifier = group.userCustomTitle ?? group.identifier
        let sections = (group.attrSections ?? []).map { section in
            encodeSection(section, redactingSecureContent: redactingSecureContent)
        }
        return MCPBridgeAttributeGroup(
            identifier: identifier ?? "",
            isUserCustom: group.userCustomTitle != nil,
            isSwiftUIGroup: group.isSwiftUIGroup,
            sections: sections
        )
    }

    private func encodeSection(
        _ section: AttributesSection,
        redactingSecureContent: Bool
    ) -> MCPBridgeAttributeSection {
        let attributes = (section.attributes ?? []).map { attribute in
            MCPBridgeAttributeEncoder.encode(
                attribute,
                redactingSecureContent: redactingSecureContent
            )
        }
        return MCPBridgeAttributeSection(
            identifier: section.identifier ?? "",
            attributes: attributes
        )
    }

    // MARK: - Encoding helpers

    /// Encodes any `Encodable` value into the loose `MCPBridgeJSONValue`
    /// tree used inside response frame `result` containers. Round-trips
    /// through `JSONEncoder` / `JSONDecoder` so non-trivial nested types
    /// (arrays, optionals, etc.) preserve their wire shape.
    private func encodeAsJSONValue(_ value: some Encodable) throws -> MCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(MCPBridgeJSONValue.self, from: data)
    }
}
