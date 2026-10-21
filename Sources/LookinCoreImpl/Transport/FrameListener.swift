//
//  FrameListener.swift
//  LookinCore
//
//  The Server's listening socket, the way Peertalk's
//  `listenOnPort:IPv4Address:callback:` made it:
//
//  - socket(AF_INET, SOCK_STREAM) -> SO_REUSEADDR -> O_NONBLOCK -> bind to
//    127.0.0.1:port -> listen(fd, 512) -> a read source on `queue`;
//  - on each read event it accepts until accept() fails (EAGAIN) or the
//    event's pending count is used up, and hands each accepted socket
//    (SO_NOSIGPIPE, O_NONBLOCK) to `onAccept`;
//  - `cancel()` stops the source; the socket is closed by the source's
//    cancel handler, so an accept loop already running finishes the
//    connections the event announced (Peertalk behaved the same way when the
//    first accepted connection cancelled its listener). Until that handler
//    has run the port stays taken; `whenClosed(_:)` waits for it.
//
//  A failed setup step throws `SocketConnector.Error` with its errno; EADDRINUSE
//  (48) means another process (or another listener) holds the port.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Darwin
    import Foundation

    public final class FrameListener: @unchecked Sendable {
        /// The bound port (the kernel's choice when listening on port 0).
        public let port: UInt16

        private let source: DispatchSourceRead
        private let stateLock = NSLock()
        private var cancelled = false
        /// Set once the cancel handler closed the socket; under `stateLock`.
        private var closed = false
        /// Waiting for `closed`; under `stateLock`.
        private var closeObservers: [() -> Void] = []

        private init(port: UInt16, source: DispatchSourceRead) {
            self.port = port
            self.source = source
        }

        /// True once the listening socket is closed and its port free again.
        /// Any thread.
        public var isClosed: Bool {
            stateLock.lock()
            defer { stateLock.unlock() }
            return closed
        }

        /// Runs `body` once the listening socket is closed: on the listener's
        /// queue, or right away on this thread when it already is.
        public func whenClosed(_ body: @escaping () -> Void) {
            stateLock.lock()
            guard !closed else {
                stateLock.unlock()
                body()
                return
            }
            closeObservers.append(body)
            stateLock.unlock()
        }

        private func didClose() {
            stateLock.lock()
            closed = true
            let observers = closeObservers
            closeObservers = []
            stateLock.unlock()
            for observer in observers {
                observer()
            }
        }

        /// True until `cancel()`. Any thread.
        public var isListening: Bool {
            stateLock.lock()
            defer { stateLock.unlock() }
            return !cancelled
        }

        /// Listens on 127.0.0.1:`port`; `onAccept` runs on `queue` with each
        /// accepted socket, which it then owns.
        public static func listen(port: UInt16, queue: DispatchQueue, onAccept: @escaping (Int32) -> Void) throws -> FrameListener {
            let fd = socket(AF_INET, SOCK_STREAM, 0)
            guard fd != -1 else { throw SocketConnector.Error(code: errno) }

            func fail() -> SocketConnector.Error {
                let code = errno
                Darwin.close(fd)
                return SocketConnector.Error(code: code)
            }

            var on: Int32 = 1
            guard setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) != -1 else {
                throw fail()
            }
            guard fcntl(fd, F_SETFL, O_NONBLOCK) != -1 else {
                throw fail()
            }
            var address = sockaddr_in()
            address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            address.sin_family = sa_family_t(AF_INET)
            address.sin_port = port.bigEndian
            address.sin_addr.s_addr = INADDR_LOOPBACK.bigEndian
            let bound = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            guard bound == 0 else { throw fail() }
            guard Darwin.listen(fd, 512) == 0 else { throw fail() }

            var boundPort = port
            var boundAddress = sockaddr_in()
            var length = socklen_t(MemoryLayout<sockaddr_in>.size)
            let named = withUnsafeMutablePointer(to: &boundAddress) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    getsockname(fd, $0, &length)
                }
            }
            if named == 0 {
                boundPort = UInt16(bigEndian: boundAddress.sin_port)
            }

            let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
            source.setEventHandler { [weak source] in
                guard let source else { return }
                var pending = max(source.data, 1)
                while let accepted = acceptOne(fd) {
                    onAccept(accepted)
                    pending -= 1
                    if pending == 0 {
                        break
                    }
                }
            }
            let listener = FrameListener(port: boundPort, source: source)
            // Weak: a listener dropped without `cancel()` still stops in
            // `deinit`. Whoever waits for the close holds the listener.
            source.setCancelHandler { [weak listener] in
                Darwin.close(fd)
                listener?.didClose()
            }
            source.resume()
            return listener
        }

        /// One accept(); nil when it fails (EAGAIN included) or the socket
        /// cannot be made non-blocking.
        private static func acceptOne(_ listeningFD: Int32) -> Int32? {
            var address = sockaddr_storage()
            var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
            let fd = withUnsafeMutablePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    accept(listeningFD, $0, &length)
                }
            }
            guard fd != -1 else { return nil }
            SocketConnector.disableSIGPIPE(fd)
            let flags = fcntl(fd, F_GETFL)
            guard flags != -1, fcntl(fd, F_SETFL, flags | O_NONBLOCK) != -1 else {
                Darwin.close(fd)
                return nil
            }
            return fd
        }

        /// Stops listening and closes the socket. Idempotent.
        public func cancel() {
            stateLock.lock()
            let wasCancelled = cancelled
            cancelled = true
            stateLock.unlock()
            if !wasCancelled {
                source.cancel()
            }
        }

        deinit {
            cancel()
        }
    }

#endif
