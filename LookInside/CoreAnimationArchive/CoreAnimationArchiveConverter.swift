// CoreAnimationArchiveConverter.swift
//
// Turns a decoded and rendered Core Animation archive into the inspector's
// model: one node per layer, in a `HierarchyFile` the read-only window shows
// exactly as it shows a `.lookin` archive.
//
// Each node takes the shape the server gives a layer (`HierarchyDisplayItemsMaker`):
// the layer's frame and bounds, visibility, opacity and background colour,
// and the dashboard rows the blueprint aims at a CALayer, read here from the
// decoded layer as the server reads them from the live one. A layer that
// backed a view becomes a `.view` node with the view folded in, the shape a
// live session gives a view while backing layers are hidden; every other
// layer is a `.layer` node.
//
// One deliberate difference: `isFlipped` is the layer's cumulative flip
// (`contentsAreFlipped`), not its own `geometryFlipped`. The inspector reads
// the flag the way AppKit reads `NSView.isFlipped` — whether this node's own
// space runs top down — when it places the node's children; a layer's own
// flag only says whether it flips its sublayers relative to its superlayer.
// The two agree for the backing layers a live session meets, but a dumped
// window holds whole subtrees of flipped views, where they do not.
//
// The archive keeps no app or AppKit classes: Core Animation archives every
// layer as its nearest QuartzCore class (`CALayerCreateCodingProxy`), and the
// views themselves are not archived at all. What survives of a view is what
// AppKit wrote onto its layer — see `CoreAnimationArchiveViewIdentity`.

import AppKit
import Foundation
import QuartzCore

/// An archive decoded, numbered and rendered: everything the converter needs.
struct CoreAnimationArchiveCapture {
    let tree: CoreAnimationArchiveLayerTree
    let screenshots: CoreAnimationArchiveScreenshots
    /// Where the archive came from, when its file name says so.
    let origin: CoreAnimationArchiveOrigin?
}

enum CoreAnimationArchiveConverter {
    static func makingHierarchyFile(from capture: CoreAnimationArchiveCapture) -> HierarchyFile {
        let session = ConversionSession(capture: capture)
        let rootItem = session.makingItem(for: capture.tree.rootLayer)
        // The root's frame places it in a superlayer the archive does not
        // have; the tree starts at the origin instead.
        rootItem.frame = CGRect(origin: .zero, size: rootItem.frame.size)

        let hierarchyInfo = HierarchyInfo()
        hierarchyInfo.displayItems = [rootItem]
        hierarchyInfo.serverVersion = Int32(LOOKIN_SERVER_VERSION)
        hierarchyInfo.appInfo = makingAppInfo(origin: capture.origin)

        let file = HierarchyFile()
        file.serverVersion = Int32(LOOKIN_SERVER_VERSION)
        file.hierarchyInfo = hierarchyInfo
        file.soloScreenshots = session.soloScreenshotsByOid
        file.groupScreenshots = session.groupScreenshotsByOid
        return file
    }

    /// One conversion's state: the screenshots filed so far, under the oid of
    /// the node each belongs to.
    private final class ConversionSession {
        let capture: CoreAnimationArchiveCapture
        private(set) var soloScreenshotsByOid: [NSNumber: Data] = [:]
        private(set) var groupScreenshotsByOid: [NSNumber: Data] = [:]
        /// Layers already emitted; the tree numbering visits each once, and
        /// so does this.
        private var convertedLayers: Set<ObjectIdentifier> = []

        init(capture: CoreAnimationArchiveCapture) {
            self.capture = capture
        }

