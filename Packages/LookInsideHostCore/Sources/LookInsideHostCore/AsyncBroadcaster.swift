import Foundation

/// Sends every value to all current subscribers. Each `subscribe` call
/// returns a new `AsyncStream` with its own buffer.
///
/// - A subscriber receives only the values yielded after it subscribed.
///   There is no replay.
/// - Values from one producer arrive in the order they were yielded.
/// - When a subscriber's task is cancelled, or it stops iterating and drops
///   the stream, it is removed. Later values are not buffered for it.
/// - `finish()` ends every stream. A subscriber that arrives after that gets
///   a stream that is already finished. Releasing the broadcaster finishes
///   the streams in the same way.
/// - The broadcaster keeps no strong reference from a stream back to itself,
///   so a subscriber that is still listening does not keep it alive.
///
/// Safe to use from any thread. `Element` does not have to be `Sendable`:
/// the Host sends AppKit-confined objects (such as connection channels) and
/// produces and consumes them on the main actor.
public final class AsyncBroadcaster<Element>: @unchecked Sendable {
    public typealias BufferingPolicy = AsyncStream<Element>.Continuation.BufferingPolicy

    private let lock = NSLock()
    /// Serialises `yield` so values from concurrent producers reach every
    /// subscriber in one order. Never held together with a termination
    /// handler: those take only `lock`.
    private let deliveryLock = NSLock()
    private var continuations: [Int: AsyncStream<Element>.Continuation] = [:]
    private var nextSubscriberID = 0
    private var isFinished = false
    private let defaultBufferingPolicy: BufferingPolicy

    /// - Parameter bufferingPolicy: how many values each subscriber keeps
    ///   while it is not iterating. Unbounded unless a subscriber asks for
    ///   another policy.
    public init(bufferingPolicy: BufferingPolicy = .unbounded) {
        defaultBufferingPolicy = bufferingPolicy
    }

    deinit {
        for continuation in continuations.values {
            continuation.finish()
        }
    }

    /// The number of subscribers whose streams are still open.
    public var subscriberCount: Int {
        lock.withLock { continuations.count }
    }

    /// Returns a stream of the values yielded from now on.
    ///
    /// - Parameter bufferingPolicy: overrides the broadcaster's policy for
    ///   this subscriber.
    public func subscribe(bufferingPolicy: BufferingPolicy? = nil) -> AsyncStream<Element> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: Element.self,
            bufferingPolicy: bufferingPolicy ?? defaultBufferingPolicy
        )
        let subscriberID: Int? = lock.withLock {
            guard !isFinished else { return nil }
            let subscriberID = nextSubscriberID
            nextSubscriberID += 1
            continuations[subscriberID] = continuation
            return subscriberID
        }
        guard let subscriberID else {
            continuation.finish()
            return stream
        }
        // Set outside the lock: the handler takes it, and it may run at once
        // on this thread if the stream is already gone.
        continuation.onTermination = { [weak self] _ in
            self?.removeSubscriber(subscriberID)
        }
        return stream
    }

    /// Sends `value` to every current subscriber. Does nothing after
    /// `finish()`.
    public func yield(_ value: Element) {
        // Each subscriber gets the same value. `Element` is not required to
        // be Sendable (see the type's note), so the compiler is told not to
        // track it; the Host yields and consumes on the main actor.
        nonisolated(unsafe) let shared = value
        // Deliver outside `lock`: yielding to a stream whose consumer was
        // cancelled can run its termination handler on this thread, and that
        // handler takes `lock` (a deadlock seen in testing). `deliveryLock`
        // keeps concurrent producers in one order instead.
        deliveryLock.withLock {
            let current = lock.withLock { Array(continuations.values) }
            for continuation in current {
                continuation.yield(shared)
            }
        }
    }

    /// Ends every subscriber's stream and every later subscription.
    public func finish() {
        let finishing: [AsyncStream<Element>.Continuation] = lock.withLock {
            isFinished = true
            let finishing = Array(continuations.values)
            continuations.removeAll()
            return finishing
        }
        // Outside the lock: finishing runs each stream's termination handler,
        // which takes the lock again.
        for continuation in finishing {
            continuation.finish()
        }
    }

    private func removeSubscriber(_ subscriberID: Int) {
        lock.withLock {
            _ = continuations.removeValue(forKey: subscriberID)
        }
    }
}
