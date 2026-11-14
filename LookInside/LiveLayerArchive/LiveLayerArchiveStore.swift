//
//  LiveLayerArchiveStore.swift
//  LookInside
//
//  The layer archives of one live document's windows, and the node images
//  drawn from them.
//
//  A macOS Server that reports `layerArchiveProtocolVersion` 1 encodes a
//  window's whole layer tree on request (211). After every hierarchy reload
//  the store fetches each window's archive, one window after another, and
//  `StaticAsyncUpdateManager` routes the images the preview asks for here
//  instead of to the Server's screenshots (203): the importers' renderer
//  draws Liquid Glass, materials and vibrancy, renderInContext: in the
//  inspected app does not. Window nodes keep the Server's real screenshot.
//  A window whose archive is unusable — more layers than the limit, a tree
//  that does not match the Server's walk, an error — and the nodes an
//  archive has no layer for keep the Server's screenshots too.
//

import AppKit
import FoundationToolbox

@Loggable(subsystem: "com.lookinside.app")
@MainActor
final class LiveLayerArchiveStore {
    /// Who draws one image of a node.
    enum ImageSource {
        /// The Server, as a screenshot (203).
        case server
        /// The window's archive, which is on its way: plan the image again
        /// once it arrives.
        case pendingArchive
        /// The window's archive.
        case archive(LiveLayerArchive, LiveLayerArchive.NodeLayers)
    }

    /// How soon an image is wanted.
    enum Priority: Int, Comparable {
        /// The preview shows it now.
        case shown
        /// A file of the whole tree waits for it.
        case wholeTree
        /// Expanding or collapsing a node would show it.
        case prefetch

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private enum WindowState {
        case pending
        case ready(LiveLayerArchive)
        case unavailable
    }

    private struct ImageKey: Hashable {
        let item: ObjectIdentifier
        let kind: LiveLayerArchive.ImageKind
    }

    private struct Job {
        let key: ImageKey
        weak var item: DisplayItem?
        let archive: LiveLayerArchive
        let nodes: LiveLayerArchive.NodeLayers
        var priority: Priority
        /// Called with the image once drawn, nil when it came out empty.
        var completions: [@MainActor (NSImage?) -> Void] = []
    }

    /// What crosses to the work queue and back.
    private struct UncheckedSendable<Value>: @unchecked Sendable {
        let value: Value
    }

    /// Decoding and drawing. The renderer moves the layers it draws into a
    /// container for the length of a render, so an archive is used by one
    /// thread at a time.
    private nonisolated static let workQueue = DispatchQueue(label: "app.lookinside.live-layer-archive", qos: .userInitiated)

    /// Called when a window's archive arrives or turns out unusable: the
    /// images planned while it was pending can be planned now.
    var archivesDidSettle: (() -> Void)?

    /// Whether the session's Server encodes layer trees.
    private(set) var isActive = false
    private var windowStates: [UInt: WindowState] = [:]
    /// Bumped by every reload; work started before it is dropped.
    private var generation = 0
    private weak var app: InspectableApp?
    /// The windows whose archives are still to be asked for, in order. One
    /// request at a time: a newer layer archive request on the channel makes
    /// the connection discard an older one.
    private var fetchQueue: [UInt] = []
    private var fetchingWindowOid: UInt?
    /// Windows the app changed again while their archive was being fetched.
    private var windowsToFetchAgain: Set<UInt> = []
    private var refetchCompletions: [UInt: [@MainActor (Bool) -> Void]] = [:]
    private var settleWaiters: [CheckedContinuation<Void, Never>] = []
    /// Most urgent first; within a priority, in the order asked for.
    private var waitingJobs: [Job] = []
    private var drawingJob: Job?
    private var drawnKeys: Set<ImageKey> = []
    private var idleWaiters: [@MainActor () -> Void] = []
    private var nodeLayerOidsByWindow: [UInt: Set<UInt>] = [:]
    /// The window nodes of the tree, by window oid.
    private var windowItemsByOid: [UInt: DisplayItem] = [:]
    /// The layers of each window's glass layer nodes (`SwiftUI.SDFLayer`).
    private var glassLayerOidsByWindow: [UInt: Set<UInt>] = [:]

