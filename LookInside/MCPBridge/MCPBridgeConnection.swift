// MCPBridgeConnection.swift
//
// Per-client connection handler for the MCPBridge Unix domain socket.
//
// Each accepted connection becomes one `MCPBridgeConnection` instance that
// reads newline-delimited JSON frames from its socket, decodes them as
// `MCPBridgeRequest`, dispatches via a request handler closure, and writes
// the resulting `MCPBridgeResponse` (or pushed `MCPBridgeEvent`) back.
//
// Buffering is line-oriented: bytes accumulate in a buffer until a `\n`
// separator is found; partial frames are tolerated across read events but
// individual frames must fit within the buffer's high-water mark.
//
// Concurrency: every piece of mutable state here — the read buffer, the
// closed flag, the read source — and every `write(2)` on the socket is
// confined to `connectionQueue`, a serial queue private to this
// connection. The serialization is load-bearing rather than defensive:
// requests are dispatched concurrently (each inbound frame spawns its
// own `Task`), so without it two responses could interleave their
// `write(2)` calls mid-frame and hand the peer a corrupt JSON line.
// Large frames — screenshots above all — widen that window enough to
// make it routine. The queue targets the shared I/O queue supplied by
// the server, so distinct connections still proceed in parallel.

import Darwin
import Dispatch
import Foundation
import os

final class MCPBridgeConnection {
    typealias RequestHandler = @Sendable (MCPBridgeRequest) async -> MCPBridgeResponse

    /// Maximum accumulated bytes for a single frame before the connection is
    /// torn down. Inspection responses can carry large screenshot data so the
    /// limit is generous; this is purely a safety cap against runaway peers.
    private static let maximumFrameBytes = 8 * 1024 * 1024

    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Connection")

    private let fileDescriptor: Int32
    private let connectionQueue: DispatchQueue
    private let requestHandler: RequestHandler
    private let onClose: @Sendable (MCPBridgeConnection) -> Void

    /// All three are `connectionQueue`-confined; never touch them from
    /// another thread.
    private var readSource: DispatchSourceRead?
    private var readBuffer = Data()
    private var isClosed = false

    init(
        fileDescriptor: Int32,
        queue: DispatchQueue,
        requestHandler: @escaping RequestHandler,
        onClose: @escaping @Sendable (MCPBridgeConnection) -> Void
    ) {
        self.fileDescriptor = fileDescriptor
        connectionQueue = DispatchQueue(
            label: "com.lookinside.mcp-bridge.connection.\(fileDescriptor)",
            target: queue
        )
        self.requestHandler = requestHandler
        self.onClose = onClose
    }

    func start() {
        connectionQueue.async { [weak self] in
            guard let self else { return }
            let source = DispatchSource.makeReadSource(
                fileDescriptor: self.fileDescriptor,
                queue: self.connectionQueue
            )
            source.setEventHandler { [weak self] in
                self?.handleReadable()
            }
            source.setCancelHandler { [weak self] in
                guard let self else { return }
                Darwin.close(self.fileDescriptor)
            }
            self.readSource = source
            source.resume()
        }
    }

    /// Closes the connection. Safe to call from any thread; the actual
    /// teardown hops onto `connectionQueue`.
    func close(reason: String) {
        // Strong capture on purpose. This block is what cancels the read
        // source and closes the socket, so it must still run when the caller
        // drops its reference first -- which is exactly what
        // `MCPBridgeServer.stop()` does when it clears `openConnections`.
        // Captured weakly, shutdown would leak the descriptor and leave a
        // live read source firing on a connection nobody owns.
        connectionQueue.async {
            self.closeOnConnectionQueue(reason: reason)
        }
    }

    /// Teardown proper. Callers must already be on `connectionQueue`.
    private func closeOnConnectionQueue(reason: String) {
        dispatchPrecondition(condition: .onQueue(connectionQueue))
        guard isClosed == false else { return }
        isClosed = true
        Self.logger.notice("Connection closed: \(reason, privacy: .public)")
        readSource?.cancel()
        readSource = nil
        onClose(self)
    }

    // MARK: - Read path

