//
//  SocketConnector.swift
//  LookinCore
//
//  The two blocking connects the transport needs, shared by the Host, the
//  e2e probe and the activation harness so none of them carries its own
//  socket code:
//
//  - `connectLoopback(port:)`: a TCP connection to 127.0.0.1, the way
//    Peertalk's `connectToPort:IPv4Address:` made it (blocking connect, which
//    on loopback succeeds or fails with ECONNREFUSED at once; SO_NOSIGPIPE).
//    Simulator and Mac apps are reached this way.
//  - `connectUnix(path:)`: a stream connection to a Unix socket, for
//    /var/run/usbmuxd (Peertalk's USB channel did the same).
//
//  The returned descriptor is blocking; FrameChannel switches it to
//  non-blocking when it takes it over.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Darwin
    import Foundation

    public enum SocketConnector {
        /// A failed socket call, with its errno (ECONNREFUSED when nothing
        /// listens on the port, ENOENT when the Unix socket does not exist).
        public struct Error: Swift.Error, Equatable, CustomStringConvertible {
            public var code: Int32

            public init(code: Int32) {
                self.code = code
            }

            public var description: String {
                "POSIX error \(code): \(String(cString: strerror(code)))"
            }
        }

        /// Connects to 127.0.0.1:`port` and returns the connected socket.
        public static func connectLoopback(port: UInt16) throws -> Int32 {
            let fd = socket(AF_INET, SOCK_STREAM, 0)
            guard fd != -1 else { throw Error(code: errno) }
            disableSIGPIPE(fd)
            var address = sockaddr_in()
            address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            address.sin_family = sa_family_t(AF_INET)
            address.sin_port = port.bigEndian
            address.sin_addr.s_addr = INADDR_LOOPBACK.bigEndian
            let result = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
            guard result == 0 else {
                let code = errno
                close(fd)
                throw Error(code: code)
            }
            return fd
        }

        /// Connects to the Unix stream socket at `path`.
        public static func connectUnix(path: String) throws -> Int32 {
            var address = sockaddr_un()
            let capacity = MemoryLayout.size(ofValue: address.sun_path)
            let bytes = Array(path.utf8)
            guard bytes.count < capacity else { throw Error(code: ENAMETOOLONG) }
            let fd = socket(AF_UNIX, SOCK_STREAM, 0)
            guard fd != -1 else { throw Error(code: errno) }
            disableSIGPIPE(fd)
            address.sun_family = sa_family_t(AF_UNIX)
            withUnsafeMutableBytes(of: &address.sun_path) { raw in
                raw.copyBytes(from: bytes)
                raw[bytes.count] = 0
            }
            address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
            let result = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
                }
            }
            guard result == 0 else {
                let code = errno
                close(fd)
                throw Error(code: code)
            }
            return fd
        }

        /// A write to a peer that closed fails with EPIPE instead of
        /// raising SIGPIPE.
        public static func disableSIGPIPE(_ fd: Int32) {
            var on: Int32 = 1
            setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
        }
    }

#endif
