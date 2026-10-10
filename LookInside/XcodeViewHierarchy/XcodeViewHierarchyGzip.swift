// XcodeViewHierarchyGzip.swift
//
// Gzip inflation for the `Response_N` entries inside an Xcode-exported
// `.viewhierarchy` bundle.
//
// Why this exists rather than a one-liner: an entry is compressed only when
// the capture that produced it asked for transport compression, so a reader
// has to sniff each file rather than assume. Xcode's own reader does the same
// (`_decompressedDataForRequestResponseData:` branches on the gzip magic).
//
// The payload is a gzip *member* — a header, a raw DEFLATE stream, and an
// 8-byte trailer — while Apple's `COMPRESSION_ZLIB` consumes raw DEFLATE. So
// the header has to be walked (its length varies with the flag byte) and the
// trailer trimmed before handing the middle to libcompression. Decoding is
// streamed rather than sized from the trailer's ISIZE field, because ISIZE is
// only the uncompressed length modulo 2^32 and is therefore a hint, not a
// contract.

import Compression
import Foundation

enum XcodeViewHierarchyGzipError: Error, CustomStringConvertible {
    case truncatedHeader
    case unsupportedCompressionMethod(UInt8)
    case truncatedPayload
    case inflateFailed

    var description: String {
        switch self {
        case .truncatedHeader:
            return "gzip header is truncated"
        case let .unsupportedCompressionMethod(method):
            return "gzip compression method \(method) is not DEFLATE"
        case .truncatedPayload:
            return "gzip payload ends before its trailer"
        case .inflateFailed:
            return "libcompression rejected the DEFLATE stream"
        }
    }
}

enum XcodeViewHierarchyGzip {
    private static let streamBufferSize = 256 * 1024

    private enum HeaderFlag {
        static let text: UInt8 = 0x01
        static let headerChecksum: UInt8 = 0x02
        static let extraField: UInt8 = 0x04
        static let originalName: UInt8 = 0x08
        static let comment: UInt8 = 0x10
    }

    /// True when the payload opens with a gzip member header.
    static func isGzipMember(_ payload: Data) -> Bool {
        // 18 is the shortest possible member: 10-byte header, 2 bytes of
        // DEFLATE for the empty stream, 8-byte trailer.
        guard payload.count >= 18 else { return false }
        let bytes = [UInt8](payload.prefix(3))
        return bytes[0] == 0x1F && bytes[1] == 0x8B && bytes[2] == 8
    }

    /// Inflates a gzip member; returns the payload untouched when it is not one.
    static func inflatingIfNeeded(_ payload: Data) throws -> Data {
        guard isGzipMember(payload) else { return payload }
        return try inflating(payload)
    }

    /// Inflates a gzip member.
    static func inflating(_ payload: Data) throws -> Data {
        let bytes = [UInt8](payload)
        let deflateStart = try deflateStreamOffset(in: bytes)
        guard bytes.count >= deflateStart + 8 else { throw XcodeViewHierarchyGzipError.truncatedPayload }
        let deflateBytes = bytes[deflateStart ..< (bytes.count - 8)]
        return try inflatingRawDeflate(Array(deflateBytes))
    }

    /// Walks the variable-length gzip header and returns where the DEFLATE stream starts.
    private static func deflateStreamOffset(in bytes: [UInt8]) throws -> Int {
        guard bytes.count >= 10 else { throw XcodeViewHierarchyGzipError.truncatedHeader }
        guard bytes[0] == 0x1F, bytes[1] == 0x8B else { throw XcodeViewHierarchyGzipError.truncatedHeader }
        guard bytes[2] == 8 else { throw XcodeViewHierarchyGzipError.unsupportedCompressionMethod(bytes[2]) }

        let flags = bytes[3]
        var cursor = 10

        if flags & HeaderFlag.extraField != 0 {
            guard cursor + 1 < bytes.count else { throw XcodeViewHierarchyGzipError.truncatedHeader }
            let extraFieldLength = Int(bytes[cursor]) | (Int(bytes[cursor + 1]) << 8)
            cursor += 2 + extraFieldLength
        }
        if flags & HeaderFlag.originalName != 0 {
            cursor = try offsetPastNulTerminatedField(in: bytes, from: cursor)
        }
        if flags & HeaderFlag.comment != 0 {
            cursor = try offsetPastNulTerminatedField(in: bytes, from: cursor)
        }
        if flags & HeaderFlag.headerChecksum != 0 {
            cursor += 2
        }

        guard cursor < bytes.count else { throw XcodeViewHierarchyGzipError.truncatedHeader }
        return cursor
    }

    private static func offsetPastNulTerminatedField(in bytes: [UInt8], from start: Int) throws -> Int {
        var cursor = start
        while cursor < bytes.count, bytes[cursor] != 0 {
            cursor += 1
        }
        guard cursor < bytes.count else { throw XcodeViewHierarchyGzipError.truncatedHeader }
        return cursor + 1
    }

    private static func inflatingRawDeflate(_ deflateBytes: [UInt8]) throws -> Data {
        guard !deflateBytes.isEmpty else { return Data() }

        var stream = compression_stream(
            dst_ptr: UnsafeMutablePointer<UInt8>(bitPattern: 1)!,
            dst_size: 0,
            src_ptr: UnsafePointer<UInt8>(bitPattern: 1)!,
            src_size: 0,
            state: nil
        )
        guard compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB) == COMPRESSION_STATUS_OK
        else { throw XcodeViewHierarchyGzipError.inflateFailed }
        defer { compression_stream_destroy(&stream) }

        var inflated = Data()
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: streamBufferSize)
        defer { destinationBuffer.deallocate() }

        return try deflateBytes.withUnsafeBufferPointer { source -> Data in
            stream.src_ptr = source.baseAddress!
            stream.src_size = source.count

            while true {
                stream.dst_ptr = destinationBuffer
                stream.dst_size = streamBufferSize

                let status = compression_stream_process(&stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))
                let producedCount = streamBufferSize - stream.dst_size
                if producedCount > 0 {
                    inflated.append(destinationBuffer, count: producedCount)
                }

                switch status {
                case COMPRESSION_STATUS_END:
                    return inflated
                case COMPRESSION_STATUS_OK:
                    // Ran out of destination room; loop for another buffer.
                    guard producedCount > 0 else { throw XcodeViewHierarchyGzipError.inflateFailed }
                default:
                    throw XcodeViewHierarchyGzipError.inflateFailed
                }
            }
        }
    }
}
