import Foundation
@testable import LookInsideActivation
import Security

/// Fixtures produced by running the original 2.3.x Auth helper code
/// (`Scripts/reborn-activation-fixtures/generate.sh`).
enum HelperFixtures {
    static func url(_ name: String) throws -> URL {
        guard let root = Bundle.module.resourceURL else {
            throw FixtureError.missing(name)
        }
        let url = root.appendingPathComponent("Fixtures", isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FixtureError.missing(name)
        }
        return url
    }

    static func data(_ name: String) throws -> Data {
        try Data(contentsOf: url(name))
    }

    static func jsonObject(_ name: String) throws -> NSDictionary {
        try jsonObject(data(name))
    }

    static func jsonObject(_ data: Data) throws -> NSDictionary {
        guard let object = try JSONSerialization.jsonObject(with: data) as? NSDictionary else {
            throw FixtureError.notAnObject
        }
        return object
    }

    /// Inputs the generator used for the challenge fixtures.
    struct ChallengeInput {
        let nonce: Data
        let serverInstanceID: String
        let evaluatedAt: Date
        let expiredAt: Date
        let testOnlyPrivateKeyDER: Data
    }

    static func challengeInput() throws -> ChallengeInput {
        let object = try jsonObject("challenge-input.json")
        guard let nonceHex = object["nonceHex"] as? String,
              let nonce = Data(hexString: nonceHex),
              let serverInstanceID = object["serverInstanceID"] as? String,
              let evaluatedAt = object["evaluatedAt"] as? Double,
              let expiredAt = object["expiredAt"] as? Double,
              let keyBase64 = object["testOnlyPrivateKeyPKCS1DERBase64"] as? String,
              let keyDER = Data(base64Encoded: keyBase64)
        else {
            throw FixtureError.malformed("challenge-input.json")
        }
        return ChallengeInput(
            nonce: nonce,
            serverInstanceID: serverInstanceID,
            evaluatedAt: Date(timeIntervalSince1970: evaluatedAt),
            expiredAt: Date(timeIntervalSince1970: expiredAt),
            testOnlyPrivateKeyDER: keyDER
        )
    }

    static func testPrivateKey(_ input: ChallengeInput) throws -> SecKey {
        var error: Unmanaged<CFError>?
        guard
            let key = SecKeyCreateWithData(
                input.testOnlyPrivateKeyDER as CFData,
                [kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeyClass: kSecAttrKeyClassPrivate] as CFDictionary,
                &error
            )
        else {
            throw FixtureError.malformed("test key: \(String(describing: error?.takeRetainedValue()))")
        }
        return key
    }

    /// Copies a fixture into a fresh temporary directory as `state.json` and
    /// returns that directory.
    static func makeStateDirectory(copying fixture: String? = nil) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LookInsideActivationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let fixture {
            try FileManager.default.copyItem(
                at: url(fixture),
                to: directory.appendingPathComponent("state.json", isDirectory: false)
            )
        }
        return directory
    }

    /// Configuration that never touches the real state, key or service: a
    /// temporary state directory, a test-only key tag and an unreachable
    /// local service URL.
    static func isolatedConfiguration(
        stateDirectoryURL: URL,
        keyStore: IntermediateKeyStoreConfiguration? = nil
    ) -> ActivationConfiguration {
        ActivationConfiguration(
            stateDirectoryURL: stateDirectoryURL,
            keyStore: keyStore
                ?? IntermediateKeyStoreConfiguration(
                    applicationTag: "com.lookinside.activation.tests.unused-\(UUID().uuidString)",
                    keychainPath: stateDirectoryURL.appendingPathComponent("missing.keychain-db").path
                ),
            serviceBaseURL: URL(string: "http://127.0.0.1:9")!
        )
    }

    enum FixtureError: Error {
        case missing(String)
        case notAnObject
        case malformed(String)
    }
}

/// Rebuilds the values the fixture generator recorded, with the same fixed
/// clock, so the new store can replay the generator's writes.
enum HelperFixtureValues {
    static let base = Date(timeIntervalSince1970: 1_767_225_600) // 2026-01-01T00:00:00Z
    static let day: TimeInterval = 24 * 60 * 60
    static let udid = "00000000-0000-4000-8000-00000000F1A7"

    static let fingerprint = DeviceFingerprint(
        deviceID: udid,
        hardwareModel: "Mac15,6",
        operatingSystemVersion: "Version 15.4 (Build 24E248)",
        appBundleID: "app.lookinside.LookInsideAuthServer"
    )

    /// The generator stored a freshly created self-signed certificate; read
    /// it back from the full-state fixture (without our decoder).
    static func certificatePEM() throws -> String {
        let object = try HelperFixtures.jsonObject("helper-state-full.json")
        guard let status = object["entitlementStatus"] as? NSDictionary,
              let lease = status["currentLease"] as? NSDictionary,
              let pem = lease["certificatePEM"] as? String
        else {
            throw HelperFixtures.FixtureError.malformed("helper-state-full.json")
        }
        return pem
    }

