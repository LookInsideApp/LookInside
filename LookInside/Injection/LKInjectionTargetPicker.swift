import AppKit
import RunningApplicationKit

final class LKInjectionTargetPicker: NSObject, RunningPickerTabViewController.Delegate {
    typealias ConfirmHandler = (_ pid: pid_t, _ label: String) -> Void
    typealias CancelHandler = () -> Void

    var onConfirm: ConfirmHandler?
    var onCancel: CancelHandler?

    /// A supplied process list that could not be fetched.
    ///
    /// Only the device path can reach this — enumerating this Mac has nothing
    /// to fail at. Worth surfacing rather than leaving as an empty list, which
    /// says nothing about why it is empty.
    var onProcessListFailure: ((any Error) -> Void)?

    private let tabController: RunningPickerTabViewController
    private let windowTitle: String

    /// Why a row cannot be picked, or `nil` when it can. Only the device path
    /// sets it — on this Mac every running process is a candidate and the
    /// privileged daemon is the one that finds out otherwise.
    private let refusalReasonForProcess: ((pid_t) -> String?)?

    private weak var presentingWindow: NSWindow?
    private var sheetWindow: NSWindow?
    private var standaloneWindow: NSWindow?

    /// A target on this Mac, injected by the privileged daemon.
    override init() {
        let appConfig = RunningPickerTabViewController.ApplicationConfiguration(
            title: NSLocalizedString("Attach to Running App", comment: ""),
            description: NSLocalizedString("Select a running app to inject LookInsideServer into.", comment: ""),
            cancelButtonTitle: NSLocalizedString("Cancel", comment: ""),
            confirmButtonTitle: NSLocalizedString("Attach", comment: ""),
            allowsFields: [.icon, .name, .bundleIdentifier, .pid, .architecture, .sandboxed]
        )
        let processConfig = RunningPickerTabViewController.ProcessConfiguration(
            title: NSLocalizedString("Attach to Running Process", comment: ""),
            description: NSLocalizedString("Select a process to inject LookInsideServer into.", comment: ""),
            cancelButtonTitle: NSLocalizedString("Cancel", comment: ""),
            confirmButtonTitle: NSLocalizedString("Attach", comment: ""),
            allowsFields: [.icon, .name, .pid, .architecture, .executablePath, .sandboxed]
        )
        tabController = RunningPickerTabViewController(
            applicationConfiguration: appConfig,
            processConfiguration: processConfig
        )
        windowTitle = NSLocalizedString("Attach to Running App", comment: "")
        refusalReasonForProcess = nil
        super.init()
        tabController.delegate = self
    }

    /// A target on an attached iOS device, injected by the injector app running
    /// on that device.
    ///
    /// One tab, not two. The Applications tab enumerates *this Mac*, and
    /// offering it beside a phone's process list would invite picking from the
    /// wrong machine — a pid that means nothing where it would be sent. The
    /// library says the same thing in its own documentation for
    /// `processItemSource`.
    ///
    /// The columns drop `architecture` and `sandboxed`: every process on one
    /// iOS device shares an architecture, and the injector does not report
    /// sandbox status, so both would be blank for every row. `bundleIdentifier`
    /// is not offered on the Processes tab at all, which is why the bundle
    /// identifier travels in the `executablePath` column instead — it is the
    /// one field wide enough for it and the one a user scans to tell two copies
    /// of the same app apart.
    init(
        deviceName: String,
        processItemSource: AnyRunningItemSource<RunningProcess>,
        refusalReasonForProcess: @escaping (pid_t) -> String?
    ) {
        let processConfig = RunningPickerTabViewController.ProcessConfiguration(
            title: String(
                format: NSLocalizedString("Attach to App on %@", comment: "iOS device serial number"),
                deviceName
            ),
            description: NSLocalizedString(
                "Select an app running on the device. The device injects LookInsideServer into it without bringing the injector to the foreground, so the app you pick never leaves the screen.",
                comment: ""
            ),
            cancelButtonTitle: NSLocalizedString("Cancel", comment: ""),
            confirmButtonTitle: NSLocalizedString("Attach", comment: ""),
            allowsFields: [.name, .pid, .executablePath]
        )
        tabController = RunningPickerTabViewController(
            configuration: .init(tabs: [.processes]),
            processConfiguration: processConfig,
            processItemSource: processItemSource
        )
        windowTitle = String(
            format: NSLocalizedString("Attach to App on %@", comment: "iOS device serial number"),
            deviceName
        )
        self.refusalReasonForProcess = refusalReasonForProcess
        super.init()
        tabController.delegate = self
    }

    func present(in window: NSWindow?) {
        presentingWindow = window
        let panel = NSWindow(contentViewController: tabController)
        panel.title = windowTitle
        panel.setContentSize(NSSize(width: 800, height: 600))
        if let window {
            window.beginSheet(panel) { _ in }
            sheetWindow = panel
        } else {
            panel.center()
            panel.makeKeyAndOrderFront(nil)
            standaloneWindow = panel
        }
    }

    private func dismiss() {
        if let sheetWindow, let presentingWindow {
            presentingWindow.endSheet(sheetWindow)
            self.sheetWindow = nil
        } else if let standaloneWindow {
            standaloneWindow.close()
            self.standaloneWindow = nil
        }
    }

    // MARK: - RunningPickerTabViewController.Delegate

    func runningPickerTabViewController(_: RunningPickerTabViewController, shouldSelectApplication application: RunningApplication) -> Bool {
        application.bundleIdentifier != Bundle.main.bundleIdentifier
    }

    func runningPickerTabViewController(_: RunningPickerTabViewController, didConfirmApplication application: RunningApplication) {
        dismiss()
        onConfirm?(application.processIdentifier, application.name)
    }

    func runningPickerTabViewController(_: RunningPickerTabViewController, shouldSelectProcess process: RunningProcess) -> Bool {
        if let refusalReasonForProcess {
            // The device's verdict, which this Mac cannot work out for itself:
            // only the device knows its own uid and the target's.
            return refusalReasonForProcess(process.processIdentifier) == nil
        }
        return process.processIdentifier != getpid()
    }

    func runningPickerTabViewController(_: RunningPickerTabViewController, didConfirmProcess process: RunningProcess) {
        dismiss()
        onConfirm?(process.processIdentifier, process.name)
    }

    func runningPickerTabViewController(_: RunningPickerTabViewController, didFailToLoadProcesses error: any Error) {
        dismiss()
        onProcessListFailure?(error)
    }

    func runningPickerTabViewControllerWasCancelled(_: RunningPickerTabViewController) {
        dismiss()
        onCancel?()
    }
}
