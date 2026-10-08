// LKXcodeViewHierarchyAttributes.swift
//
// Builds the attribute cards the dashboard shows for a node imported from an
// Xcode capture.
//
// A live session answers attribute queries on demand and a `.lookin` archive
// carries the answers on each node; an imported capture has to do the same,
// which is what this file produces. The identifiers are the inspector's own
// (`LookinAttrGroup_*`, `LookinAttrSec_*`, `LookinAttr_*`) so the cards render
// with their normal titles, ordering and editors rather than as anonymous
// key-value rows — with the editors inert, since the document is read-only.
//
// The card order and the capture property behind each row live in
// `LKXcodeViewHierarchyAttributeCatalog`. This file walks that catalog, gates
// each row on the node's class chain, and converts the decoded capture value
// into the value type the card expects. A few rows are not one property but a
// derivation — the class chains, the relations, the Auto Layout constraints,
// a scene's window count — and are built here directly, the way the server's
// `lks_relatedClassChainList` / `lks_selfRelation` / `lks_constraints`
// derive them for a live session.
//
// Two of the server's rules are kept so an imported capture reads like a live
// one: the Auto Layout card is dropped when it has no constraints (sizing
// priorities alone are not worth a card), and a row whose value is nil is
// kept or hidden according to the blueprint's `hideIfNil` — a label with no
// text still shows its Text row; a view with no image shows no image rows.

import AppKit
import Foundation

// MARK: - Context

/// Per-conversion facts the cards need beyond a node's own properties.
struct LKXcodeViewHierarchyAttributeEnvironment {
    let isAppKit: Bool
    let constraintIndex: LKXcodeViewHierarchyConstraintIndex
    /// The window the application object names as key, if the capture says.
    let keyWindowIdentifier: String?
}

/// What a node is to the inspector, and which neighbours its cards refer to.
struct LKXcodeViewHierarchyAttributeContext {
    enum Role {
        /// A view, including a UIKit window, which is a view too.
        case view
        /// An AppKit window, which is not a view.
        case window
        case windowScene
        case cell
        case layoutGuide
        /// A layer that is a node of its own: an orphan sublayer, a view's
        /// backing layer with the show-backing-layers toggle on, or the
        /// wrapper UIKit puts above it. Its cards are the pure layer rows,
        /// as the server's `attrGroupsForLayer:` gives a hostless layer.
        case layer
    }

    let role: Role
    let environment: LKXcodeViewHierarchyAttributeEnvironment
    /// The controller whose view this is (or a window's root view controller).
    var viewControllerNode: LKXcodeViewHierarchyNode? = nil
    /// An AppKit window's controller.
    var windowControllerNode: LKXcodeViewHierarchyNode? = nil
    /// The control owning a cell, or the view owning a layout guide.
    var ownerNode: LKXcodeViewHierarchyNode? = nil
    /// The node's parent in the tree, for typing constraint endpoints.
    var superviewNode: LKXcodeViewHierarchyNode? = nil
    /// The windows listed under a scene, after Xcode's skip rule.
    var sceneWindowNodes: [LKXcodeViewHierarchyNode] = []
}

// MARK: - Constraint index

/// Which constraints mention which object, built once per capture.
///
/// A capture lists every `NSLayoutConstraint` in a root group of its own, and
/// a view's Auto Layout card wants the constraints that involve that view —
/// the server's `lks_involvedRawConstraints`. Walking the whole group per
/// view would be quadratic on captures with thousands of constraints.
final class LKXcodeViewHierarchyConstraintIndex {
    private static let constraintClassName = "NSLayoutConstraint"
    private static let endpointPropertyNames = ["firstItem", "secondItem"]

    private let constraintIdentifiersByItemIdentifier: [String: [String]]

