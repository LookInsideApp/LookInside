import Foundation
import Observation

public typealias ActivationDeviceFingerprintProvider = @Sendable () async throws -> DeviceFingerprint
public typealias ActivationCertificateSigningRequestProvider = @Sendable () async throws -> String
public typealias ActivationHandler =
    @Sendable (HostActivationRequest) async throws -> HostActivationResponse
public typealias ActivationFailureRecoveryMessageProvider = @Sendable () async -> String?

public enum ActivationModelError: Error, Equatable, LocalizedError, Sendable {
    case missingClaimInput
    case missingActivationSession
    case missingEntitlementStatus
    case missingDeviceFingerprint

    public var errorDescription: String? {
        switch self {
        case .missingClaimInput:
            return "Enter the license key and purchase email to continue."
        case .missingActivationSession:
            return "A verified activation session is required before requesting a certificate."
        case .missingEntitlementStatus:
            return "Refresh the entitlement status before completing activation."
        case .missingDeviceFingerprint:
            return "A device fingerprint is required to complete activation."
        }
    }
}

@MainActor
@Observable
public final class ActivationModel {
    public enum Step: Int, CaseIterable, Identifiable, Sendable {
        case claimForm
        case verification
        case eligibilityReview
        case certificateIssue
        case finalActivation
        case licenseStatus

        public var id: Int {
            rawValue
        }

        public var title: String {
            switch self {
            case .claimForm:
                return "Claim Form"
            case .verification:
                return "Verification"
            case .eligibilityReview:
                return "Eligibility Review"
            case .certificateIssue:
                return "CSR & Certificate Issue"
            case .finalActivation:
                return "Final Activation"
            case .licenseStatus:
                return "License Status"
            }
        }
    }

    public var licenseKey = "" {
        didSet {
            let sanitizedLicenseKey = Self.sanitizedLicenseKey(licenseKey)
            if licenseKey != sanitizedLicenseKey {
                licenseKey = sanitizedLicenseKey
            }
        }
    }

    public var email = "" {
        didSet {
            let sanitizedEmail = Self.sanitizedEmail(email)
            if email != sanitizedEmail {
                email = sanitizedEmail
            }
        }
    }

    public private(set) var currentStep: Step = .claimForm
    public private(set) var isBusy = false
    public private(set) var errorMessage: String?
    public private(set) var activationSession: ActivationSession?
    public private(set) var entitlementStatus: EntitlementStatus?
    public private(set) var issuedLease: IntermediateCertificateLease?
    public private(set) var activationResponse: HostActivationResponse?
    public private(set) var lastDeviceFingerprint: DeviceFingerprint?
    public private(set) var isShowingActivationForm: Bool = false
    public private(set) var licenseStatusRefreshMessage: String?
    /// Hint shown in the license window about the license key's keychain
    /// access: paused after a refused prompt or after Not Now, or a
    /// suggestion to choose Always Allow after a one-time Allow.
    public private(set) var keychainAccessNotice: String?
    /// `true` when the notice offers Try Again (the key's use is paused).
    public private(set) var offersKeychainAccessRetry = false
    /// `true` while Try Again waits for the keychain.
    public private(set) var isRetryingKeychainAccess = false
    /// Runs Try Again: one explicit use of the license key. Set by
    /// `ActivationRuntime`.
    package var keychainRetryAction: (@MainActor () async throws -> Void)?

    private let configuration: ActivationUIConfiguration
    private let purchaseClaimResolver: any PurchaseClaimResolving
    private let trialIssuer: any TrialIssuing
    private let entitlementStatusFetcher: any EntitlementStatusFetching
    private let intermediateCertificateIssuer: any IntermediateCertificateIssuing
    private let deviceFingerprintProvider: ActivationDeviceFingerprintProvider
    private let certificateSigningRequestProvider: ActivationCertificateSigningRequestProvider
    private let activationHandler: ActivationHandler
    private let activationFailureRecoveryMessageProvider: ActivationFailureRecoveryMessageProvider
    private let clock: any Clock

