import Foundation

/// What the license window says about the license key's keychain access.
package enum KeychainAccessNotice: Sendable, Equatable {
    /// A keychain prompt was refused: automatic uses wait.
    case denied
    /// Not Now in the keychain explainer: no system prompt was shown, the
    /// key's use waits until the user continues.
    case postponed
    /// An automatic use succeeded after a one-time Allow: every newly
    /// connected app will ask again until the user picks Always Allow.
    case allowedOnce

    /// The notice for `status` at `date`, or `nil` when there is nothing to
    /// say.
    package init?(_ status: ActivationSigningStatus, at date: Date) {
        if status.isKeychainAccessDenied(at: date) {
            self = status.isKeychainAccessPostponed ? .postponed : .denied
        } else if status.isKeychainAccessAllowedOnce {
            self = .allowedOnce
        } else {
            return nil
        }
    }

    /// `true` when the notice offers Try Again.
    package var offersRetry: Bool {
        self != .allowedOnce
    }

    package var message: String {
        switch self {
        case .denied:
            return String(
                localized: "Keychain access to the license key was denied, so Pro features are paused.",
                bundle: .module
            )
        case .postponed:
            return String(
                localized:
                "LookInside won’t use the license key until you continue, so Pro features are paused. Click Try Again when you’re ready.",
                bundle: .module
            )
        case .allowedOnce:
            return String(
                localized:
                "macOS asks for keychain access each time LookInside connects to an app. Choose “Always Allow” to stop these requests.",
                bundle: .module
            )
        }
    }
}