        func makingItem(for layer: CALayer) -> DisplayItem {
            convertedLayers.insert(ObjectIdentifier(layer))
            let objectIdentifier = capture.tree.objectIdentifier(of: layer)

            let item = DisplayItem()
            let viewIdentity = CoreAnimationArchiveViewIdentity(layer: layer)
            item.nodeKind = viewIdentity == nil ? .layer : .view
            // A layer other code named reads by that name, as Mica's outline
            // shows it (`NSCGSWindow`, `CUIWindowFrameLayer`, `CAHostingLayer`);
            // its class stays on the Class card. A view reads by its class.
            if viewIdentity == nil, let name = layer.name, !name.isEmpty {
                item.customDisplayTitle = name
            }
            // Nothing else sets this for a node built in memory, and NO reads as
            // "the user hid this layer's image", taking its subtree's previews
            // with it.
            item.shouldCaptureImage = true
            item.frame = layer.frame
            item.bounds = layer.bounds
            item.isFlipped = layer.contentsAreFlipped()
            item.isHidden = layer.isHidden
            item.alpha = layer.opacity
            if let backgroundColor = layer.backgroundColor {
                item.backgroundColor = NSColor(cgColor: backgroundColor)
            }

            let layerObject = InspectedObject()
            layerObject.oid = objectIdentifier
            layerObject.classChainList = viewIdentity?.layerClassChain ?? CoreAnimationArchiveConverter.classChain(of: layer)
            item.layerObject = layerObject
            if let viewIdentity {
                // The merged node routes by its layer oid, as a live view node
                // does while backing layers are hidden; the view still needs an
                // oid of its own, which no layer's number may collide with.
                let viewObject = InspectedObject()
                viewObject.oid = UInt(capture.tree.layers.count) + objectIdentifier
                viewObject.classChainList = viewIdentity.viewClassChain
                item.viewObject = viewObject
            }
            item.attributesGroupList = CoreAnimationArchiveAttributes.makingGroups(for: layer, viewIdentity: viewIdentity)

            filingScreenshots(of: objectIdentifier, onto: item)
            item.subitems = (layer.sublayers ?? []).compactMap { sublayer in
                guard !convertedLayers.contains(ObjectIdentifier(sublayer)) else { return nil }
                return makingItem(for: sublayer)
            }
            return item
        }

        private func filingScreenshots(of objectIdentifier: UInt, onto item: DisplayItem) {
            guard objectIdentifier != 0 else { return }
            let key = NSNumber(value: UInt64(objectIdentifier))
            let screenshots = capture.screenshots
            if let soloImage = screenshots.soloByObjectIdentifier[objectIdentifier] {
                soloScreenshotsByOid[key] = soloImage
            }
            if let groupImage = screenshots.groupByObjectIdentifier[objectIdentifier] {
                groupScreenshotsByOid[key] = groupImage
            }
            if let region = screenshots.groupRegionByObjectIdentifier[objectIdentifier] {
                // Measured from the bounds origin; the node's bounds may sit at
                // another origin.
                item.groupScreenshotRegion = region.offsetBy(dx: item.bounds.origin.x, dy: item.bounds.origin.y)
            }
        }
    }

    /// The decoded object's class and its superclasses, up to NSObject: the
    /// shape of the server's `lks_classChainList`.
    static func classChain(of layer: CALayer) -> [String] {
        classChain(of: type(of: layer))
    }

    /// `someClass` and its superclasses, up to the root class. Walks the
    /// runtime's metadata only and sends the classes no message, so it runs
    /// no `+initialize`.
    static func classChain(of someClass: AnyClass) -> [String] {
        var chain: [String] = []
        var currentClass: AnyClass? = someClass
        while let visitedClass = currentClass {
            chain.append(NSStringFromClass(visitedClass))
            currentClass = class_getSuperclass(visitedClass)
        }
        return chain
    }

    private static func makingAppInfo(origin: CoreAnimationArchiveOrigin?) -> InspectedAppInfo {
        let appInfo = InspectedAppInfo()
        appInfo.appName = origin?.processName ?? NSLocalizedString(
            "Core Animation Archive",
            comment: "App name shown for an opened .caar file (a Core Animation archive) whose file name does not say which app it came from."
        )
        appInfo.serverVersion = Int32(LOOKIN_SERVER_VERSION)
        // Dump Layer exists only in the AppKit debug menu, and Mac Catalyst
        // apps run on the Mac too: the archive always comes from a Mac.
        appInfo.deviceType = .mac
        appInfo.deviceDescription = "Mac"
        return appInfo
    }
}

// MARK: - Views

/// The view a decoded layer backed, recovered from what AppKit wrote onto the
/// layer; nil for a layer that backed no view, or one that left no name.
///
/// The archive holds no views: a layer's delegate is not archived, and its
/// class is cut back to QuartzCore's. Two traces of the view remain, both
/// written by AppKit when the view got its layer (macOS 27.2):
///
/// - `-[NSView setLayer:]` sets `edgeAntialiasingMask` to 0 on every layer it
///   installs, whoever made the layer. Other layers keep the default of all
///   four edges, except the window's own two above the views (the
///   `NSCGSWindow` root and `NSWindow content layer`), which the name test
///   below turns away.
/// - `-[NSView _createLayerAndInitialize]`, which makes the layer of every
///   layer-backed view, names it `[view className]`, or
///   `"<layer className>: <view className>"` when `-makeBackingLayer`
///   returned something other than an `NSViewBackingLayer`.
///
/// A layer the app made and handed to the view itself (a layer-hosting view)
/// has no such name, and code may rename a layer afterwards: AppKit's scroll
/// pockets call theirs `PocketMask` and `Container`, Xcode appends
/// `_ControlledBy_<controller>`. The first stays a layer node; the second
/// becomes a view node whose class is that name, which the name cannot be
/// told apart from.
struct CoreAnimationArchiveViewIdentity {
    /// The view's class and its superclasses when this process has the class
    /// (AppKit's own); the bare class name when it does not (the dumped
    /// app's).
    let viewClassChain: [String]
    /// The layer's own class chain, when the name records a class this process
    /// has; nil to use the decoded layer's.
    let layerClassChain: [String]?

