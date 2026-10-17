//
//  StaticAsyncUpdateManager.swift
//  LookInside
//
//  Created by Li Kai on 2019/2/19.
//  https://lookin.work
//

import AppKit
import LookInsideHostCore
import FoundationToolbox

protocol StaticAsyncUpdateManagerDelegate: AnyObject {
    /// Called whenever the number of unfinished tasks the user is waiting
    /// for changes: `totalCount` tasks in all, `finishedCount` of them done.
    /// A prefetch is not reported.
    func detailUpdateTasksTotalCount(_ totalCount: UInt, finishedCount: UInt)

    func detailUpdateReceivedError(_ error: Error)
}

/// Progress of `updateAfterModifyingDisplayItem(_:)`.
enum ModifyingUpdateEvent {
    /// `received` of `total` screenshots arrived.
    case progress(received: Int, total: Int)
    case failure(Error)
}

/// Fetches the details (screenshots, attributes, sub items) of the items in
/// one inspector window's hierarchy from the inspected app.
///
/// The displayed items come first: what each one misses of the screenshot
/// the preview shows for it and of its attributes, in a request whose
/// progress the window shows. Then, unless fast mode is on, a prefetch asks
/// for what expanding the folded items would show, breadth first, without
/// attributes; it steps aside — cancelled, resumed later from what is still
/// missing — whenever the displayed items need something, a reload starts or
/// another request is needed. `DetailFetchPlanning` decides what each
/// request holds.
/// Only one detail request can be in flight on a channel: a newer one makes
/// the connection discard the older.
@Loggable(subsystem: "com.lookinside.app")
@Signpostable(subsystem: "com.lookinside.app", category: "RefreshPerformance")
@MainActor
final class StaticAsyncUpdateManager: NSObject {
    /// Set by the owner (window controller / live document), which holds it
    /// strongly.
    weak var hierarchyDataSource: StaticHierarchyDataSource?

    /// The app every request goes to. The owner refreshes it when a new
    /// hierarchy arrives or the document reconnects.
    weak var inspectableApp: InspectableApp?

    weak var delegate: StaticAsyncUpdateManagerDelegate?

    /// Events of `updateAfterModifyingDisplayItem(_:)`.
    let modifyingUpdates = AsyncBroadcaster<ModifyingUpdateEvent>()

    /// Tasks of requests that received every reply since the last reload, so
    /// a task answered without an image (a leaf has no solo screenshot) is
    /// not asked again each time the displayed items change.
    private var answeredTaskKeys = Set<DetailTaskKey>()
    /// The request sent and not yet ended.
    private var ongoingRequest: DetailUpdateRequest?
    /// An `updateForDisplayingItems()` is waiting for the next main-queue turn.
    private var hasScheduledDisplayingUpdate = false

    /// A prefetch package is answered in one main-queue turn of the
    /// inspected app, and a cancellation only takes effect between packages,
    /// so prefetch packages are small.
    private static let prefetchPackageMaximumArea: Double = 500_000
    private static let prefetchPackageMaximumTaskCount = 20

    private let dataSourceSignals = SyncSubscriptionBag()

    init(hierarchyDataSource: StaticHierarchyDataSource?, inspectableApp: InspectableApp?) {
        self.hierarchyDataSource = hierarchyDataSource
        self.inspectableApp = inspectableApp
        super.init()
        dataSourceSignals.observe(hierarchyDataSource?.willReloadHierarchyInfo) { [weak self] in
            guard let self else { return }
            // A prefetch of the tree being replaced has nothing left to do.
            stopPrefetching()
            answeredTaskKeys.removeAll()
        }
        PreferenceManager.shared.fastMode.subscribe(self, action: #selector(handleFastModeChange(_:)), relatedObject: nil)
    }

    override convenience init() {
        self.init(hierarchyDataSource: nil, inspectableApp: nil)
    }

    private var dataSource: StaticHierarchyDataSource? {
        hierarchyDataSource
    }

    // MARK: - Public

    /// Fetches what the displayed items miss, then prefetches the rest unless
    /// fast mode is on. Call it whenever the displayed items change; calls
    /// made before the next main-queue turn run once, after the reload or
    /// expansion that made them is complete.
    func updateForDisplayingItems() {
        guard !hasScheduledDisplayingUpdate else { return }
        hasScheduledDisplayingUpdate = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            hasScheduledDisplayingUpdate = false
            fetchForDisplayingItems()
        }
    }

