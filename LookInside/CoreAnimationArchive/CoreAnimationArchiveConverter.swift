// CoreAnimationArchiveConverter.swift
//
// Turns a decoded and rendered Core Animation archive into the inspector's
// model: one `.layer` node per layer, in a `HierarchyFile` the read-only
// window shows exactly as it shows a `.lookin` archive.
//
// Each node takes the shape the server gives a layer that backs no view
// (`HierarchyDisplayItemsMaker`): the layer's frame and bounds, visibility,
// opacity and background colour, and the dashboard rows the blueprint aims
// at a CALayer, read here from the decoded layer as the server reads them
// from the live one.
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
// layer as its nearest QuartzCore class (`CALayerCreateCodingProxy`), so a
// view's backing layer arrives as a CALayer and the Class card shows that.

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
            item.nodeKind = .layer
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

            let object = InspectedObject()
            object.oid = objectIdentifier
            object.classChainList = CoreAnimationArchiveConverter.classChain(of: layer)
            item.layerObject = object
            item.attributesGroupList = CoreAnimationArchiveAttributes.makingGroups(for: layer)

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
        var chain: [String] = []
        var currentClass: AnyClass? = type(of: layer)
        while let someClass = currentClass {
            chain.append(NSStringFromClass(someClass))
            currentClass = class_getSuperclass(someClass)
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
    static func makingGroups(for layer: CALayer) -> [AttributesGroup] {
        var groups: [AttributesGroup] = []
        for catalogGroup in XcodeViewHierarchyAttributeCatalog.groups {
            var sections: [AttributesSection] = []
            for catalogSection in catalogGroup.sections {
                let attributes = catalogSection.attributes.compactMap { identifier in
                    makingAttribute(identifier, of: layer)
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

    private static func makingAttribute(_ identifier: String, of layer: CALayer) -> InspectedAttribute? {
        switch identifier {
        case LookinAttr_Class_Class_Class:
            // The server's `lks_relatedClassChainList` for a layer that backs
            // no view: its own chain, cut after CALayer.
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
