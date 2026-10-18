import Foundation
@testable import LookInsideHostCore
import Testing

/// What the handlers and the other main-queue blocks did, in order.
@MainActor
private final class Recorder {
    var entries: [String] = []
}

/// Lets a handler reach the delivery that calls it.
@MainActor
private final class DeliveryReference {
    var delivery: PacedMainQueueDelivery<Int>?
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PacedMainQueueDeliveryTests {
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

    /// Queues a block on the main queue behind everything queued so far.
    private func enqueueOtherMainQueueWork(_ recorder: Recorder) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                recorder.entries.append("other")
            }
        }
    }

    @Test func handsItemsOverInOrderOnLaterTurns() async throws {
        let recorder = Recorder()
        let delivery = PacedMainQueueDelivery<Int>(timeBudget: .seconds(3600)) { item in
            recorder.entries.append("item \(item)")
        }
        for item in 1 ... 100 {
            delivery.enqueue(item)
        }
        #expect(recorder.entries.isEmpty)
        #expect(delivery.pendingCount == 100)

        try await waitUntil { recorder.entries.count == 100 }
        #expect(recorder.entries == (1 ... 100).map { "item \($0)" })
        #expect(delivery.pendingCount == 0)
    }

    /// The bug this type fixes: a burst handled in one block kept everything
    /// else on the main queue waiting until the last item.
    @Test func otherMainQueueWorkRunsBetweenTurns() async throws {
        let recorder = Recorder()
        // A zero budget ends each turn after one item.
        let delivery = PacedMainQueueDelivery<Int>(timeBudget: .zero) { item in
            recorder.entries.append("item \(item)")
        }
        for item in 1 ... 3 {
            delivery.enqueue(item)
        }
        enqueueOtherMainQueueWork(recorder)

        try await waitUntil { recorder.entries.count == 4 }
        #expect(recorder.entries == ["item 1", "other", "item 2", "item 3"])
    }

    @Test func oneTurnHandlesWhatFitsInTheBudget() async throws {
        let recorder = Recorder()
        let delivery = PacedMainQueueDelivery<Int>(timeBudget: .seconds(3600)) { item in
            recorder.entries.append("item \(item)")
        }
        for item in 1 ... 3 {
            delivery.enqueue(item)
        }
        enqueueOtherMainQueueWork(recorder)

        try await waitUntil { recorder.entries.count == 4 }
        #expect(recorder.entries == ["item 1", "item 2", "item 3", "other"])
    }

    @Test func theItemThatRunsPastTheBudgetEndsTheTurn() async throws {
        let recorder = Recorder()
        let delivery = PacedMainQueueDelivery<Int>(timeBudget: .milliseconds(100)) { item in
            recorder.entries.append("item \(item)")
            if item == 3 {
                Thread.sleep(forTimeInterval: 0.15)
            }
        }
        for item in 1 ... 5 {
            delivery.enqueue(item)
        }
        enqueueOtherMainQueueWork(recorder)

        try await waitUntil { recorder.entries.count == 6 }
        #expect(recorder.entries == ["item 1", "item 2", "item 3", "other", "item 4", "item 5"])
    }

    @Test func itemsTheHandlerEnqueuesWaitBehindPendingOnes() async throws {
        let recorder = Recorder()
        let reference = DeliveryReference()
        let delivery = PacedMainQueueDelivery<Int>(timeBudget: .seconds(3600)) { item in
            recorder.entries.append("item \(item)")
            if item == 1 {
                reference.delivery?.enqueue(99)
            }
        }
        reference.delivery = delivery
        for item in 1 ... 3 {
            delivery.enqueue(item)
        }

        try await waitUntil { recorder.entries.count == 4 }
        #expect(recorder.entries == ["item 1", "item 2", "item 3", "item 99"])
    }

    @Test func removePendingDropsTheMatchingItems() async throws {
        let recorder = Recorder()
        let reference = DeliveryReference()
        let delivery = PacedMainQueueDelivery<Int>(timeBudget: .seconds(3600)) { item in
            recorder.entries.append("item \(item)")
            if item == 2 {
                reference.delivery?.removePending { $0.isMultiple(of: 2) }
            }
        }
        reference.delivery = delivery
        for item in 1 ... 6 {
            delivery.enqueue(item)
        }

        try await waitUntil { delivery.pendingCount == 0 && recorder.entries.count >= 4 }
        // Give a stray turn the chance to hand over a dropped item.
        try await Task.sleep(for: .milliseconds(20))
        #expect(recorder.entries == ["item 1", "item 2", "item 3", "item 5"])
    }

    @Test func aPendingItemCanBeFoundUntilItIsHandedOver() async throws {
        let recorder = Recorder()
        let delivery = PacedMainQueueDelivery<Int>(timeBudget: .seconds(3600)) { item in
            recorder.entries.append("item \(item)")
        }
        delivery.enqueue(1)
        delivery.enqueue(2)
        #expect(delivery.containsPending { $0 == 2 })

        try await waitUntil { recorder.entries.count == 2 }
        #expect(delivery.containsPending { $0 == 2 } == false)
    }

    @Test func pendingItemsKeepTheDeliveryAlive() async throws {
        let recorder = Recorder()
        weak var releasedDelivery: PacedMainQueueDelivery<Int>?
        do {
            let delivery = PacedMainQueueDelivery<Int>(timeBudget: .seconds(3600)) { item in
                recorder.entries.append("item \(item)")
            }
            delivery.enqueue(1)
            releasedDelivery = delivery
        }

        try await waitUntil { recorder.entries.count == 1 }
        #expect(recorder.entries == ["item 1"])
        // Nothing pending: the turn's block was the last owner.
        try await waitUntil { releasedDelivery == nil }
    }
}
