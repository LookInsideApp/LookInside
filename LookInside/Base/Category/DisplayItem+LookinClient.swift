//
//  DisplayItem+LookinClient.swift
//  LookInside
//
//  Host-side display helpers on the LookinCore display item: the row title
//  and subtitle, which object id a request should use, preview screenshot
//  choice, ancestor and subtree walks, class-chain predicates and the
//  SwiftUI identifiers read out of attribute groups. Selectors keep their
//  Objective-C names for the callers that still use them.
//

import AppKit
import LookInsideHostCore

extension DisplayItem {
    /// The row text in the hierarchy, usually the class name without module.
    @objc func title() -> String {
        let baseTitle: String?
        if let customInfo {
            baseTitle = customInfo.title
        } else if let customDisplayTitle, !customDisplayTitle.isEmpty {
            baseTitle = customDisplayTitle
        } else {
            baseTitle = displayingObject()?.simpleDemangledClassName()
        }
        return PrivateDiscriminatorStore.shared.displayTitle(for: self, fallback: baseTitle) ?? ""
    }

    /// The owning window or view controller, a special trace, or the ivar
    /// names that point at the object; nil when there is none.
    @objc func subtitle() -> String? {
        if let customInfo {
            return customInfo.subtitle
        }
        if let windowControllerName = hostWindowControllerObject?.simpleDemangledClassName(), !windowControllerName.isEmpty {
            return "\(windowControllerName).window"
        }
        if let viewControllerName = hostViewControllerObject?.simpleDemangledClassName(), !viewControllerName.isEmpty {
            return "\(viewControllerName).view"
        }
        let representedObject = displayingObject()
        if let specialTrace = representedObject?.specialTrace, !specialTrace.isEmpty {
            return specialTrace
        }
        if let ivarTraces = representedObject?.ivarTraces, !ivarTraces.isEmpty {
            let names: [String] = ivarTraces.compactMap(\.ivarName)
            return (NSSet(array: names).allObjects as NSArray).componentsJoined(by: "   ")
        }
        return nil
    }

    /// The solo screenshot once children that draw something are shown on
    /// their own; the group screenshot otherwise.
    @objc func appropriateScreenshot() -> NSImage? {
        // A node whose children are all pixelless (layout guides, cells, a
        // view's outer layer) has nothing to exclude, and a leaf view has no
        // solo screenshot at all — asking for one there blanks it out.
        if isExpandable, isExpanded, hasPixelBearingSubitems() {
            return soloScreenshot
        }
        return groupScreenshot
    }

    @objc(bestObjectOidPreferView:)
    func bestObjectOidPreferView(_: Bool) -> UInt {
        switch resolvedNodeKind() {
        case .window, .windowScene:
            return windowObject?.oid ?? 0
        case .layoutGuide, .cell:
            return kindObject?.oid ?? 0
        case .custom:
            // Custom nodes carry no oid — a known limitation, out of scope
            // for the nodeKind mechanism itself.
            return 0
        case .view, .layer, .viewOuterLayer, .backingLayer, .unspecified:
            // A view's outer layer and a backing layer node ride layerObject
            // like any other layer node. With the backing-layer toggle ON the
            // layer oid belongs to the separate BackingLayer child node —
            // requests keyed by it would land on that node on both ends. The
            // view node itself must route by its view oid.
            if let viewOid = viewObject?.oid, viewOid != 0, ownsSeparateBackingLayerNode() {
                return viewOid
            }
            // Prefer the layer oid, as upstream does: the server's detail
            // handler resolves and captures through the CALayer oid.
            if let layerOid = layerObject?.oid, layerOid != 0 {
                return layerOid
            }
            if let viewOid = viewObject?.oid, viewOid != 0 {
                return viewOid
            }
            return windowObject?.oid ?? 0
        @unknown default:
            return 0
        }
    }

    /// Whether a separate BackingLayer child node claimed this view node's
    /// layer oid (backing-layer toggle ON); requests for this node must then
    /// route by the view oid. Read off the tree rather than the preference,
    /// so it stays false against servers that ignored the toggle.
    @objc func ownsSeparateBackingLayerNode() -> Bool {
        guard let layerOid = layerObject?.oid, layerOid != 0,
              let viewOid = viewObject?.oid, viewOid != 0
        else { return false }
        for subitem in subitems ?? [] {
            if subitem.resolvedNodeKind() == .backingLayer {
                return subitem.layerObject?.oid == layerOid
            }
            // On iOS the BackingLayer node nests inside the wrapper node
            // (view → outer layer → backing layer, Xcode's arrangement).
            if subitem.resolvedNodeKind() == .viewOuterLayer {
                for wrapperChild in subitem.subitems ?? [] where wrapperChild.resolvedNodeKind() == .backingLayer {
                    return wrapperChild.layerObject?.oid == layerOid
                }
            }
        }
        return false
    }

