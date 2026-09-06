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
            service.onClientDisconnect = { backend.disconnect(clientIdentifier: $0) }
            service.onStop = { backend.stop(); CFRunLoopStop(CFRunLoopGetMain()) }
            try service.start()
            withExtendedLifetime(service) { CFRunLoopRun() }
        }
    }
}

ServiceArguments.main()
