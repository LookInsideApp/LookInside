import AppKit
import RunningApplicationKit

/// Attach to an app running on an attached iOS device, driven from this Mac.
///
/// The counterpart to `LKInjectionFlow`, which does the same thing for a
/// process on this Mac. The two are kept apart because almost nothing is
/// shared: the Mac path has to register and get approval for a privileged
/// daemon, download an injectable framework, and then ask the daemon to load
/// it. Here the device carries its own payload and does its own injecting, so
/// this side only asks.
///
/// Why it exists at all, beyond saving a trip to the phone: picking the target
/// **on** the phone necessarily sends that target to the background, and both
/// of the connection-layer bugs recorded in
/// `docs/monorepo/lookinside-ios-injector-mac-control-plan.md` are triggered by
/// exactly that — the server's listening socket can be lost for good, and this
/// host caches a dead channel it never drops. Driven from here the target never
/// leaves the foreground, so the ordinary path stops running into them. They
/// are still bugs and still need fixing; this just stops them being hit every
/// single time.
@objc(LKDeviceInjectionFlow)
final class LKDeviceInjectionFlow: NSObject {
    @objc(sharedInstance) static let shared = LKDeviceInjectionFlow()

    private var picker: LKInjectionTargetPicker?
    private var startGate = LKInjectionStartGate()

    /// One reachable injector, with what it said about itself.
    private struct ReachableDevice {
        let client: LKDeviceControlClient
        let capability: LKDeviceControlCapability
    }

    @objc func startFromWindow(_ window: NSWindow?) {
        let decision = startGate.begin {
            LKSwiftUISupportGatekeeper.sharedInstance().canUseProtectedFeatureWithoutPrompt()
        }
        guard decision == .started else { return }

        Task { @MainActor in
            await self.runFlow(presentingWindow: window)
            self.startGate.finish()
        }
    }

    @MainActor
    private func runFlow(presentingWindow window: NSWindow?) async {
        await LKAttachedDeviceMonitor.shared.startAndWaitForInitialDevices()
        let attachedDevices = LKAttachedDeviceMonitor.shared.devices
        guard !attachedDevices.isEmpty else {
            presentMessage(
                title: NSLocalizedString("No Device Connected", comment: ""),
                body: NSLocalizedString(
                    "Connect an iPhone or iPad over USB, trust this Mac on the device, and try again.",
                    comment: ""
                ),
                window: window
            )
            return
        }

        let (reachable, unreachable) = await probe(attachedDevices)
        defer {
            for device in reachable {
                device.client.close()
            }
        }

        let usable = reachable.filter { $0.capability.isAvailable }
        guard !usable.isEmpty else {
            presentMessage(
                title: NSLocalizedString("No Injector Available", comment: ""),
                body: Self.explanation(forNoUsableDeviceAmong: reachable, unreachable: unreachable),
                window: window
            )
            return
        }

        guard let chosen = await chooseDevice(among: usable, window: window) else { return }

        guard let target = await pickTarget(on: chosen.client, window: window) else { return }

        let result: LKDeviceControlInjectionResult
        do {
            result = try await chosen.client.injectIntoProcess(withIdentifier: target.processIdentifier)
        } catch {
            presentAlert(error: error, window: window)
            return
        }

        guard result.isInjected else {
            presentMessage(
                title: NSLocalizedString("Could Not Attach", comment: ""),
                body: result.failureReason ?? NSLocalizedString("The injector gave no reason.", comment: ""),
                window: window
            )
            return
        }

        // The device's server binds one of 47175–47179, which this host already
        // probes for every attached device, and the Launch window re-polls every
        // 1.5 seconds. So there is nothing to wire up — only a moment to wait
        // before saying so, the same allowance the Mac path makes.
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        presentMessage(
            title: NSLocalizedString("Attached", comment: ""),
            body: String(
                format: NSLocalizedString(
                    "LookInsideServer was injected into %@ on the device. It should appear in the Launch list shortly.",
                    comment: ""
                ),
                target.name
            ),
            window: window
        )
    }

    // MARK: - Finding an injector

