import Foundation

/// Silently re-issues the intermediate certificate before its server-side
/// 30-day check-in deadline (12-hour for trials). The renewer is best-effort:
/// callers fire-and-forget `tryRenewIfDue()`, so failures are recorded in the
/// background. Each attempt's outcome is persisted via
/// `ActivationStateStore.recordRenewAttempt(...)` so the access evaluator can
/// surface a "please connect to the internet" warning when a run of failures
/// is about to take access offline.
///
/// Signing the CSR uses the license key, which can raise a keychain prompt,
/// so whether renewal is due and when it may try again are kept apart:
/// - Due: the lease's `renewAfter` has passed and less than 7 days (12 hours
///   for a trial) remain.
/// - Retry: after a failed attempt the next one waits `failureBackoff`
///   (5 min, 15 min, 1 h, 6 h, then 12 h). A success resets it. In the
///   lease's last `urgentWindow` (24 h) the wait is at most
///   `urgentMaximumBackoff` (1 h).
/// - One attempt signs at most one CSR. The CSR is kept in memory and reused
///   by later attempts while the key is unchanged (same public-key hash), and
///   dropped after a success. The service checks only the CSR's own
///   signature and binds the certificate to its public key, so a retry with
///   the same CSR is accepted. A permanent rejection (a 4xx, including the
///   service's validation errors, other than 408 and 429) also drops it, so
///   the next attempt signs a fresh CSR; a transport error or a 5xx keeps it.
/// - An attempt that has to sign asks the signing policy (`.silentRenewal`)
///   first; see `ActivationSigningPolicy` for the launch, denial, explainer
///   and slow-signing rules. An attempt the policy holds back is not a
///   failure and does not move the backoff.
/// - A failure persisted by an earlier launch counts as the first failure,
///   so relaunching does not skip the wait.
actor ActivationCertificateRenewer {
    typealias CSRProvider = @Sendable () async throws -> String
    typealias SessionRefresher = @Sendable () async throws -> Void
    typealias ClientFactory = @Sendable () -> any IntermediateCertificateIssuing
    /// Identifies the stored key without using it, or `nil` when unknown. A
    /// cached CSR is reused only while this value is the same and not `nil`.
    typealias KeyIdentityProvider = @Sendable () throws -> Data?

    static let failureBackoff: [TimeInterval] = [5 * 60, 15 * 60, 60 * 60, 6 * 60 * 60, 12 * 60 * 60]
    static let urgentWindow: TimeInterval = 24 * 60 * 60
    static let urgentMaximumBackoff: TimeInterval = 60 * 60

    private let stateStore: ActivationStateStore
    private let clientFactory: ClientFactory
    private let csrProvider: CSRProvider
    private let keyIdentity: KeyIdentityProvider
    private let sessionRefresher: SessionRefresher
    private let now: @Sendable () -> Date
    private let signingGate: ActivationSigningGate
    private var consecutiveFailures = 0
    private var lastFailedAt: Date?
    private var hasReadPersistedFailure = false
    private var cachedCSR: (keyIdentity: Data, pem: String)?
    private var inFlight = false

    init(
        stateStore: ActivationStateStore,
        clientFactory: @escaping ClientFactory = { LookInsideAuthenticatorAPIClient() },
        csrProvider: @escaping CSRProvider,
        keyIdentity: @escaping KeyIdentityProvider = { nil },
        sessionRefresher: @escaping SessionRefresher,
        now: @escaping @Sendable () -> Date = { Date() },
        signingGate: ActivationSigningGate = .open()
    ) {
        self.stateStore = stateStore
        self.clientFactory = clientFactory
        self.csrProvider = csrProvider
        self.keyIdentity = keyIdentity
        self.sessionRefresher = sessionRefresher
        self.now = now
        self.signingGate = signingGate
    }

    /// The wait after `failures` failed attempts in a row.
    static func retryDelay(afterFailures failures: Int, isUrgent: Bool) -> TimeInterval {
        guard failures > 0 else { return 0 }
        let delay = failureBackoff[min(failures, failureBackoff.count) - 1]
        return isUrgent ? min(delay, urgentMaximumBackoff) : delay
    }

    func tryRenewIfDue() async {
        let snapshot = await stateStore.snapshot()
        let nowDate = now()

        guard let status = snapshot.entitlementStatus,
              let lease = status.currentLease,
              snapshot.activationSession != nil
        else { return }

        guard lease.renewAfter <= nowDate else { return }

        let threshold: TimeInterval =
            (status.license.licenseClass == .trial)
                ? 12 * 60 * 60
                : 7 * 24 * 60 * 60
        guard lease.expiresAt.timeIntervalSince(nowDate) < threshold else { return }

        readPersistedFailureOnce(snapshot)
        let isUrgent = lease.expiresAt.timeIntervalSince(nowDate) < Self.urgentWindow
        if let lastFailedAt {
            let delay = Self.retryDelay(afterFailures: consecutiveFailures, isUrgent: isUrgent)
            guard nowDate >= lastFailedAt.addingTimeInterval(delay) else { return }
        }
        if inFlight {
            return
        }

        let reusableCSR = reusableCachedCSR()
        // A new CSR signs with the license key: wait while the signing
        // policy holds it back.
        if reusableCSR == nil, signingGate.admits(.silentRenewal, renewalIsUrgent: isUrgent) == false {
            return
        }

        inFlight = true
        defer { inFlight = false }

        do {
            try await sessionRefresher()

            let refreshedSnapshot = await stateStore.snapshot()
            guard let session = refreshedSnapshot.activationSession else {
                throw ActivationError.stateStoreFailure("activation session missing after refresh")
            }

            let csr: String
            if let reusableCSR {
                csr = reusableCSR
            } else {
                csr = try await signNewCSR(isUrgent: isUrgent)
            }
            let client = clientFactory()
            let renewedLease = try await client.issueIntermediateCertificate(
                IntermediateCertificateIssueRequest(
                    activationSessionToken: session.token,
                    deviceIdentifier: session.deviceIdentifier,
                    certificateSigningRequestPEM: csr
                )
            )
            cachedCSR = nil
            consecutiveFailures = 0
            lastFailedAt = nil
            try await stateStore.recordIssuedLease(renewedLease)
            try await stateStore.recordRenewAttempt(success: true, error: nil, at: nowDate)
            ActivationLogger.rpc.info(
                "certificate renewer: success cert_id=\(renewedLease.certificateID, privacy: .public)"
            )
        } catch ActivationError.signingDeferred {
            // The signing policy held the key back in its turn; nothing was
            // attempted.
        } catch {
            if Self.rejectsCSRPermanently(error) {
                cachedCSR = nil
            }
            consecutiveFailures += 1
            lastFailedAt = nowDate
            try? await stateStore.recordRenewAttempt(
                success: false,
                error: String(describing: error),
                at: nowDate
            )
            ActivationLogger.rpc.error(
                "certificate renewer: failed error=\(String(describing: error), privacy: .public)"
            )
        }
    }

    /// `true` when the service rejected the request for good, so resending
    /// the same CSR cannot succeed: a 4xx, which includes its validation
    /// errors, other than 408 (timeout) and 429 (rate limited). Transport
    /// errors and 5xx are worth a retry with the same CSR.
    static func rejectsCSRPermanently(_ error: any Error) -> Bool {
        guard case let LookInsideAuthenticatorAPIClientError.api(statusCode, _, _) = error else {
            return false
        }
        return (400 ..< 500).contains(statusCode) && statusCode != 408 && statusCode != 429
    }

    /// Signs a CSR through the signing gate and keeps it for retries.
    private func signNewCSR(isUrgent: Bool) async throws -> String {
        let csrProvider = csrProvider
        let csr = try await signingGate.perform(.silentRenewal, renewalIsUrgent: isUrgent) {
            try await csrProvider()
        }
        if let identity = try? keyIdentity() {
            cachedCSR = (identity, csr)
        } else {
            cachedCSR = nil
        }
        return csr
    }

    /// The cached CSR when the stored key is still the one that signed it.
    private func reusableCachedCSR() -> String? {
        guard let cachedCSR else { return nil }
        guard let identity = try? keyIdentity(), identity == cachedCSR.keyIdentity else {
            self.cachedCSR = nil
            return nil
        }
        return cachedCSR.pem
    }

    private func readPersistedFailureOnce(_ snapshot: ActivationPersistedState) {
        guard hasReadPersistedFailure == false else { return }
        hasReadPersistedFailure = true
        guard lastFailedAt == nil, let failedAt = snapshot.lastRenewFailedAt else { return }
        if let succeededAt = snapshot.lastRenewSucceededAt, succeededAt >= failedAt {
            return
        }
        consecutiveFailures = 1
        lastFailedAt = failedAt
    }
}
