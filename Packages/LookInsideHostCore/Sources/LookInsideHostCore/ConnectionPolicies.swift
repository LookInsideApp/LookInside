import Foundation

/// Counts the frames of one response. The Server can split a response into
/// several frames; each says how many items it carries (`currentDataCount`)
/// and how many the whole response has (`dataTotalCount`, 0 for a response
/// that is never split).
public struct ResponseFrameProgress: Equatable, Sendable {
    /// Items received so far across the frames of this response.
    public private(set) var receivedDataCount = 0

    public init() {}

    /// `true` before the first frame of a split response was counted.
    public var isAtFirstFrame: Bool {
        receivedDataCount == 0
    }

    /// Counts one frame and returns `true` when the response is complete.
    public mutating func record(currentDataCount: Int, dataTotalCount: Int) -> Bool {
        guard dataTotalCount > 0 else {
            return true
        }
        receivedDataCount += currentDataCount
        return receivedDataCount >= dataTotalCount
    }
}

/// Whether the Host can talk to a Server that reported `serverVersion` in
/// its ping response.
public enum ServerVersionCompatibility: Equatable, Sendable {
    case compatible
    /// The Server must be updated.
    case serverTooOld
    /// The Host must be updated.
    case serverTooNew

    /// Version values of old internal LookinServer builds, treated as too old.
    public static let legacyInternalVersions: Set<Int> = [-1, 100]

    public init(serverVersion: Int, supported: ClosedRange<Int>) {
        if Self.legacyInternalVersions.contains(serverVersion) {
            self = .serverTooOld
        } else if serverVersion > supported.upperBound {
            self = .serverTooNew
        } else if serverVersion < supported.lowerBound {
            self = .serverTooOld
        } else {
            self = .compatible
        }
    }
}

/// App infos the Host already holds are reused for this long; the Server
/// then answers with `shouldUseCache` instead of resending icons and
/// screenshots.
public enum AppInfoCachePolicy {
    public static let maximumAge: TimeInterval = 8

    public static func isFresh(cachedTimestamp: TimeInterval, now: TimeInterval) -> Bool {
        now - cachedTimestamp <= maximumAge
    }
}

/// The 220 LicenseChallenge payload: a 32-byte nonce and the Server
/// instance identifier. Other keys are ignored, so a Server may add keys
/// without breaking older Hosts.
public struct LicenseChallenge: Equatable, Sendable {
    public static let nonceLength = 32

    public let nonce: Data
    public let serverInstanceID: String

    /// Why a challenge payload was rejected, with the lengths for the log.
    public struct Malformed: Error, Equatable, Sendable {
        public let nonceLength: Int
        public let serverInstanceIDLength: Int
    }

    /// Reads the challenge from the decoded payload (an `NSDictionary`).
    public static func parse(_ payload: Any?) -> Result<LicenseChallenge, Malformed> {
        let dictionary = payload as? [AnyHashable: Any]
        let nonce = dictionary?["nonce"] as? Data
        let serverInstanceID = dictionary?["server_instance_id"] as? String
        guard let nonce, nonce.count == nonceLength, let serverInstanceID, !serverInstanceID.isEmpty else {
            return .failure(Malformed(
                nonceLength: nonce?.count ?? 0,
                serverInstanceIDLength: serverInstanceID?.utf16.count ?? 0
            ))
        }
        return .success(LicenseChallenge(nonce: nonce, serverInstanceID: serverInstanceID))
    }
}

/// When a license handshake asks the Server for a fresh challenge.
///
/// The Server accepts a 221 only within 120 s of issuing the 220. Getting the
/// signature can take longer: the key use waits behind other uses of the
/// key, then possibly on a login-keychain prompt. Each handshake retries at
/// most once, and the retry itself is an automatic use of the license key
/// that the signing policy must allow.
public enum LicenseHandshakeRetryPolicy {
    /// A signature obtained this long after the 220 arrived (queue time
    /// included, since the challenge ages either way) is not sent.
    public static let slowSigningInterval: TimeInterval = 100

    /// A 221 rejected after the key itself took at least this long (the
    /// key use's own time, without queue time) is retried: the delay most
    /// likely came from a keychain prompt.
    public static let retryAfterRejectedSigningInterval: TimeInterval = 30

    /// `true` when the signature is too old to send and a fresh 220 is
    /// requested instead.
    public static func shouldRequestFreshChallenge(challengeAge: TimeInterval, allowsRetry: Bool) -> Bool {
        allowsRetry && challengeAge >= slowSigningInterval
    }

    /// `true` when a rejected 221 is retried with a fresh 220.
    public static func shouldRetryAfterRejection(keyUseDuration: TimeInterval, allowsRetry: Bool) -> Bool {
        allowsRetry && keyUseDuration >= retryAfterRejectedSigningInterval
    }
}

/// The license handshake state of one channel: whether it is licensed,
/// whether a 220/221 exchange is running, and who waits for it.
///
/// Not thread-safe; the Host keeps it on the main actor.
public final class LicenseHandshakeGate {
    /// What the caller of `admit` does next.
    public enum Admission: Equatable, Sendable {
        /// The completion already ran with this result.
        case settled(verified: Bool)
        /// A handshake is running; the completion runs when it ends.
        case joined
        /// No handshake is running. Ask the signing policy, then call
        /// `markStarted()` and run one, or `finish(verified: false)`.
        case mayStart
    }

    public private(set) var isVerified = false
    public private(set) var isInFlight = false
    private var waiters: [(Bool) -> Void] = []

    public init() {}

    /// Registers `completion` for the channel's handshake.
    ///
    /// - Parameters:
    ///   - force: run a new handshake even when the channel is licensed.
    ///   - isActivated: whether this Mac's license is active; without it the
    ///     completion runs at once with `false`.
    public func admit(force: Bool, isActivated: Bool, completion: ((Bool) -> Void)?) -> Admission {
        if isVerified, !force {
            completion?(true)
            return .settled(verified: true)
        }
        if !isActivated {
            completion?(false)
            return .settled(verified: false)
        }
        if let completion {
            waiters.append(completion)
        }
        return isInFlight ? .joined : .mayStart
    }

    public func markStarted() {
        isInFlight = true
    }

    /// Ends the running handshake and runs every waiting completion once.
    /// A failed handshake leaves an earlier success in place.
    public func finish(verified: Bool) {
        isInFlight = false
        if verified {
            isVerified = true
        }
        let completions = waiters
        waiters = []
        for completion in completions {
            completion(verified)
        }
    }

    /// The license is no longer active: the next request needs a new
    /// handshake.
    public func revokeVerification() {
        isVerified = false
    }
}
