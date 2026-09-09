import AppKit
import Combine

/// One capture belongs to one inspection window and one Peertalk channel.
/// ObservableObject supports the host's macOS 13 deployment target.
@MainActor
final class LKGestureDebugSession: ObservableObject {
    @Published private(set) var snapshots: [LKGestureCaptureSnapshot] = []
    @Published private(set) var records: [LKGestureCaptureRecord] = []
    @Published private(set) var isRunning = false
    @Published private(set) var isStarting = false
    @Published private(set) var state = "stopped"
    @Published var message = "Start capture, then interact with a SwiftUI gesture in the target app."
    @Published private(set) var recordCount = 0
    @Published private(set) var redactedCount = 0
    @Published private(set) var droppedCount = 0
    @Published private(set) var pollDurationMS = 0.0
    @Published var selectedSnapshotID: String?
    @Published var selectedNodeID: String?
    @Published var followsLatest = true
    @Published var overlayEnabled = true
    @Published private(set) var overlayStatus: LKGestureOverlayStatus?
    @Published private(set) var appName = "No target"
    @Published private(set) var supported = false

    private var app: LKInspectableApp?
    private var channel: Lookin_PTChannel?
    private var sessionID: String?
    private var lastSessionID: String?
    private var lastBatchSequence = 0
    private var startTask: Task<Void, Never>?
    private var subscriptions: [RACDisposable] = []

    var selectedSnapshot: LKGestureCaptureSnapshot? {
        snapshots.first { $0.id == selectedSnapshotID }
    }

    init() {
        let manager = LKConnectionManager.sharedInstance()
        if let disposable = manager?.didReceivePush?.subscribeNext({ [weak self] value in
            guard let tuple = value as? RACTuple,
                  let channel = tuple.first as? Lookin_PTChannel,
                  (tuple.second as? NSNumber)?.uint32Value == 306,
                  let data = tuple.third as? Data else { return }
            Task { @MainActor [weak self] in self?.receive(data, from: channel) }
        }) {
            subscriptions.append(disposable)
        }
        if let disposable = manager?.channelWillEnd?.subscribeNext({ [weak self] value in
            guard let ended = value as? Lookin_PTChannel else { return }
            Task { @MainActor [weak self] in
                guard let self, self.channel === ended else { return }
                self.stop()
                self.message = "The target disconnected. Reconnect it, then start a new capture."
                self.state = "disconnected"
                self.supported = false
            }
        }) {
            subscriptions.append(disposable)
        }
    }

    func bind(to app: LKInspectableApp?) {
        guard self.app !== app || channel !== app?.channel else { return }
        stop()
        self.app = app
        channel = app?.channel
        appName = app?.appInfo?.appName ?? "No target"
        supported = (app?.appInfo?.gestureDebugProtocolVersion ?? 0) >= 1
        snapshots.removeAll()
        records.removeAll()
        selectedSnapshotID = nil
        selectedNodeID = nil
        message = supported
            ? "Start capture, then interact with a SwiftUI gesture in the target app."
            : "This target needs a Server with Gesture Debug support (iOS 16+ or macOS 13+)."
    }

    func start(window: NSWindow?) {
        guard supported, !isRunning, !isStarting, let app else { return }
        guard LKSwiftUISupportGatekeeper.sharedInstance().allowProtectedFeatureAccess(for: window) else { return }
        let token = UUID().uuidString
        sessionID = token
        lastSessionID = token
        lastBatchSequence = 0
        recordCount = 0
        redactedCount = 0
        droppedCount = 0
        overlayStatus = nil
        snapshots.removeAll()
        records.removeAll()
        selectedSnapshotID = nil
        selectedNodeID = nil
        followsLatest = true
        isStarting = true
        state = "starting"
        message = "Starting gesture capture…"
        startTask = Task { [weak self] in
            do {
                let response: NSDictionary = try await LKMCPBridgeRACBridge.awaitFirstValue(
                    of: app.controlGestureDebug(["command": "start", "sessionID": token, "overlay": self?.overlayEnabled ?? true])
                )
                guard let self, sessionID == token, !Task.isCancelled else { return }
                state = response["state"] as? String ?? "waiting"
                isStarting = state == "starting"
                isRunning = !isStarting
                message = isStarting ? "Preparing the system log store…" : "Waiting for SwiftUI events. Interact with the target app."
            } catch {
                guard let self, sessionID == token else { return }
                stop()
                state = "error"
                message = error.localizedDescription
            }
        }
    }