    public init(
        configuration: ActivationUIConfiguration = .init(),
        purchaseClaimResolver: any PurchaseClaimResolving,
        trialIssuer: any TrialIssuing,
        entitlementStatusFetcher: any EntitlementStatusFetching,
        intermediateCertificateIssuer: any IntermediateCertificateIssuing,
        deviceFingerprintProvider: @escaping ActivationDeviceFingerprintProvider,
        certificateSigningRequestProvider: @escaping ActivationCertificateSigningRequestProvider,
        activationHandler: @escaping ActivationHandler,
        activationFailureRecoveryMessageProvider:
        @escaping ActivationFailureRecoveryMessageProvider = { nil },
        clock: any Clock = SystemClock()
    ) {
        self.configuration = configuration
        self.purchaseClaimResolver = purchaseClaimResolver
        self.trialIssuer = trialIssuer
        self.entitlementStatusFetcher = entitlementStatusFetcher
        self.intermediateCertificateIssuer = intermediateCertificateIssuer
        self.deviceFingerprintProvider = deviceFingerprintProvider
        self.certificateSigningRequestProvider = certificateSigningRequestProvider
        self.activationHandler = activationHandler
        self.activationFailureRecoveryMessageProvider = activationFailureRecoveryMessageProvider
        self.clock = clock
    }

    public var highlightedMessage: String? {
        if let errorMessage {
            return errorMessage
        }

        return entitlementStatus?.warningMessage ?? entitlementStatus?.license.deviceWarning
    }

    public var isRefreshingLicenseStatus: Bool {
        licenseStatusRefreshMessage != nil
    }

    public var canIssueCertificate: Bool {
        activationSession != nil && entitlementStatus?.isEligibleForActivation == true
    }

    public var canCompleteActivation: Bool {
        canIssueCertificate && (issuedLease != nil || entitlementStatus?.currentLease != nil)
    }

    public var isTrialActive: Bool {
        activationResponse != nil && entitlementStatus?.license.licenseClass == .trial
    }

    public func reset() {
        licenseKey = ""
        email = ""
        currentStep = .claimForm
        isBusy = false
        errorMessage = nil
        activationSession = nil
        entitlementStatus = nil
        issuedLease = nil
        activationResponse = nil
        lastDeviceFingerprint = nil
        isShowingActivationForm = false
        licenseStatusRefreshMessage = nil
    }

    public func beginFullActivationFromTrial() {
        licenseKey = ""
        email = ""
        errorMessage = nil
        currentStep = .claimForm
        isShowingActivationForm = true
    }

    public func returnToTrialSummary() {
        errorMessage = nil
        isShowingActivationForm = false
    }

    package func setKeychainAccessNotice(_ notice: KeychainAccessNotice?) {
        keychainAccessNotice = notice?.message
        offersKeychainAccessRetry = notice?.offersRetry ?? false
    }

    /// The license window's Try Again: uses the license key once, which may
    /// show the keychain prompt. The notice updates from the runtime.
    public func retryKeychainAccess() async {
        guard let keychainRetryAction, isRetryingKeychainAccess == false else { return }
        isRetryingKeychainAccess = true
        defer { isRetryingKeychainAccess = false }
        do {
            try await keychainRetryAction()
        } catch {
            ActivationLogger.runtime.error(
                "keychain retry failed: \(String(describing: error), privacy: .public)"
            )
        }
    }

    package func restorePersistedActivationState(
        activationSession: ActivationSession?,
        entitlementStatus: EntitlementStatus?,
        activationResponse: HostActivationResponse?,
        deviceFingerprint: DeviceFingerprint?
    ) {
        let restoredSession = activationSession ?? entitlementStatus?.activationSession
        let hasActivatedLicense = entitlementStatus?.currentLease != nil || activationResponse != nil

        errorMessage = nil
        isBusy = false
        self.activationSession = restoredSession
        self.entitlementStatus = entitlementStatus
        issuedLease = entitlementStatus?.currentLease
        self.activationResponse = activationResponse
        lastDeviceFingerprint =
            deviceFingerprint
                ?? entitlementStatus?.deviceBinding.map {
                    DeviceFingerprint(
                        deviceID: $0.udid,
                        hardwareModel: $0.hardwareModel,
                        operatingSystemVersion: $0.operatingSystemVersion,
                        appBundleID: $0.appBundleID
                    )
                }
        currentStep = hasActivatedLicense ? .licenseStatus : .claimForm
        isShowingActivationForm = false
    }

