import Foundation
@testable import LookInsideActivation
@testable import LookInsideActivationUI
import Testing

@MainActor
struct ActivationModelTests {
    @Test func activationInputsNormalizePastedSingleLineValues() {
        let session = TestData.makeActivationSession()
        let license = LicenseEnvelope(
            licenseID: session.licenseID,
            licenseClass: .full,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain()
        )
        let model = makeModel(
            session: session,
            purchaseClaimResolver: RecordingPurchaseClaimResolver(session: session),
            statusFetcher: RecordingEntitlementStatusFetcher(status: TestData.makeEntitlementStatus(license: license)),
            certificateIssuer: RecordingIntermediateCertificateIssuer(
                lease: TestData.makeIntermediateCertificateLease()
            )
        )

        model.email = "  buyer@example.com\n"
        model.licenseKey = " abcde – fghij\n-klmno\t-pqrst  "

        #expect(model.email == "buyer@example.com")
        #expect(model.licenseKey == "ABCDE-FGHIJ-KLMNO-PQRST")
    }

    @Test func resolvePurchaseClaimFetchesStatusAndAdvancesToEligibilityReview() async {
        let session = TestData.makeActivationSession()
        let license = LicenseEnvelope(
            licenseID: session.licenseID,
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain(boundUDID: session.deviceIdentifier)
        )
        let status = TestData.makeEntitlementStatus(
            license: license,
            activationSession: session
        )
        let purchaseClaimResolver = RecordingPurchaseClaimResolver(session: session)
        let statusFetcher = RecordingEntitlementStatusFetcher(status: status)
        let certificateIssuer = RecordingIntermediateCertificateIssuer(
            lease: TestData.makeIntermediateCertificateLease(udid: session.deviceIdentifier)
        )
        let device = TestData.makeChallenge().device

        let model = ActivationModel(
            configuration: .init(requestedFeature: "swiftui.support", frameworkVersion: "2.0.0"),
            purchaseClaimResolver: purchaseClaimResolver,
            trialIssuer: RecordingTrialIssuer(session: session),
            entitlementStatusFetcher: statusFetcher,
            intermediateCertificateIssuer: certificateIssuer,
            deviceFingerprintProvider: { device },
            certificateSigningRequestProvider: {
                "-----BEGIN CERTIFICATE REQUEST-----\ncsr\n-----END CERTIFICATE REQUEST-----"
            },
            activationHandler: { request in
                HostActivationResponse(
                    activation: SignedActivationEnvelope(
                        activationID: "activation-123",
                        challengeNonce: request.challenge.nonce,
                        licenseID: request.license.licenseID,
                        issuedAt: TestData.baseNow,
                        expiresAt: TestData.baseNow.addingTimeInterval(3600),
                        intermediateCertificateID: request.license.certificateChain.intermediateCertificateID,
                        boundUDID: request.challenge.device.deviceID,
                        artifacts: []
                    ),
                    path: .direct,
                    secureTimestamp: nil
                )
            },
            clock: FixedClock(currentDate: TestData.baseNow)
        )
        model.licenseKey = session.orderID ?? ""
        model.email = session.email ?? ""

        await model.resolvePurchaseClaim()

        #expect(model.currentStep == ActivationModel.Step.eligibilityReview)
        #expect(model.errorMessage == nil)
        #expect(model.activationSession == session)
        #expect(model.lastDeviceFingerprint == device)
        #expect(purchaseClaimResolver.resolveCount == 1)
        #expect(statusFetcher.fetchCount == 1)
        #expect(statusFetcher.lastRequest?.forceRefresh == true)
    }

