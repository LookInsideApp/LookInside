//
//  ConnectionErrors.swift
//  LookInside
//
//  The NSErrors the Connection layer reports: the same errors as the
//  `InspectionError` values in LookinCoreImpl/InspectionError.swift (formerly
//  macros of LookinDefines.h) — same domain, codes and localization keys.
//

import Foundation
import LookInsideHostCore

enum ConnectionError {
    private static func make(_ code: Int, _ description: String, recovery: String? = nil) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: description]
        if let recovery {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recovery
        }
        return NSError(domain: InspectionError.domain, code: code, userInfo: userInfo)
    }

    /// `InspectionError.inner`
    static var inner: NSError {
        make(InspectionError.Code.inner, NSLocalizedString("The operation failed due to an inner error.", comment: ""))
    }

    /// `InspectionError.noConnection`
    static var noConnect: NSError {
        make(InspectionError.Code.noConnection, NSLocalizedString("The operation failed due to disconnection with the iOS app.", comment: ""))
    }

    /// `InspectionError.objectNotFound`
    static var objectNotFound: NSError {
        make(
            InspectionError.Code.objectNotFound,
            NSLocalizedString("Failed to get target object in iOS app", comment: ""),
            recovery: NSLocalizedString("Perhaps the related object was deallocated. You can reload LookInside to get newest data.", comment: "")
        )
    }

    static var discarded: NSError {
        make(InspectionError.Code.discarded, NSLocalizedString("The request is discarded due to a newer same request.", comment: ""))
    }

    static var timeout: NSError {
        make(
            InspectionError.Code.timeout,
            NSLocalizedString("Request timeout", comment: ""),
            // InspectionError.timeoutDescription
            recovery: NSLocalizedString("Perhaps your iOS app is paused with breakpoint in Xcode, blocked by other tasks in main thread, or moved to background state.", comment: "")
        )
    }

    /// Sending a frame failed.
    static var transport: NSError {
        make(InspectionError.Code.peerTalk, NSLocalizedString("The operation failed due to an inner error.", comment: ""))
    }

    static var appInBackground: NSError {
        make(
            InspectionError.Code.pingFailedForBackgroundState,
            NSLocalizedString("The operation failed because target iOS app has entered to the background state.", comment: "")
        )
    }

    static var serverVersionTooLow: NSError {
        make(
            InspectionError.Code.serverVersionTooLow,
            NSLocalizedString("Fail to inspect this target app due to a version problem.", comment: ""),
            recovery: NSLocalizedString("Please update the embedded LookinServer integration in your target app to a newer version from this repository.", comment: "")
        )
    }

    static var serverVersionTooHigh: NSError {
        make(
            InspectionError.Code.serverVersionTooHigh,
            NSLocalizedString("LookInside app version is too low.", comment: ""),
            recovery: NSLocalizedString("Target app is linked with a higher version LookinServer.framework. Update this community build from the current repository source.", comment: "")
        )
    }

    static func licenseVerificationFailed(detail: String? = nil) -> NSError {
        make(
            InspectionError.Code.licenseRequired,
            NSLocalizedString("LookInside license verification failed.", comment: ""),
            recovery: detail
        )
    }

    static var malformedLicenseChallenge: NSError {
        make(InspectionError.Code.inner, NSLocalizedString("License challenge payload is malformed.", comment: ""))
    }

    /// The error a failed license handshake is logged with.
    static func licenseHandshakeError(_ failure: LicenseHandshakeFailure) -> NSError {
        switch failure {
        case let .challengeRejected(error), let .challengeTransport(error),
             let .verifyRejected(error), let .verifyTransport(error):
            error
        case .malformedChallenge:
            malformedLicenseChallenge
        case let .signingFailed(detail):
            licenseVerificationFailed(detail: detail ?? NSLocalizedString("License signing failed.", comment: ""))
        case .retryHeldBack:
            licenseVerificationFailed()
        }
    }

    /// The Server's error for a request, as the inspector shows it: the
    /// object-not-found and inner-error codes become the localized errors,
    /// anything else passes through.
    static func localized(_ serverError: NSError) -> NSError {
        switch serverError.code {
        case InspectionError.Code.objectNotFound:
            objectNotFound
        case InspectionError.Code.inner:
            inner
        default:
            serverError
        }
    }
}
