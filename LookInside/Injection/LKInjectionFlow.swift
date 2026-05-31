import AppKit
import Foundation

/// Orchestrates the attach-to-running-app flow:
///
/// 1. `LKInjectionService.registerDaemonIfNeeded()` — only after the user
///    clicks Attach, asks before registering the privileged daemon with
///    SMAppService and waits for administrator approval if macOS requires it.
/// 2. `LKInjectionTargetPicker` — wraps `RunningPickerTabViewController`.
/// 3. `LKInjectableFrameworkInstaller` — ensures LookInsideServer.framework is
///    downloaded under `~/Library/Application Support/LookInside/InjectableFrameworks/`.
/// 4. `LKInjectionService.attach(pid:dylibURL:)` — fires
///    `InjectApplicationRequest` at the root daemon over XPC.
/// 5. Brief sleep so the target app's Peertalk listener can bind; the existing
///    `LKLaunchViewController` 1.5s refresh tick then discovers the newly
///    inspectable app automatically.
@objc(LKInjectionFlow)
final class LKInjectionFlow: NSObject {
    @objc(sharedInstance) static let shared = LKInjectionFlow()

    private var picker: LKInjectionTargetPicker?
    private var startGate = LKInjectionStartGate()

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
        guard await ensureDaemonReady(window: window) else {
            return
        }

        guard let pid = await pickTargetPID(window: window) else {
            return
        }

        let installation: LKInjectableFrameworkInstallation
        do {
            installation = try LKInjectableFrameworkInstaller.shared.ensureInstalled(presentingWindow: window)
        } catch let error as LKInjectableFrameworkInstallerError where error.isCancellation {
            return
        } catch {
            presentAlert(error: error, window: window)
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
    private func ensureDaemonReady(window: NSWindow?) async -> Bool {
        while true {
            let status = await LKInjectionService.shared.currentDaemonStatusSnapshot()
            switch LKInjectionDaemonReadiness.nextStep(for: status) {
            case .proceed:
                return true

            case .requestRegistrationConsent:
                guard await confirmInjectorRegistration(window: window) else {
                    return false
                }
                do {
                    try await LKInjectionService.shared.registerDaemonIfNeeded()
                    return true
                } catch LKInjectionServiceError.daemonRequiresApproval {
                    return await presentDaemonApprovalGuide(window: window)
                } catch {
                    presentAlert(error: error, window: window)
                    return false
                }

            case .waitForApproval:
                guard await presentDaemonApprovalGuide(window: window) else {
                    return false
                }

            case .reportMissingBundle:
                presentAlert(error: LKInjectionServiceError.daemonBundleMissing, window: window)
                return false

            case .reportCurrentLocationUnsupported:
                presentAlert(error: LKInjectionServiceError.daemonUnavailableFromCurrentLocation, window: window)
                return false

            case let .reportUnsupportedStatus(rawValue):
                presentAlert(error: LKInjectionServiceError.unsupportedDaemonStatus(rawValue), window: window)
                return false
            }
        }
    }

    @MainActor
    private func confirmInjectorRegistration(window: NSWindow?) async -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Enable LookInside Injector?", comment: "")
        alert.informativeText = NSLocalizedString(
            "LookInside needs to enable its privileged injector before it can attach to another process. macOS may require an administrator to approve this in System Settings.",
            comment: ""
        )
        alert.addButton(withTitle: NSLocalizedString("Continue", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.buttons.first?.keyEquivalent = "\r"

        let response: NSApplication.ModalResponse
        if let window {
            response = await alert.beginSheetModal(for: window)
        } else {
            response = alert.runModal()
        }
        return response == .alertFirstButtonReturn
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
    private func presentDaemonApprovalGuide(window: NSWindow?) async -> Bool {
        while true {
            let status = await LKInjectionService.shared.currentDaemonStatusSnapshot()
            switch LKInjectionDaemonReadiness.nextStep(for: status) {
            case .proceed:
                return true
            case .reportMissingBundle:
                presentAlert(error: LKInjectionServiceError.daemonBundleMissing, window: window)
                return false
            case .reportCurrentLocationUnsupported:
                presentAlert(error: LKInjectionServiceError.daemonUnavailableFromCurrentLocation, window: window)
                return false
            case .requestRegistrationConsent:
                return false
            case .waitForApproval:
                break
            case let .reportUnsupportedStatus(rawValue):
                presentAlert(error: LKInjectionServiceError.unsupportedDaemonStatus(rawValue), window: window)
                return false
            }

            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = NSLocalizedString("Approve LookInside Injector", comment: "")
            alert.informativeText = NSLocalizedString(
                "macOS is waiting for administrator approval before it can run the LookInside Injector. Open Login Items & Extensions, enable LookInside, then return to LookInside and click Attach to Running App again.",
                comment: ""
            )
            alert.addButton(withTitle: NSLocalizedString("Check Again", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Open System Settings", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
            alert.buttons.first?.keyEquivalent = "\r"

            let response: NSApplication.ModalResponse
            if let window {
                response = await alert.beginSheetModal(for: window)
            } else {
                response = alert.runModal()
            }

            switch response {
            case .alertFirstButtonReturn:
                continue
            case .alertSecondButtonReturn:
                LKInjectionService.shared.openLoginItemsSettings()
                return false
            default:
                return false
            }
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
