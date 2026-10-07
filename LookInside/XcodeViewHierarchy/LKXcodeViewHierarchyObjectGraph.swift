// LKXcodeViewHierarchyObjectGraph.swift
//
// Assembles the object graph a `.viewhierarchy` capture describes, by merging
// the several JSON responses a capture is split across.
//
// The shape of the data, and the merge rules, are Xcode's own — recovered from
// `DBGDataCoordinatorTargetHub` in DebugHierarchyKit. Four of them matter, and
// getting any one wrong produces a tree that looks plausible and is wrong:
//
//  1. **Objects are global and merged by `objectID`.** A capture writes the
//     same object into several responses; the later ones refine the earlier.
//     Treating each occurrence as a new node duplicates half the hierarchy.
//  2. **`childGroup` is the real hierarchy; `additionalGroups` is not.** The
//     child group holds owned children (a view's subviews); additional groups
//     hold associated objects (the view's layer, its constraints, its view
//     controller). Folding the second into the first turns a view tree into a
//     tangle.
//  3. **A dictionary without a `className` is a reference, not an object.**
//     It names an object described in full elsewhere. Applying it as an update
//     erases the real entry's class and properties.
//  4. **Properties arrive out of band.** Most values live in
//     `topLevelPropertyDescriptions`, keyed `"<objectID>.<propertyName>"`, in a
//     later response than the object itself.
//
// A fifth rule is this reader's own, and departs from Xcode's:
//
//  5. **A response with `topLevelGroups` is a whole new capture.** Xcode
//     records every request of a session, so a document holds one hierarchy
//     response per capture — complete on its own, followed by that capture's
//     property responses. Objects freed between captures have their addresses
//     reused by unrelated objects, so merging captures by `objectID` leaves
//     stale views beside their replacements, and can make two objects each
//     other's child — the shape that sends Xcode's own reader into unbounded
//     recursion when it opens such a document. The latest capture is the
//     document; everything before it is discarded whole.
//
// Everything here is Foundation-only and free of the app's Objective-C model,
// which is what lets it be unit tested by compiling this file with its test.

import Foundation

// MARK: - Property

struct LKXcodeViewHierarchyProperty {
    let name: String
    let runtimeTypeName: String?
    let logicalTypeName: String?
    let format: String?
    let value: LKXcodeViewHierarchyValue
    let fetchStatus: LKXcodeViewHierarchyFetchStatus
}

// MARK: - Node

/// One object in the capture. Reference semantics because the same node is
/// reached from several responses and refined in place.
final class LKXcodeViewHierarchyNode {
    let objectIdentifier: String
    /// Nil until a response describes this object in full rather than referencing it.
    var className: String?
    /// The grouping the object was first described under, e.g. `com.apple.UIKit.UIView`.
    var groupingIdentifier: String?
    var visibility: Int?
    /// Owned children, in capture order — the real hierarchy.
    var childIdentifiers: [String] = []
    /// Associated objects by grouping identifier, in capture order.
    var additionalGroups: [(groupingIdentifier: String, objectIdentifiers: [String])] = []
    var properties: [String: LKXcodeViewHierarchyProperty] = [:]

    init(objectIdentifier: String) {
        self.objectIdentifier = objectIdentifier
    }

    /// The identifiers of every object associated under one grouping.
    func associatedIdentifiers(inGroup groupingIdentifier: String) -> [String] {
        additionalGroups.first { $0.groupingIdentifier == groupingIdentifier }?.objectIdentifiers ?? []
    }

    func property(named name: String) -> LKXcodeViewHierarchyProperty? {
        properties[name]
    }
}

// MARK: - Graph

struct LKXcodeViewHierarchyObjectGraph {
    let nodesByIdentifier: [String: LKXcodeViewHierarchyNode]
    /// Top-level groupings in capture order, each with its root objects.
    let rootGroups: [(groupingIdentifier: String, objectIdentifiers: [String])]
    /// Superclass of each class the capture described, from `classInformation`.
    let superclassByClassName: [String: String]
    /// Highest `version` seen across the responses that were merged.
    let formatVersion: Int
    /// Non-fatal problems worth surfacing; a capture still opens with these.
    let decodingIssues: [String]
    /// How many hierarchy captures the document held. Only the last one is
    /// represented here; see rule 5 in the file comment.
    let captureCount: Int

