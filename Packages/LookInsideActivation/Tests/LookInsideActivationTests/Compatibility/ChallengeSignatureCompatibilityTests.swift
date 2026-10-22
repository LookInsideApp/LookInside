import Foundation
@testable import LookInsideActivation
import Security
import Testing

/// `license.sign_challenge` and `license.check_access` produce exactly what
/// the 2.3.x helper produced for the same state, key and inputs.
struct ChallengeSignatureCompatibilityTests {
    private func helperState() throws -> ActivationPersistedState {
        try ActivationStateCoding.decoder.decode(
            ActivationPersistedState.self,
            from: HelperFixtures.data("helper-state-full.json")
        )
    }

    @Test func checkAccessDecisionMatchesHelperBytes() throws {
        let input = try HelperFixtures.challengeInput()
        let decision = try ActivationAccessEvaluator.decision(from: helperState(), evaluatedAt: input.evaluatedAt)

        #expect(
            try ActivationStateCoding.encoder.encode(decision)
                == (HelperFixtures.data("helper-check-access.json"))
        )
    }

    @Test func signatureMatchesHelperBytes() throws {
        let input = try HelperFixtures.challengeInput()
        let state = try helperState()
        let decision = ActivationAccessEvaluator.decision(from: state, evaluatedAt: input.evaluatedAt)
        let validated = try ActivationChallengeSigner.validate(
            request: ActivationSignChallengeRequest(
                nonce: input.nonce.map { String(format: "%02x", $0) }.joined(),
                serverInstanceID: input.serverInstanceID
            ),
            snapshot: state,
            decision: decision,
            evaluatedAt: input.evaluatedAt
        )
        let signature = try ActivationChallengeSignature(
            signature: IntermediateKeyStore.sign(
                message: validated.message,
                with: HelperFixtures.testPrivateKey(input)
            ),
            intermediateCertificateDER: validated.certificateDER,
            udid: validated.lease.udid
        )

        #expect(
            try ActivationStateCoding.encoder.encode(signature.responsePayload)
                == (HelperFixtures.data("helper-sign-challenge.json"))
        )
    }

    @Test func expiredLeaseIsRefusedWithHelperCodeAndMessage() throws {
        let input = try HelperFixtures.challengeInput()
        let expected = try HelperFixtures.jsonObject("helper-sign-challenge-expired.json")
        let state = try helperState()
        let decision = ActivationAccessEvaluator.decision(from: state, evaluatedAt: input.expiredAt)
        #expect(decision.decision.rawValue == expected["decision"] as? String)

        do {
            _ = try ActivationChallengeSigner.validate(
                request: ActivationSignChallengeRequest(
                    nonce: input.nonce.map { String(format: "%02x", $0) }.joined(),
                    serverInstanceID: input.serverInstanceID
                ),
                snapshot: state,
                decision: decision,
                evaluatedAt: input.expiredAt
            )
            Issue.record("expected a refusal")
        } catch let error as ActivationError {
            #expect(error.errorCode == expected["code"] as? String)
            #expect(error.localizedDescription == expected["message"] as? String)
        }
    }

    /// Full in-process path: the runtime reads the helper's `state.json`,
    /// creates the key under its tag in an injected keychain and answers with
    /// the helper's certificate and UDID and a signature over the same message
    /// the helper signed. (Legacy keychains cannot take an imported key under
    /// an application tag, so the byte-identical signature for a fixed key is
    /// covered by `signatureMatchesHelperBytes`.)
    @Test func runtimeSignChallengeMatchesHelperPayload() async throws {
        let input = try HelperFixtures.challengeInput()
        let keychain = try TemporaryKeychain()
        defer { keychain.delete() }
        let keyStoreConfiguration = IntermediateKeyStoreConfiguration(
            applicationTag: "com.lookinside.activation.tests.\(UUID().uuidString)",
            keychainPath: keychain.path
        )

        let directory = try HelperFixtures.makeStateDirectory(copying: "helper-state-full.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(
                stateDirectoryURL: directory,
                keyStore: keyStoreConfiguration
            ),
            urlSession: .shared,
            now: { input.evaluatedAt },
            silentRenewalEnabled: false
        )
        // The Host lets handshakes sign once its first window is up.
        runtime.noteFirstWindowShown()

        let signature = try await runtime.signChallenge(nonce: input.nonce, serverInstanceID: input.serverInstanceID)
        let helperPayload = try ActivationStateCoding.decoder.decode(
            ActivationSignChallengeResponsePayload.self,
            from: HelperFixtures.data("helper-sign-challenge.json")
        )
        #expect(signature.responsePayload.intermediateCertDER == helperPayload.intermediateCertDER)
        #expect(signature.responsePayload.udid == helperPayload.udid)

        var message = input.nonce
        message.append(Data(input.serverInstanceID.utf8))
        let runtimePublicKey = try #require(
            try SecKeyCopyPublicKey(Self.storedPrivateKey(keyStoreConfiguration, keychain: keychain))
        )
        #expect(Self.verify(signature.signature, message: message, publicKey: runtimePublicKey))
        let helperPublicKey = try #require(try SecKeyCopyPublicKey(HelperFixtures.testPrivateKey(input)))
        let helperSignature = try #require(Data(base64Encoded: helperPayload.signature))
        #expect(Self.verify(helperSignature, message: message, publicKey: helperPublicKey))

        let blocking = try await Task.detached {
            try runtime.signChallengeBlocking(nonce: input.nonce, serverInstanceID: input.serverInstanceID)
        }.value
        #expect(blocking == signature)
    }

    private static func storedPrivateKey(
        _ configuration: IntermediateKeyStoreConfiguration,
        keychain: TemporaryKeychain
    ) throws -> SecKey {
        var query = IntermediateKeyStore(configuration: configuration).lookupQuery()
        query[kSecMatchSearchList] = try [#require(keychain.keychain)]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let item else {
            throw HelperFixtures.FixtureError.malformed("stored key lookup failed: \(status)")
        }
        return item as! SecKey
    }

    private static func verify(_ signature: Data, message: Data, publicKey: SecKey) -> Bool {
        SecKeyVerifySignature(
            publicKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            message as CFData,
            signature as CFData,
            nil
        )
    }
}
