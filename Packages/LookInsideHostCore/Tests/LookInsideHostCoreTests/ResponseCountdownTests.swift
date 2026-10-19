import Foundation
@testable import LookInsideHostCore
import Testing

/// What the countdown reported.
@MainActor
private final class CountdownRecorder {
    var isResponseWaiting = false
    var waitingChecksCount = 0
    var expiredCount = 0
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ResponseCountdownTests {
    /// Waits until `condition` holds, polling; false after `timeout`.
    private func waitUntil(timeout: Duration = .seconds(5), _ condition: () -> Bool) async throws -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while !condition() {
            if clock.now >= deadline {
                return false
            }
            try await Task.sleep(for: .milliseconds(5))
        }
        return true
    }

    private func makeCountdown(_ recorder: CountdownRecorder) -> ResponseCountdown {
        ResponseCountdown(
            interval: 0.05,
            isResponseWaiting: {
                recorder.waitingChecksCount += 1
                return recorder.isResponseWaiting
            },
            onExpire: {
                recorder.expiredCount += 1
            }
        )
    }

    @Test func aCountdownExpiresWhenNoResponseWaits() async throws {
        let recorder = CountdownRecorder()
        let countdown = makeCountdown(recorder)
        countdown.restart()
        #expect(try await waitUntil { recorder.expiredCount == 1 })
    }

    /// The bug this type fixes: a reply that arrived in time waited behind
    /// other frames on the Host, and the request timed out meanwhile.
    @Test func aCountdownThatEndsWhileAResponseWaitsStartsOver() async throws {
        let recorder = CountdownRecorder()
        recorder.isResponseWaiting = true
        let countdown = makeCountdown(recorder)
        countdown.restart()
        #expect(try await waitUntil { recorder.waitingChecksCount >= 2 })
        #expect(recorder.expiredCount == 0)

        recorder.isResponseWaiting = false
        #expect(try await waitUntil { recorder.expiredCount == 1 })
    }

    @Test func aStoppedCountdownDoesNotExpire() async throws {
        let recorder = CountdownRecorder()
        let countdown = makeCountdown(recorder)
        countdown.restart()
        countdown.stop()
        try await Task.sleep(for: .milliseconds(200))
        #expect(recorder.expiredCount == 0)
    }
}