    func node(_ objectIdentifier: String) -> LKXcodeViewHierarchyNode? {
        nodesByIdentifier[objectIdentifier]
    }

    func rootIdentifiers(inGroup groupingIdentifier: String) -> [String] {
        rootGroups.first { $0.groupingIdentifier == groupingIdentifier }?.objectIdentifiers ?? []
    }

    /// The class and its ancestors, e.g. `["UILabel", "UIView", "UIResponder", "NSObject"]`.
    ///
    /// The inspector shows this chain and searches it, so a bare leaf name
    /// makes a node look like it has no lineage at all.
    func classChain(forClassName className: String) -> [String] {
        var chain: [String] = [className]
        var visited: Set<String> = [className]
        var current = className
        // The capture's class table is a tree, but guard the walk anyway: a
        // malformed one must not spin here.
        while let superclassName = superclassByClassName[current], visited.insert(superclassName).inserted {
            chain.append(superclassName)
            current = superclassName
        }
        return chain
    }
}

// MARK: - Builder

final class LKXcodeViewHierarchyObjectGraphBuilder {
    private var nodesByIdentifier: [String: LKXcodeViewHierarchyNode] = [:]
    private var rootGroupOrder: [String] = []
    private var rootGroupMembers: [String: [String]] = [:]
    private var superclassByClassName: [String: String] = [:]
    private var formatVersion = 0
    private var decodingIssues: [String] = []
    private var captureCount = 0

    /// Cap on recorded issues; a badly mismatched capture must not fill memory
    /// with one message per property.
    private let issueLimit = 200

    init() {}

    // MARK: Ingestion

    /// Merges one response's contents into the graph. Responses must be fed
    /// in capture order: a hierarchy response starts a new capture, and the
    /// property responses after it refine that capture's objects.
    func ingesting(response: [String: Any]) {
        let responseVersion = (response["version"] as? NSNumber)?.intValue ?? 0
        formatVersion = max(formatVersion, responseVersion)

        if let topLevelGroups = response["topLevelGroups"] as? [String: Any], !topLevelGroups.isEmpty {
            // Rule 5: a new capture replaces everything before it. Only the
            // capture's "Initial request" response carries root groups; the
            // fetches that follow it ship an empty dictionary under this key.
            beginningCapture()
            // Dictionary iteration order is unstable, so sort for a deterministic
            // graph: two reads of the same file must produce the same tree.
            for groupingIdentifier in topLevelGroups.keys.sorted() {
                guard let group = topLevelGroups[groupingIdentifier] as? [String: Any] else { continue }
                ingestingGroup(group, isOwnedChildGroup: true, parent: nil)
            }
        }

        if let classInformation = response["classInformation"] as? [Any] {
            for rawEntry in classInformation {
                guard let entry = rawEntry as? [String: Any] else { continue }
                ingestingClassInformation(entry, superclassName: nil)
            }
        }

        if let descriptions = response["topLevelPropertyDescriptions"] as? [String: Any] {
            for (keyPath, rawDescription) in descriptions {
                guard let description = rawDescription as? [String: Any] else { continue }
                ingestingTopLevelPropertyDescription(description, keyPath: keyPath, responseVersion: responseVersion)
            }
        }
    }

    /// Walks the capture's class table, which is nested by *subclass*, and
    /// records the inverse — each class's superclass — because that is the
    /// direction a node's class chain is read in.
    private func ingestingClassInformation(_ entry: [String: Any], superclassName: String?) {
        guard let className = entry["className"] as? String else { return }
        if let superclassName, superclassByClassName[className] == nil {
            superclassByClassName[className] = superclassName
        }
        guard let subclasses = entry["subclasses"] as? [Any] else { return }
        for rawSubclass in subclasses {
            guard let subclass = rawSubclass as? [String: Any] else { continue }
            ingestingClassInformation(subclass, superclassName: className)
        }
    }