    public func beginLicenseStatusRefresh(
        message: String? = nil
    ) {
        errorMessage = nil
        licenseStatusRefreshMessage = message ?? String(localized: "Refreshing license status…", bundle: .module)
        if entitlementStatus != nil {
            currentStep = .licenseStatus
            isShowingActivationForm = false
        }
    }

    public func finishLicenseStatusRefresh() {
        licenseStatusRefreshMessage = nil
    }

    public func resolvePurchaseClaim() async {
        await runOperation(startingAt: .verification) {
            guard licenseKey.isEmpty == false,
                  email.isEmpty == false
            else {
                throw ActivationModelError.missingClaimInput
            }

            let device = try await deviceFingerprintProvider()
            lastDeviceFingerprint = device

            let session = try await purchaseClaimResolver.resolvePurchaseClaim(
                PurchaseClaimRequest(
                    licenseKey: licenseKey,
                    email: email,
                    device: device
                )
            )

            activationSession = session
            currentStep = .eligibilityReview
            try await fetchEntitlementStatus(forceRefresh: true)
        }
    }

    public func issueTrial() async {
        await runOperation(startingAt: .verification) {
            let device = try await deviceFingerprintProvider()
            lastDeviceFingerprint = device

            let session = try await trialIssuer.issueTrial(
                TrialIssueRequest(device: device)
            )

            activationSession = session
            currentStep = .eligibilityReview
            try await fetchEntitlementStatus(forceRefresh: true)
        }
    }

    public func refreshEntitlementStatus(forceRefresh: Bool = true) async {
        await runOperation(startingAt: .eligibilityReview) {
            try await fetchEntitlementStatus(forceRefresh: forceRefresh)
        }
    }

    public func issueIntermediateCertificate() async {
        await runOperation(startingAt: .certificateIssue) {
            guard let activationSession else {
                throw ActivationModelError.missingActivationSession
            }

            let csr = try await certificateSigningRequestProvider()
            let lease = try await intermediateCertificateIssuer.issueIntermediateCertificate(
                IntermediateCertificateIssueRequest(
                    activationSessionToken: activationSession.token,
                    deviceIdentifier: activationSession.deviceIdentifier,
                    certificateSigningRequestPEM: csr
                )
            )

            issuedLease = lease
            mergeEntitlementStatus(with: lease)
            currentStep = .finalActivation
        }
    }

    public func completeActivation() async {
        await runOperation(startingAt: .finalActivation) {
            guard let entitlementStatus else {
                throw ActivationModelError.missingEntitlementStatus
            }

            let device = try await resolveDeviceFingerprint(for: entitlementStatus)
            let challenge = ClientActivationChallenge(
                nonce: UUID().uuidString.lowercased(),
                issuedAt: clock.now(),
                requestedFeature: configuration.requestedFeature,
                frameworkVersion: configuration.frameworkVersion,
                device: device
            )

            let effectiveLease = issuedLease ?? entitlementStatus.currentLease
            let effectiveLicense =
                if let effectiveLease {
                    entitlementStatus.license.applying(lease: effectiveLease)
                } else {
                    entitlementStatus.license
                }

            activationResponse = try await activationHandler(
                HostActivationRequest(
                    challenge: challenge,
                    license: effectiveLicense
                )
            )
            currentStep = .licenseStatus
        }
    }

