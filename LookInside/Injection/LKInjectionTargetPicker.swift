import AppKit
import RunningApplicationKit

final class LKInjectionTargetPicker: NSObject, RunningPickerTabViewController.Delegate {
    typealias ConfirmHandler = (_ pid: pid_t, _ label: String) -> Void
    typealias CancelHandler = () -> Void

    var onConfirm: ConfirmHandler?
    var onCancel: CancelHandler?

    private let tabController: RunningPickerTabViewController
    private weak var presentingWindow: NSWindow?
    private var sheetWindow: NSWindow?
    private var standaloneWindow: NSWindow?

    override init() {
        let appConfig = RunningPickerTabViewController.ApplicationConfiguration(
            title: NSLocalizedString("Attach to Running App", comment: ""),
            description: NSLocalizedString("Select a running app to inject LookInsideServer into.", comment: ""),
            cancelButtonTitle: NSLocalizedString("Cancel", comment: ""),
            confirmButtonTitle: NSLocalizedString("Attach", comment: ""),
            allowsColumns: [.icon, .name, .bundleIdentifier, .pid, .architecture, .sandboxed]
        )
        let processConfig = RunningPickerTabViewController.ProcessConfiguration(
            title: NSLocalizedString("Attach to Running Process", comment: ""),
            description: NSLocalizedString("Select a process to inject LookInsideServer into.", comment: ""),
            cancelButtonTitle: NSLocalizedString("Cancel", comment: ""),
            confirmButtonTitle: NSLocalizedString("Attach", comment: ""),
            allowsColumns: [.icon, .name, .pid, .architecture, .executablePath, .sandboxed]
        )
        tabController = RunningPickerTabViewController(
            applicationConfiguration: appConfig,
            processConfiguration: processConfig
        )
        super.init()
        tabController.delegate = self
    }

    func present(in window: NSWindow?) {
        presentingWindow = window
        let panel = NSWindow(contentViewController: tabController)
        panel.title = NSLocalizedString("Attach to Running App", comment: "")
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
        process.processIdentifier != getpid()
    }

    func runningPickerTabViewController(_: RunningPickerTabViewController, didConfirmProcess process: RunningProcess) {
        dismiss()
        onConfirm?(process.processIdentifier, process.name)
    }

    func runningPickerTabViewControllerWasCancelled(_: RunningPickerTabViewController) {
        dismiss()
        onCancel?()
    }
}
