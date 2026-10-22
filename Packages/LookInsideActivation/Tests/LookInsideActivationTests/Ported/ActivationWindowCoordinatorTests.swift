import Foundation
@testable import LookInsideActivation
@testable import LookInsideActivationUI
import Testing

@MainActor
struct ActivationWindowCoordinatorTests {
    @Test func restoresPersistedPaidLicenseIntoWindowModelAfterStoreReopen() async throws {
        let url = Self.makeTempStateURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let session = TestData.makeActivationSession(licenseID: "lic_window_restore")
        let lease = TestData.makeIntermediateCertificateLease(
            certificateID: "lease-window-restore",
            licenseID: session.licenseID,
            udid: session.deviceIdentifier
        )
        let license = LicenseEnvelope(
            licenseID: session.licenseID,
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain(
                boundUDID: session.deviceIdentifier
            )
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
            activationID: "activation-window-restore",
            session: session,
            lease: lease
        )

        let store = ActivationStateStore(url: url)
        try await store.recordDeviceFingerprint(fingerprint)
        try await store.recordActivationSession(session)
        try await store.recordEntitlementStatus(status)
        try await store.recordIssuedLease(lease)
        try await store.recordActivationResponse(activationResponse)

        let runtime = ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(stateDirectoryURL: url.deletingLastPathComponent())
        )
        let coordinator = ActivationWindowCoordinator(runtime: runtime)

        await runtime.restoreActivationModel()

        #expect(
            coordinator.activationModel.currentStep
                == ActivationModel.Step.licenseStatus
        )
        #expect(coordinator.activationModel.activationSession == session)
        #expect(coordinator.activationModel.entitlementStatus?.currentLease == lease)
        #expect(coordinator.activationModel.issuedLease == lease)
        #expect(coordinator.activationModel.activationResponse == activationResponse)
        #expect(coordinator.activationModel.lastDeviceFingerprint == fingerprint)
    }

    private static func makeTempStateURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LookInsideActivationWindowCoordinatorTests-\(UUID().uuidString)",
                isDirectory: true
            )
            .appendingPathComponent("state.json")
    }
}