    init(graph: LKXcodeViewHierarchyObjectGraph) {
        var index: [String: [String]] = [:]
        // Dictionary order is unstable; sort so two imports of one capture
        // list a view's constraints in the same order.
        for constraintIdentifier in graph.nodesByIdentifier.keys.sorted() {
            guard let constraintNode = graph.node(constraintIdentifier),
                  Self.isConstraint(constraintNode, graph: graph)
            else { continue }
            var itemIdentifiers: Set<String> = []
            for endpointPropertyName in Self.endpointPropertyNames {
                guard case let .objectReference(reference)? = constraintNode.property(named: endpointPropertyName)?.value
                else { continue }
                itemIdentifiers.insert(reference.objectIdentifier)
            }
            for itemIdentifier in itemIdentifiers {
                index[itemIdentifier, default: []].append(constraintIdentifier)
            }
        }
        constraintIdentifiersByItemIdentifier = index
    }

    func constraintIdentifiers(involving itemIdentifier: String) -> [String] {
        constraintIdentifiersByItemIdentifier[itemIdentifier] ?? []
    }

    private static func isConstraint(_ node: LKXcodeViewHierarchyNode, graph: LKXcodeViewHierarchyObjectGraph) -> Bool {
        if node.groupingIdentifier?.hasSuffix("." + constraintClassName) == true {
            return true
        }
        guard let className = node.className else { return false }
        return graph.classChain(forClassName: className).contains(constraintClassName)
    }
}

// MARK: - Builder

enum LKXcodeViewHierarchyAttributes {
    private typealias Catalog = LKXcodeViewHierarchyAttributeCatalog
    private typealias Specification = LKXcodeViewHierarchyAttributeSpecification

    private enum GroupIdentifier {
        static let cell = "com.apple.AppKit.NSCell"
    }

    /// Class names that end the chains the Class card shows, per role.
    private enum ChainEnd {
        static let view = ["UIView", "NSView"]
        static let viewController = ["UIViewController", "NSViewController"]
        static let window = "NSWindow"
        static let windowController = "NSWindowController"
        static let scene = "UIScene"
        static let cell = "NSCell"
        static let layoutGuide = ["UILayoutGuide", "NSLayoutGuide"]
        static let layer = "CALayer"
    }

    /// Builds every attribute group for one captured object, in card order.
    ///
    /// `layerNode` is the view's backing layer when it has one: several of the
    /// properties the Layout and View/Layer cards show (position, anchor point,
    /// corner radius, masks to bounds) live on the layer rather than the view.
    static func makingGroups(
        for node: LKXcodeViewHierarchyNode,
        layerNode: LKXcodeViewHierarchyNode?,
        graph: LKXcodeViewHierarchyObjectGraph,
        context: LKXcodeViewHierarchyAttributeContext
    ) -> [AttributesGroup] {
        let classChain = graph.classChain(forClassName: node.className ?? "NSObject")
        var groups: [AttributesGroup] = []
        for catalogGroup in Catalog.groups {
            var sections: [AttributesSection] = []
            for catalogSection in catalogGroup.sections {
                let attributes = catalogSection.attributes.compactMap { identifier in
                    makingAttribute(
                        identifier, node: node, layerNode: layerNode, classChain: classChain, graph: graph, context: context
                    )
                }
                if !attributes.isEmpty {
                    sections.append(makingSection(catalogSection.identifier, attributes))
                }
            }
            // The server drops an Auto Layout card that holds only sizing
            // priorities; a view with no constraints gets no card.
            if catalogGroup.identifier == LookinAttrGroup_AutoLayout,
               !sections.contains(where: { $0.identifier == LookinAttrSec_AutoLayout_Constraints })
            {
                continue
            }
            if !sections.isEmpty {
                groups.append(makingGroup(catalogGroup.identifier, sections))
            }
        }
        return groups
    }

    // MARK: - One attribute

