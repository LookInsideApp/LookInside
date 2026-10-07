// LKXcodeViewHierarchyConverter.swift
//
// Turns a decoded `.viewhierarchy` capture into the model the inspector
// already knows how to display: a `LookinHierarchyFile`, which the existing
// read path opens exactly as it opens a `.lookin` archive.
//
// The whole point of producing that type rather than a new one is that no RPC
// has to be implemented. A live session answers questions on demand; an
// archive has the answers pre-materialised on the nodes, and this converter
// pre-materialises the capture's answers the same way.
//
// The capture's tree is not the inspector's tree, and four differences matter:
//
//  1. **The top level is Xcode's, not the capture's.** The capture's root
//     groups are flat lists per class (every window, every window controller,
//     every scene, every root view). Xcode's sidebar derives its top level
//     from them and this converter replicates that derivation — see
//     `makingRootDisplayItems` — so a capture opens here with the same rows in
//     the same order as in Xcode's own View Hierarchy outline.
//  2. **A window's root view is an association, not a child.** A window object
//     carries no children at all; the view it hosts hangs off its
//     `com.apple.*.NSView`/`UIView` association. Reading only `childGroup`
//     from a window yields an empty hierarchy.
//  3. **Layers, constraints and view controllers are associations too**, and
//     they must stay out of the view tree. The inspector wants a view's layer
//     folded into the same node (as `layerObject`), not standing beside it.
//  4. **Layout guides and AppKit cells become child nodes**, because that is
//     the shape the inspector's node model uses for them (nodeKind
//     LayoutGuide and Cell, both riding `kindObject`).
//
// Node identity is the object's address: the capture writes `objectID` as a
// hexadecimal pointer string, and Lookin's `oid` is that same pointer as an
// integer, which is what lets recovered screenshots be keyed the way a
// `.lookin` archive keys them.

import AppKit
import Foundation

enum LKXcodeViewHierarchyConversionError: Error, CustomStringConvertible {
    case noWindowsOrRootViews

    var description: String {
        switch self {
        case .noWindowsOrRootViews:
            return "the capture contains no windows or root views to display"
        }
    }
}

enum LKXcodeViewHierarchyConverter {
    // MARK: Group identifiers

    private enum GroupIdentifier {
        static let layer = "com.apple.QuartzCore.CALayer"

        static let uiKitApplication = "com.apple.UIKit.UIApplication"
        static let uiKitScene = "com.apple.UIKit.UIScene"
        static let uiKitWindow = "com.apple.UIKit.UIWindow"
        static let uiKitView = "com.apple.UIKit.UIView"
        static let uiKitLayoutGuide = "com.apple.UIKit.UILayoutGuide"
        static let uiKitViewController = "com.apple.UIKit.UIViewController"

        static let appKitApplication = "com.apple.AppKit.NSApplication"
        static let appKitWindow = "com.apple.AppKit.NSWindow"
        static let appKitView = "com.apple.AppKit.NSView"
        static let appKitLayoutGuide = "com.apple.AppKit.NSLayoutGuide"
        static let appKitViewController = "com.apple.AppKit.NSViewController"
        static let appKitWindowController = "com.apple.AppKit.NSWindowController"
        static let appKitCell = "com.apple.AppKit.NSCell"
    }

    /// Class names Xcode's sidebar special-cases when deciding what to list.
    private enum ClassName {
        /// The only root views Xcode lists at the top level.
        static let touchBarView = "NSTouchBarView"
        /// Never listed, whatever its flags say.
        static let systemOverlayWindow = "_UIWindowSystemOverlayWindow"
        /// Internal, and never granted the internal-window exception.
        static let remoteKeyboardWindow = "UIRemoteKeyboardWindow"
        /// Content that earns an internal or hidden window a row anyway: the
        /// keyboard and iMessage extension windows host the user's own code.
        static let externallyRelevantControllers = ["MSMessagesAppViewController", "UIInputViewController"]
    }

    /// Which platform's naming a capture uses; everything else follows from it.
    private struct Vocabulary {
        let isAppKit: Bool
        let applicationGroup: String
        /// The group whose objects own windows — window controllers on AppKit,
        /// scenes on UIKit. Xcode lists these first, each with its windows.
        let windowOwnerGroup: String
        /// Whether an owner is a node of its own (a scene) or folds into the
        /// window's row as its controller (AppKit).
        let windowOwnerIsSceneNode: Bool
        let windowGroup: String
        let viewGroup: String
        let layoutGuideGroup: String
        let viewControllerGroup: String
        let cellGroup: String?

        static let uiKit = Vocabulary(
            isAppKit: false,
            applicationGroup: GroupIdentifier.uiKitApplication,
            windowOwnerGroup: GroupIdentifier.uiKitScene,
            windowOwnerIsSceneNode: true,
            windowGroup: GroupIdentifier.uiKitWindow,
            viewGroup: GroupIdentifier.uiKitView,
            layoutGuideGroup: GroupIdentifier.uiKitLayoutGuide,
            viewControllerGroup: GroupIdentifier.uiKitViewController,
            cellGroup: nil
        )

        static let appKit = Vocabulary(
            isAppKit: true,
            applicationGroup: GroupIdentifier.appKitApplication,
            windowOwnerGroup: GroupIdentifier.appKitWindowController,
            windowOwnerIsSceneNode: false,
            windowGroup: GroupIdentifier.appKitWindow,
            viewGroup: GroupIdentifier.appKitView,
            layoutGuideGroup: GroupIdentifier.appKitLayoutGuide,
            viewControllerGroup: GroupIdentifier.appKitViewController,
            cellGroup: GroupIdentifier.appKitCell
        )
    }

    // MARK: Entry point

    /// Converts a capture into the inspector's model.
    ///
    /// `showingBackingLayers` selects the tree's shape the way the inspector's
    /// show-backing-layers toggle does for a live session: off, a view and its
    /// backing layer are one node and only orphan sublayers appear as layer
    /// nodes; on, every view expands into its full layer subtree, with the
    /// pixels on the layer that really renders them (backing-layer-toggle
    /// proposal). The recovered images are the same either way; what changes
    /// is which node each image is filed under.
    static func makingHierarchyFile(
        from bundle: LKXcodeViewHierarchyBundle,
        screenshots: LKXcodeViewHierarchyScreenshots,
        showingBackingLayers: Bool = false
    ) throws -> LookinHierarchyFile {
        let graph = bundle.graph
        let vocabulary = graph.rootGroups.contains { $0.groupingIdentifier.hasPrefix("com.apple.AppKit.") }
            ? Vocabulary.appKit
            : Vocabulary.uiKit
        let session = ConversionSession(
            graph: graph, vocabulary: vocabulary, screenshots: screenshots, showsBackingLayers: showingBackingLayers
        )

        let displayItems = makingRootDisplayItems(session: session)
        guard !displayItems.isEmpty else { throw LKXcodeViewHierarchyConversionError.noWindowsOrRootViews }

        let hierarchyInfo = LookinHierarchyInfo()
        hierarchyInfo.displayItems = displayItems
        hierarchyInfo.serverVersion = Int32(LOOKIN_SERVER_VERSION)
        hierarchyInfo.appInfo = makingAppInfo(from: bundle, vocabulary: vocabulary)

        let file = LookinHierarchyFile()
        file.serverVersion = Int32(LOOKIN_SERVER_VERSION)
        file.hierarchyInfo = hierarchyInfo
        file.soloScreenshots = session.soloScreenshotsByOid
        file.groupScreenshots = session.groupScreenshotsByOid
        return file
    }

