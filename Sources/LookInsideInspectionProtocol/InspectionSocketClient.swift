import Darwin
import Foundation

public enum InspectionSocketClient {
    public static let maximumFrameSize = 64 * 1024 * 1024

    public static func request(_ request: InspectionRequest, socketPath: String, timeout: TimeInterval = 30) throws -> InspectionResponse {
        var outgoing = try JSONEncoder().encode(request)
        outgoing.append(0x0A)
        let received = try exchange(outgoing, socketPath: socketPath, timeout: timeout, readsUntilEnd: false)
        guard let response = try? JSONDecoder().decode(InspectionResponse.self, from: received),
              response.kind == .response, response.identifier == request.identifier,
              (response.result == nil) != (response.error == nil) else { throw invalidResponse() }
        guard response.metadata?.schemaVersion == InspectionMetadata.currentSchemaVersion else {
            throw InspectionFailure(code: "service.incompatible", message: "The CLI and service protocol versions differ. Use the CLI bundled with the running service.")
        }
        return response
    }

    /// The authorization helper uses an EOF-delimited exchange. Its payload is
    /// independent of inspection frames; callers validate that protocol themselves.
    public static func exchangeUntilEnd(_ outgoing: Data, socketPath: String, timeout: TimeInterval = 3,
                                        validatePeer: ((pid_t) throws -> Void)? = nil) throws -> Data
    {
        try exchange(outgoing, socketPath: socketPath, timeout: timeout, readsUntilEnd: true, validatePeer: validatePeer)
    }

    private static func exchange(_ outgoing: Data, socketPath: String, timeout: TimeInterval, readsUntilEnd: Bool,
                                 validatePeer: ((pid_t) throws -> Void)? = nil) throws -> Data
    {
        var address = try InspectionSocketAddress(path: socketPath)
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw unavailable() }
        defer { close(descriptor) }
        _ = fcntl(descriptor, F_SETFD, FD_CLOEXEC)
        _ = fcntl(descriptor, F_SETFL, O_NONBLOCK)
        var enabled: Int32 = 1
        _ = setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout<Int32>.size))
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        let connectionStatus = address.withAddress { connect(descriptor, $0, $1) }
        if connectionStatus != 0 {
            guard errno == EINPROGRESS else { throw unavailable() }
            try wait(descriptor: descriptor, events: Int16(POLLOUT), deadline: deadline)
            var socketError: Int32 = 0
            var length = socklen_t(MemoryLayout<Int32>.size)
            guard getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &socketError, &length) == 0, socketError == 0 else { throw unavailable() }
        }
        var peerUser: uid_t = 0
        var peerGroup: gid_t = 0
        guard getpeereid(descriptor, &peerUser, &peerGroup) == 0, peerUser == geteuid() else { throw unavailable() }
        if let validatePeer {
            var peerProcessIdentifier: pid_t = 0
            var length = socklen_t(MemoryLayout<pid_t>.size)
            guard getsockopt(descriptor, SOL_LOCAL, LOCAL_PEERPID, &peerProcessIdentifier, &length) == 0 else { throw unavailable() }
            try validatePeer(peerProcessIdentifier)
        }

        guard outgoing.count <= maximumFrameSize else { throw InspectionFailure.invalidParameters }
        var sentCount = 0
        while sentCount < outgoing.count {
            try wait(descriptor: descriptor, events: Int16(POLLOUT), deadline: deadline)
            let writtenCount = outgoing.withUnsafeBytes { bytes in
                send(descriptor, bytes.baseAddress!.advanced(by: sentCount), bytes.count - sentCount, 0)
            }
            if writtenCount < 0, errno == EINTR || errno == EAGAIN {
                continue
            }
            guard writtenCount > 0 else { throw unavailable() }
            sentCount += writtenCount
        }
        if readsUntilEnd {
            shutdown(descriptor, SHUT_WR)
        }
        var received = Data()
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        while true {
            try wait(descriptor: descriptor, events: Int16(POLLIN), deadline: deadline)
            let receivedCount = recv(descriptor, &buffer, buffer.count, 0)
            if receivedCount < 0, errno == EINTR || errno == EAGAIN {
                continue
            }
            if receivedCount == 0, readsUntilEnd, !received.isEmpty {
                return received
            }
            guard receivedCount > 0 else { throw unavailable() }
            received.append(contentsOf: buffer.prefix(receivedCount))
            guard received.count <= maximumFrameSize else { throw invalidResponse() }
            while !readsUntilEnd, let terminator = received.firstIndex(of: 0x0A) {
                let frame = Data(received.prefix(upTo: terminator))
                received.removeSubrange(...terminator)
                if let event = try? JSONDecoder().decode(InspectionEvent.self, from: frame), event.kind == .event {
                    continue
                }
                return frame
            }
        }
    }

    private static func wait(descriptor: Int32, events: Int16, deadline: TimeInterval) throws {
        while true {
            let remaining = deadline - ProcessInfo.processInfo.systemUptime
            guard remaining > 0 else { throw InspectionFailure(code: "operation.timeout", message: "The inspection request timed out.") }
            var descriptorEvent = pollfd(fd: descriptor, events: events, revents: 0)
            let status = poll(&descriptorEvent, 1, Int32(min(remaining * 1000 + 1, Double(Int32.max))))
            if status < 0, errno == EINTR {
                continue
            }
            guard status >= 0 else { throw unavailable() }
            if status == 0 {
                continue
            }
            if descriptorEvent.revents & events != 0 {
                return
            }
            if events == Int16(POLLIN), descriptorEvent.revents & Int16(POLLHUP) != 0 {
                return
            }
            throw unavailable()
        }
    }

    private static func unavailable() -> InspectionFailure {
        InspectionFailure(code: "service.unavailable", message: "The inspection service is unavailable at the selected socket.")
    }

    private static func invalidResponse() -> InspectionFailure {
        InspectionFailure(code: "service.invalidResponse", message: "The service returned an invalid response.")
    }
}