    private func ingestingGroup(_ group: [String: Any], isOwnedChildGroup: Bool, parent: LKXcodeViewHierarchyNode?) {
        let groupingIdentifier = group["groupingID"] as? String ?? ""
        let objects = group["debugHierarchyObjects"] as? [Any] ?? []

        var memberIdentifiers: [String] = []
        for rawObject in objects {
            guard let object = rawObject as? [String: Any],
                  let objectIdentifier = object["objectID"] as? String
            else { continue }
            memberIdentifiers.append(objectIdentifier)
            ingestingObject(object, groupingIdentifier: groupingIdentifier)
        }

        guard !memberIdentifiers.isEmpty || parent != nil else { return }

        if let parent {
            if isOwnedChildGroup {
                parent.childIdentifiers = mergingPreservingOrder(parent.childIdentifiers, memberIdentifiers)
            } else {
                appendingAdditionalGroup(
                    groupingIdentifier: groupingIdentifier,
                    objectIdentifiers: memberIdentifiers,
                    to: parent
                )
            }
        } else {
            if rootGroupMembers[groupingIdentifier] == nil {
                rootGroupOrder.append(groupingIdentifier)
                rootGroupMembers[groupingIdentifier] = []
            }
            rootGroupMembers[groupingIdentifier] = mergingPreservingOrder(
                rootGroupMembers[groupingIdentifier] ?? [], memberIdentifiers
            )
        }
    }

    private func ingestingObject(_ object: [String: Any], groupingIdentifier: String) {
        guard let objectIdentifier = object["objectID"] as? String else { return }
        let node = nodeForIdentifier(objectIdentifier)

        // Rule 3: a reference names an object described elsewhere. Recording its
        // identifier (done by the caller) is all it may contribute.
        if !describesObjectInFull(object) {
            return
        }

        if let className = object["className"] as? String {
            node.className = className
        }
        if node.groupingIdentifier == nil, !groupingIdentifier.isEmpty {
            node.groupingIdentifier = groupingIdentifier
        }
        if let visibility = (object["visibility"] as? NSNumber)?.intValue {
            node.visibility = visibility
        }

        if let inlineProperties = object["properties"] as? [Any] {
            for rawProperty in inlineProperties {
                guard let description = rawProperty as? [String: Any] else { continue }
                applyingPropertyDescription(description, to: node, responseVersion: formatVersion)
            }
        }

        if let childGroup = object["childGroup"] as? [String: Any] {
            ingestingGroup(childGroup, isOwnedChildGroup: true, parent: node)
        }
        if let additionalGroups = object["additionalGroups"] as? [Any] {
            for rawGroup in additionalGroups {
                guard let group = rawGroup as? [String: Any] else { continue }
                ingestingGroup(group, isOwnedChildGroup: false, parent: node)
            }
        }
    }

    /// Distinguishes a full description from a bare reference to one.
    ///
    /// A reference carries the identifier plus the property metadata of the slot
    /// that points at it (`propertyLogicalType`, `propertyVisibility`) and never
    /// a `className`.
    private func describesObjectInFull(_ object: [String: Any]) -> Bool {
        if object["className"] != nil {
            return true
        }
        if object["childGroup"] != nil || object["additionalGroups"] != nil || object["properties"] != nil {
            return true
        }
        return false
    }

    private func ingestingTopLevelPropertyDescription(
        _ description: [String: Any],
        keyPath: String,
        responseVersion: Int
    ) {
        guard let separatorIndex = keyPath.firstIndex(of: ".") else { return }
        let objectIdentifier = String(keyPath[keyPath.startIndex ..< separatorIndex])
        guard !objectIdentifier.isEmpty else { return }

        // A property may arrive for an object this build never saw described;
        // creating the node keeps the value rather than dropping it.
        let node = nodeForIdentifier(objectIdentifier)

        var resolvedDescription = description
        if resolvedDescription["propertyName"] == nil {
            let propertyName = String(keyPath[keyPath.index(after: separatorIndex)...])
            resolvedDescription["propertyName"] = propertyName
        }
        applyingPropertyDescription(resolvedDescription, to: node, responseVersion: responseVersion)
    }

    // MARK: Property application

    private func applyingPropertyDescription(
        _ rawDescription: [String: Any],
        to node: LKXcodeViewHierarchyNode,
        responseVersion: Int
    ) {
        let description = modernizingPropertyDescription(rawDescription, responseVersion: responseVersion)
        guard let propertyName = description["propertyName"] as? String else { return }

        let fetchStatusValue = (description["fetchStatus"] as? NSNumber)?.intValue ?? 0
        let fetchStatus = LKXcodeViewHierarchyFetchStatus(rawValue: fetchStatusValue) ?? .failed

        // Rule from Xcode's reader: a failed or unchanged fetch must not
        // overwrite what an earlier response already established.
        if fetchStatus.skipsValueApplication, node.properties[propertyName] != nil {
            return
        }

        let format = description["propertyFormat"] as? String
        var decodedValue = LKXcodeViewHierarchyValue.absent
        if fetchStatus == .retrieved, let format, !format.isEmpty {
            do {
                decodedValue = try LKXcodeViewHierarchyValueDecoder.decoding(
                    jsonValue: description["propertyValue"], format: format
                )
            } catch {
                recordIssue("\(node.objectIdentifier).\(propertyName): \(error)")
                decodedValue = .absent
            }
        }

        node.properties[propertyName] = LKXcodeViewHierarchyProperty(
            name: propertyName,
            runtimeTypeName: description["propertyRuntimeType"] as? String,
            logicalTypeName: description["propertyLogicalType"] as? String,
            format: format,
            value: decodedValue,
            fetchStatus: fetchStatus
        )
    }

