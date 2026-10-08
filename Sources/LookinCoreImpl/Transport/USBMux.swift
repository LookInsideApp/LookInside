//
//  USBMux.swift
//  LookinCore
//
//  The usbmuxd client messages the Host sends to reach a Server on a USB
//  device, byte for byte the ones Peertalk's PTUSBHub sent
//  (Fixtures/usbmux-*.bin):
//
//  - a 16-byte header in little-endian (host) byte order:
//    size (header + payload), version 1 (plist), message type 8 (plist
//    payload), tag; then an XML property list;
//  - every request carries MessageType, plus ProgName and
//    ClientVersionString from the main bundle's CFBundleName and
//    CFBundleVersion (ProgName only when the bundle has a name, and
//    ClientVersionString only when it also has a version);
//  - Listen subscribes the socket to Attached / Detached broadcasts (tag 0);
//  - Connect asks for DeviceID and PortNumber, the port in network byte
//    order. After a Result with Number 0 the same socket is a byte stream to
//    that port on the device, carrying Lookin frames.
//
//  Only the encoding lives here; the socket is USBMuxClient's
//  (Host-side, macOS).
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    public enum USBMux {
        /// The usbmuxd socket on macOS.
        public static let socketPath = "/var/run/usbmuxd"
        public static let headerSize = 16
        /// Header version for property-list messages.
        public static let plistVersion: UInt32 = 1
        /// Header message type for property-list messages.
        public static let plistMessageType: UInt32 = 8

        /// `PortNumber` of a Connect request: the TCP port with its two bytes
        /// swapped, which is network byte order read back on a little-endian
        /// Mac (47175 is sent as 18360). Peertalk swapped unconditionally.
        public static func portNumber(forDevicePort port: UInt16) -> Int {
            Int(port.byteSwapped)
        }

        /// The ProgName / ClientVersionString pair Peertalk took from the main
        /// bundle.
        public struct ClientIdentity: Equatable, Sendable {
            public var progName: String?
            public var clientVersionString: String?

            public init(progName: String?, clientVersionString: String?) {
                self.progName = progName
                self.clientVersionString = clientVersionString
            }

            /// `CFBundleName` and the description of `CFBundleVersion` of
            /// `bundle`.
            public static func of(_ bundle: Bundle) -> ClientIdentity {
                let info = bundle.infoDictionary
                return ClientIdentity(
                    progName: info?["CFBundleName"] as? String,
                    clientVersionString: (info?["CFBundleVersion"]).map { "\($0)" }
                )
            }

            public static var mainBundle: ClientIdentity {
                of(Bundle.main)
            }
        }

        /// A request dictionary: `fields`, then MessageType and the client
        /// identity on top (Peertalk let them override `fields`).
        public static func request(messageType: String, fields: [String: Any] = [:], identity: ClientIdentity) -> [String: Any] {
            var packet = fields
            packet["MessageType"] = messageType
            if let progName = identity.progName {
                packet["ProgName"] = progName
                if let version = identity.clientVersionString {
                    packet["ClientVersionString"] = version
                }
            }
            return packet
        }

        public static func listenRequest(identity: ClientIdentity) -> [String: Any] {
            request(messageType: "Listen", identity: identity)
        }

        public static func connectRequest(deviceID: Int, port: UInt16, identity: ClientIdentity) -> [String: Any] {
            request(
                messageType: "Connect",
                fields: ["DeviceID": deviceID, "PortNumber": portNumber(forDevicePort: port)],
                identity: identity
            )
        }
    }

    /// Why usbmuxd turned a request down, or why its reply is unusable.
    /// `domain` and `code` are Peertalk's (`PTUSBHubError`), so log lines read
    /// the same.
    public struct USBMuxError: Error, Equatable, CustomStringConvertible {
        public static let domain = "PTUSBHubError"

        /// usbmuxd's `Number` (1 bad command, 2 bad device, 3 connection
        /// refused, 6 bad version), or 0 for a reply without one.
        public var code: Int
        public var message: String

        public init(code: Int, message: String) {
            self.code = code
            self.message = message
        }

        /// The error a Result reply carries, or nil for `Number` 0.
        public static func fromResult(_ reply: [String: Any]) -> USBMuxError? {
            guard let number = reply["Number"] as? NSNumber else {
                return USBMuxError(code: 0, message: "Result without a Number")
            }
            let code = number.intValue
            switch code {
            case 0: return nil
            case 1: return USBMuxError(code: code, message: "illegal command")
            case 2: return USBMuxError(code: code, message: "unknown device")
            case 3: return USBMuxError(code: code, message: "connection refused")
            case 6: return USBMuxError(code: code, message: "invalid version")
            default: return USBMuxError(code: code, message: "Unspecified error")
            }
        }

        public var description: String {
            "\(Self.domain) \(code): \(message)"
        }
    }

    /// One usbmuxd message.
    public struct USBMuxPacket: Equatable {
        public var version: UInt32
        public var messageType: UInt32
        public var tag: UInt32
        public var payload: Data

        public init(version: UInt32, messageType: UInt32, tag: UInt32, payload: Data) {
            self.version = version
            self.messageType = messageType
            self.tag = tag
            self.payload = payload
        }

        /// A plist message: `dictionary` as an XML property list.
        public init(plist dictionary: [String: Any], tag: UInt32) throws {
            let payload = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
            self.init(version: USBMux.plistVersion, messageType: USBMux.plistMessageType, tag: tag, payload: payload)
        }

        /// The wire bytes: little-endian header, then the payload.
        public var encoded: Data {
            var data = Data(capacity: USBMux.headerSize + payload.count)
            let size = UInt32(truncatingIfNeeded: USBMux.headerSize + payload.count)
            for field in [size, version, messageType, tag] {
                withUnsafeBytes(of: field.littleEndian) { data.append(contentsOf: $0) }
            }
            data.append(payload)
            return data
        }

        /// True for a broadcast (Attached / Detached), false for a reply.
        public var isBroadcast: Bool {
            tag == 0
        }

        /// The payload as a property-list dictionary.
        ///
        /// - Throws: `USBMuxError` (code 0) for a non-plist message, or
        ///   the property-list error.
        public func plistDictionary() throws -> [String: Any] {
            guard version == USBMux.plistVersion else {
                throw USBMuxError(code: 0, message: "Unexpected package protocol")
            }
            guard messageType == USBMux.plistMessageType else {
                throw USBMuxError(code: 0, message: "Unexpected package type")
            }
            if payload.isEmpty {
                return [:]
            }
            let object = try PropertyListSerialization.propertyList(from: payload, options: [], format: nil)
            guard let dictionary = object as? [String: Any] else {
                throw USBMuxError(code: 0, message: "Unexpected property list")
            }
            return dictionary
        }
    }

    /// Splits the bytes read from a usbmuxd socket into messages. After a
    /// successful Connect, `takeRemainingBytes()` hands the bytes that
    /// followed the Result (the device's first frames) to the frame channel.
    public struct USBMuxDecoder {
        /// usbmuxd's own messages are small; anything bigger is not usbmuxd.
        public static let maxPacketSize = 16 * 1024 * 1024

        private var buffer = Data()

        public init() {}

        public mutating func append(_ bytes: Data) {
            buffer.append(bytes)
        }

        /// The next complete message, or nil when more bytes are needed.
        ///
        /// - Throws: `USBMuxError` for a size below 16 or above
        ///   `maxPacketSize`.
        public mutating func next() throws -> USBMuxPacket? {
            guard buffer.count >= USBMux.headerSize else { return nil }
            let fields = (0 ..< 4).map { field -> UInt32 in
                var value: UInt32 = 0
                for byte in (0 ..< 4).reversed() {
                    value = value << 8 | UInt32(buffer[buffer.startIndex + field * 4 + byte])
                }
                return value
            }
            let size = Int(fields[0])
            guard size >= USBMux.headerSize, size <= Self.maxPacketSize else {
                throw USBMuxError(code: 1, message: "Received a packet that is too large")
            }
            guard buffer.count >= size else { return nil }
            let start = buffer.startIndex
            let payload = Data(buffer[start + USBMux.headerSize ..< start + size])
            buffer = Data(buffer[(start + size)...])
            return USBMuxPacket(version: fields[1], messageType: fields[2], tag: fields[3], payload: payload)
        }

        /// The bytes after the last decoded message; empties the decoder.
        public mutating func takeRemainingBytes() -> Data {
            defer { buffer = Data() }
            return Data(buffer)
        }
    }

#endif
