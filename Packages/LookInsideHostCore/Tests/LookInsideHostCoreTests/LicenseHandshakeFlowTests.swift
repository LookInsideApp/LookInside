import Foundation
@testable import LookInsideHostCore
import Testing

/// A scripted channel, signing policy and license key. Every answer is
/// given synchronously, in the order the test queued it.
@MainActor
private final class FakeEnvironment: LicenseHandshakeEnvironment {
    var isChannelConnected = true
    var clock: TimeInterval = 1000
    var policyAnswers: [Bool] = []
    var challengeAnswers: [LicenseExchangeResult] = []
    var verifyAnswers: [LicenseExchangeResult] = []
    /// Each signing takes `duration` on the clock and returns `signing`.
    var signings: [(duration: TimeInterval, signing: LicenseSigning)] = []

    private(set) var policyQuestions = 0
    private(set) var failuresNoted = 0
    private(set) var challengesSent = 0
    private(set) var signedChallenges: [LicenseChallenge] = []
    private(set) var verifyRequests: [LicenseVerifyRequest] = []
    private(set) var logs: [String] = []
    private(set) var serverReleases: [ServerRelease] = []

    func now() -> TimeInterval {
        clock
    }

    func shouldStartHandshake() -> Bool {
        policyQuestions += 1
        return policyAnswers.isEmpty ? true : policyAnswers.removeFirst()
    }

    func noteHandshakeFailed() {
        failuresNoted += 1
    }

    func sendChallenge(completion: @escaping (LicenseExchangeResult) -> Void) {
        challengesSent += 1
        completion(challengeAnswers.removeFirst())
    }

    func sendVerify(_ request: LicenseVerifyRequest, completion: @escaping (LicenseExchangeResult) -> Void) {
        verifyRequests.append(request)
        completion(verifyAnswers.removeFirst())
    }

    func sign(_ challenge: LicenseChallenge, completion: @escaping (LicenseSigning) -> Void) {
        signedChallenges.append(challenge)
        let next = signings.removeFirst()
        clock += next.duration
        var signing = next.signing
        signing.finishedAt = clock
        completion(signing)
    }

    func noteServerRelease(_ release: ServerRelease) {
        serverReleases.append(release)
    }

    func log(_ message: String) {
        logs.append(message)
    }
}

@MainActor
struct LicenseHandshakeFlowTests {
    private static let nonce = Data((0 ..< 32).map { UInt8($0) })

    private static func challengePayload(serverID: String = "server-1") -> NSDictionary {
        [
            "nonce": nonce as NSData,
            "server_instance_id": serverID as NSString,
            "issued_at": NSNumber(value: 1),
            "ttl": NSNumber(value: 120),
        ]
    }

    private static let challengeOK = LicenseExchangeResult.response(error: nil, payload: challengePayload())
    private static let accepted = LicenseExchangeResult.response(error: nil, payload: nil)

    private static func serverError(_ code: Int) -> NSError {
        NSError(domain: "LookinError", code: code)
    }

    private static func signed(keyUse: TimeInterval = 0.2, udid: String? = "UDID-1") -> LicenseSigning {
        LicenseSigning(
            signature: Data(repeating: 1, count: 256),
            intermediateCertificateDER: Data(repeating: 2, count: 900),
            udid: udid,
            keyUseDuration: keyUse,
            finishedAt: 0
        )
    }

    /// Runs the flow and returns its outcome; the fake answers synchronously.
    private func run(_ environment: FakeEnvironment) -> LicenseHandshakeFailure?? {
        var outcome: LicenseHandshakeFailure??
        LicenseHandshakeFlow.run(in: environment, channelDescription: "0x1") { outcome = .some($0) }
        return outcome
    }

