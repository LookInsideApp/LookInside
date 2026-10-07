//
//  LKChannel.swift
//  LookInside
//
//  One connection to an inspected app's Server: a LookinFrameChannel on a
//  loopback TCP socket (Simulator and Mac apps) or a usbmuxd tunnel (USB
//  devices), plus the state the connection manager keeps for it. Frames,
//  send completions and the end arrive on the main queue.
//

import Foundation

/// Where a channel's Server runs.
enum LKChannelKind {
    case simulator
    case mac
    case usb(deviceID: Int)
}

/// Receives a channel's frames and its end, on the main actor.
@MainActor
protocol LKChannelDelegate: AnyObject {
    /// Decides on each frame header before its payload is read; a rejected
    /// frame's payload is skipped.
    func channel(_ channel: LKChannel, shouldAcceptFrameOfType type: UInt32, tag: UInt32) -> Bool
    /// An accepted frame; an empty payload is `Data()`.
    func channel(_ channel: LKChannel, didReceiveFrameOfType type: UInt32, tag: UInt32, payload: Data)
    /// The channel ended: the Server closed it, the stream was invalid, or
    /// the Host closed it. Runs once, after the socket is closed.
    func channelDidEnd(_ channel: LKChannel)
}

@MainActor
final class LKChannel: NSObject {
    let port: Int32
    let kind: LKChannelKind
    /// Requests, license handshake and Server release of this connection;
    /// released with the channel.
    let connectionState = LKChannelConnectionState()

    private let frameChannel: LookinFrameChannel

    /// True until the channel ends or is closed.
    var isConnected: Bool {
        frameChannel.isConnected
    }

    /// Takes over `fileDescriptor`, a connected socket, and starts reading.
    /// `initialBytes` are frame bytes read before the channel existed (after
    /// a usbmuxd Connect result). The channel stays alive until it ends.
    init(fileDescriptor: Int32, initialBytes: Data = Data(), port: Int32, kind: LKChannelKind, delegate: LKChannelDelegate) {
        self.port = port
        self.kind = kind
        // The Host takes any payload size, as Peertalk did: a hierarchy
        // response can be large.
        frameChannel = LookinFrameChannel(
            fileDescriptor: fileDescriptor,
            queue: .main,
            maxPayloadSize: .max,
            initialBytes: initialBytes
        )
        super.init()
        // The callbacks hold the channel until it ends, as Peertalk's
        // dispatch I/O handlers did; the frame channel drops them after
        // onEnd.
        frameChannel.shouldAcceptFrame = { [self, weak delegate] header in
            MainActor.assumeIsolated {
                delegate?.channel(self, shouldAcceptFrameOfType: header.type, tag: header.tag) ?? false
            }
        }
        frameChannel.onFrame = { [self, weak delegate] frame in
            MainActor.assumeIsolated {
                delegate?.channel(self, didReceiveFrameOfType: frame.type, tag: frame.tag, payload: frame.payload)
            }
        }
        frameChannel.onEnd = { [self, weak delegate] _ in
            MainActor.assumeIsolated {
                delegate?.channelDidEnd(self)
            }
        }
        frameChannel.start()
    }

    /// Sends one frame; an empty payload sends the header only.
    /// `completion` runs on the main actor with nil once the frame is
    /// written, or the error (EPERM when the channel is closed).
    func send(type: UInt32, tag: UInt32, payload: Data, completion: (@MainActor (Error?) -> Void)? = nil) {
        frameChannel.send(type: type, tag: tag, payload: payload) { error in
            guard let completion else { return }
            MainActor.assumeIsolated {
                completion(error)
            }
        }
    }

    /// Ends the channel now; queued writes are dropped. The delegate hears
    /// `channelDidEnd` once.
    func close() {
        frameChannel.close()
    }

    override nonisolated var description: String {
        String(format: "<LKChannel: 0x%lx, port %d>", UInt(bitPattern: Unmanaged.passUnretained(self).toOpaque()), port)
    }
}
