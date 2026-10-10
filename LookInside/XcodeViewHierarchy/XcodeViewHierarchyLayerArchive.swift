// XcodeViewHierarchyLayerArchive.swift
//
// Decodes the `encodedPresentationLayer` payloads in a `.viewhierarchy`
// capture, and pairs the layers they contain with the objects the capture
// describes.
//
// These archives are where the pixels are. A capture stores per-view snapshot
// images only for the few cases compositing cannot reproduce — blur backdrops
// and symbol images — so a reader that uses only those snapshots recovers
// almost nothing: in a measured UIKit capture, 76 snapshots against 502 view
// nodes, and in an AppKit one, a single snapshot against 1019.
//
// The payload is an NSKeyedArchiver archive whose root is a dictionary
// `{ "rootLayer": CALayer, "geometryFlipped": Bool }`, with arrays wrapped in
// QuartzCore's private `LKNSArrayCodingProxy`. Those private classes live in
// QuartzCore itself, so an ordinary process decodes them without help — but
// only with secure coding switched off, because the archive names classes no
// allow-list can be written for in advance.
//
// Pairing archived layers back to captured objects has to be structural: an
// archived CALayer carries no object identifier. Two shapes occur, and both
// are handled here:
//
//   * The archived tree matches the captured layer tree exactly. Measured on
//     AppKit captures (1470 of 1470 layers, and 167 of 167 in a second file).
//   * The archived tree is a superset. Measured on UIKit captures (974
//     archived against 580 captured), where the extra layers are internals a
//     view owns but Xcode does not surface as nodes. They are matched around
//     rather than to a node; their pixels still reach the image of whichever
//     captured layer contains them.

import AppKit
import Foundation
import QuartzCore

struct XcodeViewHierarchyLayerTree {
    /// Object identifier of the captured layer this archive is rooted at.
    let rootObjectIdentifier: String
    let rootLayer: CALayer
    /// True for a y-down tree (UIKit captures); AppKit captures leave it false.
    let isGeometryFlipped: Bool
}

enum XcodeViewHierarchyLayerArchive {
    static let propertyName = "encodedPresentationLayer"
    private static let rootLayerKey = "rootLayer"
    private static let geometryFlippedKey = "geometryFlipped"

    /// Decodes every layer archive the capture carries, in a stable order.
    static func decodingLayerTrees(
        in graph: XcodeViewHierarchyObjectGraph
    ) -> (trees: [XcodeViewHierarchyLayerTree], failedIdentifiers: [String]) {
        var trees: [XcodeViewHierarchyLayerTree] = []
        var failedIdentifiers: [String] = []

        for objectIdentifier in graph.nodesByIdentifier.keys.sorted() {
            guard let node = graph.node(objectIdentifier),
                  let property = node.property(named: propertyName),
                  case let .binaryData(archiveData) = property.value
            else { continue }

            if let tree = decodingLayerTree(from: archiveData, rootObjectIdentifier: objectIdentifier) {
                trees.append(tree)
            } else {
                failedIdentifiers.append(objectIdentifier)
            }
        }
        return (trees, failedIdentifiers)
    }

    static func decodingLayerTree(from archiveData: Data, rootObjectIdentifier: String) -> XcodeViewHierarchyLayerTree? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: archiveData) else { return nil }
        // The archive names QuartzCore's private coding proxies, which cannot
        // be declared to a secure unarchiver ahead of time.
        unarchiver.requiresSecureCoding = false
        defer { unarchiver.finishDecoding() }

        guard let root = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [String: Any],
              let rootLayer = root[rootLayerKey] as? CALayer
        else { return nil }

        return XcodeViewHierarchyLayerTree(
            rootObjectIdentifier: rootObjectIdentifier,
            rootLayer: rootLayer,
            isGeometryFlipped: (root[geometryFlippedKey] as? NSNumber)?.boolValue ?? false
        )
    }
}

// MARK: - Alignment

/// Pairs captured layer objects with the archived layers that hold their pixels.
enum XcodeViewHierarchyLayerAlignment {
    /// Positional tolerance when matching a captured layer to an archived one.
    ///
    /// The archive holds the *presentation* layer while the capture's numbers
    /// come from the model layer, so a capture taken mid-animation can disagree
    /// slightly. A tolerance of half a point accepts that without letting two
    /// genuinely different sublayers match.
    private static let geometryTolerance = 0.5

