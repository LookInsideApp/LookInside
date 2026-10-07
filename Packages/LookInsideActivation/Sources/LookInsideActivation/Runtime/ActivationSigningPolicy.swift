import Foundation

/// Who wants to use the license key.
public enum ActivationSigningSource: Sendable, Equatable {
    /// The 220/221 license handshake with a connected Server.
    case licenseHandshake
    /// The background certificate renewal.
    case silentRenewal
    /// A direct user action: Try Again in the license window, Activate or
    /// Start Trial. Continue in the keychain explainer does not use the key
    /// itself; it lets the held-back automatic use run as the user's.
    case userAction

    /// `true` for the sources LookInside starts on its own.
    var isAutomatic: Bool {
        self != .userAction
    }
}

/// How one use of the license key ended.
enum ActivationSigningOutcome: Sendable, Equatable {
    /// The key signed. `duration` is how long the keychain took.
    case succeeded(duration: TimeInterval)
    /// The user cancelled or denied the keychain prompt, or the password was
    /// wrong.
    case denied
    /// The keychain is locked and may not ask (`errSecInteractionNotAllowed`).
    case interactionNotAllowed
    /// Any other failure. It does not change when the key may be used.
    case failed

    init(error: any Error) {
        guard case let .keychainAccessDenied(status) = error as? ActivationError else {
            self = .failed
            return
        }
        self = status == ActivationError.interactionNotAllowedStatus ? .interactionNotAllowed : .denied
    }
}

/// What the policy says about one automatic use of the license key.
enum ActivationSigningDecision: Sendable, Equatable {
    /// The key may be used now.
    case allowed
    /// Not now: no window yet, the launch delay, a wait after a denial or a
    /// locked keychain, or the quiet period after a slow signing.
    case deferred
    /// Everything else allows it, but the user has not yet seen the keychain
    /// explainer for a key LookInside did not create.
    case needsExplainer
}

/// Whether the Host must explain the coming keychain prompt first.
enum KeychainAccessExplainerState: Sendable, Equatable {
    /// The key signs without a prompt, the Host created it, or the Host does
    /// not know of a key it did not create.
    case notNeeded
    /// The key was created by the 2.3.x helper and has not signed without a
    /// prompt yet: automatic uses wait until the user confirms the explainer.
    case awaitingConfirmation
    /// The user chose Continue, in this launch or an earlier one for the
    /// same key, or answered a prompt from a user action in this launch.
    case confirmed
}

/// Decides when LookInside may use the license key without the user asking
/// for it. Using the key can raise a login-keychain prompt, so every
/// automatic path (license handshakes, silent renewal) asks this policy
/// first; only direct user actions sign regardless.
///
/// Rules:
/// - Nothing signs automatically before the Host has shown its first
///   window. Silent renewal also waits `launchDelay` after launch.
/// - A key LookInside did not create (an upgrade from the 2.3.x helper)
///   prompts until the user picks Always Allow. Until such a key has signed
///   without a prompt, the first automatic use waits for the keychain
///   explainer, at most once per key (`KeychainAccessMarkers`). Continue
///   confirms it and makes the next automatic use the user's own: that use
///   raises the one system prompt, and its answer counts like a user
///   action's. Not Now counts as a denial without a system prompt; the
///   explainer comes back when the wait ends.
/// - A denied prompt stops all automatic signing for an hour, and for a day
///   after each further denial. The user can clear the wait with Try Again.
///   When the wait ends, channels whose handshake failed on the denial may
///   handshake again.
/// - A locked keychain that may not ask is not a denial: automatic signing
///   pauses for `interactionNotAllowedDelay` and nothing escalates.
/// - A success clears the denial count only when the user asked for it, or
///   when it finished within `promptThreshold`: then the keychain did not
///   stop to ask, so the key no longer prompts. A slow automatic success was
///   a one-time Allow, and the next denial still escalates.
/// - After a slow automatic success, silent renewal does not sign for
///   `slowSigningQuietPeriod` unless the lease ends within a day, and the
///   license window suggests Always Allow until a signing is fast again:
///   only Always Allow ends the prompt for each newly connected app.
/// - A handshake that failed on a channel (rejected 221, failed signing) is
///   not repeated on that channel until it reconnects, the activation state
///   changes, or (for a denial) the denial wait ends.
///
/// The type is a value with no clock or I/O; `ActivationRuntime` owns the
/// app-wide instance through `ActivationSigningGate`. It lives in memory
/// only: the denial count and wait (1 h, then 24 h) hold within one launch,
/// and a relaunch starts again from the first-window, explainer and
/// first-use rules. Only the markers about the key persist.
struct ActivationSigningPolicy: Sendable, Equatable {
    static let denialBackoff: [TimeInterval] = [60 * 60, 24 * 60 * 60]
    static let interactionNotAllowedDelay: TimeInterval = 5 * 60
    static let launchDelay: TimeInterval = 30
    /// A signing at least this slow waited on a keychain prompt.
    static let promptThreshold: TimeInterval = 1
    /// Silent renewal's pause after a slow automatic signing.
    static let slowSigningQuietPeriod: TimeInterval = 6 * 60 * 60

