//
//  StaticAsyncUpdateManager.swift
//  LookInside
//
//  Created by Li Kai on 2019/2/19.
//  https://lookin.work
//

import AppKit
import LookInsideHostCore

@objc(LKStaticAsyncUpdateManagerDelegate)
protocol StaticAsyncUpdateManagerDelegate: NSObjectProtocol {
    /// Called whenever the number of unfinished tasks changes: `totalCount`
    /// tasks in all, `finishedCount` of them done.
    @objc(detailUpdateTasksTotalCount:finishedCount:)
    func detailUpdateTasksTotalCount(_ totalCount: UInt, finishedCount: UInt)

    @objc(detailUpdateReceivedError:)
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
@objc(LKStaticAsyncUpdateManager)
@MainActor
final class StaticAsyncUpdateManager: NSObject {
    /// Set by the owner (window controller / live document), which holds it
    /// strongly.
    @objc weak var hierarchyDataSource: StaticHierarchyDataSource?

    /// The app every request goes to. The owner refreshes it when a new
    /// hierarchy arrives or the document reconnects.
    @objc weak var inspectableApp: InspectableApp?

    @objc weak var delegate: StaticAsyncUpdateManagerDelegate?

    /// Events of `updateAfterModifyingDisplayItem(_:)`.
    let modifyingUpdates = AsyncBroadcaster<ModifyingUpdateEvent>()

    /// Requests that received every reply.
    private var succeededRequests: [DetailUpdateRequest] = []
    /// The request sent and not yet ended.
    private var ongoingRequest: DetailUpdateRequest?

    private let dataSourceSignals = SyncSubscriptionBag()

    @objc(initWithHierarchyDataSource:inspectableApp:)
    init(hierarchyDataSource: StaticHierarchyDataSource?, inspectableApp: InspectableApp?) {
        self.hierarchyDataSource = hierarchyDataSource
        self.inspectableApp = inspectableApp
        super.init()
        dataSourceSignals.observe(hierarchyDataSource?.willReloadHierarchyInfo) { [weak self] in
            self?.succeededRequests.removeAll()
        }
    }

    @objc override convenience init() {
        self.init(hierarchyDataSource: nil, inspectableApp: nil)
    }

    private var dataSource: StaticHierarchyDataSource? {
        hierarchyDataSource
    }

    // MARK: - Public

    /// With fast mode off: after a reload, fetches the details of every item.
    @objc func updateAll() {
        assert(!PreferenceManager.shared.fastMode.currentBOOLValue)
        guard inspectableApp != nil, let dataSource, !dataSource.flatItems.isEmpty else {
            return
        }
        endUpdating()
        let newTasks = makeMaximumTasks()
        guard !newTasks.isEmpty else { return }
        send(newTasks)
    }

    /// With fast mode on: fetches the details of the visible items that do
    /// not have them yet. Call it whenever the displayed items change.
    @objc func updateForDisplayingItems() {
        assert(PreferenceManager.shared.fastMode.currentBOOLValue)
        guard inspectableApp != nil else { return }
        let items = dataSource?.displayingFlatItems ?? []
        guard !items.isEmpty else { return }
        let newTasks = makeMinimumTasks(for: items)
        guard !newTasks.isEmpty else { return }
        send(newTasks)
    }

    /// Stops the running fetch.
    @objc func endUpdating() {
        guard ongoingRequest != nil else { return }
        NSLog("AsyncUpdate - endUpdating")
        // Completes the running details request synchronously, which runs
        // its completion below and notifies the delegate.
        inspectableApp?.cancelHierarchyDetailFetching()
    }

    /// A method rather than a property: Swift callers use `isUpdating()`.
    @objc func isUpdating() -> Bool {
        ongoingRequest != nil
    }

    /// Fetches the screenshots of `displayItem` (solo and group) and the
    /// group screenshots of its ancestors after an attribute was modified.
    /// Progress goes to `modifyingUpdates`.
    @objc(updateAfterModifyingDisplayItem:)
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
    @objc(reloadSingleDisplayItem:)
    func reloadSingleDisplayItem(_ item: DisplayItem?) {
        let tasks = makeReloadSingleItemTasks(item)
        guard !tasks.isEmpty else { return }
        send(tasks)
    }

    /// Fetches an item and its sub items again, then their details.
    @objc(reloadDisplayItemAndChildren:)
    func reloadDisplayItemAndChildren(_ rootItem: DisplayItem?) {
        // First the root item's basis, attributes and sub items.
        let tasks = makeReloadItemAndChildrenTasks(rootItem)
        guard let rootItem, !tasks.isEmpty else { return }
        rootItem.enumerateSelfAndChildren { item in
            // Drop the screenshots and the record of finished tasks: they are
            // fetched again below. The new children are new instances, but
            // their oids (which task equality uses) are likely the same.
            item.soloScreenshot = nil
            item.groupScreenshot = nil
            for request in self.succeededRequests {
                request.removeTasks(of: item)
            }
        }
        send(tasks) { [weak self] in
            self?.updateAfterReloadingItemAndChildren(rootItem)
        }
    }

