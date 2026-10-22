import Foundation
@testable import LookInsideHostCore
import Testing

struct ServerUpgradeHintTests {
    private static let nonce = Data((0 ..< 32).map { UInt8($0) })

    /// The 220 reply of a released 0.2.9 Server: no version keys.
    private static var legacyPayload: NSDictionary {
        [
            "nonce": nonce as NSData,
            "server_instance_id": "server-1" as NSString,
            "issued_at": NSNumber(value: 1),
            "ttl": NSNumber(value: 120),
        ]
    }

    private static func payload(version: String?, build: Int?) -> NSDictionary {
        let dictionary = NSMutableDictionary(dictionary: legacyPayload)
        dictionary["lookinside_server_version"] = version.map { $0 as NSString }
        dictionary["lookinside_server_build"] = build.map { NSNumber(value: $0) }
        return dictionary
    }

    @Test func legacyChallengeStillParses() throws {
        let challenge = try LicenseChallenge.parse(Self.legacyPayload).get()
        #expect(challenge == LicenseChallenge(nonce: Self.nonce, serverInstanceID: "server-1"))
        #expect(ServerRelease.parse(Self.legacyPayload) == ServerRelease(version: nil, build: nil))
    }

    @Test func newChallengeParsesTheSameAndCarriesTheRelease() throws {
        let payload = Self.payload(version: "0.3.0", build: 3000)
        let challenge = try LicenseChallenge.parse(payload).get()
        #expect(challenge == LicenseChallenge(nonce: Self.nonce, serverInstanceID: "server-1"))
        #expect(ServerRelease.parse(payload) == ServerRelease(version: "0.3.0", build: 3000))
    }

    @Test(arguments: [
        // A key is missing: a 0.2.9 or older Server.
        (nil, nil, true),
        ("0.3.0", nil, true),
        (nil, 3000, true),
        // SemVer at or below 0.2.9.
        ("0.2.9", 2009, true),
        ("0.2.0", 2000, true),
        ("0.1.12", 1012, true),
        ("0.2.9-rc.1", 2009, true),
        // Newer releases.
        ("0.2.10", 2010, false),
        ("0.3.0", 3000, false),
        ("1.0.0+5", 1_000_000, false),
        // Not SemVer: an unreleased build, or something unexpected.
        ("dev", 0, false),
        ("0.2", 0, false),
        ("v0.2.9", 0, false),
        ("0.2.9.1", 0, false),
        ("", 0, false),
    ] as [(String?, Int?, Bool)])
    func upgradeDecision(version: String?, build: Int?, expected: Bool) {
        #expect(ServerRelease(version: version, build: build).suggestsUpgrade == expected)
    }

    @Test func wrongValueTypesCountAsMissing() {
        let dictionary = NSMutableDictionary(dictionary: Self.legacyPayload)
        dictionary["lookinside_server_version"] = NSNumber(value: 3)
        dictionary["lookinside_server_build"] = "3000" as NSString
        let release = ServerRelease.parse(dictionary)
        #expect(release == ServerRelease(version: nil, build: nil))
        #expect(release.suggestsUpgrade)
    }

    @Test func ledgerShowsTheHintOncePerApp() {
        let ledger = ServerUpgradeHintLedger()
        let old = ServerRelease(version: nil, build: nil)
        let current = ServerRelease(version: "0.3.0", build: 3000)
        #expect(!ledger.shouldShowHint(for: current, appKey: "com.example.a"))
        #expect(ledger.shouldShowHint(for: old, appKey: "com.example.a"))
        #expect(!ledger.shouldShowHint(for: old, appKey: "com.example.a"))
        #expect(ledger.shouldShowHint(for: old, appKey: "com.example.b"))
    }
}