    // MARK: Conversion session

    /// What one conversion carries along: the options it runs under, the
    /// recovered images it files, and where it has filed them so far.
    ///
    /// Images are filed by the walk rather than copied over wholesale because
    /// the inspector looks a node's images up by the oid the node routes by,
    /// and that oid depends on the tree's shape: a merged view node routes by
    /// its layer, a view node with a separate BackingLayer child routes by
    /// the view itself (`bestObjectOidPreferView:`), and a layer node shows a
    /// group image that leaves out the views beneath it.
    private final class ConversionSession {
        let graph: LKXcodeViewHierarchyObjectGraph
        let vocabulary: Vocabulary
        let screenshots: LKXcodeViewHierarchyScreenshots
        let showsBackingLayers: Bool
        let topology: LKXcodeViewHierarchyLayerTopology
        let environment: LKXcodeViewHierarchyAttributeEnvironment
        /// Layers already emitted as nodes. The capture's layer tree is a
        /// tree, but a layer reachable twice must not appear twice.
        var convertedLayerIdentifiers: Set<String> = []
        private(set) var soloScreenshotsByOid: [NSNumber: Data] = [:]
        private(set) var groupScreenshotsByOid: [NSNumber: Data] = [:]

        init(
            graph: LKXcodeViewHierarchyObjectGraph,
            vocabulary: Vocabulary,
            screenshots: LKXcodeViewHierarchyScreenshots,
            showsBackingLayers: Bool
        ) {
            self.graph = graph
            self.vocabulary = vocabulary
            self.screenshots = screenshots
            self.showsBackingLayers = showsBackingLayers
            topology = LKXcodeViewHierarchyLayerTopology(graph: graph)
            environment = LKXcodeViewHierarchyAttributeEnvironment(
                isAppKit: vocabulary.isAppKit,
                constraintIndex: LKXcodeViewHierarchyConstraintIndex(graph: graph),
                keyWindowIdentifier: LKXcodeViewHierarchyConverter.keyWindowIdentifier(graph: graph, vocabulary: vocabulary)
            )
        }

        /// Files the images of the layer `imageIdentifier` under the object the
        /// node routes by, and records on `item` the region a group image
        /// covers when it covers less than the node. With
        /// `excludingHostedViews` the group image leaves out the subtrees of
        /// the layers that back a view — the shape of a layer node, whose
        /// views render on nodes of their own — and is absent when that
        /// render drew nothing, rather than falling back to a picture that
        /// includes those views.
        func filing(
            soloOf soloIdentifier: String?,
            groupOf groupIdentifier: String?,
            excludingHostedViews: Bool,
            under keyIdentifier: String,
            onto item: LookinDisplayItem
        ) {
            let oid = LKXcodeViewHierarchyConverter.objectIdentifierValue(keyIdentifier)
            guard oid != 0 else { return }
            let key = NSNumber(value: UInt64(oid))
            if let soloIdentifier, let solo = screenshots.soloByObjectIdentifier[soloIdentifier] {
                soloScreenshotsByOid[key] = solo
            }
            guard let groupIdentifier else { return }
            let hostsViews = excludingHostedViews
                && !topology.hostedDescendantIdentifiers(of: groupIdentifier, graph: graph).isEmpty
            let group = hostsViews
                ? screenshots.groupExcludingHostedViewsByObjectIdentifier[groupIdentifier]
                : screenshots.groupByObjectIdentifier[groupIdentifier]
            guard let group else { return }
            groupScreenshotsByOid[key] = group
            // The region is measured from the rendered layer's bounds origin;
            // the node's bounds may sit at another origin (a wrapped view's
            // node carries the wrapper's bounds), so re-anchor it there.
            let relativeRegion = hostsViews
                ? screenshots.groupExcludingHostedViewsRegionByObjectIdentifier[groupIdentifier]
                : screenshots.groupRegionByObjectIdentifier[groupIdentifier]
            if let relativeRegion {
                item.groupScreenshotRegion = relativeRegion.offsetBy(dx: item.bounds.origin.x, dy: item.bounds.origin.y)
            }
        }
    }

    // MARK: Top level

