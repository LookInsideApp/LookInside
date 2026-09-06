import Darwin
import Dispatch
import Foundation

/// Persistent, multiplexed connection. Reconnection is explicit and never
/// replays a request whose remote execution status may be unknown.
@MainActor
public final class InspectionServiceConnection {
    public var onEvent: ((InspectionEvent) -> Void)?
    public var onDisconnect: ((Error) -> Void)?
    public var isConnected: Bool {
        descriptor >= 0
    }

    private var descriptor: Int32 = -1
    private var reader: DispatchSourceRead?
    private var writer: DispatchSourceWrite?
    private var incoming = Data()
    private var outgoing = Data()
    private var pending: [String: CheckedContinuation<InspectionResponse, Error>] = [:]
    private var deadlines: [String: Task<Void, Never>] = [:]

    public init() {}

    deinit {
        reader?.cancel()
        writer?.cancel()
        if descriptor >= 0 {
            Darwin.close(descriptor)
        }
        for deadline in deadlines.values {
            deadline.cancel()
        }
        for continuation in pending.values {
            continuation.resume(throwing: InspectionFailure(code: "service.disconnected", message: "The inspection connection was released."))
        }
    }

    public func connect(socketPath: String) throws {
        guard !isConnected else { return }
        var address = try InspectionSocketAddress(path: socketPath)
        let connectionDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard connectionDescriptor >= 0 else { throw InspectionFailure.internalError }
        _ = fcntl(connectionDescriptor, F_SETFD, FD_CLOEXEC)
        var enabled: Int32 = 1
        _ = setsockopt(connectionDescriptor, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout<Int32>.size))
        guard address.withAddress({ Darwin.connect(connectionDescriptor, $0, $1) }) == 0 else {
            Darwin.close(connectionDescriptor)
            throw InspectionFailure(code: "service.unavailable", message: "The inspection service is unavailable.")
        }
        var peerUser: uid_t = 0
        var peerGroup: gid_t = 0
        guard getpeereid(connectionDescriptor, &peerUser, &peerGroup) == 0, peerUser == geteuid() else {
            Darwin.close(connectionDescriptor)
            throw InspectionFailure(code: "service.invalidClient", message: "The inspection service belongs to another user.")
        }
        _ = fcntl(connectionDescriptor, F_SETFL, O_NONBLOCK)
        descriptor = connectionDescriptor
        let reader = DispatchSource.makeReadSource(fileDescriptor: connectionDescriptor, queue: .main)
        reader.setEventHandler { [weak self] in self?.readAvailableBytes() }
        self.reader = reader
        reader.resume()
    }

    public func close() {
        disconnect(InspectionFailure(code: "service.disconnected", message: "The inspection connection closed."))
    }

    public func request(_ method: String, parameters: [String: InspectionValue]? = nil,
                        timeout: TimeInterval = 30) async throws -> InspectionResponse
    {
        try Task.checkCancellation()
        guard isConnected else { throw InspectionFailure(code: "service.unavailable", message: "Connect to the inspection service first.") }
        let identifier = UUID().uuidString
        var frame = try JSONEncoder().encode(InspectionRequest(identifier: identifier, method: method, parameters: parameters))
        frame.append(0x0A)
        guard frame.count <= InspectionSocketClient.maximumFrameSize,
              outgoing.count <= InspectionSocketClient.maximumFrameSize - frame.count,
              pending.count < 32
        else {
            throw InspectionFailure(code: "service.capacityExceeded", message: "Too many inspection requests are pending.")
        }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending[identifier] = continuation
                deadlines[identifier] = Task { [weak self] in
                    do { try await Task.sleep(for: .seconds(timeout)) } catch { return }
                    self?.finish(identifier: identifier, result: .failure(InspectionFailure(code: "operation.timeout",
                                                                                            message: "The inspection request timed out. It was not retried.")))
                }
                outgoing.append(frame)
                writeAvailableBytes()
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.finish(identifier: identifier, result: .failure(CancellationError()))
            }
        }
    }

    public func download(_ manifest: InspectionTransferManifest) async throws -> Data {
        var assembler = try InspectionTransferAssembler(manifest: manifest)
        do {
            while !assembler.isComplete {
                try Task.checkCancellation()
                let offset = assembler.nextOffset
                let response = try await request("transfer.read", parameters: [
                    "transferIdentifier": .string(manifest.transferIdentifier), "offset": .integer(Int64(offset)),
                ])
                if let error = response.error {
                    throw error
                }
                guard let encoded = response.result?.objectValue?["data"]?.stringValue,
                      encoded.utf8.count <= (manifest.chunkByteCount + 2) / 3 * 4,
                      let chunk = Data(base64Encoded: encoded) else { throw InspectionFailure.invalidParameters }
                try assembler.append(chunk, offset: offset)
            }
            let data = try assembler.finish()
            _ = try await request("transfer.release", parameters: ["transferIdentifier": .string(manifest.transferIdentifier)])
            return data
        } catch {
            // Cleanup is a separate operation; it never retries the original request.
            Task { [weak self] in
                _ = try? await self?.request("transfer.release", parameters: ["transferIdentifier": .string(manifest.transferIdentifier)])
            }
            throw error
        }
    }

    public func upload(_ data: Data) async throws -> String {
        let manifest = InspectionTransferManifest(data: data)
        try manifest.validate()
        let response = try await request("transfer.begin", parameters: ["manifest": .encoding(manifest)])
        if let error = response.error {
            throw error
        }
        do {
            var offset = 0
            while offset < data.count {
                try Task.checkCancellation()
                let chunk = data.subdata(in: offset ..< min(data.count, offset + manifest.chunkByteCount))
                let response = try await request("transfer.append", parameters: [
                    "transferIdentifier": .string(manifest.transferIdentifier),
                    "offset": .integer(Int64(offset)), "data": .string(chunk.base64EncodedString()),
                ])
                if let error = response.error {
                    throw error
                }
                offset += chunk.count
            }
            return manifest.transferIdentifier
        } catch {
            Task { [weak self] in
                _ = try? await self?.request("transfer.release", parameters: ["transferIdentifier": .string(manifest.transferIdentifier)])
            }
            throw error
        }
    }

    private func readAvailableBytes() {
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        while isConnected {
            let count = recv(descriptor, &buffer, buffer.count, 0)
            if count < 0, errno == EINTR {
                continue
            }
            if count < 0, errno == EAGAIN {
                return
            }
            guard count > 0 else { disconnect(unavailableError()); return }
            incoming.append(contentsOf: buffer.prefix(count))
            guard incoming.count <= InspectionSocketClient.maximumFrameSize else { disconnect(unavailableError()); return }
            while let terminator = incoming.firstIndex(of: 0x0A) {
                let frame = Data(incoming.prefix(upTo: terminator))
                incoming.removeSubrange(...terminator)
                if let response = try? JSONDecoder().decode(InspectionResponse.self, from: frame),
                   response.kind == .response, (response.result == nil) != (response.error == nil)
                {
                    finish(identifier: response.identifier, result: .success(response))
                } else if let event = try? JSONDecoder().decode(InspectionEvent.self, from: frame), event.kind == .event {
                    onEvent?(event)
                } else {
                    disconnect(unavailableError()); return
                }
            }
        }
    }

    private func writeAvailableBytes() {
        while isConnected, !outgoing.isEmpty {
            let count = outgoing.withUnsafeBytes { send(descriptor, $0.baseAddress, $0.count, 0) }
            if count < 0, errno == EINTR {
                continue
            }
            if count < 0, errno == EAGAIN {
                if writer == nil {
                    let writer = DispatchSource.makeWriteSource(fileDescriptor: descriptor, queue: .main)
                    writer.setEventHandler { [weak self] in self?.writeAvailableBytes() }
                    self.writer = writer
                    writer.resume()
                }
                return
            }
            guard count > 0 else { disconnect(unavailableError()); return }
            outgoing.removeFirst(count)
        }
        writer?.cancel()
        writer = nil
    }

    private func finish(identifier: String, result: Result<InspectionResponse, Error>) {
        deadlines.removeValue(forKey: identifier)?.cancel()
        pending.removeValue(forKey: identifier)?.resume(with: result)
    }

    private func disconnect(_ error: Error) {
        guard isConnected else { return }
        reader?.cancel()
        writer?.cancel()
        reader = nil
        writer = nil
        Darwin.close(descriptor)
        descriptor = -1
        incoming.removeAll()
        outgoing.removeAll()
        for identifier in Array(pending.keys) {
            finish(identifier: identifier, result: .failure(error))
        }
        onDisconnect?(error)
    }

    private func unavailableError() -> InspectionFailure {
        InspectionFailure(code: "service.disconnected", message: "The inspection service disconnected. Pending operations were not replayed.")
    }
}
