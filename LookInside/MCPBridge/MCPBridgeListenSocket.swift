// MCPBridgeListenSocket.swift
//
// Creation of the MCPBridge listening Unix domain socket, split out of
// `MCPBridgeServer` so it can be exercised on its own.
//
// The split exists for a reason beyond tidiness: the socket's blocking
// mode is a correctness property that is invisible at the call site and
// impossible to test through the server, which drags in the whole
// inspection stack (AppKit, NSDocumentController, the ObjC bridge).
// Everything here depends on Darwin and Foundation only, so
// `Tests/MCPBridge/MCPBridgeListenSocketTests.swift` can compile it
// with a bare `swiftc` invocation the way the other host-side tests do.
//
// Why non-blocking matters: the server drives accepts from a
// `DispatchSourceRead` and drains them in a `while true` loop that
// expects `EAGAIN` to signal "no more pending connections". On a
// blocking descriptor that call never returns `EAGAIN` — it parks the
// thread until the *next* client shows up. Since the accept handler
// runs on the server's serial state queue, the first connected client
// would leave that queue occupied indefinitely, and everything else
// scheduled on it (`stop()`, connection bookkeeping) would simply never
// run.

import Darwin
import Foundation

enum MCPBridgeListenSocket {
    /// File permissions for the socket itself: owner-only, matching the
    /// per-user trust model (any process running as this user may
    /// connect; nothing else may).
    static let socketFilePermissions: mode_t = 0o600

    /// Binds and listens on a Unix domain socket at `socketPath`,
    /// returning a non-blocking descriptor ready for `accept(2)`.
    ///
    /// Any existing socket file at the path is unlinked first — a stale
    /// file from a crashed host would otherwise make `bind` fail with
    /// `EADDRINUSE` forever.
    ///
    /// - Throws: `MCPBridgeListenSocketError` when any step fails. The
    ///   descriptor is closed before throwing, so a failed call leaks
    ///   nothing.
    static func makeListening(
        atPath socketPath: String,
        backlog: Int32
    ) throws -> Int32 {
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            throw MCPBridgeListenSocketError(message: "socket(AF_UNIX) failed (errno \(errno))")
        }

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(socketPath.utf8)
        let pathCapacity = MemoryLayout.size(ofValue: address.sun_path)
        if pathBytes.count >= pathCapacity {
            Darwin.close(descriptor)
            throw MCPBridgeListenSocketError(
                message: "Socket path is longer than the kernel's sun_path limit (\(pathCapacity) bytes)."
            )
        }
        withUnsafeMutableBytes(of: &address.sun_path) { pathBuffer in
            for index in 0 ..< pathBytes.count {
                pathBuffer[index] = pathBytes[index]
            }
            pathBuffer[pathBytes.count] = 0
        }

        unlink(socketPath)

        let bindResult = withUnsafePointer(to: &address) { addressPointer -> Int32 in
            addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { rebound in
                Darwin.bind(descriptor, rebound, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        if bindResult != 0 {
            let savedErrorNumber = errno
            Darwin.close(descriptor)
            throw MCPBridgeListenSocketError(message: "bind() failed (errno \(savedErrorNumber))")
        }

        // Best-effort: a permissive umask would otherwise leave the
        // socket group/world accessible. Not fatal — the parent
        // directory is already 0700.
        _ = chmod(socketPath, socketFilePermissions)

        if listen(descriptor, backlog) != 0 {
            let savedErrorNumber = errno
            Darwin.close(descriptor)
            unlink(socketPath)
            throw MCPBridgeListenSocketError(message: "listen() failed (errno \(savedErrorNumber))")
        }

        // The accept drain loop's termination condition. See the file
        // header for what happens without it.
        if fcntl(descriptor, F_SETFL, O_NONBLOCK) != 0 {
            let savedErrorNumber = errno
            Darwin.close(descriptor)
            unlink(socketPath)
            throw MCPBridgeListenSocketError(
                message: "fcntl(F_SETFL, O_NONBLOCK) failed (errno \(savedErrorNumber))"
            )
        }

        return descriptor
    }

    /// Accepts one pending connection, returning a **blocking**
    /// descriptor, or a negative value when there is nothing to accept
    /// (`errno` is `EAGAIN` in that case) or the call failed.
    ///
    /// The blocking mode is the whole reason this wraps `accept(2)`.
    /// On BSD-derived systems — macOS included — the accepted socket
    /// inherits `O_NONBLOCK` from the listener, which is the opposite
    /// of Linux and the opposite of what POSIX requires. Since the
    /// listener has to be non-blocking (see `makeListening`), every
    /// connection would silently come out non-blocking too.
    ///
    /// That matters because `MCPBridgeConnection` writes responses
    /// with a blocking `write(2)` loop and treats `EAGAIN` as fatal.
    /// On a non-blocking descriptor, any response larger than the
    /// socket send buffer hits `EAGAIN` partway through and the
    /// connection is torn down mid-frame. Small responses still work,
    /// so the symptom is selective and confusing: hierarchy reads
    /// succeed, screenshots drop the connection.
    static func acceptConnection(listenDescriptor: Int32) -> Int32 {
        var clientAddress = sockaddr_un()
        var addressLength = socklen_t(MemoryLayout<sockaddr_un>.size)
        let descriptor = withUnsafeMutablePointer(to: &clientAddress) { addressPointer -> Int32 in
            addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { rebound in
                accept(listenDescriptor, rebound, &addressLength)
            }
        }
        guard descriptor >= 0 else { return descriptor }

        let flags = fcntl(descriptor, F_GETFL)
        if flags >= 0 && (flags & O_NONBLOCK) != 0 {
            _ = fcntl(descriptor, F_SETFL, flags & ~O_NONBLOCK)
        }
        return descriptor
    }

    /// Whether `descriptor` is in non-blocking mode. Exists so the
    /// property can be asserted directly rather than inferred from
    /// timing.
    static func isNonBlocking(descriptor: Int32) -> Bool {
        let flags = fcntl(descriptor, F_GETFL)
        guard flags >= 0 else { return false }
        return (flags & O_NONBLOCK) != 0
    }
}

struct MCPBridgeListenSocketError: LocalizedError {
    let message: String
    var errorDescription: String? {
        return message
    }
}