    /// Connects to every attached device and asks each whether it can inject.
    ///
    /// Sequential rather than concurrent. The common case is one device, and
    /// each probe is a connect plus one round trip over a cable — making the
    /// rare two-device case marginally faster is not worth running several
    /// `@MainActor` clients through a task group for.
    @MainActor
    private func probe(
        _ attachedDevices: [LKAttachedDeviceMonitor.Device]
    ) async -> (reachable: [ReachableDevice], unreachable: [LKAttachedDeviceMonitor.Device]) {
        var reachable: [ReachableDevice] = []
        var unreachable: [LKAttachedDeviceMonitor.Device] = []
        for attachedDevice in attachedDevices {
            let client = LKDeviceControlClient(
                deviceIdentifier: attachedDevice.identifier,
                serialNumber: attachedDevice.serialNumber,
                usbHub: LKAttachedDeviceMonitor.shared.connectionHub
            )
            do {
                try await client.connect()
                reachable.append(ReachableDevice(client: client, capability: try await client.injectionCapability()))
            } catch {
                // A refused connection is the ordinary answer for a device that
                // has never had the injector opened, so it is not reported as a
                // failure of its own — it only shapes the message below when
                // *no* device turns out to be usable.
                client.close()
                unreachable.append(attachedDevice)
            }
        }
        return (reachable, unreachable)
    }

    /// What to tell the user when nothing can be injected into.
    ///
    /// A device that answered and said no gets its own words shown: those name
    /// the missing entitlement, or the absent payload, or the fact that it
    /// cannot stay resident in the background — and each has a different
    /// remedy. A device that never answered gets the generic instruction,
    /// because "connection refused" is exactly what a device with no injector
    /// installed and a device with the injector not yet opened both produce.
    private static func explanation(
        forNoUsableDeviceAmong reachable: [ReachableDevice],
        unreachable: [LKAttachedDeviceMonitor.Device]
    ) -> String {
        let refusals = reachable.compactMap { device in
            device.capability.unsupportedReason.map { "\(device.client.serialNumber):\n\($0)" }
        }
        if !refusals.isEmpty {
            return refusals.joined(separator: "\n\n")
        }
        return String(
            format: NSLocalizedString(
                "LookInside could not reach an injector on %d connected device(s).\n\nInstall the LookInside Injector app on the device and open it once. It stays reachable in the background after that, until the device restarts.",
                comment: ""
            ),
            unreachable.count
        )
    }

    /// Which device to use, asking only when there is a choice to make.
    @MainActor
    private func chooseDevice(among usable: [ReachableDevice], window: NSWindow?) async -> ReachableDevice? {
        guard usable.count > 1 else { return usable.first }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Which Device?", comment: "")
        alert.informativeText = NSLocalizedString(
            "More than one connected device has a LookInside Injector ready.",
            comment: ""
        )
        let devicePopUp = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 320, height: 25), pullsDown: false)
        for device in usable {
            devicePopUp.addItem(withTitle: device.client.serialNumber)
        }
        alert.accessoryView = devicePopUp
        alert.addButton(withTitle: NSLocalizedString("Continue", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.buttons.first?.keyEquivalent = "\r"

        let response: NSApplication.ModalResponse
        if let window {
            response = await alert.beginSheetModal(for: window)
        } else {
            response = alert.runModal()
        }
        guard response == .alertFirstButtonReturn else { return nil }
        let selectedIndex = devicePopUp.indexOfSelectedItem
        guard usable.indices.contains(selectedIndex) else { return nil }
        return usable[selectedIndex]
    }

    // MARK: - Picking a target

    private struct Target {
        let processIdentifier: pid_t
        let name: String
    }

    @MainActor
    private func pickTarget(on client: LKDeviceControlClient, window: NSWindow?) async -> Target? {
        // What the device last said, kept for two things the picker needs: an
        // answer for `shouldSelect` ready before the first click, and
        // something to show when a *refresh* fails.
        let snapshot = LKDeviceProcessSnapshot()

        let itemSource = AnyRunningItemSource<RunningProcess> {
            do {
                let processes = try await client.processList()
                snapshot.record(processes)
                return processes.map(RunningProcess.init(deviceProcess:))
            } catch {
                // A failed *refresh* must not empty a list the user is reading,
                // and must not be reported as a failure either — the picker's
                // failure handler closes the sheet, so a single dropped poll
                // would yank it out from under them. The first load has nothing
                // to fall back on, so that one does throw and does get shown.
                guard let lastKnown = snapshot.lastKnownProcesses() else { throw error }
                snapshot.markStale()
                return lastKnown.map(RunningProcess.init(deviceProcess:))
            }
        }

        return await withCheckedContinuation { continuation in
            let picker = LKInjectionTargetPicker(
                deviceName: client.serialNumber,
                processItemSource: itemSource,
                refusalReasonForProcess: { processIdentifier in
                    snapshot.refusalReason(forProcessWithIdentifier: processIdentifier)
                }
            )
            self.picker = picker

            // The device's process table changes while the sheet is open — the
            // whole point of driving this from the Mac is that the user is not
            // touching the phone, so an app they launch there has to turn up
            // here without them reopening anything. Matches the cadence the
            // library's own local picker uses, which a measured round trip of
            // 70–100 ms over USB easily affords.
            let refreshTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
                guard let self, let picker = self.picker else {
                    timer.invalidate()
                    return
                }
                // Stop polling a channel that has already failed once rather
                // than hammering it; the list stays on screen, and picking a
                // row will surface the real error.
                guard !snapshot.isStale else {
                    timer.invalidate()
                    return
                }
                picker.reloadProcesses()
            }

            var hasResumed = false
            let finish: (Target?) -> Void = { [weak self] target in
                guard !hasResumed else { return }
                hasResumed = true
                refreshTimer.invalidate()
                self?.picker = nil
                continuation.resume(returning: target)
            }

            picker.onConfirm = { processIdentifier, name in
                finish(Target(processIdentifier: processIdentifier, name: name))
            }
            picker.onCancel = {
                finish(nil)
            }
            picker.onProcessListFailure = { [weak self] error in
                guard !hasResumed else { return }
                self?.presentAlert(error: error, window: window)
                finish(nil)
            }
            picker.present(in: window)
        }
    }

    // MARK: - Alerts

    @MainActor
    private func presentMessage(title: String, body: String, window: NSWindow?) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        if let window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }

    @MainActor
    private func presentAlert(error: any Error, window: NSWindow?) {
        let alert = NSAlert(error: error)
        if let window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
}

