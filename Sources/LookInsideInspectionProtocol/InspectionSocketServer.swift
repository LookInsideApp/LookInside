import Darwin
import Dispatch
import Foundation

@MainActor
public final class InspectionSocketServer {
    public typealias Handler = @MainActor @Sendable (InspectionRequest, String) async -> InspectionResponse
    public let instanceIdentifier = UUID().uuidString
    public var onStop: (() -> Void)?
    public var onClientDisconnect: ((String) -> Void)?

    private let paths: InspectionRuntimePaths
    private let idleTimeout: TimeInterval
    private let supportedMethods: [String]
    private let handler: Handler
    private var ownership: InspectionFileLock?
    private var listener: DispatchSourceRead?
    private var expiration: DispatchSourceTimer?
    private var terminationSignals: [DispatchSourceSignal] = []
    private var clients: [String: InspectionSocketConnection] = [:]
    private var socketIdentity: (device: dev_t, inode: ino_t)?
    private var lastActivity = ProcessInfo.processInfo.systemUptime

    public init(paths: InspectionRuntimePaths, idleTimeout: TimeInterval = 300,
                supportedMethods: [String] = InspectionCapabilities.methods, handler: @escaping Handler)
    {
        self.paths = paths
        self.idleTimeout = idleTimeout
        self.supportedMethods = supportedMethods
        self.handler = handler
    }

