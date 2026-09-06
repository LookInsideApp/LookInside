import Darwin
import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol
import ServiceManagement
import SwiftyXPC

@MainActor
enum InspectionInjectionSystem {
    static let machServiceName = "app.lookinside.LookInsideInjector"
    static let daemonPlistName = machServiceName + ".plist"
    static let helperRequirement = #"anchor apple generic and certificate leaf[subject.OU] = "964G86XT2P" and identifier "app.lookinside.LookInsideInjector""#

    static func environment(authorization: InspectionAuthorization) -> InspectionInjectionEnvironment {
        InspectionInjectionEnvironment(process: InjectionProcessIdentity.read, authorize: {
            try authorization.prepare()
            guard authorization.isActivated else {
                throw InspectionFailure(code: "injection.licenseRequired", message: authorization.failure.message)
            }
        }, helperStatus: status, framework: { identity in
            let framework = try InjectableFrameworkRepository.preparedFramework()
            let executable = framework.appendingPathComponent("LookInsideServer")
            guard let bundle = Bundle(url: framework),
                  bundle.executableArchitectures?.contains(NSNumber(value: identity.architecture)) == true,
                  FileManager.default.isExecutableFile(atPath: executable.path)
            else { throw InspectionFailure(code: "injection.frameworkUnavailable", message: "The prepared framework does not contain the target architecture. Prepare the current Server release through LookInside.") }
            return framework
        }, submit: submit)
    }

    static func status() async throws -> InspectionValue {
        guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() else { return state("missing") }
        let contents = executable.deletingLastPathComponent().deletingLastPathComponent()
        let application = contents.deletingLastPathComponent()
        guard contents.lastPathComponent == "Contents", application.pathExtension == "app",
              FileManager.default.isExecutableFile(atPath: contents.appendingPathComponent("MacOS/lookinside-injector").path),
              FileManager.default.isReadableFile(atPath: contents.appendingPathComponent("Library/LaunchDaemons/" + daemonPlistName).path)
        else { return state("missing") }
        let applicationsDirectory = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first
        guard let applicationsDirectory, application.path.hasPrefix(applicationsDirectory.path + "/") else { return state("unsupportedLocation") }
        switch SMAppService.daemon(plistName: daemonPlistName).status {
        case .enabled:
            do {
                let response: InjectorStatus = try await exchange(name: "app.lookinside.injector.status", request: EmptyRequest(), timeout: 3)
                guard response.protocolVersion == 1 else { return state("incompatible") }
                return .object(["state": .string("enabled"), "protocolVersion": .integer(1), "helperVersion": .string(response.version)])
            } catch XPCConnection.Error.unexpectedMessage {
                return state("incompatible")
            } catch { return .object(["state": .string("unreachable"), "message": .string(error.localizedDescription)]) }
        case .requiresApproval: return state("requiresApproval")
        case .notRegistered: return state("notRegistered")
        case .notFound: return state("notRegistered")
        @unknown default: return state("unknown")
        }
    }

    static func submit(_ identity: InjectionProcessIdentity, framework: URL) async throws {
        let request = VerifiedInjectionRequest(processIdentifier: identity.processIdentifier,
                                               startIdentifier: identity.startIdentifier, executablePath: identity.executablePath,
                                               architecture: identity.architecture, userIdentifier: identity.userIdentifier,
                                               frameworkURL: framework)
        let response: VerifiedInjectionResponse = try await exchange(name: "app.lookinside.injector.injectVerifiedApplication",
                                                                     request: request, timeout: 8)
        if let code = response.errorCode {
            throw InspectionFailure(code: code, message: response.message ?? "The injector denied the request.",
                                    details: ["injectionStage": .string(response.injectionStage)])
        }
        guard response.injectionStage == "injected" else {
            throw InspectionFailure(code: "injection.targetUnverified", message: "The helper returned an unrecognized injection result; execution may already have occurred.")
        }
    }

    private static func state(_ value: String) -> InspectionValue {
        .object(["state": .string(value)])
    }

    private static func exchange<Request: Codable & Sendable, Response: Codable & Sendable>(
        name: String, request: Request, timeout: Double
    ) async throws -> Response {
        let connection = try XPCConnection(type: .remoteMachService(serviceName: machServiceName, isPrivilegedHelperTool: true),
                                           codeSigningRequirement: helperRequirement)
        connection.activate()
        defer { connection.cancel() }
        return try await withTaskCancellationHandler {
            try await withThrowingTaskGroup(of: Response.self) { group in
                group.addTask { try await connection.sendMessage(name: name, request: request) }
                group.addTask {
                    try await Task.sleep(for: .seconds(timeout))
                    connection.cancel()
                    throw InspectionFailure(code: "injection.helperTimeout", message: "The injector did not return a result before the deadline. A submitted injection must not be replayed automatically.")
                }
                defer { group.cancelAll() }
                return try await group.next()!
            }
        } onCancel: { connection.cancel() }
    }
}

// This wire contract is implemented independently of the privileged executable;
// the GPL service does not link the proprietary injector's implementation.
private struct EmptyRequest: Codable, Sendable {}
private struct InjectorStatus: Codable, Sendable {
    let protocolVersion: Int
    let version: String
}

private struct VerifiedInjectionRequest: Codable, Sendable {
    let processIdentifier: Int32
    let startIdentifier: String
    let executablePath: String
    let architecture: Int32
    let userIdentifier: UInt32
    let frameworkURL: URL
}

private struct VerifiedInjectionResponse: Codable, Sendable {
    let injectionStage: String
    let errorCode: String?
    let message: String?
}
