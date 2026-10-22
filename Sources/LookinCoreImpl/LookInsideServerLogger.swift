//
//  LookInsideServerLogger.swift
//  LookinCore
//
//  Swift implementation of LookinServerBase/LookInsideServerLogger.h (the
//  class was in LookInsideServerLogger.m). The exported C constant
//  LookInsideServerLogLevelEnvironmentKey stays in LookInsideServerLogger.m:
//  Swift cannot define a C global.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinServerBase
    #endif

    @objc @implementation extension LookInsideServerLogger {
        class var minimumLogLevel: LookInsideServerLogLevel {
            lookInsideServerMinimumLogLevel
        }

        @objc(shouldLogAtLevel:)
        class func shouldLog(at level: LookInsideServerLogLevel) -> Bool {
            level.rawValue >= minimumLogLevel.rawValue
        }

        @objc(logWithLevel:message:)
        class func log(with level: LookInsideServerLogLevel, message: String) {
            if !shouldLog(at: level) {
                return
            }
            NSLog("LookinServer [%@] - %@", lookInsideServerLogLevelName(level) as NSString, message as NSString)
        }
    }

    /// Read once from the environment, like the original's dispatch_once: a
    /// global `let` is initialized once, thread-safely, on first use.
    private let lookInsideServerMinimumLogLevel: LookInsideServerLogLevel = lookInsideServerLogLevelFromEnvironment()

    private func lookInsideServerLogLevelFromEnvironment() -> LookInsideServerLogLevel {
        guard let rawValue = ProcessInfo.processInfo.environment[LookInsideServerLogLevelEnvironmentKey],
              !rawValue.isEmpty
        else {
            return .default
        }
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "0":
            return .debug
        case "1":
            return .info
        case "2":
            return .default
        case "3":
            return .warning
        case "4":
            return .error
        default:
            return .default
        }
    }

    private func lookInsideServerLogLevelName(_ level: LookInsideServerLogLevel) -> String {
        switch level {
        case .debug:
            "debug"
        case .info:
            "info"
        case .default:
            "default"
        case .warning:
            "warning"
        case .error:
            "error"
        @unknown default:
            // The Objective-C switch fell off the end here; NSLog printed
            // "(null)" for the nil name.
            "(null)"
        }
    }

#endif
