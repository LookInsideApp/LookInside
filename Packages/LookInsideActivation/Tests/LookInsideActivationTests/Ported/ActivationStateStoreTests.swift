import Foundation
@testable import LookInsideActivation
@testable import LookInsideActivationUI
import Testing

struct ActivationStateStoreTests {
    @Test func persistsAndReloadsFingerprintAcrossStoreInstances() async throws {
        let url = Self.makeTempStateURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let firstStore = ActivationStateStore(url: url)
        let fingerprint = DeviceFingerprint(
            deviceID: "device-1",
            hardwareModel: "Mac16,1",
            operatingSystemVersion: "15.0",
            appBundleID: "app.lookinside.AuthServer"
        )
        try await firstStore.recordDeviceFingerprint(fingerprint)

        let reopened = ActivationStateStore(url: url)
        let snapshot = await reopened.snapshot()
        #expect(snapshot.deviceFingerprint == fingerprint)
    }

    @Test func recordIssuedLeaseNoOpsWhenEntitlementStatusAbsent() async throws {
        let url = Self.makeTempStateURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ActivationStateStore(url: url)
        let lease = TestData.makeIntermediateCertificateLease()
        try await store.recordIssuedLease(lease)

        let snapshot = await store.snapshot()
        #expect(snapshot.entitlementStatus == nil)
    }

    @Test func persistsPaidEntitlementAcrossStoreInstances() async throws {
        let url = Self.makeTempStateURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ActivationStateStore(url: url)
        let session = TestData.makeActivationSession(licenseID: "lic_paid_abc")
        let license = Self.makeLicense(licenseID: "lic_paid_abc", licenseClass: .full)
        let status = TestData.makeEntitlementStatus(license: license)

        try await store.recordActivationSession(session)
        try await store.recordEntitlementStatus(status)

        let reopened = ActivationStateStore(url: url)
        let snapshot = await reopened.snapshot()
        #expect(snapshot.activationSession?.licenseID == "lic_paid_abc")
        #expect(snapshot.entitlementStatus?.license.licenseID == "lic_paid_abc")
        #expect(snapshot.entitlementStatus?.license.licenseClass == .full)
    }

    @Test func persistsPaidLeaseAndActivationResponseAcrossStoreInstances() async throws {
        let url = Self.makeTempStateURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ActivationStateStore(url: url)
        let session = TestData.makeActivationSession(licenseID: "lic_paid_restored")
        let lease = TestData.makeIntermediateCertificateLease(
            certificateID: "lease-cert-restored",
            licenseID: session.licenseID,
            udid: session.deviceIdentifier
        )
        let license = Self.makeLicense(
            licenseID: session.licenseID,
            licenseClass: .full
        )
        let status = TestData.makeEntitlementStatus(
            license: license,
            activationSession: session
        )
        let fingerprint = DeviceFingerprint(
            deviceID: session.deviceIdentifier,
            hardwareModel: "Mac16,1",
            operatingSystemVersion: "15.0",
            appBundleID: "app.lookinside.AuthServer"
        )
        let activationResponse = TestData.makeHostActivationResponse(
            activationID: "activation-restored",
            session: session,
            lease: lease
        )

        try await store.recordDeviceFingerprint(fingerprint)
        try await store.recordActivationSession(session)
        try await store.recordEntitlementStatus(status)
        try await store.recordIssuedLease(lease)
        try await store.recordActivationResponse(activationResponse)

        let reopened = ActivationStateStore(url: url)
        let snapshot = await reopened.snapshot()
        #expect(snapshot.deviceFingerprint == fingerprint)
        #expect(snapshot.activationSession == session)
        #expect(snapshot.entitlementStatus?.currentLease == lease)
        #expect(snapshot.entitlementStatus?.license.certificateChain.intermediateCertificateID == lease.certificateID)
        #expect(snapshot.entitlementStatus?.license.certificateChain.boundUDID == lease.udid)
        #expect(snapshot.activationResponse == activationResponse)
    }

    @Test func keepsTransientActivationSessionInMemoryOnly() async throws {
        let url = Self.makeTempStateURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ActivationStateStore(url: url)
        let session = TestData.makeActivationSession(licenseID: "lic_trial_abc")

        try await store.recordTransientActivationSession(session)

        let currentSnapshot = await store.snapshot()
        #expect(currentSnapshot.activationSession?.licenseID == "lic_trial_abc")

        let reopened = ActivationStateStore(url: url)
        let snapshot = await reopened.snapshot()
        #expect(snapshot.activationSession == nil)
    }

    @Test func keepsTrialEntitlementInMemoryOnly() async throws {
        let url = Self.makeTempStateURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = ActivationStateStore(url: url)
        let session = TestData.makeActivationSession(licenseID: "lic_trial_abc")
        let license = Self.makeLicense(licenseID: "lic_trial_abc", licenseClass: .trial)
        let status = TestData.makeEntitlementStatus(license: license)

        try await store.recordActivationSession(session)
        try await store.recordEntitlementStatus(status)

        let currentSnapshot = await store.snapshot()
        #expect(currentSnapshot.activationSession?.licenseID == "lic_trial_abc")
        #expect(currentSnapshot.entitlementStatus?.license.licenseClass == .trial)

        let reopened = ActivationStateStore(url: url)
        let snapshot = await reopened.snapshot()
        #expect(snapshot.activationSession == nil)
        #expect(snapshot.entitlementStatus == nil)
        #expect(snapshot.activationResponse == nil)
    }

    private static func makeLicense(
        licenseID: String,
        licenseClass: LicenseClass,
        expiresAt: Date = TestData.baseNow.addingTimeInterval(3600)
    ) -> LicenseEnvelope {
        LicenseEnvelope(
            licenseID: licenseID,
            licenseClass: licenseClass,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: expiresAt,
            certificateChain: TestData.makeCertificateChain(
                intermediateExpiresAt: expiresAt
            )
        )
    }

    private static func makeTempStateURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("LookInsideAuthServerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("state.json")
    }
}