    /// Stops the running fetch, prefetch included.
    func endUpdating() {
        guard ongoingRequest != nil else { return }
        #log(.default, "AsyncUpdate - endUpdating")
        // Completes the running details request synchronously, which runs
        // its completion below and notifies the delegate.
        inspectableApp?.cancelHierarchyDetailFetching()
    }

    /// Stops a running prefetch; a fetch the user waits for goes on. What
    /// the prefetch did not reach is asked for on the next
    /// `updateForDisplayingItems()`.
    func stopPrefetching() {
        guard ongoingRequest?.kind == .prefetch else { return }
        endUpdating()
    }

    /// Whether a fetch the user waits for is running; a prefetch does not
    /// count. A method rather than a property: Swift callers use
    /// `isUpdating()`.
    func isUpdating() -> Bool {
        ongoingRequest?.kind == .foreground
    }

    /// Whether a prefetch is running.
    func isPrefetching() -> Bool {
        ongoingRequest?.kind == .prefetch
    }

    /// Fetches the screenshots of `displayItem` (solo and group) and the
    /// group screenshots of its ancestors after an attribute was modified.
    /// Progress goes to `modifyingUpdates`.
    func updateAfterModifyingDisplayItem(_ displayItem: DisplayItem?) {
        guard let app = inspectableApp else { return }
        guard let displayItem else {
            assertionFailure()
            return
        }

        var tasks: [StaticAsyncUpdateTask] = []
        displayItem.enumerateSelfAndAncestors { item, _ in
            guard item.doNotFetchScreenshotReason == .fetchScreenshotPermitted else { return }
            if item === displayItem, !(item.subitems ?? []).isEmpty,
               let task = self.task(from: item, type: .soloScreenshot)
            {
                tasks.append(task)
            }
            if let task = self.task(from: item, type: .groupScreenshot) {
                tasks.append(task)
            }
        }

        modifyingUpdates.yield(.progress(received: 0, total: 0))

        let screenshotsTotalCount = tasks.count
        var receivedScreenshotsCount = 0
        startRequest(app: app, type: LookinRequestTypeAttrModificationPatch, tasks: tasks) { [weak self] event in
            guard let self else { return }
            switch event {
            case let .value(value):
                guard let detail = value as? DisplayItemDetail else { return }
                dataSource?.modify(with: detail)
                if detail.groupScreenshot != nil {
                    receivedScreenshotsCount += 1
                }
                if detail.soloScreenshot != nil {
                    receivedScreenshotsCount += 1
                }
                modifyingUpdates.yield(.progress(received: receivedScreenshotsCount, total: screenshotsTotalCount))
            case let .failure(error):
                assertionFailure("\(error)")
                modifyingUpdates.yield(.failure(error))
            case .completion:
                modifyingUpdates.yield(.progress(received: screenshotsTotalCount, total: screenshotsTotalCount))
            }
        }
    }

    /// Fetches one item's screenshots and attributes again, not its sub items.
    func reloadSingleDisplayItem(_ item: DisplayItem?) {
        let tasks = makeReloadSingleItemTasks(item)
        guard !tasks.isEmpty else { return }
        send(tasks) { [weak self] in
            self?.startPrefetchIfNeeded()
        }
    }

