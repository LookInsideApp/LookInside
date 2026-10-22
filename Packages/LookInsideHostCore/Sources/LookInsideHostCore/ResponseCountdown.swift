import Foundation

/// How long a request waits for its next response frame before it times
/// out, counted on the main run loop in the default mode only
/// (`-performSelector:withObject:afterDelay:`, as the Objective-C request
/// class did).
///
/// The Host hands the frames it reads to the connection layer a time slice
/// per main-queue turn (`PacedMainQueueDelivery`), so a response can arrive in
/// time and still wait behind other frames when the countdown ends. Then the
/// countdown starts over instead of expiring: the inspected app answered,
/// only the Host has not caught up yet.
@MainActor
public final class ResponseCountdown: NSObject {
    private let interval: TimeInterval
    private let isResponseWaiting: @MainActor () -> Bool
    private let onExpire: @MainActor () -> Void

    /// - Parameters:
    ///   - interval: must be positive.
    ///   - isResponseWaiting: whether a response the request is waiting
    ///     for has been read but not handed over yet; asked when the
    ///     countdown ends.
    ///   - onExpire: the request timed out.
    public init(
        interval: TimeInterval,
        isResponseWaiting: @escaping @MainActor () -> Bool,
        onExpire: @escaping @MainActor () -> Void
    ) {
        self.interval = interval
        self.isResponseWaiting = isResponseWaiting
        self.onExpire = onExpire
    }

    /// Starts the countdown, or starts it over.
    public func restart() {
        stop()
        guard interval > 0 else {
            assertionFailure("the countdown interval is 0")
            return
        }
        perform(#selector(handleEnd), with: nil, afterDelay: interval)
    }

    public func stop() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }

    @objc private func handleEnd() {
        if isResponseWaiting() {
            restart()
            return
        }
        onExpire()
    }
}
