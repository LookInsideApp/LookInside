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
            return "The client challenge is outside the accepted time window."
        case .challengeIssuedInFuture:
            return "The client challenge time is ahead of the accepted clock skew."
        case .replayDetected:
            return "The challenge nonce has already been used."
        case .licenseExpired:
            return "The license is outside its validity window."
        case .intermediateCertificateExpired:
            return "The intermediate certificate has expired."
        case .intermediateCertificateNotYetValid:
            return "The intermediate certificate is not yet valid."
        case .secureTimestampProviderUnavailable:
            return "A secure timestamp provider is required for this activation path."
        case .secureTimestampExpired:
            return "The secure timestamp is outside the accepted time window."
        case .secureTimestampRootMismatch:
            return "The secure timestamp root certificate does not match the trusted root."
        case .secureTimestampNonceMismatch:
            return "The secure timestamp does not match the challenge nonce."
        }
    }
}