    private static func makingAttribute(
        _ identifier: String,
        node: LKXcodeViewHierarchyNode,
        layerNode: LKXcodeViewHierarchyNode?,
        classChain: [String],
        graph: LKXcodeViewHierarchyObjectGraph,
        context: LKXcodeViewHierarchyAttributeContext
    ) -> InspectedAttribute? {
        switch identifier {
        case LookinAttr_Class_Class_Class:
            let chains = relatedClassChains(classChain, graph: graph, context: context)
            return makingAttribute(identifier, .customObj, chains as NSArray)

        case LookinAttr_Relation_Relation_Relation:
            let relations = relationDescriptions(for: node, context: context)
            guard !relations.isEmpty else { return nil }
            return makingAttribute(identifier, .customObj, relations as NSArray)

        case LookinAttr_AutoLayout_Constraints_Constraints:
            guard context.role == .view else { return nil }
            let constraints = makingConstraints(for: node, graph: graph, context: context)
            guard !constraints.isEmpty else { return nil }
            return makingAttribute(identifier, .customObj, constraints as NSArray)

        case LookinAttr_UIWindowScene_Windows_WindowCount:
            guard context.role == .windowScene else { return nil }
            return makingAttribute(identifier, .long, NSNumber(value: context.sceneWindowNodes.count))

        case LookinAttr_UIWindowScene_Windows_KeyWindowClassName:
            guard context.role == .windowScene,
                  let keyWindowIdentifier = context.environment.keyWindowIdentifier,
                  let keyWindowClassName = context.sceneWindowNodes
                  .first(where: { $0.objectIdentifier == keyWindowIdentifier })?.className
            else { return nil }
            return makingAttribute(identifier, .nsString, keyWindowClassName as NSString)

        case LookinAttr_LayoutGuide_OwningView_OwningView:
            guard context.role == .layoutGuide, let ownerNode = context.ownerNode, let ownerClassName = ownerNode.className
            else { return nil }
            // The server's shape: "UIView (0x...)".
            return makingAttribute(identifier, .nsString, "\(ownerClassName) (\(ownerNode.objectIdentifier))" as NSString)

        default:
            return makingSpecifiedAttribute(
                identifier, node: node, layerNode: layerNode, classChain: classChain, graph: graph, context: context
            )
        }
    }

    /// A row the catalog maps to a capture property.
    private static func makingSpecifiedAttribute(
        _ identifier: String,
        node: LKXcodeViewHierarchyNode,
        layerNode: LKXcodeViewHierarchyNode?,
        classChain: [String],
        graph: LKXcodeViewHierarchyObjectGraph,
        context: LKXcodeViewHierarchyAttributeContext
    ) -> InspectedAttribute? {
        guard let specification = Catalog.specifications[identifier] else { return nil }
        if context.role == .layer {
            // A hostless layer answers only the rows the blueprint aims at a
            // CALayer; the view rows have no object to read from.
            guard DashboardBlueprint.targetKind(forAttrID: identifier) == .layer else { return nil }
        } else {
            guard specification.classNames.isEmpty || specification.classNames.contains(where: classChain.contains)
            else { return nil }
        }
        guard let property = capturedProperty(for: specification, node: node, layerNode: layerNode, graph: graph)
        else { return nil }

        if case .absent = property.value {
            // A captured nil: shown as nil where the blueprint wants it shown.
            guard !DashboardBlueprint.hideIfNil(withAttrID: identifier),
                  let attrType = nilCapableAttrType(for: specification.kind)
            else { return nil }
            return makingAttribute(identifier, attrType, nil)
        }

        let isEnumeration = DashboardBlueprint.enumListName(withAttrID: identifier) != nil
        guard let converted = makingValue(property.value, kind: specification.kind, isEnumeration: isEnumeration)
        else { return nil }
        return makingAttribute(identifier, converted.attrType, converted.value)
    }

    /// The first of the specification's candidate properties present on the
    /// first of its candidate sources.
    private static func capturedProperty(
        for specification: Specification,
        node: LKXcodeViewHierarchyNode,
        layerNode: LKXcodeViewHierarchyNode?,
        graph: LKXcodeViewHierarchyObjectGraph
    ) -> LKXcodeViewHierarchyProperty? {
        let sourceNodes: [LKXcodeViewHierarchyNode?]
        switch specification.source {
        case .node: sourceNodes = [node]
        case .layer: sourceNodes = [layerNode]
        case .nodeThenLayer: sourceNodes = [node, layerNode]
        case .layerThenNode: sourceNodes = [layerNode, node]
        case .cell: sourceNodes = [cellNode(of: node, graph: graph)]
        case .screen: sourceNodes = [referencedNode(from: node, propertyName: "screen", graph: graph)]
        }
        for sourceNode in sourceNodes {
            guard let sourceNode else { continue }
            for propertyName in specification.properties {
                if let property = sourceNode.property(named: propertyName) {
                    return property
                }
            }
        }
        return nil
    }