    static func session(licenseID: String, token: String) -> ActivationSession {
        ActivationSession(
            sessionID: "ses_fixture_\(licenseID)",
            licenseID: licenseID,
            orderID: "ord_fixture",
            email: "fixture@example.invalid",
            deviceIdentifier: udid,
            token: token,
            expiresAt: base.addingTimeInterval(3 * day),
            createdAt: base.addingTimeInterval(-day)
        )
    }

    static func lease(licenseID: String, expiresIn: TimeInterval, certificatePEM: String)
        -> IntermediateCertificateLease
    {
        IntermediateCertificateLease(
            certificateID: "int_fixture_\(licenseID)",
            licenseID: licenseID,
            udid: udid,
            issuedAt: base.addingTimeInterval(-5 * day),
            expiresAt: base.addingTimeInterval(expiresIn),
            renewAfter: base.addingTimeInterval(20 * day),
            issuanceReason: .initialActivation,
            certificatePEM: certificatePEM,
            publicKeyPEM: "-----BEGIN PUBLIC KEY-----\nZml4dHVyZQ==\n-----END PUBLIC KEY-----\n",
            fullChainPEM: certificatePEM,
            status: .active
        )
    }

    static func status(
        licenseClass: LicenseClass,
        lease: IntermediateCertificateLease,
        session: ActivationSession
    ) -> EntitlementStatus {
        let license = LicenseEnvelope(
            licenseID: lease.licenseID,
            audience: .personal,
            licenseClass: licenseClass,
            lifecycleState: .active,
            issuedTo: "fixture@example.invalid",
            issuedAt: base.addingTimeInterval(-150 * day),
            expiresAt: base.addingTimeInterval(215 * day),
            serviceEndsAt: base.addingTimeInterval(215 * day),
            nextCertificateRenewalAt: lease.renewAfter,
            deviceWarning: nil,
            certificateChain: CertificateChain(
                rootCertificateID: EmbeddedTrustedRoots.rootProd2026.certificateID,
                intermediateCertificateID: lease.certificateID,
                intermediateIssuedAt: lease.issuedAt,
                intermediateExpiresAt: lease.expiresAt,
                renewAfter: lease.renewAfter,
                boundUDID: udid
            )
        )
        return EntitlementStatus(
            license: license,
            deviceBinding: DeviceBinding(
                licenseID: lease.licenseID,
                udid: udid,
                machineName: "Fixture Mac",
                hardwareModel: fingerprint.hardwareModel,
                operatingSystemVersion: fingerprint.operatingSystemVersion,
                appBundleID: fingerprint.appBundleID,
                firstSeenAt: base.addingTimeInterval(-150 * day),
                lastSeenAt: base.addingTimeInterval(-day)
            ),
            currentLease: lease,
            activationSession: session,
            isEligibleForActivation: true,
            isEligibleForRenewal: true,
            requiresLiveRefresh: false,
            lastFetchedAt: base.addingTimeInterval(-day),
            informationalMessage: "Fixture info",
            warningMessage: nil
        )
    }

    static func activationResponse(lease: IntermediateCertificateLease) -> HostActivationResponse {
        HostActivationResponse(
            activation: SignedActivationEnvelope(
                activationID: "act_fixture",
                challengeNonce: "nonce_fixture",
                licenseID: lease.licenseID,
                issuedAt: base.addingTimeInterval(-day),
                expiresAt: base.addingTimeInterval(25 * day),
                intermediateCertificateID: lease.certificateID,
                boundUDID: udid,
                artifacts: [
                    ActivationArtifact(
                        name: "activation.json",
                        payload: Data(#"{"device_id":"fixture","license_id":"lic_fixture_full"}"#.utf8),
                        digest: "00ff"
                    ),
                ]
            ),
            path: .direct,
            secureTimestamp: SecureTimestampToken(
                challengeNonce: "nonce_fixture",
                signedAt: base.addingTimeInterval(-day),
                rootCertificateID: EmbeddedTrustedRoots.rootProd2026.certificateID,
                signature: Data([1, 2, 3, 4])
            )
        )
    }
}

/// A temporary file-based keychain, deleted (and removed from the search
/// list) by `delete()`. Never the login keychain.
final class TemporaryKeychain {
    let directory: URL
    let path: String
    private(set) var keychain: SecKeychain?

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LookInsideActivationKeychain-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        path = directory.appendingPathComponent("test.keychain-db").path
        let password = UUID().uuidString
        var created: SecKeychain?
        let status = SecKeychainCreate(path, UInt32(password.utf8.count), password, false, nil, &created)
        guard status == errSecSuccess, let created else {
            throw HelperFixtures.FixtureError.malformed("SecKeychainCreate failed: \(status)")
        }
        keychain = created
    }

    func delete() {
        if let keychain {
            SecKeychainDelete(keychain)
        }
        keychain = nil
        try? FileManager.default.removeItem(at: directory)
    }
}
