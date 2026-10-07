import Darwin
import Foundation

/// Regression coverage for the MCPBridge listening socket.
///
/// The socket used to be created blocking. `LKMCPBridgeServer` drains
/// accepts in a `while true` loop that treats `EAGAIN` as "no more
/// pending connections", so on a blocking descriptor the second
/// `accept(2)` of each drain parked the server's serial state queue
/// until another client happened to connect. One connected client was
/// enough to wedge `stop()` and all connection bookkeeping behind it.
///
/// `testSecondAcceptReturnsPromptly` is the one that reproduces it: it
/// fails (rather than hanging) if the descriptor ever goes back to
/// blocking mode.
@main
struct LKMCPBridgeListenSocketTests {
    static func main() {
        testDescriptorIsNonBlocking()
        testAcceptWithNoPendingConnectionsReturnsImmediately()
        testSecondAcceptReturnsPromptly()
        testAcceptedConnectionIsBlocking()
        testSocketFileIsOwnerOnly()
        testStaleSocketFileIsReplaced()
        print("MCPBridge listen socket tests passed")
    }

    // MARK: - Tests

    private static func testDescriptorIsNonBlocking() {
        let socketPath = makeTemporarySocketPath()
        defer { unlink(socketPath) }

        guard let descriptor = try? LKMCPBridgeListenSocket.makeListening(atPath: socketPath, backlog: 16) else {
            fail("makeListening should succeed on a fresh path")
        }
        defer { Darwin.close(descriptor) }

        expect(
            LKMCPBridgeListenSocket.isNonBlocking(descriptor: descriptor),
            "listening descriptor must be non-blocking so the accept drain loop can terminate"
        )
    }

    private static func testAcceptWithNoPendingConnectionsReturnsImmediately() {
        let socketPath = makeTemporarySocketPath()
        defer { unlink(socketPath) }

        guard let descriptor = try? LKMCPBridgeListenSocket.makeListening(atPath: socketPath, backlog: 16) else {
            fail("makeListening should succeed on a fresh path")
        }
        defer { Darwin.close(descriptor) }

        let accepted = accept(descriptor, nil, nil)
        let savedErrorNumber = errno
        expect(accepted < 0, "accept with no pending connection must not produce a descriptor")
        expect(
            savedErrorNumber == EAGAIN || savedErrorNumber == EWOULDBLOCK,
            "accept with no pending connection must report EAGAIN, got errno \(savedErrorNumber)"
        )
    }

    /// The actual wedge. Connect one client, accept it, then ask for
    /// another the way the drain loop does. On a blocking descriptor
    /// that second call never returns.
    private static func testSecondAcceptReturnsPromptly() {
        let socketPath = makeTemporarySocketPath()
        defer { unlink(socketPath) }

        guard let listenDescriptor = try? LKMCPBridgeListenSocket.makeListening(atPath: socketPath, backlog: 16) else {
            fail("makeListening should succeed on a fresh path")
        }
        defer { Darwin.close(listenDescriptor) }

        guard let clientDescriptor = connectClient(toPath: socketPath) else {
            fail("test client should connect to the listening socket")
        }
        defer { Darwin.close(clientDescriptor) }

        let firstAccepted = acceptWithRetry(listenDescriptor: listenDescriptor)
        expect(firstAccepted >= 0, "the pending client connection must be accepted")
        defer {
            if firstAccepted >= 0 {
                Darwin.close(firstAccepted)
            }
        }

        // Run the second accept off the main thread with a watchdog, so
        // a regression reports a failure instead of hanging the suite.
        let completion = DispatchSemaphore(value: 0)
        let resultLock = NSLock()
        var secondAcceptErrorNumber: Int32 = 0
        var secondAcceptDescriptor: Int32 = -1

        DispatchQueue.global().async {
            let accepted = accept(listenDescriptor, nil, nil)
            let savedErrorNumber = errno
            resultLock.lock()
            secondAcceptDescriptor = accepted
            secondAcceptErrorNumber = savedErrorNumber
            resultLock.unlock()
            completion.signal()
        }

        let waitResult = completion.wait(timeout: .now() + 2)
        expect(
            waitResult == .success,
            "the second accept blocked instead of returning EAGAIN — the drain loop would wedge the server's state queue"
        )
        guard waitResult == .success else { return }

        resultLock.lock()
        let accepted = secondAcceptDescriptor
        let savedErrorNumber = secondAcceptErrorNumber
        resultLock.unlock()

        expect(accepted < 0, "the second accept must not produce a descriptor")
        expect(
            savedErrorNumber == EAGAIN || savedErrorNumber == EWOULDBLOCK,
            "the second accept must report EAGAIN, got errno \(savedErrorNumber)"
        )
    }

