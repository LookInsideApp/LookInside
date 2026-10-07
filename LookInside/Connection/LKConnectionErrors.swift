//
//  LKConnectionErrors.swift
//  LookInside
//
//  The NSErrors the Connection layer reports. Swift does not import the
//  LookinErr_* macros of LookinDefines.h, so these build the same errors:
//  same domain, codes and localization keys.
//

import Foundation
import LookInsideHostCore

enum LKConnectionError {
    private static func make(_ code: Int, _ description: String, recovery: String? = nil) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: description]
        if let recovery {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recovery
        }
        return NSError(domain: LookinErrorDomain, code: code, userInfo: userInfo)
    }

    /// `LookinErr_Inner`
    static var inner: NSError {
        make(LookinErrCode_Inner, NSLocalizedString("The operation failed due to an inner error.", comment: ""))
    }

    /// `LookinErr_NoConnect`
    static var noConnect: NSError {
        make(LookinErrCode_NoConnect, NSLocalizedString("The operation failed due to disconnection with the iOS app.", comment: ""))
    }

    /// `LookinErr_ObjNotFound`
    static var objectNotFound: NSError {
        make(
            LookinErrCode_ObjectNotFound,
            NSLocalizedString("Failed to get target object in iOS app", comment: ""),
            recovery: NSLocalizedString("Perhaps the related object was deallocated. You can reload LookInside to get newest data.", comment: "")
        )
    }

    static var discarded: NSError {
        make(LookinErrCode_Discard, NSLocalizedString("The request is discarded due to a newer same request.", comment: ""))
    }

    static var timeout: NSError {
        make(
            LookinErrCode_Timeout,
            NSLocalizedString("Request timeout", comment: ""),
            // LookinErrorText_Timeout
            recovery: NSLocalizedString("Perhaps your iOS app is paused with breakpoint in Xcode, blocked by other tasks in main thread, or moved to background state.", comment: "")
        )
    }

    /// Sending a frame failed.
    static var transport: NSError {
        make(LookinErrCode_PeerTalk, NSLocalizedString("The operation failed due to an inner error.", comment: ""))
    }

    static var appInBackground: NSError {
        make(
            LookinErrCode_PingFailForBackgroundState,
            NSLocalizedString("The operation failed because target iOS app has entered to the background state.", comment: "")
        )
    }

    static var serverVersionTooLow: NSError {
        make(
            LookinErrCode_ServerVersionTooLow,
            NSLocalizedString("Fail to inspect this target app due to a version problem.", comment: ""),
            recovery: NSLocalizedString("Please update the embedded LookinServer integration in your target app to a newer version from this repository.", comment: "")
        )
    }

    static var serverVersionTooHigh: NSError {
        make(
            LookinErrCode_ServerVersionTooHigh,
            NSLocalizedString("LookInside app version is too low.", comment: ""),
            recovery: NSLocalizedString("Target app is linked with a higher version LookinServer.framework. Update this community build from the current repository source.", comment: "")
        )
    }

    static func licenseVerificationFailed(detail: String? = nil) -> NSError {
        make(
            LookinErrCode_LicenseRequired,
            NSLocalizedString("LookInside license verification failed.", comment: ""),
            recovery: detail
        )
    }

    static var malformedLicenseChallenge: NSError {
        make(LookinErrCode_Inner, NSLocalizedString("License challenge payload is malformed.", comment: ""))
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
        case LookinErrCode_ObjectNotFound:
            objectNotFound
        case LookinErrCode_Inner:
            inner
        default:
            serverError
        }
    }
}
