import Foundation
@testable import LookInsideActivation
import Security
import Testing

/// Keychain lookups that fail for any reason other than "not found" must
/// never lead to a new key: an upgraded user who cancels the first-access
/// prompt still owns the helper's key, and a second key under the same tag
/// would break the existing activation.
struct KeychainAccessTests {
    private final class Recorder: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0

        func increment() {
            lock.withLock { count += 1 }
        }

        var value: Int {
            lock.withLock { count }
        }
    }

    private func makeStore(lookupStatus: OSStatus, generations: Recorder) -> IntermediateKeyStore {
        IntermediateKeyStore(
            configuration: IntermediateKeyStoreConfiguration(
                applicationTag: "com.lookinside.activation.tests.\(UUID().uuidString)"
            ),
            operations: IntermediateKeychainOperations(
                copyMatching: { _, _ in lookupStatus },
                createRandomKey: { _, _ in
                    generations.increment()
                    return nil
                }
            )
        )
    }

    @Test(arguments: [
        errSecUserCanceled,
        errSecAuthFailed,
        errSecInteractionNotAllowed,
    ])
    func deniedLookupThrowsAccessDeniedWithoutGenerating(status: OSStatus) {
        let generations = Recorder()
        let store = makeStore(lookupStatus: status, generations: generations)

        #expect(throws: ActivationError.keychainAccessDenied(status)) {
            try store.sign(message: Data("lookinside".utf8))
        }
        #expect(throws: ActivationError.keychainAccessDenied(status)) {
            try store.makeCertificateSigningRequestPEM(commonName: "LookInside Device test")
        }
        #expect(store.hasPrivateKey() == false)
        #expect(generations.value == 0)
    }

    @Test(arguments: [errSecNotAvailable, errSecDecode, errSecParam, errSecNoSuchKeychain])
    func otherLookupFailuresThrowWithoutGenerating(status: OSStatus) {
        let generations = Recorder()
        let store = makeStore(lookupStatus: status, generations: generations)

        #expect {
            try store.sign(message: Data("lookinside".utf8))
        } throws: { error in
            guard case .keychainFailure = error as? ActivationError else { return false }
            return true
        }
        #expect(generations.value == 0)
    }

    @Test func onlyItemNotFoundGeneratesAKey() {
        let generations = Recorder()
        let store = makeStore(lookupStatus: errSecItemNotFound, generations: generations)

        // The fake generator returns no key, so signing still fails, but only
        // after it was asked to create one.
        #expect(throws: ActivationError.self) {
            try store.sign(message: Data("lookinside".utf8))
        }
        #expect(generations.value == 1)
    }

    @Test func deniedStatusesMapToAccessDeniedAndKeepTheHelperCode() {
        #expect(ActivationError.keychain(status: errSecUserCanceled, message: "m") == .keychainAccessDenied(-128))
        #expect(ActivationError.keychain(status: errSecParam, message: "m") == .keychainFailure("m"))
        #expect(ActivationError.keychainAccessDenied(-128).errorCode == "keychain_failure")
    }

    /// A key the Host creates also trusts the installed 2.3.x helper, so an
    /// older LookInside can still sign after a downgrade without a prompt.
    @Test func newKeyTrustsConfiguredApplications() throws {
        // A test must never wait on a keychain prompt. The setting is
        // process-wide, so it is put back afterwards.
        var interactionAllowed: DarwinBoolean = true
        SecKeychainGetUserInteractionAllowed(&interactionAllowed)
        SecKeychainSetUserInteractionAllowed(false)
        defer { SecKeychainSetUserInteractionAllowed(interactionAllowed.boolValue) }
        let keychain = try TemporaryKeychain()
        defer { keychain.delete() }
        let trustedPath = "/usr/bin/security"
        let store = IntermediateKeyStore(
            configuration: IntermediateKeyStoreConfiguration(
                applicationTag: "com.lookinside.activation.tests.\(UUID().uuidString)",
                keychainPath: keychain.path,
                trustedApplicationPaths: [trustedPath, "/nonexistent/lookinside-auth-server.app"]
            ),
            trustedApplication: { path in
                var application: SecTrustedApplication?
                SecTrustedApplicationCreateFromPath(path, &application)
                return application
            }
        )

        let message = Data("lookinside".utf8)
        let signature = try store.sign(message: message)
        #expect(signature.count == 256)
        #expect(try store.sign(message: message) == signature)

        let key = try #require(try store.existingPrivateKey())
        var access: SecAccess?
        #expect(SecKeychainItemCopyAccess(unsafeBitCast(key, to: SecKeychainItem.self), &access) == errSecSuccess)
        let trustedPaths = try Self.trustedApplicationPaths(in: #require(access))
        #expect(trustedPaths.contains(trustedPath))
        #expect(trustedPaths.contains { $0.contains("lookinside-auth-server") } == false)
    }

    @Test func keyWithoutExistingTrustedPathsKeepsDefaultAccess() {
        let store = IntermediateKeyStore(
            configuration: IntermediateKeyStoreConfiguration(
                applicationTag: "com.lookinside.activation.tests.\(UUID().uuidString)",
                trustedApplicationPaths: ["/nonexistent/lookinside-auth-server.app"]
            )
        )
        #expect(store.makeAccess() == nil)
    }

    /// The helper path is user-writable: a bundle there whose signature the
    /// store does not accept never joins the key's access list.
    @Test func applicationWithRejectedSignatureIsNotTrusted() {
        let checked = Recorder()
        let store = IntermediateKeyStore(
            configuration: IntermediateKeyStoreConfiguration(
                applicationTag: "com.lookinside.activation.tests.\(UUID().uuidString)",
                trustedApplicationPaths: ["/usr/bin/security"]
            ),
            trustedApplication: { _ in
                checked.increment()
                return nil
            }
        )
        #expect(store.makeAccess() == nil)
        #expect(checked.value == 1)
    }

    @Test func standardConfigurationTrustsTheInstalledHelper() {
        let paths = IntermediateKeyStoreConfiguration.standard.trustedApplicationPaths
        #expect(paths.count == 1)
        #expect(
            paths.first?.hasSuffix(
                "Library/Application Support/LookInside/AuthServer/current/lookinside-auth-server.app"
            ) == true
        )
    }

    private static func trustedApplicationPaths(in access: SecAccess) -> [String] {
        var aclList: CFArray?
        guard SecAccessCopyACLList(access, &aclList) == errSecSuccess,
              let acls = aclList as? [SecACL]
        else {
            return []
        }
        var paths: [String] = []
        for acl in acls {
            var applications: CFArray?
            var description: CFString?
            var selector = SecKeychainPromptSelector()
            guard SecACLCopyContents(acl, &applications, &description, &selector) == errSecSuccess,
                  let applications = applications as? [SecTrustedApplication]
            else {
                continue
            }
            for application in applications {
                var data: CFData?
                guard SecTrustedApplicationCopyData(application, &data) == errSecSuccess,
                      let bytes = data as Data?
                else {
                    continue
                }
                let path = String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
                paths.append(path)
            }
        }
        return paths
    }
}

