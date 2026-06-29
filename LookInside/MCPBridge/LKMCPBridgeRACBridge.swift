// LKMCPBridgeRACBridge.swift
//
// Bridge between the host's ReactiveObjC `RACSignal *` based RPC APIs and
// modern Swift structured concurrency. The MCPBridge inspection routes
// today only read cached state on the main actor, but routes that need
// to round-trip to the inspected target over Peertalk (invocation,
// attribute mutation, screenshot fetch) consume RACSignals returned by
// `LKInspectableApp` / `LKConnectionManager`. This file is the one place
// that knows how to await a single-value signal as an `async throws`
// call.
//
// Semantics:
//   - Awaits the FIRST `next` value emitted by the signal, then disposes.
//     LookInside's RPC signals all follow the "emit once, then complete"
//     convention, so first-value semantics match the signal's own.
//   - Forwards `error` events to the `async throws` channel.
//   - Coalesces "completed without emitting" into a structured
//     `RACBridgeError.completedWithoutValue`.
//   - Cooperatively cancels the signal subscription when the awaiting
//     Task is cancelled. (Cancellation does NOT propagate back to the
//     Peertalk request itself — that requires explicit push-304-cancel
//     plumbing on the server side; see invoke.* error mapping for the
//     timeout path.)

import Foundation

// MARK: - Errors

/// Errors surfaced by the RAC → async bridge itself, distinct from any
/// errors the source RACSignal may emit. Bridge methods that want to
/// translate these into structured wire error codes can switch on the
/// case.
enum RACBridgeError: Error, LocalizedError {
    /// The source signal completed without ever emitting a `next`
    /// value. LookInside RPC signals do not normally do this — the
    /// only known path is a deliberate cancellation race.
    case completedWithoutValue
    /// The awaiting Task was cancelled before the signal produced a
    /// value or an error.
    case cancelled

    var errorDescription: String? {
        switch self {
        case .completedWithoutValue:
            return "The source signal completed without producing a value."
        case .cancelled:
            return "The await on the source signal was cancelled."
        }
    }
}

// MARK: - Awaiters

enum LKMCPBridgeRACBridge {

    /// Awaits the first `next` value of an `RACSignal`, cast to the
    /// expected type. Throws when the signal emits an `error`, completes
    /// before producing a value, or returns a value that does not bridge
    /// to the requested type.
    ///
    /// The signal's subscription is torn down as soon as a value, error,
    /// or completion is observed; the caller's Task does not retain the
    /// disposable beyond the await.
    static func awaitFirstValue<Value>(
        of signal: RACSignal<AnyObject>,
        as type: Value.Type = Value.self
    ) async throws -> Value {
        // Continuations resume exactly once; the state box guards
        // against the "next then completed" race where ReactiveObjC
        // synchronously completes after emitting a value.
        let stateBox = RACContinuationState()

        return try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    let disposable: RACDisposable? = signal.subscribeNext({ value in
                        guard stateBox.markResolved() else { return }
                        if let typed = value as? Value {
                            continuation.resume(returning: typed)
                        } else {
                            continuation.resume(throwing: RACBridgeError.completedWithoutValue)
                        }
                    }, error: { error in
                        guard stateBox.markResolved() else { return }
                        continuation.resume(throwing: error ?? RACBridgeError.completedWithoutValue)
                    }, completed: {
                        guard stateBox.markResolved() else { return }
                        continuation.resume(throwing: RACBridgeError.completedWithoutValue)
                    })
                    stateBox.disposable = disposable
                    if stateBox.isCancelled {
                        // Cancellation arrived before subscribeNext returned;
                        // dispose immediately and fail the continuation.
                        disposable?.dispose()
                        if stateBox.markResolved() {
                            continuation.resume(throwing: RACBridgeError.cancelled)
                        }
                    }
                }
            },
            onCancel: {
                stateBox.cancel()
            }
        )
    }
}

// MARK: - Private state box

/// Thread-safe one-shot guard around the RACSignal → continuation hand-off.
/// Tracks both "did I resume the continuation yet?" and "did the Task get
/// cancelled?". `NSLock` is sufficient — there's no contention on the hot
/// path, just a few callbacks per await.
private final class RACContinuationState: @unchecked Sendable {
    private let lock = NSLock()
    private var resolved = false
    private var cancelled = false
    var disposable: RACDisposable?

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    /// Atomically claims the right to resume the continuation. Returns
    /// `true` the first time it's called, `false` on every subsequent
    /// call so duplicate signal events become no-ops.
    func markResolved() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if resolved { return false }
        resolved = true
        return true
    }

    /// Marks cancellation and disposes the active subscription. Safe to
    /// call from any thread; the dispose happens outside the lock to
    /// avoid reentrancy into ReactiveObjC internals.
    func cancel() {
        lock.lock()
        cancelled = true
        let pendingDisposable = disposable
        disposable = nil
        lock.unlock()
        pendingDisposable?.dispose()
    }
}