    /// Fetches an item and its sub items again, then their details.
    func reloadDisplayItemAndChildren(_ rootItem: DisplayItem?) {
        // First the root item's basis, attributes and sub items.
        let tasks = makeReloadItemAndChildrenTasks(rootItem)
        guard let rootItem, !tasks.isEmpty else { return }
        rootItem.enumerateSelfAndChildren { item in
            // Drop the screenshots and the record of answered tasks: they are
            // fetched again below. The new children are new instances, but
            // their oids (which the record is keyed by) are likely the same.
            item.soloScreenshot = nil
            item.groupScreenshot = nil
            let itemOids = Set(item.availableObjectOidsPreferView(false).map(\.uintValue))
            self.answeredTaskKeys = self.answeredTaskKeys.filter { !itemOids.contains($0.oid) }
        }
        send(tasks) { [weak self] in
            // The new children: the displayed ones now, the others prefetched.
            self?.updateForDisplayingItems()
        }
    }

    // MARK: - Displayed items and prefetch

    private func fetchForDisplayingItems() {
        guard inspectableApp != nil, dataSource != nil else { return }
        let newTasks = #signpostInterval("Make detail tasks") {
            makeTasks(prefetching: false)
        }
        guard !newTasks.isEmpty else {
            // Everything on screen is there: carry on with the prefetch.
            if ongoingRequest == nil {
                startPrefetchIfNeeded()
            }
            return
        }
        send(newTasks) { [weak self] in
            self?.startPrefetchIfNeeded()
        }
    }

    private func startPrefetchIfNeeded() {
        guard !PreferenceManager.shared.fastMode.currentBOOLValue, ongoingRequest == nil, inspectableApp != nil else { return }
        let newTasks = #signpostInterval("Make prefetch tasks") {
            makeTasks(prefetching: true)
        }
        guard !newTasks.isEmpty else { return }
        send(newTasks, kind: .prefetch)
    }

    @objc private func handleFastModeChange(_ parameters: MessageActionParameters) {
        if parameters.boolValue {
            stopPrefetching()
        } else {
            startPrefetchIfNeeded()
        }
    }

    // MARK: - Tasks

    /// The displayed items' tasks, or the prefetch's, as
    /// `DetailFetchPlanning` lists them, without the tasks a request already
    /// answered since the last reload.
    private func makeTasks(prefetching: Bool) -> [StaticAsyncUpdateTask] {
        guard let dataSource else { return [] }
        let items = dataSource.flatItems ?? []
        var indexByItem: [ObjectIdentifier: Int] = [:]
        let nodes = #signpostInterval("Build planning nodes") {
            indexByItem.reserveCapacity(items.count)
            for (index, item) in items.enumerated() {
                indexByItem[ObjectIdentifier(item)] = index
            }
            return items.map { item in
                DetailFetchPlanning.Node(
                    childIndexes: (item.subitems ?? []).compactMap { indexByItem[ObjectIdentifier($0)] },
                    isExpandable: item.isExpandable,
                    isExpanded: item.isExpanded,
                    hasPixelBearingSubitems: item.hasPixelBearingSubitems(),
                    mayFetchScreenshot: item.doNotFetchScreenshotReason == .fetchScreenshotPermitted,
                    isUserCustom: item.isUserCustom(),
                    hasSoloScreenshot: item.soloScreenshot != nil,
                    hasGroupScreenshot: item.groupScreenshot != nil,
                    hasAttributes: !(item.attributesGroupList ?? []).isEmpty
                )
            }
        }
        let displayedIndexes = (dataSource.displayingFlatItems ?? []).compactMap { indexByItem[ObjectIdentifier($0)] }
        let requests = #signpostInterval("Plan detail requests") {
            prefetching
                ? DetailFetchPlanning.prefetchRequests(for: nodes, displayedIndexes: displayedIndexes)
                : DetailFetchPlanning.onScreenRequests(for: nodes, displayedIndexes: displayedIndexes)
        }

        let context = TaskContext(appInfo: dataSource.rawHierarchyInfo?.appInfo)
        let blockedIndexes = #signpostInterval("Check SwiftUI access") {
            Self.itemIndexesBlockedBySwiftUIAccess(requests, items: items, context: context)
        }
        return #signpostInterval("Make task objects") {
            var tasks: [StaticAsyncUpdateTask] = []
            var taskKeys = Set<DetailTaskKey>()
            for request in requests where !blockedIndexes.contains(request.nodeIndex) {
                let taskType: LookinStaticAsyncUpdateTaskType = switch request.screenshot {
                case .solo: .soloScreenshot
                case .group: .groupScreenshot
                case nil: .noScreenshot
                }
                guard let task = Self.task(from: items[request.nodeIndex], type: taskType, context: context) else { continue }
                task.attrRequest = request.wantsAttributes ? .need : .notNeed
                let key = DetailTaskKey(task)
                guard !self.answeredTaskKeys.contains(key), taskKeys.insert(key).inserted else { continue }
                tasks.append(task)
            }
            return tasks
        }
    }

    /// What every task of one request shares.
    private struct TaskContext {
        let isMacTarget: Bool
        let clientReadableVersion: String

        init(appInfo: InspectedAppInfo?) {
            isMacTarget = AppHelper.appInfoLooksLikeMacTarget(appInfo)
            clientReadableVersion = AppHelper.readableVersion()
        }
    }

    private func task(from item: DisplayItem, type: LookinStaticAsyncUpdateTaskType) -> StaticAsyncUpdateTask? {
        let context = TaskContext(appInfo: dataSource?.rawHierarchyInfo?.appInfo)
        if context.isMacTarget, item.isSwiftUISupportRelated(), !Self.swiftUISupportAccessAllowed() {
            return nil
        }
        return Self.task(from: item, type: type, context: context)
    }

    /// The task, or nil for an item without an oid. The SwiftUI license
    /// check is the caller's.
    private static func task(from item: DisplayItem, type: LookinStaticAsyncUpdateTaskType, context: TaskContext) -> StaticAsyncUpdateTask? {
        var oid: UInt = 0
        switch item.resolvedNodeKind() {
        case .window, .windowScene:
            oid = item.windowObject?.oid ?? 0
        case .layoutGuide, .cell:
            oid = item.kindObject?.oid ?? 0
        case .custom:
            break
        default:
            // View, layer, a view's outer layer and a backing layer node all
            // ride layerObject / viewObject.
            //
            // On macOS the view oid comes first: the Server's detail handler
            // can screenshot every NSView (layer-backed SwiftUI views
            // included), and the layer oid may point at a released layer. On
            // iOS the layer oid comes first, as upstream does, unless a
            // separate BackingLayer node owns the layer oid (show backing
            // layers on): then the view node has to use the view oid.
            let viewOid = item.viewObject?.oid ?? 0
            let layerOid = item.layerObject?.oid ?? 0
            let prefersViewOid = context.isMacTarget || item.ownsSeparateBackingLayerNode()
            if prefersViewOid, viewOid != 0 {
                oid = viewOid
            } else if layerOid != 0 {
                oid = layerOid
            } else if viewOid != 0 {
                oid = viewOid
            }
        }
        guard oid != 0 else { return nil }

        let task = StaticAsyncUpdateTask()
        task.oid = oid
        task.frameSize = item.frame.size
        task.taskType = type
        task.needBasisVisualInfo = true
        task.clientReadableVersion = context.clientReadableVersion
        return task
    }

    /// The indexes of the requests' items a Mac app's SwiftUI license check
    /// keeps out: its SwiftUI items, when the license does not cover them.
    /// The gatekeeper is asked once, at the first SwiftUI item, as it may
    /// show an alert; once it grants access no other item needs a look.
    private static func itemIndexesBlockedBySwiftUIAccess(
        _ requests: [DetailFetchPlanning.Request],
        items: [DisplayItem],
        context: TaskContext
    ) -> Set<Int> {
        guard context.isMacTarget else { return [] }
        var checkedIndexes = Set<Int>()
        var blockedIndexes = Set<Int>()
        var accessAllowed: Bool?
        for request in requests where checkedIndexes.insert(request.nodeIndex).inserted {
            guard items[request.nodeIndex].isSwiftUISupportRelated() else { continue }
            let allowed = accessAllowed ?? swiftUISupportAccessAllowed()
            accessAllowed = allowed
            if allowed {
                return []
            }
            blockedIndexes.insert(request.nodeIndex)
        }
        return blockedIndexes
    }

    private static func swiftUISupportAccessAllowed() -> Bool {
        SwiftUISupportGatekeeper.sharedInstance().allowProtectedFeatureAccess(for: NSApplication.shared.keyWindow)
    }

    private static func packages(from tasks: [StaticAsyncUpdateTask], kind: DetailRequestKind) -> [StaticAsyncUpdateTasksPackage] {
        let areas = tasks.map { Double($0.frameSize.width * $0.frameSize.height) }
        let ranges = switch kind {
        case .foreground:
            DetailTaskPackaging.packageRanges(areas: areas)
        case .prefetch:
            DetailTaskPackaging.packageRanges(areas: areas, maxArea: prefetchPackageMaximumArea, maxCount: prefetchPackageMaximumTaskCount)
        }
        return ranges.map { range in
            let package = StaticAsyncUpdateTasksPackage()
            package.tasks = Array(tasks[range])
            return package
        }
    }

    // MARK: - Requests

    /// Sends a request whose events arrive synchronously on the main
    /// thread. `endUpdating()` relies on that: cancelling the details
    /// request completes it before the next request starts.
    private func startRequest(
        app: InspectableApp,
        type: Int,
        tasks: NSArray,
        onEvent: @escaping (AppResponseEvent) -> Void
    ) {
        guard let channel = app.channel else {
            onEvent(.failure(ConnectionError.noConnect))
            return
        }
        _ = InspectableApp.startRequest(on: channel, type: UInt32(type), data: tasks, onEvent: onEvent)
    }

    private func startRequest(
        app: InspectableApp,
        type: Int,
        tasks: [StaticAsyncUpdateTask],
        onEvent: @escaping (AppResponseEvent) -> Void
    ) {
        startRequest(app: app, type: type, tasks: tasks as NSArray, onEvent: onEvent)
    }

    /// Sends `newTasks`, replacing the running request. `completion` runs
    /// once every task is answered, not when the request is cancelled or
    /// fails.
    private func send(_ newTasks: [StaticAsyncUpdateTask], kind: DetailRequestKind = .foreground, completion: (() -> Void)? = nil) {
        guard let app = inspectableApp, !newTasks.isEmpty else { return }
        // The same request cannot run twice at once: cancel the previous one.
        endUpdating()

        let request = DetailUpdateRequest(kind: kind, packages: Self.packages(from: newTasks, kind: kind))
        request.signpostInterval = switch kind {
        case .foreground: #signpost(.begin, "Fetch displayed items")
        case .prefetch: #signpost(.begin, "Prefetch")
        }
        ongoingRequest = request
        notifyTasksCountToDelegate()

        #log(.default, "AsyncUpdate - Will send \(NSNumber(value: newTasks.count), privacy: .public) tasks (\(kind == .prefetch ? "prefetch" : "foreground", privacy: .public)).")

        startRequest(app: app, type: LookinRequestTypeHierarchyDetails, tasks: request.packages as NSArray) { [weak self] event in
            guard let self else { return }
            switch event {
            case let .value(value):
                #signpostInterval("Apply details") {
                    self.receive(details: value as? [DisplayItemDetail] ?? [], for: request)
                }
            case let .failure(error):
                request.endSignpostInterval()
                fail(request, error: error)
            case .completion:
                request.endSignpostInterval()
                // A request the user cancelled, or one a newer request
                // replaced, ends here too.
                if complete(request) {
                    completion?()
                }
            }
        }
    }

    private func receive(details: [DisplayItemDetail], for request: DetailUpdateRequest) {
        for detail in details {
            if detail.failureCode != LookinDisplayItemDetailFailureCode.none.rawValue {
                // ObjectGone is routine: the inspected app released the
                // object after the hierarchy build (TextKit 2 fragment views,
                // portals and other short-lived internals go away on their
                // own). The node keeps the data captured at build time, so
                // only real faults feed the "Some layer data failed to
                // transmit" alert.
                let objectIsGone = detail.failureCode == LookinDisplayItemDetailFailureCode.objectGone.rawValue
                if !objectIsGone {
                    request.failedTasksCount += 1
                }
                let failedItem = dataSource?.displayItem(withOid: detail.displayItemOid)
                let outcome: String = objectIsGone ? "skipped, object gone" : "failed"
                let title: String = failedItem?.title() ?? "<not in the current tree>"
                let nodeKind: Int = failedItem?.resolvedNodeKind().rawValue ?? 0
                let viewClass: String = failedItem?.viewObject?.rawClassName() ?? "-"
                let viewAddress: String = failedItem?.viewObject?.memoryAddress ?? "-"
                let layerClass: String = failedItem?.layerObject?.rawClassName() ?? "-"
                let layerAddress: String = failedItem?.layerObject?.memoryAddress ?? "-"
                #log(.default, "AsyncUpdate - task \(outcome as NSString, privacy: .public): oid \(detail.displayItemOid, privacy: .public), item \(title as NSString, privacy: .public) (nodeKind \(nodeKind, privacy: .public), view \(viewClass as NSString, privacy: .public) \(viewAddress as NSString, privacy: .public), layer \(layerClass as NSString, privacy: .public) \(layerAddress as NSString, privacy: .public))")
            } else {
                dataSource?.modify(with: detail)
            }
        }
        request.finishedTasksCount += details.count
        if request === ongoingRequest {
            notifyTasksCountToDelegate()
        }
    }

    private func fail(_ request: DetailUpdateRequest, error: NSError) {
        guard request === ongoingRequest else { return }
        ongoingRequest = nil
        notifyTasksCountToDelegate()

        if error.code == LookinErrCode_Discard {
            // Another detail request took the channel (the MCP bridge asks
            // for screenshots this way). Nothing went wrong: what is still
            // missing is asked for again once it is done.
            #log(.default, "AsyncUpdate - \(request.kind == .prefetch ? "prefetch" : "request", privacy: .public) discarded by a newer detail request")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self, ongoingRequest == nil else { return }
                updateForDisplayingItems()
            }
            return
        }
        guard request.kind == .foreground else {
            // A prefetch the user never waited for fails quietly; the items
            // it did not reach are asked for when they are displayed.
            #log(.default, "AsyncUpdate - prefetch failed: \(error.localizedDescription, privacy: .public)")
            return
        }

        let title = NSLocalizedString("Request timeout, layer data transmission failed.", comment: "")
        var detail = NSLocalizedString(
            "Perhaps your iOS app is paused with breakpoint in Xcode, blocked by other tasks in main thread, or moved to background state.\nToo large screenshots may also lead to this error.",
            comment: ""
        )
        if SwiftUISupportGatekeeper.sharedInstance().activationState == .activated,
           (dataSource?.flatItems ?? []).contains(where: { $0.isSwiftUISupportRelated() })
        {
            detail += "\n" + NSLocalizedString(
                "First-time loading of SwiftUI details may take longer because LookInside needs to collect and match SwiftUI debug data.",
                comment: ""
            )
        }
        let alertError = StaticErrors.make(title: title, detail: detail)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // The static view controller may not be set up yet to show the
            // tip, so wait a little.
            self.delegate?.detailUpdateReceivedError(alertError)
        }
    }

    /// Ends `request`; true when every task was answered, false when it was
    /// cancelled or replaced first.
    private func complete(_ request: DetailUpdateRequest) -> Bool {
        guard request === ongoingRequest else { return false }
        let answeredEveryTask = request.finishedTasksCount >= request.tasksTotalCount
        if answeredEveryTask {
            answeredTaskKeys.formUnion(request.taskKeys)
        }
        if request.kind == .foreground, request.failedTasksCount > 0 {
            let error = StaticErrors.make(
                title: NSLocalizedString("Some layer data failed to transmit.", comment: ""),
                detail: NSLocalizedString(
                    "It may be due to changes in the layer structure within the iOS app. You can try reloading the entire structure in LookInside.",
                    comment: ""
                )
            )
            delegate?.detailUpdateReceivedError(error)
        }
        ongoingRequest = nil
        notifyTasksCountToDelegate()
        PerformanceReporter.sharedInstance().didComplete()
        return answeredEveryTask
    }

    /// Reports the request the user waits for; a prefetch reports nothing.
    private func notifyTasksCountToDelegate() {
        let request = ongoingRequest?.kind == .foreground ? ongoingRequest : nil
        let totalCount = request?.tasksTotalCount ?? 0
        let finishedCount = request?.finishedTasksCount ?? 0
        #log(.default, "AsyncUpdate - notify delagate: \(NSNumber(value: finishedCount), privacy: .public)/\(NSNumber(value: totalCount), privacy: .public)")
        delegate?.detailUpdateTasksTotalCount(UInt(totalCount), finishedCount: UInt(max(finishedCount, 0)))
    }
}