    let launchedAt: Date
    private(set) var hasShownFirstWindow = false
    private(set) var denialCount = 0
    private(set) var deniedUntil: Date?
    private(set) var pausedUntil: Date?
    private(set) var failedHandshakeChannels: Set<String> = []
    /// Channels in `failedHandshakeChannels` because their signing was denied.
    private(set) var deniedHandshakeChannels: Set<String> = []
    private(set) var lastSlowAutomaticSigningAt: Date?
    private(set) var explainer = KeychainAccessExplainerState.notNeeded
    /// `true` while an automatic use waits for the Host to show the explainer.
    private(set) var isExplainerRequested = false
    /// `true` once the key signed without a prompt or the Host created it.
    private(set) var keySignsWithoutPrompt = false
    /// `true` after Continue until an automatic use answers the system
    /// prompt: that use counts as the user's.
    private(set) var isContinuedUsePending = false
    /// `true` while the denial wait came from Not Now in the explainer, so
    /// no system prompt was shown or refused.
    private(set) var isDenialFromExplainer = false
    /// `true` after a slow automatic success (a one-time Allow) until a
    /// fast signing or a denial.
    private(set) var isKeyAllowedOnce = false

    init(launchedAt: Date) {
        self.launchedAt = launchedAt
    }

    // MARK: Decisions

    /// What the policy says about a use from `source` at `date`.
    /// `renewalIsUrgent` is `true` when the lease ends within a day, which
    /// lifts silent renewal's quiet period after a slow signing.
    func decision(
        for source: ActivationSigningSource,
        at date: Date,
        renewalIsUrgent: Bool = false
    ) -> ActivationSigningDecision {
        switch source {
        case .userAction:
            return .allowed
        case .licenseHandshake:
            guard hasShownFirstWindow, isWaiting(at: date) == false else { return .deferred }
        case .silentRenewal:
            guard hasShownFirstWindow,
                  date >= launchedAt.addingTimeInterval(Self.launchDelay),
                  isWaiting(at: date) == false
            else { return .deferred }
            if renewalIsUrgent == false, let lastSlowAutomaticSigningAt,
               date < lastSlowAutomaticSigningAt.addingTimeInterval(Self.slowSigningQuietPeriod)
            {
                return .deferred
            }
        }
        return explainer == .awaitingConfirmation ? .needsExplainer : .allowed
    }

    /// `true` when `source` may use the key at `date`.
    func allowsSigning(
        for source: ActivationSigningSource,
        at date: Date,
        renewalIsUrgent: Bool = false
    ) -> Bool {
        decision(for: source, at: date, renewalIsUrgent: renewalIsUrgent) == .allowed
    }

    /// What the policy says about a license handshake on `channel` at `date`.
    func handshakeDecision(onChannel channel: String?, at date: Date) -> ActivationSigningDecision {
        if let channel, failedHandshakeChannels.contains(channel) {
            return .deferred
        }
        return decision(for: .licenseHandshake, at: date)
    }

    /// `true` when a license handshake may start on `channel` at `date`.
    func allowsHandshake(onChannel channel: String?, at date: Date) -> Bool {
        handshakeDecision(onChannel: channel, at: date) == .allowed
    }

    /// `true` while automatic signing waits after a denied prompt.
    func isKeychainAccessDenied(at date: Date) -> Bool {
        guard let deniedUntil else { return false }
        return date < deniedUntil
    }

    private func isWaiting(at date: Date) -> Bool {
        if isKeychainAccessDenied(at: date) {
            return true
        }
        if let pausedUntil, date < pausedUntil {
            return true
        }
        return false
    }

    // MARK: Events

    mutating func noteFirstWindowShown() {
        hasShownFirstWindow = true
    }

    /// Records how a use of the key from `source` ended. `channel` is the
    /// handshake's channel, if any.
    mutating func record(
        _ outcome: ActivationSigningOutcome,
        from source: ActivationSigningSource,
        channel: String? = nil,
        at date: Date
    ) {
        switch outcome {
        case let .succeeded(duration):
            pausedUntil = nil
            let signedWithoutPrompt = duration < Self.promptThreshold
            let answeredByUser = source == .userAction || takeContinuedUse(from: source)
            if answeredByUser || signedWithoutPrompt {
                denialCount = 0
                deniedUntil = nil
                isDenialFromExplainer = false
            }
            if signedWithoutPrompt {
                noteKeySignsWithoutPrompt()
            } else if source.isAutomatic {
                lastSlowAutomaticSigningAt = date
                isKeyAllowedOnce = true
            }
            if answeredByUser {
                // The user answered the prompt themselves.
                if explainer == .awaitingConfirmation {
                    explainer = .confirmed
                    isExplainerRequested = false
                }
                failedHandshakeChannels.removeAll()
                deniedHandshakeChannels.removeAll()
            }
        case .denied:
            _ = takeContinuedUse(from: source)
            applyDenial(at: date)
            noteHandshakeFailed(onChannel: channel)
            if let channel {
                deniedHandshakeChannels.insert(channel)
            }
        case .interactionNotAllowed:
            pausedUntil = date.addingTimeInterval(Self.interactionNotAllowedDelay)
        case .failed:
            noteHandshakeFailed(onChannel: channel)
        }
    }