    /// The top level of the tree, derived the way Xcode's sidebar derives it.
    ///
    /// Xcode (DebuggerFoundation's `DBGDebugHierarchyViewObjectAdaptor`, then
    /// DebuggerUI's `DBGApplicationObject`) builds its View Hierarchy outline
    /// from the capture's root groups in this order:
    ///
    ///  1. every window owner in root-group order — window controllers on
    ///     AppKit, scenes on UIKit — each followed by the windows that name it
    ///     as their owner, in window order;
    ///  2. the windows no listed owner claims, in window order, with child
    ///     windows flattened in after the root ones;
    ///  3. root views, of which only an `NSTouchBarView` with children counts.
    ///
    /// The owner of the key window moves to the front, with the key window
    /// first among its windows. Windows that are internal or invisible are
    /// left out unless they host the user's keyboard or iMessage extension
    /// code, and a system overlay window is always left out.
    ///
    /// A root view that is not a touch bar therefore never appears — a view
    /// controller's view that is currently detached from any window, say.
    /// Xcode only shows those in its other outline mode ("View Controller
    /// Containment"), which the inspector has no counterpart for.
    private static func makingRootDisplayItems(session: ConversionSession) -> [LookinDisplayItem] {
        let graph = session.graph
        let vocabulary = session.vocabulary
        let environment = session.environment
        let keyWindowIdentifier = environment.keyWindowIdentifier
        var convertedViewIdentifiers: Set<String> = []

        let windowIdentifiers = listedWindowIdentifiers(graph: graph, vocabulary: vocabulary)
        let listedOwnerIdentifiers = Set(graph.rootIdentifiers(inGroup: vocabulary.windowOwnerGroup))
        var windowIdentifiersByOwner: [String: [String]] = [:]
        var unownedWindowIdentifiers: [String] = []
        for windowIdentifier in windowIdentifiers {
            guard let windowNode = graph.node(windowIdentifier) else { continue }
            // Xcode only credits owners that appear in the owner root group;
            // a window whose owner the capture never listed stays unowned.
            if let ownerIdentifier = windowNode.associatedIdentifiers(inGroup: vocabulary.windowOwnerGroup).first,
               listedOwnerIdentifiers.contains(ownerIdentifier)
            {
                windowIdentifiersByOwner[ownerIdentifier, default: []].append(windowIdentifier)
            } else {
                unownedWindowIdentifiers.append(windowIdentifier)
            }
        }

        var ownerIdentifiers = graph.rootIdentifiers(inGroup: vocabulary.windowOwnerGroup)
        if let keyWindowIdentifier {
            if let ownerIdentifier = ownerIdentifiers.first(where: {
                windowIdentifiersByOwner[$0]?.contains(keyWindowIdentifier) == true
            }) {
                ownerIdentifiers.moveToFront(ownerIdentifier)
                windowIdentifiersByOwner[ownerIdentifier]?.moveToFront(keyWindowIdentifier)
            } else {
                unownedWindowIdentifiers.moveToFront(keyWindowIdentifier)
            }
        }

        var rootItems: [LookinDisplayItem] = []
        for ownerIdentifier in ownerIdentifiers {
            let ownedWindowIdentifiers = windowIdentifiersByOwner[ownerIdentifier] ?? []
            let windowItems = ownedWindowIdentifiers.compactMap { windowIdentifier in
                makingWindowItem(
                    windowIdentifier: windowIdentifier,
                    isKeyWindow: windowIdentifier == keyWindowIdentifier,
                    graph: graph,
                    vocabulary: vocabulary,
                    environment: environment,
                    session: session,
                    convertedViewIdentifiers: &convertedViewIdentifiers
                )
            }
            if vocabulary.windowOwnerIsSceneNode {
                // A scene is a node even with no windows, as in a live session.
                guard let sceneNode = graph.node(ownerIdentifier) else { continue }
                rootItems.append(makingSceneItem(
                    sceneNode: sceneNode,
                    windowNodes: ownedWindowIdentifiers.compactMap(graph.node),
                    windowItems: windowItems,
                    graph: graph,
                    environment: environment
                ))
            } else {
                // A window controller is not a node here: the window row
                // carries it as its controller. One without windows has no row.
                rootItems.append(contentsOf: windowItems)
            }
        }
        for windowIdentifier in unownedWindowIdentifiers {
            guard let windowItem = makingWindowItem(
                windowIdentifier: windowIdentifier,
                isKeyWindow: windowIdentifier == keyWindowIdentifier,
                graph: graph,
                vocabulary: vocabulary,
                environment: environment,
                session: session,
                convertedViewIdentifiers: &convertedViewIdentifiers
            ) else { continue }
            rootItems.append(windowItem)
        }

        for viewIdentifier in graph.rootIdentifiers(inGroup: vocabulary.viewGroup)
            where !convertedViewIdentifiers.contains(viewIdentifier)
        {
            guard let viewNode = graph.node(viewIdentifier),
                  !viewNode.childIdentifiers.isEmpty,
                  isNode(viewNode, kindOfClassNamed: ClassName.touchBarView, graph: graph),
                  let viewItem = makingViewItem(
                      viewIdentifier: viewIdentifier,
                      superviewNode: nil,
                      graph: graph,
                      vocabulary: vocabulary,
                      environment: environment,
                      session: session,
                      convertedViewIdentifiers: &convertedViewIdentifiers
                  )
            else { continue }
            rootItems.append(viewItem)
        }

        return rootItems
    }

    /// Every window Xcode would list, in the order it processes them: the
    /// window root group first, then child windows of those, minus the ones
    /// its skip rule excludes.
    private static func listedWindowIdentifiers(
        graph: LKXcodeViewHierarchyObjectGraph,
        vocabulary: Vocabulary
    ) -> [String] {
        let rootWindowIdentifiers = graph.rootIdentifiers(inGroup: vocabulary.windowGroup)
        var childWindowIdentifiers: [String] = []
        for rootWindowIdentifier in rootWindowIdentifiers {
            appendingChildWindowIdentifiers(
                of: rootWindowIdentifier, graph: graph, vocabulary: vocabulary, into: &childWindowIdentifiers
            )
        }

        var seen: Set<String> = []
        return (rootWindowIdentifiers + childWindowIdentifiers).filter { windowIdentifier in
            guard seen.insert(windowIdentifier).inserted, let windowNode = graph.node(windowIdentifier) else {
                return false
            }
            return !shouldSkipWindow(windowNode, graph: graph, vocabulary: vocabulary)
        }
    }

    /// An NSWindow's `childGroup` holds its child windows (a UIWindow's holds
    /// its subviews, which are not windows and are left alone here).
    private static func appendingChildWindowIdentifiers(
        of windowIdentifier: String,
        graph: LKXcodeViewHierarchyObjectGraph,
        vocabulary: Vocabulary,
        into childWindowIdentifiers: inout [String]
    ) {
        guard let windowNode = graph.node(windowIdentifier) else { return }
        for childIdentifier in windowNode.childIdentifiers
            where graph.node(childIdentifier)?.groupingIdentifier == vocabulary.windowGroup
        {
            childWindowIdentifiers.append(childIdentifier)
            appendingChildWindowIdentifiers(
                of: childIdentifier, graph: graph, vocabulary: vocabulary, into: &childWindowIdentifiers
            )
        }
    }

    /// Xcode's rule for leaving a window out of the sidebar. The flag pair is
    /// only recorded by the UIKit agent; AppKit captures carry neither, so no
    /// AppKit window is ever skipped on their account.
    private static func shouldSkipWindow(
        _ windowNode: LKXcodeViewHierarchyNode,
        graph: LKXcodeViewHierarchyObjectGraph,
        vocabulary: Vocabulary
    ) -> Bool {
        if isNode(windowNode, kindOfClassNamed: ClassName.systemOverlayWindow, graph: graph) {
            return true
        }
        guard let isInternal = windowNode.property(named: "internal")?.value.boolValue,
              let isVisible = windowNode.property(named: "visible")?.value.boolValue,
              isInternal || !isVisible
        else { return false }
        return !hostsExternallyRelevantContent(windowNode, graph: graph, vocabulary: vocabulary)
    }