    /// Maps captured layer object identifiers to archived layers.
    static func aligning(
        trees: [XcodeViewHierarchyLayerTree],
        graph: XcodeViewHierarchyObjectGraph
    ) -> [String: CALayer] {
        var alignment: [String: CALayer] = [:]
        for tree in trees {
            aligning(
                capturedIdentifier: tree.rootObjectIdentifier,
                archivedLayer: tree.rootLayer,
                graph: graph,
                into: &alignment
            )
        }
        return alignment
    }

    private static func aligning(
        capturedIdentifier: String,
        archivedLayer: CALayer,
        graph: XcodeViewHierarchyObjectGraph,
        into alignment: inout [String: CALayer]
    ) {
        // A layer reached twice would mean a cycle in the capture; stop rather
        // than recurse forever.
        guard alignment[capturedIdentifier] == nil else { return }
        alignment[capturedIdentifier] = archivedLayer

        guard let capturedNode = graph.node(capturedIdentifier) else { return }
        let capturedChildren = capturedNode.childIdentifiers
        guard !capturedChildren.isEmpty else { return }
        let archivedChildren = archivedLayer.sublayers ?? []
        guard !archivedChildren.isEmpty else { return }

        let pairings = pairing(
            capturedChildren: capturedChildren,
            archivedChildren: archivedChildren,
            graph: graph
        )
        for (capturedChild, archivedChild) in pairings {
            aligning(
                capturedIdentifier: capturedChild,
                archivedLayer: archivedChild,
                graph: graph,
                into: &alignment
            )
        }
    }

    /// Pairs one level of children.
    ///
    /// Equal counts are the common case and pair by position, which is exact.
    /// Otherwise the archived list is a superset, and captured children are
    /// matched to it in order by geometry, skipping the archived internals in
    /// between.
    private static func pairing(
        capturedChildren: [String],
        archivedChildren: [CALayer],
        graph: XcodeViewHierarchyObjectGraph
    ) -> [(String, CALayer)] {
        if capturedChildren.count == archivedChildren.count {
            return Array(zip(capturedChildren, archivedChildren))
        }

        var pairings: [(String, CALayer)] = []
        var searchStart = 0
        for capturedChild in capturedChildren {
            let capturedGeometry = geometry(ofCapturedLayer: capturedChild, graph: graph)
            var matchIndex: Int?
            for index in searchStart ..< archivedChildren.count {
                if matches(capturedGeometry: capturedGeometry, archivedLayer: archivedChildren[index]) {
                    matchIndex = index
                    break
                }
            }
            guard let matchIndex else { continue }
            pairings.append((capturedChild, archivedChildren[matchIndex]))
            searchStart = matchIndex + 1
        }
        return pairings
    }

    private struct CapturedGeometry {
        let bounds: CGRect?
        let position: CGPoint?
    }

    private static func geometry(
        ofCapturedLayer objectIdentifier: String,
        graph: XcodeViewHierarchyObjectGraph
    ) -> CapturedGeometry {
        guard let node = graph.node(objectIdentifier) else {
            return CapturedGeometry(bounds: nil, position: nil)
        }
        var bounds: CGRect?
        if let components = node.property(named: "bounds")?.value.numericComponents(expectedCount: 4) {
            bounds = CGRect(x: components[0], y: components[1], width: components[2], height: components[3])
        }
        var position: CGPoint?
        if let components = node.property(named: "position")?.value.numericComponents(expectedCount: 2) {
            position = CGPoint(x: components[0], y: components[1])
        }
        return CapturedGeometry(bounds: bounds, position: position)
    }

    private static func matches(capturedGeometry: CapturedGeometry, archivedLayer: CALayer) -> Bool {
        // With nothing recorded to compare, accept the next archived layer
        // rather than abandon the whole subtree.
        guard capturedGeometry.bounds != nil || capturedGeometry.position != nil else { return true }

        if let bounds = capturedGeometry.bounds {
            let archivedBounds = archivedLayer.bounds
            guard abs(bounds.size.width - archivedBounds.size.width) <= geometryTolerance,
                  abs(bounds.size.height - archivedBounds.size.height) <= geometryTolerance
            else { return false }
        }
        if let position = capturedGeometry.position {
            let archivedPosition = archivedLayer.position
            guard abs(position.x - archivedPosition.x) <= geometryTolerance,
                  abs(position.y - archivedPosition.y) <= geometryTolerance
            else { return false }
        }
        return true
    }
}
