//
//  ServerChannel.swift
//  LookInside
//
//  One connection to an inspected app's Server: a FrameChannel on a
//  loopback TCP socket (Simulator and Mac apps) or a usbmuxd tunnel (USB
//  devices), plus the state the connection manager keeps for it. Frames,
//  send completions and the end arrive on the main queue; frames and the
//  end reach the delegate a time slice per main-queue turn, so a long
//  response does not hold the main thread (see PacedMainQueueDelivery).
//

import Foundation
import LookInsideHostCore

/// Where a channel's Server runs.
enum ServerChannelKind {
    case simulator
    case mac
    case usb(deviceID: Int)
}

/// Receives a channel's frames and its end, on the main actor.
@MainActor
protocol ServerChannelDelegate: AnyObject {
    /// Decides on each frame header before its payload is read; a rejected
    /// frame's payload is skipped.
    func channel(_ channel: ServerChannel, shouldAcceptFrameOfType type: UInt32, tag: UInt32) -> Bool
    /// An accepted frame; an empty payload is `Data()`.
    func channel(_ channel: ServerChannel, didReceiveFrameOfType type: UInt32, tag: UInt32, payload: Data)
    /// The channel ended: the Server closed it, the stream was invalid, or
    /// the Host closed it. Runs once, after the socket is closed.
    func channelDidEnd(_ channel: ServerChannel)
}

@MainActor
final class ServerChannel: NSObject {
    let port: Int32
    let kind: ServerChannelKind
    /// Requests, license handshake and Server release of this connection;
    /// released with the channel.
    let connectionState = ServerChannelConnectionState()

    private let frameChannel: FrameChannel
    /// The frames and the end the frame channel reported, in order, on their
    /// way to the delegate. Released once the end is delivered.
    private var channelEvents: PacedMainQueueDelivery<ChannelEvent>?

    /// What one main-queue turn spends handing frames to the delegate: about
    /// half a 60 Hz frame, so the run loop keeps time for events and drawing.
    private static let eventDeliveryTimeBudget: Duration = .milliseconds(8)

    /// True until the channel ends or is closed.
    var isConnected: Bool {
        frameChannel.isConnected
    }

    /// Takes over `fileDescriptor`, a connected socket, and starts reading.
    /// `initialBytes` are frame bytes read before the channel existed (after
    /// a usbmuxd Connect result). The channel stays alive until it ends.
    init(fileDescriptor: Int32, initialBytes: Data = Data(), port: Int32, kind: ServerChannelKind, delegate: ServerChannelDelegate) {
        self.port = port
        self.kind = kind
        // The Host takes any payload size, as Peertalk did: a hierarchy
        // response can be large.
        frameChannel = FrameChannel(
            fileDescriptor: fileDescriptor,
            queue: .main,
            maxPayloadSize: .max,
            initialBytes: initialBytes
        )
        super.init()
        // The callbacks hold the channel until it ends, as Peertalk's
        // dispatch I/O handlers did; the frame channel drops them after
        // onEnd, and the delivery lets go of the channel once the end is
        // delivered.
        let channelEvents = PacedMainQueueDelivery<ChannelEvent>(timeBudget: Self.eventDeliveryTimeBudget) { [self, weak delegate] event in
            switch event {
            case let .frame(frame):
                delegate?.channel(self, didReceiveFrameOfType: frame.type, tag: frame.tag, payload: frame.payload)
            case .end:
                self.channelEvents = nil
                delegate?.channelDidEnd(self)
            }
        }
        self.channelEvents = channelEvents
        // A frame header is decided on as it is read, ahead of the frames
        // still waiting for the delegate. A frame accepted for a request that
        // ends before the frame is delivered is dropped there.
        frameChannel.shouldAcceptFrame = { [self, weak delegate] header in
            MainActor.assumeIsolated {
                delegate?.channel(self, shouldAcceptFrameOfType: header.type, tag: header.tag) ?? false
            }
        }
        frameChannel.onFrame = { frame in
            MainActor.assumeIsolated {
                channelEvents.enqueue(.frame(frame))
            }
        }
        frameChannel.onEnd = { _ in
            MainActor.assumeIsolated {
                channelEvents.enqueue(.end)
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

    /// Whether a frame of `type` with `tag` was read and still waits for its
    /// turn to reach the delegate. A request whose response waits here has
    /// been answered in time: its timeout starts over instead of expiring.
    func hasUndeliveredFrame(type: UInt32, tag: UInt32) -> Bool {
        channelEvents?.containsPending { event in
            guard case let .frame(frame) = event else { return false }
            return frame.type == type && frame.tag == tag
        } ?? false
    }

    /// Ends the channel now; queued writes are dropped, and so are the
    /// frames read but not delivered yet, as the frame channel stops reading.
    /// The delegate hears `channelDidEnd` once.
    func close() {
        channelEvents?.removePending { event in
            if case .frame = event {
                return true
            }
            return false
        }
        frameChannel.close()
    }

    /// What the frame channel reported.
    private enum ChannelEvent {
        case frame(TransportFrame)
        case end
    }

    override nonisolated var description: String {
        String(format: "<ServerChannel: 0x%lx, port %d>", UInt(bitPattern: Unmanaged.passUnretained(self).toOpaque()), port)
    }
}