    @Test func issueIntermediateCertificateMergesLeaseIntoEntitlementStatus() async {
        let session = TestData.makeActivationSession()
        let lease = TestData.makeIntermediateCertificateLease(
            certificateID: "lease-cert-002",
            udid: session.deviceIdentifier
        )
        let license = LicenseEnvelope(
            licenseID: session.licenseID,
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain(boundUDID: session.deviceIdentifier)
        )
        let purchaseClaimResolver = RecordingPurchaseClaimResolver(session: session)
        let statusFetcher = RecordingEntitlementStatusFetcher(
            status: TestData.makeEntitlementStatus(
                license: license,
                activationSession: session,
                isEligibleForActivation: true
            )
        )
        let certificateIssuer = RecordingIntermediateCertificateIssuer(lease: lease)

        let model = makeModel(
            session: session,
            purchaseClaimResolver: purchaseClaimResolver,
            statusFetcher: statusFetcher,
            certificateIssuer: certificateIssuer
        )
        model.licenseKey = session.orderID ?? ""
        model.email = session.email ?? ""

        await model.resolvePurchaseClaim()
        await model.issueIntermediateCertificate()

        #expect(model.currentStep == ActivationModel.Step.finalActivation)
        #expect(model.issuedLease == lease)
        #expect(model.entitlementStatus?.currentLease == lease)
        #expect(model.entitlementStatus?.license.certificateChain.boundUDID == session.deviceIdentifier)
        #expect(certificateIssuer.issueCount == 1)
        #expect(model.canCompleteActivation == true)
    }

    @Test func restorePersistedActivationStateShowsLicenseStatus() {
        let session = TestData.makeActivationSession()
        let lease = TestData.makeIntermediateCertificateLease(
            certificateID: "lease-cert-restored",
            udid: session.deviceIdentifier
        )
        let license = LicenseEnvelope(
            licenseID: session.licenseID,
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain(boundUDID: session.deviceIdentifier)
        )
        let status = TestData.makeEntitlementStatus(
            license: license,
            currentLease: lease,
            activationSession: session
        )
        let response = HostActivationResponse(
            activation: SignedActivationEnvelope(
                activationID: "activation-restored",
                challengeNonce: "nonce-restored",
                licenseID: session.licenseID,
                issuedAt: TestData.baseNow,
                expiresAt: TestData.baseNow.addingTimeInterval(3600),
                intermediateCertificateID: lease.certificateID,
                boundUDID: session.deviceIdentifier,
                artifacts: []
            ),
            path: .direct,
            secureTimestamp: nil
        )
        let device = DeviceFingerprint(
            deviceID: session.deviceIdentifier,
            hardwareModel: "Mac16,1",
            operatingSystemVersion: "15.0",
            appBundleID: "app.lookinside.AuthServer"
        )
        let model = makeModel(
            session: session,
            purchaseClaimResolver: RecordingPurchaseClaimResolver(session: session),
            statusFetcher: RecordingEntitlementStatusFetcher(status: status),
            certificateIssuer: RecordingIntermediateCertificateIssuer(lease: lease)
        )

        model.restorePersistedActivationState(
            activationSession: session,
            entitlementStatus: status,
            activationResponse: response,
            deviceFingerprint: device
        )

        #expect(model.currentStep == ActivationModel.Step.licenseStatus)
        #expect(model.activationSession == session)
        #expect(model.entitlementStatus?.currentLease == lease)
        #expect(model.issuedLease == lease)
        #expect(model.activationResponse == response)
        #expect(model.lastDeviceFingerprint == device)
    }

    @Test func restorePersistedActivationStateShowsLicenseStatusFromActivationResponse() {
        let session = TestData.makeActivationSession()
        let lease = TestData.makeIntermediateCertificateLease(udid: session.deviceIdentifier)
        let license = LicenseEnvelope(
            licenseID: session.licenseID,
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain(boundUDID: session.deviceIdentifier)
        )
        let status = TestData.makeEntitlementStatus(
            license: license,
            activationSession: session
        )
        let response = TestData.makeHostActivationResponse(
            activationID: "activation-response-only",
            session: session,
            lease: lease
        )
        let model = makeModel(
            session: session,
            purchaseClaimResolver: RecordingPurchaseClaimResolver(session: session),
            statusFetcher: RecordingEntitlementStatusFetcher(status: status),
            certificateIssuer: RecordingIntermediateCertificateIssuer(lease: lease)
        )

        model.restorePersistedActivationState(
            activationSession: nil,
            entitlementStatus: status,
            activationResponse: response,
            deviceFingerprint: nil
        )

        #expect(model.currentStep == ActivationModel.Step.licenseStatus)
        #expect(model.activationSession == session)
        #expect(model.issuedLease == nil)
        #expect(model.activationResponse == response)
    }

