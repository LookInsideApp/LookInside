import AppKit
import Darwin
import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol

struct InjectionProcessIdentity: Codable, Sendable, Equatable, Hashable {
    let processIdentifier: Int32
    let startIdentifier: String
    let executablePath: String
    let architecture: Int32
    let userIdentifier: UInt32

    static func read(_ processIdentifier: Int32) throws -> Self {
        var information = proc_bsdinfo()
        let informationSize = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard processIdentifier > 1,
              proc_pidinfo(processIdentifier, PROC_PIDTBSDINFO, 0, &information, informationSize) == informationSize
        else { throw InspectionFailure(code: "injection.targetNotFound", message: "Choose a currently running macOS application process.") }
        var executableBytes = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        var architectureInformation = proc_archinfo()
        let architectureSize = Int32(MemoryLayout<proc_archinfo>.size)
        guard proc_pidpath(processIdentifier, &executableBytes, UInt32(executableBytes.count)) > 0,
              proc_pidinfo(processIdentifier, PROC_PIDARCHINFO, 0, &architectureInformation, architectureSize) == architectureSize
        else { throw InspectionFailure(code: "injection.targetUnverified", message: "Cannot read the target executable or architecture.") }
        let identity = Self(processIdentifier: processIdentifier,
                            startIdentifier: "\(information.pbi_start_tvsec):\(information.pbi_start_tvusec)",
                            executablePath: String(cString: executableBytes),
                            architecture: architectureInformation.p_cputype, userIdentifier: information.pbi_uid)
        guard let application = NSRunningApplication(processIdentifier: processIdentifier),
              application.bundleURL != nil, !application.isTerminated,
              application.executableURL?.resolvingSymlinksInPath().path == URL(fileURLWithPath: identity.executablePath).resolvingSymlinksInPath().path
        else { throw InspectionFailure(code: "injection.denied", message: "The selected process is not a running macOS application.") }
        var confirmation = proc_bsdinfo()
        guard proc_pidinfo(processIdentifier, PROC_PIDTBSDINFO, 0, &confirmation, informationSize) == informationSize,
              information.pbi_start_tvsec == confirmation.pbi_start_tvsec,
              information.pbi_start_tvusec == confirmation.pbi_start_tvusec,
              information.pbi_uid == confirmation.pbi_uid
        else { throw InspectionFailure(code: "injection.targetChanged", message: "The selected process changed. Select its current running instance.") }
        return identity
    }
}

/// Dependencies represent the operating system, installed artifacts, and helper
/// process. Tests supply these boundaries without injecting into any real process.
@MainActor
struct InspectionInjectionEnvironment {
    var process: (Int32) throws -> InjectionProcessIdentity
    var authorize: () throws -> Void
    var helperStatus: () async throws -> InspectionValue
    var framework: (InjectionProcessIdentity) throws -> URL
    var submit: (InjectionProcessIdentity, URL) async throws -> Void
}

enum InjectionStage: String {
    case notSubmitted, submissionUnknown, injected, sessionReady
}

@MainActor
final class InspectionInjection {
    let environment: InspectionInjectionEnvironment
    private var activeProcesses: Set<Int32> = []
    private var submittedProcesses: [InjectionProcessIdentity: InjectionStage] = [:]

    init(environment: InspectionInjectionEnvironment) {
        self.environment = environment
    }

