import Foundation
@testable import LookInsideActivation
import Testing

/// `state.json` is shared by every LookInside instance and by a 2.3.x helper
/// that may still run after a downgrade. A process must never write its
/// stale snapshot over newer state another process stored.
struct StateSharingTests {
    private func makeRuntime(directory: URL, now: Date) -> ActivationRuntime {
        ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(stateDirectoryURL: directory),
            urlSession: .shared,
            now: { now },
            silentRenewalEnabled: false
        )
    }

    private func fixtureState() throws -> ActivationPersistedState {
        try ActivationStateCoding.decoder.decode(
            ActivationPersistedState.self,
            from: HelperFixtures.data("helper-state-full.json")
        )
    }

    @Test func twoRuntimesOnOneDirectoryKeepEachOthersWrites() async throws {
        let input = try HelperFixtures.challengeInput()
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let stateURL = directory.appendingPathComponent("state.json")

        let first = makeRuntime(directory: directory, now: input.evaluatedAt)
        let second = makeRuntime(directory: directory, now: input.evaluatedAt)
        #expect(first.activationState == .notActivated)
        #expect(second.activationState == .notActivated)

        // The first instance activates.
        let full = try fixtureState()
        let fingerprint = try #require(full.deviceFingerprint)
        let session = try #require(full.activationSession)
        let status = try #require(full.entitlementStatus)
        let response = try #require(full.activationResponse)
        try await first.stateStore.recordDeviceFingerprint(fingerprint)
        try await first.stateStore.recordActivationSession(session)
        try await first.stateStore.recordEntitlementStatus(status)
        try await first.stateStore.recordActivationResponse(response)
        #expect(await first.currentDecision().grantsAccess)

        // The second instance still holds its empty snapshot. Its next write
        // starts from the file, so the activation survives.
        let failedAt = input.evaluatedAt.addingTimeInterval(-60)
        try await second.stateStore.recordRenewAttempt(success: false, error: "offline", at: failedAt)
        let onDisk = ActivationStateStore.loadState(from: stateURL)
        #expect(onDisk.activationResponse == response)
        #expect(onDisk.entitlementStatus?.currentLease == status.currentLease)
        #expect(onDisk.lastRenewFailedAt == failedAt)

        // Each instance picks up the other's change on its next evaluation.
        #expect(await second.currentDecision().grantsAccess)
        #expect(second.activationState == .activated)
        _ = await first.currentDecision()
        #expect(await first.snapshot().lastRenewFailedAt == failedAt)
    }

    @Test func fileWrittenByAnotherProcessIsReloadedOnlyWhenChanged() async throws {
        let input = try HelperFixtures.challengeInput()
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let stateURL = directory.appendingPathComponent("state.json")
        let runtime = makeRuntime(directory: directory, now: input.evaluatedAt)

        #expect(await runtime.stateStore.reloadIfChanged() == false)
        #expect(await runtime.currentDecision().grantsAccess == false)

        // A 2.3.x helper (or another Host) writes the file.
        try HelperFixtures.data("helper-state-full.json").write(to: stateURL, options: .atomic)
        #expect(await runtime.currentDecision().grantsAccess)
        #expect(await runtime.stateStore.reloadIfChanged() == false)
    }

    @Test func trialInMemorySurvivesAnotherProcessWritingTelemetry() async throws {
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")
        let trialProcess = ActivationStateStore(url: url)
        let otherProcess = ActivationStateStore(url: url)

        let pem = try HelperFixtureValues.certificatePEM()
        let session = HelperFixtureValues.session(licenseID: "lic_fixture_trial", token: "fixture-token-trial")
        let lease = HelperFixtureValues.lease(
            licenseID: "lic_fixture_trial",
            expiresIn: 2 * HelperFixtureValues.day,
            certificatePEM: pem
        )
        try await trialProcess.recordTransientActivationSession(session)
        try await trialProcess.recordEntitlementStatus(
            HelperFixtureValues.status(licenseClass: .trial, lease: lease, session: session)
        )
        try await otherProcess.recordDeviceFingerprint(HelperFixtureValues.fingerprint)

        #expect(await trialProcess.reloadIfChanged())
        let snapshot = await trialProcess.snapshot()
        #expect(snapshot.deviceFingerprint == HelperFixtureValues.fingerprint)
        #expect(snapshot.activationSession == session)
        #expect(snapshot.entitlementStatus?.license.licenseClass == .trial)
        // The trial still never reaches the disk.
        let onDisk = ActivationStateStore.loadState(from: url)
        #expect(onDisk.activationSession == nil)
        #expect(onDisk.entitlementStatus == nil)
    }

    /// Starts a trial in `store` the way the trial flow does: a transient
    /// session first, then the trial entitlement.
    private func startTrial(in store: ActivationStateStore, certificatePEM pem: String) async throws
        -> ActivationSession
    {
        let session = HelperFixtureValues.session(licenseID: "lic_fixture_trial", token: "fixture-token-trial")
        let lease = HelperFixtureValues.lease(
            licenseID: "lic_fixture_trial",
            expiresIn: 2 * HelperFixtureValues.day,
            certificatePEM: pem
        )
        try await store.recordTransientActivationSession(session)
        try await store.recordEntitlementStatus(
            HelperFixtureValues.status(licenseClass: .trial, lease: lease, session: session)
        )
        return session
    }

    /// State another process (or the 2.3.x helper) writes for a full license
    /// whose lease ends `expiresIn` after the fixture date.
    private func writeFullLicense(to url: URL, expiresIn: TimeInterval, certificatePEM pem: String) throws {
        let session = HelperFixtureValues.session(licenseID: "lic_fixture_full", token: "fixture-token-full")
        let lease = HelperFixtureValues.lease(
            licenseID: "lic_fixture_full",
            expiresIn: expiresIn,
            certificatePEM: pem
        )
        let state = ActivationPersistedState(
            deviceFingerprint: HelperFixtureValues.fingerprint,
            activationSession: session,
            entitlementStatus: HelperFixtureValues.status(licenseClass: .full, lease: lease, session: session),
            activationResponse: HelperFixtureValues.activationResponse(lease: lease),
            updatedAt: HelperFixtureValues.base
        )
        try ActivationStateCoding.encoder.encode(state).write(to: url, options: .atomic)
    }

    /// An expired license on disk does not replace a trial running in
    /// memory, neither while the trial starts nor when an older process
    /// writes that license again later.
    @Test func trialOverAnExpiredLicenseSurvivesWrites() async throws {
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")
        let pem = try HelperFixtureValues.certificatePEM()
        try writeFullLicense(to: url, expiresIn: -HelperFixtureValues.day, certificatePEM: pem)
        let store = ActivationStateStore(url: url, now: { HelperFixtureValues.base })
        #expect(await store.snapshot().entitlementStatus?.license.licenseClass == .full)

        let trialSession = try await startTrial(in: store, certificatePEM: pem)
        try await store.recordRenewAttempt(success: false, error: "offline", at: HelperFixtureValues.base)
        var snapshot = await store.snapshot()
        #expect(snapshot.activationSession == trialSession)
        #expect(snapshot.entitlementStatus?.license.licenseClass == .trial)

        // The 2.3.x helper writes its expired license back.
        try writeFullLicense(to: url, expiresIn: -HelperFixtureValues.day, certificatePEM: pem)
        try await store.recordDeviceFingerprint(HelperFixtureValues.fingerprint)
        #expect(await store.reloadIfChanged() == false)
        snapshot = await store.snapshot()
        #expect(snapshot.activationSession == trialSession)
        #expect(snapshot.entitlementStatus?.license.licenseClass == .trial)
        #expect(snapshot.deviceFingerprint == HelperFixtureValues.fingerprint)
    }

    /// A license another process activates wins over the in-memory trial.
    @Test func newActiveLicenseFromAnotherProcessReplacesTheTrial() async throws {
        let directory = try HelperFixtures.makeStateDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")
        let pem = try HelperFixtureValues.certificatePEM()
        let store = ActivationStateStore(url: url, now: { HelperFixtureValues.base })
        _ = try await startTrial(in: store, certificatePEM: pem)

        try writeFullLicense(to: url, expiresIn: 20 * HelperFixtureValues.day, certificatePEM: pem)
        try await store.recordRenewAttempt(success: true, error: nil, at: HelperFixtureValues.base)
        let snapshot = await store.snapshot()
        #expect(snapshot.entitlementStatus?.license.licenseClass == .full)
        #expect(snapshot.activationSession?.licenseID == "lic_fixture_full")
        // The full license stays on disk, with this process's telemetry.
        let onDisk = ActivationStateStore.loadState(from: url)
        #expect(onDisk.entitlementStatus?.license.licenseClass == .full)
        #expect(onDisk.activationSession?.licenseID == "lic_fixture_full")
        #expect(onDisk.lastRenewSucceededAt == HelperFixtureValues.base)
    }

    /// Rewriting the file with the same contents (a touch, a copy) is not a
    /// change and does not reload.
    @Test func sameContentsDoNotReload() async throws {
        let directory = try HelperFixtures.makeStateDirectory(copying: "helper-state-full.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("state.json")
        let store = ActivationStateStore(url: url)

        try Data(contentsOf: url).write(to: url, options: .atomic)
        #expect(await store.reloadIfChanged() == false)
    }
}
