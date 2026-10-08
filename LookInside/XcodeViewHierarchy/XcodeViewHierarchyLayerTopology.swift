// XcodeViewHierarchyLayerTopology.swift
//
// Which layers of a capture back a view, and how the layer tree hangs
// together. Shared by pixel recovery (which sublayers to hide when a layer
// node is rendered without the views beneath it) and by conversion (which
// sublayers become nodes of their own, and where a subview sits in its
// superview's z order).
//
// "Hosted" here is what the server calls a layer with a host view, plus the
// wrapper UIKit installs above a view's backing layer on iOS 26: in a capture
// the view's `layer` association points at that wrapper, so the wrapper is
// the hosted layer and the real backing layer sits one level below it.

import Foundation

struct XcodeViewHierarchyLayerTopology {
    static let layerGroupingIdentifier = "com.apple.QuartzCore.CALayer"

    /// Layers some captured object owns as its `layer`: views and, on UIKit,
    /// windows. On iOS 26 that is the `_UIMultiLayer` wrapper, not the backing
    /// layer beneath it.
    let hostedLayerIdentifiers: Set<String>
    /// Superlayer of every layer that has one.
    let parentByLayerIdentifier: [String: String]

    init(graph: XcodeViewHierarchyObjectGraph) {
        var hosted: Set<String> = []
        var parents: [String: String] = [:]
        for (identifier, node) in graph.nodesByIdentifier {
            for layerIdentifier in node.associatedIdentifiers(inGroup: Self.layerGroupingIdentifier) {
                hosted.insert(layerIdentifier)
            }
            if node.groupingIdentifier == Self.layerGroupingIdentifier {
                for childIdentifier in node.childIdentifiers {
                    parents[childIdentifier] = identifier
                }
            }
        }
        hostedLayerIdentifiers = hosted
        parentByLayerIdentifier = parents
    }

    func isHosted(_ layerIdentifier: String) -> Bool {
        hostedLayerIdentifiers.contains(layerIdentifier)
    }

    /// The hosted layers below `layerIdentifier`, in tree order, without
    /// descending into them: the planes on which the views beneath a layer
    /// render, which a layer node's own image must leave out.
    func hostedDescendantIdentifiers(
        of layerIdentifier: String,
        graph: XcodeViewHierarchyObjectGraph
    ) -> [String] {
        var collected: [String] = []
        var visited: Set<String> = [layerIdentifier]
        func visiting(_ identifier: String) {
            guard let node = graph.node(identifier) else { return }
            for childIdentifier in node.childIdentifiers where visited.insert(childIdentifier).inserted {
                if hostedLayerIdentifiers.contains(childIdentifier) {
                    collected.append(childIdentifier)
                } else {
                    visiting(childIdentifier)
                }
            }
        }
        visiting(layerIdentifier)
        return collected
    }

    /// The child of `ancestorIdentifier` on the way down to `layerIdentifier`,
    /// or nil when the layer is not below it. A subview's z position in its
    /// superview is the position of this child among the superview's
    /// sublayers — on macOS 26 AppKit inserts container layers, so a subview's
    /// layer is not always a direct sublayer.
    func childOfAncestor(
        _ ancestorIdentifier: String,
        onPathTo layerIdentifier: String
    ) -> String? {
        var current = layerIdentifier
        var visited: Set<String> = [current]
        while let parent = parentByLayerIdentifier[current] {
            if parent == ancestorIdentifier {
                return current
            }
            guard visited.insert(parent).inserted else { return nil }
            current = parent
        }
        return nil
    }
}
