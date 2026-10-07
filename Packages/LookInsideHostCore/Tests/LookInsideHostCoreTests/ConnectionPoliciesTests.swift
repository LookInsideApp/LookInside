import Foundation
@testable import LookInsideHostCore
import Testing

struct ResponseFrameProgressTests {
    @Test func unsplitResponseCompletesWithItsOnlyFrame() {
        var progress = ResponseFrameProgress()
        #expect(progress.isAtFirstFrame)
        let complete = progress.record(currentDataCount: 0, dataTotalCount: 0)
        #expect(complete)
        #expect(progress.receivedDataCount == 0)
    }

    @Test func splitResponseCompletesWhenEveryItemArrived() {
        var progress = ResponseFrameProgress()
        var completions: [Bool] = []
        completions.append(progress.record(currentDataCount: 3, dataTotalCount: 10))
        #expect(!progress.isAtFirstFrame)
        completions.append(progress.record(currentDataCount: 3, dataTotalCount: 10))
        completions.append(progress.record(currentDataCount: 4, dataTotalCount: 10))
        #expect(completions == [false, false, true])
        #expect(progress.receivedDataCount == 10)
    }

    @Test func overcountedResponseStillCompletes() {
        var progress = ResponseFrameProgress()
        let first = progress.record(currentDataCount: 1, dataTotalCount: 2)
        let second = progress.record(currentDataCount: 5, dataTotalCount: 2)
        #expect(!first)
        #expect(second)
    }
}

struct ServerVersionCompatibilityTests {
    @Test(arguments: [
        (8, ServerVersionCompatibility.compatible),
        (9, .compatible),
        (7, .serverTooOld),
        (0, .serverTooOld),
        (10, .serverTooNew),
        // Old internal builds report these and are always too old, even
        // 100, which is above the supported range.
        (-1, .serverTooOld),
        (100, .serverTooOld),
    ])
    func classifiesAgainstTheSupportedRange(version: Int, expected: ServerVersionCompatibility) {
        #expect(ServerVersionCompatibility(serverVersion: version, supported: 8 ... 9) == expected)
    }
}

struct AppInfoCachePolicyTests {
    @Test func appInfoIsReusedForEightSeconds() {
        #expect(AppInfoCachePolicy.isFresh(cachedTimestamp: 100, now: 100))
        #expect(AppInfoCachePolicy.isFresh(cachedTimestamp: 100, now: 108))
        #expect(!AppInfoCachePolicy.isFresh(cachedTimestamp: 100, now: 108.01))
    }
}

struct LicenseChallengeTests {
    private let nonce = Data(repeating: 0xAB, count: 32)

    @Test func parsesTheNonceAndServerInstanceID() throws {
        let payload: NSDictionary = [
            "nonce": nonce as NSData,
            "server_instance_id": "server-1" as NSString,
            "issued_at": NSNumber(value: 1),
            "ttl": NSNumber(value: 120),
        ]
        let challenge = try LicenseChallenge.parse(payload).get()
        #expect(challenge.nonce == nonce)
        #expect(challenge.serverInstanceID == "server-1")
    }

    @Test func ignoresKeysItDoesNotKnow() throws {
        let payload: NSDictionary = [
            "nonce": nonce as NSData,
            "server_instance_id": "server-1" as NSString,
            "lookinside_server_version": "1.0" as NSString,
            NSNumber(value: 7): "non-string key" as NSString,
        ]
        #expect(try LicenseChallenge.parse(payload).get().serverInstanceID == "server-1")
    }

    @Test func rejectsAShortNonce() {
        let payload: NSDictionary = [
            "nonce": Data(count: 31) as NSData,
            "server_instance_id": "server-1" as NSString,
        ]
        #expect(throws: LicenseChallenge.Malformed(nonceLength: 31, serverInstanceIDLength: 8)) {
            try LicenseChallenge.parse(payload).get()
        }
    }

    @Test func rejectsAMissingOrEmptyServerInstanceID() {
        let empty: NSDictionary = ["nonce": nonce as NSData, "server_instance_id": "" as NSString]
        #expect(throws: LicenseChallenge.Malformed(nonceLength: 32, serverInstanceIDLength: 0)) {
            try LicenseChallenge.parse(empty).get()
        }
        let missing: NSDictionary = ["nonce": nonce as NSData]
        #expect(throws: LicenseChallenge.Malformed(nonceLength: 32, serverInstanceIDLength: 0)) {
            try LicenseChallenge.parse(missing).get()
        }
    }

    @Test func rejectsValuesOfTheWrongType() {
        let payload: NSDictionary = ["nonce": "not data" as NSString, "server_instance_id": NSNumber(value: 1)]
        #expect(throws: LicenseChallenge.Malformed(nonceLength: 0, serverInstanceIDLength: 0)) {
            try LicenseChallenge.parse(payload).get()
        }
    }

    @Test func rejectsAPayloadThatIsNotADictionary() {
        #expect(throws: LicenseChallenge.Malformed(nonceLength: 0, serverInstanceIDLength: 0)) {
            try LicenseChallenge.parse(nil).get()
        }
        #expect(throws: LicenseChallenge.Malformed(nonceLength: 0, serverInstanceIDLength: 0)) {
            try LicenseChallenge.parse(["nonce"] as NSArray).get()
        }
    }
}

