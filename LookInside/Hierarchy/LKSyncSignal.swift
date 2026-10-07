//
//  LKSyncSignal.swift
//  LookInside
//
//  The hierarchy data sources' synchronous events. `send` runs every
//  observer before it returns, on the sender's thread, in subscription
//  order. The preview and the async update manager depend on that: they
//  must react to a reload or an item change before the sender goes on,
//  which an `events()` stream, delivering later, cannot give them.
//

/// A synchronous multicast event.
final class LKSyncSignal<Value> {
    private var observers: [(id: Int, handler: (Value) -> Void)] = []
    private var nextObserverID = 0

    /// Runs `handler` on every value sent until the subscription is
    /// cancelled or released.
    func observe(_ handler: @escaping (Value) -> Void) -> LKSyncSubscription {
        let id = nextObserverID
        nextObserverID += 1
        observers.append((id, handler))
        return LKSyncSubscription { [weak self] in
            self?.observers.removeAll { $0.id == id }
        }
    }

    /// Runs the observers subscribed now; one cancelled by an earlier
    /// observer during this send is skipped.
    func send(_ value: Value) {
        let snapshot = observers
        for observer in snapshot where observers.contains(where: { $0.id == observer.id }) {
            observer.handler(value)
        }
    }
}

extension LKSyncSignal where Value == Void {
    func send() {
        send(())
    }
}

/// Ends an `LKSyncSignal` observation when cancelled or released.
final class LKSyncSubscription {
    private var onCancel: (() -> Void)?

    init(_ onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        let onCancel = onCancel
        self.onCancel = nil
        onCancel?()
    }

    deinit {
        cancel()
    }
}

/// Subscriptions that end together when the owner releases the bag.
final class LKSyncSubscriptionBag {
    private var subscriptions: [LKSyncSubscription] = []

    /// Runs `handler` on every value `signal` sends, ignoring the value. A
    /// nil signal is ignored.
    func observe<Value>(_ signal: LKSyncSignal<Value>?, _ handler: @escaping () -> Void) {
        guard let signal else { return }
        subscriptions.append(signal.observe { _ in handler() })
    }
}
