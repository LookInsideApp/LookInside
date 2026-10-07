import Compression
import Foundation

/// Coverage for gzip inflation of `.viewhierarchy` response entries.
///
/// Two failure modes motivate this file, and neither one announces itself:
///
///  1. **Silent truncation.** The inflater streams through a fixed output
///     buffer, so a payload larger than that buffer exercises a loop that, if
///     it stops early, yields JSON that still parses — just with the tail of
///     the hierarchy missing. The large-payload case here is the guard.
///  2. **Header walking.** A gzip header is variable length: optional filename,
///     comment, and extra fields sit between the magic and the DEFLATE stream.
///     Assuming the fixed 10-byte form feeds garbage to the decoder for any
///     capture written with those flags set.
@main
struct LKXcodeViewHierarchyGzipTests {
    static func main() {
        testMinimalMemberRoundTrips()
        testMemberWithNameAndCommentAndExtraFieldRoundTrips()
        testPayloadLargerThanStreamBufferRoundTrips()
        testNonGzipPayloadPassesThroughUnchanged()
        testTruncatedHeaderIsRejected()
        testUnsupportedCompressionMethodIsRejected()
        testGzipMemberDetection()
        print("Xcode view hierarchy gzip tests passed")
    }

    // MARK: - Round trips

    private static func testMinimalMemberRoundTrips() {
        let original = Data("{\"topLevelGroups\":{}}".utf8)
        let member = gzipMember(wrapping: original)
        let inflated = inflate(member)
        expect(inflated == original, "minimal gzip member should round-trip")
    }

    private static func testMemberWithNameAndCommentAndExtraFieldRoundTrips() {
        let original = Data("{\"version\":2}".utf8)
        let member = gzipMember(
            wrapping: original,
            originalName: "Response_0",
            comment: "captured by Xcode",
            extraField: Data([0x01, 0x02, 0x03, 0x04])
        )
        let inflated = inflate(member)
        expect(inflated == original, "gzip member with optional header fields should round-trip")
    }

    /// The response entries in a real capture inflate to several megabytes; the
    /// inflater's output buffer is 256 KB, so this is the case that proves the
    /// streaming loop keeps going instead of returning a first chunk.
    private static func testPayloadLargerThanStreamBufferRoundTrips() {
        var original = Data()
        original.reserveCapacity(3 * 1024 * 1024)
        // Semi-repetitive content: compresses well, but not to a degenerate stream.
        for index in 0 ..< 60000 {
            original.append(Data("{\"objectID\":\"0x\(String(index, radix: 16))\",\"className\":\"UIView\"},".utf8))
        }
        expect(original.count > 1024 * 1024, "fixture should exceed the stream buffer")

        let member = gzipMember(wrapping: original)
        let inflated = inflate(member)
        expect(inflated.count == original.count,
               "inflated \(inflated.count) bytes but expected \(original.count) — streaming loop truncated")
        expect(inflated == original, "large payload should round-trip byte for byte")
    }

    // MARK: - Non-gzip and malformed input

    /// Entries are compressed only when the capture asked for it, so an
    /// uncompressed entry must pass through rather than fail.
    private static func testNonGzipPayloadPassesThroughUnchanged() {
        let plain = Data("{\"request\":{}}".utf8)
        let result = inflateIfNeeded(plain)
        expect(result == plain, "a non-gzip payload should pass through untouched")
    }

    private static func testTruncatedHeaderIsRejected() {
        let truncated = Data([0x1F, 0x8B, 0x08, 0x08, 0x00, 0x00])
        do {
            _ = try LKXcodeViewHierarchyGzip.inflating(truncated)
            fail("a truncated gzip header must be rejected")
        } catch {
            // Expected.
        }
    }

    private static func testUnsupportedCompressionMethodIsRejected() {
        var member = [UInt8](repeating: 0, count: 20)
        member[0] = 0x1F
        member[1] = 0x8B
        member[2] = 0x07 // not DEFLATE
        do {
            _ = try LKXcodeViewHierarchyGzip.inflating(Data(member))
            fail("a non-DEFLATE compression method must be rejected")
        } catch {
            // Expected.
        }
    }

    private static func testGzipMemberDetection() {
        let member = gzipMember(wrapping: Data("x".utf8))
        expect(LKXcodeViewHierarchyGzip.isGzipMember(member), "a real member should be detected")
        expect(!LKXcodeViewHierarchyGzip.isGzipMember(Data("{\"a\":1}".utf8)),
               "JSON should not be mistaken for a gzip member")
        expect(!LKXcodeViewHierarchyGzip.isGzipMember(Data([0x1F, 0x8B])),
               "a two-byte payload is too short to be a member")
    }

    // MARK: - Fixture construction

    /// Builds a real gzip member: header, raw DEFLATE stream, trailer.
    /// The trailer's CRC is left zero because the inflater does not verify it;
    /// only its length matters, since it must be trimmed before decoding.
    private static func gzipMember(
        wrapping payload: Data,
        originalName: String? = nil,
        comment: String? = nil,
        extraField: Data? = nil
    ) -> Data {
        var flags: UInt8 = 0
        if extraField != nil {
            flags |= 0x04
        }
        if originalName != nil {
            flags |= 0x08
        }
        if comment != nil {
            flags |= 0x10
        }

        var member = Data([0x1F, 0x8B, 0x08, flags, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03])
        if let extraField {
            member.append(UInt8(extraField.count & 0xFF))
            member.append(UInt8((extraField.count >> 8) & 0xFF))
            member.append(extraField)
        }
        if let originalName {
            member.append(Data(originalName.utf8))
            member.append(0)
        }
        if let comment {
            member.append(Data(comment.utf8))
            member.append(0)
        }

        member.append(rawDeflate(payload))

        member.append(Data([0x00, 0x00, 0x00, 0x00])) // CRC32, unverified
        let inputSize = UInt32(truncatingIfNeeded: payload.count)
        member.append(Data([
            UInt8(inputSize & 0xFF),
            UInt8((inputSize >> 8) & 0xFF),
            UInt8((inputSize >> 16) & 0xFF),
            UInt8((inputSize >> 24) & 0xFF),
        ]))
        return member
    }

    private static func rawDeflate(_ payload: Data) -> Data {
        let sourceBytes = [UInt8](payload)
        let capacity = max(sourceBytes.count + 4096, 8192)
        var destination = [UInt8](repeating: 0, count: capacity)
        let writtenCount = sourceBytes.withUnsafeBufferPointer { source in
            destination.withUnsafeMutableBufferPointer { target in
                compression_encode_buffer(
                    target.baseAddress!, capacity,
                    source.baseAddress!, sourceBytes.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        guard writtenCount > 0 else { fail("fixture compression produced no output") }
        return Data(destination[0 ..< writtenCount])
    }

    // MARK: - Helpers

    private static func inflate(_ member: Data) -> Data {
        do {
            return try LKXcodeViewHierarchyGzip.inflating(member)
        } catch {
            fail("inflating threw: \(error)")
        }
    }

    private static func inflateIfNeeded(_ payload: Data) -> Data {
        do {
            return try LKXcodeViewHierarchyGzip.inflatingIfNeeded(payload)
        } catch {
            fail("inflatingIfNeeded threw: \(error)")
        }
    }

    private static func expect(_ condition: Bool, _ message: String) {
        guard condition else {
            fail(message)
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        Foundation.exit(1)
    }
}