    /// Rewrites a version-1 property description into the modern shape.
    ///
    /// Version 1 spelled the outcome `propertyValueStatus` with a different set
    /// of codes; Xcode still migrates them on read, so old exports open. The
    /// mapping is taken from `compatibility_modernizedPropertyDescription:targetVersion:`.
    private func modernizingPropertyDescription(
        _ description: [String: Any],
        responseVersion: Int
    ) -> [String: Any] {
        guard responseVersion == 1 else { return description }

        var modernized = description
        if let statusNumber = description["propertyValueStatus"] as? NSNumber {
            switch statusNumber.intValue {
            case 0:
                modernized["fetchStatus"] = NSNumber(value: 4)
            case 1:
                modernized.removeValue(forKey: "propertyValue")
                modernized["fetchStatus"] = NSNumber(value: 4)
            case 3:
                modernized["fetchStatus"] = NSNumber(value: 8)
            default:
                modernized["fetchStatus"] = NSNumber(value: 0)
            }
        } else {
            modernized["fetchStatus"] = NSNumber(value: description["propertyValue"] != nil ? 4 : 1)
        }
        return modernized
    }

    // MARK: Bookkeeping

    /// Drops the previous capture. Each capture ships its own class table and
    /// its own property responses, so nothing from before it is still needed,
    /// and keeping any of it is how stale objects get back into the tree.
    private func beginningCapture() {
        captureCount += 1
        nodesByIdentifier.removeAll()
        rootGroupOrder.removeAll()
        rootGroupMembers.removeAll()
        superclassByClassName.removeAll()
        decodingIssues.removeAll()
    }

    private func nodeForIdentifier(_ objectIdentifier: String) -> LKXcodeViewHierarchyNode {
        if let existing = nodesByIdentifier[objectIdentifier] {
            return existing
        }
        let created = LKXcodeViewHierarchyNode(objectIdentifier: objectIdentifier)
        nodesByIdentifier[objectIdentifier] = created
        return created
    }

    private func appendingAdditionalGroup(
        groupingIdentifier: String,
        objectIdentifiers: [String],
        to node: LKXcodeViewHierarchyNode
    ) {
        if let existingIndex = node.additionalGroups.firstIndex(where: { $0.groupingIdentifier == groupingIdentifier }) {
            let merged = mergingPreservingOrder(
                node.additionalGroups[existingIndex].objectIdentifiers, objectIdentifiers
            )
            node.additionalGroups[existingIndex] = (groupingIdentifier, merged)
        } else {
            node.additionalGroups.append((groupingIdentifier, objectIdentifiers))
        }
    }

    /// Appends identifiers not already present, keeping first-seen order.
    private func mergingPreservingOrder(_ existing: [String], _ incoming: [String]) -> [String] {
        guard !existing.isEmpty else { return incoming }
        var merged = existing
        var seen = Set(existing)
        for identifier in incoming where !seen.contains(identifier) {
            merged.append(identifier)
            seen.insert(identifier)
        }
        return merged
    }

    private func recordIssue(_ message: String) {
        guard decodingIssues.count < issueLimit else { return }
        decodingIssues.append(message)
    }

    // MARK: Result

    func build() -> LKXcodeViewHierarchyObjectGraph {
        LKXcodeViewHierarchyObjectGraph(
            nodesByIdentifier: nodesByIdentifier,
            rootGroups: rootGroupOrder.map { ($0, rootGroupMembers[$0] ?? []) },
            superclassByClassName: superclassByClassName,
            formatVersion: formatVersion,
            decodingIssues: decodingIssues,
            captureCount: captureCount
        )
    }
}
