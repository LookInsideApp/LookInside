import AppKit
import Foundation

/// Orchestrates the attach-to-running-app flow:
///
/// 1. `LKInjectableFrameworkInstaller` — ensures LookInsideServer.framework is
///    downloaded under `~/Library/Application Support/LookInside/InjectableFrameworks/`.
/// 2. `LKInjectionService.registerDaemonIfNeeded()` — registers the
///    privileged daemon with SMAppService. If the user has not yet approved
///    it, surfaces a guide alert with a button that opens System Settings.
/// 3. `LKInjectionTargetPicker` — wraps `RunningPickerTabViewController`.
/// 4. `LKInjectionService.attach(pid:dylibURL:)` — fires
///    `InjectApplicationRequest` at the root daemon over XPC.
/// 5. Brief sleep so the target app's Peertalk listener can bind; the existing
///    `LKLaunchViewController` 1.5s refresh tick then discovers the newly
///    inspectable app automatically.
@objc(LKInjectionFlow)
final class LKInjectionFlow: NSObject {
    @objc(sharedInstance) static let shared = LKInjectionFlow()

    private var picker: LKInjectionTargetPicker?
    private var inProgress = false

    @objc func startFromWindow(_ window: NSWindow?) {
        guard !inProgress else { return }
        inProgress = true

        Task { @MainActor in
            await self.runFlow(presentingWindow: window)
            self.inProgress = false
        }
    }

    @MainActor
    private func runFlow(presentingWindow window: NSWindow?) async {
        let installation: LKInjectableFrameworkInstallation
        do {
            installation = try LKInjectableFrameworkInstaller.shared.ensureInstalled(presentingWindow: window)
        } catch let error as LKInjectableFrameworkInstallerError where error.isCancellation {
            return
        } catch {
            presentAlert(error: error, window: window)
            return
        }

        do {
            try await LKInjectionService.shared.registerDaemonIfNeeded()
        } catch LKInjectionServiceError.daemonRequiresApproval {
            await presentDaemonApprovalGuide(window: window)
            return
        } catch {
            presentAlert(error: error, window: window)
            return
        }

        guard let pid = await pickTargetPID(window: window) else {
            return
        }

        let dylibURL = installation.frameworkURL.appendingPathComponent("LookInsideServer", isDirectory: false)

        do {
            try await LKInjectionService.shared.attach(pid: pid, dylibURL: dylibURL)
        } catch {
            presentAlert(error: error, window: window)
            return
        }

        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await presentAttachSuccess(pid: pid, window: window)
    }

    @MainActor
    private func pickTargetPID(window: NSWindow?) async -> pid_t? {
        await withCheckedContinuation { continuation in
            let picker = LKInjectionTargetPicker()
            self.picker = picker
            var resumed = false
            picker.onConfirm = { [weak self] pid, _ in
                guard !resumed else { return }
                resumed = true
                self?.picker = nil
                continuation.resume(returning: pid)
            }
            picker.onCancel = { [weak self] in
                guard !resumed else { return }
                resumed = true
                self?.picker = nil
                continuation.resume(returning: nil)
            }
            picker.present(in: window)
        }
    }

    @MainActor
    private func presentDaemonApprovalGuide(window: NSWindow?) async {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Approve LookInside Injector", comment: "")
        alert.informativeText = LKInjectionServiceError.daemonRequiresApproval.localizedDescription ?? ""
        alert.addButton(withTitle: NSLocalizedString("Open Login Items Settings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))

        let response: NSApplication.ModalResponse
        if let window {
            response = await alert.beginSheetModal(for: window)
        } else {
            response = alert.runModal()
        }
        if response == .alertFirstButtonReturn {
            LKInjectionService.shared.openLoginItemsSettings()
        }
    }

    @MainActor
    private func presentAttachSuccess(pid: pid_t, window: NSWindow?) async {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Attached", comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("LookInsideServer was injected into pid %d. The app should appear in the Launch list shortly.", comment: ""),
            pid
        )
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        if let window {
            _ = await alert.beginSheetModal(for: window)
        } else {
            _ = alert.runModal()
        }
    }

    @MainActor
    private func presentAlert(error: Error, window: NSWindow?) {
        let alert = NSAlert(error: error)
        if let window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
}

private extension LKInjectableFrameworkInstallerError {
    var isCancellation: Bool {
        if case .cancelled = self { return true }
        return false
    }
}
