//
//  LookinDisplayItem.swift
//  qmuidemo
//
//  Was LookinDisplayItem.m: one
//  hierarchy node on the wire, in .lookin documents, and in the host's tree.
//  The coding keys, scalar encodings, decode defaults and the conditional
//  screenshot keys are pinned by Tests/WireFormatGolden. The setters keep the
//  original's side effects (tree bookkeeping and delegate notifications) in
//  the same order.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif
    #if canImport(UIKit)
        import UIKit
    #elseif os(macOS)
        import AppKit
    #endif

    // The colour's RGBA components are archived as the very NSArray the
    // category returns (bridging through [NSNumber] would copy it), and the
    // decoded value is handed back untouched.
    #if canImport(UIKit)
        /// `-[UIColor lks_rgbaComponents]` and `+[UIColor
        /// lks_colorFromRGBAComponents:]` live in LookinServer
        /// (UIColor+LookinServer.h); LookinCore does not link against the
        /// server, so they are sent dynamically, as the original's import did.
        @objc private protocol LookinDisplayItemColorBridge {
            func lks_rgbaComponents() -> NSArray?
            func lks_colorFromRGBAComponents(_ components: AnyObject?) -> AnyObject?
        }

        private func lookinRGBAComponents(of color: LookinColor?) -> NSArray? {
            guard let color else {
                return nil
            }
            return unsafeBitCast(color, to: LookinDisplayItemColorBridge.self).lks_rgbaComponents()
        }

        private func lookinColor(fromRGBAComponents components: Any?) -> LookinColor? {
            let colorClass: AnyObject = UIColor.self
            return unsafeBitCast(colorClass, to: LookinDisplayItemColorBridge.self).lks_colorFromRGBAComponents(components as AnyObject?) as? LookinColor
        }
    #elseif os(macOS)
        /// `-[NSColor lookin_rgbaComponents]` and `+[NSColor
        /// lookin_colorFromRGBAComponents:]` (Color+Lookin.h), sent the same way
        /// so the arrays are not bridged.
        @objc private protocol LookinDisplayItemColorBridge {
            func lookin_rgbaComponents() -> NSArray?
            func lookin_colorFromRGBAComponents(_ components: AnyObject?) -> AnyObject?
        }

        private func lookinRGBAComponents(of color: LookinColor?) -> NSArray? {
            guard let color else {
                return nil
            }
            return unsafeBitCast(color, to: LookinDisplayItemColorBridge.self).lookin_rgbaComponents()
        }

        private func lookinColor(fromRGBAComponents components: Any?) -> LookinColor? {
            let colorClass: AnyObject = NSColor.self
            return unsafeBitCast(colorClass, to: LookinDisplayItemColorBridge.self).lookin_colorFromRGBAComponents(components as AnyObject?) as? LookinColor
        }
    #endif

    /// The screenshot decode of -initWithCoder:: PNG/TIFF data, or the image
    /// object itself.
    private func lookinDecodedScreenshot(_ screenshotObj: Any?) -> LookinImage?? {
        guard let screenshotObj = screenshotObj as? NSObject else {
            return .none
        }
        if screenshotObj.isKind(of: NSData.self) {
            return .some(screenshotObj.lookin_decodedObject(with: .image) as? LookinImage)
        }
        if let image = screenshotObj as? LookinImage {
            return .some(image)
        }
        assertionFailure()
        return .none
    }

    /// Was declared in LookinDisplayItem.h; same runtime name and selector.
    @objc(LookinDisplayItemDelegate)
    public protocol LookinDisplayItemDelegate: NSObjectProtocol {
        @objc(displayItem:propertyDidChange:)
        func displayItem(_ displayItem: LookinDisplayItem!, propertyDidChange property: LookinDisplayItemProperty)
    }

    @objc(LookinDisplayItem)
    public class LookinDisplayItem: NSObject, NSCoding, NSSecureCoding, NSCopying {
        // MARK: Storage behind the setters with side effects

        private var _subitems: [LookinDisplayItem]?
        private var _isHidden: Bool = false
        private var _alpha: Float = 0
        private var _frame: CGRect = .zero
        private var _bounds: CGRect = .zero
        private var _soloScreenshot: LookinImage?
        private var _groupScreenshot: LookinImage?
        private var _attributesGroupList: [LookinAttributesGroup]?
        private var _customAttrGroupList: [LookinAttributesGroup]?
        private var _isExpanded: Bool = false
        private var _isExpandable: Bool = false
        private var _displayingInHierarchy: Bool = false
        private var _inHiddenHierarchy: Bool = false
        private var _doNotFetchScreenshotReason: LookinDoNotFetchScreenshotReason = .fetchScreenshotPermitted
        private var _noPreview: Bool = false
        private var _inNoPreviewHierarchy: Bool = false
        private var _indentLevel: Int = 0
        private var _isInSearch: Bool = false
        private var _highlightedSearchString: String?
        #if os(macOS)
            private var _flipped: Bool = false
        #endif

        // MARK: Plain properties

        @objc(customInfo)
        public var customInfo: LookinCustomDisplayItemInfo!
        @objc(nodeKind)
        public var nodeKind: LookinDisplayItemNodeKind = .unspecified
        @objc(kindObject)
        public var kindObject: LookinObject!
        @objc(representsSystemManagedNode)
        public var representsSystemManagedNode: Bool = false
        @objc(cellObject)
        public var cellObject: LookinObject!
        @objc(soloScreenshotRegion)
        public var soloScreenshotRegion: CGRect = .zero
        @objc(groupScreenshotRegion)
        public var groupScreenshotRegion: CGRect = .zero
        @objc(windowObject)
        public var windowObject: LookinObject!
        @objc(viewObject)
        public var viewObject: LookinObject!
        @objc(layerObject)
        public var layerObject: LookinObject!
        @objc(hostViewControllerObject)
        public var hostViewControllerObject: LookinObject!
        @objc(hostWindowControllerObject)
        public var hostWindowControllerObject: LookinObject!
        @objc(eventHandlers)
        public var eventHandlers: [LookinEventHandler]!
        @objc(representedAsKeyWindow)
        public var representedAsKeyWindow: Bool = false
        @objc(backgroundColor)
        public var backgroundColor: LookinColor!
        @objc(shouldCaptureImage)
        public var shouldCaptureImage: Bool = false
        @objc(customDisplayTitle)
        public var customDisplayTitle: String!
        @objc(danceuiSource)
        public var danceuiSource: String!
        /// `superItem` in Objective-C; `super` in Swift, the name the old
        /// header's import gave it.
        @objc(superItem) public weak var `super`: LookinDisplayItem?
        @objc(screenshotEncodeType)
        public var screenshotEncodeType: LookinDisplayItemImageEncodeType = .none
        // `previewLayer` and `previewNode` keep their Objective-C accessors
        // (same selectors, same weak storage). Only the host app has the
        // LKDisplayItemNode class, so only its build types previewNode;
        // SwiftPM builds and the host's standalone test builds
        // (LOOKIN_CORE_STANDALONE) store an untyped object.
        // LookinPreviewItemLayer no longer exists anywhere.
        #if SWIFT_PACKAGE || LOOKIN_CORE_STANDALONE
            @objc private weak var previewNode: AnyObject?
        #else
            // Internal: LKDisplayItemNode is the host app's own class.
            @objc(previewNode)
            weak var previewNode: LKDisplayItemNode?
        #endif
        @objc private weak var previewLayer: AnyObject?
        @objc(previewZIndex)
        public var previewZIndex: Int = 0
        @objc(preferToBeCollapsed)
        public var preferToBeCollapsed: Bool = false
        @objc(hasDeterminedExpansion)
        public var hasDeterminedExpansion: Bool = false

        // MARK: Init

        override public init() {
            super.init()
            // The server creates its display items through this initializer.
            _updateDisplayingInHierarchyProperty()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newDisplayItem = LookinDisplayItem()
            newDisplayItem.subitems = subitems?.map { $0.copy() as! LookinDisplayItem }
            newDisplayItem.customInfo = customInfo?.copy() as? LookinCustomDisplayItemInfo
            newDisplayItem.isHidden = isHidden
            newDisplayItem.alpha = alpha
            newDisplayItem.frame = frame
            newDisplayItem.bounds = bounds
            #if os(macOS)
                newDisplayItem.isFlipped = isFlipped
            #endif
            newDisplayItem.soloScreenshot = soloScreenshot
            newDisplayItem.groupScreenshot = groupScreenshot
            newDisplayItem.soloScreenshotRegion = soloScreenshotRegion
            newDisplayItem.groupScreenshotRegion = groupScreenshotRegion
            newDisplayItem.viewObject = viewObject?.copy() as? LookinObject
            newDisplayItem.layerObject = layerObject?.copy() as? LookinObject
            newDisplayItem.windowObject = windowObject?.copy() as? LookinObject
            newDisplayItem.nodeKind = nodeKind
            newDisplayItem.kindObject = kindObject?.copy() as? LookinObject
            newDisplayItem.representsSystemManagedNode = representsSystemManagedNode
            newDisplayItem.cellObject = cellObject?.copy() as? LookinObject
            newDisplayItem.hostViewControllerObject = hostViewControllerObject?.copy() as? LookinObject
            newDisplayItem.hostWindowControllerObject = hostWindowControllerObject?.copy() as? LookinObject
            newDisplayItem.attributesGroupList = attributesGroupList?.map { $0.copy() as! LookinAttributesGroup }
            newDisplayItem.customAttrGroupList = customAttrGroupList?.map { $0.copy() as! LookinAttributesGroup }
            newDisplayItem.eventHandlers = eventHandlers?.map { ($0 as NSObject).copy() as! LookinEventHandler }
            newDisplayItem.shouldCaptureImage = shouldCaptureImage
            newDisplayItem.representedAsKeyWindow = representedAsKeyWindow
            newDisplayItem.customDisplayTitle = customDisplayTitle
            newDisplayItem.danceuiSource = danceuiSource
            newDisplayItem._updateDisplayingInHierarchyProperty()
            return newDisplayItem
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(customInfo, forKey: "customInfo")
            aCoder.encode(subitems, forKey: "subitems")
            aCoder.encode(isHidden, forKey: "hidden")
            aCoder.encode(alpha, forKey: "alpha")
            #if os(macOS)
                aCoder.encode(isFlipped, forKey: "isFlipped")
            #endif
            aCoder.encode(viewObject, forKey: "viewObject")
            aCoder.encode(layerObject, forKey: "layerObject")
            aCoder.encode(windowObject, forKey: "windowObject")
            aCoder.encode(nodeKind.rawValue, forKey: "nodeKind")
            aCoder.encode(kindObject, forKey: "kindObject")
            aCoder.encode(representsSystemManagedNode, forKey: "representsSystemManagedNode")
            aCoder.encode(cellObject, forKey: "cellObject")
            aCoder.encode(hostViewControllerObject, forKey: "hostViewControllerObject")
            aCoder.encode(hostWindowControllerObject, forKey: "hostWindowControllerObject")
            aCoder.encode(attributesGroupList, forKey: "attributesGroupList")
            aCoder.encode(customAttrGroupList, forKey: "customAttrGroupList")
            aCoder.encode(representedAsKeyWindow, forKey: "representedAsKeyWindow")
            aCoder.encode(eventHandlers, forKey: "eventHandlers")
            aCoder.encode(shouldCaptureImage, forKey: "shouldCaptureImage")
            if screenshotEncodeType == .nsData {
                aCoder.encode(soloScreenshot?.lookin_encodedObject(with: .image), forKey: "soloScreenshot")
                aCoder.encode(groupScreenshot?.lookin_encodedObject(with: .image), forKey: "groupScreenshot")
            } else if screenshotEncodeType == .image {
                aCoder.encode(soloScreenshot, forKey: "soloScreenshot")
                aCoder.encode(groupScreenshot, forKey: "groupScreenshot")
            }
            aCoder.encode(customDisplayTitle, forKey: "customDisplayTitle")
            aCoder.encode(danceuiSource, forKey: "danceuiSource")
            #if canImport(UIKit)
                // -encodeCGRect:forKey: stores NSStringFromCGRect. Spelled out
                // because on Mac Catalyst Foundation's -encodeRect:forKey:
                // imports with the same Swift signature and the call is
                // ambiguous.
                aCoder.encode(NSCoder.string(for: frame), forKey: "frame")
                aCoder.encode(NSCoder.string(for: bounds), forKey: "bounds")
                aCoder.encode(NSCoder.string(for: soloScreenshotRegion), forKey: "soloScreenshotRegion")
                aCoder.encode(NSCoder.string(for: groupScreenshotRegion), forKey: "groupScreenshotRegion")
            #elseif os(macOS)
                aCoder.encode(frame as NSRect, forKey: "frame")
                aCoder.encode(bounds as NSRect, forKey: "bounds")
                aCoder.encode(soloScreenshotRegion as NSRect, forKey: "soloScreenshotRegion")
                aCoder.encode(groupScreenshotRegion as NSRect, forKey: "groupScreenshotRegion")
            #endif
            aCoder.encode(lookinRGBAComponents(of: backgroundColor), forKey: "backgroundColor")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            customInfo = aDecoder.decodeObject(forKey: "customInfo") as? LookinCustomDisplayItemInfo
            subitems = aDecoder.decodeObject(forKey: "subitems") as? [LookinDisplayItem]
            isHidden = aDecoder.decodeBool(forKey: "hidden")
            alpha = aDecoder.decodeFloat(forKey: "alpha")
            #if os(macOS)
                isFlipped = aDecoder.decodeBool(forKey: "isFlipped")
            #endif
            windowObject = aDecoder.decodeObject(forKey: "windowObject") as? LookinObject
            viewObject = aDecoder.decodeObject(forKey: "viewObject") as? LookinObject
            layerObject = aDecoder.decodeObject(forKey: "layerObject") as? LookinObject
            // These fields exist since the nodeKind mechanism landed; absent keys
            // decode to Unspecified / nil / NO, which is exactly the legacy-data
            // contract resolvedNodeKind derives from.
            nodeKind = aDecoder.containsValue(forKey: "nodeKind") ? (LookinDisplayItemNodeKind(rawValue: aDecoder.decodeInteger(forKey: "nodeKind")) ?? .unspecified) : .unspecified
            kindObject = aDecoder.decodeObject(forKey: "kindObject") as? LookinObject
            representsSystemManagedNode = aDecoder.decodeBool(forKey: "representsSystemManagedNode")
            cellObject = aDecoder.decodeObject(forKey: "cellObject") as? LookinObject
            hostViewControllerObject = aDecoder.decodeObject(forKey: "hostViewControllerObject") as? LookinObject
            hostWindowControllerObject = aDecoder.decodeObject(forKey: "hostWindowControllerObject") as? LookinObject
            attributesGroupList = aDecoder.decodeObject(forKey: "attributesGroupList") as? [LookinAttributesGroup]
            customAttrGroupList = aDecoder.decodeObject(forKey: "customAttrGroupList") as? [LookinAttributesGroup]
            representedAsKeyWindow = aDecoder.decodeBool(forKey: "representedAsKeyWindow")

            if case let .some(decoded) = lookinDecodedScreenshot(aDecoder.decodeObject(forKey: "soloScreenshot")) {
                soloScreenshot = decoded
            }
            if case let .some(decoded) = lookinDecodedScreenshot(aDecoder.decodeObject(forKey: "groupScreenshot")) {
                groupScreenshot = decoded
            }

            eventHandlers = aDecoder.decodeObject(forKey: "eventHandlers") as? [LookinEventHandler]
            // Added in LookinServer 1.1.3.
            shouldCaptureImage = aDecoder.containsValue(forKey: "shouldCaptureImage") ? aDecoder.decodeBool(forKey: "shouldCaptureImage") : true
            customDisplayTitle = aDecoder.decodeObject(forKey: "customDisplayTitle") as? String
            danceuiSource = aDecoder.decodeObject(forKey: "danceuiSource") as? String
            #if canImport(UIKit)
                frame = aDecoder.decodeCGRect(forKey: "frame")
                bounds = aDecoder.decodeCGRect(forKey: "bounds")
                // Absent in archives and wire data that predate the field: zero,
                // the whole of bounds.
                soloScreenshotRegion = aDecoder.decodeCGRect(forKey: "soloScreenshotRegion")
                groupScreenshotRegion = aDecoder.decodeCGRect(forKey: "groupScreenshotRegion")
            #elseif os(macOS)
                frame = aDecoder.decodeRect(forKey: "frame")
                bounds = aDecoder.decodeRect(forKey: "bounds")
                soloScreenshotRegion = aDecoder.decodeRect(forKey: "soloScreenshotRegion")
                groupScreenshotRegion = aDecoder.decodeRect(forKey: "groupScreenshotRegion")
            #endif
            backgroundColor = lookinColor(fromRGBAComponents: aDecoder.decodeObject(forKey: "backgroundColor"))
            _updateDisplayingInHierarchyProperty()
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        // MARK: Node kind

        @objc(displayingObject)
        public func displayingObject() -> LookinObject! {
            kindObject ?? windowObject ?? viewObject ?? layerObject
        }

        @objc(resolvedNodeKind)
        public func resolvedNodeKind() -> LookinDisplayItemNodeKind {
            if nodeKind != .unspecified {
                return nodeKind
            }
            // Derivation for data that predates the field, matching how the
            // maker used the legacy slots: scene and window nodes both borrowed
            // windowObject (alone), custom nodes carry customInfo, view nodes
            // carry viewObject, and everything else is a bare layer.
            if customInfo != nil {
                return .custom
            }
            if let windowObject, viewObject == nil, layerObject == nil {
                let representsWindowScene = (windowObject.classChainList ?? []).contains { lookinStringsEqual($0, "UIWindowScene") }
                return representsWindowScene ? .windowScene : .window
            }
            if viewObject != nil {
                return .view
            }
            return .layer
        }

        @objc(shouldRenderAsCoplanarPreviewOverlay)
        public func shouldRenderAsCoplanarPreviewOverlay() -> Bool {
            switch resolvedNodeKind() {
            case .layoutGuide, .cell:
                return true
            default:
                return false
            }
        }

        @objc(isPixelBearing)
        public func isPixelBearing() -> Bool {
            switch resolvedNodeKind() {
            case .layoutGuide, .cell, .viewOuterLayer:
                return false
            default:
                return true
            }
        }

        @objc(hasPixelBearingSubitems)
        public func hasPixelBearingSubitems() -> Bool {
            for subitem in subitems ?? [] where subitem.isPixelBearing() || subitem.hasPixelBearingSubitems() {
                return true
            }
            return false
        }

        // MARK: Geometry

        @objc(hasValidFrameToRoot)
        public func hasValidFrameToRoot() -> Bool {
            if let customInfo {
                return customInfo.hasValidFrame()
            }
            return LookinIsUsableRect(frame)
        }

        @objc(calculateFrameToRoot)
        public func calculateFrameToRoot() -> CGRect {
            if let customInfo {
                guard hasValidFrameToRoot(), let frameInWindow = customInfo.frameInWindow else {
                    return .zero
                }
                #if canImport(UIKit)
                    return frameInWindow.cgRectValue
                #else
                    return frameInWindow.rectValue
                #endif
            }
            if !LookinIsUsableRect(frame) {
                return .zero
            }
            guard let superItem = self.super else {
                return frame
            }

            let superFrameToRoot = superItem.calculateFrameToRoot()
            var superBounds = superItem.bounds
            if !LookinIsUsableRect(superBounds) {
                superBounds = .zero
            }
            let selfFrame = frame

            let x = selfFrame.origin.x - superBounds.origin.x + superFrameToRoot.origin.x
            let y: CGFloat
            if superItem.isFlipped {
                y = superFrameToRoot.origin.y + (superBounds.size.height - selfFrame.origin.y - selfFrame.size.height)
            } else {
                y = selfFrame.origin.y - superBounds.origin.y + superFrameToRoot.origin.y
            }

            return CGRect(x: x, y: y, width: selfFrame.size.width, height: selfFrame.size.height)
        }

        @objc(frame)
        public var frame: CGRect {
            get { _frame }
            set {
                _frame = newValue
                recursivelyNotifyFrameToRootMayChange()
            }
        }

        @objc(bounds)
        public var bounds: CGRect {
            get { _bounds }
            set {
                _bounds = newValue
                recursivelyNotifyFrameToRootMayChange()
            }
        }

        /// Meaningful on macOS only; always NO on iOS, where the setter does
        /// nothing.
        /// `@property(getter=isFlipped) BOOL flipped`: the accessors keep the
        /// header's selectors (`-isFlipped`, `-setFlipped:`).
        @objc(flipped) public var isFlipped: Bool {
            @objc(isFlipped) get {
                #if os(macOS)
                    _flipped
                #else
                    false
                #endif
            }
            @objc(setFlipped:) set {
                #if os(macOS)
                    _flipped = newValue
                #endif
            }
        }

        private func recursivelyNotifyFrameToRootMayChange() {
            _notifyDelegates(with: .frameToRoot)
            for obj in subitems ?? [] {
                obj.recursivelyNotifyFrameToRootMayChange()
            }
        }

        // MARK: Attributes

        @objc(attributesGroupList)
        public var attributesGroupList: [LookinAttributesGroup]! {
            get { _attributesGroupList }
            set {
                _attributesGroupList = newValue
                lookinAssignTargetDisplayItem(self, in: newValue)
            }
        }

        @objc(customAttrGroupList)
        public var customAttrGroupList: [LookinAttributesGroup]! {
            get { _customAttrGroupList }
            set {
                _customAttrGroupList = newValue
                // Already sorted when it is passed in.
                lookinAssignTargetDisplayItem(self, in: newValue)
            }
        }

        @objc(queryAllAttrGroupList)
        public func queryAllAttrGroupList() -> [LookinAttributesGroup]! {
            var array: [LookinAttributesGroup] = []
            if let attributesGroupList {
                array.append(contentsOf: attributesGroupList)
            }
            if let customAttrGroupList {
                array.append(contentsOf: customAttrGroupList)
            }
            return array
        }

        // MARK: Tree

        @objc(subitems)
        public var subitems: [LookinDisplayItem]! {
            get { _subitems }
            set {
                for obj in _subitems ?? [] {
                    obj.super = nil
                }

                _subitems = newValue

                _setIsExpandable((newValue?.count ?? 0) > 0)

                for obj in newValue ?? [] {
                    assert(obj.super == nil)
                    obj.super = self

                    obj._updateInHiddenHierarchyProperty()
                    obj._updateDisplayingInHierarchyProperty()
                }
            }
        }

        @objc(indentLevel)
        public func indentLevel() -> Int {
            _indentLevel
        }

        @objc(isExpandable)
        public var isExpandable: Bool {
            _isExpandable
        }

        private func _setIsExpandable(_ isExpandable: Bool) {
            if _isExpandable == isExpandable {
                return
            }
            _isExpandable = isExpandable
            _notifyDelegates(with: .isExpandable)
        }

        @objc(isExpanded)
        public var isExpanded: Bool {
            get { _isExpanded }
            set {
                if _isExpanded == newValue {
                    return
                }
                _isExpanded = newValue
                for obj in subitems ?? [] {
                    obj._updateDisplayingInHierarchyProperty()
                }
                _notifyDelegates(with: .isExpanded)
            }
        }

        @objc(displayingInHierarchy)
        public var displayingInHierarchy: Bool {
            _displayingInHierarchy
        }

        private func _setDisplayingInHierarchy(_ displayingInHierarchy: Bool) {
            if _displayingInHierarchy == displayingInHierarchy {
                return
            }
            _displayingInHierarchy = displayingInHierarchy
            for obj in subitems ?? [] {
                obj._updateDisplayingInHierarchyProperty()
            }

            _notifyDelegates(with: .displayingInHierarchy)
        }

        private func _updateDisplayingInHierarchyProperty() {
            if let superItem = self.super, !superItem.displayingInHierarchy || !superItem.isExpanded {
                _setDisplayingInHierarchy(false)
            } else {
                _setDisplayingInHierarchy(true)
            }
        }

        @objc(flatItemsFromHierarchicalItems:)
        public class func flatItems(fromHierarchicalItems items: [LookinDisplayItem]?) -> [LookinDisplayItem]! {
            var resultArray: [LookinDisplayItem] = []

            for obj in items ?? [] {
                if let superItem = obj.super {
                    obj._indentLevel = superItem.indentLevel() + 1
                }
                resultArray.append(obj)
                if let subitems = obj.subitems, !subitems.isEmpty {
                    resultArray.append(contentsOf: flatItems(fromHierarchicalItems: subitems) ?? [])
                }
            }

            return resultArray
        }

        // MARK: Hidden

        @objc(isHidden)
        public var isHidden: Bool {
            get { _isHidden }
            set {
                _isHidden = newValue
                _updateInHiddenHierarchyProperty()
            }
        }

        @objc(alpha)
        public var alpha: Float {
            get { _alpha }
            set {
                _alpha = newValue
                _updateInHiddenHierarchyProperty()
            }
        }

        @objc(inHiddenHierarchy)
        public var inHiddenHierarchy: Bool {
            _inHiddenHierarchy
        }

        private func _setInHiddenHierarchy(_ inHiddenHierarchy: Bool) {
            if _inHiddenHierarchy == inHiddenHierarchy {
                return
            }
            _inHiddenHierarchy = inHiddenHierarchy
            for obj in subitems ?? [] {
                obj._updateInHiddenHierarchyProperty()
            }

            _notifyDelegates(with: .inHiddenHierarchy)
        }

        private func _updateInHiddenHierarchyProperty() {
            if self.super?.inHiddenHierarchy == true || isHidden || alpha <= 0 {
                _setInHiddenHierarchy(true)
            } else {
                _setInHiddenHierarchy(false)
            }
        }

        // MARK: Preview

        @objc(noPreview)
        public var noPreview: Bool {
            get { _noPreview }
            set {
                _noPreview = newValue
                _updateInNoPreviewHierarchy()
            }
        }

        @objc(inNoPreviewHierarchy)
        public var inNoPreviewHierarchy: Bool {
            _inNoPreviewHierarchy
        }

        private func _setInNoPreviewHierarchy(_ inNoPreviewHierarchy: Bool) {
            if _inNoPreviewHierarchy == inNoPreviewHierarchy {
                return
            }
            _inNoPreviewHierarchy = inNoPreviewHierarchy
            for obj in subitems ?? [] {
                obj._updateInNoPreviewHierarchy()
            }
            _notifyDelegates(with: .inNoPreviewHierarchy)
        }

        private func _updateInNoPreviewHierarchy() {
            if self.super?.inNoPreviewHierarchy == true || noPreview {
                _setInNoPreviewHierarchy(true)
            } else {
                _setInNoPreviewHierarchy(false)
            }
        }

        // MARK: Screenshots

        @objc(soloScreenshot)
        public var soloScreenshot: LookinImage! {
            get { _soloScreenshot }
            set {
                if _soloScreenshot === newValue {
                    return
                }
                _soloScreenshot = newValue
                _notifyDelegates(with: .soloScreenshot)
            }
        }

        @objc(groupScreenshot)
        public var groupScreenshot: LookinImage! {
            get { _groupScreenshot }
            set {
                if _groupScreenshot === newValue {
                    return
                }
                _groupScreenshot = newValue
                _notifyDelegates(with: .groupScreenshot)
            }
        }

        @objc(doNotFetchScreenshotReason)
        public var doNotFetchScreenshotReason: LookinDoNotFetchScreenshotReason {
            get { _doNotFetchScreenshotReason }
            set {
                if _doNotFetchScreenshotReason == newValue {
                    return
                }
                _doNotFetchScreenshotReason = newValue
                _notifyDelegates(with: .avoidSyncScreenshot)
            }
        }

        // MARK: Delegates

        @objc(previewItemDelegate)
        public weak var previewItemDelegate: (any LookinDisplayItemDelegate)? {
            didSet {
                guard let previewItemDelegate, previewItemDelegate.responds(to: #selector(LookinDisplayItemDelegate.displayItem(_:propertyDidChange:))) else {
                    assertionFailure()
                    previewItemDelegate = nil
                    return
                }
                previewItemDelegate.displayItem(self, propertyDidChange: .none)
            }
        }

        @objc(rowViewDelegate)
        public weak var rowViewDelegate: (any LookinDisplayItemDelegate)? {
            didSet {
                // The original returned before assigning an identical delegate.
                if oldValue === rowViewDelegate {
                    return
                }
                guard let rowViewDelegate, rowViewDelegate.responds(to: #selector(LookinDisplayItemDelegate.displayItem(_:propertyDidChange:))) else {
                    assertionFailure()
                    rowViewDelegate = nil
                    return
                }
                rowViewDelegate.displayItem(self, propertyDidChange: .none)
            }
        }

        @objc(notifySelectionChangeToDelegates)
        public func notifySelectionChangeToDelegates() {
            _notifyDelegates(with: .isSelected)
        }

        @objc(notifyHoverChangeToDelegates)
        public func notifyHoverChangeToDelegates() {
            _notifyDelegates(with: .isHovered)
        }

        private func _notifyDelegates(with property: LookinDisplayItemProperty) {
            previewItemDelegate?.displayItem(self, propertyDidChange: property)
            rowViewDelegate?.displayItem(self, propertyDidChange: property)
        }

        // MARK: Search

        @objc(isInSearch)
        public var isInSearch: Bool {
            get { _isInSearch }
            set {
                _isInSearch = newValue
                _notifyDelegates(with: .isInSearch)
            }
        }

        @objc(highlightedSearchString)
        public var highlightedSearchString: String! {
            get { _highlightedSearchString }
            set {
                _highlightedSearchString = newValue
                _notifyDelegates(with: .highlightedSearchString)
            }
        }

        // MARK: Description

        override open var description: String {
            // The original returned the raw class name, which is nil for an
            // empty class chain; "%@" prints that as "(null)".
            if let viewObject {
                return viewObject.rawClassName() ?? "(null)"
            } else if let layerObject {
                return layerObject.rawClassName() ?? "(null)"
            } else if let windowObject {
                return windowObject.rawClassName() ?? "(null)"
            } else {
                return super.description
            }
        }
    }

    /// Points every attribute of `groups` back at `item` (the original's
    /// nested enumeration in the two group-list setters).
    private func lookinAssignTargetDisplayItem(_ item: LookinDisplayItem, in groups: [LookinAttributesGroup]?) {
        for group in groups ?? [] {
            for section in group.attrSections ?? [] {
                for attr in section.attributes ?? [] {
                    attr.targetDisplayItem = item
                }
            }
        }
    }

#endif