    private mutating func applyDenial(at date: Date, fromExplainer: Bool = false) {
        denialCount += 1
        let backoff = Self.denialBackoff
        deniedUntil = date.addingTimeInterval(backoff[min(denialCount, backoff.count) - 1])
        pausedUntil = nil
        isDenialFromExplainer = fromExplainer
        isKeyAllowedOnce = false
    }

    /// `true`, once, for the first automatic use after Continue that answered
    /// the system prompt.
    private mutating func takeContinuedUse(from source: ActivationSigningSource) -> Bool {
        guard source.isAutomatic, isContinuedUsePending else { return false }
        isContinuedUsePending = false
        return true
    }

    /// Remembers that the handshake on `channel` failed, so it is not
    /// repeated there.
    mutating func noteHandshakeFailed(onChannel channel: String?) {
        guard let channel else { return }
        failedHandshakeChannels.insert(channel)
    }

    mutating func noteChannelEnded(_ channel: String) {
        failedHandshakeChannels.remove(channel)
        deniedHandshakeChannels.remove(channel)
    }

    /// The license was activated, renewed, replaced or lost: every channel
    /// may try again.
    mutating func noteActivationChanged() {
        failedHandshakeChannels.removeAll()
        deniedHandshakeChannels.removeAll()
    }

    /// Ends the denial wait once `date` reached it: the channels whose
    /// signing was denied may handshake again. The denial count stays, so
    /// the next denial still escalates.
    mutating func noteDenialWaitEnded(at date: Date) {
        guard let deniedUntil, date >= deniedUntil else { return }
        self.deniedUntil = nil
        isDenialFromExplainer = false
        failedHandshakeChannels.subtract(deniedHandshakeChannels)
        deniedHandshakeChannels.removeAll()
    }

    // MARK: Keychain explainer

    /// The key was created by the 2.3.x helper, has not been seen to sign
    /// without a prompt and its explainer was never confirmed: automatic uses
    /// wait for the explainer.
    mutating func noteExplainerNeeded() {
        guard keySignsWithoutPrompt == false, explainer == .notNeeded else { return }
        explainer = .awaitingConfirmation
    }

    /// The Host created the key, or the key signed without a prompt: its
    /// access list already lists the Host, so no explainer is needed again.
    mutating func noteKeySignsWithoutPrompt() {
        keySignsWithoutPrompt = true
        explainer = .notNeeded
        isExplainerRequested = false
        isContinuedUsePending = false
        isKeyAllowedOnce = false
    }

    /// An automatic use found the explainer missing: the Host should show it.
    mutating func requestExplainer() {
        guard explainer == .awaitingConfirmation else { return }
        isExplainerRequested = true
    }

    /// Continue: automatic uses may sign, and the next one that reaches the
    /// keychain counts as the user's (it raises the prompt Continue
    /// announced). Continue itself does not use the key, so it costs no
    /// extra prompt.
    mutating func confirmExplainer() {
        isExplainerRequested = false
        guard explainer == .awaitingConfirmation else { return }
        explainer = .confirmed
        isContinuedUsePending = true
    }

    /// Not Now: counts as a denied prompt, without a system prompt.
    mutating func declineExplainer(at date: Date) {
        isExplainerRequested = false
        guard explainer == .awaitingConfirmation else { return }
        applyDenial(at: date, fromExplainer: true)
    }
}

/// What the license window and the Host show about the license key.
public struct ActivationSigningStatus: Sendable, Equatable {
    /// Automatic signing waits after a denied keychain prompt until this
    /// date. `nil` when it does not wait for a denial.
    public let keychainAccessDeniedUntil: Date?
    /// `true` once the Host showed its first window.
    public let hasShownFirstWindow: Bool
    /// Changes every time handshakes that failed or were held back may be
    /// tried again.
    public let handshakeGeneration: Int
    /// `true` while an automatic use of a key LookInside did not create waits
    /// for the keychain explainer. The Host shows it, then calls
    /// `ActivationRuntime.confirmKeychainAccessExplainer()` or
    /// `declineKeychainAccessExplainer()`.
    public let needsKeychainAccessExplainer: Bool
    /// `true` while the denial wait came from Not Now in the explainer: no
    /// system prompt was shown, the user only postponed the key's use.
    public let isKeychainAccessPostponed: Bool
    /// `true` after an automatic signing waited on a prompt and succeeded (a
    /// one-time Allow): each newly connected app will ask again until the
    /// user picks Always Allow.
    public let isKeychainAccessAllowedOnce: Bool

    public func isKeychainAccessDenied(at date: Date = Date()) -> Bool {
        guard let keychainAccessDeniedUntil else { return false }
        return date < keychainAccessDeniedUntil
    }
}