    public func start() throws {
        guard listener == nil else { return }
        try paths.prepareDirectory()
        let ownership = try InspectionFileLock(path: paths.socketPath + ".lock")
        try removeStaleSocket()
        var address = try InspectionSocketAddress(path: paths.socketPath)
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw InspectionFailure.internalError }
        var hasBoundSocket = false
        do {
            _ = fcntl(descriptor, F_SETFD, FD_CLOEXEC)
            _ = fcntl(descriptor, F_SETFL, O_NONBLOCK)
            guard address.withAddress({ bind(descriptor, $0, $1) }) == 0 else { throw InspectionFailure.internalError }
            hasBoundSocket = true
            var information = stat()
            guard lstat(paths.socketPath, &information) == 0 else { throw InspectionFailure.internalError }
            socketIdentity = (information.st_dev, information.st_ino)
            guard chmod(paths.socketPath, 0o600) == 0, listen(descriptor, 32) == 0 else { throw InspectionFailure.internalError }
            let listener = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: .main)
            listener.setEventHandler { [weak self] in self?.acceptConnections(descriptor: descriptor) }
            listener.setCancelHandler { close(descriptor) }
            self.ownership = ownership
            self.listener = listener
            listener.resume()
            installExpirationAndSignals()
        } catch {
            close(descriptor)
            if hasBoundSocket {
                removeOwnedSocket()
            }
            throw error
        }
    }

    public func stop() {
        guard listener != nil else { return }
        expiration?.cancel()
        expiration = nil
        for terminationSignal in terminationSignals {
            terminationSignal.cancel()
        }
        terminationSignals.removeAll()
        for client in Array(clients.values) {
            client.closeConnection()
        }
        clients.removeAll()
        listener?.cancel()
        listener = nil
        removeOwnedSocket()
        ownership = nil
        onStop?()
    }

    private func acceptConnections(descriptor: Int32) {
        while true {
            let connectionDescriptor = accept(descriptor, nil, nil)
            guard connectionDescriptor >= 0 else { return }
            var peerUser: uid_t = 0
            var peerGroup: gid_t = 0
            guard clients.count < 64, getpeereid(connectionDescriptor, &peerUser, &peerGroup) == 0,
                  peerUser == geteuid()
            else {
                close(connectionDescriptor)
                continue
            }
            let connection = InspectionSocketConnection(descriptor: connectionDescriptor)
            let clientIdentifier = connection.identifier
            connection.handler = { [weak self] request in
                guard let self else { return .failure(identifier: request.identifier, error: .internalError) }
                if request.method == "service.status" {
                    return InspectionResponse(identifier: request.identifier, result: .object([
                        "status": .string("running"),
                        "processIdentifier": .integer(Int64(getpid())),
                        "protocolVersion": .integer(Int64(InspectionMetadata.currentSchemaVersion)),
                        "methods": .array(self.supportedMethods.map(InspectionValue.string)),
                        "idleTimeoutSeconds": .double(self.idleTimeout),
                    ]), error: nil, metadata: InspectionMetadata(serviceInstanceIdentifier: self.instanceIdentifier))
                }
                let response = await withTaskGroup(of: InspectionResponse.self) { group in
                    group.addTask { await self.handler(request, clientIdentifier) }
                    group.addTask {
                        try? await Task.sleep(for: .seconds(30))
                        return .failure(identifier: request.identifier, error: InspectionFailure(code: "operation.timeout", message: "The inspection operation exceeded its deadline."))
                    }
                    let response = await group.next()!
                    group.cancelAll()
                    return response
                }
                if response.metadata != nil {
                    return response
                }
                return InspectionResponse(identifier: response.identifier, result: response.result, error: response.error,
                                          metadata: InspectionMetadata(serviceInstanceIdentifier: self.instanceIdentifier))
            }
            connection.onClose = { [weak self] in
                guard let self else { return }
                self.clients.removeValue(forKey: clientIdentifier)
                self.lastActivity = ProcessInfo.processInfo.systemUptime
                self.onClientDisconnect?(clientIdentifier)
            }
            clients[clientIdentifier] = connection
            lastActivity = ProcessInfo.processInfo.systemUptime
            connection.start()
        }
    }

    private func installExpirationAndSignals() {
        let expiration = DispatchSource.makeTimerSource(queue: .main)
        expiration.schedule(deadline: .now() + 0.25, repeating: .milliseconds(250))
        expiration.setEventHandler { [weak self] in
            guard let self else { return }
            for connection in Array(self.clients.values) {
                connection.expirePartialFrame()
            }
            if self.clients.isEmpty, ProcessInfo.processInfo.systemUptime - self.lastActivity >= self.idleTimeout {
                self.stop()
            }
        }
        expiration.resume()
        self.expiration = expiration
        for signalNumber in [SIGTERM, SIGINT] {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler { [weak self] in self?.stop() }
            source.resume()
            terminationSignals.append(source)
        }
    }

    private func removeStaleSocket() throws {
        var information = stat()
        guard lstat(paths.socketPath, &information) == 0 else {
            guard errno == ENOENT else { throw InspectionFailure.internalError }
            return
        }
        guard information.st_mode & S_IFMT == S_IFSOCK, information.st_uid == geteuid() else {
            throw InspectionFailure(code: "service.invalidPath", message: "The socket path is occupied by a file that this service cannot replace.")
        }
        let probe = socket(AF_UNIX, SOCK_STREAM, 0)
        guard probe >= 0 else { throw InspectionFailure.internalError }
        defer { close(probe) }
        _ = fcntl(probe, F_SETFL, O_NONBLOCK)
        var address = try InspectionSocketAddress(path: paths.socketPath)
        let status = address.withAddress { connect(probe, $0, $1) }
        guard status != 0, errno == ECONNREFUSED || errno == ENOENT else {
            throw InspectionFailure(code: "service.inUse", message: "A live process is already listening at this socket.")
        }
        var currentInformation = stat()
        guard lstat(paths.socketPath, &currentInformation) == 0,
              currentInformation.st_dev == information.st_dev, currentInformation.st_ino == information.st_ino,
              unlink(paths.socketPath) == 0 else { throw InspectionFailure.internalError }
    }

    private func removeOwnedSocket() {
        guard let socketIdentity else { return }
        var information = stat()
        if lstat(paths.socketPath, &information) == 0,
           information.st_dev == socketIdentity.device, information.st_ino == socketIdentity.inode
        {
            _ = unlink(paths.socketPath)
        }
        self.socketIdentity = nil
    }
}