/// What the device last reported, kept while a picker is open.
///
/// A reference type with its own lock rather than state on the flow: the
/// picker's item source is a `@Sendable` closure, so it cannot reach into
/// main-actor state to record what it fetched, and both readers — the
/// `shouldSelect` callback and the refresh timer — arrive on the main thread.
private final class LKDeviceProcessSnapshot: @unchecked Sendable {
    private let lock = NSLock()
    private var processes: [LKDeviceControlProcess]?
    private var refusalByProcessIdentifier: [pid_t: String] = [:]
    private var hasFailedARefresh = false

    func record(_ processes: [LKDeviceControlProcess]) {
        lock.lock()
        defer { lock.unlock() }
        self.processes = processes
        refusalByProcessIdentifier = processes.reduce(into: [:]) { result, process in
            if let reason = process.injectability.refusalReason {
                result[process.processIdentifier] = reason
            }
        }
    }

    /// The last list the device sent, or `nil` if it has never answered — which
    /// is what separates a refresh worth absorbing from a first load worth
    /// reporting.
    func lastKnownProcesses() -> [LKDeviceControlProcess]? {
        lock.lock()
        defer { lock.unlock() }
        return processes
    }

    func markStale() {
        lock.lock()
        defer { lock.unlock() }
        hasFailedARefresh = true
    }

    var isStale: Bool {
        lock.lock()
        defer { lock.unlock() }
        return hasFailedARefresh
    }

    /// Why this row cannot be picked, or `nil` when it can.
    ///
    /// An identifier nobody recorded answers `nil` — pickable. That is the
    /// right direction here, unlike in a list of local processes: the device
    /// only sends rows it is willing to be asked about, and the injection
    /// attempt is the authority anyway.
    func refusalReason(forProcessWithIdentifier processIdentifier: pid_t) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return refusalByProcessIdentifier[processIdentifier]
    }
}

private extension RunningProcess {
    /// A picker row describing a process on an attached device.
    ///
    /// Four fields are left empty rather than guessed. There is no icon to
    /// fetch for a process on another machine; every process on one iOS device
    /// shares an architecture, so a column for it would distinguish nothing;
    /// the injector does not report sandbox status, and `false` renders as *no
    /// badge*, which is the honest showing of "not reported"; and `platform`
    /// exists to tell simulator processes from host ones on a Mac, a question
    /// that does not arise here.
    ///
    /// The bundle identifier goes in `executablePath` because the Processes tab
    /// has no bundle-identifier column, and on an iOS device the bundle
    /// identifier is what tells two similarly-named apps apart — far more
    /// useful than a path that always ends in the display name again.
    init(deviceProcess: LKDeviceControlProcess) {
        self.init(
            processIdentifier: deviceProcess.processIdentifier,
            name: deviceProcess.name,
            executablePath: deviceProcess.bundleIdentifier ?? deviceProcess.executablePath
        )
    }
}