    /// The listening socket must be non-blocking, but the connections
    /// it hands out must not be.
    ///
    /// On BSD-derived systems -- macOS included -- accept(2) inherits
    /// O_NONBLOCK from the listener, the opposite of Linux. Connection
    /// writes are blocking by design (`LKMCPBridgeConnection.writeAll`
    /// treats EAGAIN as fatal and closes), so an inherited flag turns
    /// any response larger than the socket send buffer into a dropped
    /// connection. Small frames still work, which is what makes this
    /// fail so selectively: hierarchy reads are fine and screenshots
    /// kill the connection.
    private static func testAcceptedConnectionIsBlocking() {
        let socketPath = makeTemporarySocketPath()
        defer { unlink(socketPath) }

        guard let listenDescriptor = try? LKMCPBridgeListenSocket.makeListening(atPath: socketPath, backlog: 16) else {
            fail("makeListening should succeed on a fresh path")
        }
        defer { Darwin.close(listenDescriptor) }

        guard let clientDescriptor = connectClient(toPath: socketPath) else {
            fail("test client should connect to the listening socket")
        }
        defer { Darwin.close(clientDescriptor) }

        let accepted = LKMCPBridgeListenSocket.acceptConnection(listenDescriptor: listenDescriptor)
        expect(accepted >= 0, "the pending client connection must be accepted")
        defer { Darwin.close(accepted) }

        expect(
            LKMCPBridgeListenSocket.isNonBlocking(descriptor: accepted) == false,
            "accepted connections must be blocking; a non-blocking one drops any frame larger than the send buffer"
        )
    }

    private static func testSocketFileIsOwnerOnly() {
        let socketPath = makeTemporarySocketPath()
        defer { unlink(socketPath) }

        guard let descriptor = try? LKMCPBridgeListenSocket.makeListening(atPath: socketPath, backlog: 16) else {
            fail("makeListening should succeed on a fresh path")
        }
        defer { Darwin.close(descriptor) }

        var fileStatus = stat()
        guard stat(socketPath, &fileStatus) == 0 else {
            fail("the socket file should exist after makeListening")
        }
        let permissionBits = fileStatus.st_mode & 0o777
        expect(
            permissionBits == LKMCPBridgeListenSocket.socketFilePermissions,
            "socket must be owner-only, got \(String(permissionBits, radix: 8))"
        )
    }

    /// A host that crashed leaves its socket file behind. Without the
    /// unlink, every subsequent launch would fail to bind.
    private static func testStaleSocketFileIsReplaced() {
        let socketPath = makeTemporarySocketPath()
        defer { unlink(socketPath) }

        guard let firstDescriptor = try? LKMCPBridgeListenSocket.makeListening(atPath: socketPath, backlog: 16) else {
            fail("makeListening should succeed on a fresh path")
        }
        // Close without unlinking: exactly what a crash leaves behind.
        Darwin.close(firstDescriptor)

        guard let secondDescriptor = try? LKMCPBridgeListenSocket.makeListening(atPath: socketPath, backlog: 16) else {
            fail("makeListening should replace a stale socket file rather than failing to bind")
        }
        Darwin.close(secondDescriptor)
    }

    // MARK: - Helpers

    /// Socket paths are capped at 104 bytes by the kernel, so this stays
    /// directly under /tmp rather than in a nested temporary directory.
    private static func makeTemporarySocketPath() -> String {
        let uniqueSuffix = UUID().uuidString.prefix(8)
        return "/tmp/lkmcp-listen-\(uniqueSuffix).sock"
    }

    private static func connectClient(toPath socketPath: String) -> Int32? {
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { return nil }
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(socketPath.utf8)
        withUnsafeMutableBytes(of: &address.sun_path) { pathBuffer in
            for index in 0 ..< pathBytes.count {
                pathBuffer[index] = pathBytes[index]
            }
            pathBuffer[pathBytes.count] = 0
        }
        let connectResult = withUnsafePointer(to: &address) { addressPointer -> Int32 in
            addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { rebound in
                Darwin.connect(descriptor, rebound, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        if connectResult != 0 {
            Darwin.close(descriptor)
            return nil
        }
        return descriptor
    }

    /// `connect(2)` returning does not guarantee the kernel has already
    /// queued the connection on the listener, so give it a moment before
    /// concluding there is nothing to accept.
    private static func acceptWithRetry(listenDescriptor: Int32) -> Int32 {
        for _ in 0 ..< 100 {
            let accepted = accept(listenDescriptor, nil, nil)
            if accepted >= 0 {
                return accepted
            }
            if errno != EAGAIN && errno != EWOULDBLOCK {
                return accepted
            }
            usleep(10000)
        }
        return -1
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        Foundation.exit(1)
    }
}
