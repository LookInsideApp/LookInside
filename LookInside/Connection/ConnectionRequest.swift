//
//  ConnectionRequest.swift
//  LookInside
//
//  One request the Host sent on a channel and has not heard the end of.
//

import Foundation
import FoundationToolbox
import LookInsideHostCore

/// What a request reports, in order: zero or more responses, then either a
/// failure or a completion.
enum ResponseEvent {
    /// One response frame. `nil` when its payload could not be decoded.
    case response(ConnectionResponseAttachment?)
    case failure(NSError)
    case completion
}

/// Receives the events of one request on the main actor until it is
/// detached or a failure or completion ends it. Detaching stops the
/// delivery only; the request itself runs to its end.
@MainActor
final class ResponseSink {
    private var onEvent: ((ResponseEvent) -> Void)?
    /// Set by `cancel()`. A request still waiting for its ping when it is
    /// cancelled is not sent.
    private(set) var isCancelled = false

    init(_ onEvent: @escaping (ResponseEvent) -> Void) {
        self.onEvent = onEvent
    }

    var isDetached: Bool {
        onEvent == nil
    }

    /// Ends the delivery with a completion, the way a cancelled request
    /// ends.
    func cancel() {
        isCancelled = true
        send(.completion)
    }

    func send(_ event: ResponseEvent) {
        guard let onEvent else { return }
        switch event {
        case .response:
            break
        case .failure, .completion:
            self.onEvent = nil
        }
        onEvent(event)
    }

    func detach() {
        onEvent = nil
    }
}

/// A request in flight on one channel. The timeout is a `ResponseCountdown`:
/// it fires on the main run loop in the default mode only, like the
/// Objective-C class this replaces, and it does not expire while a response
/// to the request waits to be handed over.
@MainActor
final class ConnectionRequest: NSObject, ChannelRequest {
    let type: UInt32
    let tag: UInt32
    let sink: ResponseSink
    var frameProgress = ResponseFrameProgress()
    /// The signpost interval of a hierarchy or detail request, from the
    /// send until the request leaves its channel; nil for other requests.
    var signpostInterval: SignpostInterval?

    /// Must be positive.
    private let timeoutInterval: TimeInterval
    private let isResponseWaiting: (ConnectionRequest) -> Bool
    private let onTimeout: (ConnectionRequest) -> Void
    /// The running countdown. Only the run loop holds it, and through its
    /// closures this request, while it runs: a request whose channel is gone
    /// still times out and reports it, as the request kept alive by
    /// `-performSelector:afterDelay:` did.
    private weak var countdown: ResponseCountdown?

    /// - Parameter isResponseWaiting: whether a response to the request was
    ///   read but not handed over yet; the countdown starts over then.
    init(
        type: UInt32,
        tag: UInt32,
        timeoutInterval: TimeInterval,
        sink: ResponseSink,
        isResponseWaiting: @escaping (ConnectionRequest) -> Bool,
        onTimeout: @escaping (ConnectionRequest) -> Void
    ) {
        self.type = type
        self.tag = tag
        self.timeoutInterval = timeoutInterval
        self.sink = sink
        self.isResponseWaiting = isResponseWaiting
        self.onTimeout = onTimeout
    }

    /// Starts or restarts the countdown.
    func resetTimeoutCount() {
        endTimeoutCount()
        let countdown = ResponseCountdown(
            interval: timeoutInterval,
            isResponseWaiting: { [self] in isResponseWaiting(self) },
            onExpire: { [self] in onTimeout(self) }
        )
        self.countdown = countdown
        countdown.restart()
    }

    /// Closes `signpostInterval`, once.
    func endSignpostInterval() {
        guard let signpostInterval else { return }
        self.signpostInterval = nil
        #signpost(.end, signpostInterval)
    }

    /// Stops the countdown. Called before the request is dropped.
    func endTimeoutCount() {
        countdown?.stop()
    }
}