    private static func cellNode(
        of node: LKXcodeViewHierarchyNode,
        graph: LKXcodeViewHierarchyObjectGraph
    ) -> LKXcodeViewHierarchyNode? {
        guard let cellIdentifier = node.associatedIdentifiers(inGroup: GroupIdentifier.cell).first else { return nil }
        return graph.node(cellIdentifier)
    }

    private static func referencedNode(
        from node: LKXcodeViewHierarchyNode,
        propertyName: String,
        graph: LKXcodeViewHierarchyObjectGraph
    ) -> LKXcodeViewHierarchyNode? {
        guard case let .objectReference(reference)? = node.property(named: propertyName)?.value else { return nil }
        return graph.node(reference.objectIdentifier)
    }

    // MARK: - Values

    /// The attribute value a decoded capture value becomes, typed the way the
    /// card for that kind reads it (`LookinAttrType.h`).
    private static func makingValue(
        _ value: LKXcodeViewHierarchyValue,
        kind: Specification.Kind,
        isEnumeration: Bool
    ) -> (attrType: LookinAttrType, value: Any)? {
        switch kind {
        case .bool:
            guard let boolValue = value.boolValue else { return nil }
            return (.BOOL, NSNumber(value: boolValue))

        case .integer:
            guard let integerValue = integerValue(of: value) else { return nil }
            return (isEnumeration ? .enumLong : .long, NSNumber(value: integerValue))

        case .number:
            guard let doubleValue = value.doubleValue else { return nil }
            return (.double, NSNumber(value: doubleValue))

        case .text:
            guard let text = value.textValue else { return nil }
            return (.nsString, text as NSString)

        case .color:
            guard case let .color(color) = value, let components = rgbaComponents(of: color) else { return nil }
            return (.uiColor, components as NSArray)

        case .rect:
            guard let components = value.numericComponents(expectedCount: 4) else { return nil }
            let rect = CGRect(x: components[0], y: components[1], width: components[2], height: components[3])
            return (.cgRect, NSValue(rect: rect))

        case .point:
            guard let components = value.numericComponents(expectedCount: 2) else { return nil }
            return (.cgPoint, NSValue(point: CGPoint(x: components[0], y: components[1])))

        case .size:
            guard let components = value.numericComponents(expectedCount: 2) else { return nil }
            return (.cgSize, NSValue(size: CGSize(width: components[0], height: components[1])))

        case .insets:
            // Both platforms write insets as top, left, bottom, right.
            guard let components = value.numericComponents(expectedCount: 4) else { return nil }
            let insets = NSEdgeInsets(top: components[0], left: components[1], bottom: components[2], right: components[3])
            return (.uiEdgeInsets, NSValue(edgeInsets: insets))

        case .sizeWidth:
            guard let components = value.numericComponents(expectedCount: 2) else { return nil }
            return (.double, NSNumber(value: components[0]))

        case .sizeHeight:
            guard let components = value.numericComponents(expectedCount: 2) else { return nil }
            return (.double, NSNumber(value: components[1]))

        case .fontName:
            guard case let .font(font) = value else { return nil }
            return (.nsString, font.fontName as NSString)

        case .fontSize:
            guard case let .font(font) = value else { return nil }
            return (.double, NSNumber(value: font.pointSize))

        case .imageName:
            guard case let .image(image) = value, let imageName = image.metadata?.imageName, !imageName.isEmpty
            else { return nil }
            return (.nsString, imageName as NSString)

        case .imageData:
            guard case let .image(image) = value else { return nil }
            return (.customObj, image.encodedData as NSData)

        case let .maskBit(bit):
            guard let integerValue = integerValue(of: value) else { return nil }
            return (.BOOL, NSNumber(value: (UInt64(bitPattern: integerValue) & bit) != 0))
        }
    }