    /// Whether an internal or hidden window still deserves a row: the
    /// keyboard and iMessage extension windows are the system's, but the view
    /// controllers inside them are the user's.
    private static func hostsExternallyRelevantContent(
        _ windowNode: LKXcodeViewHierarchyNode,
        graph: LKXcodeViewHierarchyObjectGraph,
        vocabulary: Vocabulary
    ) -> Bool {
        if isNode(windowNode, kindOfClassNamed: ClassName.remoteKeyboardWindow, graph: graph) {
            return false
        }
        var pendingControllerIdentifiers = windowNode.associatedIdentifiers(inGroup: vocabulary.viewControllerGroup)
        var visited: Set<String> = []
        while !pendingControllerIdentifiers.isEmpty {
            let controllerIdentifier = pendingControllerIdentifiers.removeFirst()
            guard visited.insert(controllerIdentifier).inserted,
                  let controllerNode = graph.node(controllerIdentifier)
            else { continue }
            if ClassName.externallyRelevantControllers.contains(where: {
                isNode(controllerNode, kindOfClassNamed: $0, graph: graph)
            }) {
                return true
            }
            pendingControllerIdentifiers.append(contentsOf: controllerNode.childIdentifiers)
        }
        return false
    }

    /// The window the application object names as key, if the capture
    /// recorded one. Xcode reads the pointer off the application, not the
    /// windows' own flags.
    private static func keyWindowIdentifier(
        graph: LKXcodeViewHierarchyObjectGraph,
        vocabulary: Vocabulary
    ) -> String? {
        guard let applicationIdentifier = graph.rootIdentifiers(inGroup: vocabulary.applicationGroup).first,
              let keyWindowText = graph.node(applicationIdentifier)?.property(named: "keyWindow")?.value.textValue
        else { return nil }
        let keyWindowValue = objectIdentifierValue(keyWindowText)
        guard keyWindowValue != 0 else { return nil }
        return graph.rootIdentifiers(inGroup: vocabulary.windowGroup)
            .first { objectIdentifierValue($0) == keyWindowValue }
            ?? graph.nodesByIdentifier.keys.first { objectIdentifierValue($0) == keyWindowValue }
    }

    // MARK: Tree

    /// A UIKit scene, the node a live session puts above its windows.
    private static func makingSceneItem(
        sceneNode: LKXcodeViewHierarchyNode,
        windowNodes: [LKXcodeViewHierarchyNode],
        windowItems: [LookinDisplayItem],
        graph: LKXcodeViewHierarchyObjectGraph,
        environment: LKXcodeViewHierarchyAttributeEnvironment
    ) -> LookinDisplayItem {
        let item = makingDisplayItem(kind: .windowScene)
        item.windowObject = makingLookinObject(for: sceneNode, graph: graph)
        item.alpha = 1
        item.customDisplayTitle = sceneDisplayTitle(for: sceneNode)
        item.representedAsKeyWindow = windowItems.contains { $0.representedAsKeyWindow }
        var context = LKXcodeViewHierarchyAttributeContext(role: .windowScene, environment: environment)
        context.sceneWindowNodes = windowNodes
        item.attributesGroupList = LKXcodeViewHierarchyAttributes.makingGroups(
            for: sceneNode, layerNode: nil, graph: graph, context: context
        )
        item.subitems = windowItems
        return item
    }

    /// The server's title shape for a scene: class, title, activation state.
    private static func sceneDisplayTitle(for sceneNode: LKXcodeViewHierarchyNode) -> String {
        var title = sceneNode.className ?? "UIWindowScene"
        if let sceneTitle = sceneNode.property(named: "title")?.value.textValue, !sceneTitle.isEmpty {
            title += " – \(sceneTitle)"
        }
        if let activationState = sceneNode.property(named: "activationState")?.value.doubleValue {
            let stateDescription: String
            switch Int(activationState) {
            case -1: stateDescription = "Unattached"
            case 0: stateDescription = "Foreground Active"
            case 1: stateDescription = "Foreground Inactive"
            case 2: stateDescription = "Background"
            default: stateDescription = "Unknown"
            }
            title += " (\(stateDescription))"
        }
        return title
    }

    private static func makingWindowItem(
        windowIdentifier: String,
        isKeyWindow: Bool,
        graph: LKXcodeViewHierarchyObjectGraph,
        vocabulary: Vocabulary,
        environment: LKXcodeViewHierarchyAttributeEnvironment,
        session: ConversionSession,
        convertedViewIdentifiers: inout Set<String>
    ) -> LookinDisplayItem? {
        guard let windowNode = graph.node(windowIdentifier) else { return nil }

        let item = makingDisplayItem(kind: .window)
        item.windowObject = makingLookinObject(for: windowNode, graph: graph)
        item.representedAsKeyWindow = isKeyWindow
        // A UIWindow is a view and gets a view's cards; an NSWindow is not.
        var context = LKXcodeViewHierarchyAttributeContext(
            role: vocabulary.isAppKit ? .window : .view, environment: environment
        )

        // A UIWindow is itself a view and owns a layer; an NSWindow is not.
        // Carrying the layer lets the window node resolve a recovered
        // screenshot, which is keyed by layer identity like every other node.
        let ownedLayers = resolvingOwnedLayers(of: windowNode, graph: graph)
        if let ownedLayers {
            item.layerObject = makingLookinObject(for: ownedLayers.backingNode, graph: graph)
            applyingGeometry(from: ownedLayers.associatedNode, fallback: windowNode, to: item)
            applyingBackgroundColor(from: ownedLayers.backingNode, to: item)
        } else {
            applyingGeometry(from: windowNode, to: item)
        }
        applyingVisibility(from: windowNode, to: item)

        if !vocabulary.windowOwnerIsSceneNode,
           let controllerIdentifier = windowNode.associatedIdentifiers(inGroup: vocabulary.windowOwnerGroup).first,
           let controllerNode = graph.node(controllerIdentifier)
        {
            item.hostWindowControllerObject = makingLookinObject(for: controllerNode, graph: graph)
            context.windowControllerNode = controllerNode
        }
        // The window's root view controller marks the row, as before; the
        // cards leave it out, since a window is not that controller's view
        // and a live session's Class and Relation cards do not list it.
        if let controllerIdentifier = windowNode.associatedIdentifiers(inGroup: vocabulary.viewControllerGroup).first,
           let controllerNode = graph.node(controllerIdentifier)
        {
            item.hostViewControllerObject = makingLookinObject(for: controllerNode, graph: graph)
        }

        // Where the window's content hangs differs by platform, and reading
        // only one of the two loses the entire hierarchy on the other. A
        // UIWindow is a view, so its subviews are its own children; an NSWindow
        // is not, so its content view is an association — and its children,
        // when it has any, are child windows, which the top level lists.
        var rootViewIdentifiers = windowNode.childIdentifiers.filter {
            graph.node($0)?.groupingIdentifier != vocabulary.windowGroup
        }
        rootViewIdentifiers.append(contentsOf: windowNode.associatedIdentifiers(inGroup: vocabulary.viewGroup))

        var rootViewItems: [LookinDisplayItem] = []
        for rootViewIdentifier in rootViewIdentifiers {
            guard let viewItem = makingViewItem(
                viewIdentifier: rootViewIdentifier,
                superviewNode: windowNode,
                graph: graph,
                vocabulary: vocabulary,
                environment: environment,
                session: session,
                convertedViewIdentifiers: &convertedViewIdentifiers
            ) else { continue }
            rootViewItems.append(viewItem)
        }
        var subitems = rootViewItems
        if let ownedLayers {
            // A UIWindow's layer tree is a view's: its orphan sublayers and,
            // with the toggle on, its backing layer become nodes too.
            subitems = assemblingLayerAwareChildren(
                ownerIdentifier: windowIdentifier, ownerItem: item, ownedLayers: ownedLayers,
                subviewItems: rootViewItems, session: session
            )
        }
        subitems.append(contentsOf: makingLayoutGuideItems(
            owner: windowNode, graph: graph, vocabulary: vocabulary, environment: environment
        ))
        item.subitems = subitems
        item.attributesGroupList = LKXcodeViewHierarchyAttributes.makingGroups(
            for: windowNode, layerNode: associatedLayerNode(of: windowNode, graph: graph), graph: graph, context: context
        )

        // A window whose frame the capture did not record still needs bounds
        // for the preview to place it; borrow the root view's.
        if item.frame == .zero, let firstChild = subitems.first {
            item.frame = firstChild.frame
            item.bounds = firstChild.bounds
        }
        return item
    }