    /// Whether the Liquid Glass setting hides the glass of windows drawn
    /// from archives (Hide): their images then leave the glass layers out,
    /// as the Server's group screenshots do. The owner sets it, and draws the
    /// images on screen again when it changes.
    var hidesGlassLayers = false
    private var serverDrawnDescendantsByItem: [ObjectIdentifier: Bool] = [:]

    // MARK: - Archives

    /// Starts over for a new hierarchy whose top-level nodes are `windows`:
    /// when `appInfo`'s Server encodes layer trees, every window's archive is
    /// fetched, one after another.
    func reload(windows: [DisplayItem], appInfo: InspectedAppInfo?, app: InspectableApp?) {
        reset()
        guard let app, (appInfo?.layerArchiveProtocolVersion ?? 0) >= 1 else { return }
        isActive = true
        let windowOids = windows.compactMap { window -> UInt? in
            guard window.resolvedNodeKind() == .window, let oid = window.windowObject?.oid, oid != 0 else { return nil }
            windowItemsByOid[oid] = window
            return oid
        }
        for windowOid in windowOids {
            windowStates[windowOid] = .pending
        }
        self.app = app
        fetchQueue = windowOids
        #log(.default, "LayerArchive - fetching \(windowOids.count, privacy: .public) window archives")
        fetchNextArchive()
    }

    /// Fetches the archive of `window` again after the app changed — an
    /// attribute edit, a node reloaded — ahead of the windows still waiting.
    /// `completion` hears whether the new archive arrived: true once the
    /// window is drawn from it, false when the window is the Server's now.
    func refetchArchive(of window: DisplayItem, completion: @escaping @MainActor (Bool) -> Void) {
        guard isActive, let windowOid = window.windowObject?.oid, windowStates[windowOid] != nil else {
            completion(false)
            return
        }
        windowStates[windowOid] = .pending
        refetchCompletions[windowOid, default: []].append(completion)
        if fetchingWindowOid == windowOid {
            windowsToFetchAgain.insert(windowOid)
        } else {
            fetchQueue.removeAll { $0 == windowOid }
            fetchQueue.insert(windowOid, at: 0)
        }
        fetchNextArchive()
    }

    /// The window `item` belongs to, when that window is drawn from an
    /// archive that arrived.
    func readyWindow(containing item: DisplayItem) -> DisplayItem? {
        guard isActive, let window = Self.window(of: item), let windowOid = window.windowObject?.oid,
              case .ready = windowStates[windowOid]
        else { return nil }
        return window
    }

    /// Returns once no window's archive is on its way.
    func waitForPendingArchives() async {
        guard hasPendingArchives else { return }
        await withCheckedContinuation { continuation in
            settleWaiters.append(continuation)
        }
    }

    private func fetchNextArchive() {
        guard fetchingWindowOid == nil, let app, !fetchQueue.isEmpty else { return }
        let windowOid = fetchQueue.removeFirst()
        fetchingWindowOid = windowOid
        let generation = generation
        Task { [weak self] in
            let outcome = await Self.fetchingArchive(windowOid: windowOid, from: app)
            guard let self, self.generation == generation else { return }
            fetchingWindowOid = nil
            if windowsToFetchAgain.remove(windowOid) != nil {
                // Changed again while it was being encoded: this archive is
                // already old.
                fetchQueue.insert(windowOid, at: 0)
            } else {
                settle(windowOid, outcome)
                let succeeded = if case .success = outcome { true } else { false }
                for completion in refetchCompletions.removeValue(forKey: windowOid) ?? [] {
                    completion(succeeded)
                }
            }
            fetchNextArchive()
        }
    }

    /// The windows whose images the Server takes after all: no usable
    /// archive arrived.
    var windowsWithoutArchive: Set<UInt> {
        Set(windowStates.compactMap { windowOid, state in
            if case .unavailable = state { windowOid } else { nil }
        })
    }

    /// Whether a window's archive is still on its way.
    var hasPendingArchives: Bool {
        windowStates.values.contains { state in
            if case .pending = state { true } else { false }
        }
    }