    func handle(_ request: InspectionRequest, backend: InspectionServiceBackend, owner: String) async -> InspectionResponse {
        var stage = InjectionStage.notSubmitted
        var identity: InjectionProcessIdentity?
        do {
            if request.method == "injector.status" {
                return try InspectionResponse(identifier: request.identifier, result: await environment.helperStatus(),
                                              error: nil, metadata: backend.metadata(session: nil, fromCache: false))
            }
            guard request.method == "injection.inject",
                  let identifier = request.parameters?["processIdentifier"]?.integerValue,
                  identifier > 1, identifier <= Int32.max
            else { throw InspectionFailure.invalidParameters }
            let timeout = request.parameters?["waitTimeout"]?.doubleValue ?? 25
            guard timeout.isFinite, timeout > 0, timeout <= 25 else { throw InspectionFailure.invalidParameters }
            let deadline = ProcessInfo.processInfo.systemUptime + timeout
            let processIdentifier = Int32(identifier)
            guard activeProcesses.insert(processIdentifier).inserted else {
                throw InspectionFailure(code: "injection.alreadyInProgress", message: "An injection for this process is already in progress. Wait for its result.")
            }
            defer { activeProcesses.remove(processIdentifier) }
            let selected = try environment.process(processIdentifier)
            identity = selected
            guard selected.userIdentifier == geteuid() else {
                throw InspectionFailure(code: "injection.denied", message: "Choose a macOS application owned by the current user.")
            }
            try environment.authorize()
            try Task.checkCancellation()

            // Discovery must confirm a native local transport and the entire
            // process incarnation. A matching name, port, or bundle is insufficient.
            _ = try await backend.discover()
            try confirm(selected)
            if let ready = try await connectedSession(for: selected, request: request, backend: backend, owner: owner) {
                return ready
            }
            if let previous = submittedProcesses[selected] {
                stage = previous
                throw InspectionFailure(code: "injection.targetUnverified", message: "A previous injection was submitted for this process. Its result is still unverified; no second injection was sent.")
            }

            let status = try await environment.helperStatus()
            guard status.objectValue?["state"]?.stringValue == "enabled" else {
                throw helperFailure(status)
            }
            let framework = try environment.framework(selected)
            try confirm(selected)
            try checkDeadline(deadline)
            try Task.checkCancellation()
            // Keep receipts for this service lifetime, including lost replies.
            // Refuse additional submissions rather than evicting an uncertain one.
            guard submittedProcesses.count < 128 else {
                throw InspectionFailure(code: "injection.historyFull", message: "This service has reached its injection receipt limit. Finish current inspections before restarting it.")
            }
            stage = .submissionUnknown
            submittedProcesses[selected] = stage
            try await environment.submit(selected, framework)
            stage = .injected
            submittedProcesses[selected] = stage
            backend.publish?(InspectionEvent(topic: "injection.progress", payload: [
                "operationIdentifier": .string(request.identifier), "processIdentifier": .integer(identifier),
                "stage": .string(stage.rawValue),
            ]))
            while true {
                try Task.checkCancellation()
                try confirm(selected)
                if ProcessInfo.processInfo.systemUptime >= deadline,
                   backend.targets.values.contains(where: {
                       backend.isConnected($0) && $0.transportIdentifier == "mac"
                           && ($0.appInfo?.processIdentifier == nil || $0.appInfo?.processStartIdentifier == nil)
                   })
                {
                    throw InspectionFailure(code: "injection.targetUnverified", message: "Discovered Server connections lack process identity. Prepare a Server release supporting verified injection; none was associated by name or port.")
                }
                try checkDeadline(deadline)
                _ = try await backend.discover()
                try confirm(selected)
                if let ready = try await connectedSession(for: selected, request: request, backend: backend, owner: owner) {
                    submittedProcesses[selected] = .injected
                    return ready
                }
                try await Task.sleep(for: .milliseconds(100))
            }
        } catch {
            let underlying = backend.failure(for: error)
            if underlying.details?["injectionStage"]?.stringValue == InjectionStage.notSubmitted.rawValue, let identity {
                submittedProcesses.removeValue(forKey: identity)
                stage = .notSubmitted
            }
            var details: [String: InspectionValue] = [
                "injectionStage": .string(stage.rawValue), "operationIdentifier": .string(request.identifier),
            ]
            if let identity {
                details["processIdentifier"] = .integer(Int64(identity.processIdentifier))
                details["processStartIdentifier"] = .string(identity.startIdentifier)
            }
            let failure = InspectionFailure(code: underlying.code, message: underlying.message, details: details)
            return InspectionResponse(identifier: request.identifier, result: nil, error: failure,
                                      metadata: backend.metadata(session: nil, fromCache: false))
        }
    }

    private func confirm(_ identity: InjectionProcessIdentity) throws {
        guard try environment.process(identity.processIdentifier) == identity else {
            throw InspectionFailure(code: "injection.targetChanged", message: "The target process or executable changed. No further injection was submitted.")
        }
    }

    private func checkDeadline(_ deadline: TimeInterval) throws {
        guard ProcessInfo.processInfo.systemUptime < deadline else {
            throw InspectionFailure(code: "injection.discoveryTimeout", message: "The target did not complete a verified Server handshake before the deadline. Check injectionStage before retrying.")
        }
    }

    private func connectedSession(for identity: InjectionProcessIdentity, request: InspectionRequest,
                                  backend: InspectionServiceBackend, owner: String) async throws -> InspectionResponse?
    {
        let matches = backend.targets.filter { _, application in
            guard backend.isConnected(application), application.serverVersionError == nil,
                  let information = application.appInfo, information.deviceType == .mac,
                  application.transportIdentifier == "mac"
            else { return false }
            return information.processIdentifier?.int64Value == Int64(identity.processIdentifier)
                && information.processStartIdentifier == identity.startIdentifier
                && information.appInfoIdentifier != 0
        }
        guard matches.count <= 1 else {
            throw InspectionFailure(code: "injection.targetUnverified", message: "Multiple Server connections claimed the selected process identity.")
        }
        guard let match = matches.first else { return nil }
        let opened = await backend.handleCommand(InspectionRequest(identifier: request.identifier, method: "sessions.open",
                                                                   parameters: ["targetIdentifier": .string(match.key)]),
                                                 clientIdentifier: owner)
        if let error = opened.error {
            throw error
        }
        guard var result = opened.result?.objectValue else { throw InspectionFailure.internalError }
        result["injectionStage"] = .string(InjectionStage.sessionReady.rawValue)
        result["processIdentifier"] = .integer(Int64(identity.processIdentifier))
        result["processStartIdentifier"] = .string(identity.startIdentifier)
        result["applicationInstanceIdentifier"] = .string(String(match.value.appInfo.appInfoIdentifier))
        result["serverVersion"] = .integer(Int64(match.value.appInfo.serverVersion))
        result["operationIdentifier"] = .string(request.identifier)
        return InspectionResponse(identifier: request.identifier, result: .object(result), error: nil, metadata: opened.metadata)
    }

    private func helperFailure(_ status: InspectionValue) -> InspectionFailure {
        let state = status.objectValue?["state"]?.stringValue ?? "unreachable"
        let code: String
        switch state {
        case "requiresApproval": code = "injection.approvalRequired"
        case "missing": code = "injection.helperMissing"
        case "unsupportedLocation": code = "injection.unsupportedLocation"
        case "incompatible": code = "injection.helperIncompatible"
        default: code = "injection.helperNotEnabled"
        }
        return InspectionFailure(code: code, message: "Injector status is \(state). Open LookInside from Applications and use Attach to Running App to prepare or approve the helper.")
    }
}

private extension InspectionValue {
    var doubleValue: Double? {
        switch self {
        case let .double(value): value
        case let .integer(value): Double(value)
        default: nil
        }
    }
}
