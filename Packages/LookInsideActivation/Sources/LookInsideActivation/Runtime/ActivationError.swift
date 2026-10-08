import Foundation

/// Errors raised by the in-process activation runtime.
///
/// `errorCode` keeps the string codes the 2.3.x Auth helper sent over its
/// socket, so logs and callers that branch on a code see the same values.
public enum ActivationError: LocalizedError, Equatable, Sendable {
    case invalidRequest(String)
    case keychainFailure(String)
    /// The keychain refused to use the intermediate key: the user cancelled
    /// or denied the access prompt, the password was wrong, or the keychain
    /// is locked and cannot ask. Carries the `OSStatus`.
    case keychainAccessDenied(Int32)
    case stateStoreFailure(String)
    case licenseNotActivated(String)
    case signingFailed(String)
    /// The license key was not used: the Host has not shown a window yet,
    /// the user has not confirmed the keychain explainer, or automatic
    /// signing waits after a refused keychain prompt.
    case signingDeferred
    case activationFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidRequest(message):
            return message
        case let .keychainFailure(message):
            return String(localized: "Keychain operation failed.\n\(message)", bundle: .module)
        case let .keychainAccessDenied(status):
            return String(localized: "Keychain access to the license key was denied.\nStatus \(Int(status)).", bundle: .module)
        case let .stateStoreFailure(message):
            return String(localized: "Auth state storage failed.\n\(message)", bundle: .module)
        case let .licenseNotActivated(message):
            return String(localized: "License is not activated on this device.\n\(message)", bundle: .module)
        case let .signingFailed(message):
            return String(localized: "Signing failed.\n\(message)", bundle: .module)
        case .signingDeferred:
            return String(
                localized: "The license key is not used right now.\nLookInside waits for keychain access to be confirmed.",
                bundle: .module
            )
        case let .activationFailed(message):
            return message
        }
    }

    public var errorCode: String {
        switch self {
        case .invalidRequest: return "invalid_request"
        case .keychainFailure, .keychainAccessDenied: return "keychain_failure"
        case .stateStoreFailure: return "state_store_failure"
        case .licenseNotActivated: return "license_not_activated"
        case .signingFailed, .signingDeferred: return "signing_failed"
        case .activationFailed: return "activation_failed"
        }
    }
}

extension ActivationError {
    /// Statuses that mean the keychain refused access rather than failed:
    /// user cancel (`errSecUserCanceled`, also what `CSSMERR_CSP_USER_CANCELED`
    /// maps to), a wrong password, an ACL denial, or a locked keychain that
    /// may not ask.
    static let keychainAccessDeniedStatuses: Set<Int32> = [
        -128, // errSecUserCanceled
        -25293, // errSecAuthFailed
        -25308, // errSecInteractionNotAllowed
        -2_147_416_032, // CSSMERR_CSP_OPERATION_AUTH_DENIED
    ]

    /// `errSecInteractionNotAllowed`: the keychain is locked and may not
    /// ask. Not a user decision.
    static let interactionNotAllowedStatus: Int32 = -25308

    /// Maps a failed keychain status to `.keychainAccessDenied` or
    /// `.keychainFailure`.
    static func keychain(status: Int32, message: String) -> ActivationError {
        if keychainAccessDeniedStatuses.contains(status) {
            return .keychainAccessDenied(status)
        }
        return .keychainFailure(message)
    }

    /// `true` for `.keychainAccessDenied`.
    var isKeychainAccessDenied: Bool {
        if case .keychainAccessDenied = self {
            return true
        }
        return false
    }
}