    func stop() {
        let token = sessionID
        sessionID = nil
        startTask?.cancel()
        startTask = nil
        isRunning = false
        isStarting = false
        overlayStatus = nil
        state = "stopped"
        if token != nil {
            message = "Capture stopped. Recorded events remain available."
        }
        guard let token, let app else { return }
        // The stop request must outlive the panel that initiated it.
        Task { [weak self] in
            do {
                let _: NSDictionary = try await LKMCPBridgeRACBridge.awaitFirstValue(
                    of: app.controlGestureDebug(["command": "stop", "sessionID": token])
                )
            } catch {
                if self?.sessionID == nil, self?.channel === app.channel {
                    self?.message = "Could not confirm capture stopped: \(error.localizedDescription). Disconnect the target to end capture."
                }
            }
        }
    }

    func updateOverlay() {
        sendOverlayControl(clear: false)
    }

    func clearBorders() {
        guard overlayStatus?.mode == "persistentObserved" else { return }
        sendOverlayControl(clear: true)
    }

    private func sendOverlayControl(clear: Bool) {
        guard let app, let token = sessionID, isRunning || isStarting else { return }
        let enabled = overlayEnabled
        Task { [weak self] in
            do {
                let _: NSDictionary = try await LKMCPBridgeRACBridge.awaitFirstValue(
                    of: app.controlGestureDebug(["command": "overlay", "sessionID": token, "enabled": enabled, "clear": clear])
                )
            } catch {
                guard self?.sessionID == token else { return }
                self?.message = error.localizedDescription
            }
        }
    }

    func followLatest() {
        if followsLatest {
            selectedSnapshotID = snapshots.last?.id
        }
    }

    func selectSnapshot(_ id: String?) {
        selectedSnapshotID = id
        selectedNodeID = nil
        followsLatest = id == snapshots.last?.id
    }

    func archiveData() throws -> Data {
        let archive = LKGestureCaptureArchive(
            appName: appName, bundleIdentifier: app?.appInfo?.appBundleIdentifier ?? "",
            sessionID: lastSessionID, snapshots: snapshots, records: records
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }

    func dispose() {
        stop()
        for subscription in subscriptions {
            subscription.dispose()
        }
        subscriptions.removeAll()
    }

    private func receive(_ data: Data, from channel: Lookin_PTChannel) {
        guard channel === self.channel, let sessionID, data.count <= 4 * 1024 * 1024 else { return }
        do {
            let batch = try JSONDecoder().decode(LKGestureCaptureBatch.self, from: data)
            guard batch.schemaVersion == 1, batch.sessionID == sessionID,
                  batch.sequence > lastBatchSequence else { return }
            let gap = lastBatchSequence > 0 && batch.sequence != lastBatchSequence + 1
            lastBatchSequence = batch.sequence
            recordCount = batch.recordCount
            redactedCount = batch.redactedCount
            droppedCount = batch.droppedCount
            pollDurationMS = batch.pollDurationMS
            overlayStatus = batch.overlayStatus
            state = batch.state
            isStarting = state == "starting"
            isRunning = state == "waiting" || state == "capturing" || state == "redacted"
            message = gap ? "A capture batch was lost. Some event details may be incomplete." : batch.message
            if batch.state == "stopped" || batch.state == "error" {
                isRunning = false
                isStarting = false
                self.sessionID = nil
            }
            records.append(contentsOf: batch.records)
            if records.count > 2000 {
                records.removeFirst(records.count - 2000)
            }
            snapshots.append(contentsOf: batch.snapshots)
            if snapshots.count > 64 {
                snapshots.removeFirst(snapshots.count - 64)
            }
            if followsLatest {
                if let latest = snapshots.last?.id, selectedSnapshotID != latest {
                    selectedSnapshotID = latest
                    selectedNodeID = nil
                }
            } else if !snapshots.contains(where: { $0.id == selectedSnapshotID }) {
                selectedSnapshotID = snapshots.first?.id
                selectedNodeID = nil
            }
        } catch {
            message = "Could not decode the target's gesture capture: \(error.localizedDescription)"
            state = "error"
        }
    }
}
