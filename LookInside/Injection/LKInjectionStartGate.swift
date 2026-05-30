import Foundation

enum LKInjectionStartDecision: Equatable {
    case started
    case alreadyInProgress
    case blocked
}

struct LKInjectionStartGate {
    private(set) var isInProgress = false

    mutating func begin(isProtectedFeatureAllowedSilently: () -> Bool) -> LKInjectionStartDecision {
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

enum LKInjectionDaemonStatusSnapshot: Equatable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
    case unknown(Int)
}

enum LKInjectionDaemonNextStep: Equatable {
    case proceed
    case requestRegistrationConsent
    case waitForApproval
    case reportMissingBundle
    case reportUnsupportedStatus(Int)
}

struct LKInjectionDaemonReadiness {
    static func nextStep(for status: LKInjectionDaemonStatusSnapshot) -> LKInjectionDaemonNextStep {
        switch status {
        case .enabled:
            return .proceed
        case .notRegistered:
            return .requestRegistrationConsent
        case .requiresApproval:
            return .waitForApproval
        case .notFound:
            return .reportMissingBundle
        case let .unknown(rawValue):
            return .reportUnsupportedStatus(rawValue)
        }
    }
}
