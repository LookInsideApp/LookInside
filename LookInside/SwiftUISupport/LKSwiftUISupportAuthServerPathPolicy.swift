import Foundation

enum LKSwiftUISupportAuthServerPathPolicy {
    static func executableURL(
        environment: [String: String],
        overrideKey: String,
        defaultURL: URL
    ) -> URL {
        #if DEBUG
            if let explicitPath = environment[overrideKey], explicitPath.isEmpty == false {
                return URL(fileURLWithPath: explicitPath)
            }
        #endif
        return defaultURL
    }

    static func socketURL(
        environment: [String: String],
        overrideKey: String,
        defaultURL: URL
    ) -> URL {
        #if DEBUG
            if let explicitPath = environment[overrideKey], explicitPath.isEmpty == false {
                return URL(fileURLWithPath: explicitPath)
            }
        #endif
        return defaultURL
    }

    static func launchEnvironment(
        from environment: [String: String],
        helperPathKey: String,
        helperVersionKey: String
    ) -> [String: String] {
        var launchEnvironment = environment
        #if !DEBUG
            launchEnvironment.removeValue(forKey: helperPathKey)
            launchEnvironment.removeValue(forKey: helperVersionKey)
        #endif
        return launchEnvironment
    }
}

enum LKSwiftUISupportActivationStateRefreshStartupAction: Equatable {
    case installAndLaunch
    case launchInstalledHelper
}

enum LKSwiftUISupportActivationStateRefreshPolicy {
    static var startupAction: LKSwiftUISupportActivationStateRefreshStartupAction {
        return .installAndLaunch
    }
}
