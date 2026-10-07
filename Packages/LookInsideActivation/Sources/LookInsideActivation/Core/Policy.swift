import Foundation

public struct ActivationPolicy: Sendable, Equatable {
    public let acceptedClockSkew: TimeInterval
    public let challengeTimeToLive: TimeInterval
    public let secureTimestampTimeToLive: TimeInterval
    public let activationLifetime: TimeInterval
    public let requiresSecureTimestampForTrial: Bool

    public init(
        acceptedClockSkew: TimeInterval = 30,
        challengeTimeToLive: TimeInterval = 180,
        secureTimestampTimeToLive: TimeInterval = 120,
        activationLifetime: TimeInterval = 3600,
        requiresSecureTimestampForTrial: Bool = true
    ) {
        self.acceptedClockSkew = acceptedClockSkew
        self.challengeTimeToLive = challengeTimeToLive
        self.secureTimestampTimeToLive = secureTimestampTimeToLive
        self.activationLifetime = activationLifetime
        self.requiresSecureTimestampForTrial = requiresSecureTimestampForTrial
    }

    public func activationPath(for licenseClass: LicenseClass) -> ActivationPath {
        switch licenseClass {
        case .trial where requiresSecureTimestampForTrial:
            return .timeAnchored
        case .trial, .full:
            return .direct
        }
    }
}
