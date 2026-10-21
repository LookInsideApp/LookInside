//
//  HostAppTests.swift
//  LookInsideAppTests
//
//  The tests run inside the LookInside app (the bundle's test host), against
//  its singletons: ConnectionManager.shared, NSApp and its delegate. Two
//  tests touching those at once would see each other's channels, reports
//  and windows, so every suite is nested in this serialized one.
//

import Foundation
@testable import LookInside
import Testing

@Suite(.serialized)
@MainActor
enum HostAppTests {}

/// Lets the main queue run until `condition` holds; false when `timeout`
/// passes first. Frames, channel ends and request timeouts all arrive on
/// the main queue, so a test that awaits here lets them through.
@MainActor
func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !condition() {
        guard clock.now < deadline else { return false }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return true
}

/// Records the events a request reports through its `ResponseSink`.
@MainActor
final class ResponseRecorder {
    private(set) var responses: [ConnectionResponseAttachment?] = []
    private(set) var failure: NSError?
    private(set) var isCompleted = false

    private(set) lazy var sink = ResponseSink { [weak self] event in
        guard let self else { return }
        switch event {
        case let .response(attachment):
            responses.append(attachment)
        case let .failure(error):
            failure = error
        case .completion:
            isCompleted = true
        }
    }

    /// Whether the request reported its end, a failure or a completion.
    var hasEnded: Bool {
        failure != nil || isCompleted
    }
}

/// Collects what an `AsyncStream` delivers while a test runs; `stop()`
/// ends the subscription.
@MainActor
final class StreamCollector<Element> {
    private(set) var elements: [Element] = []
    private var task: Task<Void, Never>?

    init(_ stream: AsyncStream<Element>) {
        task = Task { [weak self] in
            for await element in stream {
                self?.elements.append(element)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