    /// One window's decoded archive, or why there is none.
    private static func fetchingArchive(windowOid: UInt, from app: InspectableApp) async -> Result<LiveLayerArchive, Error> {
        let reply: LayerArchive
        do {
            reply = try await app.layerArchive(windowOid: windowOid, layerLimit: LiveLayerArchive.layerLimit)
        } catch {
            return .failure(error)
        }
        let sendableReply = UncheckedSendable(value: reply)
        let decoded: UncheckedSendable<Result<LiveLayerArchive, Error>> = await withCheckedContinuation { continuation in
            workQueue.async {
                let outcome: Result<LiveLayerArchive, Error>
                do {
                    outcome = try .success(LiveLayerArchive(reply: sendableReply.value, windowOid: windowOid))
                } catch {
                    outcome = .failure(error)
                }
                continuation.resume(returning: UncheckedSendable(value: outcome))
            }
        }
        return decoded.value
    }

    private func settle(_ windowOid: UInt, _ outcome: Result<LiveLayerArchive, Error>) {
        switch outcome {
        case let .success(archive):
            windowStates[windowOid] = .ready(archive)
            if let window = windowItemsByOid[windowOid] {
                linkingPortalSources(in: window, from: archive)
            }
            #log(.default, "LayerArchive - window \(windowOid, privacy: .public): \(archive.layers.count, privacy: .public) layers")
        case let .failure(error):
            windowStates[windowOid] = .unavailable
            #log(.default, "LayerArchive - window \(windowOid, privacy: .public) stays with the Server's screenshots: \(String(describing: error), privacy: .public)")
        }
        serverDrawnDescendantsByItem.removeAll()
        if !hasPendingArchives {
            resumeSettleWaiters()
        }
        archivesDidSettle?()
    }

    /// Tells each node of `window` that a portal draws elsewhere while
    /// hiding it in place the portal's node, after which the preview orders
    /// it — how an `NSGlassEffectView`'s content comes out in front of its
    /// glass. A portal that is no node of its own counts as the nearest node
    /// above it; a layer two nodes share (a view and its BackingLayer node)
    /// counts as the outer one. Links from an older archive go.
    private func linkingPortalSources(in window: DisplayItem, from archive: LiveLayerArchive) {
        var itemsByLayerOid: [UInt: DisplayItem] = [:]
        window.enumerateSelfAndChildren { item in
            item.previewPortalItem = nil
            guard let oid = item.layerObject?.oid, oid != 0, itemsByLayerOid[oid] == nil else { return }
            itemsByLayerOid[oid] = item
        }
        for (source, portal) in XcodeViewHierarchyPixelRecovery.portalsHidingTheirSources(in: archive.layers) {
            guard let sourceItem = itemsByLayerOid[archive.oid(of: source)] else { continue }
            var holder: CALayer? = portal
            var portalItem: DisplayItem?
            while let candidate = holder, portalItem == nil {
                portalItem = itemsByLayerOid[archive.oid(of: candidate)]
                holder = candidate.superlayer
            }
            guard let portalItem, portalItem !== sourceItem else { continue }
            sourceItem.previewPortalItem = portalItem
        }
    }

    private func resumeSettleWaiters() {
        let waiters = settleWaiters
        settleWaiters.removeAll()
        for waiter in waiters {
            waiter.resume()
        }
    }

    private func reset() {
        generation += 1
        isActive = false
        fetchQueue.removeAll()
        fetchingWindowOid = nil
        windowsToFetchAgain.removeAll()
        // The windows of the old tree are gone; nobody draws from them.
        let completions = refetchCompletions.values.flatMap { $0 }
        refetchCompletions.removeAll()
        for completion in completions {
            completion(false)
        }
        windowStates.removeAll()
        resumeSettleWaiters()
        waitingJobs.removeAll()
        drawnKeys.removeAll()
        nodeLayerOidsByWindow.removeAll()
        windowItemsByOid.removeAll()
        glassLayerOidsByWindow.removeAll()
        serverDrawnDescendantsByItem.removeAll()
        // A drawing on the work queue finishes into the old generation and
        // is dropped. Whoever waits for the images hears on a later turn,
        // once the reload that called this is over.
        DispatchQueue.main.async { [weak self] in
            self?.drawNext()
        }
    }

    // MARK: - Who draws an image

