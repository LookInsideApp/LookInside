//
//  DisplayItem.swift
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
        @objc private protocol DisplayItemColorBridge {
            @objc(lks_rgbaComponents) func rgbaComponents() -> NSArray?
            @objc(lks_colorFromRGBAComponents:) func colorFromRGBAComponents(_ components: AnyObject?) -> AnyObject?
        }

        private func rgbaComponents(of color: PlatformColor?) -> NSArray? {
            guard let color else {
                return nil
            }
            return unsafeBitCast(color, to: DisplayItemColorBridge.self).rgbaComponents()
        }

        private func platformColor(fromRGBAComponents components: Any?) -> PlatformColor? {
            let colorClass: AnyObject = UIColor.self
            return unsafeBitCast(colorClass, to: DisplayItemColorBridge.self).colorFromRGBAComponents(components as AnyObject?) as? PlatformColor
        }
    #elseif os(macOS)
        /// `-[NSColor lookin_rgbaComponents]` and `+[NSColor
        /// lookin_colorFromRGBAComponents:]` (Color+Lookin.h), sent the same way
        /// so the arrays are not bridged.
        @objc private protocol DisplayItemColorBridge {
            @objc(lookin_rgbaComponents) func sRGBAComponents() -> NSArray?
            @objc(lookin_colorFromRGBAComponents:) func sRGBColorFromRGBAComponents(_ components: AnyObject?) -> AnyObject?
        }

        private func rgbaComponents(of color: PlatformColor?) -> NSArray? {
            guard let color else {
                return nil
            }
            return unsafeBitCast(color, to: DisplayItemColorBridge.self).sRGBAComponents()
        }

        private func platformColor(fromRGBAComponents components: Any?) -> PlatformColor? {
            let colorClass: AnyObject = NSColor.self
            return unsafeBitCast(colorClass, to: DisplayItemColorBridge.self).sRGBColorFromRGBAComponents(components as AnyObject?) as? PlatformColor
        }
    #endif

    /// The screenshot decode of -initWithCoder:: PNG/TIFF data, or the image
    /// object itself.
    private func decodedScreenshot(_ screenshotObj: Any?) -> PlatformImage?? {
        guard let screenshotObj = screenshotObj as? NSObject else {
            return .none
        }
        if screenshotObj.isKind(of: NSData.self) {
            return .some(screenshotObj.decodedObject(with: .image) as? PlatformImage)
        }
        if let image = screenshotObj as? PlatformImage {
            return .some(image)
        }
        assertionFailure()
        return .none
    }

    /// Was declared in LookinDisplayItem.h; same runtime name and selector.
    @objc(LookinDisplayItemDelegate)
    public protocol DisplayItemDelegate: NSObjectProtocol {
        @objc(displayItem:propertyDidChange:)
        func displayItem(_ displayItem: DisplayItem, propertyDidChange property: LookinDisplayItemProperty)
    }

    @objc(LookinDisplayItem)
    public class DisplayItem: NSObject, NSCoding, NSSecureCoding, NSCopying {
        // MARK: Storage behind the setters with side effects

        private var _subitems: [DisplayItem]?
        private var _isHidden: Bool = false
        private var _alpha: Float = 0
        private var _frame: CGRect = .zero
        private var _bounds: CGRect = .zero
        private var _soloScreenshot: PlatformImage?
        private var _groupScreenshot: PlatformImage?
        private var _attributesGroupList: [AttributesGroup]?
        private var _customAttrGroupList: [AttributesGroup]?
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
        public var customInfo: CustomDisplayItemInfo?
        @objc(nodeKind)
        public var nodeKind: LookinDisplayItemNodeKind = .unspecified
        @objc(kindObject)
        public var kindObject: InspectedObject?
        @objc(representsSystemManagedNode)
        public var representsSystemManagedNode: Bool = false
        @objc(cellObject)
        public var cellObject: InspectedObject?
        @objc(soloScreenshotRegion)
        public var soloScreenshotRegion: CGRect = .zero
        @objc(groupScreenshotRegion)
        public var groupScreenshotRegion: CGRect = .zero
        @objc(windowObject)
        public var windowObject: InspectedObject?
        @objc(viewObject)
        public var viewObject: InspectedObject?
        @objc(layerObject)
        public var layerObject: InspectedObject?
        @objc(hostViewControllerObject)
        public var hostViewControllerObject: InspectedObject?
        @objc(hostWindowControllerObject)
        public var hostWindowControllerObject: InspectedObject?
        @objc(eventHandlers)
        public var eventHandlers: [EventHandlerDescription]?
        @objc(representedAsKeyWindow)
        public var representedAsKeyWindow: Bool = false
        @objc(backgroundColor)
        public var backgroundColor: PlatformColor?
        @objc(shouldCaptureImage)
        public var shouldCaptureImage: Bool = false
        @objc(customDisplayTitle)
        public var customDisplayTitle: String?
        @objc(danceuiSource)
        public var danceuiSource: String?
        /// `superItem` in Objective-C; `super` in Swift, the name the old
        /// header's import gave it.
        @objc(superItem) public weak var `super`: DisplayItem?
        @objc(screenshotEncodeType)
        public var screenshotEncodeType: LookinDisplayItemImageEncodeType = .none
        // `previewLayer` and `previewNode` keep their Objective-C accessors
        // (same selectors, same weak storage). Only the host app has the
        // DisplayItemNode class, so only its build types previewNode;
        // SwiftPM builds and the host's standalone test builds
        // (LOOKIN_CORE_STANDALONE) store an untyped object.
        // LookinPreviewItemLayer no longer exists anywhere.
        #if SWIFT_PACKAGE || LOOKIN_CORE_STANDALONE
            @objc private weak var previewNode: AnyObject?
        #else
            // Internal: DisplayItemNode is the host app's own class.
            @objc(previewNode)
            weak var previewNode: DisplayItemNode?
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
            let newDisplayItem = DisplayItem()
            newDisplayItem.subitems = subitems?.map { $0.copy() as! DisplayItem }
            newDisplayItem.customInfo = customInfo?.copy() as? CustomDisplayItemInfo
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
            newDisplayItem.viewObject = viewObject?.copy() as? InspectedObject
            newDisplayItem.layerObject = layerObject?.copy() as? InspectedObject
            newDisplayItem.windowObject = windowObject?.copy() as? InspectedObject
            newDisplayItem.nodeKind = nodeKind
            newDisplayItem.kindObject = kindObject?.copy() as? InspectedObject
            newDisplayItem.representsSystemManagedNode = representsSystemManagedNode
            newDisplayItem.cellObject = cellObject?.copy() as? InspectedObject
            newDisplayItem.hostViewControllerObject = hostViewControllerObject?.copy() as? InspectedObject
            newDisplayItem.hostWindowControllerObject = hostWindowControllerObject?.copy() as? InspectedObject
            newDisplayItem.attributesGroupList = attributesGroupList?.map { $0.copy() as! AttributesGroup }
            newDisplayItem.customAttrGroupList = customAttrGroupList?.map { $0.copy() as! AttributesGroup }
            newDisplayItem.eventHandlers = eventHandlers?.map { ($0 as NSObject).copy() as! EventHandlerDescription }
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
                aCoder.encode(soloScreenshot?.encodedObject(with: .image), forKey: "soloScreenshot")
                aCoder.encode(groupScreenshot?.encodedObject(with: .image), forKey: "groupScreenshot")
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
            aCoder.encode(rgbaComponents(of: backgroundColor), forKey: "backgroundColor")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            customInfo = aDecoder.decodeObject(forKey: "customInfo") as? CustomDisplayItemInfo
            subitems = aDecoder.decodeObject(forKey: "subitems") as? [DisplayItem]
            isHidden = aDecoder.decodeBool(forKey: "hidden")
            alpha = aDecoder.decodeFloat(forKey: "alpha")
            #if os(macOS)
                isFlipped = aDecoder.decodeBool(forKey: "isFlipped")
            #endif
            windowObject = aDecoder.decodeObject(forKey: "windowObject") as? InspectedObject
            viewObject = aDecoder.decodeObject(forKey: "viewObject") as? InspectedObject
            layerObject = aDecoder.decodeObject(forKey: "layerObject") as? InspectedObject
            // These fields exist since the nodeKind mechanism landed; absent keys
            // decode to Unspecified / nil / NO, which is exactly the legacy-data
            // contract resolvedNodeKind derives from.
            nodeKind = aDecoder.containsValue(forKey: "nodeKind") ? (LookinDisplayItemNodeKind(rawValue: aDecoder.decodeInteger(forKey: "nodeKind")) ?? .unspecified) : .unspecified
            kindObject = aDecoder.decodeObject(forKey: "kindObject") as? InspectedObject
            representsSystemManagedNode = aDecoder.decodeBool(forKey: "representsSystemManagedNode")
            cellObject = aDecoder.decodeObject(forKey: "cellObject") as? InspectedObject
            hostViewControllerObject = aDecoder.decodeObject(forKey: "hostViewControllerObject") as? InspectedObject
            hostWindowControllerObject = aDecoder.decodeObject(forKey: "hostWindowControllerObject") as? InspectedObject
            attributesGroupList = aDecoder.decodeObject(forKey: "attributesGroupList") as? [AttributesGroup]
            customAttrGroupList = aDecoder.decodeObject(forKey: "customAttrGroupList") as? [AttributesGroup]
            representedAsKeyWindow = aDecoder.decodeBool(forKey: "representedAsKeyWindow")

            if case let .some(decoded) = decodedScreenshot(aDecoder.decodeObject(forKey: "soloScreenshot")) {
                soloScreenshot = decoded
            }
            if case let .some(decoded) = decodedScreenshot(aDecoder.decodeObject(forKey: "groupScreenshot")) {
                groupScreenshot = decoded
            }

            eventHandlers = aDecoder.decodeObject(forKey: "eventHandlers") as? [EventHandlerDescription]
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
            backgroundColor = platformColor(fromRGBAComponents: aDecoder.decodeObject(forKey: "backgroundColor"))
            _updateDisplayingInHierarchyProperty()
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        // MARK: Node kind

        @objc(displayingObject)
        public func displayingObject() -> InspectedObject? {
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
                let representsWindowScene = (windowObject.classChainList ?? []).contains { stringsEqual($0, "UIWindowScene") }
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
        public var attributesGroupList: [AttributesGroup]? {
            get { _attributesGroupList }
            set {
                _attributesGroupList = newValue
                assignTargetDisplayItem(self, in: newValue)
            }
        }

        @objc(customAttrGroupList)
        public var customAttrGroupList: [AttributesGroup]? {
            get { _customAttrGroupList }
            set {
                _customAttrGroupList = newValue
                // Already sorted when it is passed in.
                assignTargetDisplayItem(self, in: newValue)
            }
        }

        @objc(queryAllAttrGroupList)
        public func queryAllAttrGroupList() -> [AttributesGroup] {
            var array: [AttributesGroup] = []
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
        public var subitems: [DisplayItem]? {
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
        public class func flatItems(fromHierarchicalItems items: [DisplayItem]?) -> [DisplayItem] {
            var resultArray: [DisplayItem] = []

            for obj in items ?? [] {
                if let superItem = obj.super {
                    obj._indentLevel = superItem.indentLevel() + 1
                }
                resultArray.append(obj)
                if let subitems = obj.subitems, !subitems.isEmpty {
                    resultArray.append(contentsOf: flatItems(fromHierarchicalItems: subitems))
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
        public var soloScreenshot: PlatformImage? {
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
        public var groupScreenshot: PlatformImage? {
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
        public weak var previewItemDelegate: (any DisplayItemDelegate)? {
            didSet {
                guard let previewItemDelegate, previewItemDelegate.responds(to: #selector(DisplayItemDelegate.displayItem(_:propertyDidChange:))) else {
                    assertionFailure()
                    previewItemDelegate = nil
                    return
                }
                previewItemDelegate.displayItem(self, propertyDidChange: .none)
            }
        }

        @objc(rowViewDelegate)
        public weak var rowViewDelegate: (any DisplayItemDelegate)? {
            didSet {
                // The original returned before assigning an identical delegate.
                if oldValue === rowViewDelegate {
                    return
                }
                guard let rowViewDelegate, rowViewDelegate.responds(to: #selector(DisplayItemDelegate.displayItem(_:propertyDidChange:))) else {
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
        public var highlightedSearchString: String? {
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
    private func assignTargetDisplayItem(_ item: DisplayItem, in groups: [AttributesGroup]?) {
        for group in groups ?? [] {
            for section in group.attrSections ?? [] {
                for attr in section.attributes ?? [] {
                    attr.targetDisplayItem = item
                }
            }
        }
    }

#endif