    @Test func restorePersistedActivationStateReturnsToClaimFormWithoutActivatedLicense() {
        let session = TestData.makeActivationSession()
        let license = LicenseEnvelope(
            licenseID: session.licenseID,
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain(boundUDID: session.deviceIdentifier)
        )
        let status = TestData.makeEntitlementStatus(
            license: license,
            activationSession: session
        )
        let model = makeModel(
            session: session,
            purchaseClaimResolver: RecordingPurchaseClaimResolver(session: session),
            statusFetcher: RecordingEntitlementStatusFetcher(status: status),
            certificateIssuer: RecordingIntermediateCertificateIssuer(
                lease: TestData.makeIntermediateCertificateLease()
            )
        )
        model.beginFullActivationFromTrial()

        model.restorePersistedActivationState(
            activationSession: nil,
            entitlementStatus: status,
            activationResponse: nil,
            deviceFingerprint: nil
        )

        #expect(model.currentStep == ActivationModel.Step.claimForm)
        #expect(model.activationSession == session)
        #expect(model.issuedLease == nil)
        #expect(model.activationResponse == nil)
        #expect(model.isShowingActivationForm == false)
        #expect(model.lastDeviceFingerprint?.deviceID == status.deviceBinding?.udid)
    }

    @Test func licenseStatusRefreshProgressUsesDedicatedModelState() {
        let session = TestData.makeActivationSession()
        let lease = TestData.makeIntermediateCertificateLease(
            certificateID: "lease-refresh-progress",
            udid: session.deviceIdentifier
        )
        let license = LicenseEnvelope(
            licenseID: session.licenseID,
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain(boundUDID: session.deviceIdentifier)
        )
        let status = TestData.makeEntitlementStatus(
            license: license,
            currentLease: lease,
            activationSession: session
        )
        let model = makeModel(
            session: session,
            purchaseClaimResolver: RecordingPurchaseClaimResolver(session: session),
            statusFetcher: RecordingEntitlementStatusFetcher(status: status),
            certificateIssuer: RecordingIntermediateCertificateIssuer(lease: lease)
        )

        model.restorePersistedActivationState(
            activationSession: session,
            entitlementStatus: status,
            activationResponse: TestData.makeHostActivationResponse(session: session, lease: lease),
            deviceFingerprint: nil
        )

        model.beginLicenseStatusRefresh(message: "Refreshing test license…")

        #expect(model.isRefreshingLicenseStatus == true)
        #expect(model.licenseStatusRefreshMessage == "Refreshing test license…")
        #expect(model.currentStep == ActivationModel.Step.licenseStatus)
        #expect(model.isShowingActivationForm == false)

        model.finishLicenseStatusRefresh()

        #expect(model.isRefreshingLicenseStatus == false)
        #expect(model.licenseStatusRefreshMessage == nil)
    }