    private static func makingViewItem(
        viewIdentifier: String,
        superviewNode: LKXcodeViewHierarchyNode?,
        graph: LKXcodeViewHierarchyObjectGraph,
        vocabulary: Vocabulary,
        environment: LKXcodeViewHierarchyAttributeEnvironment,
        session: ConversionSession,
        convertedViewIdentifiers: inout Set<String>
    ) -> LookinDisplayItem? {
        // The capture is a graph, not a tree: a view reachable twice would
        // otherwise be converted twice and appear twice.
        guard convertedViewIdentifiers.insert(viewIdentifier).inserted,
              let viewNode = graph.node(viewIdentifier)
        else { return nil }

        let item = makingDisplayItem(kind: .view)
        item.viewObject = makingLookinObject(for: viewNode, graph: graph)
        item.isFlipped = vocabulary.isAppKit && (viewNode.property(named: "flipped")?.value.boolValue ?? false)

        // The node's layer is the backing layer — the one whose contents are
        // the view's own drawing — which on iOS 26 sits below the wrapper the
        // capture associates with the view. Geometry comes from the wrapper
        // when there is one: UIKit moved position, bounds and visibility onto
        // it and reset the backing layer to the view's origin.
        let ownedLayers = resolvingOwnedLayers(of: viewNode, graph: graph)
        if let ownedLayers {
            item.layerObject = makingLookinObject(for: ownedLayers.backingNode, graph: graph)
            applyingGeometry(from: ownedLayers.associatedNode, fallback: viewNode, to: item)
            applyingBackgroundColor(from: ownedLayers.backingNode, to: item)
        } else {
            applyingGeometry(from: viewNode, to: item)
        }
        applyingVisibility(from: viewNode, to: item)

        var context = LKXcodeViewHierarchyAttributeContext(role: .view, environment: environment)
        context.superviewNode = superviewNode
        if let controllerIdentifier = viewNode.associatedIdentifiers(inGroup: vocabulary.viewControllerGroup).first,
           let controllerNode = graph.node(controllerIdentifier)
        {
            item.hostViewControllerObject = makingLookinObject(for: controllerNode, graph: graph)
            context.viewControllerNode = controllerNode
        }
        item.attributesGroupList = LKXcodeViewHierarchyAttributes.makingGroups(
            for: viewNode, layerNode: associatedLayerNode(of: viewNode, graph: graph), graph: graph, context: context
        )

        var subviewItems: [LookinDisplayItem] = []
        for childIdentifier in viewNode.childIdentifiers {
            guard let childItem = makingViewItem(
                viewIdentifier: childIdentifier,
                superviewNode: viewNode,
                graph: graph,
                vocabulary: vocabulary,
                environment: environment,
                session: session,
                convertedViewIdentifiers: &convertedViewIdentifiers
            ) else { continue }
            subviewItems.append(childItem)
        }
        var subitems = subviewItems
        if let ownedLayers {
            subitems = assemblingLayerAwareChildren(
                ownerIdentifier: viewIdentifier, ownerItem: item, ownedLayers: ownedLayers,
                subviewItems: subviewItems, session: session
            )
        }
        subitems.append(contentsOf: makingLayoutGuideItems(
            owner: viewNode, graph: graph, vocabulary: vocabulary, environment: environment
        ))
        if let cellGroup = vocabulary.cellGroup {
            subitems.append(contentsOf: makingCellItems(
                owner: viewNode, cellGroup: cellGroup, graph: graph, environment: environment
            ))
        }
        item.subitems = subitems
        return item
    }

    // MARK: Layer nodes

    /// The layers a view (or a UIKit window) owns, as the capture records them.
    private struct OwnedLayers {
        /// The layer the capture associates with the object: its backing
        /// layer, or on iOS 26 the `_UIMultiLayer` wrapper UIKit put above it.
        let associatedNode: LKXcodeViewHierarchyNode
        /// The layer whose contents are the object's own drawing.
        let backingNode: LKXcodeViewHierarchyNode
        /// The wrapper, when UIKit installed one; nil elsewhere.
        let outerNode: LKXcodeViewHierarchyNode?
    }

    private static let multiLayerWrapperClassName = "_UIMultiLayer"

    /// Resolves a view's layers from its `layer` association.
    ///
    /// On iOS 26 UIKit wraps a view's backing layer in a `_UIMultiLayer`, and
    /// the capture associates the view with that wrapper. The backing layer
    /// is the wrapper's sublayer whose delegate is the view — the wrapper's
    /// delegate is the view too, but any other layer parked on the wrapper
    /// belongs to someone else (the server's `lks_viewWrappedAsOuterLayer`).
    private static func resolvingOwnedLayers(
        of node: LKXcodeViewHierarchyNode,
        graph: LKXcodeViewHierarchyObjectGraph
    ) -> OwnedLayers? {
        guard let associatedNode = associatedLayerNode(of: node, graph: graph) else { return nil }
        guard isNode(associatedNode, kindOfClassNamed: multiLayerWrapperClassName, graph: graph) else {
            return OwnedLayers(associatedNode: associatedNode, backingNode: associatedNode, outerNode: nil)
        }
        let wrappedLayerNodes = associatedNode.childIdentifiers.compactMap(graph.node)
        let backingNode = wrappedLayerNodes.first { wrappedLayerNode in
            guard case let .objectReference(delegate)? = wrappedLayerNode.property(named: "delegate")?.value else {
                return false
            }
            return delegate.objectIdentifier == node.objectIdentifier
        } ?? wrappedLayerNodes.first
        guard let backingNode else {
            return OwnedLayers(associatedNode: associatedNode, backingNode: associatedNode, outerNode: nil)
        }
        return OwnedLayers(associatedNode: associatedNode, backingNode: backingNode, outerNode: associatedNode)
    }