    /// The type a nil value is reported under; nil for kinds that cannot be nil.
    private static func nilCapableAttrType(for kind: Specification.Kind) -> LookinAttrType? {
        switch kind {
        case .text, .fontName, .imageName: return .nsString
        case .color: return .uiColor
        default: return nil
        }
    }

    private static func integerValue(of value: LKXcodeViewHierarchyValue) -> Int64? {
        switch value {
        case let .integer(integer): return integer
        case let .unsignedInteger(unsigned): return Int64(bitPattern: unsigned)
        case let .number(number): return Int64(exactly: number.rounded())
        case let .boolean(flag): return flag ? 1 : 0
        default: return nil
        }
    }

    /// RGBA in 0...1, which is what a `LookinAttrTypeUIColor` value carries
    /// (`LookinAttrType.h`). The dashboard decodes that array itself and
    /// asserts on anything else, so no `NSColor` is built here.
    ///
    /// The capture writes a colour in its own space: RGB(A), gray(+alpha) for
    /// the system's white/black colours, and CMYK on occasion. The card only
    /// knows RGBA, so the others are converted, and wide-gamut components are
    /// clamped — an approximation the card can show rather than a row lost.
    private static func rgbaComponents(of color: LKXcodeViewHierarchyColor) -> [NSNumber]? {
        let components = color.components
        let rgba: [Double]
        switch components.count {
        case 4: rgba = components
        case 3: rgba = components + [1]
        case 2: rgba = [components[0], components[0], components[0], components[1]]
        case 1: rgba = [components[0], components[0], components[0], 1]
        case 5:
            let (cyan, magenta, yellow, black) = (components[0], components[1], components[2], components[3])
            rgba = [(1 - cyan) * (1 - black), (1 - magenta) * (1 - black), (1 - yellow) * (1 - black), components[4]]
        default: return nil
        }
        return rgba.map { NSNumber(value: min(max($0, 0), 1)) }
    }

    // MARK: - Class card

    /// The chains the Class card lists: the node's own, cut at the framework
    /// class the inspector considers the root of its kind, then its owning
    /// controller's cut the same way — the server's `lks_relatedClassChainList`.
    private static func relatedClassChains(
        _ classChain: [String],
        graph: LKXcodeViewHierarchyObjectGraph,
        context: LKXcodeViewHierarchyAttributeContext
    ) -> [[String]] {
        var chains: [[String]] = []
        switch context.role {
        case .view:
            chains.append(trimmingChain(classChain, throughAnyOf: ChainEnd.view))
            if let controllerChain = classChainOfNode(context.viewControllerNode, graph: graph) {
                chains.append(trimmingChain(controllerChain, throughAnyOf: ChainEnd.viewController))
            }
        case .window:
            chains.append(trimmingChain(classChain, throughAnyOf: [ChainEnd.window]))
            if let controllerChain = classChainOfNode(context.windowControllerNode, graph: graph) {
                chains.append(trimmingChain(controllerChain, throughAnyOf: [ChainEnd.windowController]))
            }
        case .windowScene:
            chains.append(trimmingChain(classChain, throughAnyOf: [ChainEnd.scene]))
        case .cell:
            chains.append(trimmingChain(classChain, throughAnyOf: [ChainEnd.cell]))
        case .layoutGuide:
            chains.append(trimmingChain(classChain, throughAnyOf: ChainEnd.layoutGuide))
        case .layer:
            chains.append(trimmingChain(classChain, throughAnyOf: [ChainEnd.layer]))
        }
        return chains
    }

    private static func classChainOfNode(
        _ node: LKXcodeViewHierarchyNode?,
        graph: LKXcodeViewHierarchyObjectGraph
    ) -> [String]? {
        guard let className = node?.className else { return nil }
        return graph.classChain(forClassName: className)
    }

    /// The chain up to and including the first of the ending classes; the
    /// whole chain when none of them is an ancestor.
    private static func trimmingChain(_ chain: [String], throughAnyOf endingClassNames: [String]) -> [String] {
        guard let endIndex = chain.firstIndex(where: endingClassNames.contains) else { return chain }
        return Array(chain[...endIndex])
    }