// MARK: - Reload tasks

extension StaticAsyncUpdateManager {
    /// The tasks that reload one item: its group screenshot (and solo one
    /// when it has children), or its attributes alone when it has no
    /// screenshot. Empty when the Server is too old or the item is a
    /// SwiftUI item the license does not cover.
    fileprivate func makeReloadSingleItemTasks(_ item: DisplayItem?) -> [StaticAsyncUpdateTask] {
        guard let item, canReload(item) else { return [] }
        let appInfo = inspectableApp?.appInfo
        var tasks: [StaticAsyncUpdateTask] = []
        if item.doNotFetchScreenshotReason == .fetchScreenshotPermitted {
            if let task = Self.reloadTask(from: item, appInfo: appInfo) {
                task.taskType = .groupScreenshot
                tasks.append(task)
            }
            if item.isExpandable, let task = Self.reloadTask(from: item, appInfo: appInfo) {
                task.taskType = .soloScreenshot
                tasks.append(task)
            }
        } else if let task = Self.reloadTask(from: item, appInfo: appInfo) {
            task.taskType = .noScreenshot
            tasks.append(task)
        }
        tasks.first?.needBasisVisualInfo = true
        return tasks
    }

    /// The task that reloads an item's basis and sub items (no screenshot,
    /// no attributes).
    fileprivate func makeReloadItemAndChildrenTasks(_ item: DisplayItem?) -> [StaticAsyncUpdateTask] {
        guard let item, canReload(item),
              let task = Self.reloadTask(from: item, appInfo: inspectableApp?.appInfo)
        else {
            return []
        }
        task.taskType = .noScreenshot
        task.attrRequest = .notNeed
        task.needBasisVisualInfo = true
        task.needSubitems = true
        return [task]
    }

