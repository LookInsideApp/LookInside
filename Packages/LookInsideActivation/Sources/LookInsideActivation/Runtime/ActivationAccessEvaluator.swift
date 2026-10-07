import Foundation

typealias ActivationEvaluatorClient = ActivationSessionRefreshing & EntitlementStatusFetching

final class ActivationAccessEvaluator: @unchecked Sendable {
    private let stateStore: ActivationStateStore
    private let apiClientFactory: @Sendable () -> any ActivationEvaluatorClient
    private let now: @Sendable () -> Date

    init(
        stateStore: ActivationStateStore,
        apiClientFactory: @escaping @Sendable () -> any ActivationEvaluatorClient = {
            LookInsideAuthenticatorAPIClient()
        },
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.stateStore = stateStore
        self.apiClientFactory = apiClientFactory
        self.now = now
    }

    func currentDecision() async -> ActivationAccessDecision {
        let state = await stateStore.snapshot()
        return ActivationAccessEvaluator.decision(from: state, evaluatedAt: now())
    }

    func refreshedDecision() async throws -> ActivationAccessDecision {
        let state = await stateStore.snapshot()
        guard let session = state.activationSession,
              let fingerprint = state.deviceFingerprint
        else {
            return await currentDecision()
        }

        let refreshedSession = try await ensureSessionFresh() ?? session

        let client = apiClientFactory()
        let status = try await client.fetchEntitlementStatus(
            EntitlementStatusRequest(
                licenseID: refreshedSession.licenseID,
                deviceID: fingerprint.deviceID,
                forceRefresh: true,
                activationSessionToken: refreshedSession.token
            )
        )
        try await stateStore.recordEntitlementStatus(status)
        return await currentDecision()
    }

    /// Refreshes the activation session token if it is within the server's
    /// 1-day refresh window. Swallows `refresh_window_not_open` (server says
    /// "too early") so callers can call this opportunistically before any
    /// authenticated request. Other errors propagate so the caller can decide
    /// whether to surface a re-activation prompt.
    @discardableResult
    func ensureSessionFresh() async throws -> ActivationSession? {
        let snapshot = await stateStore.snapshot()
        guard let session = snapshot.activationSession else { return nil }

        let nowDate = now()
        let secondsUntilExpiry = session.expiresAt.timeIntervalSince(nowDate)
        guard secondsUntilExpiry <= 24 * 60 * 60 else { return session }

        let client = apiClientFactory()
        do {
            let refreshed = try await client.refreshActivationSession(
                ActivationSessionRefreshRequest(activationSessionToken: session.token)
            )
            try await stateStore.recordActivationSession(refreshed)
            return refreshed
        } catch let LookInsideAuthenticatorAPIClientError.api(_, code, _)
            where code == "refresh_window_not_open"
        {
            // Server says it's too early; fine, sit tight.
            return session
        }
    }

    static func decision(
        from state: ActivationPersistedState,
        evaluatedAt now: Date
    ) -> ActivationAccessDecision {
        guard let status = state.entitlementStatus else {
            return .activationRequired
        }

        switch status.license.lifecycleState {
        case .expired, .refunded:
            return .expired(at: status.effectiveAccessEndsAt ?? now)
        case .pendingReview:
            // Force a re-resolution against the server before granting access.
            return .activationRequired
        case .active, .canceled:
            // Canceled subscriptions keep access until the period end.
            break
        @unknown default:
            return .activationRequired
        }

        let accessEndsAt = status.effectiveAccessEndsAt ?? state.activationResponse?.activation.expiresAt
        if let accessEndsAt, accessEndsAt < now {
            return .expired(at: accessEndsAt)
        }

        if let connectivityWarning = connectivityWarning(for: status, state: state, now: now) {
            return .allowedWithWarning(message: connectivityWarning, statusSummary: summary(for: status))
        }

        let warning = status.warningMessage ?? status.license.deviceWarning
        if let warning, warning.isEmpty == false {
            return .allowedWithWarning(message: warning, statusSummary: summary(for: status))
        }

        return .allowed(statusSummary: summary(for: status))
    }

    /// Returns a user-facing message when the silent certificate renewer has
    /// recently failed and access is about to lapse. The threshold is wider
    /// than the renewer's so the warning shows up before the lease actually
    /// expires.
    private static func connectivityWarning(
        for status: EntitlementStatus,
        state: ActivationPersistedState,
        now: Date
    ) -> String? {
        guard let endsAt = status.effectiveAccessEndsAt else { return nil }
        let succeeded = state.lastRenewSucceededAt ?? .distantPast
        let failed = state.lastRenewFailedAt ?? .distantPast
        guard failed > succeeded else { return nil }

        let threshold: TimeInterval =
            (status.license.licenseClass == .trial)
                ? 12 * 60 * 60
                : 7 * 24 * 60 * 60
        guard endsAt.timeIntervalSince(now) < threshold else { return nil }

        let dateString = endsAt.formatted(date: .abbreviated, time: .omitted)
        let template = String(
            localized:
            "LookInside needs to reach the activation server to keep your license active. Please connect to the internet — access will pause on %@.",
            bundle: .module
        )
        return String(format: template, dateString)
    }

    private static func summary(for status: EntitlementStatus) -> String {
        let lifecycle = status.license.lifecycleState.rawValue
        if let accessEndsAt = status.effectiveAccessEndsAt {
            return
                "License \(status.license.licenseID) is \(lifecycle) until \(ActivationStateCoding.iso8601Formatter.string(from: accessEndsAt))."
        }
        return "License \(status.license.licenseID) is \(lifecycle)."
    }
}

extension ActivationAccessDecision {
    static let activationRequired = ActivationAccessDecision(
        decision: .block,
        title: String(localized: "Activation Required", bundle: .module),
        message: String(
            localized: "Activate LookInside Pro from the LookInside Pro menu before using this feature.",
            bundle: .module
        ),
        statusSummary: String(localized: "No license state is stored in the Auth Server.", bundle: .module)
    )

    static func expired(at endedAt: Date) -> ActivationAccessDecision {
        ActivationAccessDecision(
            decision: .block,
            title: String(localized: "License Expired", bundle: .module),
            message: String(
                localized: "Refresh the license state or complete activation again to restore access.", bundle: .module
            ),
            statusSummary: "Access expired at \(ActivationStateCoding.iso8601Formatter.string(from: endedAt))."
        )
    }

    static func allowedWithWarning(message: String, statusSummary: String) -> ActivationAccessDecision {
        ActivationAccessDecision(
            decision: .allowWithWarning,
            title: String(localized: "License Review Warning", bundle: .module),
            message: message,
            statusSummary: statusSummary
        )
    }

    static var allowedTitle: String {
        String(localized: "Access Granted", bundle: .module)
    }

    static var allowedMessage: String {
        String(localized: "LookInside Pro is active for this machine.", bundle: .module)
    }

    static func allowed(statusSummary: String) -> ActivationAccessDecision {
        ActivationAccessDecision(
            decision: .allow,
            title: allowedTitle,
            message: allowedMessage,
            statusSummary: statusSummary
        )
    }
}
