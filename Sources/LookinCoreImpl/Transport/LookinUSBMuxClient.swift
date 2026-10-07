//
//  LookinUSBMuxClient.swift
//  LookinCore
//
//  The Host's usbmuxd client (macOS only), shared by the Host and
//  lookin-probe. It replaces the vendored Peertalk's USB hub and sends the same
//  bytes (LookinUSBMux builds them):
//
//  - `startListening` keeps one socket open with a Listen request (tag 1)
//    and reports usbmuxd's Attached / Detached broadcasts (tag 0). Devices
//    are not filtered by ConnectionType, as in Peertalk. Unlike Peertalk,
//    a Listen socket that fails or ends reports every known device as
//    detached and is opened again every 2 s until `stopListening()`.
//  - `connect` opens a new socket per attempt, sends Connect (tag 1) and
//    reads one Result. Number 0 hands over the socket, now a byte stream to
//    the device port, together with any bytes that followed the Result.
//    Unlike Peertalk, an attempt fails after `timeout`.
//
//  Socket I/O is blocking and runs on private queues; every callback runs
//  on the queue given to `init`.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    #if os(macOS)

        import Darwin
        import Foundation

        public final class LookinUSBMuxClient: @unchecked Sendable {
            public enum Event {
                /// `properties` is the whole Attached message, DeviceID
                /// included (what Peertalk posted as the notification's
                /// userInfo).
                case attached(deviceID: Int, properties: [String: Any])
                case detached(deviceID: Int)
            }

            /// The pause before a failed or ended Listen socket is opened
            /// again.
            public static let listenRetryInterval: TimeInterval = 2

            /// The tag of the first request on a socket; each socket counts
            /// its own tags from here.
            private static let firstTag: UInt32 = 1

            public let queue: DispatchQueue
            public let identity: LookinUSBMux.ClientIdentity
            public let socketPath: String

            private let ioQueue = DispatchQueue(label: "lookin.usbmux.io", attributes: .concurrent)

            /// Guards the listen state below.
            private let listenCondition = NSCondition()
            /// Bumped by every start and stop; a listen loop whose generation
            /// is no longer current stops.
            private var listenGeneration = 0
            private var isListening = false
            /// The open Listen socket, or -1; the listen loop owns and closes
            /// it, `stopListening()` only shuts it down to wake the read.
            private var listenFD: Int32 = -1

            public init(
                queue: DispatchQueue,
                identity: LookinUSBMux.ClientIdentity = .mainBundle,
                socketPath: String = LookinUSBMux.socketPath
            ) {
                self.queue = queue
                self.identity = identity
                self.socketPath = socketPath
            }

            deinit {
                stopListening()
            }

            // MARK: - Listen

            /// Subscribes to device broadcasts. `onEvent` runs on `queue`. A
            /// second call replaces the first subscription.
            public func startListening(onEvent: @escaping (Event) -> Void) {
                stopListening()
                listenCondition.lock()
                listenGeneration += 1
                isListening = true
                let generation = listenGeneration
                listenCondition.unlock()
                ioQueue.async { [self] in
                    listenLoop(generation: generation, onEvent: onEvent)
                }
            }

            /// Closes the Listen socket and stops retrying. No event is
            /// delivered after this returns, except one already queued.
            public func stopListening() {
                listenCondition.lock()
                if isListening {
                    isListening = false
                    listenGeneration += 1
                    if listenFD != -1 {
                        shutdown(listenFD, SHUT_RDWR)
                    }
                }
                listenCondition.broadcast()
                listenCondition.unlock()
            }

            private func isCurrent(_ generation: Int) -> Bool {
                listenCondition.lock()
                defer { listenCondition.unlock() }
                return isListening && listenGeneration == generation
            }

            private func listenLoop(generation: Int, onEvent: @escaping (Event) -> Void) {
                var knownDevices = [Int]()
                let deliver: (Event) -> Void = { [weak self] event in
                    self?.queue.async {
                        guard let self, self.isCurrent(generation) else { return }
                        onEvent(event)
                    }
                }
                while isCurrent(generation) {
                    do {
                        try listenSession(generation: generation) { event in
                            switch event {
                            case let .attached(deviceID, _):
                                if !knownDevices.contains(deviceID) {
                                    knownDevices.append(deviceID)
                                }
                            case let .detached(deviceID):
                                knownDevices.removeAll { $0 == deviceID }
                            }
                            deliver(event)
                        }
                        if isCurrent(generation) {
                            NSLog("LookinUSBMux - the usbmuxd listen connection ended")
                        }
                    } catch {
                        if isCurrent(generation) {
                            NSLog("LookinUSBMux - listening to usbmuxd failed: %@", String(describing: error))
                        }
                    }
                    for deviceID in knownDevices {
                        deliver(.detached(deviceID: deviceID))
                    }
                    knownDevices.removeAll()
                    waitBeforeRetry(generation: generation)
                }
            }

            /// Sleeps `listenRetryInterval`, or less when the subscription
            /// stops.
            private func waitBeforeRetry(generation: Int) {
                let deadline = Date().addingTimeInterval(Self.listenRetryInterval)
                listenCondition.lock()
                while isListening, listenGeneration == generation, Date() < deadline {
                    listenCondition.wait(until: deadline)
                }
                listenCondition.unlock()
            }

            /// One Listen socket, from connect to its end. Returns when the
            /// socket ends; throws when it cannot be opened, the Result is
            /// an error or the stream is invalid.
            private func listenSession(generation: Int, onEvent: (Event) -> Void) throws {
                let fd = try LookinSocket.connectUnix(path: socketPath)
                listenCondition.lock()
                guard isListening, listenGeneration == generation else {
                    listenCondition.unlock()
                    Darwin.close(fd)
                    return
                }
                listenFD = fd
                listenCondition.unlock()
                defer {
                    listenCondition.lock()
                    listenFD = -1
                    listenCondition.unlock()
                    Darwin.close(fd)
                }

                let request = try LookinUSBMuxPacket(plist: LookinUSBMux.listenRequest(identity: identity), tag: Self.firstTag)
                try Self.writeAll(fd, request.encoded)

                var decoder = LookinUSBMuxDecoder()
                var listening = false
                while true {
                    while let packet = try decoder.next() {
                        let message = try packet.plistDictionary()
                        if packet.isBroadcast {
                            handleBroadcast(message, onEvent: onEvent)
                        } else if !listening, packet.tag == Self.firstTag {
                            if let error = LookinUSBMuxError.fromResult(message) {
                                throw error
                            }
                            listening = true
                        } else {
                            NSLog("LookinUSBMux - ignoring a usbmuxd reply with tag %@", NSNumber(value: packet.tag))
                        }
                    }
                    guard let bytes = try Self.readSome(fd) else { return }
                    decoder.append(bytes)
                }
            }

            private func handleBroadcast(_ message: [String: Any], onEvent: (Event) -> Void) {
                let messageType = message["MessageType"] as? String
                guard let deviceID = (message["DeviceID"] as? NSNumber)?.intValue else {
                    NSLog("LookinUSBMux - ignoring a usbmuxd broadcast without a DeviceID: %@", messageType ?? "(null)")
                    return
                }
                switch messageType {
                case "Attached":
                    onEvent(.attached(deviceID: deviceID, properties: message))
                case "Detached":
                    onEvent(.detached(deviceID: deviceID))
                default:
                    NSLog("LookinUSBMux - ignoring a usbmuxd broadcast: %@", messageType ?? "(null)")
                }
            }

            // MARK: - Connect

            /// Opens a byte stream to `port` on the device `deviceID`.
            /// `completion` runs once on `queue` with the connected socket
            /// (blocking; the caller owns it) and the bytes already read past
            /// the Result, or with the error: `LookinUSBMuxError` for a
            /// refused Connect (code 3 when nothing listens on the port),
            /// `LookinSocket.Error` for a socket failure (ETIMEDOUT after
            /// `timeout`).
            public func connect(
                deviceID: Int,
                port: UInt16,
                timeout: TimeInterval = 3,
                completion: @escaping (Result<(fileDescriptor: Int32, initialBytes: Data), Error>) -> Void
            ) {
                let attempt = ConnectAttempt()
                let finish: (Result<(fileDescriptor: Int32, initialBytes: Data), Error>) -> Void = { [queue] result in
                    queue.async { completion(result) }
                }
                ioQueue.async { [self] in
                    let result: Result<(fileDescriptor: Int32, initialBytes: Data), Error>
                    var fd: Int32 = -1
                    do {
                        fd = try LookinSocket.connectUnix(path: socketPath)
                        guard attempt.register(fd) else {
                            Darwin.close(fd)
                            return
                        }
                        let request = try LookinUSBMuxPacket(
                            plist: LookinUSBMux.connectRequest(deviceID: deviceID, port: port, identity: identity),
                            tag: Self.firstTag
                        )
                        try Self.writeAll(fd, request.encoded)
                        result = try .success((fd, Self.readConnectResult(fd)))
                    } catch {
                        result = .failure(error)
                    }
                    guard attempt.finish() else {
                        // Timed out; the timer reported it.
                        if fd != -1 {
                            Darwin.close(fd)
                        }
                        return
                    }
                    if case .failure = result, fd != -1 {
                        Darwin.close(fd)
                    }
                    finish(result)
                }
                ioQueue.asyncAfter(deadline: .now() + timeout) {
                    guard attempt.timeOut() else { return }
                    finish(.failure(LookinSocket.Error(code: ETIMEDOUT)))
                }
            }

            /// Reads one reply and returns the bytes after it.
            private static func readConnectResult(_ fd: Int32) throws -> Data {
                var decoder = LookinUSBMuxDecoder()
                while true {
                    if let packet = try decoder.next() {
                        if let error = try LookinUSBMuxError.fromResult(packet.plistDictionary()) {
                            throw error
                        }
                        return decoder.takeRemainingBytes()
                    }
                    guard let bytes = try readSome(fd) else {
                        throw LookinSocket.Error(code: ECONNRESET)
                    }
                    decoder.append(bytes)
                }
            }

            /// Finishes a Connect attempt once, from its worker or its timer.
            private final class ConnectAttempt: @unchecked Sendable {
                private let lock = NSLock()
                private var fd: Int32 = -1
                private var finished = false

                /// False when the attempt already timed out.
                func register(_ fd: Int32) -> Bool {
                    lock.lock()
                    defer { lock.unlock() }
                    self.fd = fd
                    return !finished
                }

                /// Claims the result for the worker; false after a timeout.
                func finish() -> Bool {
                    lock.lock()
                    defer { lock.unlock() }
                    guard !finished else { return false }
                    finished = true
                    return true
                }

                /// Claims the result for the timer and wakes a blocked worker,
                /// which then closes the socket.
                func timeOut() -> Bool {
                    lock.lock()
                    defer { lock.unlock() }
                    guard !finished else { return false }
                    finished = true
                    if fd != -1 {
                        shutdown(fd, SHUT_RDWR)
                    }
                    return true
                }
            }

            // MARK: - Blocking I/O

            private static func writeAll(_ fd: Int32, _ data: Data) throws {
                try data.withUnsafeBytes { raw in
                    var offset = 0
                    while offset < raw.count {
                        let written = Darwin.write(fd, raw.baseAddress! + offset, raw.count - offset)
                        if written < 0 {
                            if errno == EINTR {
                                continue
                            }
                            throw LookinSocket.Error(code: errno)
                        }
                        offset += written
                    }
                }
            }

            /// The next bytes from `fd`, or nil at the end of the stream.
            private static func readSome(_ fd: Int32) throws -> Data? {
                var buffer = [UInt8](repeating: 0, count: 64 * 1024)
                while true {
                    let count = buffer.withUnsafeMutableBytes { Darwin.read(fd, $0.baseAddress!, $0.count) }
                    if count > 0 {
                        return Data(buffer[0 ..< count])
                    }
                    if count == 0 {
                        return nil
                    }
                    if errno == EINTR {
                        continue
                    }
                    throw LookinSocket.Error(code: errno)
                }
            }
        }

    #endif

#endif