    /// Whether `item` may be reloaded: not while updating, not from a
    /// Server older than 1.2.7 (after an alert), and not for a SwiftUI item
    /// the license does not cover.
    private func canReload(_ item: DisplayItem) -> Bool {
        if isUpdating() {
            assertionFailure()
            return false
        }
        let appInfo = inspectableApp?.appInfo
        guard VersionComparer.compare(expectedVersion: "1.2.7", realVersion: (appInfo?.serverReadableVersion as String?) ?? "") else {
            let error = StaticErrors.make(
                title: NSLocalizedString("Operation failed.", comment: ""),
                detail: NSLocalizedString("Please upgrade the LookinServer SDK version in your iOS project to 1.2.7 or higher.", comment: "")
            )
            StaticErrors.alert(error, in: NSApplication.shared.keyWindow)
            return false
        }
        if AppHelper.appInfoLooksLikeMacTarget(appInfo),
           item.isSwiftUISupportRelated(),
           !SwiftUISupportGatekeeper.sharedInstance().allowProtectedFeatureAccess(for: NSApplication.shared.keyWindow)
        {
            return false
        }
        return true
    }

    private static func reloadTask(from item: DisplayItem, appInfo: InspectedAppInfo?) -> StaticAsyncUpdateTask? {
        let oid = item.bestObjectOidPreferView(AppHelper.appInfoLooksLikeMacTarget(appInfo))
        guard oid != 0 else { return nil }
        let task = StaticAsyncUpdateTask()
        task.oid = oid
        task.frameSize = item.frame.size
        task.clientReadableVersion = AppHelper.readableVersion()
        return task
    }
}

