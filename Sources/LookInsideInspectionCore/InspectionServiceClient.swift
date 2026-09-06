import Foundation
import LookInsideInspectionProtocol

@MainActor
@objc(LKInspectionServiceClient)
public final class InspectionServiceClient: NSObject {
    @objc public static let shared = InspectionServiceClient()
    @objc public static let didReceiveEventNotification = Notification.Name("LKInspectionServiceDidReceiveEvent")
    public let connection = InspectionServiceConnection()
    @objc public var initialCaptureOptionsProvider: (() -> [String: Any])?
    private let socketPath: String?
    private var connectionTask: Task<Void, Error>?
    private var applications: [String: RemoteInspectableApp] = [:]
    private let mirrors = NSHashTable<RemoteInspectionSession>.weakObjects()
    public private(set) var serviceInstanceIdentifier: String?

    public init(socketPath: String? = nil) {
        self.socketPath = socketPath
        super.init()
        connection.onEvent = { [weak self] event in
            guard let self else { return }
            for mirror in self.mirrors.allObjects {
                mirror.receive(event)
            }
            NotificationCenter.default.post(name: Self.didReceiveEventNotification, object: self,
                                            userInfo: ["topic": event.topic])
        }
        connection.onDisconnect = { [weak self] error in
            guard let self else { return }
            for mirror in self.mirrors.allObjects {
                mirror.markMirrorDisconnected(error.localizedDescription)
            }
        }
    }

    @objc public func discoverApplications() -> RACSignal<AnyObject> {
        Self.signal {
            try await self.connect()
            let response = try await self.send("targets.models")
            let model = try await self.model(from: response)
            guard let descriptions = model as? [[String: Any]] else { throw InspectionSignalError.invalidResponse }
            var applications: [InspectableApp] = []
            for description in descriptions {
                guard let identifier = description["targetIdentifier"] as? String,
                      let information = description["appInfo"] as? LookinAppInfo,
                      let transport = description["transportIdentifier"] as? String else { throw InspectionSignalError.invalidResponse }
                let application = self.applications[identifier] ?? RemoteInspectableApp(client: self, targetIdentifier: identifier)
                application.appInfo = information
                application.transportIdentifier = transport
                self.applications[identifier] = application
                applications.append(application)
            }
            return [applications as NSArray]
        }
    }

    public func connect() async throws {
        if let connectionTask {
            return try await connectionTask.value
        }
        if connection.isConnected {
            return
        }
        let task = Task {
            defer { connectionTask = nil }
            let paths = try InspectionRuntimePaths(socketPath: socketPath)
            do { try connection.connect(socketPath: paths.socketPath) }
            catch let failure as InspectionFailure where socketPath == nil && failure.code == "service.unavailable" {
                let executable = Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0])
                _ = try InspectionServiceLauncher.launch(executableURL: InspectionServiceLauncher.bundledServiceURL(executableURL: executable))
                let deadline = ContinuousClock.now.advanced(by: .seconds(5))
                while true {
                    do { try connection.connect(socketPath: paths.socketPath); break }
                    catch let failure as InspectionFailure where failure.code == "service.unavailable" {
                        guard ContinuousClock.now < deadline else { throw failure }
                        try await Task.sleep(for: .milliseconds(50))
                    }
                }
            }
            let health = try await connection.request("service.status")
            try InspectionCapabilities.validate(health, supporting: "hierarchy.capture")
            let instance = health.metadata?.serviceInstanceIdentifier
            if let previous = serviceInstanceIdentifier, previous != instance {
                for mirror in mirrors.allObjects {
                    mirror.markMirrorDisconnected("The inspection service restarted. Select the target again.")
                }
                applications.removeAll()
            }
            serviceInstanceIdentifier = instance
        }
        connectionTask = task
        do { try await task.value } catch { connection.close(); throw error }
    }

    @objc public func disconnect() {
        connectionTask?.cancel()
        connectionTask = nil
        connection.close()
    }

    func register(_ mirror: RemoteInspectionSession) {
        mirrors.add(mirror)
    }

    func send(_ method: String, parameters: [String: InspectionValue]? = nil) async throws -> InspectionResponse {
        try await connect()
        let response = try await connection.request(method, parameters: parameters)
        if let error = response.error {
            throw error
        }
        guard response.metadata?.serviceInstanceIdentifier == serviceInstanceIdentifier else {
            throw InspectionFailure(code: "service.restarted", message: "The inspection service changed while handling the request.")
        }
        return response
    }

    func model(from response: InspectionResponse) async throws -> Any {
        guard let transfer = response.result?.objectValue?["transfer"] else { throw InspectionSignalError.invalidResponse }
        let manifest = try transfer.decode(InspectionTransferManifest.self)
        guard manifest.metadata?.serviceInstanceIdentifier == serviceInstanceIdentifier else {
            throw InspectionFailure(code: "service.restarted", message: "The model belongs to another inspection service.")
        }
        return try InspectionModelArchive.decode(await connection.download(manifest))
    }

    static func signal(_ operation: @escaping @MainActor () async throws -> [AnyObject]) -> RACSignal<AnyObject> {
        RACSignal<AnyObject>.createSignal { subscriber in
            let task = Task { @MainActor in
                do {
                    for value in try await operation() {
                        try Task.checkCancellation()
                        subscriber.sendNext(value)
                    }
                    subscriber.sendCompleted()
                } catch { subscriber.sendError(error) }
            }
            return RACDisposable { task.cancel() }
        }
    }
}

@objc(LKRemoteInspectableApp)
public final class RemoteInspectableApp: InspectableApp {
    let client: InspectionServiceClient
    let targetIdentifier: String
    @MainActor private weak var mirror: RemoteInspectionSession?

    @MainActor
    init(client: InspectionServiceClient, targetIdentifier: String) {
        self.client = client
        self.targetIdentifier = targetIdentifier
        super.init()
    }

    override public var inspectionSession: InspectionSession! {
        MainActor.assumeIsolated {
            if let mirror {
                return mirror
            }
            let mirror = RemoteInspectionSession(application: self)
            self.mirror = mirror
            return mirror
        }
    }

    override public func performInspectionRequest(withType requestType: UInt32, payload: Any!) -> RACSignal<AnyObject>! {
        MainActor.assumeIsolated { inspectionSession.request(withType: requestType, payload: payload) }
    }

    override public func fetchHierarchyData() -> RACSignal<AnyObject>! {
        MainActor.assumeIsolated { (inspectionSession as! RemoteInspectionSession).readOrCapture() }
    }
}