struct LicenseHandshakeRetryPolicyTests {
    @Test func aSignatureOlderThanOneHundredSecondsAsksForAFreshChallenge() {
        #expect(!LicenseHandshakeRetryPolicy.shouldRequestFreshChallenge(challengeAge: 99.9, allowsRetry: true))
        #expect(LicenseHandshakeRetryPolicy.shouldRequestFreshChallenge(challengeAge: 100, allowsRetry: true))
        // The retry itself never retries again.
        #expect(!LicenseHandshakeRetryPolicy.shouldRequestFreshChallenge(challengeAge: 500, allowsRetry: false))
    }

    @Test func aRejectionAfterASlowKeyUseRetriesOnce() {
        #expect(!LicenseHandshakeRetryPolicy.shouldRetryAfterRejection(keyUseDuration: 29.9, allowsRetry: true))
        #expect(LicenseHandshakeRetryPolicy.shouldRetryAfterRejection(keyUseDuration: 30, allowsRetry: true))
        #expect(!LicenseHandshakeRetryPolicy.shouldRetryAfterRejection(keyUseDuration: 60, allowsRetry: false))
    }
}

struct LicenseHandshakeGateTests {
    private final class Results {
        var values: [Bool] = []
        func record(_ verified: Bool) {
            values.append(verified)
        }
    }

    @Test func withoutActivationTheRequestRunsUnlicensedAtOnce() {
        let gate = LicenseHandshakeGate()
        let results = Results()
        #expect(gate.admit(force: false, isActivated: false, completion: results.record) == .settled(verified: false))
        #expect(results.values == [false])
        #expect(!gate.isInFlight)
    }

    @Test func callersWaitingOnOneHandshakeAllGetItsResult() {
        let gate = LicenseHandshakeGate()
        let results = Results()
        #expect(gate.admit(force: false, isActivated: true, completion: results.record) == .mayStart)
        gate.markStarted()
        #expect(gate.admit(force: false, isActivated: true, completion: results.record) == .joined)
        #expect(gate.admit(force: false, isActivated: true, completion: nil) == .joined)
        #expect(results.values.isEmpty)

        gate.finish(verified: true)
        #expect(results.values == [true, true])
        #expect(gate.isVerified)
        #expect(!gate.isInFlight)

        // Licensed: later requests go straight through.
        #expect(gate.admit(force: false, isActivated: true, completion: results.record) == .settled(verified: true))
        #expect(results.values == [true, true, true])
    }

    @Test func aLicensedChannelSkipsTheActivationCheck() {
        // Matches the Objective-C order: a verified channel is not re-checked
        // against the activation state until it is revoked.
        let gate = LicenseHandshakeGate()
        _ = gate.admit(force: false, isActivated: true, completion: nil)
        gate.markStarted()
        gate.finish(verified: true)
        #expect(gate.admit(force: false, isActivated: false, completion: nil) == .settled(verified: true))
    }

    @Test func aFailedHandshakeLeavesTheChannelUnlicensedAndAllowsAnother() {
        let gate = LicenseHandshakeGate()
        let results = Results()
        _ = gate.admit(force: false, isActivated: true, completion: results.record)
        gate.markStarted()
        gate.finish(verified: false)
        #expect(results.values == [false])
        #expect(!gate.isVerified)
        #expect(gate.admit(force: false, isActivated: true, completion: results.record) == .mayStart)
    }

    @Test func aSigningPolicyRefusalFinishesWithoutStarting() {
        let gate = LicenseHandshakeGate()
        let results = Results()
        #expect(gate.admit(force: false, isActivated: true, completion: results.record) == .mayStart)
        // The caller's signing policy says no: finish without markStarted.
        gate.finish(verified: false)
        #expect(results.values == [false])
        #expect(!gate.isInFlight)
    }

    @Test func forceRunsAgainOnALicensedChannelAndKeepsTheEarlierSuccess() {
        let gate = LicenseHandshakeGate()
        _ = gate.admit(force: false, isActivated: true, completion: nil)
        gate.markStarted()
        gate.finish(verified: true)

        let results = Results()
        #expect(gate.admit(force: true, isActivated: true, completion: results.record) == .mayStart)
        gate.markStarted()
        gate.finish(verified: false)
        #expect(results.values == [false])
        #expect(gate.isVerified)
    }

    @Test func revokingVerificationRequiresANewHandshake() {
        let gate = LicenseHandshakeGate()
        _ = gate.admit(force: false, isActivated: true, completion: nil)
        gate.markStarted()
        gate.finish(verified: true)
        gate.revokeVerification()
        #expect(gate.admit(force: false, isActivated: true, completion: nil) == .mayStart)
    }

    @Test func aCompletionThatStartsAnotherRequestJoinsAFreshWaitList() {
        let gate = LicenseHandshakeGate()
        var nested: LicenseHandshakeGate.Admission?
        var nestedResult: Bool?
        _ = gate.admit(force: false, isActivated: true) { _ in
            nested = gate.admit(force: false, isActivated: true) { nestedResult = $0 }
        }
        gate.markStarted()
        gate.finish(verified: false)
        // The nested request found no handshake running and was not run by
        // the finished one.
        #expect(nested == .mayStart)
        #expect(nestedResult == nil)
        gate.markStarted()
        gate.finish(verified: true)
        #expect(nestedResult == true)
    }
}
