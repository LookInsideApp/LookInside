//
//  PreviewView.swift
//  LookInside
//
//  Created by Li Kai on 2019/8/17.
//  https://lookin.work
//
//  Much of the SceneKit code here was borrowed or copied from
//  https://github.com/TalkingData/YourView.
//  Lookin acknowledgements: https://qxh1ndiez2w.feishu.cn/docx/YIFjdE4gIolp3hxn1tGckiBxnWf
//

import AppKit
import LookInsideHostCore
import SceneKit

/// The 3D (or flat) preview of the hierarchy: one DisplayItemNode per
/// item, stacked along the z axis.
@objc(LKPreviewView)
final class PreviewView: SCNView {
    private let dataSource: HierarchyDataSource?

    private let stageNode = SCNNode()
    private let cameraNode = SCNNode()
    private let rightLightNode = SCNNode()
    private let leftLightNode = SCNNode()

    private var flatDisplayItems: [DisplayItem] = []
    private var displayItemNodes: [DisplayItemNode] = []

    /// The frameToRoot point at the 3D origin: the centre of the largest
    /// top-level window item. Recomputed on every render and handed to every
    /// node.
    private var referenceCenter: CGPoint = .zero {
        didSet {
            guard referenceCenter != oldValue else { return }
            for node in displayItemNodes {
                node.referenceCenter = referenceCenter
            }
        }
    }

    /// x turns left and right, y turns up and down (radians).
    private(set) var rotation: CGPoint = .zero

    /// How far the preview is moved.
    var translation: CGPoint = .zero {
        didSet {
            var position = stageNode.position
            position.x = translation.x
            position.y = translation.y
            stageNode.position = position
        }
    }

    /// Zoom, from LookinPreviewMinScale to LookinPreviewMaxScale.
    var scale: CGFloat = 0 {
        didSet {
            // A smaller focal length shows a smaller image.
            cameraNode.camera?.focalLength = PreviewGeometry.focalLength(forScale: scale)
        }
    }

    /// The spacing between layers, from LookinPreviewMinZInterspace to
    /// LookinPreviewMaxZInterspace.
    var zInterspace: CGFloat {
        get { storedZInterspace }
        set {
            storedZInterspace = PreviewGeometry.clampedZInterspace(newValue)
            updateZPositionByZIndex()
        }
    }

    private var storedZInterspace: CGFloat = 0

    /// 2D or 3D. Going 2D resets the rotation; going 3D keeps it.
    private(set) var dimension: PreviewDimension = .dimension2D

    /// The inspected app's screen size.
    var appScreenSize: CGSize = .zero {
        didSet {
            guard appScreenSize != oldValue else { return }

            var rightPosition = rightLightNode.position
            rightPosition.x = appScreenSize.width * 0.01 * 0.5 + 2
            rightPosition.y = appScreenSize.height * 0.01 * 0.5 + 2
            rightLightNode.position = rightPosition

            var leftPosition = leftLightNode.position
            leftPosition.x = -appScreenSize.width * 0.01 * 0.5 - 2
            leftPosition.y = -appScreenSize.height * 0.01 * 0.5 - 2
            leftLightNode.position = leftPosition

            // Until a render computes the real reference centre (from the
            // largest top-level window), use the screen centre.
            if referenceCenter == .zero {
                referenceCenter = CGPoint(x: appScreenSize.width / 2, y: appScreenSize.height / 2)
            }
        }
    }

    var preferenceManager: PreferenceManager?

    var isDarkMode = false {
        didSet {
            backgroundColor = isDarkMode
                ? NSColor(red: 19 / 255, green: 20 / 255, blue: 21 / 255, alpha: 1)
                : NSColor(red: 249 / 255, green: 249 / 255, blue: 249 / 255, alpha: 1)
            for node in displayItemNodes {
                node.isDarkMode = isDarkMode
            }
        }
    }

    var showHiddenItems = false

