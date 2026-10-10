//
//  ConnectionRequest.swift
//  LookInside
//
//  One request the Host sent on a channel and has not heard the end of.
//

import Foundation
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

    init(_ onEvent: @escaping (ResponseEvent) -> Void) {
        self.onEvent = onEvent
    }

    var isDetached: Bool {
        onEvent == nil
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

/// A request in flight on one channel. The timeout uses
/// `-performSelector:withObject:afterDelay:` like the Objective-C class it
/// replaces, so it fires on the main run loop in the default mode only.
@MainActor
final class ConnectionRequest: NSObject {
    let type: UInt32
    let tag: UInt32
    let sink: ResponseSink
    var frameProgress = ResponseFrameProgress()

    /// Must be positive.
    private let timeoutInterval: TimeInterval
    private let onTimeout: (ConnectionRequest) -> Void

    init(
        type: UInt32,
        tag: UInt32,
        timeoutInterval: TimeInterval,
        sink: ResponseSink,
        onTimeout: @escaping (ConnectionRequest) -> Void
    ) {
        self.type = type
        self.tag = tag
        self.timeoutInterval = timeoutInterval
        self.sink = sink
        self.onTimeout = onTimeout
    }

    /// Starts or restarts the countdown.
    func resetTimeoutCount() {
        endTimeoutCount()
        guard timeoutInterval > 0 else {
            assertionFailure("timeoutInterval is 0")
            return
        }
        perform(#selector(handleTimeout), with: nil, afterDelay: timeoutInterval)
    }

    /// Stops the countdown. Called before the request is dropped.
    func endTimeoutCount() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }

    @objc private func handleTimeout() {
        onTimeout(self)
    }
}