    /// The children of a view node, in the shape the show-backing-layers
    /// toggle selects, and the view's own images filed where the node will
    /// look for them.
    ///
    /// Toggle off (the server's default shape): the subviews sit at their z
    /// positions among the backing layer's sublayers, the sublayers that back
    /// no view become layer nodes between them, and AppKit's drawing
    /// containers stay hidden inside the view. On iOS 26 the wrapper follows
    /// as a pixelless coplanar child so its attributes stay reachable.
    ///
    /// Toggle on: the backing layer becomes a node of its own — nested inside
    /// the wrapper node when there is one — carrying its whole non-backing
    /// sublayer tree, drawing containers included; it comes first because it
    /// renders below every subview, and the subviews follow. The view's
    /// pixels then belong to that subtree: no solo image, so the expanded
    /// view renders as a wireframe, while the group keeps the folded look.
    private static func assemblingLayerAwareChildren(
        ownerIdentifier: String,
        ownerItem: LookinDisplayItem,
        ownedLayers: OwnedLayers,
        subviewItems: [LookinDisplayItem],
        session: ConversionSession
    ) -> [LookinDisplayItem] {
        let backingIdentifier = ownedLayers.backingNode.objectIdentifier
        if session.showsBackingLayers {
            session.filing(
                soloOf: nil, groupOf: backingIdentifier, excludingHostedViews: false, under: ownerIdentifier, onto: ownerItem
            )
            var children: [LookinDisplayItem] = []
            if let outerNode = ownedLayers.outerNode {
                // Xcode's nesting for a wrapped view: view → wrapper → backing layer.
                let outerItem = makingOuterLayerItem(outerNode, session: session)
                var outerChildren: [LookinDisplayItem] = []
                for sublayerIdentifier in outerNode.childIdentifiers {
                    if sublayerIdentifier == backingIdentifier {
                        outerChildren.append(makingBackingLayerItem(ownedLayers.backingNode, session: session))
                    } else if let parkedItem = makingLayerItem(sublayerIdentifier, session: session) {
                        // UIKit parks only the backing layer on the wrapper
                        // today, but anything else there belongs under it.
                        outerChildren.append(parkedItem)
                    }
                }
                outerItem.subitems = outerChildren
                children.append(outerItem)
            } else {
                children.append(makingBackingLayerItem(ownedLayers.backingNode, session: session))
            }
            children.append(contentsOf: subviewItems)
            return children
        }

        session.filing(
            soloOf: backingIdentifier, groupOf: backingIdentifier, excludingHostedViews: false,
            under: backingIdentifier, onto: ownerItem
        )
        var children = interleaving(subviewItems, amongSublayersOf: ownedLayers.backingNode, session: session)
        if let outerNode = ownedLayers.outerNode {
            session.convertedLayerIdentifiers.insert(outerNode.objectIdentifier)
            for sublayerIdentifier in outerNode.childIdentifiers where sublayerIdentifier != backingIdentifier {
                if let parkedItem = makingLayerItem(sublayerIdentifier, session: session) {
                    children.append(parkedItem)
                }
            }
            children.append(makingOuterLayerItem(outerNode, session: session))
        }
        return children
    }

    /// Subview nodes in the z order of the backing layer's sublayers, with
    /// the sublayers that back no view as layer nodes between them — the
    /// server's `_orderedSubviewAndSublayerItemsForView:`.
    ///
    /// A subview's anchor is the direct sublayer on the way down to its
    /// layer: usually that layer itself, but on macOS 26 AppKit inserts
    /// container layers, and then the container becomes a layer node at that
    /// z position with the subviews it carries right after it. Subviews whose
    /// layer is not below the backing layer at all keep their own order at
    /// the end.
    private static func interleaving(
        _ subviewItems: [LookinDisplayItem],
        amongSublayersOf backingNode: LKXcodeViewHierarchyNode,
        session: ConversionSession
    ) -> [LookinDisplayItem] {
        var anchoredItems: [String: [LookinDisplayItem]] = [:]
        var unanchoredItems: [LookinDisplayItem] = []
        for subviewItem in subviewItems {
            guard let subviewIdentifier = subviewItem.viewObject?.memoryAddress,
                  let subviewNode = session.graph.node(subviewIdentifier),
                  let subviewLayerIdentifier = subviewNode.associatedIdentifiers(inGroup: GroupIdentifier.layer).first,
                  let anchorIdentifier = session.topology.childOfAncestor(
                      backingNode.objectIdentifier, onPathTo: subviewLayerIdentifier
                  )
            else {
                unanchoredItems.append(subviewItem)
                continue
            }
            anchoredItems[anchorIdentifier, default: []].append(subviewItem)
        }

        var orderedItems: [LookinDisplayItem] = []
        for sublayerIdentifier in backingNode.childIdentifiers {
            if let anchored = anchoredItems[sublayerIdentifier] {
                // A container layer wrapping subviews sits at this z position
                // as a node; the subviews it carries follow it. A subview's own
                // layer is hosted, so makingLayerItem yields nothing for it.
                if let containerItem = makingLayerItem(sublayerIdentifier, session: session) {
                    orderedItems.append(containerItem)
                }
                orderedItems.append(contentsOf: anchored)
            } else if let orphanItem = makingLayerItem(sublayerIdentifier, session: session) {
                orderedItems.append(orphanItem)
            }
        }
        orderedItems.append(contentsOf: unanchoredItems)
        return orderedItems
    }

    /// A sublayer that backs no view, as a node of its own with its subtree,
    /// fenced off from the layers that back a view: those subtrees belong to
    /// the view skeleton. Nil for a hosted layer, a layer already emitted, or
    /// — with the toggle off, on AppKit — a drawing container.
    private static func makingLayerItem(
        _ layerIdentifier: String,
        session: ConversionSession
    ) -> LookinDisplayItem? {
        guard !session.topology.isHosted(layerIdentifier),
              let layerNode = session.graph.node(layerIdentifier)
        else { return nil }
        if !session.showsBackingLayers, representsDrawingContainer(layerNode, session: session) {
            return nil
        }
        guard session.convertedLayerIdentifiers.insert(layerIdentifier).inserted else { return nil }

        let item = makingDisplayItem(kind: .layer)
        item.layerObject = makingLookinObject(for: layerNode, graph: session.graph)
        applyingGeometry(from: layerNode, to: item)
        applyingLayerVisibility(from: layerNode, to: item)
        applyingBackgroundColor(from: layerNode, to: item)
        item.attributesGroupList = makingLayerAttributeGroups(for: layerNode, session: session)
        item.subitems = layerNode.childIdentifiers.compactMap { makingLayerItem($0, session: session) }
        session.filing(
            soloOf: layerIdentifier, groupOf: layerIdentifier, excludingHostedViews: true, under: layerIdentifier, onto: item
        )
        return item
    }

