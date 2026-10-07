import Foundation
import Security

/// Identifies the keychain item that holds the intermediate RSA-2048 key.
public struct IntermediateKeyStoreConfiguration: Sendable, Equatable {
    /// `kSecAttrApplicationTag` of the private key.
    public var applicationTag: String
    /// Path of a file-based keychain to use instead of the default keychain
    /// search list. `nil` (the default) uses the user's login keychain, as the
    /// helper did. Tests pass a temporary keychain file.
    public var keychainPath: String?
    /// Applications, besides the current one, that a newly created key trusts
    /// without a keychain prompt. Paths that do not exist when the key is
    /// created, or whose code signature the key store does not accept, are
    /// skipped. Existing keys are never changed.
    public var trustedApplicationPaths: [String]

    public init(
        applicationTag: String,
        keychainPath: String? = nil,
        trustedApplicationPaths: [String] = []
    ) {
        self.applicationTag = applicationTag
        self.keychainPath = keychainPath
        self.trustedApplicationPaths = trustedApplicationPaths
    }

    /// Tag the 2.3.x Auth helper used. Reusing it keeps existing keys.
    public static let helperApplicationTag = "com.lookinside.authserver.intermediate-key"

    /// The installed 2.3.x Auth helper. A key the Host creates trusts it, so
    /// an older LookInside that launches the helper after a downgrade can
    /// sign without a keychain prompt.
    public static var helperApplicationPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(
                "Library/Application Support/LookInside/AuthServer/current/lookinside-auth-server.app",
                isDirectory: true
            )
            .path
    }

    public static var standard: IntermediateKeyStoreConfiguration {
        IntermediateKeyStoreConfiguration(
            applicationTag: helperApplicationTag,
            trustedApplicationPaths: [helperApplicationPath]
        )
    }
}

/// The Security calls `IntermediateKeyStore` makes. Tests replace them to
/// simulate keychain statuses.
struct IntermediateKeychainOperations: Sendable {
    var copyMatching: @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    var createRandomKey: @Sendable (CFDictionary, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey?

    static let system = IntermediateKeychainOperations(
        copyMatching: { SecItemCopyMatching($0, $1) },
        createRandomKey: { SecKeyCreateRandomKey($0, $1) }
    )
}

/// Keeps the intermediate RSA-2048 key in the file-based keychain and signs
/// with it.
///
/// The query and key attributes match the helper's `AuthServerKeyMaterialStore`
/// exactly (no data-protection keychain, no access group), so the Host finds
/// the key the helper created and creates one the helper can find. The key is
/// generated only when the keychain reports that no key with the tag exists;
/// any other lookup failure (a denied or cancelled prompt, a locked keychain)
/// is thrown, so an existing key is never replaced by a second one.
final class IntermediateKeyStore: @unchecked Sendable {
    let configuration: IntermediateKeyStoreConfiguration
    private let operations: IntermediateKeychainOperations
    private let trustedApplication: @Sendable (String) -> SecTrustedApplication?
    private let didCreateKey: @Sendable () -> Void
    private let lock = NSLock()

    /// `trustedApplication` turns an existing path from
    /// `trustedApplicationPaths` into an access-list entry for a new key, or
    /// refuses it with `nil`. By default only the 2.3.x helper signed by the
    /// running Host's own team is accepted. `didCreateKey` runs after this
    /// store created a key.
    init(
        configuration: IntermediateKeyStoreConfiguration = .standard,
        operations: IntermediateKeychainOperations = .system,
        trustedApplication: @escaping @Sendable (String) -> SecTrustedApplication? =
            TrustedApplicationSignature.trustedHelperApplication(atPath:),
        didCreateKey: @escaping @Sendable () -> Void = {}
    ) {
        self.configuration = configuration
        self.operations = operations
        self.trustedApplication = trustedApplication
        self.didCreateKey = didCreateKey
    }

    private var applicationTag: Data {
        Data(configuration.applicationTag.utf8)
    }

    func makeCertificateSigningRequestPEM(commonName: String) throws -> String {
        let privateKey = try ensurePrivateKey()
        do {
            return try CertificateSigningRequestBuilder.makePKCS10PEM(
                privateKey: privateKey,
                commonName: commonName
            )
        } catch let CertificateSigningRequestError.signingFailedWithStatus(status, message) {
            throw ActivationError.keychain(status: status, message: message)
        } catch let error as CertificateSigningRequestError {
            throw ActivationError.keychainFailure(String(describing: error))
        }
    }

    /// Signs `message` with the stored intermediate RSA-2048 key using
    /// RSA-PKCS1v15-SHA256. Used for the 220/221 license handshake.
    func sign(message: Data) throws -> Data {
        let privateKey = try ensurePrivateKey()
        return try Self.sign(message: message, with: privateKey)
    }

    /// Signs `message` with the stored key and never creates one. Throws
    /// `ActivationError.licenseNotActivated` when no key is stored.
    func signWithExistingKey(message: Data) throws -> Data {
        let existing = try lock.withLock { try existingPrivateKey() }
        guard let existing else {
            throw ActivationError.licenseNotActivated("No license key is stored on this Mac.")
        }
        return try Self.sign(message: message, with: existing)
    }

