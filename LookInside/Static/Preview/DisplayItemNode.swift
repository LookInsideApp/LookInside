//
//  DisplayItemNode.swift
//  LookInside
//
//  Created by Li Kai on 2019/8/17.
//  https://lookin.work
//

import AppKit
import SceneKit

/// One item's plane in the 3D preview: the screenshot (or background
/// colour), a tint mask for hover and selection, and an outline.
final class DisplayItemNode: SCNNode, DisplayItemDelegate {
    /// Rendering order added to a coplanar overlay node's border so it draws
    /// after every ordinary node. Paired with a depth-test-free material,
    /// this puts the highlight box on top of whatever the owning view has
    /// stacked over the region — a guide sitting under an opaque subview
    /// still shows its box. Comfortably above index * 10 + 2 for any
    /// hierarchy a person can open.
    private static let overlayBorderRenderingOrderBase = 1_000_000

    /// Scene units per point.
    private static let factor: CGFloat = 0.01

    private let dataSource: HierarchyDataSource?
    private let isMacTarget: Bool

    private let contentPlane = SCNPlane()
    private let contentNode: SCNNode
    /// Shows the screenshot when it covers only a region of the node (see
    /// DisplayItem.groupScreenshotRegion). The content plane stays the
    /// size of the whole node underneath it — it is the plane hit-testing
    /// selects by — and shows the background colour, or nothing.
    private let regionPlane = SCNPlane()
    private let regionNode: SCNNode
    private let maskPlane = SCNPlane()
    /// Added as a child only once it is first needed.
    private let maskNode: SCNNode
    private let borderNode = SCNNode()
    private var borderGeometry: SCNGeometry?
    private var borderColor: NSColor? {
        didSet { renderBorderColor() }
    }

    /// The node's index among all display items.
    var index = 0 {
        didSet { updateRenderingOrder() }
    }

    /// The point of frameToRoot space at the origin of the 3D scene. Set by
    /// PreviewView on every render from the largest top-level window item,
    /// so that window's centre stays at (0, 0) and smaller windows sit
    /// around it.
    var referenceCenter: CGPoint = .zero {
        didSet {
            guard referenceCenter != oldValue, let displayItem else { return }
            render(displayItem, changedProperty: .frameToRoot)
        }
    }

