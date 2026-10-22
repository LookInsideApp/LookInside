import Foundation
@testable import LookInsideActivation
import Security
import Testing

/// The intermediate key must be found by, and findable from, the 2.3.x
/// helper: same tag, class, type, size and attributes, in the file-based
/// login keychain.
struct KeyStoreCompatibilityTests {
    private static let helperTag = Data("com.lookinside.authserver.intermediate-key".utf8)

    /// `AuthServerKeyMaterialStore.existingPrivateKey()` query.
    @Test func lookupQueryMatchesHelper() {
        let store = IntermediateKeyStore(configuration: .standard)
        let helperQuery: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: Self.helperTag,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecReturnRef: true,
        ]
        #expect(NSDictionary(dictionary: store.lookupQuery()) == NSDictionary(dictionary: helperQuery))
    }

    /// `AuthServerKeyMaterialStore.softwareKeyAttributes()`.
    @Test func generationAttributesMatchHelper() {
        let store = IntermediateKeyStore(configuration: .standard)
        let helperAttributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 2048,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: Self.helperTag,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            ],
        ]
        #expect(
            NSDictionary(dictionary: store.generationAttributes()) == NSDictionary(dictionary: helperAttributes)
        )
    }

    @Test func standardQueriesStayOnTheFileBasedKeychain() {
        let store = IntermediateKeyStore(configuration: .standard)
        let forbidden: [CFString] = [kSecUseDataProtectionKeychain, kSecAttrAccessGroup, kSecAttrSynchronizable]
        for key in forbidden {
            #expect(store.lookupQuery()[key] == nil)
            #expect(store.generationAttributes()[key] == nil)
            let privateAttributes = store.generationAttributes()[kSecPrivateKeyAttrs] as? [CFString: Any]
            #expect(privateAttributes?[key] == nil)
        }
        #expect(IntermediateKeyStoreConfiguration.standard.keychainPath == nil)
    }

    /// Creates the key only when absent and reuses it afterwards, in a
    /// temporary keychain under a test-only tag.
    @Test func generatesOnceThenReusesKeyInInjectedKeychain() throws {
        let keychain = try TemporaryKeychain()
        defer { keychain.delete() }
        let store = IntermediateKeyStore(
            configuration: IntermediateKeyStoreConfiguration(
                applicationTag: "com.lookinside.activation.tests.\(UUID().uuidString)",
                keychainPath: keychain.path
            )
        )

        #expect(store.hasPrivateKey() == false)
        let message = Data("lookinside".utf8)
        let first = try store.sign(message: message)
        #expect(store.hasPrivateKey())
        let second = try store.sign(message: message)
        // RSA-PKCS1v15 is deterministic: equal signatures mean the same key.
        #expect(first == second)
        #expect(first.count == 256)

        let csr = try store.makeCertificateSigningRequestPEM(commonName: "LookInside Device test")
        #expect(csr.hasPrefix("-----BEGIN CERTIFICATE REQUEST-----"))

        let reopened = IntermediateKeyStore(configuration: store.configuration)
        #expect(try reopened.sign(message: message) == first)
    }

    @Test func unopenableInjectedKeychainNeverFallsBackToDefaultSearchList() {
        let store = IntermediateKeyStore(
            configuration: IntermediateKeyStoreConfiguration(
                applicationTag: "com.lookinside.activation.tests.\(UUID().uuidString)",
                keychainPath: "/nonexistent/LookInsideActivationTests/missing.keychain-db"
            )
        )
        #expect(store.hasPrivateKey() == false)
    }
}