    public func runActivationFlow() async {
        await resolvePurchaseClaim()
        guard errorMessage == nil else {
            return
        }

        await issueIntermediateCertificate()
        guard errorMessage == nil else {
            return
        }

        await completeActivation()
        if errorMessage == nil {
            isShowingActivationForm = false
        }
    }

    public func runTrialFlow() async {
        await issueTrial()
        guard errorMessage == nil else {
            return
        }

        await issueIntermediateCertificate()
        guard errorMessage == nil else {
            return
        }

        await completeActivation()
    }

    private func runOperation(
        startingAt step: Step,
        _ operation: @MainActor () async throws -> Void
    ) async {
        isBusy = true
        errorMessage = nil
        currentStep = step

        do {
            try await operation()
        } catch {
            let baseMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            if shouldCheckForRecoveryMessage(after: error),
               let recoveryMessage = await activationFailureRecoveryMessageProvider(),
               recoveryMessage.isEmpty == false
            {
                errorMessage = "\(baseMessage)\n\n\(recoveryMessage)"
            } else {
                errorMessage = baseMessage
            }
        }

        isBusy = false
    }

    private func shouldCheckForRecoveryMessage(after error: Error) -> Bool {
        if error is ActivationModelError {
            return false
        }
        return true
    }

    private func fetchEntitlementStatus(forceRefresh: Bool) async throws {
        guard let activationSession else {
            throw ActivationModelError.missingActivationSession
        }

        let status = try await entitlementStatusFetcher.fetchEntitlementStatus(
            EntitlementStatusRequest(
                licenseID: activationSession.licenseID,
                deviceID: activationSession.deviceIdentifier,
                forceRefresh: forceRefresh,
                activationSessionToken: activationSession.token
            )
        )

        entitlementStatus = EntitlementStatus(
            license: status.license,
            deviceBinding: status.deviceBinding,
            currentLease: status.currentLease,
            activationSession: activationSession,
            isEligibleForActivation: status.isEligibleForActivation,
            isEligibleForRenewal: status.isEligibleForRenewal,
            requiresLiveRefresh: status.requiresLiveRefresh,
            lastFetchedAt: status.lastFetchedAt,
            informationalMessage: status.informationalMessage,
            warningMessage: status.warningMessage
        )
    }

    private func mergeEntitlementStatus(with lease: IntermediateCertificateLease) {
        guard let entitlementStatus else {
            return
        }

        self.entitlementStatus = EntitlementStatus(
            license: entitlementStatus.license.applying(lease: lease),
            deviceBinding: entitlementStatus.deviceBinding,
            currentLease: lease,
            activationSession: activationSession ?? entitlementStatus.activationSession,
            isEligibleForActivation: entitlementStatus.isEligibleForActivation,
            isEligibleForRenewal: entitlementStatus.isEligibleForRenewal,
            requiresLiveRefresh: entitlementStatus.requiresLiveRefresh,
            lastFetchedAt: entitlementStatus.lastFetchedAt,
            informationalMessage: entitlementStatus.informationalMessage,
            warningMessage: entitlementStatus.warningMessage
        )
    }

    private func resolveDeviceFingerprint(for status: EntitlementStatus) async throws -> DeviceFingerprint {
        if let lastDeviceFingerprint {
            return lastDeviceFingerprint
        }

        if let deviceBinding = status.deviceBinding {
            let fingerprint = DeviceFingerprint(
                deviceID: deviceBinding.udid,
                hardwareModel: deviceBinding.hardwareModel,
                operatingSystemVersion: deviceBinding.operatingSystemVersion,
                appBundleID: deviceBinding.appBundleID
            )
            lastDeviceFingerprint = fingerprint
            return fingerprint
        }

        let device = try await deviceFingerprintProvider()
        lastDeviceFingerprint = device
        return device
    }

    private static func sanitizedEmail(_ email: String) -> String {
        email.components(separatedBy: .whitespacesAndNewlines).joined()
    }

    private static func sanitizedLicenseKey(_ licenseKey: String) -> String {
        licenseKey
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "－", with: "-")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .uppercased()
    }
}