// MARK: - DetailUpdateRequest

/// Whether the user waits for a request.
private enum DetailRequestKind {
    /// The displayed items, or an item reloaded on request: the window shows
    /// the progress, and its reload button stops it.
    case foreground
    /// What expanding the folded items would show: never shown, never in
    /// the way of a reload, cancelled whenever anything else needs the
    /// channel.
    case prefetch
}

/// A task as the answered-task record knows it.
private struct DetailTaskKey: Hashable {
    let oid: UInt
    let taskType: Int
    let requestsAttributes: Bool

    init(_ task: StaticAsyncUpdateTask) {
        oid = task.oid
        taskType = task.taskType.rawValue
        requestsAttributes = task.attrRequest == .need
    }
}

/// One details request: its packages and how many of their tasks replied.
private final class DetailUpdateRequest {
    let kind: DetailRequestKind
    let packages: [StaticAsyncUpdateTasksPackage]
    /// Tasks that received a reply, failed ones included. Which ones is not
    /// known, only how many.
    var finishedTasksCount = 0
    var failedTasksCount = 0
    /// From the send to the completion or failure.
    var signpostInterval: SignpostInterval?

    init(kind: DetailRequestKind, packages: [StaticAsyncUpdateTasksPackage]) {
        self.kind = kind
        self.packages = packages
    }