    weak var preferenceManager: PreferenceManager? {
        didSet {
            preferenceManager?.showHiddenItems.subscribe(self, action: #selector(renderVisibility), relatedObject: nil)
            preferenceManager?.showOutline.subscribe(self, action: #selector(renderImageAndColor), relatedObject: nil)
            preferenceManager?.isQuickSelecting.subscribe(self, action: #selector(renderVisibility), relatedObject: nil)
        }
    }

    var displayItem: DisplayItem? {
        didSet {
            // Never set the contents to nil: some scenes then render the
            // wrong content.
            contentPlane.firstMaterial?.diffuse.contents = displayItem?.backgroundColor ?? NSColor.clear
            // Nodes are recycled across renders, so the rendering order has
            // to be recomputed whenever the item changes and not only when
            // the index does.
            updateRenderingOrder()
            // Calls displayItem(_:propertyDidChange:) at once with .none.
            displayItem?.previewItemDelegate = self
        }
    }

    var isDarkMode = false {
        didSet { renderImageAndColor() }
    }

    init(dataSource: HierarchyDataSource?) {
        self.dataSource = dataSource
        isMacTarget = AppHelper.appInfoLooksLikeMacTarget(dataSource?.rawHierarchyInfo?.appInfo)

        contentPlane.firstMaterial?.isDoubleSided = true
        contentPlane.firstMaterial?.lightingModel = .constant
        contentPlane.firstMaterial?.diffuse.contents = NSColor.clear
        contentNode = SCNNode(geometry: contentPlane)
        contentNode.position = SCNVector3(0, 0, 0)
        contentNode.name = "screenshot"
        contentNode.categoryBitMask = Int(LookinPreviewBitMask.noLight.rawValue)

        regionPlane.firstMaterial?.isDoubleSided = true
        regionPlane.firstMaterial?.lightingModel = .constant
        regionNode = SCNNode(geometry: regionPlane)
        regionNode.name = "screenshot-region"
        // Just above the content plane, which shows the background colour
        // beneath a partial screenshot.
        regionNode.position = SCNVector3(0, 0, 0.0005)
        regionNode.categoryBitMask = Int(LookinPreviewBitMask.noLight.rawValue)
        regionNode.isHidden = true

        maskPlane.firstMaterial?.isDoubleSided = true
        maskNode = SCNNode(geometry: maskPlane)
        maskNode.name = "mask"
        maskNode.position = SCNVector3(0, 0, 0.001)
        maskNode.categoryBitMask = Int(LookinPreviewBitMask.hasLight.rawValue)

        borderNode.name = "border"
        borderNode.position = SCNVector3(0, 0, 0.002)
        borderNode.categoryBitMask = Int(LookinPreviewBitMask.noLight.rawValue)

        super.init()

        addChildNode(contentNode)
        addChildNode(regionNode)
        addChildNode(borderNode)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Rendering

    private func updateRenderingOrder() {
        contentNode.renderingOrder = index * 10
        maskNode.renderingOrder = index * 10 + 1
        if displayItem?.shouldRenderAsCoplanarPreviewOverlay() == true {
            borderNode.renderingOrder = Self.overlayBorderRenderingOrderBase + index * 10 + 2
        } else {
            borderNode.renderingOrder = index * 10 + 2
        }
    }

    private func renderBorderColor() {
        borderGeometry?.firstMaterial?.diffuse.contents = borderColor
    }

    private func makeBorderGeometry(around planeNode: SCNNode) -> SCNGeometry {
        let (min, max) = planeNode.boundingBox
        let width = max.x - min.x
        let height = max.y - min.y
        let vertices = [
            max,
            SCNVector3(max.x, max.y - height, max.z),
            SCNVector3(max.x - width, max.y - height, max.z),
            SCNVector3(max.x - width, max.y, max.z),
        ]
        let indexes: [UInt8] = [0, 1, 1, 2, 2, 3, 3, 0]
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(
            data: Data(indexes),
            primitiveType: .line,
            primitiveCount: 4,
            bytesPerIndex: MemoryLayout<UInt8>.size
        )
        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        geometry.firstMaterial?.isDoubleSided = true
        geometry.firstMaterial?.lightingModel = .constant
        if displayItem?.shouldRenderAsCoplanarPreviewOverlay() == true {
            // The box marks out a region of the owning view, so it has to
            // stay readable even when that region is covered by opaque
            // subviews. Those sit in front of it on the z axis, so the depth
            // test would otherwise discard it.
            geometry.firstMaterial?.readsFromDepthBuffer = false
            geometry.firstMaterial?.writesToDepthBuffer = false
        }
        return geometry
    }

    @objc private func renderVisibility() {
        let displayingInHierarchy = displayItem?.displayingInHierarchy ?? false
        let inHiddenHierarchy = displayItem?.inHiddenHierarchy ?? false
        let showEvenWhenCollapsed = (preferenceManager?.isQuickSelecting.currentBOOLValue ?? false)
            && !(displayItem?.super?.preferToBeCollapsed ?? false)
        let showHiddenItems = preferenceManager?.showHiddenItems.currentBOOLValue ?? false

        var canSelect: Bool
        if inHiddenHierarchy, !showHiddenItems {
            contentNode.opacity = 0
            borderNode.opacity = 0
            maskNode.isHidden = true
            canSelect = false
        } else if displayingInHierarchy {
            contentNode.opacity = 1
            borderNode.opacity = 1
            maskNode.isHidden = false
            canSelect = true
        } else {
            contentNode.opacity = 0
            maskNode.isHidden = true
            if showEvenWhenCollapsed {
                borderNode.opacity = 1
                canSelect = true
            } else {
                borderNode.opacity = 0
                canSelect = false
            }
        }

        if displayItem?.shouldRenderAsCoplanarPreviewOverlay() == true {
            // Never hit-testable. A safe-area guide covers its whole view,
            // and it sits right on that view's plane, so leaving it
            // selectable would mean every click landing on the view selects
            // the guide instead. Such a node is selected from the hierarchy
            // tree, the way Xcode does it.
            canSelect = false
        }

        let selectability: LookinPreviewBitMask = canSelect ? .selectable : .unselectable
        contentNode.categoryBitMask = Int(selectability.union(.noLight).rawValue)
    }

    /// The region `screenshot` covers, or nil when it covers the whole node
    /// — which is also the answer for an image that is neither of the node's
    /// two screenshots, or a region that equals the bounds anyway.
    private func region(of screenshot: NSImage?) -> CGRect? {
        guard let screenshot, let displayItem else { return nil }
        var region = CGRect.zero
        if screenshot === displayItem.soloScreenshot {
            region = displayItem.soloScreenshotRegion
        } else if screenshot === displayItem.groupScreenshot {
            region = displayItem.groupScreenshotRegion
        }
        if region.isEmpty || !LookinIsUsableRect(displayItem.bounds) || region.equalTo(displayItem.bounds) {
            return nil
        }
        return region
    }

    /// Places the region plane over `region`, a rect in the node's bounds
    /// space. It maps to root space the way a subview's frame does (see
    /// -[LookinDisplayItem calculateFrameToRoot]): offset from the bounds
    /// origin, measured from the bottom when the node is flipped, and the
    /// y axis negated for iOS targets as the node's own position is.
    private func layoutRegionNode(region: CGRect, frameToRoot: CGRect) {
        guard let displayItem else { return }
        let bounds = displayItem.bounds
        let x = region.origin.x - bounds.origin.x
        let y: CGFloat
        if displayItem.isFlipped {
            y = bounds.size.height - region.origin.y - region.size.height
        } else {
            y = region.origin.y - bounds.origin.y
        }
        let offsetX = (x + region.size.width / 2) - frameToRoot.size.width / 2
        let offsetY = (y + region.size.height / 2) - frameToRoot.size.height / 2
        regionPlane.width = region.size.width * Self.factor
        regionPlane.height = region.size.height * Self.factor
        var position = regionNode.position
        position.x = offsetX * Self.factor
        position.y = (isMacTarget ? offsetY : -offsetY) * Self.factor
        regionNode.position = position
    }

    @objc private func renderImageAndColor() {
        // Like the Objective-C pointer comparison, nil equals nil.
        let isSelected = dataSource?.selectedItem === displayItem
        let isHovered = dataSource?.hoveredItem === displayItem

        let screenshot = displayItem?.optionalAppropriateScreenshot
        if let rep = screenshot?.representations.first {
            assert(CGFloat(Swift.max(rep.pixelsWide, rep.pixelsHigh)) <= CGFloat(LookinNodeImageMaxLengthInPx), "image is too large")
        }
        let backgroundColor = displayItem?.backgroundColor ?? NSColor.clear
        if let screenshot, let region = region(of: screenshot) {
            // A partial screenshot: the node's own plane shows what the image
            // does not cover, the region plane shows the image where it
            // belongs.
            contentPlane.firstMaterial?.diffuse.contents = backgroundColor
            regionPlane.firstMaterial?.diffuse.contents = screenshot
            regionNode.isHidden = false
            layoutRegionNode(region: region, frameToRoot: displayItem?.calculateFrameToRoot() ?? .zero)
        } else {
            contentPlane.firstMaterial?.diffuse.contents = screenshot ?? backgroundColor
            regionNode.isHidden = true
        }

        let tooLargeToFetchScreenshot = screenshot == nil
            && displayItem?.doNotFetchScreenshotReason == .doNotFetchScreenshotForTooLarge

        if displayItem?.shouldRenderAsCoplanarPreviewOverlay() == true {
            // Draw the box only while the node is the one being looked at.
            // These nodes are coplanar with the view that owns them and there
            // is one on almost every view (safe area, layout margins), so
            // outlining them all the time would bury the preview under
            // duplicated rectangles. No mask either: the point is to outline
            // the region, not to tint it.
            borderColor = (isSelected || isHovered) ? Self.color(100, 146, 199) : NSColor.clear
            maskNode.opacity = 0
            return
        }

        if isSelected || isHovered {
            borderColor = tooLargeToFetchScreenshot ? Self.color(255, 38, 0, 0.8) : Self.color(100, 146, 199)
        } else if preferenceManager?.showOutline.currentBOOLValue == true {
            if tooLargeToFetchScreenshot {
                borderColor = isDarkMode ? Self.color(255, 38, 0, 0.5) : Self.color(255, 38, 0, 0.6)
            } else {
                borderColor = isDarkMode ? Self.color(160, 168, 189, 0.6) : Self.color(120, 122, 124, 0.6)
            }
        } else {
            borderColor = NSColor.clear
        }

        let maskColor: NSColor
        let maskOpacity: CGFloat
        if tooLargeToFetchScreenshot {
            maskColor = Self.color(255, 38, 0)
            if isSelected {
                maskOpacity = 0.45
            } else if isHovered {
                maskOpacity = 0.3
            } else {
                maskOpacity = isDarkMode ? 0.17 : 0.2
            }
        } else {
            maskColor = Self.color(110, 183, 255)
            var level = PreferenceManager.shared.imageContrastLevel
            if level < 0 || level > 2 {
                assertionFailure()
                level = 0
            }
            if isSelected {
                maskOpacity = [0.35, 0.6, 0.85][level]
            } else if isHovered {
                maskOpacity = [0.18, 0.38, 0.6][level]
            } else {
                maskOpacity = 0
            }
        }
        if maskOpacity > 0, maskNode.parent == nil {
            insertChildNode(maskNode, at: 1)
        }
        maskNode.opacity = maskOpacity
        maskPlane.firstMaterial?.diffuse.contents = maskColor
    }

    /// `LookinColorRGBAMake`.
    private static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
        NSColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }

    // MARK: - DisplayItemDelegate

    func displayItem(_ displayItem: DisplayItem, propertyDidChange property: LookinDisplayItemProperty) {
        render(displayItem, changedProperty: property)
    }

    private func render(_ displayItem: DisplayItem, changedProperty property: LookinDisplayItemProperty) {
        if property == .none || property == .frameToRoot {
            let frameToRoot = displayItem.calculateFrameToRoot()
            let width = frameToRoot.size.width
            let height = frameToRoot.size.height
            let xOffset = -referenceCenter.x
            let yOffset = referenceCenter.y

            let transformedX = frameToRoot.origin.x + width / 2 + xOffset
            let transformedY: CGFloat
            if isMacTarget {
                transformedY = frameToRoot.origin.y + height / 2 - yOffset
            } else {
                transformedY = -(frameToRoot.origin.y + height / 2) + yOffset
            }

            contentPlane.width = width * Self.factor
            contentPlane.height = height * Self.factor
            maskPlane.width = contentPlane.width
            maskPlane.height = contentPlane.height
            if !regionNode.isHidden {
                let region = region(of: self.displayItem?.optionalAppropriateScreenshot) ?? .zero
                layoutRegionNode(region: region, frameToRoot: frameToRoot)
            }

            var position = self.position
            position.x = transformedX * Self.factor
            position.y = transformedY * Self.factor
            self.position = position

            borderGeometry = makeBorderGeometry(around: contentNode)
            borderNode.geometry = borderGeometry
            renderBorderColor()
        }

        switch property {
        case .none, .isExpandable, .isExpanded, .soloScreenshot, .groupScreenshot, .isSelected, .isHovered, .avoidSyncScreenshot:
            renderImageAndColor()
        default:
            break
        }

        switch property {
        case .none, .displayingInHierarchy, .inHiddenHierarchy:
            renderVisibility()
        default:
            break
        }
    }
}

extension DisplayItem {
    /// `-appropriateScreenshot`, which returns nil for an item without a
    /// screenshot although its header (inside NS_ASSUME_NONNULL) says it
    /// never does; read through the runtime so Swift sees the nil.
    var optionalAppropriateScreenshot: NSImage? {
        value(forKey: "appropriateScreenshot") as? NSImage
    }
}
