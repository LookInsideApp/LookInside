import Foundation

enum InjectionStartDecision: Equatable {
    case started
    case alreadyInProgress
    case blocked
}

struct InjectionStartGate {
    private(set) var isInProgress = false

    mutating func begin(isProtectedFeatureAllowedSilently: () -> Bool) -> InjectionStartDecision {
        guard !isInProgress else {
            return .alreadyInProgress
        }
        guard isProtectedFeatureAllowedSilently() else {
            return .blocked
        }
        isInProgress = true
        return .started
    }

    mutating func finish() {
        isInProgress = false
    }
}

enum InjectionDaemonStatusSnapshot: Equatable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
    case unavailableFromCurrentLocation
    case unknown(Int)
}

enum InjectionDaemonNextStep: Equatable {
    case proceed
    case requestRegistrationConsent
    case waitForApproval
    case reportMissingBundle
    case reportCurrentLocationUnsupported
    case reportUnsupportedStatus(Int)
}

enum InjectionDaemonReadiness {
    static func nextStep(for status: InjectionDaemonStatusSnapshot) -> InjectionDaemonNextStep {
        switch status {
        case .enabled:
            return .proceed
        case .notRegistered:
            return .requestRegistrationConsent
        case .requiresApproval:
            return .waitForApproval
        case .notFound:
            return .reportMissingBundle
        case .unavailableFromCurrentLocation:
            return .reportCurrentLocationUnsupported
        case let .unknown(rawValue):
            return .reportUnsupportedStatus(rawValue)
        }
    }
}
