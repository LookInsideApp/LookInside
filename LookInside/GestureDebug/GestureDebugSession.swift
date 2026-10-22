import AppKit
import Combine

/// One capture belongs to one inspection window and one channel.
@MainActor
final class GestureDebugSession: ObservableObject {
    @Published private(set) var snapshots: [GestureCaptureSnapshot] = []
    @Published private(set) var records: [GestureCaptureRecord] = []
    @Published private(set) var isRunning = false
    @Published private(set) var isStarting = false
    @Published private(set) var state = "stopped"
    @Published var message = NSLocalizedString("Start capture, then interact with a SwiftUI gesture in the target app.", comment: "")
    @Published private(set) var recordCount = 0
    @Published private(set) var redactedCount = 0
    @Published private(set) var droppedCount = 0
    @Published private(set) var pollDurationMS = 0.0
    @Published var selectedSnapshotID: String?
    @Published var selectedNodeID: String?
    @Published var followsLatest = true
    @Published var overlayEnabled = true
    @Published private(set) var overlayStatus: GestureOverlayStatus?
    @Published private(set) var nativeRegions: [NativeInteractionRegion] = []
    @Published private var lastNativeRegions: [NativeInteractionRegion] = []
    @Published private(set) var suggestions = HitTargetSuggestionReport()
    @Published private(set) var suggestionPlatform = HitTargetSuggestionPlatform.unsupported
    private var lastInteractions: InteractionSnapshot?
    @Published private(set) var appName = NSLocalizedString("No target", comment: "")
    @Published private(set) var supported = false

    private var app: InspectableApp?
    private var channel: ServerChannel?
    private var sessionID: String?
    private var lastSessionID: String?
    private var lastBatchSequence = 0
    private var startTask: Task<Void, Never>?
    private var subscriptions: [Task<Void, Never>] = []

    var selectedSnapshot: GestureCaptureSnapshot? {
        snapshots.first { $0.id == selectedSnapshotID }
    }

    var canExport: Bool {
        !records.isEmpty || !snapshots.isEmpty || !lastNativeRegions.isEmpty || lastInteractions?.targets.isEmpty == false
    }

    init() {
        let manager = ConnectionManager.shared
        let pushes = manager.pushEvents()
        subscriptions.append(Task { [weak self] in
            for await push in pushes {
                guard push.type == UInt32(LookinPush_GestureDebug), let data = push.data as? Data else { continue }
                self?.receive(data, from: push.channel)
            }
        })
        let endedChannels = manager.channelWillEndEvents()
        subscriptions.append(Task { [weak self] in
            for await ended in endedChannels {
                guard let self, channel === ended else { continue }
                stop()
                message = NSLocalizedString("The target disconnected. Reconnect it, then start a new capture.", comment: "")
                state = "disconnected"
                supported = false
            }
        })
    }

    func bind(to app: InspectableApp?) {
        guard self.app !== app || channel !== app?.channel else { return }
        stop()
        self.app = app
        channel = app?.channel
        appName = app?.appInfo?.appName ?? NSLocalizedString("No target", comment: "")
        if let info = app?.appInfo {
            suggestionPlatform = .resolve(deviceType: info.deviceType.rawValue, model: info.deviceModelIdentifier ?? "",
                                          deviceName: info.deviceDescription ?? "", os: info.osDescription ?? "")
        } else {
            suggestionPlatform = .unsupported
        }
        lastInteractions = nil
        supported = (app?.appInfo?.gestureDebugProtocolVersion ?? 0) >= 1
        snapshots.removeAll()
        records.removeAll()
        lastNativeRegions.removeAll()
        selectedSnapshotID = nil
        selectedNodeID = nil
        message = supported
            ? NSLocalizedString("Start capture, then interact with a SwiftUI gesture in the target app.", comment: "")
            : NSLocalizedString("This target needs a Server with Gesture Debug support (iOS 16+ or macOS 13+).", comment: "")
    }