    @Test func completeActivationBuildsHostRequestFromIssuedLease() async {
        let session = TestData.makeActivationSession()
        let lease = TestData.makeIntermediateCertificateLease(
            certificateID: "lease-cert-003",
            udid: session.deviceIdentifier
        )
        let license = LicenseEnvelope(
            licenseID: session.licenseID,
            licenseClass: .full,
            lifecycleState: .active,
            issuedTo: "Acme",
            issuedAt: TestData.baseNow,
            expiresAt: TestData.baseNow.addingTimeInterval(3600),
            certificateChain: TestData.makeCertificateChain()
        )
        let purchaseClaimResolver = RecordingPurchaseClaimResolver(session: session)
        let statusFetcher = RecordingEntitlementStatusFetcher(
            status: TestData.makeEntitlementStatus(
                license: license,
                activationSession: session,
                isEligibleForActivation: true
            )
        )
        let certificateIssuer = RecordingIntermediateCertificateIssuer(lease: lease)
        let device = TestData.makeChallenge().device
        let recordedRequest = LockIsolated<HostActivationRequest?>(nil)

        let model = ActivationModel(
            configuration: .init(requestedFeature: "swiftui.support", frameworkVersion: "2.1.0"),
            purchaseClaimResolver: purchaseClaimResolver,
            trialIssuer: RecordingTrialIssuer(session: session),
            entitlementStatusFetcher: statusFetcher,
            intermediateCertificateIssuer: certificateIssuer,
            deviceFingerprintProvider: { device },
            certificateSigningRequestProvider: { "csr" },
            activationHandler: { request in
                await recordedRequest.setValue(request)
                return HostActivationResponse(
                    activation: SignedActivationEnvelope(
                        activationID: "activation-123",
                        challengeNonce: request.challenge.nonce,
                        licenseID: request.license.licenseID,
                        issuedAt: TestData.baseNow,
                        expiresAt: TestData.baseNow.addingTimeInterval(3600),
                        intermediateCertificateID: request.license.certificateChain.intermediateCertificateID,
                        boundUDID: request.challenge.device.deviceID,
                        artifacts: []
                    ),
                    path: .direct,
                    secureTimestamp: nil
                )
            },
            clock: FixedClock(currentDate: TestData.baseNow)
        )
        model.licenseKey = session.orderID ?? ""
        model.email = session.email ?? ""

        await model.resolvePurchaseClaim()
        await model.issueIntermediateCertificate()
        await model.completeActivation()

        let request = await recordedRequest.value
        #expect(model.currentStep == ActivationModel.Step.licenseStatus)
        #expect(request?.license.certificateChain.intermediateCertificateID == lease.certificateID)
        #expect(request?.license.certificateChain.boundUDID == session.deviceIdentifier)
        #expect(request?.challenge.requestedFeature == "swiftui.support")
        #expect(model.activationResponse?.activation.boundUDID == session.deviceIdentifier)
    }

    @Test func resolvePurchaseClaimRequiresOrderAndEmail() async {
        let session = TestData.makeActivationSession()
        let purchaseClaimResolver = RecordingPurchaseClaimResolver(session: session)
        let statusFetcher = RecordingEntitlementStatusFetcher(
            status: TestData.makeEntitlementStatus(
                license: LicenseEnvelope(
                    licenseID: session.licenseID,
                    licenseClass: .full,
                    issuedTo: "Acme",
                    issuedAt: TestData.baseNow,
                    expiresAt: TestData.baseNow.addingTimeInterval(3600),
                    certificateChain: TestData.makeCertificateChain()
                )
            )
        )
        let certificateIssuer = RecordingIntermediateCertificateIssuer(
            lease: TestData.makeIntermediateCertificateLease()
        )

        let model = makeModel(
            session: session,
            purchaseClaimResolver: purchaseClaimResolver,
            statusFetcher: statusFetcher,
            certificateIssuer: certificateIssuer
        )

        await model.resolvePurchaseClaim()

        #expect(model.errorMessage == ActivationModelError.missingClaimInput.errorDescription)
        #expect(purchaseClaimResolver.resolveCount == 0)
    }

    @Test func activationFailureAppendsRestartPromptWhenHelperUpdateExists() async {
        let session = TestData.makeActivationSession()
        let purchaseClaimResolver = RecordingPurchaseClaimResolver(session: session)
        purchaseClaimResolver.error = TestFailure.fetchFailed
        let statusFetcher = RecordingEntitlementStatusFetcher(
            status: TestData.makeEntitlementStatus(
                license: LicenseEnvelope(
                    licenseID: session.licenseID,
                    licenseClass: .full,
                    issuedTo: "Acme",
                    issuedAt: TestData.baseNow,
                    expiresAt: TestData.baseNow.addingTimeInterval(3600),
                    certificateChain: TestData.makeCertificateChain()
                )
            )
        )
        let recoveryProviderCalled = LockIsolated(false)
        let model = ActivationModel(
            configuration: .init(requestedFeature: "swiftui.support", frameworkVersion: "2.0.0"),
            purchaseClaimResolver: purchaseClaimResolver,
            trialIssuer: RecordingTrialIssuer(session: session),
            entitlementStatusFetcher: statusFetcher,
            intermediateCertificateIssuer: RecordingIntermediateCertificateIssuer(
                lease: TestData.makeIntermediateCertificateLease()
            ),
            deviceFingerprintProvider: { TestData.makeChallenge().device },
            certificateSigningRequestProvider: { "csr" },
            activationHandler: { _ in
                TestData.makeHostActivationResponse(session: session)
            },
            activationFailureRecoveryMessageProvider: {
                await recoveryProviderCalled.setValue(true)
                return "Restart LookInside to load the updated authenticator."
            },
            clock: FixedClock(currentDate: TestData.baseNow)
        )
        model.licenseKey = session.orderID ?? ""
        model.email = session.email ?? ""

        await model.resolvePurchaseClaim()

        #expect(model.errorMessage?.contains("fetchFailed") == true)
        #expect(model.errorMessage?.contains("Restart LookInside") == true)
        #expect(await recoveryProviderCalled.value == true)
    }

