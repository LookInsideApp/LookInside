//
//  FrameChannel.swift
//  LookinCore
//
//  A connected stream socket that carries Lookin frames, shared by the
//  Server (an accepted Host connection) and the Host (a TCP connection to a
//  Simulator or Mac app, or a usbmuxd tunnel to a device). It takes the
//  place of the vendored Peertalk's connected channel and keeps its behaviour:
//
//  - frames are written in send order, each in one dispatch I/O write;
//  - `shouldAcceptFrame` decides on each header before its payload is read;
//    a rejected frame's payload is skipped;
//  - a received type-0 frame ends the channel without an error, like the
//    peer closing the socket at a frame boundary;
//  - an invalid frame (version other than 1, payload above the limit) ends
//    it with that error; the peer closing the socket ends it without an
//    error, even inside a header or a payload (the partial frame is
//    dropped, as Peertalk did);
//  - `close()` stops at once and drops queued writes; `cancel()` stops
//    reading at once and closes the socket once queued writes are written
//    (Peertalk's graceful close also waited for a pending read, which could
//    hold a quiet connection open);
//  - `onEnd` runs exactly once, after the socket is closed, on `queue`.
//
//  Every callback runs on `queue`; give the channel a serial queue. The
//  channel keeps itself alive until `onEnd` has run.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Darwin
    import Foundation

    public final class FrameChannel: @unchecked Sendable {
        /// Why the channel ended, when it did not end cleanly.
        public enum EndError: Error, Equatable {
            /// A POSIX error from the socket.
            case posix(Int32)
            /// The byte stream is not a valid frame stream.
            case frame(FrameError)
        }

        public let queue: DispatchQueue

        /// Decides on each header before its payload is read; nil accepts
        /// every frame. Set before `start()`.
        public var shouldAcceptFrame: ((FrameHeader) -> Bool)?
        /// Each accepted frame, payload complete. Set before `start()`.
        public var onFrame: ((TransportFrame) -> Void)?
        /// Runs once, after the socket is closed: nil for an orderly end (the
        /// peer closed, a type-0 frame, `close()` or `cancel()`). Set before
        /// `start()`.
        public var onEnd: ((EndError?) -> Void)?

        private let io: DispatchIO
        private var decoder: FrameDecoder
        private var pendingBytes: Data
        private var endError: EndError?
        private var started = false
        private var ended = false
        /// Holds the channel until `onEnd` has run.
        private var keepAlive: FrameChannel?

        private let stateLock = NSLock()
        private var open = true
        /// Writes handed to dispatch I/O and not finished; under `stateLock`.
        private var pendingWrites = 0
        /// `cancel()` waits for `pendingWrites` to reach 0; under `stateLock`.
        private var closeAfterWrites = false

        /// True until the channel is closed, cancelled or ended. Any thread.
        public var isConnected: Bool {
            stateLock.lock()
            defer { stateLock.unlock() }
            return open
        }

        /// Takes ownership of `fileDescriptor`, a connected stream socket; it
        /// is closed when the channel ends.
        ///
        /// - Parameters:
        ///   - maxPayloadSize: the largest payload an accepted frame may
        ///     announce (see `FrameDecoder`).
        ///   - initialBytes: bytes already read from the socket that belong
        ///     to the frame stream (after a usbmuxd Connect result).
        public init(fileDescriptor: Int32, queue: DispatchQueue, maxPayloadSize: UInt32 = .max, initialBytes: Data = Data()) {
            self.queue = queue
            decoder = FrameDecoder(maxPayloadSize: maxPayloadSize)
            pendingBytes = initialBytes
            var on: Int32 = 1
            setsockopt(fileDescriptor, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
            let flags = fcntl(fileDescriptor, F_GETFL)
            if flags != -1 {
                _ = fcntl(fileDescriptor, F_SETFL, flags | O_NONBLOCK)
            }
            // The cleanup handler cannot capture self before init completes;
            // it reaches the channel through this box.
            let box = WeakBox()
            io = DispatchIO(type: .stream, fileDescriptor: fileDescriptor, queue: queue) { error in
                Darwin.close(fileDescriptor)
                box.channel?.didClose(posixError: error)
            }
            io.setLimit(lowWater: 1)
            box.channel = self
            keepAlive = self
        }

        private final class WeakBox: @unchecked Sendable {
            weak var channel: FrameChannel?
        }

        /// Starts reading. Frames and the end arrive on `queue`.
        public func start() {
            queue.async { [self] in
                guard !started, !ended else { return }
                started = true
                if !pendingBytes.isEmpty {
                    let bytes = pendingBytes
                    pendingBytes = Data()
                    receive(bytes)
                }
                guard isConnected else { return }
                io.read(offset: 0, length: Int.max, queue: queue) { [weak self] done, data, error in
                    self?.didRead(done: done, data: data, error: error)
                }
            }
        }

        /// Sends one frame. `completion` (on `queue`) gets nil once it is
        /// fully written, or the error; a closed channel fails with EPERM, as
        /// Peertalk did.
        public func send(_ frame: TransportFrame, completion: ((EndError?) -> Void)? = nil) {
            let bytes: Data
            do {
                bytes = try frame.encoded()
            } catch let error as FrameError {
                queue.async { completion?(.frame(error)) }
                return
            } catch {
                queue.async { completion?(.posix(EINVAL)) }
                return
            }
            stateLock.lock()
            guard open else {
                stateLock.unlock()
                queue.async { completion?(.posix(EPERM)) }
                return
            }
            pendingWrites += 1
            stateLock.unlock()
            let data = bytes.withUnsafeBytes { DispatchData(bytes: $0) }
            io.write(offset: 0, data: data, queue: queue) { [io] done, _, error in
                guard done else { return }
                completion?(error == 0 ? nil : .posix(error))
                self.stateLock.lock()
                self.pendingWrites -= 1
                let closeNow = self.closeAfterWrites && self.pendingWrites == 0
                if closeNow {
                    self.closeAfterWrites = false
                }
                self.stateLock.unlock()
                if closeNow {
                    io.close(flags: .stop)
                }
            }
        }

        public func send(type: UInt32, tag: UInt32, payload: Data = Data(), completion: ((EndError?) -> Void)? = nil) {
            send(TransportFrame(type: type, tag: tag, payload: payload), completion: completion)
        }

        /// Ends the channel now; queued writes are dropped.
        public func close() {
            stateLock.lock()
            // Open, or cancelled and still waiting for its writes.
            let stopNow = open || closeAfterWrites
            open = false
            closeAfterWrites = false
            stateLock.unlock()
            if stopNow {
                io.close(flags: .stop)
            }
        }

        /// Stops reading now and ends the channel once queued writes are
        /// written.
        public func cancel() {
            stateLock.lock()
            guard open else {
                stateLock.unlock()
                return
            }
            open = false
            let closeNow = pendingWrites == 0
            closeAfterWrites = !closeNow
            stateLock.unlock()
            if closeNow {
                io.close(flags: .stop)
            }
        }

        // MARK: - Reading

        private func markClosed() -> Bool {
            stateLock.lock()
            defer { stateLock.unlock() }
            guard open else { return false }
            open = false
            return true
        }

        private func didRead(done: Bool, data: DispatchData?, error: Int32) {
            if let data, !data.isEmpty, isConnected {
                receive(Data(data))
            }
            guard done else { return }
            if error != 0 {
                if error != ECANCELED, endError == nil {
                    endError = .posix(error)
                }
                close()
                return
            }
            // End of stream; a partial frame is dropped without an error.
            cancel()
        }

        private func receive(_ bytes: Data) {
            decoder.append(bytes)
            while isConnected {
                let output: FrameDecoder.Output?
                do {
                    output = try decoder.next(accepting: { [self] header in shouldAcceptFrame?(header) ?? true })
                } catch let error as FrameError {
                    endError = .frame(error)
                    close()
                    return
                } catch {
                    close()
                    return
                }
                switch output {
                case nil:
                    return
                case .endOfStream:
                    cancel()
                    return
                case let .frame(frame):
                    onFrame?(frame)
                }
            }
        }

        private func didClose(posixError: Int32) {
            _ = markClosed()
            guard !ended else { return }
            ended = true
            if posixError != 0, posixError != ECANCELED, endError == nil {
                endError = .posix(posixError)
            }
            let handler = onEnd
            let error = endError
            onEnd = nil
            onFrame = nil
            shouldAcceptFrame = nil
            handler?(error)
            keepAlive = nil
        }
    }

#endif
