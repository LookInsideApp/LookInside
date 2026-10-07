//
//  LookinFrameDecoder.swift
//  LookinCore
//
//  Turns a byte stream into frames, however the bytes are split or joined
//  across reads. It reproduces what Peertalk's read loop delivered
//  (Fixtures/receive-behaviour.json):
//
//  - a header is decided on as soon as its 16 bytes are in: the `accepting`
//    closure sees it before any payload byte is buffered, like Peertalk's
//    `shouldAcceptFrameOfType:tag:payloadSize:`;
//  - a rejected frame's payload is skipped as it arrives, never buffered;
//  - a header of type 0 is Peertalk's end-of-stream marker: the decoder
//    reports `.endOfStream` without asking `accepting`, and decodes nothing
//    after it;
//  - a version other than 1 is an error that ends the stream.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    public struct LookinFrameDecoder {
        public enum Output: Equatable {
            /// An accepted frame, payload complete.
            case frame(LookinFrame)
            /// A type-0 header arrived: the stream is over.
            case endOfStream
        }

        /// Where the stream stands between two complete frames.
        public enum Position: Equatable {
            /// At a frame boundary (or finished).
            case betweenFrames
            /// Some, but not all, of a header is buffered.
            case insideHeader
            /// A header is decided on and its payload is incomplete.
            case insidePayload
        }

        private enum State {
            case header
            case payload(LookinFrameHeader)
            case discarding(remaining: Int)
            case finished
        }

        /// The largest payload an accepted frame may announce; a larger one
        /// throws `LookinFrameError.payloadTooLarge`. `UInt32.max`, the
        /// default, accepts every frame, as Peertalk did.
        public let maxPayloadSize: UInt32

        private var buffer = Data()
        /// Index into `buffer` of the first byte not yet consumed.
        private var readIndex: Int
        private var state: State = .header

        public init(maxPayloadSize: UInt32 = .max) {
            self.maxPayloadSize = maxPayloadSize
            readIndex = buffer.startIndex
        }

        /// Bytes received and not yet handed out.
        public var bufferedByteCount: Int {
            buffer.endIndex - readIndex
        }

        public var position: Position {
            switch state {
            case .header:
                return bufferedByteCount == 0 ? .betweenFrames : .insideHeader
            case .payload, .discarding:
                return .insidePayload
            case .finished:
                return .betweenFrames
            }
        }

        /// True once a type-0 header was read; later bytes are ignored.
        public var isFinished: Bool {
            if case .finished = state {
                return true
            }
            return false
        }

        /// Adds received bytes. Bytes after the end of the stream are dropped.
        public mutating func append(_ bytes: Data) {
            guard !bytes.isEmpty, !isFinished else { return }
            if case let .discarding(remaining) = state, bufferedByteCount == 0 {
                // Skip without buffering.
                let skipped = min(remaining, bytes.count)
                if skipped < bytes.count {
                    buffer = bytes.subdata(in: bytes.startIndex + skipped ..< bytes.endIndex)
                    readIndex = buffer.startIndex
                }
                state = remaining - skipped > 0 ? .discarding(remaining: remaining - skipped) : .header
                return
            }
            compactIfWorthwhile()
            buffer.append(bytes)
        }

        /// The next accepted frame, `.endOfStream`, or nil when more bytes are
        /// needed. Call it until it returns nil after every `append`.
        ///
        /// - Parameter accepting: decides on each header once, before its
        ///   payload is read; a rejected frame is skipped. Not called for a
        ///   type-0 header.
        /// - Throws: `LookinFrameError.unsupportedVersion` or
        ///   `.payloadTooLarge`; the decoder is finished afterwards.
        public mutating func next(accepting: (LookinFrameHeader) -> Bool = { _ in true }) throws -> Output? {
            while true {
                switch state {
                case .finished:
                    return nil

                case let .discarding(remaining):
                    let skipped = min(remaining, bufferedByteCount)
                    readIndex += skipped
                    if remaining - skipped > 0 {
                        state = .discarding(remaining: remaining - skipped)
                        return nil
                    }
                    state = .header

                case .header:
                    guard bufferedByteCount >= LookinFrameProtocol.headerSize else {
                        return nil
                    }
                    let header: LookinFrameHeader
                    do {
                        header = try LookinFrameHeader.decode(buffer[readIndex ..< readIndex + LookinFrameProtocol.headerSize])
                    } catch {
                        state = .finished
                        throw error
                    }
                    readIndex += LookinFrameProtocol.headerSize
                    if header.type == LookinFrameProtocol.endOfStreamType {
                        state = .finished
                        buffer = Data()
                        readIndex = buffer.startIndex
                        return .endOfStream
                    }
                    guard accepting(header) else {
                        state = header.payloadSize > 0 ? .discarding(remaining: Int(header.payloadSize)) : .header
                        continue
                    }
                    guard header.payloadSize <= maxPayloadSize else {
                        state = .finished
                        throw LookinFrameError.payloadTooLarge(size: header.payloadSize, limit: maxPayloadSize)
                    }
                    state = .payload(header)

                case let .payload(header):
                    let size = Int(header.payloadSize)
                    guard bufferedByteCount >= size else {
                        return nil
                    }
                    let payload = size > 0 ? Data(buffer[readIndex ..< readIndex + size]) : Data()
                    readIndex += size
                    state = .header
                    return .frame(LookinFrame(type: header.type, tag: header.tag, payload: payload))
                }
            }
        }

        /// Drops consumed bytes once they are the larger part of the buffer.
        private mutating func compactIfWorthwhile() {
            let consumed = readIndex - buffer.startIndex
            guard consumed > 0 else { return }
            if consumed == buffer.count {
                buffer = Data()
            } else if consumed >= 64 * 1024, consumed * 2 >= buffer.count {
                buffer = buffer.subdata(in: readIndex ..< buffer.endIndex)
            } else {
                return
            }
            readIndex = buffer.startIndex
        }
    }

#endif
