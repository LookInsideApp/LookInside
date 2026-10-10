//
//  TransportFrame.swift
//  LookinCore
//
//  The frame format the Host and the Server exchange, byte for byte the one
//  the vendored Peertalk used (released Hosts and Servers still speak it):
//
//      offset  size  field         byte order
//      0       4     version = 1   big-endian
//      4       4     type          big-endian
//      8       4     tag           big-endian
//      12      4     payloadSize   big-endian
//      16      n     payload       n = payloadSize, absent when 0
//
//  The type is the Lookin request or push type (LookinDefines.h). A reply
//  carries the tag of its request; a push and a frame that wants no reply use
//  tag 0. There is no ping, close or handshake frame at this layer: ping is
//  the application request 200, and a connection ends by closing the socket.
//  A received frame of type 0 is Peertalk's end-of-stream marker and ends the
//  stream (see FrameDecoder). Pinned by Tests/LookinTransportTests,
//  whose fixtures were recorded from Peertalk.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    /// Constants of the frame protocol.
    public enum FrameProtocolConstants {
        /// The only protocol version; a frame with another version ends the
        /// connection with an error.
        public static let version: UInt32 = 1
        /// Bytes in a frame header.
        public static let headerSize = 16
        /// Peertalk's `PTFrameTypeEndOfStream`. A received frame of this type
        /// ends the stream; nothing sends it on purpose.
        public static let endOfStreamType: UInt32 = 0
        /// Peertalk's `PTFrameNoTag`: pushes and frames that expect no reply.
        public static let noTag: UInt32 = 0
    }

    /// Why a byte stream is not a valid frame stream.
    public enum FrameError: Error, Equatable {
        /// The header's version is not `FrameProtocolConstants.version`.
        case unsupportedVersion(UInt32)
        /// An accepted frame announces a payload above the decoder's limit.
        case payloadTooLarge(size: UInt32, limit: UInt32)
        /// The payload does not fit the 32-bit size field.
        case payloadSizeOverflow(Int)
        /// The stream ended inside a frame header.
        case truncatedHeader
    }

    /// The 16-byte frame header.
    public struct FrameHeader: Equatable, Sendable {
        public var type: UInt32
        public var tag: UInt32
        public var payloadSize: UInt32

        public init(type: UInt32, tag: UInt32, payloadSize: UInt32) {
            self.type = type
            self.tag = tag
            self.payloadSize = payloadSize
        }

        /// The header bytes (version 1, every field big-endian).
        public var encoded: Data {
            var data = Data(capacity: FrameProtocolConstants.headerSize)
            for field in [FrameProtocolConstants.version, type, tag, payloadSize] {
                withUnsafeBytes(of: field.bigEndian) { data.append(contentsOf: $0) }
            }
            return data
        }

        /// Reads a header from the first 16 bytes of `bytes`.
        ///
        /// - Throws: `FrameError.truncatedHeader` for fewer than 16
        ///   bytes, `.unsupportedVersion` for a version other than 1.
        public static func decode<Bytes: Collection>(_ bytes: Bytes) throws -> FrameHeader where Bytes.Element == UInt8 {
            guard bytes.count >= FrameProtocolConstants.headerSize else {
                throw FrameError.truncatedHeader
            }
            var fields = [UInt32]()
            fields.reserveCapacity(4)
            var index = bytes.startIndex
            for _ in 0 ..< 4 {
                var value: UInt32 = 0
                for _ in 0 ..< 4 {
                    value = value << 8 | UInt32(bytes[index])
                    index = bytes.index(after: index)
                }
                fields.append(value)
            }
            guard fields[0] == FrameProtocolConstants.version else {
                throw FrameError.unsupportedVersion(fields[0])
            }
            return FrameHeader(type: fields[1], tag: fields[2], payloadSize: fields[3])
        }
    }

    /// One frame. An empty payload is what Peertalk delivered as a nil
    /// payload: the header says 0 and no payload bytes follow.
    public struct TransportFrame: Equatable, Sendable {
        public var type: UInt32
        public var tag: UInt32
        public var payload: Data

        public init(type: UInt32, tag: UInt32, payload: Data = Data()) {
            self.type = type
            self.tag = tag
            self.payload = payload
        }

        public var header: FrameHeader {
            FrameHeader(type: type, tag: tag, payloadSize: UInt32(truncatingIfNeeded: payload.count))
        }

        /// The frame's wire bytes: header, then payload.
        ///
        /// - Throws: `FrameError.payloadSizeOverflow` for a payload of
        ///   4 GiB or more (Peertalk asserted instead).
        public func encoded() throws -> Data {
            guard payload.count <= Int(UInt32.max) else {
                throw FrameError.payloadSizeOverflow(payload.count)
            }
            var data = header.encoded
            data.append(payload)
            return data
        }
    }

#endif
