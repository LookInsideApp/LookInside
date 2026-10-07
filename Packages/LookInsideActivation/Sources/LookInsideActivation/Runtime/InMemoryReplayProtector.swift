import Foundation

final class InMemoryReplayProtector: ReplayProtecting, @unchecked Sendable {
    private let lock = NSLock()
    private var expirations: [String: Date] = [:]

    func reserve(_ nonce: String, until expiresAt: Date) throws {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        expirations = expirations.filter { $0.value > now }
        guard expirations[nonce] == nil else {
            throw AuthenticatorError.replayDetected
        }
        expirations[nonce] = expiresAt
    }
}