    /// Who draws `kind` of `item`'s images.
    func imageSource(_ kind: LiveLayerArchive.ImageKind, of item: DisplayItem) -> ImageSource {
        guard isActive, Self.mayBeDrawnFromArchive(item),
              let layerOid = item.layerObject?.oid, layerOid != 0,
              let window = Self.window(of: item),
              let windowOid = window.windowObject?.oid,
              let state = windowStates[windowOid]
        else {
            return .server
        }
        switch state {
        case .pending:
            return .pendingArchive
        case .unavailable:
            return .server
        case let .ready(archive):
            guard archive.layer(withOid: layerOid) != nil else {
                return .server
            }
            if kind == .solo, hasServerDrawnDescendant(item, in: archive) {
                return .server
            }
            return .archive(archive, nodeLayers(of: item, layerOid: layerOid, window: window, windowOid: windowOid))
        }
    }

    /// A node with pixels of its own and a layer: not a window (its image is
    /// the window's real screenshot), not a SwiftUI or other custom node.
    private static func mayBeDrawnFromArchive(_ item: DisplayItem) -> Bool {
        guard item.isPixelBearing(), !item.isUserCustom() else { return false }
        switch item.resolvedNodeKind() {
        case .window, .windowScene:
            return false
        default:
            return true
        }
    }

    private static func window(of item: DisplayItem) -> DisplayItem? {
        var current: DisplayItem? = item
        while let candidate = current {
            if candidate.resolvedNodeKind() == .window {
                return candidate
            }
            current = candidate.super
        }
        return nil
    }

    private func nodeLayers(of item: DisplayItem, layerOid: UInt, window: DisplayItem, windowOid: UInt) -> LiveLayerArchive.NodeLayers {
        let windowNodeLayerOids: Set<UInt>
        if let known = nodeLayerOidsByWindow[windowOid] {
            windowNodeLayerOids = known
        } else {
            windowNodeLayerOids = Self.layerOids(under: window)
            nodeLayerOidsByWindow[windowOid] = windowNodeLayerOids
        }
        var hiddenGlassLayerOids: Set<UInt> = []
        if hidesGlassLayers {
            if let known = glassLayerOidsByWindow[windowOid] {
                hiddenGlassLayerOids = known
            } else {
                window.enumerateSelfAndChildren { node in
                    if node.isGlassLayer(), let oid = node.layerObject?.oid, oid != 0 {
                        hiddenGlassLayerOids.insert(oid)
                    }
                }
                glassLayerOidsByWindow[windowOid] = hiddenGlassLayerOids
            }
        }
        return LiveLayerArchive.NodeLayers(
            layerOid: layerOid,
            subtreeLayerOids: Self.layerOids(under: item),
            windowNodeLayerOids: windowNodeLayerOids,
            hiddenGlassLayerOids: hiddenGlassLayerOids
        )
    }

    /// The layer oids of `item` and of every node below it.
    private static func layerOids(under item: DisplayItem) -> Set<UInt> {
        var oids: Set<UInt> = []
        item.enumerateSelfAndChildren { node in
            if let oid = node.layerObject?.oid, oid != 0 {
                oids.insert(oid)
            }
        }
        return oids
    }

    /// Whether a node below `item` gets its pixels from the Server's
    /// screenshots — a SwiftUI node, a view without a layer of its own, a
    /// layer the archive lacks. Those pixels sit in layers no node owns, so
    /// `item`'s solo image from the archive would draw them a second time:
    /// its solo image comes from the Server too.
    private func hasServerDrawnDescendant(_ item: DisplayItem, in archive: LiveLayerArchive) -> Bool {
        let key = ObjectIdentifier(item)
        if let known = serverDrawnDescendantsByItem[key] {
            return known
        }
        var found = false
        for subitem in item.subitems ?? [] where !found {
            subitem.enumerateSelfAndChildren { node in
                guard !found, node.isPixelBearing(), node.doNotFetchScreenshotReason == .fetchScreenshotPermitted else { return }
                if node.isUserCustom() {
                    found = node.customInfo?.detailHasScreenshots == true
                } else {
                    let oid = node.layerObject?.oid ?? 0
                    found = oid == 0 || archive.layer(withOid: oid) == nil
                }
            }
        }
        serverDrawnDescendantsByItem[key] = found
        return found
    }

    // MARK: - Drawing

