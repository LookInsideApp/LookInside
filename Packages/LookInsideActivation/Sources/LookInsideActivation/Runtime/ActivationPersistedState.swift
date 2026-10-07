import Foundation

struct ActivationPersistedState: Codable {
    var deviceFingerprint: DeviceFingerprint?
    var activationSession: ActivationSession?
    var entitlementStatus: EntitlementStatus?
    var activationResponse: HostActivationResponse?
    var updatedAt: Date?

    /// Telemetry written by `ActivationCertificateRenewer`. The evaluator
    /// surfaces a connectivity warning when the most recent attempt failed
    /// and the lease is approaching expiry, so these timestamps must outlive
    /// the in-memory renewer instance.
    var lastRenewAttemptAt: Date?
    var lastRenewSucceededAt: Date?
    var lastRenewFailedAt: Date?
    var lastRenewError: String?
}

extension ActivationPersistedState {
    var diskBackedState: ActivationPersistedState {
        guard entitlementStatus?.license.licenseClass == .trial else {
            return self
        }

        return ActivationPersistedState(
            deviceFingerprint: deviceFingerprint,
            activationSession: nil,
            entitlementStatus: nil,
            activationResponse: nil,
            updatedAt: updatedAt,
            lastRenewAttemptAt: lastRenewAttemptAt,
            lastRenewSucceededAt: lastRenewSucceededAt,
            lastRenewFailedAt: lastRenewFailedAt,
            lastRenewError: lastRenewError
        )
    }
}
