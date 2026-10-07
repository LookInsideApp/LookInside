import AppKit
import Foundation
import LookInsideActivation
import SwiftUI

/// Alert the Host asks the activation UI to show (the helper's `ui.show_alert`).
public struct ActivationAlert: Equatable, Sendable {
    public enum Style: String, Sendable {
        case informational
        case warning
        case critical
    }

    public let title: String
    public let message: String
    public let style: Style

    public init(title: String, message: String, style: Style) {
        self.title = title
        self.message = message
        self.style = style
    }
}

/// Where an activation alert or prompt appears.
public enum ActivationAlertPresentation {
    /// For a direct user action, such as a menu command: a sheet on the
    /// activation window when it is visible, otherwise an app-modal alert.
    case modal
    /// For an alert raised by a background flow (a connection, a reload, a
    /// detection). It never runs a modal loop, so inspection keeps going: a
    /// sheet on the activation window when it is visible, else on `window`
    /// when it is visible and has no sheet, else on the activation window,
    /// which is shown for it.
    case attached(to: NSWindow?)
}

/// Owns the activation window and the activation prompts, replacing the
/// helper's `ui.*` RPCs. All windows are shown inside the Host process.
@MainActor
public final class ActivationWindowCoordinator {
    private let runtime: ActivationRuntime
    private let activationWindowController: ActivationWindowController
    private var acknowledgedAlertKeys = Set<String>()
    private var presentedAlertKeys = Set<String>()
    private var keychainExplainerPanel: NSPanel?

    public var activationModel: ActivationModel {
        activationWindowController.model
    }

    public var activationWindow: NSWindow {
        activationWindowController.activationWindow
    }

    public init(
        runtime: ActivationRuntime,
        uiConfiguration: ActivationUIConfiguration? = nil
    ) {
        self.runtime = runtime
        activationWindowController = ActivationWindowController(
            model: runtime.activationModel(),
            configuration: uiConfiguration
                ?? ActivationUIConfiguration(
                    requestedFeature: runtime.configuration.requestedFeature,
                    frameworkVersion: runtime.configuration.frameworkVersion
                )
        )
    }

    /// `ui.show_activation`.
    public func showActivationWindow() async {
        await runtime.restoreActivationModel()
        activationWindowController.present()
    }

    /// `ui.show_license`.
    public func showLicenseWindow() async {
        await runtime.restoreActivationModel()
        activationWindowController.present()
    }

    /// `license.refresh_status` with the helper's window behaviour: shows the
    /// license window with a progress message while the refresh runs.
    @discardableResult
    public func refreshLicenseStatus() async throws -> ActivationAccessDecision {
        await runtime.restoreActivationModel()
        activationModel.beginLicenseStatusRefresh()
        activationWindowController.present()
        do {
            let decision = try await runtime.refreshedDecision()
            await runtime.restoreActivationModel()
            activationModel.finishLicenseStatusRefresh()
            return decision
        } catch {
            await runtime.restoreActivationModel()
            activationModel.finishLicenseStatusRefresh()
            throw error
        }
    }

    /// `ui.show_activation_prompt`: asks whether to activate and opens the
    /// activation window on "Activate".
    public func showActivationPrompt(presentation: ActivationAlertPresentation = .modal) {
        let alert = NSAlert()
        alert.messageText = String(localized: "Activate LookInside Pro?", bundle: .activationUI)
        alert.informativeText = String(
            localized:
            "This target app includes SwiftUI views. Activate LookInside Pro to inspect SwiftUI view details.",
            bundle: .activationUI
        )
        alert.alertStyle = .informational
        alert.addButton(withTitle: String(localized: "Activate", bundle: .activationUI))
        alert.addButton(withTitle: String(localized: "Later", bundle: .activationUI))
        alert.icon = NSApp.applicationIconImage

        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .alertFirstButtonReturn else { return }
            Task { [weak self] in
                await self?.showActivationWindow()
            }
        }

