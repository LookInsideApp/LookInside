import Foundation

/// Window-independent inspection access. All model graphs stay on the main actor.
@MainActor
public protocol InspectionSessionAccess: AnyObject {
    var sessionIdentifier: String { get }
    var connectionGeneration: UInt64 { get }
    var hierarchyRevision: UInt64 { get }

    func readHierarchy() throws -> LookinHierarchyInfo
    func refreshHierarchy() async throws -> LookinHierarchyInfo
    func fetchDetails(packages: [LookinStaticAsyncUpdateTasksPackage]) async throws -> [LookinDisplayItemDetail]
}

extension InspectionSession: InspectionSessionAccess {
    public func refreshHierarchy() async throws -> LookinHierarchyInfo {
        let hierarchies = try await InspectionSignalAwaiter.allValues(
            of: refreshHierarchy(initiator: "client"), as: LookinHierarchyInfo.self
        )
        guard hierarchies.count == 1, let hierarchy = hierarchies.first else {
            throw InspectionSignalError.invalidResponse
        }
        return hierarchy
    }

    public func fetchDetails(packages: [LookinStaticAsyncUpdateTasksPackage]) async throws -> [LookinDisplayItemDetail] {
        let batches = try await InspectionSignalAwaiter.allValues(
            of: detailResponses(packages: packages), as: [LookinDisplayItemDetail].self
        )
        return batches.flatMap { $0 }
    }
}

public enum InspectionSignalError: Error {
    case invalidResponse
}

/// Adapts complete request streams without changing the session's drain policy.
@MainActor
public enum InspectionSignalAwaiter {
    public static func allValues<Element>(
        of signal: RACSignal<AnyObject>, as _: Element.Type = Element.self
    ) async throws -> [Element] {
        let pending = InspectionSignalContinuation<[Element]>()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                guard pending.install(continuation) else { return }
                var values: [Element] = []
                let subscription = signal.subscribeNext { value in
                    dispatchPrecondition(condition: .onQueue(.main))
                    guard let element = value as? Element else {
                        pending.finish(.failure(InspectionSignalError.invalidResponse))
                        return
                    }
                    values.append(element)
                } error: { error in
                    pending.finish(.failure(error ?? InspectionSignalError.invalidResponse))
                } completed: {
                    pending.finish(.success(values))
                }
                pending.install(subscription)
            }
        } onCancel: {
            pending.cancel()
        }
    }
}

/// The lock protects continuation ownership and subscription installation against
/// cancellation on any executor. Model collection itself remains main-actor-only.
private final class InspectionSignalContinuation<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Error>?
    private var subscription: RACDisposable?
    private var resolved = false

    func install(_ continuation: CheckedContinuation<Value, Error>) -> Bool {
        lock.lock()
        if resolved {
            lock.unlock()
            continuation.resume(throwing: CancellationError())
            return false
        }
        self.continuation = continuation
        lock.unlock()
        return true
    }

    func install(_ subscription: RACDisposable?) {
        lock.lock()
        let alreadyResolved = resolved
        if !alreadyResolved {
            self.subscription = subscription
        }
        lock.unlock()
        if alreadyResolved {
            subscription?.dispose()
        }
    }

    func finish(_ result: Result<Value, Error>) {
        lock.lock()
        guard !resolved else {
            lock.unlock()
            return
        }
        resolved = true
        let waitingContinuation = continuation
        let activeSubscription = subscription
        continuation = nil
        subscription = nil
        lock.unlock()
        activeSubscription?.dispose()
        waitingContinuation?.resume(with: result)
    }

    func cancel() {
        finish(.failure(CancellationError()))
    }
}
