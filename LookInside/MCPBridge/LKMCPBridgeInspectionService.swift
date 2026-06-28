// LKMCPBridgeInspectionService.swift
//
// Routes MCPBridge inspection requests to the host's per-window
// `LookinLiveDocument` instances and converts the results to wire DTOs.
//
// All access to `NSDocumentController` and `LookinLiveDocument` happens on
// the main thread; the public entry point is `@MainActor` so the bridge
// connection handlers can `await` it from a background queue and get the
// hop for free.

import AppKit
import CoreGraphics
import Foundation
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
        default:
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
    }

    // MARK: - targets.list

    private func handleTargetsList(identifier: String) -> LKMCPBridgeResponse {
        let documents = enumerateLiveDocuments()
        let infos = documents.compactMap(makeTargetInfo(for:))
        do {
            let payload = try encodeAsJSONValue(infos)
            return .success(identifier: identifier, result: .object(["targets": payload]))
        } catch {
            Self.logger.error("targets.list encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    private func makeTargetInfo(for document: LookinLiveDocument) -> LKMCPBridgeTargetInfo? {
        guard let appInfo = document.inspectableApp.appInfo else { return nil }
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
        case .iPad:      return "iPad"
        case .others:    return "device"
        case .mac:       return "mac"
        @unknown default: return "unknown"
        }
    }

    // MARK: - hierarchy.read

    private func handleHierarchyRead(
        identifier: String,
        parameters: [String: LKMCPBridgeJSONValue]?
    ) -> LKMCPBridgeResponse {
        guard let parameters = parameters,
              case .string(let targetIdentifier)? = parameters["targetIdentifier"]
        else {
            return .failure(identifier: identifier, error: .invalidParameters)
        }

        let rootObjectIdentifier: String?
        if case .string(let raw)? = parameters["rootObjectIdentifier"] {
            rootObjectIdentifier = raw
        } else {
            rootObjectIdentifier = nil
        }

        let depth: Int?
        if case .integer(let raw)? = parameters["depth"] {
            depth = Int(raw)
        } else if case .double(let raw)? = parameters["depth"] {
            depth = Int(raw)
        } else {
            depth = nil
        }

        guard let document = findLiveDocument(targetIdentifier: targetIdentifier) else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.targetNotFound",
                    message: "No live inspection document found for target identifier \(targetIdentifier)."
                )
            )
        }

        guard let dataSource = document.hierarchyDataSource else {
            return .failure(
                identifier: identifier,
                error: LKMCPBridgeErrorPayload(
                    code: "hierarchy.notReady",
                    message: "Live document has not loaded a hierarchy yet."
                )
            )
        }

        let rootItems: [LookinDisplayItem]
        if let rootObjectIdentifier {
            guard let scopedRoot = findDisplayItem(
                amongRoots: dataSource.rawFlatItems ?? [],
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
            // Top-level UIWindow / NSWindow items report indentLevel == 0;
            // every nested view has indentLevel >= 1. `superItem` would also
            // work but the Objective-C importer renames it into a Swift
            // keyword collision, so `indentLevel()` is the portable check.
            rootItems = dataSource.rawFlatItems?.filter { $0.indentLevel() == 0 } ?? []
        }

        let nodes = rootItems.map { makeViewNode(from: $0, remainingDepth: depth) }
        do {
            let payload = try encodeAsJSONValue(nodes)
            return .success(identifier: identifier, result: .object(["roots": payload]))
        } catch {
            Self.logger.error("hierarchy.read encode failed: \(error.localizedDescription, privacy: .public)")
            return .failure(identifier: identifier, error: .internalError)
        }
    }

    private func makeViewNode(from item: LookinDisplayItem, remainingDepth: Int?) -> LKMCPBridgeViewNode {
        let identity = objectIdentifierString(for: item)
        let className = item.displayingObject()?.classChainList?.first ?? ""
        let frame = LKMCPBridgeRect(cgRect: item.frame)
        let subitems = item.subitems ?? []
        let childIdentifiers = subitems.map(objectIdentifierString(for:))

        let inlinedChildren: [LKMCPBridgeViewNode]?
        if let remainingDepth, remainingDepth <= 1 {
            inlinedChildren = nil
        } else {
            let nextDepth = remainingDepth.map { $0 - 1 }
            inlinedChildren = subitems.map { makeViewNode(from: $0, remainingDepth: nextDepth) }
        }

        return LKMCPBridgeViewNode(
            objectIdentifier: identity,
            className: className,
            frame: frame,
            isHidden: item.isHidden,
            alpha: Double(item.alpha),
            representsKeyWindow: item.representedAsKeyWindow,
            childObjectIdentifiers: childIdentifiers,
            children: inlinedChildren
        )
    }

    // MARK: - Document lookup

    private func enumerateLiveDocuments() -> [LookinLiveDocument] {
        let allDocuments = NSDocumentController.shared.documents
        return allDocuments.compactMap { $0 as? LookinLiveDocument }
    }

    private func findLiveDocument(targetIdentifier: String) -> LookinLiveDocument? {
        guard let identifierValue = UInt(targetIdentifier) else { return nil }
        return enumerateLiveDocuments().first { document in
            return document.inspectableApp.appInfo?.appInfoIdentifier == identifierValue
        }
    }

    private func findDisplayItem(
        amongRoots roots: [LookinDisplayItem],
        matchingObjectIdentifier identifier: String
    ) -> LookinDisplayItem? {
        var queue: [LookinDisplayItem] = roots
        while queue.isEmpty == false {
            let current = queue.removeFirst()
            if objectIdentifierString(for: current) == identifier {
                return current
            }
            if let subitems = current.subitems {
                queue.append(contentsOf: subitems)
            }
        }
        return nil
    }

    // MARK: - Encoding helpers

    private func objectIdentifierString(for item: LookinDisplayItem) -> String {
        let oid = item.displayingObject()?.oid ?? 0
        return String(format: "0x%lx", oid)
    }

    /// Encodes any `Encodable` value into the loose `LKMCPBridgeJSONValue`
    /// tree used inside response frame `result` containers. Round-trips
    /// through `JSONEncoder` / `JSONDecoder` so non-trivial nested types
    /// (arrays, optionals, etc.) preserve their wire shape.
    private func encodeAsJSONValue(_ value: some Encodable) throws -> LKMCPBridgeJSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(LKMCPBridgeJSONValue.self, from: data)
    }
}