        present(alert, presentation: presentation, completion: completion)
    }

    /// Shows the keychain explainer for a license key LookInside did not
    /// create, centred over `window` when it is visible. The panel does not
    /// activate LookInside or take keyboard focus, so it cannot catch typing
    /// meant for another window. Continue confirms the explainer and lets the
    /// held-back use of the key run, which raises the system prompt; Not Now
    /// counts as a denial. A panel already on screen is kept.
    public func showKeychainAccessExplainer(over window: NSWindow?) {
        guard keychainExplainerPanel == nil else { return }
        let runtime = runtime
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        let finish: @MainActor (Bool) -> Void = { [weak self, weak panel] confirmed in
            panel?.close()
            self?.keychainExplainerPanel = nil
            if confirmed {
                runtime.confirmKeychainAccessExplainer()
            } else {
                runtime.declineKeychainAccessExplainer()
            }
        }
        panel.contentViewController = NSHostingController(
            rootView: KeychainAccessExplainerView(
                onContinue: { finish(true) },
                onNotNow: { finish(false) }
            )
        )
        panel.title = "LookInside"
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.layoutIfNeeded()
        if let window, window.isVisible {
            let frame = window.frame
            panel.setFrameOrigin(
                NSPoint(
                    x: frame.midX - panel.frame.width / 2,
                    y: frame.midY - panel.frame.height / 2
                )
            )
        } else {
            panel.center()
        }
        keychainExplainerPanel = panel
        panel.orderFront(nil)
    }

    /// `ui.show_alert`. An alert with the same style, title and message is
    /// shown once until acknowledged, and not again after that.
    public func showAlert(
        _ payload: ActivationAlert,
        presentation: ActivationAlertPresentation = .modal
    ) {
        let alertKey = payload.deduplicationKey
        guard acknowledgedAlertKeys.contains(alertKey) == false,
              presentedAlertKeys.contains(alertKey) == false
        else {
            return
        }
        presentedAlertKeys.insert(alertKey)

        let alert = NSAlert()
        alert.messageText = Self.localizedPayloadString(payload.title)
        alert.informativeText = Self.localizedPayloadString(payload.message)
        alert.alertStyle = payload.style.nsAlertStyle
        alert.icon = NSApp.applicationIconImage
        alert.addButton(withTitle: String(localized: "OK", bundle: .activationUI))

        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] _ in
            self?.acknowledgedAlertKeys.insert(alertKey)
            self?.presentedAlertKeys.remove(alertKey)
        }

        present(alert, presentation: presentation, completion: completion)
    }

    private func present(
        _ alert: NSAlert,
        presentation: ActivationAlertPresentation,
        completion: @escaping (NSApplication.ModalResponse) -> Void
    ) {
        let activationWindow = activationWindowController.activationWindow
        switch Self.alertTarget(
            for: presentation,
            activationWindowIsVisible: activationWindow.isVisible
        ) {
        case .activationWindow:
            alert.beginSheetModal(for: activationWindow, completionHandler: completion)
        case let .sheet(window):
            alert.beginSheetModal(for: window, completionHandler: completion)
        case .shownActivationWindow:
            activationWindowController.present()
            alert.beginSheetModal(for: activationWindow, completionHandler: completion)
        case .appModal:
            NSApp.activate(ignoringOtherApps: true)
            completion(alert.runModal())
        }
    }

    enum AlertTarget: Equatable {
        case activationWindow
        case sheet(NSWindow)
        case shownActivationWindow
        case appModal
    }

    /// Where `present(_:presentation:completion:)` puts an alert. Only
    /// `.modal` ever ends in an app-modal alert.
    static func alertTarget(
        for presentation: ActivationAlertPresentation,
        activationWindowIsVisible: Bool
    ) -> AlertTarget {
        if activationWindowIsVisible {
            return .activationWindow
        }
        switch presentation {
        case .modal:
            return .appModal
        case let .attached(window):
            if let window, window.isVisible, window.attachedSheet == nil {
                return .sheet(window)
            }
            return .shownActivationWindow
        }
    }

    private static func localizedPayloadString(_ value: String) -> String {
        String(localized: String.LocalizationValue(value), bundle: .main)
    }
}

private extension ActivationAlert.Style {
    var nsAlertStyle: NSAlert.Style {
        switch self {
        case .informational:
            return .informational
        case .warning:
            return .warning
        case .critical:
            return .critical
        }
    }
}

extension ActivationAlert {
    var deduplicationKey: String {
        "\(style.rawValue)\u{1f}\(title)\u{1f}\(message)"
    }
}
