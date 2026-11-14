//
//  StaticHierarchyDataSource.swift
//  LookInside
//
//  Created by Li Kai on 2018/12/21.
//  https://lookin.work
//

import AppKit

/// The data source of a live document: applies the details the update
/// tasks deliver and starts those tasks.
class StaticHierarchyDataSource: HierarchyDataSource {
    var appInfo: InspectedAppInfo? {
        storedAppInfo
    }

    /// The update manager of the owning window controller.
    weak var asyncUpdateManager: StaticAsyncUpdateManager?

    /// Sends each item whose frame changed. Also reaches `events()` as
    /// `.itemDidChangeFrame`.
    final let itemsDidChangeFrame = SyncSignal<DisplayItem>()
    /// The preview's front-to-back order changed while the tree did not: a
    /// window's layer archive told which nodes portals draw elsewhere
    /// (`DisplayItem.previewPortalItem`).
    final let previewOrderDidChange = SyncSignal<Void>()

    private var storedAppInfo: InspectedAppInfo?
    /// Keeps a detail's subitems rebuild from starting a detail update
    /// while the update task that delivered it is still running: update
    /// tasks must not overlap.
    private var shouldIgnoreAutomaticDetailUpdate = false
    private var isUsingDanceUI = false
    private var frameSubscription: SyncSubscription?

    private let livePreferenceManager: PreferenceManager

    /// A live session's tree, following `preferenceManager` — the app's
    /// settings, or a set of its own in tests, which must not change them.
    init(preferenceManager: PreferenceManager) {
        livePreferenceManager = preferenceManager
        super.init()
        let broadcaster = eventBroadcaster
        frameSubscription = itemsDidChangeFrame.observe { [weak broadcaster] item in
            broadcaster?.yield(.itemDidChangeFrame(item))
        }
    }

    // MARK: - Reload

    override func reload(with info: HierarchyInfo?, keepState: Bool) {
        super.reload(with: info, keepState: keepState)

        storedAppInfo = info?.appInfo

        assert(info == nil || (info?.appInfo?.screenScale ?? 0) > 0)
        for item in flatItems ?? [] {
            markingImageLimits(of: item)
        }

        updateMessageStatus()
        // The details follow from buildDisplayingFlatItems(), which the reload
        // ran: the displayed items first, then the prefetch.
    }

    func modify(with detail: DisplayItemDetail?) {
        guard let detail else {
            return
        }
        guard let item = displayItem(withOid: UInt(detail.displayItemOid)) else {
            assertionFailure("no display item for a detail")
            return
        }
        if let title = detail.customDisplayTitle {
            item.customDisplayTitle = title
        }
        if let source = detail.danceUISource {
            item.danceuiSource = source
            isUsingDanceUI = true
        }
        if let screenshot = detail.groupScreenshot {
            item.groupScreenshot = screenshot
        }
        if let screenshot = detail.soloScreenshot {
            item.soloScreenshot = screenshot
        }

        if detail.frameValue != nil || detail.boundsValue != nil {
            modify(item, frame: detail.frameValue?.rectValue ?? .zero, bounds: detail.boundsValue?.rectValue ?? .zero)
        }

        var didChangeHiddenAlpha = false
        if let hidden = detail.hiddenValue, hidden.boolValue != item.isHidden {
            item.isHidden = hidden.boolValue
            didChangeHiddenAlpha = true
        }
        if let alpha = detail.alphaValue, alpha.floatValue != item.alpha {
            item.alpha = alpha.floatValue
            didChangeHiddenAlpha = true
        }
        if didChangeHiddenAlpha {
            itemDidChangeHiddenAlphaValue.send(item)
        }

        var didChangeAttributes = false
        if let groups = detail.attributesGroupList, !groups.isEmpty {
            item.attributesGroupList = groups
            didChangeAttributes = true
        }
        if let groups = detail.customAttrGroupList, !groups.isEmpty {
            item.customAttrGroupList = groups
            didChangeAttributes = true
        }
        if didChangeAttributes {
            itemDidChangeAttrGroup.send(item)
        }

        if let subitems = detail.subitems, !(item.subitems ?? []).isEmpty || !subitems.isEmpty {
            replaceSubitems(of: item, with: subitems)
        }
    }