    static func sign(message: Data, with privateKey: SecKey) throws -> Data {
        var errorRef: Unmanaged<CFError>?
        guard
            let signature = SecKeyCreateSignature(
                privateKey,
                .rsaSignatureMessagePKCS1v15SHA256,
                message as CFData,
                &errorRef
            ) as Data?
        else {
            let error = errorRef?.takeRetainedValue() as Error?
            let message = error?.localizedDescription ?? "SecKeyCreateSignature returned no signature."
            if let error = error as NSError?, error.domain == NSOSStatusErrorDomain,
               ActivationError.keychainAccessDeniedStatuses.contains(Int32(error.code))
            {
                throw ActivationError.keychainAccessDenied(Int32(error.code))
            }
            throw ActivationError.signingFailed(message)
        }
        return signature
    }

    /// `true` when a key with the configured tag exists. Never creates one,
    /// and answers `false` when the keychain cannot be searched.
    func hasPrivateKey() -> Bool {
        (try? existingPrivateKey()) != nil
    }

    func ensurePrivateKey() throws -> SecKey {
        lock.lock()
        defer { lock.unlock() }
        if let existing = try existingPrivateKey() {
            return existing
        }
        var attributes = generationAttributes()
        if let keychain = try openKeychain() {
            attributes[kSecUseKeychain] = keychain
        }
        if let access = makeAccess() {
            attributes[kSecAttrAccess] = access
        }
        var errorRef: Unmanaged<CFError>?
        guard let key = operations.createRandomKey(attributes as CFDictionary, &errorRef) else {
            let message =
                (errorRef?.takeRetainedValue() as Error?)?.localizedDescription
                    ?? "Private key creation returned no key reference."
            throw ActivationError.keychainFailure(message)
        }
        didCreateKey()
        return key
    }

    /// The stored key's public-key hash (`kSecAttrApplicationLabel`), or
    /// `nil` when no key is stored. Reads attributes only, so it never uses
    /// the key or raises a keychain prompt.
    func keyIdentity() throws -> Data? {
        var query = lookupQuery()
        query[kSecReturnRef] = nil
        query[kSecReturnAttributes] = true
        if let keychain = try openKeychain() {
            query[kSecMatchSearchList] = [keychain]
        }
        var item: CFTypeRef?
        let status = operations.copyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            let attributes = item as? [String: Any]
            return attributes?[kSecAttrApplicationLabel as String] as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw ActivationError.keychain(
                status: status,
                message: "SecItemCopyMatching failed with status \(status)."
            )
        }
    }

    /// The stored key, or `nil` only when the keychain answers
    /// `errSecItemNotFound`. Every other failure throws.
    func existingPrivateKey() throws -> SecKey? {
        var query = lookupQuery()
        if let keychain = try openKeychain() {
            // An injected keychain that cannot be opened throws above
            // instead of falling back to the default search list.
            query[kSecMatchSearchList] = [keychain]
        }

        var item: CFTypeRef?
        let status = operations.copyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let item, CFGetTypeID(item) == SecKeyGetTypeID() else {
                throw ActivationError.keychainFailure("The keychain returned an item that is not a key.")
            }
            return (item as! SecKey)
        case errSecItemNotFound:
            return nil
        default:
            throw ActivationError.keychain(
                status: status,
                message: "SecItemCopyMatching failed with status \(status)."
            )
        }
    }

    /// Lookup query, identical to the helper's.
    func lookupQuery() -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: applicationTag,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecReturnRef: true,
        ]
    }

    /// Key generation attributes, identical to the helper's.
    func generationAttributes() -> [CFString: Any] {
        [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 2048,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: applicationTag,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            ],
        ]
    }

    /// Access for a new key: trusted by the current application and by every
    /// existing, accepted path in `trustedApplicationPaths`. `nil` keeps the
    /// keychain's default access (only the creating application), which is
    /// also the fallback when the access object cannot be built.
    func makeAccess() -> SecAccess? {
        let others: [SecTrustedApplication] = configuration.trustedApplicationPaths.compactMap { path in
            guard FileManager.default.fileExists(atPath: path) else { return nil }
            guard let application = trustedApplication(path) else {
                ActivationLogger.runtime.error(
                    "license key access: skipping an application whose signature does not match LookInside"
                )
                return nil
            }
            return application
        }
        guard others.isEmpty == false else {
            return nil
        }
        var currentApplication: SecTrustedApplication?
        guard SecTrustedApplicationCreateFromPath(nil, &currentApplication) == errSecSuccess,
              let currentApplication
        else {
            return nil
        }
        let applications = [currentApplication] + others
        var access: SecAccess?
        let status = SecAccessCreate(
            Self.accessDescriptor as CFString,
            applications as CFArray,
            &access
        )
        guard status == errSecSuccess else {
            ActivationLogger.runtime.error(
                "keychain access for the new key could not be created, status=\(status, privacy: .public)"
            )
            return nil
        }
        return access
    }

    /// Name the keychain shows for the key in access prompts.
    static let accessDescriptor = "LookInside License Key"

    private func openKeychain() throws -> SecKeychain? {
        guard let path = configuration.keychainPath else {
            return nil
        }
        var keychain: SecKeychain?
        let status = SecKeychainOpen(path, &keychain)
        guard status == errSecSuccess, let keychain else {
            throw ActivationError.keychainFailure("SecKeychainOpen failed with status \(status).")
        }
        return keychain
    }
}