    // MARK: - Tasks

    private func makeMaximumTasks() -> [StaticAsyncUpdateTask] {
        guard let dataSource else { return [] }
        // Order matters: earlier tasks are fetched first, so the visible
        // items go first.
        var tasks: [StaticAsyncUpdateTask] = (dataSource.displayingFlatItems ?? []).compactMap { item in
            if item.isUserCustom() {
                return nil
            }
            if item.doNotFetchScreenshotReason == .fetchScreenshotPermitted {
                // Mirrors -appropriateScreenshot: a node showing its group
                // screenshot must not have the solo one fetched first, or the
                // preview waits on an image it will never display.
                if item.isExpandable, item.isExpanded, item.hasPixelBearingSubitems() {
                    return task(from: item, type: .soloScreenshot)
                }
                return task(from: item, type: .groupScreenshot)
            }
            return task(from: item, type: .noScreenshot)
        }

        func appendIfNew(_ task: StaticAsyncUpdateTask?) {
            if let task, !tasks.contains(task) {
                tasks.append(task)
            }
        }
        for item in dataSource.flatItems ?? [] where !item.isUserCustom() {
            if item.doNotFetchScreenshotReason == .fetchScreenshotPermitted {
                appendIfNew(task(from: item, type: .groupScreenshot))
                if item.isExpandable {
                    appendIfNew(task(from: item, type: .soloScreenshot))
                }
            } else {
                appendIfNew(task(from: item, type: .noScreenshot))
            }
        }
        return tasks
    }

    private func makeMinimumTasks(for items: [DisplayItem]) -> [StaticAsyncUpdateTask] {
        items.compactMap { item -> StaticAsyncUpdateTask? in
            if item.isUserCustom() {
                return nil
            }
            if item.lkOptionalAppropriateScreenshot != nil {
                // Has its image, and so its attributes too.
                return nil
            }
            let newTask: StaticAsyncUpdateTask?
            if item.doNotFetchScreenshotReason == .fetchScreenshotPermitted {
                // Should have an image but does not: fetch it.
                if item.isExpandable, item.isExpanded {
                    newTask = task(from: item, type: .soloScreenshot)
                } else {
                    newTask = task(from: item, type: .groupScreenshot)
                }
            } else if (item.attributesGroupList ?? []).isEmpty {
                // No image by design; fetch the attributes once.
                newTask = task(from: item, type: .noScreenshot)
            } else {
                return nil
            }
            guard let newTask else { return nil }

            // attrRequest is supported since Client 1.0.7 and Server 1.2.7.
            newTask.attrRequest = (item.attributesGroupList ?? []).isEmpty ? .need : .notNeed

            if succeededRequests.contains(where: { $0.contains(newTask) }) {
                // Already fetched successfully.
                return nil
            }
            return newTask
        }
    }

    private func updateAfterReloadingItemAndChildren(_ rootItem: DisplayItem) {
        // The root item's and its children's screenshots and attributes.
        if PreferenceManager.shared.fastMode.currentBOOLValue {
            updateForDisplayingItems()
            return
        }
        var tasks: [StaticAsyncUpdateTask] = []
        rootItem.enumerateSelfAndChildren { item in
            guard !item.isUserCustom() else { return }
            if item.doNotFetchScreenshotReason == .fetchScreenshotPermitted {
                if let groupTask = self.task(from: item, type: .groupScreenshot) {
                    tasks.append(groupTask)
                }
                if item.isExpandable, let soloTask = self.task(from: item, type: .soloScreenshot) {
                    tasks.append(soloTask)
                }
            } else if let attrTask = self.task(from: item, type: .noScreenshot) {
                tasks.append(attrTask)
            }
        }
        send(tasks)
    }

    private func task(from item: DisplayItem, type: LookinStaticAsyncUpdateTaskType) -> StaticAsyncUpdateTask? {
        let appInfo = dataSource?.rawHierarchyInfo?.appInfo
        guard Self.allowsSwiftUISupportAccess(for: item, appInfo: appInfo) else {
            return nil
        }

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
            let prefersViewOid = AppHelper.appInfoLooksLikeMacTarget(appInfo) || item.lk_ownsSeparateBackingLayerNode()
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
        task.clientReadableVersion = AppHelper.lookinReadableVersion()
        return task
    }

    private static func allowsSwiftUISupportAccess(for item: DisplayItem, appInfo: InspectedAppInfo?) -> Bool {
        guard AppHelper.appInfoLooksLikeMacTarget(appInfo), item.lk_isSwiftUISupportRelated() else {
            return true
        }
        return SwiftUISupportGatekeeper.sharedInstance().allowProtectedFeatureAccess(for: NSApplication.shared.keyWindow)
    }