    init(dataSource: HierarchyDataSource?) {
        self.dataSource = dataSource
        super.init(frame: .zero, options: nil)

        allowsCameraControl = false
        showsStatistics = false

        let scene = SCNScene()
        self.scene = scene

        stageNode.name = "stage"
        scene.rootNode.addChildNode(stageNode)

        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true
        cameraNode.name = "camera"
        cameraNode.camera = camera
        // position.z sets how strong the perspective is.
        cameraNode.position = SCNVector3(0, 0, 34)
        scene.rootNode.addChildNode(cameraNode)

        let rightLight = SCNLight()
        rightLight.type = .omni
        rightLight.categoryBitMask = Int(LookinPreviewBitMask.hasLight.rawValue)
        rightLightNode.name = "right light"
        rightLightNode.light = rightLight
        scene.rootNode.addChildNode(rightLightNode)

        // The left light node has always carried the right light, so the
        // spot light made here was never used; kept as it was.
        leftLightNode.name = "left light"
        leftLightNode.light = rightLight
        scene.rootNode.addChildNode(leftLightNode)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Rendering

    /// Picks, among the top-level items and their direct children (macOS's
    /// top-level windows, and iOS / Catalyst's scene → window), the one with
    /// the largest frameToRoot and returns its centre. Falls back to the
    /// centre of the app's screen.
    private func referenceCenter(for items: [DisplayItem]) -> CGPoint {
        var largestItem: DisplayItem?
        var largestArea: CGFloat = 0
        for item in items where item.super == nil {
            for candidate in [item] + (item.subitems ?? []) {
                let frameToRoot = candidate.calculateFrameToRoot()
                let area = frameToRoot.size.width * frameToRoot.size.height
                if area > largestArea {
                    largestArea = area
                    largestItem = candidate
                }
            }
        }
        if let largestItem {
            let frameToRoot = largestItem.calculateFrameToRoot()
            return CGPoint(x: frameToRoot.midX, y: frameToRoot.midY)
        }
        return CGPoint(x: appScreenSize.width / 2, y: appScreenSize.height / 2)
    }

    /// Builds a node per item. `items` must not contain items whose
    /// `noPreview` is set. With `discardCache`, nodes this render does not
    /// use are dropped; otherwise they are only removed from the scene and
    /// kept for later renders.
    func render(displayItems items: [DisplayItem], discardCache: Bool) {
        NSLog("LKPreviewView - render %@ items", NSNumber(value: items.count))

        flatDisplayItems = items

        // Decide the reference centre before any node is made or reused;
        // setting it hands it to the existing nodes.
        referenceCenter = referenceCenter(for: items)

        for (index, item) in items.enumerated() {
            let node: DisplayItemNode
            if index < displayItemNodes.count {
                node = displayItemNodes[index]
            } else {
                node = DisplayItemNode(dataSource: dataSource)
                node.referenceCenter = referenceCenter
                node.preferenceManager = preferenceManager
                node.isDarkMode = isDarkMode
                stageNode.addChildNode(node)
                displayItemNodes.append(node)
            }
            if node.parent == nil {
                stageNode.addChildNode(node)
            }
            item.previewNode = node
            node.index = index
            node.displayItem = item
        }

        if displayItemNodes.count > items.count {
            let unused = displayItemNodes[items.count...]
            for node in unused {
                node.removeFromParentNode()
            }
            if discardCache {
                displayItemNodes.removeLast(unused.count)
            }
        }

        updateZPosition()
    }

    /// Recomputes every item's z index and moves its plane along the z axis
    /// to match; folding and other states show or hide the planes.
    func updateZPosition() {
        for item in flatDisplayItems {
            updateZIndex(for: item)
        }
        updateZPositionByZIndex()
    }

    private func updateZPositionByZIndex() {
        let interspace = PreviewGeometry.layerInterspace(is3D: dimension == .dimension3D, zInterspace: zInterspace)
        let zIndexes = displayItemNodes.map { $0.displayItem?.previewZIndex ?? 0 }
        let positions = PreviewGeometry.zPositions(zIndexes: zIndexes, interspace: interspace)

        // Without the transaction, folding and unfolding do not animate.
        SCNTransaction.begin()
        for (node, z) in zip(displayItemNodes, positions) {
            var position = node.position
            position.z = z
            node.position = position
        }
        // One commit outside the loop: many small transactions render slowly.
        SCNTransaction.commit()
    }

    private func updateZIndex(for item: DisplayItem) {
        item.previewZIndex = -1
        // A pixelless overlay node (layout guide, cell) marks out a region of
        // the node that owns it, so it belongs on that node's plane rather
        // than on one of its own. It always overlaps its super item, so the
        // rule below would push every guide a full plane forward and thicken
        // the preview for nothing. Inheriting the super item's zIndex keeps
        // them coplanar; the coplanar offset in PreviewGeometry.zPositions
        // then nudges them a hair in front, which is exactly "drawn on its
        // own view".
        //
        // flatDisplayItems runs parents before children, so the super item's
        // zIndex read here was already computed in this same pass.
        if item.shouldRenderAsCoplanarPreviewOverlay(), let superItem = item.super {
            item.previewZIndex = max(superItem.previewZIndex, 0)
            return
        }
        if item.displayingInHierarchy {
            if let referenceItem = highestOverlappedItem(below: item) {
                // Overlapping another item puts this one a level above it.
                item.previewZIndex = referenceItem.previewZIndex + 1
            } else {
                item.previewZIndex = 0
            }
        } else if let superItem = item.super {
            item.previewZIndex = superItem.previewZIndex
        } else {
            // A top-level item without a super item (a folded UIWindowScene).
            item.previewZIndex = 0
        }

        if item.previewZIndex < 0 {
            assertionFailure()
            item.previewZIndex = 0
        }
    }

    /// The item, among those visible in the preview and earlier in
    /// flatDisplayItems (lower in the hierarchy) whose frameToRoot overlaps
    /// `item`'s, with the highest z index; nil when there is none.
    private func highestOverlappedItem(below item: DisplayItem) -> DisplayItem? {
        guard let itemIndex = flatDisplayItems.firstIndex(where: { $0 == item }) else {
            assertionFailure()
            return nil
        }
        guard itemIndex > 0 else { return nil }
        let itemFrameToRoot = item.calculateFrameToRoot()
        var target: DisplayItem?
        for other in flatDisplayItems[..<itemIndex].reversed() {
            guard !other.inHiddenHierarchy || showHiddenItems else { continue }
            guard itemFrameToRoot.intersects(other.calculateFrameToRoot()) else { continue }
            if let current = target, other.previewZIndex <= current.previewZIndex {
                continue
            }
            target = other
        }
        return target
    }

    /// Moves the lights level with the selected item's plane.
    func didSelect(_ item: DisplayItem?) {
        guard let item else { return }
        let nodeZ = (item.previewNode as DisplayItemNode?)?.position.z ?? 0

        var rightPosition = rightLightNode.position
        rightPosition.z = nodeZ + 2
        rightLightNode.position = rightPosition

        var leftPosition = leftLightNode.position
        leftPosition.z = nodeZ + 2
        leftLightNode.position = leftPosition
    }

    func displayItem(at point: CGPoint) -> DisplayItem? {
        let results = hitTest(point, options: [
            .categoryBitMask: Int(LookinPreviewBitMask.selectable.rawValue),
            .searchMode: SCNHitTestSearchMode.closest.rawValue,
            .ignoreHiddenNodes: false,
        ])
        guard let result = results.first else { return nil }
        let targetNode = result.node.parent as? DisplayItemNode
        assert(targetNode != nil)
        return targetNode?.displayItem
    }

    // MARK: - Rotation and dimension

    func setRotation(_ rotation: CGPoint, animated: Bool) {
        setRotation(rotation, animated: animated, timingFunction: nil, duration: 0)
    }

    /// A zero `duration` uses the default (0.25 s).
    func setRotation(_ rotation: CGPoint, animated: Bool, timingFunction: CAMediaTimingFunction?, duration: CGFloat) {
        self.rotation = rotation
        let equivalentRotation = CGPoint(
            x: PreviewGeometry.equivalentAngle(rotation.x),
            y: PreviewGeometry.equivalentAngle(rotation.y)
        )
        let angles = SCNVector3(rotation.y, rotation.x, 0)

        if animated {
            SCNTransaction.begin()
            if duration > 0 {
                SCNTransaction.animationDuration = duration
            }
            if let timingFunction {
                SCNTransaction.animationTimingFunction = timingFunction
            }
            SCNTransaction.completionBlock = { [weak self] in
                self?.rotation = equivalentRotation
            }
            stageNode.eulerAngles = angles
            SCNTransaction.commit()
        } else {
            stageNode.eulerAngles = angles
            self.rotation = equivalentRotation
        }
    }

    func setDimension(_ dimension: PreviewDimension, animated: Bool) {
        self.dimension = dimension
        if dimension != .dimension3D {
            setRotation(.zero, animated: animated)
        }
        updateZPositionByZIndex()
    }
}
