import AppKit
import Foundation
import HelperClient
import HelperCommunication
import InjectionServiceInterface
import ServiceManagement

enum LKInjectionServiceError: LocalizedError {
    case daemonRegistrationFailed(String)
    case daemonRequiresApproval
    case daemonBundleMissing
    case unsupportedDaemonStatus(Int)
    case daemonNotEnabled(status: SMAppService.Status)
    case daemonUnreachable(String)
    case attachFailed(String)

    var errorDescription: String? {
        switch self {
        case let .daemonRegistrationFailed(message):
            return String(
                format: NSLocalizedString("Failed to register the LookInside Injector daemon.\n%@", comment: ""),
                message
            )
        case .daemonRequiresApproval:
            return NSLocalizedString(
                "The LookInside Injector daemon requires your approval.\nOpen System Settings → Login Items & Extensions, locate “LookInside Injector”, and turn it on, then try again.",
                comment: ""
            )
        case .daemonBundleMissing:
            return NSLocalizedString(
                "The LookInside Injector daemon is missing from this app.\nPlease reinstall LookInside, then try again.",
                comment: ""
            )
        case let .unsupportedDaemonStatus(rawValue):
            return String(
                format: NSLocalizedString("The LookInside Injector daemon returned an unsupported status (%d).", comment: ""),
                rawValue
            )
        case let .daemonNotEnabled(status):
            return String(
                format: NSLocalizedString("The LookInside Injector daemon is not enabled (status %@).", comment: ""),
                Self.statusDescription(status)
            )
        case let .daemonUnreachable(message):
            return String(
                format: NSLocalizedString("Unable to reach the LookInside Injector daemon.\n%@", comment: ""),
                message
            )
        case let .attachFailed(message):
            return String(
                format: NSLocalizedString("Failed to inject LookInsideServer.framework into the target process.\n%@", comment: ""),
                message
            )
        }
    }

    private static func statusDescription(_ status: SMAppService.Status) -> String {
        switch status {
        case .notRegistered: return "notRegistered"
        case .enabled: return "enabled"
        case .requiresApproval: return "requiresApproval"
        case .notFound: return "notFound"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }
}

final class LKInjectionService {
    static let shared = LKInjectionService()

    static let machServiceName = "app.lookinside.LookInsideInjector"
    static let daemonPlistName = "app.lookinside.LookInsideInjector.plist"

    private let helperClient = HelperClient()
    private let daemonInstaller: SMAppServiceDaemonInstaller

    private init() {
        daemonInstaller = SMAppServiceDaemonInstaller(plistName: Self.daemonPlistName)
    }

    func currentDaemonStatus() async -> SMAppService.Status {
        await daemonInstaller.currentStatus
    }

    func currentDaemonStatusSnapshot() async -> LKInjectionDaemonStatusSnapshot {
        Self.statusSnapshot(await daemonInstaller.currentStatus)
    }

    /// Registers the daemon via SMAppService if it is not already enabled.
    ///
    /// Outcomes:
    /// - `.enabled` already: returns immediately.
    /// - `.notRegistered` / `.notFound`: calls `register()`. If the resulting
    ///   status is `.enabled` returns; if it is `.requiresApproval` throws
    ///   `.daemonRequiresApproval`.
    /// - `.requiresApproval` already: throws `.daemonRequiresApproval` so the
    ///   caller can point the user to System Settings.
    func registerDaemonIfNeeded() async throws {
        let status = await daemonInstaller.currentStatus
        switch status {
        case .enabled:
            return
        case .requiresApproval:
            throw LKInjectionServiceError.daemonRequiresApproval
        case .notFound:
            throw LKInjectionServiceError.daemonBundleMissing
        case .notRegistered:
            do {
                try await daemonInstaller.register()
            } catch {
                throw LKInjectionServiceError.daemonRegistrationFailed(Self.registrationFailureMessage(from: error))
            }
            let newStatus = await daemonInstaller.currentStatus
            switch newStatus {
            case .enabled:
                return
            case .requiresApproval, .notRegistered:
                throw LKInjectionServiceError.daemonRequiresApproval
            case .notFound:
                throw LKInjectionServiceError.daemonBundleMissing
            @unknown default:
                throw LKInjectionServiceError.daemonNotEnabled(status: newStatus)
            }
        @unknown default:
            throw LKInjectionServiceError.daemonNotEnabled(status: status)
        }
    }

    @MainActor
    func openLoginItemsSettings() {
        daemonInstaller.openLoginItemsSettings()
    }

    /// Attaches by remotely `dlopen`-ing `dylibURL` inside the process at `pid`.
    ///
    /// The daemon performs the actual `task_for_pid` + Mach-injection. Callers
    /// must have:
    /// 1. Resolved a valid macOS-slice dylib URL inside an installed
    ///    `LookInsideServer.framework` (see `LKInjectableFrameworkInstaller`).
    /// 2. Confirmed daemon enablement via `registerDaemonIfNeeded()`.
    ///
    /// LookInside Pro gating is enforced in the host before this service is
    /// reached. This daemon/XPC boundary is not a hard license-enforcement
    /// layer in v1; adding daemon-side proof validation is a separate protocol
    /// change.
    func attach(pid: pid_t, dylibURL: URL) async throws {
        try await ensureConnectedToTool()
        do {
            try await helperClient.sendToTool(
                request: InjectApplicationRequest(pid: pid, dylibURL: dylibURL)
            )
        } catch {
            throw LKInjectionServiceError.attachFailed(error.localizedDescription)
        }
    }

    private func ensureConnectedToTool() async throws {
        let status = await daemonInstaller.currentStatus
        guard status == .enabled else {
            throw LKInjectionServiceError.daemonNotEnabled(status: status)
        }
        if await helperClient.isConnectedToTool {
            return
        }
        do {
            try await helperClient.connectToTool(
                machServiceName: Self.machServiceName,
                isPrivilegedHelperTool: true
            )
        } catch {
            throw LKInjectionServiceError.daemonUnreachable(error.localizedDescription)
        }
    }

    private static func registrationFailureMessage(from error: Error) -> String {
        let message = error.localizedDescription
        let unreadablePlistPrefix = "Unable to read plist:"
        guard message.localizedStandardContains(unreadablePlistPrefix) else {
            return message
        }
        return String(
            format: NSLocalizedString("Unable to read injector daemon plist: %@", comment: ""),
            daemonPlistName
        )
    }

    private static func statusSnapshot(_ status: SMAppService.Status) -> LKInjectionDaemonStatusSnapshot {
        switch status {
        case .notRegistered:
            return .notRegistered
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        @unknown default:
            return .unknown(status.rawValue)
        }
    }
}
