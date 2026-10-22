import Foundation
@testable import LookInsideActivation
import Testing

/// `state.json` is shared with the 2.3.x Auth helper: the new Host must read
/// what the helper wrote and write what the helper can read, byte for byte.
struct StateFileCompatibilityTests {
    /// The synthetic old-user state (`make_state_json` in
    /// `Scripts/reborn-old-user-vm.sh`) decodes and re-encodes with the same
    /// keys and values.
    @Test func oldUserStateRoundTripsKeyForKey() throws {
        let original = try HelperFixtures.data("olduser-state.json")
        let state = try ActivationStateCoding.decoder.decode(ActivationPersistedState.self, from: original)
        let reencoded = try ActivationStateCoding.encoder.encode(state)

        #expect(try HelperFixtures.jsonObject(reencoded) == HelperFixtures.jsonObject(original))
    }

    /// The re-encoded old-user state is the exact bytes the helper's codec
    /// produced for the same input.
    @Test func oldUserStateReencodesToHelperBytes() throws {
        let state = try ActivationStateCoding.decoder.decode(
            ActivationPersistedState.self,
            from: HelperFixtures.data("olduser-state.json")
        )
        let reencoded = try ActivationStateCoding.encoder.encode(state)

        #expect(try reencoded == (HelperFixtures.data("olduser-state.helper-reencoded.json")))
    }

    /// A helper-written full-license state reads back without losing fields.
    @Test(arguments: ["helper-state-full.json", "helper-state-trial.json"])
    func helperStateRoundTripsByteForByte(fixture: String) throws {
        let original = try HelperFixtures.data(fixture)
        let state = try ActivationStateCoding.decoder.decode(ActivationPersistedState.self, from: original)

        #expect(try ActivationStateCoding.encoder.encode(state) == original)
    }

    @Test func storeLoadsHelperWrittenState() async throws {
        let directory = try HelperFixtures.makeStateDirectory(copying: "helper-state-full.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = ActivationStateStore(url: directory.appendingPathComponent("state.json"))
        let snapshot = await store.snapshot()

        #expect(snapshot.deviceFingerprint == HelperFixtureValues.fingerprint)
        #expect(snapshot.activationSession?.licenseID == "lic_fixture_full")
        #expect(snapshot.entitlementStatus?.license.licenseClass == .full)
        #expect(snapshot.entitlementStatus?.currentLease?.udid == HelperFixtureValues.udid)
        #expect(snapshot.activationResponse?.activation.activationID == "act_fixture")
        #expect(snapshot.lastRenewError == "offline")
    }

    /// Replaying the generator's writes through the new store produces the
    /// helper's file byte for byte.
    @Test func storeWritesHelperBytesForFullLicense() async throws {
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")

        let base = HelperFixtureValues.base
        let day = HelperFixtureValues.day
        let pem = try HelperFixtureValues.certificatePEM()
        let session = HelperFixtureValues.session(licenseID: "lic_fixture_full", token: "fixture-token-full")
        let lease = HelperFixtureValues.lease(licenseID: "lic_fixture_full", expiresIn: 25 * day, certificatePEM: pem)

        let store = ActivationStateStore(url: url)
        try await store.recordDeviceFingerprint(HelperFixtureValues.fingerprint)
        try await store.recordActivationSession(session)
        try await store.recordEntitlementStatus(
            HelperFixtureValues.status(licenseClass: .full, lease: lease, session: session)
        )
        try await store.recordActivationResponse(HelperFixtureValues.activationResponse(lease: lease))
        try await store.recordRenewAttempt(success: true, error: nil, at: base.addingTimeInterval(-3 * day))
        try await store.recordRenewAttempt(success: false, error: "offline", at: base.addingTimeInterval(-2 * day))

        #expect(try Data(contentsOf: url) == (HelperFixtures.data("helper-state-full.json")))
    }

    /// A trial stays in memory: only the fingerprint and renewal telemetry
    /// reach the disk, exactly as the helper wrote them.
    @Test func storeKeepsTrialInMemoryLikeHelper() async throws {
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")

        let pem = try HelperFixtureValues.certificatePEM()
        let session = HelperFixtureValues.session(licenseID: "lic_fixture_trial", token: "fixture-token-trial")
        let lease = HelperFixtureValues.lease(
            licenseID: "lic_fixture_trial",
            expiresIn: 2 * HelperFixtureValues.day,
            certificatePEM: pem
        )

        let store = ActivationStateStore(url: url)
        try await store.recordDeviceFingerprint(HelperFixtureValues.fingerprint)
        try await store.recordTransientActivationSession(session)
        try await store.recordEntitlementStatus(
            HelperFixtureValues.status(licenseClass: .trial, lease: lease, session: session)
        )
        try await store.recordRenewAttempt(success: true, error: nil, at: HelperFixtureValues.base)

        #expect(try Data(contentsOf: url) == (HelperFixtures.data("helper-state-trial.json")))
        let inMemory = await store.snapshot()
        #expect(inMemory.entitlementStatus?.license.licenseClass == .trial)
        #expect(inMemory.activationSession == session)
    }

    @Test func standardConfigurationUsesHelperLocations() {
        let configuration = ActivationConfiguration.standard
        #expect(
            configuration.stateFileURL.path.hasSuffix(
                "Library/Application Support/LookInside/AuthServer/state/state.json"
            )
        )
        #expect(configuration.keyStore.applicationTag == "com.lookinside.authserver.intermediate-key")
        #expect(configuration.keyStore.keychainPath == nil)
        #expect(configuration.fingerprintAppBundleID == "app.lookinside.LookInsideAuthServer")
    }
}
