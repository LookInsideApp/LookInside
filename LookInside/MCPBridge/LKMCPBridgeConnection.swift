// LKMCPBridgeConnection.swift
//
// Per-client connection handler for the MCPBridge Unix domain socket.
//
// Each accepted connection becomes one `LKMCPBridgeConnection` instance that
// reads newline-delimited JSON frames from its socket, decodes them as
// `LKMCPBridgeRequest`, dispatches via a request handler closure, and writes
// the resulting `LKMCPBridgeResponse` (or pushed `LKMCPBridgeEvent`) back.
//
// Buffering is line-oriented: bytes accumulate in a buffer until a `\n`
// separator is found; partial frames are tolerated across read events but
// individual frames must fit within the buffer's high-water mark.

import Darwin
import Dispatch
import Foundation
import os

public final class LKMCPBridgeConnection {
    public typealias RequestHandler = @Sendable (LKMCPBridgeRequest) async -> LKMCPBridgeResponse

    /// Maximum accumulated bytes for a single frame before the connection is
    /// torn down. Inspection responses can carry large screenshot data so the
    /// limit is generous; this is purely a safety cap against runaway peers.
    private static let maximumFrameBytes = 8 * 1024 * 1024

    private static let logger = Logger(subsystem: "com.lookinside.app", category: "MCPBridge.Connection")

    private let fileDescriptor: Int32
    private let queue: DispatchQueue
    private let requestHandler: RequestHandler
    private let onClose: @Sendable (LKMCPBridgeConnection) -> Void

    private var readSource: DispatchSourceRead?
    private var readBuffer = Data()
    private var isClosed = false

    public init(
        fileDescriptor: Int32,
        queue: DispatchQueue,
        requestHandler: @escaping RequestHandler,
        onClose: @escaping @Sendable (LKMCPBridgeConnection) -> Void
    ) {
        self.fileDescriptor = fileDescriptor
        self.queue = queue
        self.requestHandler = requestHandler
        self.onClose = onClose
    }

    public func start() {
        let source = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor, queue: queue)
        source.setEventHandler { [weak self] in
            self?.handleReadable()
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            Darwin.close(self.fileDescriptor)
        }
        readSource = source
        source.resume()
    }

    public func close(reason: String) {
        guard isClosed == false else { return }
        isClosed = true
        Self.logger.notice("Connection closed: \(reason, privacy: .public)")
        readSource?.cancel()
        readSource = nil
        onClose(self)
    }

    // MARK: - Read path

    private func handleReadable() {
        guard isClosed == false else { return }
        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = buffer.withUnsafeMutableBufferPointer { pointer -> ssize_t in
            return read(fileDescriptor, pointer.baseAddress, pointer.count)
        }
        if bytesRead == 0 {
            close(reason: "peer closed (EOF)")
            return
        }
        if bytesRead < 0 {
            let errorNumber = errno
            if errorNumber == EAGAIN || errorNumber == EWOULDBLOCK {
                return
            }
            close(reason: "read failed (errno \(errorNumber))")
            return
        }
        readBuffer.append(buffer, count: bytesRead)
        if readBuffer.count > Self.maximumFrameBytes {
            close(reason: "frame buffer exceeded \(Self.maximumFrameBytes) bytes")
            return
        }
        drainFrames()
    }

    private func drainFrames() {
        while let newlineIndex = readBuffer.firstIndex(of: UInt8(ascii: "\n")) {
            let frameSlice = readBuffer[readBuffer.startIndex..<newlineIndex]
            let frameData = Data(frameSlice)
            readBuffer.removeSubrange(readBuffer.startIndex...newlineIndex)
            if frameData.isEmpty {
                continue
            }
            dispatchFrame(frameData)
        }
    }

    private func dispatchFrame(_ frameData: Data) {
        do {
            let request = try JSONDecoder().decode(LKMCPBridgeRequest.self, from: frameData)
            Task { [weak self] in
                guard let self else { return }
                let response = await self.requestHandler(request)
                self.send(response: response)
            }
        } catch {
            Self.logger.error("Failed to decode inbound frame as request: \(error.localizedDescription, privacy: .public)")
            // No identifier available — push a generic error event so the peer
            // can observe the malformed frame without correlating to a request.
            let event = LKMCPBridgeEvent(
                topic: "frame.decodeError",
                payload: ["message": .string(error.localizedDescription)]
            )
            send(event: event)
        }
    }

    // MARK: - Write path

    public func send(response: LKMCPBridgeResponse) {
        sendCodable(response)
    }

    public func send(event: LKMCPBridgeEvent) {
        sendCodable(event)
    }

    private func sendCodable(_ value: some Encodable) {
        guard isClosed == false else { return }
        do {
            var data = try JSONEncoder().encode(value)
            data.append(UInt8(ascii: "\n"))
            queue.async { [weak self] in
                self?.writeAll(data)
            }
        } catch {
            Self.logger.error("Failed to encode outbound frame: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func writeAll(_ data: Data) {
        guard isClosed == false else { return }
        var remaining = data
        while remaining.isEmpty == false {
            let written = remaining.withUnsafeBytes { rawBufferPointer -> ssize_t in
                guard let baseAddress = rawBufferPointer.baseAddress else { return 0 }
                return write(fileDescriptor, baseAddress, rawBufferPointer.count)
            }
            if written < 0 {
                let errorNumber = errno
                if errorNumber == EINTR { continue }
                if errorNumber == EAGAIN || errorNumber == EWOULDBLOCK {
                    // Socket buffer full; in v0 we just close. A future revision
                    // can switch to non-blocking writes with a deferred queue.
                    close(reason: "write would block (errno \(errorNumber))")
                    return
                }
                close(reason: "write failed (errno \(errorNumber))")
                return
            }
            remaining.removeFirst(written)
        }
    }
}