    private func handleReadable() {
        dispatchPrecondition(condition: .onQueue(connectionQueue))
        guard isClosed == false else { return }
        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = buffer.withUnsafeMutableBufferPointer { pointer -> ssize_t in
            read(fileDescriptor, pointer.baseAddress, pointer.count)
        }
        if bytesRead == 0 {
            closeOnConnectionQueue(reason: "peer closed (EOF)")
            return
        }
        if bytesRead < 0 {
            let errorNumber = errno
            if errorNumber == EAGAIN || errorNumber == EWOULDBLOCK {
                return
            }
            closeOnConnectionQueue(reason: "read failed (errno \(errorNumber))")
            return
        }
        readBuffer.append(buffer, count: bytesRead)
        if readBuffer.count > Self.maximumFrameBytes {
            closeOnConnectionQueue(reason: "frame buffer exceeded \(Self.maximumFrameBytes) bytes")
            return
        }
        drainFrames()
    }

    private func drainFrames() {
        while let newlineIndex = readBuffer.firstIndex(of: UInt8(ascii: "\n")) {
            let frameSlice = readBuffer[readBuffer.startIndex ..< newlineIndex]
            let frameData = Data(frameSlice)
            readBuffer.removeSubrange(readBuffer.startIndex ... newlineIndex)
            if frameData.isEmpty {
                continue
            }
            dispatchFrame(frameData)
        }
    }

    private func dispatchFrame(_ frameData: Data) {
        do {
            let request = try JSONDecoder().decode(MCPBridgeRequest.self, from: frameData)
            Task { [weak self] in
                guard let self else { return }
                let response = await self.requestHandler(request)
                self.send(response: response)
            }
        } catch {
            Self.logger.error("Failed to decode inbound frame as request: \(error.localizedDescription, privacy: .public)")
            // No identifier available — push a generic error event so the peer
            // can observe the malformed frame without correlating to a request.
            let event = MCPBridgeEvent(
                topic: "frame.decodeError",
                payload: ["message": .string(error.localizedDescription)]
            )
            send(event: event)
        }
    }

    // MARK: - Write path

    func send(response: MCPBridgeResponse) {
        sendCodable(response)
    }

    func send(event: MCPBridgeEvent) {
        sendCodable(event)
    }

    private func sendCodable(_ value: some Encodable) {
        // Encoding is pure CPU work over a local value, so it stays on
        // the calling thread; only the socket write is serialized.
        let data: Data
        do {
            var encoded = try JSONEncoder().encode(value)
            encoded.append(UInt8(ascii: "\n"))
            data = encoded
        } catch {
            Self.logger.error("Failed to encode outbound frame: \(error.localizedDescription, privacy: .public)")
            return
        }
        connectionQueue.async { [weak self] in
            guard let self, self.isClosed == false else { return }
            self.writeAll(data)
        }
    }

    private func writeAll(_ data: Data) {
        dispatchPrecondition(condition: .onQueue(connectionQueue))
        guard isClosed == false else { return }
        var remaining = data
        while remaining.isEmpty == false {
            let written = remaining.withUnsafeBytes { rawBufferPointer -> ssize_t in
                guard let baseAddress = rawBufferPointer.baseAddress else { return 0 }
                return write(fileDescriptor, baseAddress, rawBufferPointer.count)
            }
            if written < 0 {
                let errorNumber = errno
                if errorNumber == EINTR {
                    continue
                }
                if errorNumber == EAGAIN || errorNumber == EWOULDBLOCK {
                    // Unreachable while the descriptor is blocking, which
                    // `MCPBridgeListenSocket.acceptConnection` guarantees --
                    // and that guarantee is load-bearing: on macOS accept(2)
                    // inherits O_NONBLOCK from the (necessarily non-blocking)
                    // listener, and a non-blocking descriptor lands here
                    // partway through any response larger than the socket send
                    // buffer, tearing the connection down mid-frame. Kept as a
                    // backstop; if it ever fires, fix the descriptor's mode
                    // rather than making this branch retry.
                    closeOnConnectionQueue(reason: "write would block (errno \(errorNumber))")
                    return
                }
                closeOnConnectionQueue(reason: "write failed (errno \(errorNumber))")
                return
            }
            remaining.removeFirst(written)
        }
    }
}