@MainActor
private final class InspectionSocketConnection {
    let identifier = UUID().uuidString
    var handler: ((InspectionRequest) async -> InspectionResponse)?
    var onClose: (() -> Void)?
    private let descriptor: Int32
    private var reader: DispatchSourceRead?
    private var writer: DispatchSourceWrite?
    private var incoming = Data()
    private var outgoing = Data()
    private var writtenCount = 0
    private var task: Task<Void, Never>?
    private var deadline = ProcessInfo.processInfo.systemUptime + 30
    private var isClosed = false

    init(descriptor: Int32) {
        self.descriptor = descriptor
        _ = fcntl(descriptor, F_SETFD, FD_CLOEXEC)
        _ = fcntl(descriptor, F_SETFL, O_NONBLOCK)
        var enabled: Int32 = 1
        _ = setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout<Int32>.size))
    }

    func start() {
        let reader = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: .main)
        reader.setEventHandler { [weak self] in self?.readAvailableBytes() }
        self.reader = reader
        reader.resume()
    }

    func closeConnection() {
        guard !isClosed else { return }
        isClosed = true
        task?.cancel()
        task = nil
        reader?.cancel()
        writer?.cancel()
        reader = nil
        writer = nil
        // Sources execute exclusively on the main queue and never use the descriptor
        // in cancellation handlers, so it cannot be reused underneath a callback.
        close(descriptor)
        onClose?()
        onClose = nil
    }

    func expirePartialFrame() {
        if ProcessInfo.processInfo.systemUptime >= deadline {
            closeConnection()
        }
    }

    private func readAvailableBytes() {
        guard !isClosed else { return }
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        while true {
            let receivedCount = recv(descriptor, &buffer, buffer.count, 0)
            if receivedCount < 0, errno == EINTR {
                continue
            }
            if receivedCount < 0, errno == EAGAIN {
                return
            }
            guard receivedCount > 0 else { closeConnection(); return }
            incoming.append(contentsOf: buffer.prefix(receivedCount))
            guard incoming.count <= InspectionSocketClient.maximumFrameSize else { closeConnection(); return }
            if let terminator = incoming.firstIndex(of: 0x0A) {
                guard task == nil, outgoing.isEmpty,
                      incoming.distance(from: terminator, to: incoming.endIndex) == 1,
                      let request = try? JSONDecoder().decode(InspectionRequest.self, from: incoming.prefix(upTo: terminator)),
                      request.kind == .request else { closeConnection(); return }
                incoming.removeAll(keepingCapacity: true)
                deadline = ProcessInfo.processInfo.systemUptime + 45
                task = Task { [weak self] in
                    guard let self, let handler = self.handler else { return }
                    let response = await handler(request)
                    guard !Task.isCancelled, !self.isClosed else { return }
                    self.task = nil
                    self.sendResponse(response)
                }
            }
        }
    }

    private func sendResponse(_ response: InspectionResponse) {
        guard let encoded = try? JSONEncoder().encode(response), encoded.count < InspectionSocketClient.maximumFrameSize else {
            closeConnection()
            return
        }
        outgoing = encoded
        outgoing.append(0x0A)
        writtenCount = 0
        deadline = ProcessInfo.processInfo.systemUptime + 30
        writeAvailableBytes()
        if !outgoing.isEmpty, !isClosed {
            let writer = DispatchSource.makeWriteSource(fileDescriptor: descriptor, queue: .main)
            writer.setEventHandler { [weak self] in self?.writeAvailableBytes() }
            self.writer = writer
            writer.resume()
        }
    }

    private func writeAvailableBytes() {
        guard !isClosed else { return }
        while writtenCount < outgoing.count {
            let sentCount = outgoing.withUnsafeBytes { bytes in
                send(descriptor, bytes.baseAddress!.advanced(by: writtenCount), bytes.count - writtenCount, 0)
            }
            if sentCount < 0, errno == EINTR {
                continue
            }
            if sentCount < 0, errno == EAGAIN {
                return
            }
            guard sentCount > 0 else { closeConnection(); return }
            writtenCount += sentCount
        }
        outgoing.removeAll(keepingCapacity: false)
        writer?.cancel()
        writer = nil
        deadline = ProcessInfo.processInfo.systemUptime + 300
    }
}