    /// The preferred oid first, then every other oid this node carries.
    @objc(availableObjectOidsPreferView:)
    func availableObjectOidsPreferView(_ preferView: Bool) -> [NSNumber] {
        var oids: [UInt] = []
        func add(_ oid: UInt?) {
            if let oid, oid != 0, !oids.contains(oid) {
                oids.append(oid)
            }
        }
        add(bestObjectOidPreferView(preferView))
        add(viewObject?.oid)
        add(layerObject?.oid)
        add(kindObject?.oid)
        return oids.map { NSNumber(value: $0) }
    }

    /// Whether the title starts like a system class ("UI", "CA", "NS", "_").
    @objc var representedForSystemClass: Bool {
        let title = title()
        return title.hasPrefix("UI") || title.hasPrefix("CA") || title.hasPrefix("_") || title.hasPrefix("NS")
    }

    @objc func isUserCustom() -> Bool {
        customInfo != nil
    }

    /// Whether the preview can draw a box for this node.
    @objc func hasPreviewBoxAbility() -> Bool {
        guard let customInfo else { return true }
        return customInfo.hasValidFrame()
    }

    /// Whether an expanded node shows its group screenshot in the preview
    /// because its solo screenshot is (nearly) empty.
    @objc func usesGroupScreenshotFallbackInPreview() -> Bool {
        guard isExpandable, isExpanded else { return false }
        // A window root's solo screenshot is always nearly transparent (just
        // the frame) — its children draw the content. Falling back here
        // would make the ancestor suppression blank every child.
        let nodeKind = resolvedNodeKind()
        if nodeKind == .window || nodeKind == .windowScene {
            return false
        }
        let solo = soloScreenshot
        let group = groupScreenshot
        return ClientDisplayText.prefersGroupScreenshot(
            soloVisibleRatio: { solo.map(Self.approximateVisiblePixelRatio) },
            groupVisibleRatio: { group.map(Self.approximateVisiblePixelRatio) },
            hasGroupScreenshot: group != nil
        )
    }

    @objc func hasAncestorUsingGroupScreenshotFallbackInPreview() -> Bool {
        var found = false
        enumerateAncestors { item, stop in
            if item.usesGroupScreenshotFallbackInPreview() {
                found = true
                stop.pointee = true
            }
        }
        return found
    }

    /// Whether the node matches a non-empty hierarchy filter: its title,
    /// subtitle or one of its objects' addresses contains the text.
    @objc(isMatchedWithSearchString:)
    func isMatched(withSearch string: String) -> Bool {
        if string.isEmpty {
            assertionFailure("an empty search string matches nothing")
            return false
        }
        // NSString comparisons, as the inspector always matched; addresses
        // are compared as they are, without lowercasing.
        let searchString = (string as NSString).lowercased
        if (title() as NSString).lowercased.contains(searchString) {
            return true
        }
        if let subtitle = subtitle(), (subtitle as NSString).lowercased.contains(searchString) {
            return true
        }
        for object in [viewObject, layerObject, windowObject, kindObject] {
            if let address = object?.memoryAddress, (address as NSString).contains(searchString) {
                return true
            }
        }
        return false
    }