    /// A view's backing layer as a node of its own, only with the toggle on:
    /// the server's `_backingLayerItemForLayer:`. It covers the view's node
    /// edge to edge; its solo is the layer's own content and its group the
    /// subtree minus the subviews' planes, which render on their own nodes.
    private static func makingBackingLayerItem(
        _ backingNode: LKXcodeViewHierarchyNode,
        session: ConversionSession
    ) -> LookinDisplayItem {
        session.convertedLayerIdentifiers.insert(backingNode.objectIdentifier)
        let item = makingDisplayItem(kind: .backingLayer)
        item.layerObject = makingLookinObject(for: backingNode, graph: session.graph)
        applyingCoveringGeometry(from: backingNode, to: item)
        applyingLayerVisibility(from: backingNode, to: item)
        // A backing layer that only paints its background gets no image of
        // its own (pixel recovery skips plain colour fills); the preview
        // paints this colour in its place.
        applyingBackgroundColor(from: backingNode, to: item)
        item.attributesGroupList = makingLayerAttributeGroups(for: backingNode, session: session)
        item.subitems = backingNode.childIdentifiers.compactMap { makingLayerItem($0, session: session) }
        session.filing(
            soloOf: backingNode.objectIdentifier,
            groupOf: backingNode.objectIdentifier,
            excludingHostedViews: true,
            under: backingNode.objectIdentifier,
            onto: item
        )
        return item
    }

    /// The `_UIMultiLayer` wrapper as a child of the view it wraps — Xcode's
    /// placement, and the server's `_outerLayerItemForLayer:`. It has no
    /// pixels (the contents stayed on the backing layer), so no image is
    /// filed for it; the host suppresses screenshots for this kind.
    private static func makingOuterLayerItem(
        _ outerNode: LKXcodeViewHierarchyNode,
        session: ConversionSession
    ) -> LookinDisplayItem {
        session.convertedLayerIdentifiers.insert(outerNode.objectIdentifier)
        let item = makingDisplayItem(kind: .viewOuterLayer)
        item.layerObject = makingLookinObject(for: outerNode, graph: session.graph)
        applyingCoveringGeometry(from: outerNode, to: item)
        applyingLayerVisibility(from: outerNode, to: item)
        applyingBackgroundColor(from: outerNode, to: item)
        item.attributesGroupList = makingLayerAttributeGroups(for: outerNode, session: session)
        return item
    }

    private static func makingLayerAttributeGroups(
        for layerNode: LKXcodeViewHierarchyNode,
        session: ConversionSession
    ) -> [LookinAttributesGroup] {
        let context = LKXcodeViewHierarchyAttributeContext(role: .layer, environment: session.environment)
        return LKXcodeViewHierarchyAttributes.makingGroups(
            for: layerNode, layerNode: layerNode, graph: session.graph, context: context
        )
    }

    /// The server's `lks_representsBackingLayerDrawingContainer`: a sublayer
    /// of a view's backing layer with no delegate, whose contents are AppKit's
    /// own drawing (a CGDisplayList) rather than an image the app assigned.
    /// Its pixels are the host view's; with the toggle off it is no node.
    private static func representsDrawingContainer(
        _ layerNode: LKXcodeViewHierarchyNode,
        session: ConversionSession
    ) -> Bool {
        guard session.vocabulary.isAppKit else { return false }
        if case .objectReference? = layerNode.property(named: "delegate")?.value {
            return false
        }
        guard let parentIdentifier = session.topology.parentByLayerIdentifier[layerNode.objectIdentifier],
              session.topology.isHosted(parentIdentifier)
        else { return false }
        guard let contentsDescription = layerNode.property(named: "contentsDescription")?.value.textValue,
              !contentsDescription.isEmpty
        else { return false }
        return !contentsDescription.hasPrefix("<CGImage")
    }

    /// A layer node covering its parent node edge to edge: origin zero, the
    /// layer's own size (the server's shape for backing and wrapper nodes).
    private static func applyingCoveringGeometry(from layerNode: LKXcodeViewHierarchyNode, to item: LookinDisplayItem) {
        applyingGeometry(from: layerNode, to: item)
        item.frame = CGRect(origin: .zero, size: item.bounds.size)
    }

    private static func applyingLayerVisibility(from layerNode: LKXcodeViewHierarchyNode, to item: LookinDisplayItem) {
        applyingVisibility(from: layerNode, to: item)
        // The server reads a layer node's flip off the layer itself.
        item.isFlipped = layerNode.property(named: "geometryFlipped")?.value.boolValue ?? false
    }

    /// Layout guides mark out a region of their owner and carry no pixels of
    /// their own — the node model's LayoutGuide kind, riding `kindObject`.
    private static func makingLayoutGuideItems(
        owner: LKXcodeViewHierarchyNode,
        graph: LKXcodeViewHierarchyObjectGraph,
        vocabulary: Vocabulary,
        environment: LKXcodeViewHierarchyAttributeEnvironment
    ) -> [LookinDisplayItem] {
        var context = LKXcodeViewHierarchyAttributeContext(role: .layoutGuide, environment: environment)
        context.ownerNode = owner
        return owner.associatedIdentifiers(inGroup: vocabulary.layoutGuideGroup).compactMap { guideIdentifier in
            guard let guideNode = graph.node(guideIdentifier) else { return nil }
            let item = makingDisplayItem(kind: .layoutGuide)
            item.kindObject = makingLookinObject(for: guideNode, graph: graph)
            item.representsSystemManagedNode = looksSystemManaged(guideNode)
            if let layoutFrame = guideNode.property(named: "layoutFrame")?.value.numericComponents(expectedCount: 4) {
                item.frame = rect(from: layoutFrame)
                item.bounds = CGRect(origin: .zero, size: item.frame.size)
            } else {
                applyingGeometry(from: guideNode, to: item)
            }
            item.alpha = 1
            item.attributesGroupList = LKXcodeViewHierarchyAttributes.makingGroups(
                for: guideNode, layerNode: nil, graph: graph, context: context
            )
            return item
        }
    }

    /// An AppKit control's cell, promoted to a first-class node by the
    /// cell-node proposal: pixelless, attributes read from the cell itself.
    private static func makingCellItems(
        owner: LKXcodeViewHierarchyNode,
        cellGroup: String,
        graph: LKXcodeViewHierarchyObjectGraph,
        environment: LKXcodeViewHierarchyAttributeEnvironment
    ) -> [LookinDisplayItem] {
        var context = LKXcodeViewHierarchyAttributeContext(role: .cell, environment: environment)
        context.ownerNode = owner
        return owner.associatedIdentifiers(inGroup: cellGroup).compactMap { cellIdentifier in
            guard let cellNode = graph.node(cellIdentifier) else { return nil }
            let item = makingDisplayItem(kind: .cell)
            item.kindObject = makingLookinObject(for: cellNode, graph: graph)
            applyingGeometry(from: cellNode, to: item)
            item.alpha = 1
            item.attributesGroupList = LKXcodeViewHierarchyAttributes.makingGroups(
                for: cellNode, layerNode: nil, graph: graph, context: context
            )
            return item
        }
    }

