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
@objc(LKStaticHierarchyDataSource)
class StaticHierarchyDataSource: HierarchyDataSource {
    @objc var appInfo: InspectedAppInfo! {
        storedAppInfo
    }

    /// The update manager of the owning window controller.
    @objc weak var asyncUpdateManager: StaticAsyncUpdateManager?

    /// Sends each item whose frame changed. Also reaches `events()` as
    /// `.itemDidChangeFrame`.
    final let itemsDidChangeFrame = SyncSignal<DisplayItem>()

    /// Keeps a detail's subitems rebuild from starting a fast-mode update
    /// while the update task that delivered it is still running: update
    /// tasks must not overlap.
    private var storedAppInfo: InspectedAppInfo?
    private var shouldIgnoreFastModeAutoUpdate = false
    private var isUsingDanceUI = false
    private var frameSubscription: SyncSubscription?

    override init() {
        super.init()
        let broadcaster = eventBroadcaster
        frameSubscription = itemsDidChangeFrame.observe { [weak broadcaster] item in
            broadcaster?.yield(.itemDidChangeFrame(item))
        }
    }

    // MARK: - Reload

    @objc(reloadWithHierarchyInfo:keepState:)
    override func reload(with info: HierarchyInfo!, keepState: Bool) {
        super.reload(with: info, keepState: keepState)

        storedAppInfo = info.appInfo

        assert((info.appInfo?.screenScale ?? 0) > 0)
        let screenScale = max(CGFloat(info.appInfo?.screenScale ?? 0), 1)

        // An SCNNode image is at most 16384 px on each side; keep 100 px
        // clear of that. Pixels, not points.
        let maxLengthInPx = CGFloat(LookinNodeImageMaxLengthInPx) - 100
        for item in flatItems ?? [] {
            guard item.isPixelBearing() else {
                // Guides, cells and a view's outer layer have no pixels of
                // their own: a screenshot would draw the owning view's
                // content a second time. No screenshot task, but they stay
                // in the preview.
                item.doNotFetchScreenshotReason = .doNotFetchScreenshotForNoPixels
                continue
            }
            if item.frame.width * screenScale > maxLengthInPx || item.frame.height * screenScale > maxLengthInPx {
                item.doNotFetchScreenshotReason = .doNotFetchScreenshotForTooLarge
            }
        }

        updateMessageStatus()

        if !PreferenceManager.shared.fastMode.currentBOOLValue {
            MainActor.assumeIsolated {
                asyncUpdateManager?.updateAll()
            }
        }
    }

    @objc(modifyWithDisplayItemDetail:)
    func modify(with detail: DisplayItemDetail!) {
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
        // fast-mode update task while the current one is still running (it
        // is still in its subscription, not yet completed), and update tasks
        // must not run concurrently.
        shouldIgnoreFastModeAutoUpdate = true

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
            if let source = node.customInfo?.danceuiSource, !source.isEmpty {
                DanceUIAttributeMaker.makeDanceUIJumpAttribute(node, danceSource: source)
            }
        }
        buildDisplayingFlatItems()
        shouldIgnoreFastModeAutoUpdate = false
    }

    override func buildDisplayingFlatItems() {
        super.buildDisplayingFlatItems()
        if PreferenceManager.shared.fastMode.currentBOOLValue, !shouldIgnoreFastModeAutoUpdate {
            MainActor.assumeIsolated {
                asyncUpdateManager?.updateForDisplayingItems()
            }
        }
    }

    override func preferenceManager() -> PreferenceManager! {
        PreferenceManager.shared
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
        itemsDidChangeFrame.send(item)
    }

    private func updateMessageStatus() {
        if serverSideIsSwiftProject, appInfo?.swiftEnabledInLookinServer == -1 {
            MessageManager.sharedInstance().addMessage(swiftSubspecMessageIdentifier)
        } else {
            MessageManager.sharedInstance().removeMessage(swiftSubspecMessageIdentifier)
        }
    }
}