    // MARK: - Relation card

    /// The server's `lks_selfRelation` strings: who owns this object.
    private static func relationDescriptions(
        for node: LKXcodeViewHierarchyNode,
        context: LKXcodeViewHierarchyAttributeContext
    ) -> [String] {
        var relations: [String] = []
        switch context.role {
        case .view:
            if let controllerClassName = context.viewControllerNode?.className {
                relations.append("(\(controllerClassName) *).view")
            }
        case .window:
            if let controllerClassName = context.windowControllerNode?.className {
                relations.append("(\(controllerClassName) *).window")
            }
            if let delegateDescription = delegateDescription(of: node) {
                relations.append(delegateDescription)
            }
        case .windowScene:
            if let delegateDescription = delegateDescription(of: node) {
                relations.append(delegateDescription)
            }
        case .cell:
            if let ownerClassName = context.ownerNode?.className {
                relations.append("(\(ownerClassName) *).cell")
            }
        case .layoutGuide, .layer:
            break
        }
        return relations
    }

    private static func delegateDescription(of node: LKXcodeViewHierarchyNode) -> String? {
        guard case let .objectReference(reference)? = node.property(named: "delegate")?.value else { return nil }
        return "(\(reference.className) *) delegate"
    }

    // MARK: - Constraints

    private enum ConstraintProperty {
        static let active = "active"
        static let firstItem = "firstItem"
        static let firstAttribute = "firstAttribute"
        static let relation = "relation"
        static let secondItem = "secondItem"
        static let secondAttribute = "secondAttribute"
        static let multiplier = "multiplier"
        static let constant = "constant"
        static let priority = "priority"
        static let identifier = "identifier"
        /// The view's own record of which constraints decide its layout on
        /// each axis: comma-separated constraint identifiers.
        static let affecting = ["horizontalAffectingConstraints", "verticalAffectingConstraints"]
    }

    /// The constraints involving a view, in the server's model: every active
    /// constraint naming the view as an item, marked effective when the
    /// capture lists it among the ones affecting the view's layout.
    private static func makingConstraints(
        for node: LKXcodeViewHierarchyNode,
        graph: LKXcodeViewHierarchyObjectGraph,
        context: LKXcodeViewHierarchyAttributeContext
    ) -> [AutoLayoutConstraint] {
        let effectiveIdentifiers = affectingConstraintIdentifiers(of: node)
        let constraintIdentifiers = context.environment.constraintIndex.constraintIdentifiers(involving: node.objectIdentifier)
        return constraintIdentifiers.compactMap { constraintIdentifier in
            guard let constraintNode = graph.node(constraintIdentifier) else { return nil }
            // The whole product ignores inactive constraints, as the server does.
            if constraintNode.property(named: ConstraintProperty.active)?.value.boolValue == false {
                return nil
            }

            let firstAttribute = integerProperty(constraintNode, ConstraintProperty.firstAttribute) ?? 0
            let secondAttribute = integerProperty(constraintNode, ConstraintProperty.secondAttribute) ?? 0
            // The model asserts on attribute values outside the ranges it
            // knows; a capture carrying one of those is dropped rather than
            // allowed to trip a debug build.
            guard isRepresentableAttribute(firstAttribute), isRepresentableAttribute(secondAttribute) else { return nil }

            let first = endpoint(of: constraintNode, propertyName: ConstraintProperty.firstItem, for: node, graph: graph, context: context)
            let second = endpoint(of: constraintNode, propertyName: ConstraintProperty.secondItem, for: node, graph: graph, context: context)

            let constraint = AutoLayoutConstraint()
            constraint.effective = effectiveIdentifiers.contains(constraintIdentifier)
            constraint.active = true
            constraint.firstItem = first.object
            constraint.firstItemType = first.type
            constraint.firstAttribute = firstAttribute
            constraint.secondItem = second.object
            constraint.secondItemType = second.type
            constraint.secondAttribute = secondAttribute
            let relationValue = integerProperty(constraintNode, ConstraintProperty.relation) ?? 0
            constraint.relation = NSLayoutConstraint.Relation(rawValue: relationValue) ?? .equal
            constraint.multiplier = CGFloat(constraintNode.property(named: ConstraintProperty.multiplier)?.value.doubleValue ?? 1)
            constraint.constant = CGFloat(constraintNode.property(named: ConstraintProperty.constant)?.value.doubleValue ?? 0)
            constraint.priority = CGFloat(constraintNode.property(named: ConstraintProperty.priority)?.value.doubleValue ?? 1000)
            constraint.identifier = constraintNode.property(named: ConstraintProperty.identifier)?.value.textValue
            constraint.constraintOid = LKXcodeViewHierarchyConverter.objectIdentifierValue(constraintIdentifier)
            return constraint
        }
    }

