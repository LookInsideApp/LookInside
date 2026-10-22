import Foundation

public enum AuthenticatorError: Error, Equatable, LocalizedError, Sendable {
    case challengeExpired
    case challengeIssuedInFuture
    case replayDetected
    case licenseExpired
    case intermediateCertificateExpired
    case intermediateCertificateNotYetValid
    case secureTimestampProviderUnavailable
    case secureTimestampExpired
    case secureTimestampRootMismatch
    case secureTimestampNonceMismatch

    public var errorDescription: String? {
        switch self {
        case .challengeExpired:
            return String(localized: "The client challenge is outside the accepted time window.", bundle: .module)
        case .challengeIssuedInFuture:
            return String(localized: "The client challenge time is ahead of the accepted clock skew.", bundle: .module)
        case .replayDetected:
            return String(localized: "The challenge nonce has already been used.", bundle: .module)
        case .licenseExpired:
            return String(localized: "The license is outside its validity window.", bundle: .module)
        case .intermediateCertificateExpired:
            return String(localized: "The intermediate certificate has expired.", bundle: .module)
        case .intermediateCertificateNotYetValid:
            return String(localized: "The intermediate certificate is not yet valid.", bundle: .module)
        case .secureTimestampProviderUnavailable:
            return String(localized: "A secure timestamp provider is required for this activation path.", bundle: .module)
        case .secureTimestampExpired:
            return String(localized: "The secure timestamp is outside the accepted time window.", bundle: .module)
        case .secureTimestampRootMismatch:
            return String(localized: "The secure timestamp root certificate does not match the trusted root.", bundle: .module)
        case .secureTimestampNonceMismatch:
            return String(localized: "The secure timestamp does not match the challenge nonce.", bundle: .module)
        }
    }
}