    /// Closes `signpostInterval`, once.
    func endSignpostInterval() {
        guard let signpostInterval else { return }
        self.signpostInterval = nil
        #signpost(.end, signpostInterval)
    }

    var tasksTotalCount: Int {
        packages.reduce(0) { $0 + ($1.tasks?.count ?? 0) }
    }

    var taskKeys: [DetailTaskKey] {
        packages.flatMap { ($0.tasks ?? []).map(DetailTaskKey.init) }
    }
}

// MARK: - Errors

/// The NSError the Objective-C `LookinErrorMake` / `AlertError` macros made
/// and showed.
enum StaticErrors {
    static func make(title: String, detail: String) -> NSError {
        NSError(domain: LookinErrorDomain, code: LookinErrCode_Default, userInfo: [
            NSLocalizedDescriptionKey: title,
            NSLocalizedRecoverySuggestionErrorKey: detail,
        ])
    }

    /// Shows `error` as a sheet on `window`, unless it is a discard error.
    static func alert(_ error: Error, in window: NSWindow?) {
        let error = error as NSError
        guard error.code != LookinErrCode_Discard else { return }
        let alert = NSAlert(error: error)
        if let window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            // What the macro did with a nil window.
            alert.perform(#selector(NSAlert.beginSheetModal(for:completionHandler:)), with: nil, with: nil)
        }
    }
}