    /// Visits this item, then each ancestor up to the root, until stopped.
    @objc(enumerateSelfAndAncestors:)
    func enumerateSelfAndAncestors(_ block: (DisplayItem, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var item: DisplayItem? = self
        while let current = item {
            var shouldStop: ObjCBool = false
            block(current, &shouldStop)
            if shouldStop.boolValue {
                break
            }
            item = current.`super`
        }
    }

    @objc(enumerateAncestors:)
    func enumerateAncestors(_ block: (DisplayItem, UnsafeMutablePointer<ObjCBool>) -> Void) {
        self.`super`?.enumerateSelfAndAncestors(block)
    }

    /// Visits this item and then its whole subtree, depth first.
    @objc(enumerateSelfAndChildren:)
    func enumerateSelfAndChildren(_ block: (DisplayItem) -> Void) {
        block(self)
        for subitem in subitems ?? [] {
            subitem.enumerateSelfAndChildren(block)
        }
    }

    @objc(itemIsKindOfClassWithName:)
    func itemIsKindOfClass(withName className: String) -> Bool {
        itemIsKindOfClasses(withNames: [className])
    }

    /// Whether any class in the displayed object's class chain, without its
    /// module prefix, is one of `classNames`.
    @objc(itemIsKindOfClassesWithNames:)
    func itemIsKindOfClasses(withNames classNames: Set<String>) -> Bool {
        guard !classNames.isEmpty, let object = displayingObject() else { return false }
        let chain = object.classChainList ?? []
        return classNames.contains { target in
            chain.contains { ClientDisplayText.classChainEntry($0, matches: target) }
        }
    }

    // MARK: - SwiftUI

    @objc func isSwiftUISupportRelated() -> Bool {
        func looksLikeSwiftUISupport(_ object: InspectedObject?) -> Bool {
            guard let object else { return false }
            if ClientDisplayText.looksLikeSwiftUISupport(object.rawClassName()) {
                return true
            }
            return (object.classChainList ?? []).contains { ClientDisplayText.looksLikeSwiftUISupport($0) }
        }
        if looksLikeSwiftUISupport(viewObject) || looksLikeSwiftUISupport(layerObject)
            || looksLikeSwiftUISupport(windowObject) || looksLikeSwiftUISupport(kindObject)
        {
            return true
        }
        return ClientDisplayText.looksLikeSwiftUISupport(title()) || ClientDisplayText.looksLikeSwiftUISupport(subtitle())
    }

    /// Addresses of the layers named by "… Backed By" rows in the
    /// "SwiftUI Layers" group.
    @objc func swiftUIBackingLayerMemoryAddresses() -> [String] {
        var addresses: [String] = []
        for group in allAttributeGroups where group.userCustomTitle == "SwiftUI Layers" {
            for attribute in group.allAttributes {
                guard let title = attribute.displayTitle, title.hasSuffix("Backed By"),
                      let value = attribute.value as? String,
                      let address = Self.memoryAddress(inObjectDescription: value),
                      !addresses.contains(address)
                else { continue }
                addresses.append(address)
            }
        }
        return addresses
    }

    /// Display-list IDs from "… Display List ID" rows of "SwiftUI Layers"
    /// and "Identity IDs" rows of "SwiftUI Display List".
    @objc func swiftUIBackingDisplayListIDs() -> [NSNumber] {
        var displayListIDs: [UInt64] = []
        for group in allAttributeGroups {
            let isLayersGroup = group.userCustomTitle == "SwiftUI Layers"
            let isDisplayListGroup = group.userCustomTitle == "SwiftUI Display List"
            guard isLayersGroup || isDisplayListGroup else { continue }
            for attribute in group.allAttributes {
                guard let value = attribute.value as? String else { continue }
                let title = attribute.displayTitle ?? ""
                let isLayerDisplayListID = isLayersGroup && title.hasSuffix("Display List ID")
                let isIdentityIDs = isDisplayListGroup && title == "Identity IDs"
                guard isLayerDisplayListID || isIdentityIDs else { continue }
                for displayListID in ClientDisplayText.swiftUIDisplayListIDs(in: value) where !displayListIDs.contains(displayListID) {
                    displayListIDs.append(displayListID)
                }
            }
        }
        return displayListIDs.map { NSNumber(value: $0) }
    }

    /// The first "Display List ID" of the "SwiftUI" group, for layer nodes.
    @objc func swiftUILayerDisplayListID() -> NSNumber? {
        guard layerObject != nil else { return nil }
        for group in allAttributeGroups where group.userCustomTitle == "SwiftUI" {
            for attribute in group.allAttributes {
                guard attribute.displayTitle == "Display List ID", let value = attribute.value as? String else { continue }
                if let first = ClientDisplayText.swiftUIDisplayListIDs(in: value).first {
                    return NSNumber(value: first)
                }
            }
        }
        return nil
    }

    /// "Source" and "Full Source" values of the "SwiftUI" group.
    @objc func swiftUILayerSourceTypeNames() -> [String] {
        var sourceNames: [String] = []
        for group in allAttributeGroups where group.userCustomTitle == "SwiftUI" {
            for attribute in group.allAttributes {
                guard attribute.displayTitle == "Source" || attribute.displayTitle == "Full Source",
                      let value = attribute.value as? String, !sourceNames.contains(value)
                else { continue }
                sourceNames.append(value)
            }
        }
        return sourceNames
    }

    /// The custom node's title, then "Type" and "Full Type" values of the
    /// "SwiftUI Type" group.
    @objc func swiftUITypeNames() -> [String] {
        var typeNames: [String] = []
        if let customTitle = customInfo?.title {
            typeNames.append(customTitle)
        }
        for group in allAttributeGroups where group.userCustomTitle == "SwiftUI Type" {
            for attribute in group.allAttributes {
                guard attribute.displayTitle == "Type" || attribute.displayTitle == "Full Type",
                      let value = attribute.value as? String, !typeNames.contains(value)
                else { continue }
                typeNames.append(value)
            }
        }
        return typeNames
    }

    @objc(lk_validSwiftUIDisplayListIDsInString:)
    static func validSwiftUIDisplayListIDs(in string: String) -> [NSNumber] {
        ClientDisplayText.swiftUIDisplayListIDs(in: string).map { NSNumber(value: $0) }
    }

    @objc(lk_memoryAddressInObjectDescription:)
    static func memoryAddress(inObjectDescription description: String) -> String? {
        ClientDisplayText.memoryAddress(inObjectDescription: description)
    }

    // MARK: - Private

    private var allAttributeGroups: [AttributesGroup] {
        (attributesGroupList ?? []) + (customAttrGroupList ?? [])
    }

    /// The share of visible pixels in a 16×16 downsample of `image`.
    private static func approximateVisiblePixelRatio(_ image: NSImage) -> Double {
        guard image.size.width > 0, image.size.height > 0 else { return 0 }
        var proposedRect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else { return 0 }
        let side = 16
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return 0 }
        return ClientDisplayText.visiblePixelRatio(rgbaPixels: pixels)
    }
}

private extension AttributesGroup {
    /// Every attribute of every section, in order.
    var allAttributes: [InspectedAttribute] {
        (attrSections ?? []).flatMap { $0.attributes ?? [] }
    }
}
