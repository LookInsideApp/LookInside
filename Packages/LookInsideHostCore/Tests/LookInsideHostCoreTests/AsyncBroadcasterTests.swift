import Foundation
@testable import LookInsideHostCore
import Testing

/// A deadlock in the broadcaster hangs a test instead of failing it; the limit
/// turns that into a failure within a minute.
@Suite(.timeLimit(.minutes(1)))
struct AsyncBroadcasterTests {
    /// Waits until `condition` holds, polling, or fails after `timeout`.
    private func waitUntil(
        timeout: Duration = .seconds(5),
        _ condition: () -> Bool,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while !condition() {
            if clock.now >= deadline {
                Issue.record("condition did not become true in time", sourceLocation: sourceLocation)
                return
            }
            try await Task.sleep(for: .milliseconds(5))
        }
    }

    private func collect<Element>(_ stream: AsyncStream<Element>) async -> [Element] {
        var values: [Element] = []
        for await value in stream {
            values.append(value)
        }
        return values
    }

    @Test func everySubscriberReceivesEveryValueInOrder() async {
        let broadcaster = AsyncBroadcaster<Int>()
        let first = broadcaster.subscribe()
        let second = broadcaster.subscribe()
        #expect(broadcaster.subscriberCount == 2)

        for value in 1 ... 5 {
            broadcaster.yield(value)
        }
        broadcaster.finish()

        #expect(await collect(first) == [1, 2, 3, 4, 5])
        #expect(await collect(second) == [1, 2, 3, 4, 5])
    }

    @Test func lateSubscriberReceivesOnlyLaterValues() async {
        let broadcaster = AsyncBroadcaster<String>()
        let early = broadcaster.subscribe()
        broadcaster.yield("before")
        let late = broadcaster.subscribe()
        broadcaster.yield("after")
        broadcaster.finish()

        #expect(await collect(early) == ["before", "after"])
        #expect(await collect(late) == ["after"])
    }

    @Test func yieldWithoutSubscribersIsDropped() async {
        let broadcaster = AsyncBroadcaster<Int>()
        broadcaster.yield(1)
        let stream = broadcaster.subscribe()
        broadcaster.yield(2)
        broadcaster.finish()
        #expect(await collect(stream) == [2])
    }

    @Test func cancellingTheConsumerRemovesItsSubscription() async throws {
        let broadcaster = AsyncBroadcaster<Int>()
        let stream = broadcaster.subscribe()
        let survivor = broadcaster.subscribe()
        let received = LockedBox<[Int]>([])

        let consumer = Task {
            for await value in stream {
                received.mutate { $0.append(value) }
            }
        }
        broadcaster.yield(1)
        try await waitUntil { received.value == [1] }

        consumer.cancel()
        await consumer.value
        try await waitUntil { broadcaster.subscriberCount == 1 }

        broadcaster.yield(2)
        broadcaster.finish()
        #expect(received.value == [1])
        #expect(await collect(survivor) == [1, 2])
    }

    @Test func droppingAStreamWithoutIteratingRemovesItsSubscription() async throws {
        let broadcaster = AsyncBroadcaster<Int>()
        do {
            _ = broadcaster.subscribe()
        }
        try await waitUntil { broadcaster.subscriberCount == 0 }
    }

    @Test func finishEndsEveryStreamAndLaterSubscriptions() async {
        let broadcaster = AsyncBroadcaster<Int>()
        let stream = broadcaster.subscribe()
        let consumer = Task { await collect(stream) }

        broadcaster.yield(7)
        broadcaster.finish()
        #expect(await consumer.value == [7])
        #expect(broadcaster.subscriberCount == 0)

        // After finish: nothing is delivered and new streams end at once.
        broadcaster.yield(8)
        let afterFinish = broadcaster.subscribe()
        #expect(await collect(afterFinish).isEmpty)
        #expect(broadcaster.subscriberCount == 0)
    }

    @Test func finishIsIdempotent() async {
        let broadcaster = AsyncBroadcaster<Int>()
        let stream = broadcaster.subscribe()
        broadcaster.finish()
        broadcaster.finish()
        #expect(await collect(stream).isEmpty)
    }

    @Test func bufferingPolicyLimitsWhatAnIdleSubscriberKeeps() async {
        let broadcaster = AsyncBroadcaster<Int>(bufferingPolicy: .bufferingNewest(2))
        let newest = broadcaster.subscribe()
        let oldest = broadcaster.subscribe(bufferingPolicy: .bufferingOldest(1))
        let unbounded = broadcaster.subscribe(bufferingPolicy: .unbounded)

        for value in 1 ... 4 {
            broadcaster.yield(value)
        }
        broadcaster.finish()

        #expect(await collect(newest) == [3, 4])
        #expect(await collect(oldest) == [1])
        #expect(await collect(unbounded) == [1, 2, 3, 4])
    }

    @Test func aListeningSubscriberDoesNotKeepTheBroadcasterAlive() async {
        weak var weakBroadcaster: AsyncBroadcaster<Int>?
        let stream: AsyncStream<Int>
        do {
            let broadcaster = AsyncBroadcaster<Int>()
            weakBroadcaster = broadcaster
            stream = broadcaster.subscribe()
            broadcaster.yield(1)
        }
        #expect(weakBroadcaster == nil)
        // Releasing the broadcaster finished the stream after the buffered value.
        #expect(await collect(stream) == [1])
    }

    @Test func aSubscriberThatHoldsTheBroadcasterIsReleasedAfterFinish() async {
        final class Owner: @unchecked Sendable {
            let broadcaster = AsyncBroadcaster<Int>()
            var consumer: Task<Void, Never>?
        }
        weak var weakOwner: Owner?
        do {
            let owner = Owner()
            weakOwner = owner
            let stream = owner.broadcaster.subscribe()
            // The consumer captures the owner weakly, as the Host's
            // subscribers do; the stream itself holds nothing back.
            owner.consumer = Task { [weak owner] in
                for await _ in stream {
                    _ = owner
                }
            }
            owner.broadcaster.finish()
            await owner.consumer?.value
        }
        #expect(weakOwner == nil)
    }

    @Test func concurrentProducersAndSubscribersDoNotLoseOrDuplicateValues() async {
        let broadcaster = AsyncBroadcaster<Int>()
        let streams = (0 ..< 8).map { _ in broadcaster.subscribe() }
        let consumers = streams.map { stream in
            Task { await collect(stream) }
        }

        await withTaskGroup(of: Void.self) { group in
            for producer in 0 ..< 4 {
                group.addTask {
                    for index in 0 ..< 250 {
                        broadcaster.yield(producer * 1000 + index)
                    }
                }
            }
            // Subscribing and cancelling at the same time must not disturb
            // the others.
            group.addTask {
                for _ in 0 ..< 100 {
                    let transient = broadcaster.subscribe()
                    let task = Task { for await _ in transient {} }
                    task.cancel()
                }
            }
        }
        broadcaster.finish()

        let expected = Set((0 ..< 4).flatMap { producer in (0 ..< 250).map { producer * 1000 + $0 } })
        for consumer in consumers {
            let values = await consumer.value
            #expect(values.count == 1000)
            #expect(Set(values) == expected)
            // Each producer's own values stay in order.
            for producer in 0 ..< 4 {
                let own = values.filter { $0 / 1000 == producer }
                #expect(own == own.sorted())
            }
        }
    }
}

/// A value shared between a test and the tasks it starts.
final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value

    init(_ value: Value) {
        stored = value
    }

    var value: Value {
        lock.withLock { stored }
    }

    func mutate(_ body: (inout Value) -> Void) {
        lock.withLock { body(&stored) }
    }
}
