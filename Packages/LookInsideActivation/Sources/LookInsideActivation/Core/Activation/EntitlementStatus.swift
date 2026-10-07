import Foundation

public struct EntitlementStatus: Codable, Sendable, Equatable {
    public let license: LicenseEnvelope
    public let deviceBinding: DeviceBinding?
    public let currentLease: IntermediateCertificateLease?
    public let activationSession: ActivationSession?
    public let isEligibleForActivation: Bool
    public let isEligibleForRenewal: Bool
    public let requiresLiveRefresh: Bool
    public let lastFetchedAt: Date
    public let informationalMessage: String?
    public let warningMessage: String?

    public init(
        license: LicenseEnvelope,
        deviceBinding: DeviceBinding? = nil,
        currentLease: IntermediateCertificateLease? = nil,
        activationSession: ActivationSession? = nil,
        isEligibleForActivation: Bool,
        isEligibleForRenewal: Bool,
        requiresLiveRefresh: Bool = false,
        lastFetchedAt: Date,
        informationalMessage: String? = nil,
        warningMessage: String? = nil
    ) {
        self.license = license
        self.deviceBinding = deviceBinding
        self.currentLease = currentLease
        self.activationSession = activationSession
        self.isEligibleForActivation = isEligibleForActivation
        self.isEligibleForRenewal = isEligibleForRenewal
        self.requiresLiveRefresh = requiresLiveRefresh
        self.lastFetchedAt = lastFetchedAt
        self.informationalMessage = informationalMessage
        self.warningMessage = warningMessage
    }

    public var entitlementEndsAt: Date? {
        license.serviceEndsAt ?? license.expiresAt
    }

    /// The cert and the entitlement are independent expiries; access ends at
    /// whichever lapses first. Either side may be missing (perpetual licenses
    /// have no entitlement end; pre-issuance state has no lease).
    public var effectiveAccessEndsAt: Date? {
        switch (currentLease?.expiresAt, entitlementEndsAt) {
        case let (lease?, ent?):
            return min(lease, ent)
        case let (lease?, nil):
            return lease
        case let (nil, ent?):
            return ent
        case (nil, nil):
            return nil
        }
    }

    public var certificateRenewalAt: Date? {
        currentLease?.renewAfter ?? license.nextCertificateRenewalAt
    }

    public var isAccessCurrentlyAvailable: Bool {
        guard let effectiveAccessEndsAt else {
            return isEligibleForActivation
        }
        return effectiveAccessEndsAt >= lastFetchedAt
    }

    public var displayState: SummaryDisplayState {
        switch (license.licenseClass, license.lifecycleState) {
        case (.trial, _):
            return .trial(daysRemaining: trialDaysRemaining)
        case (.full, .active):
            return .subscriptionActive
        case (.full, .canceled):
            return .subscriptionCanceled
        case (.full, .expired):
            return .subscriptionExpired
        case (.full, .refunded):
            return .subscriptionRefunded
        case (.full, .pendingReview):
            return .subscriptionInReview
        }
    }

    /// Ceiling-rounded days from the server's last verification timestamp to
    /// the entitlement end. Reference time is `lastFetchedAt` so the rendered
    /// count does not drift with client clock skew or screen-on time.
    private var trialDaysRemaining: Int {
        guard let end = entitlementEndsAt else { return 0 }
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute, .second],
            from: lastFetchedAt,
            to: end
        )
        let days = components.day ?? 0
        let hasRemainder =
            (components.hour ?? 0) > 0
                || (components.minute ?? 0) > 0
                || (components.second ?? 0) > 0
        return days + (hasRemainder ? 1 : 0)
    }
}

public enum SummaryDisplayState: Sendable, Equatable {
    case trial(daysRemaining: Int)
    case subscriptionActive
    case subscriptionCanceled
    case subscriptionExpired
    case subscriptionRefunded
    case subscriptionInReview
}