    /// Draws `kind` of `item`'s image from `archive` and puts it on the node,
    /// unless it was drawn already or waits to be; a waiting one moves up to
    /// `priority` when that is sooner. `again` draws it even so, from this
    /// archive: the app changed. `completion` hears the image, nil when it
    /// came out empty or was drawn before.
    func drawImage(
        _ kind: LiveLayerArchive.ImageKind,
        of item: DisplayItem,
        archive: LiveLayerArchive,
        nodes: LiveLayerArchive.NodeLayers,
        priority: Priority,
        again: Bool = false,
        completion: (@MainActor (NSImage?) -> Void)? = nil
    ) {
        let key = ImageKey(item: ObjectIdentifier(item), kind: kind)
        if let index = waitingJobs.firstIndex(where: { $0.key == key }) {
            var job = waitingJobs.remove(at: index)
            if again {
                job = Job(key: key, item: item, archive: archive, nodes: nodes, priority: priority, completions: job.completions)
            }
            job.priority = min(job.priority, priority)
            if let completion {
                job.completions.append(completion)
            }
            enqueue(job)
        } else if again || (!drawnKeys.contains(key) && drawingJob?.key != key) {
            drawnKeys.remove(key)
            var job = Job(key: key, item: item, archive: archive, nodes: nodes, priority: priority)
            if let completion {
                job.completions.append(completion)
            }
            enqueue(job)
        } else if let completion {
            if drawingJob?.key == key {
                drawingJob?.completions.append(completion)
            } else {
                completion(nil)
            }
            return
        } else {
            return
        }
        drawNext()
    }

    /// Forgets `kind` of `item`'s image: it is drawn again when next asked
    /// for. A waiting drawing of it is dropped.
    func forgetImage(_ kind: LiveLayerArchive.ImageKind, of item: DisplayItem) {
        let key = ImageKey(item: ObjectIdentifier(item), kind: kind)
        drawnKeys.remove(key)
        waitingJobs.removeAll { $0.key == key }
    }

    /// Whether `kind` of `item`'s image was drawn from an archive, or waits
    /// to be.
    func hasDrawnOrQueued(_ kind: LiveLayerArchive.ImageKind, of item: DisplayItem) -> Bool {
        let key = ImageKey(item: ObjectIdentifier(item), kind: kind)
        return drawnKeys.contains(key) || drawingJob?.key == key || waitingJobs.contains { $0.key == key }
    }

    /// Whether images are waiting or being drawn.
    var isDrawingImages: Bool {
        drawingJob != nil || !waitingJobs.isEmpty
    }

    /// Runs `action` once every image asked for so far is drawn, or at the
    /// next reload.
    func whenImagesAreDrawn(_ action: @escaping @MainActor () -> Void) {
        guard isDrawingImages else {
            action()
            return
        }
        idleWaiters.append(action)
    }

    private func enqueue(_ job: Job) {
        let index = waitingJobs.firstIndex { job.priority < $0.priority } ?? waitingJobs.endIndex
        waitingJobs.insert(job, at: index)
    }

    private func drawNext() {
        guard drawingJob == nil else { return }
        guard !waitingJobs.isEmpty else {
            runIdleWaiters()
            return
        }
        let job = waitingJobs.removeFirst()
        drawingJob = job
        let generation = generation
        let work = UncheckedSendable(value: (archive: job.archive, nodes: job.nodes, kind: job.key.kind))
        Self.workQueue.async { [weak self] in
            let image = work.value.archive.image(of: work.value.kind, for: work.value.nodes)
            let size = work.value.archive.layer(withOid: work.value.nodes.layerOid)?.bounds.size ?? .zero
            let result = UncheckedSendable(value: (image: image, size: size))
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self?.finishDrawing(image: result.value.image, size: result.value.size, generation: generation)
                }
            }
        }
    }

    private func finishDrawing(image: CGImage?, size: CGSize, generation: Int) {
        let job = drawingJob
        drawingJob = nil
        var screenshot: NSImage?
        if generation == self.generation, let job {
            drawnKeys.insert(job.key)
            if let image, let item = job.item {
                screenshot = NSImage(cgImage: image, size: size)
                switch job.key.kind {
                case .group:
                    item.groupScreenshot = screenshot
                case .solo:
                    item.soloScreenshot = screenshot
                }
            }
        }
        for completion in job?.completions ?? [] {
            completion(screenshot)
        }
        drawNext()
    }

    private func runIdleWaiters() {
        let waiters = idleWaiters
        idleWaiters.removeAll()
        for waiter in waiters {
            waiter()
        }
    }
}
