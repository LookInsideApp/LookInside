// LKMCPBridgeServer.swift
//
// The MCPBridge server is the GPL-side surface that exposes LookInside's
// inspection state over a local Unix domain socket. Proprietary consumers
// (currently only the `lookinside-mcp` MCP shim, but the surface is designed
// to also serve future CI bridges, remote inspectors, and automation runners)
// connect to this socket and exchange newline-delimited JSON frames.
//
// Process model: the server runs inside the LookInside.app host process.
// Activation is keyed off `applicationDidFinishLaunching:` and shutdown is
// keyed off `applicationWillTerminate:`. The server is intentionally a
// process-global singleton (the host has exactly one inspection state).
//
// Socket location: a single per-user UNIX socket inside the user's
// Application Support directory, with `0o600` permissions and a `0o700`
// parent directory. The path is stable across host restarts.

import Darwin
import Dispatch
import Foundation
import os

@objc(LKMCPBridgeServer)
public final class LKMCPBridgeServer: NSObject {

    // MARK: - Singleton

    @objc public static let sharedInstance = LKMCPBridgeServer()

    // MARK: - Configuration

    /// Maximum number of pending connections in the kernel accept queue.
    private static let listenBacklog: Int32 = 16

    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Server")

    // MARK: - State

    private let stateQueue = DispatchQueue(label: "com.lookinside.mcp-bridge.state")
    private let ioQueue = DispatchQueue(
        label: "com.lookinside.mcp-bridge.io",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private var listenFileDescriptor: Int32 = -1
    private var acceptSource: DispatchSourceRead?
    private var activeConnections: Set<ObjectIdentifier> = []
    private var openConnections: [ObjectIdentifier: LKMCPBridgeConnection] = [:]
    private var isRunning = false

    // MARK: - Lifecycle

    @objc public func start() {
        stateQueue.async { [weak self] in
            guard let self else { return }
            guard self.isRunning == false else { return }
            do {
                try self.bindAndListen()
                self.isRunning = true
                Self.logger.notice("MCPBridge started at \(LKMCPBridgeServer.socketURL.path, privacy: .public)")
            } catch {
                Self.logger.error("MCPBridge failed to start: \(error.localizedDescription, privacy: .public)")
                self.cleanUpListenSocket()
            }
        }
    }

    @objc public func stop() {
        stateQueue.async { [weak self] in
            guard let self else { return }
            guard self.isRunning else { return }
            self.isRunning = false
            self.acceptSource?.cancel()
            self.acceptSource = nil
            self.cleanUpListenSocket()
            for connection in self.openConnections.values {
                connection.close(reason: "server shutdown")
            }
            self.openConnections.removeAll()
            self.activeConnections.removeAll()
            Self.logger.notice("MCPBridge stopped")
        }
    }

    // MARK: - Bind / Listen / Accept

    private func bindAndListen() throws {
        let socketURL = Self.socketURL
        try ensureRuntimeDirectory(at: socketURL.deletingLastPathComponent())
        unlink(socketURL.path)

        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            throw MCPBridgeServerError(message: "socket(AF_UNIX) failed (errno \(errno))")
        }
        listenFileDescriptor = descriptor

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(socketURL.path.utf8)
        let pathCapacity = MemoryLayout.size(ofValue: address.sun_path)
        if pathBytes.count >= pathCapacity {
            throw MCPBridgeServerError(message: "Socket path is longer than the kernel's sun_path limit (\(pathCapacity) bytes).")
        }
        withUnsafeMutableBytes(of: &address.sun_path) { pathBuffer in
            for index in 0..<pathBytes.count {
                pathBuffer[index] = pathBytes[index]
            }
            pathBuffer[pathBytes.count] = 0
        }

        let bindResult = withUnsafePointer(to: &address) { addressPointer -> Int32 in
            return addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { rebound in
                return Darwin.bind(descriptor, rebound, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        if bindResult != 0 {
            throw MCPBridgeServerError(message: "bind() failed (errno \(errno))")
        }

        if chmod(socketURL.path, 0o600) != 0 {
            Self.logger.warning("chmod 0600 on socket failed (errno \(errno)); continuing with default permissions")
        }

        if listen(descriptor, Self.listenBacklog) != 0 {
            throw MCPBridgeServerError(message: "listen() failed (errno \(errno))")
        }

        let source = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: stateQueue)
        source.setEventHandler { [weak self] in
            self?.acceptPendingConnections()
        }
        source.setCancelHandler {
            close(descriptor)
        }
        acceptSource = source
        source.resume()
    }

    private func acceptPendingConnections() {
        while true {
            var clientAddress = sockaddr_un()
            var addressLength = socklen_t(MemoryLayout<sockaddr_un>.size)
            let clientDescriptor = withUnsafeMutablePointer(to: &clientAddress) { addressPointer -> Int32 in
                return addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { rebound in
                    return accept(listenFileDescriptor, rebound, &addressLength)
                }
            }
            if clientDescriptor < 0 {
                let errorNumber = errno
                if errorNumber == EAGAIN || errorNumber == EWOULDBLOCK {
                    return
                }
                Self.logger.error("accept() failed (errno \(errorNumber))")
                return
            }
            let connection = LKMCPBridgeConnection(
                fileDescriptor: clientDescriptor,
                queue: ioQueue,
                requestHandler: { [weak self] request in
                    return await self?.handle(request: request) ?? .failure(
                        identifier: request.identifier,
                        error: .internalError
                    )
                },
                onClose: { [weak self] closingConnection in
                    self?.removeConnection(closingConnection)
                }
            )
            let key = ObjectIdentifier(connection)
            openConnections[key] = connection
            activeConnections.insert(key)
            Self.logger.notice("Accepted connection (fd=\(clientDescriptor))")
            connection.start()
        }
    }

    private func removeConnection(_ connection: LKMCPBridgeConnection) {
        stateQueue.async { [weak self] in
            guard let self else { return }
            let key = ObjectIdentifier(connection)
            self.openConnections.removeValue(forKey: key)
            self.activeConnections.remove(key)
        }
    }

    // MARK: - Request dispatch

    private func handle(request: LKMCPBridgeRequest) async -> LKMCPBridgeResponse {
        // Phase 1 (v0): no methods implemented yet. Return a structured
        // `unknownMethod` error for every method except `ping` so the wire
        // pipeline can be smoke-tested end-to-end without committing to any
        // inspection schema. Real method handlers will be wired in a later
        // commit once `MCPBridgeEntitlement` / `MCPBridgeTargetRegistry` /
        // `MCPBridgeEventCoalescer` land.
        switch request.method {
        case "ping":
            return .success(
                identifier: request.identifier,
                result: .object([
                    "pong": .bool(true),
                    "serverVersion": .string(currentHostMarketingVersion()),
                ])
            )
        default:
            return .failure(identifier: request.identifier, error: .unknownMethod)
        }
    }

    // MARK: - Helpers

    private func cleanUpListenSocket() {
        if listenFileDescriptor >= 0 {
            close(listenFileDescriptor)
            listenFileDescriptor = -1
        }
        unlink(Self.socketURL.path)
    }

    private func ensureRuntimeDirectory(at directoryURL: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        // createDirectory ignores posixPermissions on pre-existing dirs;
        // re-apply 0o700 to lock down any inherited permissive state.
        _ = chmod(directoryURL.path, 0o700)
    }

    private func currentHostMarketingVersion() -> String {
        return (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"
    }

    // MARK: - Socket location

    /// Canonical socket location: `~/Library/Application Support/LookInside/Host/run/lookinside-host-mcp.sock`.
    public static let socketURL: URL = {
        let fileManager = FileManager.default
        let applicationSupportURL = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
        return applicationSupportURL
            .appendingPathComponent("LookInside", isDirectory: true)
            .appendingPathComponent("Host", isDirectory: true)
            .appendingPathComponent("run", isDirectory: true)
            .appendingPathComponent("lookinside-host-mcp.sock", isDirectory: false)
    }()
}

// MARK: - Local error type

private struct MCPBridgeServerError: LocalizedError {
    let message: String
    var errorDescription: String? { return message }
}