    @Test func localActivationValidationSkipsRestartPrompt() async {
        let session = TestData.makeActivationSession()
        let recoveryProviderCalled = LockIsolated(false)
        let model = ActivationModel(
            configuration: .init(requestedFeature: "swiftui.support", frameworkVersion: "2.0.0"),
            purchaseClaimResolver: RecordingPurchaseClaimResolver(session: session),
            trialIssuer: RecordingTrialIssuer(session: session),
            entitlementStatusFetcher: RecordingEntitlementStatusFetcher(
                status: TestData.makeEntitlementStatus(
                    license: LicenseEnvelope(
                        licenseID: session.licenseID,
                        licenseClass: .full,
                        issuedTo: "Acme",
                        issuedAt: TestData.baseNow,
                        expiresAt: TestData.baseNow.addingTimeInterval(3600),
                        certificateChain: TestData.makeCertificateChain()
                    )
                )
            ),
            intermediateCertificateIssuer: RecordingIntermediateCertificateIssuer(
                lease: TestData.makeIntermediateCertificateLease()
            ),
            deviceFingerprintProvider: { TestData.makeChallenge().device },
            certificateSigningRequestProvider: { "csr" },
            activationHandler: { _ in
                TestData.makeHostActivationResponse(session: session)
            },
            activationFailureRecoveryMessageProvider: {
                await recoveryProviderCalled.setValue(true)
                return "Restart LookInside to load the updated authenticator."
            },
            clock: FixedClock(currentDate: TestData.baseNow)
        )

        await model.resolvePurchaseClaim()

        #expect(model.errorMessage == ActivationModelError.missingClaimInput.errorDescription)
        #expect(await recoveryProviderCalled.value == false)
    }

    private func makeModel(
        session: ActivationSession,
        purchaseClaimResolver: RecordingPurchaseClaimResolver,
        statusFetcher: RecordingEntitlementStatusFetcher,
        certificateIssuer: RecordingIntermediateCertificateIssuer
    ) -> ActivationModel {
        let device = TestData.makeChallenge().device

        return ActivationModel(
            configuration: .init(requestedFeature: "swiftui.support", frameworkVersion: "2.0.0"),
            purchaseClaimResolver: purchaseClaimResolver,
            trialIssuer: RecordingTrialIssuer(session: session),
            entitlementStatusFetcher: statusFetcher,
            intermediateCertificateIssuer: certificateIssuer,
            deviceFingerprintProvider: { device },
            certificateSigningRequestProvider: { "csr-\(session.sessionID)" },
            activationHandler: { request in
                HostActivationResponse(
                    activation: SignedActivationEnvelope(
                        activationID: "activation-\(session.sessionID)",
                        challengeNonce: request.challenge.nonce,
                        licenseID: request.license.licenseID,
                        issuedAt: TestData.baseNow,
                        expiresAt: TestData.baseNow.addingTimeInterval(3600),
                        intermediateCertificateID: request.license.certificateChain.intermediateCertificateID,
                        boundUDID: request.challenge.device.deviceID,
                        artifacts: []
                    ),
                    path: .direct,
                    secureTimestamp: nil
                )
            },
            clock: FixedClock(currentDate: TestData.baseNow)
        )
    }
}

private actor LockIsolated<Value> {
    private var storage: Value

    init(_ value: Value) {
        storage = value
    }

    var value: Value {
        storage
    }

    func setValue(_ value: Value) {
        storage = value
    }
}
