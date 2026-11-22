//
//  InspectionError.swift
//  LookinCore
//
//  The error domain, codes and ready-made errors the Host and the Server
//  share; this was part of LookinDefines.h. The domain and codes cross the
//  wire in error replies, pinned by Tests/WireFormatGolden
//  (Response-Error-*).
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    /// The errors the Host and the Server make, as `NSError` in one domain.
    public enum InspectionError {
        /// The domain of every error here.
        public static let domain = "LookinError"

        /// The codes in `domain`. `Int`, as the anonymous C enum they replace
        /// was imported.
        public enum Code {
            public static let `default` = -400
            /// An internal logic error in Lookin.
            public static let inner = -401
            /// An internal PeerTalk error.
            public static let peerTalk = -402
            /// There is no connection, or it was closed.
            public static let noConnection = -403
            /// A ping timed out.
            public static let pingFailedForTimeout = -404
            /// A request timed out.
            public static let timeout = -405
            /// A newer request of the same type was sent, so the older one was
            /// dropped.
            public static let discarded = -406
            /// A ping failed because the app reported that it is in the
            /// background.
            public static let pingFailedForBackgroundState = -407
            /// The Host did not pass LookinServer's license check.
            public static let licenseRequired = -408

            /// The object was not found; it may have been deallocated.
            public static let objectNotFound = -500
            /// The value type cannot be modified.
            public static let modifyValueTypeInvalid = -501
            public static let exception = -502

            /// LookinServer is too new; the client needs an update.
            public static let serverVersionTooHigh = -600
            /// LookinServer is too old; the Server needs an update.
            public static let serverVersionTooLow = -601

            /// The file type is not supported.
            public static let unsupportedFileType = -700
        }

        /// The target object is gone. A new error on every read.
        public static var objectNotFound: NSError {
            NSError(domain: domain, code: Code.objectNotFound, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("Failed to get target object in iOS app", comment: ""),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Perhaps the related object was deallocated. You can reload LookInside to get newest data.", comment: ""),
            ])
        }

        /// The connection is gone. A new error on every read.
        public static var noConnection: NSError {
            NSError(domain: domain, code: Code.noConnection, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("The operation failed due to disconnection with the iOS app.", comment: ""),
            ])
        }

        /// An internal error. A new error on every read.
        public static var inner: NSError {
            NSError(domain: domain, code: Code.inner, userInfo: [
                NSLocalizedDescriptionKey: NSLocalizedString("The operation failed due to an inner error.", comment: ""),
            ])
        }

        /// An error with code `Code.default` that shows `title` and suggests
        /// `detail`.
        public static func makeError(title: String, detail: String) -> NSError {
            NSError(domain: domain, code: Code.default, userInfo: [
                NSLocalizedDescriptionKey: title,
                NSLocalizedRecoverySuggestionErrorKey: detail,
            ])
        }

        /// What the Host tells the user when a request timed out.
        public static var timeoutDescription: String {
            NSLocalizedString("Perhaps your iOS app is paused with breakpoint in Xcode, blocked by other tasks in main thread, or moved to background state.", comment: "")
        }
    }

#endif