    private static func packages(from tasks: [StaticAsyncUpdateTask]) -> [StaticAsyncUpdateTasksPackage] {
        let areas = tasks.map { Double($0.frameSize.width * $0.frameSize.height) }
        return DetailTaskPackaging.packageRanges(areas: areas).map { range in
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

    private func send(_ newTasks: [StaticAsyncUpdateTask], completion: (() -> Void)? = nil) {
        guard let app = inspectableApp, !newTasks.isEmpty else { return }
        // The same request cannot run twice at once: cancel the previous one.
        endUpdating()

        let packages = Self.packages(from: newTasks)
        let request = DetailUpdateRequest(packages: packages)
        ongoingRequest = request
        notifyTasksCountToDelegate()

        NSLog("AsyncUpdate - Will send %@ tasks.", NSNumber(value: newTasks.count))

        startRequest(app: app, type: LookinRequestTypeHierarchyDetails, tasks: packages as NSArray) { [weak self] event in
            guard let self else { return }
            switch event {
            case let .value(value):
                receive(details: value as? [DisplayItemDetail] ?? [])
            case .failure:
                fail()
            case .completion:
                // A request the user cancelled ends here too.
                complete()
                completion?()
            }
        }
    }

    private func receive(details: [DisplayItemDetail]) {
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
                    ongoingRequest?.failedTasksCount += 1
                }
                let failedItem = dataSource?.displayItem(withOid: detail.displayItemOid)
                let outcome: String = objectIsGone ? "skipped, object gone" : "failed"
                let title: String = failedItem?.title() ?? "<not in the current tree>"
                let nodeKind: Int = failedItem?.resolvedNodeKind().rawValue ?? 0
                let viewClass: String = failedItem?.viewObject?.rawClassName() ?? "-"
                let viewAddress: String = failedItem?.viewObject?.memoryAddress ?? "-"
                let layerClass: String = failedItem?.layerObject?.rawClassName() ?? "-"
                let layerAddress: String = failedItem?.layerObject?.memoryAddress ?? "-"
                NSLog(
                    "AsyncUpdate - task %@: oid %lu, item %@ (nodeKind %ld, view %@ %@, layer %@ %@)",
                    outcome as NSString,
                    detail.displayItemOid,
                    title as NSString,
                    nodeKind,
                    viewClass as NSString,
                    viewAddress as NSString,
                    layerClass as NSString,
                    layerAddress as NSString
                )
            } else {
                dataSource?.modify(with: detail)
            }
        }
        ongoingRequest?.finishedTasksCount += details.count
        notifyTasksCountToDelegate()
    }

    private func fail() {
        ongoingRequest = nil
        notifyTasksCountToDelegate()

        let title = NSLocalizedString("Request timeout, layer data transmission failed.", comment: "")
        var detail = NSLocalizedString(
            "Perhaps your iOS app is paused with breakpoint in Xcode, blocked by other tasks in main thread, or moved to background state.\nToo large screenshots may also lead to this error.",
            comment: ""
        )
        if SwiftUISupportGatekeeper.sharedInstance().activationState == .activated,
           (dataSource?.flatItems ?? []).contains(where: { $0.lk_isSwiftUISupportRelated() })
        {
            detail += "\n" + NSLocalizedString(
                "First-time loading of SwiftUI details may take longer because LookInside needs to collect and match SwiftUI debug data.",
                comment: ""
            )
        }
        let error = StaticErrors.make(title: title, detail: detail)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // The static view controller may not be set up yet to show the
            // tip, so wait a little.
            self.delegate?.detailUpdateReceivedError(error)
        }
    }

    private func complete() {
        if let request = ongoingRequest {
            let userCancelled = request.tasksTotalCount > request.finishedTasksCount
            if !userCancelled {
                succeededRequests.append(request)
            }
            if request.failedTasksCount > 0 {
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
        } else {
            assertionFailure()
        }
        notifyTasksCountToDelegate()
        PerformanceReporter.sharedInstance().didComplete()
    }

    private func notifyTasksCountToDelegate() {
        let totalCount = ongoingRequest?.tasksTotalCount ?? 0
        let finishedCount = ongoingRequest?.finishedTasksCount ?? 0
        NSLog("AsyncUpdate - notify delagate: %@/%@", NSNumber(value: finishedCount), NSNumber(value: totalCount))
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
           item.lk_isSwiftUISupportRelated(),
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
        task.clientReadableVersion = AppHelper.lookinReadableVersion()
        return task
    }
}

// MARK: - DetailUpdateRequest

/// One details request: its packages and how many of their tasks replied.
private final class DetailUpdateRequest {
    private(set) var packages: [StaticAsyncUpdateTasksPackage]
    /// Tasks that received a reply, failed ones included. Which ones is not
    /// known, only how many.
    var finishedTasksCount = 0
    var failedTasksCount = 0

    init(packages: [StaticAsyncUpdateTasksPackage]) {
        self.packages = packages
    }

    var tasksTotalCount: Int {
        packages.reduce(0) { $0 + ($1.tasks?.count ?? 0) }
    }

    func contains(_ task: StaticAsyncUpdateTask) -> Bool {
        packages.contains { ($0.tasks ?? []).contains(task) }
    }

    func removeTasks(of item: DisplayItem) {
        let itemOids = Set(item.availableObjectOidsPreferView(false).map(\.uintValue))
        for package in packages {
            package.tasks = (package.tasks ?? []).filter { !itemOids.contains($0.oid) }
        }
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