    init?(layer: CALayer) {
        guard layer.edgeAntialiasingMask.isEmpty, let name = layer.name else { return nil }

        let viewClassName: String
        let layerClassName: String?
        if let separatorRange = name.range(of: ": ") {
            layerClassName = String(name[..<separatorRange.lowerBound])
            viewClassName = String(name[separatorRange.upperBound...])
        } else {
            layerClassName = nil
            viewClassName = name
        }
        guard Self.isShapedLikeClassName(viewClassName),
              layerClassName.map(Self.isShapedLikeClassName) ?? true
        else { return nil }

        // The names come from a file, but the class lookup is the one the
        // keyed unarchiver already made for every class the file names, and it
        // runs no code of the class it finds.
        if let viewClass = NSClassFromString(viewClassName) {
            // A class this process has and that is no view: the name was
            // something else's, such as the window's root layer's.
            guard Self.isClass(viewClass, kindOf: NSView.self) else { return nil }
            viewClassChain = CoreAnimationArchiveConverter.classChain(of: viewClass)
        } else {
            viewClassChain = [viewClassName]
        }

        if let layerClassName, let layerClass = NSClassFromString(layerClassName),
           Self.isClass(layerClass, kindOf: CALayer.self)
        {
            layerClassChain = CoreAnimationArchiveConverter.classChain(of: layerClass)
        } else {
            layerClassChain = nil
        }
    }

    /// The view's chain the way the Class card lists it: up to NSView, as the
    /// server's `lks_relatedClassChainList` lists a view's.
    var classCardChain: [String] {
        viewClassChain.firstIndex(of: "NSView").map { Array(viewClassChain[...$0]) } ?? viewClassChain
    }

    /// `className` spells an Objective-C name, a module-qualified Swift name
    /// or a mangled one (`_TtC…`, which may hold `$`); none has a space or a
    /// colon, and a name written for people, such as `NSWindow content layer`,
    /// usually has a space.
    private static func isShapedLikeClassName(_ name: String) -> Bool {
        !name.isEmpty && !name.contains { $0.isWhitespace || $0 == ":" }
    }

    /// Walks the superclass chain rather than asking the class, which would
    /// send it a message and run its `+initialize`.
    private static func isClass(_ someClass: AnyClass, kindOf ancestor: AnyClass) -> Bool {
        var currentClass: AnyClass? = someClass
        while let visitedClass = currentClass {
            if visitedClass === ancestor {
                return true
            }
            currentClass = class_getSuperclass(visitedClass)
        }
        return false
    }
}

// MARK: - Attributes

/// The dashboard rows of one decoded layer: the rows the blueprint aims at a
/// CALayer, in the blueprint's card order, typed the way the server types
/// them for a live layer.
///
/// The rows are listed by identifier below rather than found by asking the
/// blueprint for each row's target: in a Debug build the blueprint raises
/// for a row whose class it does not record, and the card order shared with
/// the `.viewhierarchy` import lists rows of every kind.
enum CoreAnimationArchiveAttributes {
    static func makingGroups(for layer: CALayer, viewIdentity: CoreAnimationArchiveViewIdentity? = nil) -> [AttributesGroup] {
        var groups: [AttributesGroup] = []
        for catalogGroup in XcodeViewHierarchyAttributeCatalog.groups {
            var sections: [AttributesSection] = []
            for catalogSection in catalogGroup.sections {
                let attributes = catalogSection.attributes.compactMap { identifier in
                    makingAttribute(identifier, of: layer, viewIdentity: viewIdentity)
                }
                if !attributes.isEmpty {
                    let section = AttributesSection()
                    section.identifier = catalogSection.identifier
                    section.attributes = attributes
                    sections.append(section)
                }
            }
            if !sections.isEmpty {
                let group = AttributesGroup()
                group.identifier = catalogGroup.identifier
                group.attrSections = sections
                groups.append(group)
            }
        }
        return groups
    }

