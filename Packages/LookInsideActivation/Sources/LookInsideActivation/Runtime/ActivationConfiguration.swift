import Foundation

/// Where the activation runtime keeps its state and key, and which service it
/// talks to.
///
/// `standard` points at the locations the 2.3.x Auth helper used, so a Mac
/// activated by the helper stays activated and the helper can still read what
/// the Host writes. Tests and tools inject a temporary state directory and a
/// temporary keychain instead.
public struct ActivationConfiguration: Sendable {
    /// Directory holding `state.json`.
    public var stateDirectoryURL: URL
    /// Keychain item that holds the intermediate RSA-2048 key.
    public var keyStore: IntermediateKeyStoreConfiguration
    /// LookInside Web base URL.
    public var serviceBaseURL: URL
    /// `appBundleID` reported in the device fingerprint. The helper reported its
    /// own bundle identifier; keeping it keeps the server-side device binding
    /// unchanged for existing activations.
    public var fingerprintAppBundleID: String
    /// Activation UI defaults: requested feature and framework version sent
    /// in the activation challenge.
    public var requestedFeature: String
    public var frameworkVersion: String

    public init(
        stateDirectoryURL: URL,
        keyStore: IntermediateKeyStoreConfiguration = .standard,
        serviceBaseURL: URL = LookInsideAuthenticatorAPIClient.serviceBaseURL,
        fingerprintAppBundleID: String = ActivationConfiguration.helperBundleIdentifier,
        requestedFeature: String = "swiftui.support",
        frameworkVersion: String = "1.0.0"
    ) {
        self.stateDirectoryURL = stateDirectoryURL
        self.keyStore = keyStore
        self.serviceBaseURL = serviceBaseURL
        self.fingerprintAppBundleID = fingerprintAppBundleID
        self.requestedFeature = requestedFeature
        self.frameworkVersion = frameworkVersion
    }

    /// `state.json` inside `stateDirectoryURL`.
    public var stateFileURL: URL {
        stateDirectoryURL.appendingPathComponent("state.json", isDirectory: false)
    }

    /// Bundle identifier of the 2.3.x Auth helper.
    public static let helperBundleIdentifier = "app.lookinside.LookInsideAuthServer"

    /// `~/Library/Application Support/LookInside/AuthServer/state`, the helper's
    /// state directory.
    public static var standardStateDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(
                "Library/Application Support/LookInside/AuthServer",
                isDirectory: true
            )
            .appendingPathComponent("state", isDirectory: true)
    }

    /// The helper-compatible configuration. In DEBUG builds the service URL,
    /// the state directory and the keychain can be redirected with
    /// `ActivationDebugOverrides`.
    public static var standard: ActivationConfiguration {
        let configuration = ActivationConfiguration(
            stateDirectoryURL: standardStateDirectoryURL,
            keyStore: .standard,
            serviceBaseURL: ActivationEnvironment.serviceBaseURL
        )
        #if DEBUG
            return ActivationDebugOverrides.apply(to: configuration)
        #else
            return configuration
        #endif
    }
}

/// Resolves the service URL and trusted roots, applying DEBUG overrides.
enum ActivationEnvironment {
    static var serviceBaseURL: URL {
        #if DEBUG
            if let override = ActivationDebugOverrides.serviceBaseURL {
                return override
            }
        #endif
        return LookInsideAuthenticatorAPIClient.serviceBaseURL
    }
}