struct DeviceFingerprintTests {
    @Test func missingPlatformUUIDThrowsInsteadOfCrashing() {
        #expect {
            try ActivationDeviceFingerprint.current(platformUUID: { nil })
        } throws: { error in
            guard case .activationFailed = error as? ActivationError else { return false }
            return true
        }
        #expect(throws: ActivationError.self) {
            try ActivationDeviceFingerprint.current(platformUUID: { "" })
        }
    }

    @Test func platformUUIDBecomesTheDeviceID() throws {
        let fingerprint = try ActivationDeviceFingerprint.current(
            appBundleID: "app.lookinside.LookInsideAuthServer",
            platformUUID: { "00000000-0000-4000-8000-000000000001" }
        )
        #expect(fingerprint.deviceID == "00000000-0000-4000-8000-000000000001")
        #expect(fingerprint.appBundleID == "app.lookinside.LookInsideAuthServer")
    }
}

/// The installed helper joins a new key's access list only when its code
/// signature matches the helper's own requirement and the running Host's
/// team, and the bundle did not change while the entry was made.
struct TrustedApplicationSignatureTests {
    private final class Calls: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [String] = []

        func append(_ call: String) {
            lock.withLock { stored.append(call) }
        }

        var values: [String] {
            lock.withLock { stored }
        }
    }

    private static func operations(
        calls: Calls,
        hashBefore: Data?,
        hashAfter: Data?
    ) -> TrustedApplicationSignature.Operations {
        TrustedApplicationSignature.Operations(
            codeDirectoryHash: { _ in
                calls.append("hash")
                return hashBefore
            },
            makeApplication: { _ in
                calls.append("make")
                var application: SecTrustedApplication?
                SecTrustedApplicationCreateFromPath("/usr/bin/security", &application)
                return application
            },
            validatedCodeDirectoryHash: { _, requirement in
                calls.append("validate \(requirement)")
                return hashAfter
            }
        )
    }

    @Test func requirementMatchesTheHelperValidator() throws {
        let requirement = try #require(TrustedApplicationSignature.requirement(forTeamID: "ABCDE12345"))
        #expect(requirement.hasPrefix("anchor apple generic and "))
        #expect(requirement.contains(#"identifier "app.lookinside.LookInsideAuthServer""#))
        #expect(requirement.contains(#"certificate leaf[subject.OU] = "ABCDE12345""#))
        #expect(requirement.contains("certificate leaf[field.1.2.840.113635.100.6.1.9]"))
        #expect(requirement.contains("certificate 1[field.1.2.840.113635.100.6.2.6]"))
        #expect(requirement.contains("certificate leaf[field.1.2.840.113635.100.6.1.13]"))
        var parsed: SecRequirement?
        #expect(SecRequirementCreateWithString(requirement as CFString, [], &parsed) == errSecSuccess)
        #expect(parsed != nil)
    }

    @Test(arguments: [nil, "", "abcde12345", "ABCDE1234", #"A" or true"#, "ABCDE12345 "])
    func noRequirementWithoutAValidTeam(teamID: String?) {
        #expect(TrustedApplicationSignature.requirement(forTeamID: teamID) == nil)
    }

    @Test func noRequirementForAnUnsafeIdentifier() {
        #expect(TrustedApplicationSignature.requirement(forTeamID: "ABCDE12345", identifier: #"x" or true"#) == nil)
    }

    @Test func adHocHostTrustsNothingAndNeverChecks() {
        let calls = Calls()
        let trusted = TrustedApplicationSignature.trustedApplication(
            atPath: "/p",
            hostTeamID: nil,
            operations: Self.operations(calls: calls, hashBefore: Data([1]), hashAfter: Data([1]))
        )
        #expect(trusted == nil)
        #expect(calls.values.isEmpty)
    }

    /// The entry is made before the check, and the bundle must be the same
    /// before and after.
    @Test func entryIsMadeFirstAndCheckedAfter() throws {
        let calls = Calls()
        let trusted = TrustedApplicationSignature.trustedApplication(
            atPath: "/p",
            hostTeamID: "ABCDE12345",
            operations: Self.operations(calls: calls, hashBefore: Data([1]), hashAfter: Data([1]))
        )
        #expect(trusted != nil)
        let requirement = try #require(TrustedApplicationSignature.requirement(forTeamID: "ABCDE12345"))
        #expect(calls.values == ["hash", "make", "validate \(requirement)"])
    }

    @Test func bundleReplacedDuringTheCheckIsRefused() {
        #expect(
            TrustedApplicationSignature.trustedApplication(
                atPath: "/p",
                hostTeamID: "ABCDE12345",
                operations: Self.operations(
                    calls: Calls(),
                    hashBefore: Data([1]),
                    hashAfter: Data([2])
                )
            ) == nil
        )
    }

    @Test func failedCheckOrUnsignedBundleIsRefused() {
        for (before, after) in [(Data([1]), nil), (nil, Data([1]))] as [(Data?, Data?)] {
            let calls = Calls()
            #expect(
                TrustedApplicationSignature.trustedApplication(
                    atPath: "/p",
                    hostTeamID: "ABCDE12345",
                    operations: Self.operations(calls: calls, hashBefore: before, hashAfter: after)
                ) == nil
            )
            if before == nil {
                #expect(calls.values == ["hash"])
            }
        }
    }

    /// The real check: an Apple platform binary satisfies an Apple anchor
    /// requirement but not the helper's requirement, and a missing path
    /// satisfies nothing.
    @Test func staticCodeCheckUsesTheBundleSignature() throws {
        #expect(TrustedApplicationSignature.staticCodeSatisfies(path: "/usr/bin/security", requirement: "anchor apple"))
        #expect(TrustedApplicationSignature.codeDirectoryHash(path: "/usr/bin/security", requirement: nil) != nil)
        let helperRequirement = try #require(TrustedApplicationSignature.requirement(forTeamID: "ABCDE12345"))
        #expect(
            TrustedApplicationSignature.staticCodeSatisfies(path: "/usr/bin/security", requirement: helperRequirement)
                == false
        )
        #expect(
            TrustedApplicationSignature.staticCodeSatisfies(
                path: "/nonexistent/lookinside-auth-server.app",
                requirement: "anchor apple"
            ) == false
        )
    }
}