    /// Layout guides the system creates (safe area, layout margins, readable
    /// width) drive the inspector's toggle for hiding them.
    private static func looksSystemManaged(_ guideNode: LKXcodeViewHierarchyNode) -> Bool {
        let identifier = guideNode.property(named: "identifier")?.value.textValue ?? ""
        if identifier.hasPrefix("UIView") || identifier.hasPrefix("NSView") {
            return true
        }
        let systemIdentifiers = ["UIViewSafeAreaLayoutGuide", "UIViewLayoutMarginsGuide", "UIViewReadableContentGuide"]
        if systemIdentifiers.contains(identifier) {
            return true
        }
        let className = guideNode.className ?? ""
        return className.hasPrefix("_") || className == "NSSafeAreaLayoutGuide"
    }

    // MARK: Node fields

    /// Every node starts here. `shouldCaptureImage` is opted into explicitly:
    /// its Objective-C default is NO, and the host reads NO as "the user's
    /// config excluded this layer", marking the node and its whole subtree
    /// `noPreview` — the preview then receives nothing (node-model-internals,
    /// trap 1). The server sets the flag per kind and the archive decoder
    /// defaults an absent key to YES; an in-memory producer gets neither.
    private static func makingDisplayItem(kind: LookinDisplayItemNodeKind) -> LookinDisplayItem {
        let item = LookinDisplayItem()
        item.nodeKind = kind
        item.shouldCaptureImage = true
        return item
    }

    /// Xcode's `isKindOfTypeWithName:` — the class or any of its ancestors.
    private static func isNode(
        _ node: LKXcodeViewHierarchyNode,
        kindOfClassNamed className: String,
        graph: LKXcodeViewHierarchyObjectGraph
    ) -> Bool {
        guard let nodeClassName = node.className else { return false }
        return graph.classChain(forClassName: nodeClassName).contains(className)
    }

    private static func associatedLayerNode(
        of node: LKXcodeViewHierarchyNode,
        graph: LKXcodeViewHierarchyObjectGraph
    ) -> LKXcodeViewHierarchyNode? {
        guard let layerIdentifier = node.associatedIdentifiers(inGroup: GroupIdentifier.layer).first else {
            return nil
        }
        return graph.node(layerIdentifier)
    }

    private static func makingLookinObject(
        for node: LKXcodeViewHierarchyNode,
        graph: LKXcodeViewHierarchyObjectGraph
    ) -> LookinObject {
        let object = LookinObject()
        object.oid = objectIdentifierValue(node.objectIdentifier)
        object.memoryAddress = node.objectIdentifier
        let className = node.className ?? "NSObject"
        object.classChainList = graph.classChain(forClassName: className)
        return object
    }

    private static func applyingGeometry(
        from node: LKXcodeViewHierarchyNode,
        fallback fallbackNode: LKXcodeViewHierarchyNode? = nil,
        to item: LookinDisplayItem
    ) {
        if let frameComponents = node.property(named: "frame")?.value.numericComponents(expectedCount: 4) {
            item.frame = rect(from: frameComponents)
        } else if let fallbackComponents = fallbackNode?
            .property(named: "frame")?.value.numericComponents(expectedCount: 4)
        {
            item.frame = rect(from: fallbackComponents)
        }
        if let boundsComponents = node.property(named: "bounds")?.value.numericComponents(expectedCount: 4) {
            item.bounds = rect(from: boundsComponents)
        } else if let fallbackComponents = fallbackNode?
            .property(named: "bounds")?.value.numericComponents(expectedCount: 4)
        {
            item.bounds = rect(from: fallbackComponents)
        } else {
            item.bounds = CGRect(origin: .zero, size: item.frame.size)
        }
    }

    private static func applyingVisibility(from node: LKXcodeViewHierarchyNode, to item: LookinDisplayItem) {
        item.isHidden = node.property(named: "hidden")?.value.boolValue ?? false
        if let alpha = node.property(named: "alpha")?.value.doubleValue {
            item.alpha = Float(alpha)
        } else if let opacity = node.property(named: "opacity")?.value.doubleValue {
            item.alpha = Float(opacity)
        } else {
            item.alpha = 1
        }
    }

    /// The inspector paints this before a screenshot is available, so a node
    /// with no recovered pixels still reads as something rather than a hole.
    private static func applyingBackgroundColor(from layerNode: LKXcodeViewHierarchyNode, to item: LookinDisplayItem) {
        guard case let .color(color)? = layerNode.property(named: "backgroundColor")?.value,
              color.components.count >= 3
        else { return }
        let alpha = color.components.count >= 4 ? color.components[3] : 1
        item.backgroundColor = NSColor(
            srgbRed: color.components[0],
            green: color.components[1],
            blue: color.components[2],
            alpha: alpha
        )
    }

    private static func rect(from components: [Double]) -> CGRect {
        CGRect(x: components[0], y: components[1], width: components[2], height: components[3])
    }

    // MARK: Identity

    /// The pointer an `objectID` spells, which is what Lookin's `oid` holds.
    static func objectIdentifierValue(_ objectIdentifier: String) -> UInt {
        var text = objectIdentifier
        if text.hasPrefix("0x") || text.hasPrefix("0X") {
            text = String(text.dropFirst(2))
        }
        return UInt(text, radix: 16) ?? 0
    }

    // MARK: App info

    private static func makingAppInfo(
        from bundle: LKXcodeViewHierarchyBundle,
        vocabulary: Vocabulary
    ) -> LookinAppInfo {
        let appInfo = LookinAppInfo()
        appInfo.appName = bundle.metadata.runnableDisplayName ?? "Xcode Capture"
        appInfo.serverVersion = Int32(LOOKIN_SERVER_VERSION)
        // The inspector keys view-versus-layer identifier preference off this,
        // and shows the platform's own class names in its copy.
        appInfo.deviceType = vocabulary.isAppKit ? .mac : .others
        appInfo.deviceDescription = vocabulary.isAppKit ? "Mac" : "iOS"
        return appInfo
    }
}

extension LKXcodeViewHierarchyConversionError: LocalizedError {
    var errorDescription: String? {
        description
    }
}

private extension Array where Element: Equatable {
    /// Moves `element` to index 0 when present; leaves the order otherwise.
    mutating func moveToFront(_ element: Element) {
        guard let index = firstIndex(of: element), index != 0 else { return }
        remove(at: index)
        insert(element, at: 0)
    }
}
