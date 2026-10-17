import Foundation

/// Hands items to a handler on the main queue, in the order they were
/// enqueued, one time slice per main-queue turn.
///
/// Work handed to the main thread in one block keeps the run loop from
/// events, timers and drawing until it ends. The Host reads its channels with
/// dispatch I/O on the main queue, and dispatch I/O calls its read handler on
/// a serial queue that targets the main queue: that queue goes on draining
/// for as long as more data arrives in time, so frames handled inside the
/// read handler hold the main thread for a whole multi-frame response (2.4 s
/// for a 7,000-task prefetch from a Mac app). Items enqueued here are handled
/// for up to `timeBudget`; the rest wait for a later main-queue turn, after
/// the run loop has had its go.
///
/// - Each turn handles at least one item, however long it takes.
/// - An item the handler enqueues waits behind the ones already pending.
/// - Pending items keep the delivery, and what its handler holds, alive.
@MainActor
public final class PacedMainQueueDelivery<Item> {
    private let timeBudget: Duration
    private let handler: @MainActor (Item) -> Void
    private let clock = ContinuousClock()
    /// The pending items are `pendingItems[headIndex...]`; the slots before
    /// `headIndex` were handled and hold nil.
    private var pendingItems: [Item?] = []
    private var headIndex = 0
    private var isTurnScheduled = false

    /// - Parameters:
    ///   - timeBudget: how long one turn goes on handling items; the item
    ///     that runs past it ends the turn.
    ///   - handler: called on the main actor for each item, in order.
    public init(timeBudget: Duration, handler: @escaping @MainActor (Item) -> Void) {
        self.timeBudget = timeBudget
        self.handler = handler
    }

    /// The items not handled yet.
    public var pendingCount: Int {
        pendingItems.count - headIndex
    }

    /// Queues `item` behind the pending ones; it is handled on a later
    /// main-queue turn, never before this returns.
    public func enqueue(_ item: Item) {
        pendingItems.append(item)
        scheduleTurnIfNeeded()
    }

    /// Drops the pending items `shouldRemove` matches. The handler may call
    /// it for the items after its own.
    public func removePending(where shouldRemove: (Item) -> Bool) {
        var keptItems: [Item?] = []
        for case let item? in pendingItems[headIndex...] where !shouldRemove(item) {
            keptItems.append(item)
        }
        pendingItems = keptItems
        headIndex = 0
    }

    private func scheduleTurnIfNeeded() {
        guard !isTurnScheduled, pendingCount > 0 else { return }
        isTurnScheduled = true
        // The main queue runs the blocks it held when its drain began; this
        // block, queued during a turn, runs after the run loop's next pass.
        DispatchQueue.main.async { [self] in
            MainActor.assumeIsolated {
                handleTurn()
            }
        }
    }

    private func handleTurn() {
        let deadline = clock.now.advanced(by: timeBudget)
        while headIndex < pendingItems.count {
            let item = pendingItems[headIndex]
            pendingItems[headIndex] = nil
            headIndex += 1
            if let item {
                handler(item)
            }
            if clock.now >= deadline {
                break
            }
        }
        compactHandledSlots()
        // Still set while the handler ran, so its enqueues did not schedule
        // a second turn.
        isTurnScheduled = false
        scheduleTurnIfNeeded()
    }

    private func compactHandledSlots() {
        if headIndex == pendingItems.count {
            pendingItems.removeAll(keepingCapacity: true)
            headIndex = 0
        } else if headIndex >= 1024, headIndex * 2 >= pendingItems.count {
            pendingItems.removeFirst(headIndex)
            headIndex = 0
        }
    }
}