    func start(window: NSWindow?) {
        guard supported, !isRunning, !isStarting, let app else { return }
        guard SwiftUISupportGatekeeper.sharedInstance().allowProtectedFeatureAccess(for: window) else { return }
        let token = UUID().uuidString
        sessionID = token
        lastSessionID = token
        lastBatchSequence = 0
        recordCount = 0
        redactedCount = 0
        droppedCount = 0
        overlayStatus = nil
        nativeRegions.removeAll()
        lastNativeRegions.removeAll()
        snapshots.removeAll()
        lastInteractions = nil
        suggestions.replace(with: nil, platform: suggestionPlatform, isCapturing: true)
        records.removeAll()
        selectedSnapshotID = nil
        selectedNodeID = nil
        followsLatest = true
        isStarting = true
        state = "starting"
        message = NSLocalizedString("Starting gesture capture…", comment: "")
        startTask = Task { [weak self] in
            do {
                let response = try await app.controlGestureDebug(["command": "start", "sessionID": token, "overlay": self?.overlayEnabled ?? true])
                guard let self, sessionID == token, !Task.isCancelled else { return }
                state = response["state"] as? String ?? "waiting"
                isStarting = state == "starting"
                isRunning = !isStarting
                message = isStarting ? NSLocalizedString("Preparing the system log store…", comment: "") : NSLocalizedString("Waiting for SwiftUI events. Interact with the target app.", comment: "")
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
        nativeRegions.removeAll()
        state = "stopped"
        suggestions.replace(with: nil, platform: suggestionPlatform, isCapturing: false)
        if token != nil {
            message = NSLocalizedString("Capture stopped. Recorded events remain available.", comment: "")
        }
        guard let token, let app else { return }
        // The stop request must outlive the panel that initiated it.
        Task { [weak self] in
            do {
                _ = try await app.controlGestureDebug(["command": "stop", "sessionID": token])
            } catch {
                if self?.sessionID == nil, self?.channel === app.channel {
                    self?.message = String(format: NSLocalizedString("Could not confirm capture stopped: %@. Disconnect the target to end capture.", comment: ""), error.localizedDescription)
                }
            }
        }
    }

    func updateOverlay() {
        sendOverlayControl(clear: false)
    }

    func clearBorders() {
        sendOverlayControl(clear: true)
    }

    private func sendOverlayControl(clear: Bool) {
        guard let app, let token = sessionID, isRunning || isStarting else { return }
        let enabled = overlayEnabled
        Task { [weak self] in
            do {
                _ = try await app.controlGestureDebug(["command": "overlay", "sessionID": token, "enabled": enabled, "clear": clear])
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
        let archive = GestureCaptureArchive(
            appName: appName, bundleIdentifier: app?.appInfo?.appBundleIdentifier ?? "",
            sessionID: lastSessionID, snapshots: snapshots, records: records, nativeRegions: lastNativeRegions,
            interactions: lastInteractions, suggestionPlatform: suggestionPlatform
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }

    func dispose() {
        stop()
        for subscription in subscriptions {
            subscription.cancel()
        }
        subscriptions.removeAll()
    }

    private func receive(_ data: Data, from channel: ServerChannel) {
        guard channel === self.channel, let sessionID, data.count <= 4 * 1024 * 1024 else { return }
        do {
            let batch = try JSONDecoder().decode(GestureCaptureBatch.self, from: data)
            guard batch.schemaVersion == 1, batch.sessionID == sessionID,
                  batch.sequence > lastBatchSequence else { return }
            let gap = lastBatchSequence > 0 && batch.sequence != lastBatchSequence + 1
            lastBatchSequence = batch.sequence
            recordCount = batch.recordCount
            redactedCount = batch.redactedCount
            droppedCount = batch.droppedCount
            pollDurationMS = batch.pollDurationMS
            overlayStatus = batch.overlayStatus
            nativeRegions = batch.nativeRegions ?? []
            if batch.state != "stopped", batch.state != "error" {
                lastNativeRegions = nativeRegions
            }
            state = batch.state
            isStarting = state == "starting"
            isRunning = state == "waiting" || state == "capturing" || state == "redacted"
            suggestions.replace(with: batch.interactions, platform: suggestionPlatform, isCapturing: isRunning || isStarting)
            if isRunning || isStarting {
                lastInteractions = batch.interactions
            }
            message = gap ? NSLocalizedString("A capture batch was lost. Some event details may be incomplete.", comment: "") : batch.message
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
            suggestions.replace(with: nil, platform: suggestionPlatform, isCapturing: isRunning || isStarting)
            message = String(format: NSLocalizedString("Could not decode the target's gesture capture: %@", comment: ""), error.localizedDescription)
            state = "error"
        }
    }
}