    @Test func acceptedSignatureLicensesTheChannel() throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK]
        environment.signings = [(1, Self.signed())]
        environment.verifyAnswers = [Self.accepted]

        let outcome = try #require(run(environment))
        #expect(outcome == nil)
        #expect(environment.signedChallenges == [LicenseChallenge(nonce: Self.nonce, serverInstanceID: "server-1")])
        let request = try #require(environment.verifyRequests.first)
        #expect(request.signature.count == 256)
        #expect(request.intermediateCertificateDER.count == 900)
        #expect(request.udid == "UDID-1")
        // The 220's own payload goes back for its nonce and server id objects.
        #expect((request.challengePayload as? NSDictionary) == Self.challengePayload())
        #expect(environment.failuresNoted == 0)
        // The first attempt is cleared by the caller; the flow does not ask.
        #expect(environment.policyQuestions == 0)
        #expect(environment.logs.last == "LookInside - License: 221 verify accepted; channel 0x1 marked licensed.")
    }

    /// A released 0.2.9 Server sends no version keys; the handshake runs
    /// as before and the 221 carries nothing extra.
    @Test func legacyChallengeWithoutReleaseKeysIsHandled() throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK]
        environment.signings = [(1, Self.signed())]
        environment.verifyAnswers = [Self.accepted]

        let outcome = try #require(run(environment))
        #expect(outcome == nil)
        #expect(environment.serverReleases == [ServerRelease(version: nil, build: nil)])
        #expect(environment.serverReleases.first?.suggestsUpgrade == true)
        #expect(environment.logs.contains("LookInside - License: 220 Server release <none> (build <none>)."))
    }

    @Test func challengeReleaseKeysAreReportedAndIgnoredByTheHandshake() throws {
        let environment = FakeEnvironment()
        let payload = NSMutableDictionary(dictionary: Self.challengePayload())
        payload["lookinside_server_version"] = "dev" as NSString
        payload["lookinside_server_build"] = NSNumber(value: 0)
        environment.challengeAnswers = [.response(error: nil, payload: payload)]
        environment.signings = [(1, Self.signed())]
        environment.verifyAnswers = [Self.accepted]

        let outcome = try #require(run(environment))
        #expect(outcome == nil)
        #expect(environment.signedChallenges == [LicenseChallenge(nonce: Self.nonce, serverInstanceID: "server-1")])
        #expect(environment.serverReleases == [ServerRelease(version: "dev", build: 0)])
        #expect(environment.serverReleases.first?.suggestsUpgrade == false)
    }

    @Test func missingUDIDIsSentEmpty() {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK]
        environment.signings = [(1, Self.signed(udid: nil))]
        environment.verifyAnswers = [Self.accepted]
        _ = run(environment)
        #expect(environment.verifyRequests.first?.udid == "")
        #expect(environment.logs.contains { $0.contains("udid=<none>") })
    }

    @Test func challengeErrorIsRememberedForTheChannel() throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [.response(error: Self.serverError(-408), payload: nil)]

        let outcome = try #require(run(environment))
        guard case let .challengeRejected(error)? = outcome else {
            Issue.record("unexpected outcome \(String(describing: outcome))")
            return
        }
        #expect(error.code == -408)
        #expect(environment.failuresNoted == 1)
        #expect(environment.signedChallenges.isEmpty)
    }

    @Test func malformedChallengeIsRememberedForTheChannel() throws {
        let environment = FakeEnvironment()
        let shortNonce: NSDictionary = ["nonce": Data(count: 16) as NSData, "server_instance_id": "s" as NSString]
        environment.challengeAnswers = [.response(error: nil, payload: shortNonce)]

        let outcome = try #require(run(environment))
        guard case let .malformedChallenge(malformed)? = outcome else {
            Issue.record("unexpected outcome \(String(describing: outcome))")
            return
        }
        #expect(malformed == LicenseChallenge.Malformed(nonceLength: 16, serverInstanceIDLength: 1))
        #expect(environment.failuresNoted == 1)
        #expect(environment.logs.contains("LookInside - License: 220 challenge payload malformed (nonce_len=16, server_instance_id_len=1)."))
    }

    @Test func transportErrorsAreNotRemembered() throws {
        let challengeFailure = FakeEnvironment()
        challengeFailure.challengeAnswers = [.transportFailure(Self.serverError(-405))]
        let first = try #require(run(challengeFailure))
        guard case .challengeTransport? = first else {
            Issue.record("unexpected outcome \(String(describing: first))")
            return
        }
        #expect(challengeFailure.failuresNoted == 0)

        let verifyFailure = FakeEnvironment()
        verifyFailure.challengeAnswers = [Self.challengeOK]
        verifyFailure.signings = [(1, Self.signed())]
        verifyFailure.verifyAnswers = [.transportFailure(Self.serverError(-403))]
        let second = try #require(run(verifyFailure))
        guard case .verifyTransport? = second else {
            Issue.record("unexpected outcome \(String(describing: second))")
            return
        }
        #expect(verifyFailure.failuresNoted == 0)
    }

    @Test(arguments: [
        LicenseSigning(failureDescription: "keychain refused", failed: true, finishedAt: 0),
        LicenseSigning(signature: Data(), intermediateCertificateDER: Data([1]), finishedAt: 0),
        LicenseSigning(signature: Data([1]), intermediateCertificateDER: nil, finishedAt: 0),
    ])
    func failedSigningEndsTheHandshakeWithoutRetry(signing: LicenseSigning) throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK]
        // Slow as well: a failed signing is never retried.
        environment.signings = [(500, signing)]

        let outcome = try #require(run(environment))
        guard case let .signingFailed(detail)? = outcome else {
            Issue.record("unexpected outcome \(String(describing: outcome))")
            return
        }
        #expect(detail == signing.failureDescription)
        #expect(environment.challengesSent == 1)
        #expect(environment.verifyRequests.isEmpty)
        // The activation runtime records signing failures itself.
        #expect(environment.failuresNoted == 0)
    }

    @Test func slowSignatureAsksForAFreshChallengeOnce() throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK, .response(error: nil, payload: Self.challengePayload(serverID: "server-2"))]
        // Both signings are slow; only the first one retries.
        environment.signings = [(100, Self.signed(keyUse: 90)), (150, Self.signed(keyUse: 140))]
        environment.verifyAnswers = [Self.accepted]

        let outcome = try #require(run(environment))
        #expect(outcome == nil)
        #expect(environment.challengesSent == 2)
        #expect(environment.policyQuestions == 1)
        #expect(environment.verifyRequests.map(\.challenge.serverInstanceID) == ["server-2"])
        #expect(environment.logs.contains(
            "LookInside - License: the signature arrived 100s after the challenge (key use 90s), past its lifetime; requesting a fresh 220."
        ))
    }

    @Test func signatureJustUnderTheLimitIsSent() throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK]
        environment.signings = [(99.5, Self.signed())]
        environment.verifyAnswers = [Self.accepted]
        #expect(try #require(run(environment)) == nil)
        #expect(environment.challengesSent == 1)
    }

    @Test func retryHeldBackByTheSigningPolicy() throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK]
        environment.signings = [(120, Self.signed())]
        environment.policyAnswers = [false]

        let outcome = try #require(run(environment))
        guard case .retryHeldBack? = outcome else {
            Issue.record("unexpected outcome \(String(describing: outcome))")
            return
        }
        #expect(environment.challengesSent == 1)
        #expect(environment.verifyRequests.isEmpty)
        #expect(environment.logs.last == "LookInside - License: the signing policy holds the retry back on channel 0x1.")
    }

    @Test func retryHeldBackWhenTheChannelIsGone() throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK]
        environment.signings = [(120, Self.signed())]
        environment.isChannelConnected = false

        let outcome = try #require(run(environment))
        guard case .retryHeldBack? = outcome else {
            Issue.record("unexpected outcome \(String(describing: outcome))")
            return
        }
        // The policy is not asked for a disconnected channel.
        #expect(environment.policyQuestions == 0)
    }

    @Test func rejectionAfterASlowKeyUseRetriesOnceThenIsRemembered() throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK, Self.challengeOK]
        environment.signings = [(31, Self.signed(keyUse: 30)), (40, Self.signed(keyUse: 40))]
        environment.verifyAnswers = [
            .response(error: Self.serverError(-408), payload: nil),
            .response(error: Self.serverError(-408), payload: nil),
        ]

        let outcome = try #require(run(environment))
        guard case let .verifyRejected(error)? = outcome else {
            Issue.record("unexpected outcome \(String(describing: outcome))")
            return
        }
        #expect(error.code == -408)
        #expect(environment.challengesSent == 2)
        #expect(environment.verifyRequests.count == 2)
        #expect(environment.policyQuestions == 1)
        #expect(environment.failuresNoted == 1)
    }

    @Test func rejectionAfterAFastKeyUseIsRememberedAtOnce() throws {
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK]
        environment.signings = [(2, Self.signed(keyUse: 29.9))]
        environment.verifyAnswers = [.response(error: Self.serverError(-408), payload: nil)]

        let outcome = try #require(run(environment))
        guard case .verifyRejected? = outcome else {
            Issue.record("unexpected outcome \(String(describing: outcome))")
            return
        }
        #expect(environment.challengesSent == 1)
        #expect(environment.failuresNoted == 1)
    }

    @Test func slowSigningAndRejectionShareTheSingleRetry() throws {
        // The first signature is too old and retried; the retry's verify is
        // rejected after a slow key use, but there is no second retry.
        let environment = FakeEnvironment()
        environment.challengeAnswers = [Self.challengeOK, Self.challengeOK]
        environment.signings = [(130, Self.signed(keyUse: 120)), (60, Self.signed(keyUse: 60))]
        environment.verifyAnswers = [.response(error: Self.serverError(-408), payload: nil)]

        let outcome = try #require(run(environment))
        guard case .verifyRejected? = outcome else {
            Issue.record("unexpected outcome \(String(describing: outcome))")
            return
        }
        #expect(environment.challengesSent == 2)
        #expect(environment.failuresNoted == 1)
    }
}