    private func replaceSubitems(of item: DisplayItem, with subitems: [DisplayItem]) {
        // Without this flag the buildDisplayingFlatItems below would start a
        // detail update task while the current one is still running (it
        // is still in its subscription, not yet completed), and update tasks
        // must not run concurrently.
        shouldIgnoreAutomaticDetailUpdate = true

        // Leave search or focus first; keeping their state across the
        // rebuild is not worth it.
        switch state {
        case .focus:
            endFocus()
        case .search:
            endSearch()
        default:
            break
        }

        item.subitems = subitems
        // Flatten the tree again; this also sets every item's indentLevel.
        rawFlatItems = DisplayItem.flatItems(fromHierarchicalItems: rawHierarchyInfo?.displayItems ?? [])
        flatItems = rawFlatItems
        // Before the reload signal, which the preview renders on.
        let glassLayerVisibility = preferenceManager().glassLayerVisibility
        item.enumerateSelfAndChildren { node in
            if node !== item, node.isGlassLayer(),
               glassLayerVisibility.hidesGlassLayer(
                   isDrawnByLookInside: glassLayerIsDrawnByLookInside(node),
                   isSplitViewBackground: node.isSplitViewBackgroundGlass()
               )
            {
                // A capture of Liquid Glass is only its white shape source;
                // glass LookInside draws goes where it covers a split view
                // item's content.
                node.noPreview = true
            }
        }
        didReloadHierarchyInfo.send()

        item.enumerateSelfAndChildren { node in
            guard node !== item else {
                return
            }
            if !node.isUserCustom(), !node.shouldCaptureImage {
                node.enumerateSelfAndChildren { descendant in
                    descendant.noPreview = true
                    descendant.doNotFetchScreenshotReason = .doNotFetchScreenshotForUserConfig
                }
            }
            // The image limits a reload marks, applied after the app's own
            // opt-out as a reload applies them.
            self.markingImageLimits(of: node)
            if let source = node.customInfo?.danceuiSource, !source.isEmpty {
                DanceUIAttributeMaker.makeDanceUIJumpAttribute(node, danceSource: source)
            }
        }
        buildDisplayingFlatItems()
        shouldIgnoreAutomaticDetailUpdate = false
    }

    override func buildDisplayingFlatItems() {
        super.buildDisplayingFlatItems()
        if !shouldIgnoreAutomaticDetailUpdate {
            MainActor.assumeIsolated {
                asyncUpdateManager?.updateForDisplayingItems()
            }
        }
    }

    override convenience init() {
        self.init(preferenceManager: .shared)
    }

    override func preferenceManager() -> PreferenceManager {
        livePreferenceManager
    }

    override func isReadOnly() -> Bool {
        false
    }

    // MARK: - Private

    private func modify(_ item: DisplayItem, frame: CGRect, bounds: CGRect) {
        if item.frame.equalTo(frame), item.bounds.equalTo(bounds) {
            return
        }
        item.frame = frame
        item.bounds = bounds
        refreshingTooLargeMark(of: item)
        itemsDidChangeFrame.send(item)
    }

    /// An image the preview takes is at most `LookinNodeImageMaxLengthInPx`
    /// on each side, an SCNNode's limit; keep 100 px clear of that. Pixels,
    /// not points.
    private static let maximumImageLengthInPixels = CGFloat(LookinNodeImageMaxLengthInPx) - 100

    /// Whether `item`'s frame is too large for an image of it.
    private func isTooLargeForImages(_ item: DisplayItem) -> Bool {
        let screenScale = max(CGFloat(storedAppInfo?.screenScale ?? 0), 1)
        return max(item.frame.width, item.frame.height) * screenScale > Self.maximumImageLengthInPixels
    }

    /// Marks `item` when the preview takes no image of it, for every node a
    /// reload or a detail brings. Guides, cells and a view's outer layer
    /// have no pixels of their own: a screenshot would draw the owning
    /// view's content a second time. No screenshot task, but they stay in
    /// the preview. A node too large for an image gets none either.
    private func markingImageLimits(of item: DisplayItem) {
        if !item.isPixelBearing() {
            item.doNotFetchScreenshotReason = .doNotFetchScreenshotForNoPixels
        } else if isTooLargeForImages(item) {
            item.doNotFetchScreenshotReason = .doNotFetchScreenshotForTooLarge
        }
    }

    /// A detail changed `item`'s frame. Grown too large for an image, it is
    /// marked as a reload would have marked it and lets go of its images:
    /// they show it at its old size. Fitting again, it gets images again.
    private func refreshingTooLargeMark(of item: DisplayItem) {
        switch item.doNotFetchScreenshotReason {
        case .fetchScreenshotPermitted where isTooLargeForImages(item):
            item.doNotFetchScreenshotReason = .doNotFetchScreenshotForTooLarge
            item.groupScreenshot = nil
            item.soloScreenshot = nil
        case .doNotFetchScreenshotForTooLarge where !isTooLargeForImages(item):
            item.doNotFetchScreenshotReason = .fetchScreenshotPermitted
        default:
            break
        }
    }

    private func updateMessageStatus() {
        if serverSideIsSwiftProject, appInfo?.swiftEnabledInLookinServer == -1 {
            MessageManager.sharedInstance().addMessage(swiftSubspecMessageIdentifier)
        } else {
            MessageManager.sharedInstance().removeMessage(swiftSubspecMessageIdentifier)
        }
    }
}
