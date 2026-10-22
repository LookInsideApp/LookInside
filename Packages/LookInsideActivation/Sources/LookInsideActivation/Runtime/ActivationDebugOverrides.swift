#if DEBUG
    import Foundation

    /// DEBUG-only hooks that point the activation runtime at a local LookInside
    /// Web instance, trust a throwaway test root, and keep a test run away from
    /// this Mac's real activation. Compiled out of release builds, which talk to
    /// production, trust only `rootProd2026`, and use the helper's state
    /// directory and login-keychain key.
    ///
    /// Values come from the setters or, when unset, from the environment:
    /// - `LOOKINSIDE_ACTIVATION_API_BASE_URL`: service base URL.
    /// - `LOOKINSIDE_ACTIVATION_TEST_ROOT_ID` and
    ///   `LOOKINSIDE_ACTIVATION_TEST_ROOT_PUBLIC_KEY_PEM`: an extra trusted root.
    /// - `LOOKINSIDE_ACTIVATION_STATE_DIR`: directory for `state.json`
    ///   instead of the helper's.
    /// - `LOOKINSIDE_ACTIVATION_KEYCHAIN_PATH`: a file keychain for the license
    ///   key instead of the login keychain. The key then uses the test-only tag
    ///   `testKeyApplicationTag` and trusts no other application. The file does
    ///   not have to exist; without it every key lookup finds nothing.
    public enum ActivationDebugOverrides {
        private static let lock = NSLock()
        private nonisolated(unsafe) static var storedServiceBaseURL: URL?
        private nonisolated(unsafe) static var storedAdditionalTrustedRoot: TrustedRootPublicKey?
        private nonisolated(unsafe) static var storedStateDirectoryURL: URL?
        private nonisolated(unsafe) static var storedKeychainPath: String?

        static let serviceBaseURLEnvironmentKey = "LOOKINSIDE_ACTIVATION_API_BASE_URL"
        static let testRootIDEnvironmentKey = "LOOKINSIDE_ACTIVATION_TEST_ROOT_ID"
        static let testRootPublicKeyEnvironmentKey = "LOOKINSIDE_ACTIVATION_TEST_ROOT_PUBLIC_KEY_PEM"
        static let stateDirectoryEnvironmentKey = "LOOKINSIDE_ACTIVATION_STATE_DIR"
        static let keychainPathEnvironmentKey = "LOOKINSIDE_ACTIVATION_KEYCHAIN_PATH"

        /// Key tag used with `keychainPath`, so a test key never carries the
        /// helper's tag.
        public static let testKeyApplicationTag = "app.lookinside.debug.intermediate-key"

        public static var serviceBaseURL: URL? {
            get {
                if let stored = lock.withLock({ storedServiceBaseURL }) {
                    return stored
                }
                let environment = ProcessInfo.processInfo.environment
                guard let value = environment[serviceBaseURLEnvironmentKey], value.isEmpty == false else {
                    return nil
                }
                return URL(string: value)
            }
            set {
                lock.withLock { storedServiceBaseURL = newValue }
            }
        }

        public static var stateDirectoryURL: URL? {
            get {
                if let stored = lock.withLock({ storedStateDirectoryURL }) {
                    return stored
                }
                guard let value = environmentValue(stateDirectoryEnvironmentKey) else {
                    return nil
                }
                return URL(fileURLWithPath: (value as NSString).expandingTildeInPath, isDirectory: true)
            }
            set {
                lock.withLock { storedStateDirectoryURL = newValue }
            }
        }

        public static var keychainPath: String? {
            get {
                if let stored = lock.withLock({ storedKeychainPath }) {
                    return stored
                }
                return environmentValue(keychainPathEnvironmentKey).map { ($0 as NSString).expandingTildeInPath }
            }
            set {
                lock.withLock { storedKeychainPath = newValue }
            }
        }

        /// `configuration` with the state directory and keychain overrides
        /// applied.
        static func apply(to configuration: ActivationConfiguration) -> ActivationConfiguration {
            var configuration = configuration
            if let stateDirectoryURL {
                configuration.stateDirectoryURL = stateDirectoryURL
            }
            if let keychainPath {
                configuration.keyStore = IntermediateKeyStoreConfiguration(
                    applicationTag: testKeyApplicationTag,
                    keychainPath: keychainPath
                )
            }
            return configuration
        }

        private static func environmentValue(_ key: String) -> String? {
            guard let value = ProcessInfo.processInfo.environment[key], value.isEmpty == false else {
                return nil
            }
            return value
        }

        public static var additionalTrustedRoot: TrustedRootPublicKey? {
            get {
                if let stored = lock.withLock({ storedAdditionalTrustedRoot }) {
                    return stored
                }
                let environment = ProcessInfo.processInfo.environment
                guard let identifier = environment[testRootIDEnvironmentKey], identifier.isEmpty == false,
                      let pem = environment[testRootPublicKeyEnvironmentKey], pem.isEmpty == false
                else {
                    return nil
                }
                return TrustedRootPublicKey(certificateID: identifier, publicKeyPEM: pem, publicKeySHA256: "")
            }
            set {
                lock.withLock { storedAdditionalTrustedRoot = newValue }
            }
        }
    }
#endif

#if DEBUG
    public extension ActivationRuntime {
        /// DEBUG end-to-end hook: creates the license key when none is stored
        /// and returns a PKCS#10 request for it, so a test can issue an
        /// intermediate certificate under a throwaway root for a key this
        /// process created (and may then use without a keychain prompt).
        ///
        /// Works only on a file keychain (`LOOKINSIDE_ACTIVATION_KEYCHAIN_PATH`);
        /// it refuses to create a key in the login keychain.
        func debugMakeTestKeyCertificateSigningRequestPEM(commonName: String) throws -> String {
            guard configuration.keyStore.keychainPath != nil else {
                throw ActivationError.invalidRequest("The test key needs a file keychain (LOOKINSIDE_ACTIVATION_KEYCHAIN_PATH).")
            }
            return try keyStore.makeCertificateSigningRequestPEM(commonName: commonName)
        }
    }
#endif
