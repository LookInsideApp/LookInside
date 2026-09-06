import ArgumentParser
import Darwin
import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol

struct ServiceArguments: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "lookinside-service", abstract: "Run the LookInside inspection service without opening the application.", version: "1")

    @Option(help: "An absolute Unix socket path. The enclosing directory must be private to this service.")
    var socketPath: String?

    @Option(help: "Exit after this many seconds without connected clients. Cached sessions do not prevent exit.")
    var idleTimeout: Double = 300

    mutating func validate() throws {
        guard idleTimeout.isFinite, idleTimeout > 0 else { throw ValidationError("--idle-timeout must be positive and finite.") }
        _ = try InspectionRuntimePaths(socketPath: socketPath)
    }

    mutating func run() throws {
        let paths = try InspectionRuntimePaths(socketPath: socketPath)
        let idleTimeout = idleTimeout
        try MainActor.assumeIsolated {
            InspectionEnvironment.shared().hierarchyRequestTimeoutInterval = 30
            let authorization = InspectionAuthorization()
            authorization.configureEnvironment()
            let backend = InspectionServiceBackend(prepareAuthorization: {
                try InspectionConnectionOwnership.shared.acquire()
                try authorization.prepare()
            }, authorizationFailure: { authorization.failure })
            let service = InspectionSocketServer(paths: paths, idleTimeout: idleTimeout) { request, clientIdentifier in
                await backend.handle(request, clientIdentifier: clientIdentifier)
            }
            backend.instanceIdentifier = service.instanceIdentifier
            backend.authorizationRequest = { try await authorization.forward($0) }
            var legacyService: InspectionSocketServer?
            defer { legacyService?.stop() }
            if socketPath == nil, ProcessInfo.processInfo.environment["LOOKINSIDE_INSPECTION_RUNTIME_DIRECTORY"] == nil {
                let legacyPath = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/Application Support/LookInside/Host/run/lookinside-host-mcp.sock").path
                let listener = try InspectionSocketServer(paths: InspectionRuntimePaths(socketPath: legacyPath),
                                                          idleTimeout: .greatestFiniteMagnitude, instanceIdentifier: service.instanceIdentifier)
                { request, clientIdentifier in
                    await backend.handle(request, clientIdentifier: clientIdentifier)
                }
                do {
                    try listener.start()
                    listener.onClientDisconnect = { backend.disconnect(clientIdentifier: $0) }
                    legacyService = listener
                } catch let failure as InspectionFailure where ["service.inUse", "service.invalidPath"].contains(failure.code) {
                    // A live legacy host keeps its socket. The connection-owner
                    // lock will report the conflict before target discovery.
                }
            }
            backend.publish = { [weak service, weak legacyService] event in
                service?.publish(event)
                legacyService?.publish(event)
            }
            authorization.onActivationChange = { [weak backend] activated in
                backend?.publish?(InspectionEvent(topic: "license.stateChanged", payload: [
                    "activated": .bool(activated), "serviceInstanceIdentifier": .string(service.instanceIdentifier),
                ]))
            }
            service.hasExternalClients = { [weak legacyService] in (legacyService?.connectedClientCount ?? 0) > 0 }
            service.onClientDisconnect = { backend.disconnect(clientIdentifier: $0) }
            service.onStop = { legacyService?.stop(); backend.stop(); CFRunLoopStop(CFRunLoopGetMain()) }
            try service.start()
            withExtendedLifetime(service) { CFRunLoopRun() }
        }
    }
}

ServiceArguments.main()