    /// `AutoLayoutConstraint` asserts on attributes in 21...31 or above
    /// 37 — private ones it has no name for. Captures so far use 32, 33, 36
    /// and 37 among the private values, all of which it accepts.
    private static func isRepresentableAttribute(_ attribute: Int) -> Bool {
        !((21 ... 31).contains(attribute) || attribute > 37)
    }

    private static func affectingConstraintIdentifiers(of node: LKXcodeViewHierarchyNode) -> Set<String> {
        var identifiers: Set<String> = []
        for propertyName in ConstraintProperty.affecting {
            guard let text = node.property(named: propertyName)?.value.textValue else { continue }
            for identifier in text.split(separator: ",") {
                let trimmed = identifier.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    identifiers.insert(trimmed)
                }
            }
        }
        return identifiers
    }

    private static func integerProperty(_ node: LKXcodeViewHierarchyNode, _ propertyName: String) -> Int? {
        guard let value = node.property(named: propertyName)?.value, let integer = integerValue(of: value) else { return nil }
        return Int(integer)
    }

    /// One end of a constraint, typed the way the server's
    /// `_lks_constraintItemTypeForItem:` types it relative to the view.
    private static func endpoint(
        of constraintNode: LKXcodeViewHierarchyNode,
        propertyName: String,
        for node: LKXcodeViewHierarchyNode,
        graph: LKXcodeViewHierarchyObjectGraph,
        context: LKXcodeViewHierarchyAttributeContext
    ) -> (object: InspectedObject?, type: LookinConstraintItemType) {
        guard case let .objectReference(reference)? = constraintNode.property(named: propertyName)?.value else {
            return (nil, .`nil`)
        }
        let object = InspectedObject()
        object.oid = LKXcodeViewHierarchyConverter.objectIdentifierValue(reference.objectIdentifier)
        object.memoryAddress = reference.objectIdentifier
        object.classChainList = graph.classChain(forClassName: reference.className)

        let type: LookinConstraintItemType
        if reference.objectIdentifier == node.objectIdentifier {
            type = .`self`
        } else if reference.objectIdentifier == context.superviewNode?.objectIdentifier {
            type = .super
        } else if object.classChainList?.contains(where: ChainEnd.layoutGuide.contains) == true
            || reference.className.hasSuffix("LayoutGuide")
        {
            type = .layoutGuide
        } else {
            type = .view
        }
        return (object, type)
    }

    // MARK: - Model builders

    private static func makingGroup(
        _ identifier: String,
        _ sections: [AttributesSection]
    ) -> AttributesGroup {
        let group = AttributesGroup()
        group.identifier = identifier
        group.attrSections = sections
        return group
    }

    private static func makingSection(
        _ identifier: String,
        _ attributes: [InspectedAttribute]
    ) -> AttributesSection {
        let section = AttributesSection()
        section.identifier = identifier
        section.attributes = attributes
        return section
    }

    private static func makingAttribute(
        _ identifier: String,
        _ attrType: LookinAttrType,
        _ value: Any?
    ) -> InspectedAttribute {
        let attribute = InspectedAttribute()
        attribute.identifier = identifier
        attribute.attrType = attrType
        attribute.value = value
        return attribute
    }
}
