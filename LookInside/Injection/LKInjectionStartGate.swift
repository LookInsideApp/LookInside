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