    private static func makingAttribute(
        _ identifier: String,
        of layer: CALayer,
        viewIdentity: CoreAnimationArchiveViewIdentity?
    ) -> InspectedAttribute? {
        switch identifier {
        case LookinAttr_Class_Class_Class:
            // The server's `lks_relatedClassChainList`: for a layer that backs
            // a view, the view's chain up to NSView (the view controller's
            // chain it adds is not in the archive); for any other layer, its
            // own chain, cut after CALayer.
            if let viewIdentity {
                return attribute(identifier, .customObj, [viewIdentity.classCardChain] as NSArray)
            }
            let chain = CoreAnimationArchiveConverter.classChain(of: layer)
            let trimmedChain = chain.firstIndex(of: "CALayer").map { Array(chain[...$0]) } ?? chain
            return attribute(identifier, .customObj, [trimmedChain] as NSArray)
        case LookinAttr_Layout_Frame_Frame:
            return attribute(identifier, .cgRect, NSValue(rect: layer.frame))
        case LookinAttr_Layout_Bounds_Bounds:
            return attribute(identifier, .cgRect, NSValue(rect: layer.bounds))
        case LookinAttr_Layout_Position_Position:
            return attribute(identifier, .cgPoint, NSValue(point: layer.position))
        case LookinAttr_Layout_AnchorPoint_AnchorPoint:
            return attribute(identifier, .cgPoint, NSValue(point: layer.anchorPoint))
        case LookinAttr_ViewLayer_Visibility_Hidden:
            return attribute(identifier, .BOOL, NSNumber(value: layer.isHidden))
        case LookinAttr_ViewLayer_Visibility_Opacity:
            return attribute(identifier, .float, NSNumber(value: layer.opacity))
        case LookinAttr_ViewLayer_InterationAndMasks_MasksToBounds:
            return attribute(identifier, .BOOL, NSNumber(value: layer.masksToBounds))
        case LookinAttr_ViewLayer_Corner_Radius:
            return attribute(identifier, .double, NSNumber(value: Double(layer.cornerRadius)))
        case LookinAttr_ViewLayer_BgColor_BgColor:
            return colorAttribute(identifier, layer.backgroundColor)
        case LookinAttr_ViewLayer_Border_Color:
            return colorAttribute(identifier, layer.borderColor)
        case LookinAttr_ViewLayer_Border_Width:
            return attribute(identifier, .double, NSNumber(value: Double(layer.borderWidth)))
        case LookinAttr_ViewLayer_Shadow_Color:
            return colorAttribute(identifier, layer.shadowColor)
        case LookinAttr_ViewLayer_Shadow_Opacity:
            return attribute(identifier, .float, NSNumber(value: layer.shadowOpacity))
        case LookinAttr_ViewLayer_Shadow_Radius:
            return attribute(identifier, .double, NSNumber(value: Double(layer.shadowRadius)))
        case LookinAttr_ViewLayer_Shadow_OffsetW:
            return attribute(identifier, .double, NSNumber(value: Double(layer.shadowOffset.width)))
        case LookinAttr_ViewLayer_Shadow_OffsetH:
            return attribute(identifier, .double, NSNumber(value: Double(layer.shadowOffset.height)))
        default:
            // The class image paths and the Relation card: a decoded layer
            // has neither an image of its own process nor an owner to name.
            return nil
        }
    }

    /// A colour row: RGBA in 0...1, the value a `LookinAttrTypeUIColor`
    /// carries (`LookinAttrType.h`). No colour — or one with no RGB
    /// equivalent, such as a pattern — is shown as nil unless the blueprint
    /// hides nil for the row.
    private static func colorAttribute(_ identifier: String, _ color: CGColor?) -> InspectedAttribute? {
        if let components = rgbaComponents(of: color) {
            return attribute(identifier, .uiColor, components as NSArray)
        }
        guard !DashboardBlueprint.hideIfNil(withAttrID: identifier) else { return nil }
        return attribute(identifier, .uiColor, nil)
    }

    static func rgbaComponents(of color: CGColor?) -> [NSNumber]? {
        guard let color,
              let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = color.converted(to: sRGB, intent: .defaultIntent, options: nil),
              let components = converted.components,
              components.count == 4
        else { return nil }
        return components.map { NSNumber(value: Double(min(max($0, 0), 1))) }
    }

    private static func attribute(_ identifier: String, _ attrType: LookinAttrType, _ value: Any?) -> InspectedAttribute {
        let attribute = InspectedAttribute()
        attribute.identifier = identifier
        attribute.attrType = attrType
        attribute.value = value
        return attribute
    }
}
