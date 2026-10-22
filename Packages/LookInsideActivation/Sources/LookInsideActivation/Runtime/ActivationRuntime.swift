import Foundation

/// Coarse activation state for synchronous callers such as menu validation.
public enum ActivationState: Int, Sendable {
    /// No decision has been made yet. `ActivationRuntime` evaluates the stored
    /// state when it is created, so this only shows up before that.
    case unknown
    case notActivated
    case activated

    init(_ decision: ActivationAccessDecision) {
        self = decision.grantsAccess ? .activated : .notActivated
    }
}

/// Handle returned by `ActivationRuntime.addDecisionObserver(_:)`.
public final class ActivationObservation: Sendable {
    private let onCancel: @Sendable () -> Void

    init(onCancel: @escaping @Sendable () -> Void) {
        self.onCancel = onCancel
    }

    public func cancel() {
        onCancel()
    }

    deinit {
        onCancel()
    }
}

/// In-process replacement for the LookInside Auth helper.
///
/// One instance owns the state store, the keychain key, the access evaluator
/// and the silent certificate renewer. It answers what the Host used to ask the
/// helper over its socket:
///
/// | helper RPC               | runtime API                         |
/// | ------------------------ | ----------------------------------- |
/// | `license.check_access`   | `currentDecision()`                 |
/// | `license.refresh_status` | `refreshedDecision()`               |
/// | `license.sign_challenge` | `signChallenge(nonce:serverInstanceID:)` |
/// | `health.ping`            | not needed (`statusSummary`)        |
/// | `ui.*`                   | `LookInsideActivationUI`            |
///
/// Every decision it computes is published to observers when it differs from
/// the previous one.
public final class ActivationRuntime: Sendable {
    public let configuration: ActivationConfiguration

    let stateStore: ActivationStateStore
    let keyStore: IntermediateKeyStore
    let evaluator: ActivationAccessEvaluator
    let renewer: ActivationCertificateRenewer
    private let apiClientFactory: @Sendable () -> LookInsideAuthenticatorAPIClient
    private let now: @Sendable () -> Date
    private let silentRenewalEnabled: Bool
    /// The app-wide signing policy: every use of the license key, by the
    /// handshake, by silent renewal or by a user action, goes through it.
    let signingGate: ActivationSigningGate
    private let broadcaster: DecisionBroadcaster
    private let monitor = MonitorTaskBox()
    @MainActor private var cachedModel: ActivationModel?
    @MainActor private var modelSigningObservation: ActivationObservation?

    /// Creates a runtime and evaluates the stored state right away, so
    /// `activationState` is known before the first async call.
    public convenience init(configuration: ActivationConfiguration = .standard) {
        self.init(
            configuration: configuration,
            urlSession: .shared,
            now: { Date() }
        )
    }

    /// `keychainAccessMarkers` remembers, in the Host's own defaults and per
    /// key identity, a key the Host created, one that signed without a
    /// prompt, or one whose keychain explainer the user confirmed. By default it is
    /// used only for the login keychain (`keyStore.keychainPath == nil`); a
    /// file keychain is a test keychain, and its keys never need the keychain
    /// explainer.
    init(
        configuration: ActivationConfiguration,
        urlSession: URLSession,
        now: @escaping @Sendable () -> Date,
        silentRenewalEnabled: Bool = true,
        keychainAccessMarkers: KeychainAccessMarkers? = nil
    ) {
        self.configuration = configuration
        self.now = now
        self.silentRenewalEnabled = silentRenewalEnabled
        let markers =
            keychainAccessMarkers
                ?? (configuration.keyStore.keychainPath == nil ? KeychainAccessMarkers(defaults: .standard) : nil)
        let keyStoreBox = KeyStoreBox()
        // The stored key's public-key hash: markers are kept per key, so a
        // new key is assessed afresh.
        let keyIdentity: @Sendable () -> String? = {
            guard let identity = try? keyStoreBox.keyStore?.keyIdentity() else { return nil }
            return identity.map { String(format: "%02x", $0) }.joined()
        }
        let signingGate = ActivationSigningGate(
            launchedAt: now(),
            now: now,
            markers: markers,
            keyIdentity: markers == nil ? nil : keyIdentity
        )
        self.signingGate = signingGate
        // A new, renewed or lost license lets every channel handshake again.
        broadcaster = DecisionBroadcaster { previous, decision in
            if previous?.grantsAccess != decision.grantsAccess || previous?.statusSummary != decision.statusSummary {
                signingGate.noteActivationChanged()
            }
        }
        let baseURL = configuration.serviceBaseURL
        let apiClientFactory: @Sendable () -> LookInsideAuthenticatorAPIClient = {
            LookInsideAuthenticatorAPIClient(urlSession: urlSession, baseURL: baseURL)
        }
        self.apiClientFactory = apiClientFactory

        let initialState = ActivationStateStore.loadState(from: configuration.stateFileURL)
        let stateStore = ActivationStateStore(
            url: configuration.stateFileURL,
            initialState: initialState,
            now: now
        )
        self.stateStore = stateStore
        let keyStore = IntermediateKeyStore(
            configuration: configuration.keyStore,
            didCreateKey: { signingGate.noteKeyCreatedByHost() }
        )
        keyStoreBox.keyStore = keyStore
        self.keyStore = keyStore
        let evaluator = ActivationAccessEvaluator(
            stateStore: stateStore,
            apiClientFactory: apiClientFactory,
            now: now
        )
        self.evaluator = evaluator
        let appBundleID = configuration.fingerprintAppBundleID
        renewer = ActivationCertificateRenewer(
            stateStore: stateStore,
            clientFactory: apiClientFactory,
            csrProvider: {
                let fingerprint = try ActivationDeviceFingerprint.current(appBundleID: appBundleID)
                return try keyStore.makeCertificateSigningRequestPEM(
                    commonName: "LookInside Device \(fingerprint.deviceID)"
                )
            },
            keyIdentity: { try keyStore.keyIdentity() },
            sessionRefresher: { [weak evaluator] in
                try await evaluator?.ensureSessionFresh()
            },
            now: now,
            signingGate: signingGate
        )
        broadcaster.seed(ActivationAccessEvaluator.decision(from: initialState, evaluatedAt: now()))
    }

    // MARK: - State

    /// Last published decision, or `nil` before the first evaluation.
    public var lastDecision: ActivationAccessDecision? {
        broadcaster.lastDecision
    }

    /// Coarse state from the last published decision. Safe to read from any
    /// thread without waiting.
    public var activationState: ActivationState {
        broadcaster.lastDecision.map(ActivationState.init) ?? .unknown
    }

    /// `license.check_access`: evaluates the stored state offline (no network),
    /// publishes the decision when it changed and schedules a silent
    /// certificate renewal.
    ///
    /// Offline behaviour is the helper's: an active license keeps access until
    /// its lease or license end date, and a recent failed renewal close to that
    /// date turns the decision into `allowWithWarning`.
    ///
    /// Re-reads `state.json` first when another process changed it.
    @discardableResult
    public func currentDecision() async -> ActivationAccessDecision {
        await stateStore.reloadIfChanged()
        let decision = await evaluator.currentDecision()
        broadcaster.publish(decision)
        scheduleSilentRenewal()
        return decision
    }

    /// `license.refresh_status`: refreshes the activation session when due,
    /// fetches the license status from the server, persists it and returns the
    /// new decision. Without a stored session it returns `currentDecision()`.
    @discardableResult
    public func refreshedDecision() async throws -> ActivationAccessDecision {
        await stateStore.reloadIfChanged()
        let decision = try await evaluator.refreshedDecision()
        broadcaster.publish(decision)
        scheduleSilentRenewal()
        return decision
    }

    /// `true` when this process holds license material: a completed activation
    /// or a current lease, including an in-memory trial.
    public func hasLicenseMaterial() async -> Bool {
        await stateStore.reloadIfChanged()
        let snapshot = await stateStore.snapshot()
        return snapshot.activationResponse != nil || snapshot.entitlementStatus?.currentLease != nil
    }

    /// Read-only view of the stored state.
    public func snapshot() async -> ActivationSnapshot {
        ActivationSnapshot(await stateStore.snapshot())
    }

    // MARK: - License handshake

    /// `license.sign_challenge`: signs `nonce || serverInstanceID.utf8` with the
    /// intermediate key (RSA-PKCS1v15-SHA256) and returns the signature, the
    /// intermediate certificate DER and the bound UDID, exactly as the helper
    /// returned them.
    ///
    /// Throws `ActivationError.invalidRequest` for a nonce that is not 32 bytes
    /// or an empty instance identifier, and `.licenseNotActivated` when access
    /// is blocked or no unexpired lease is stored. The signing policy decides
    /// whether the key may be used now; when it may not (no window shown yet,
    /// the keychain explainer not confirmed, or waiting after a refused
    /// keychain prompt) this throws
    /// `.signingDeferred` without touching the keychain. A refused prompt
    /// throws `.keychainAccessDenied` and stops automatic signing for a while.
    /// `channel` names the Server connection, so a failure there is not
    /// retried until it reconnects. Key uses run one at a time; see
    /// `ActivationSigningGate`.
    public func signChallenge(
        nonce: Data,
        serverInstanceID: String,
        channel: String? = nil
    ) async throws -> ActivationChallengeSignature {
        try await signChallengeMeasured(nonce: nonce, serverInstanceID: serverInstanceID, channel: channel).signature
    }

    /// `signChallenge(nonce:serverInstanceID:channel:)` that also returns how
    /// long the key took in its turn (`keyUseDuration`): the keychain's time,
    /// including a prompt, without the time spent waiting behind other uses
    /// of the key.
    public func signChallengeMeasured(
        nonce: Data,
        serverInstanceID: String,
        channel: String? = nil
    ) async throws -> (signature: ActivationChallengeSignature, keyUseDuration: TimeInterval) {
        let request = ActivationSignChallengeRequest(
            nonce: nonce.map { String(format: "%02x", $0) }.joined(),
            serverInstanceID: serverInstanceID
        )
        await stateStore.reloadIfChanged()
        let evaluatedAt = now()
        let snapshot = await stateStore.snapshot()
        let decision = ActivationAccessEvaluator.decision(from: snapshot, evaluatedAt: evaluatedAt)
        let validated = try ActivationChallengeSigner.validate(
            request: request,
            snapshot: snapshot,
            decision: decision,
            evaluatedAt: evaluatedAt
        )
        let keyStore = keyStore
        let message = validated.message
        let (signature, duration) = try await signingGate.performMeasured(.licenseHandshake, channel: channel) {
            try keyStore.sign(message: message)
        }
        let result = ActivationChallengeSignature(
            signature: signature,
            intermediateCertificateDER: validated.certificateDER,
            udid: validated.lease.udid
        )
        return (result, duration)
    }

    /// Blocking form of `signChallenge(nonce:serverInstanceID:channel:)` for
    /// the Objective-C connection code, which asks from a background queue.
    /// Do not call it on the main thread.
    public func signChallengeBlocking(
        nonce: Data,
        serverInstanceID: String,
        channel: String? = nil
    ) throws -> ActivationChallengeSignature {
        try signChallengeMeasuredBlocking(nonce: nonce, serverInstanceID: serverInstanceID, channel: channel).signature
    }

    /// Blocking form of `signChallengeMeasured(nonce:serverInstanceID:channel:)`.
    /// Do not call it on the main thread.
    public func signChallengeMeasuredBlocking(
        nonce: Data,
        serverInstanceID: String,
        channel: String? = nil
    ) throws -> (signature: ActivationChallengeSignature, keyUseDuration: TimeInterval) {
        let box = ResultBox<MeasuredSignature>()
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached { [self] in
            do {
                let (signature, duration) = try await signChallengeMeasured(
                    nonce: nonce,
                    serverInstanceID: serverInstanceID,
                    channel: channel
                )
                box.set(.success(MeasuredSignature(signature: signature, keyUseDuration: duration)))
            } catch {
                box.set(.failure(error))
            }
            semaphore.signal()
        }
        semaphore.wait()
        let measured = try box.get()
        return (measured.signature, measured.keyUseDuration)
    }

    /// `true` when a license handshake may start on `channel` now: the Host
    /// has shown a window, automatic signing is not waiting after a refused
    /// keychain prompt, and no handshake failed on `channel` since it
    /// connected, since the activation changed or since a denial wait ended.
    /// For a key LookInside did not create, the user must also have confirmed
    /// the keychain explainer; when only that is missing, this asks the Host
    /// to show it (`ActivationSigningStatus.needsKeychainAccessExplainer`).
    public func allowsLicenseHandshake(onChannel channel: String?) -> Bool {
        signingGate.allowsHandshake(onChannel: channel)
    }

    /// Records that the Server on `channel` rejected the handshake (or sent
    /// a malformed challenge), so the handshake is not repeated there.
    public func noteLicenseHandshakeFailed(onChannel channel: String) {
        signingGate.noteHandshakeFailed(onChannel: channel)
    }

    /// Forgets `channel`'s handshake failures after it disconnected.
    public func noteLicenseHandshakeChannelEnded(_ channel: String) {
        signingGate.noteChannelEnded(channel)
    }

    /// Lets automatic signing start. The Host calls it once it has shown its
    /// first window: license handshakes may then sign, and silent renewal
    /// may after the launch delay.
    public func noteFirstWindowShown() {
        signingGate.noteFirstWindowShown()
    }

    /// Current signing status: whether automatic signing waits after a
    /// refused keychain prompt.
    public var signingStatus: ActivationSigningStatus {
        signingGate.status
    }

    /// Calls `handler` with the signing status now and whenever it changes,
    /// on an arbitrary thread. A change of `handshakeGeneration` means held
    /// back handshakes may start.
    public func addSigningStatusObserver(
        _ handler: @escaping @Sendable (ActivationSigningStatus) -> Void
    ) -> ActivationObservation {
        signingGate.addObserver(handler)
    }

    /// The license window's Try Again: uses the stored license key once,
    /// which may show the keychain prompt. On success automatic signing
    /// resumes at once and every channel may handshake again. Never creates
    /// a key.
    public func retryKeychainAccess() async throws {
        let keyStore = keyStore
        let probe = Data("LookInside license key access check".utf8)
        _ = try await signingGate.perform(.userAction) {
            try keyStore.signWithExistingKey(message: probe)
        }
    }

    // MARK: - Keychain explainer

    /// Continue in the keychain explainer: confirms it for the stored key
    /// (it does not come back for that key) and lets the held-back automatic
    /// uses start: the handshakes waiting for it (through
    /// `ActivationSigningStatus.handshakeGeneration`) and silent renewal. The
    /// first of them raises the system prompt and counts as the user's use,
    /// so Continue costs no signing of its own.
    public func confirmKeychainAccessExplainer() {
        signingGate.confirmExplainer()
        scheduleSilentRenewal()
    }

    /// Not Now in the keychain explainer: counts as a denied prompt, so
    /// automatic signing waits (an hour, then a day) and the explainer comes
    /// back after the wait. No system prompt is shown. The wait lives in
    /// memory: after a relaunch the explainer is asked for again on the
    /// first automatic use.
    public func declineKeychainAccessExplainer() {
        signingGate.declineExplainer()
    }

    // MARK: - Activation

    /// Starts a trial: issues a trial session, fetches entitlement status,
    /// issues the intermediate certificate and completes local activation.
    /// The trial lives in memory only, like it did in the helper.
    @MainActor
    public func startTrial() async throws {
        let model = activationModel()
        await model.runTrialFlow()
        try finishFlow(model)
    }

    /// Activates with a license key and email (same flow as the activation
    /// window's Activate button).
    @MainActor
    public func activate(licenseKey: String, email: String) async throws {
        let model = activationModel()
        model.licenseKey = licenseKey
        model.email = email
        await model.runActivationFlow()
        try finishFlow(model)
    }

    @MainActor
    private func finishFlow(_ model: ActivationModel) throws {
        if let message = model.errorMessage {
            throw ActivationError.activationFailed(message)
        }
    }

    /// The activation model shared by the activation window and by
    /// `startTrial()` / `activate(licenseKey:email:)`. Created on first use.
    @MainActor
    public func activationModel() -> ActivationModel {
        if let cachedModel {
            return cachedModel
        }
        let model = makeActivationModel()
        cachedModel = model
        let now = now
        model.keychainRetryAction = { [weak self] in
            try await self?.retryKeychainAccess()
        }
        // Keeps the license window's keychain notice current while it is open.
        modelSigningObservation = signingGate.addObserver { [weak model] status in
            let notice = KeychainAccessNotice(status, at: now())
            Task { @MainActor in
                model?.setKeychainAccessNotice(notice)
            }
        }
        return model
    }

    /// Loads the stored state into the shared activation model.
    @MainActor
    public func restoreActivationModel() async {
        await stateStore.reloadIfChanged()
        let snapshot = await stateStore.snapshot()
        let notice = KeychainAccessNotice(signingGate.status, at: now())
        let model = activationModel()
        model.restorePersistedActivationState(
            activationSession: snapshot.activationSession,
            entitlementStatus: snapshot.entitlementStatus,
            activationResponse: snapshot.activationResponse,
            deviceFingerprint: snapshot.deviceFingerprint
        )
        model.setKeychainAccessNotice(notice)
    }

    /// `true` while automatic signing waits after a refused keychain prompt.
    public func isKeychainAccessDenied() -> Bool {
        signingGate.status.isKeychainAccessDenied(at: now())
    }

    @MainActor
    private func makeActivationModel() -> ActivationModel {
        let apiClient = apiClientFactory()
        let stateStore = stateStore
        let keyStore = keyStore
        let signingGate = signingGate
        let appBundleID = configuration.fingerprintAppBundleID
        let hostCoordinator = HostActivationCoordinator(
            replayProtector: InMemoryReplayProtector(),
            secureTimestampFetcher: apiClient,
            activationIssuer: LocalActivationMaterialIssuer()
        )
        return ActivationModel(
            configuration: ActivationUIConfiguration(
                requestedFeature: configuration.requestedFeature,
                frameworkVersion: configuration.frameworkVersion
            ),
            purchaseClaimResolver: PurchaseClaimResolverProxy(apiClient: apiClient, stateStore: stateStore),
            trialIssuer: TrialIssuerProxy(apiClient: apiClient, stateStore: stateStore),
            entitlementStatusFetcher: EntitlementStatusFetcherProxy(apiClient: apiClient, stateStore: stateStore),
            intermediateCertificateIssuer: IntermediateCertificateIssuerProxy(
                apiClient: apiClient,
                stateStore: stateStore
            ),
            deviceFingerprintProvider: {
                let fingerprint = try ActivationDeviceFingerprint.current(appBundleID: appBundleID)
                try await stateStore.recordDeviceFingerprint(fingerprint)
                return fingerprint
            },
            certificateSigningRequestProvider: {
                let fingerprint = try ActivationDeviceFingerprint.current(appBundleID: appBundleID)
                // Activate and Start Trial are user actions: they sign even
                // while automatic signing waits.
                return try await signingGate.perform(.userAction) {
                    try keyStore.makeCertificateSigningRequestPEM(
                        commonName: "LookInside Device \(fingerprint.deviceID)"
                    )
                }
            },
            activationHandler: { [weak self] request in
                let response = try await hostCoordinator.activate(request)
                try await stateStore.recordActivationResponse(response)
                await self?.currentDecision()
                return response
            }
        )
    }

    // MARK: - Renewal

    /// Fires the silent certificate renewer in the background. The renewer
    /// decides whether renewal is due, backs off after failures and asks the
    /// signing policy before it signs (see `ActivationCertificateRenewer`),
    /// so calling it often is cheap. Nothing happens before
    /// `noteFirstWindowShown()`.
    public func scheduleSilentRenewal() {
        guard silentRenewalEnabled, signingGate.status.hasShownFirstWindow else { return }
        let renewer = renewer
        Task.detached(priority: .background) {
            await renewer.tryRenewIfDue()
        }
    }

    /// Re-evaluates the stored state every `interval` (publishing changes and
    /// scheduling renewal), replacing the Host's 5-second helper polling.
    /// Calling it again restarts the loop with the new interval.
    public func startMonitoring(interval: Duration = .seconds(60)) {
        let task = Task.detached(priority: .utility) { [weak self] in
            while Task.isCancelled == false {
                guard let self else { return }
                await self.currentDecision()
                try? await Task.sleep(for: interval)
            }
        }
        monitor.replace(with: task)
    }

    public func stopMonitoring() {
        monitor.replace(with: nil)
    }

    // MARK: - Observation

    /// Decisions as they change. The stream starts with the current decision.
    public func decisionUpdates() -> AsyncStream<ActivationAccessDecision> {
        AsyncStream { continuation in
            let observation = broadcaster.add { decision in
                continuation.yield(decision)
            }
            continuation.onTermination = { _ in
                observation.cancel()
            }
        }
    }

    /// Calls `handler` with the current decision and then on every change, on
    /// an arbitrary thread. Keep the returned observation alive; cancelling or
    /// releasing it stops the calls.
    public func addDecisionObserver(
        _ handler: @escaping @Sendable (ActivationAccessDecision) -> Void
    ) -> ActivationObservation {
        broadcaster.add(handler)
    }
}

/// Read-only view of `state.json` plus in-memory trial state.
public struct ActivationSnapshot: Sendable {
    public let deviceFingerprint: DeviceFingerprint?
    public let activationSession: ActivationSession?
    public let entitlementStatus: EntitlementStatus?
    public let activationResponse: HostActivationResponse?
    public let updatedAt: Date?
    public let lastRenewAttemptAt: Date?
    public let lastRenewSucceededAt: Date?
    public let lastRenewFailedAt: Date?

    init(_ state: ActivationPersistedState) {
        deviceFingerprint = state.deviceFingerprint
        activationSession = state.activationSession
        entitlementStatus = state.entitlementStatus
        activationResponse = state.activationResponse
        updatedAt = state.updatedAt
        lastRenewAttemptAt = state.lastRenewAttemptAt
        lastRenewSucceededAt = state.lastRenewSucceededAt
        lastRenewFailedAt = state.lastRenewFailedAt
    }
}

private final class DecisionBroadcaster: @unchecked Sendable {
    private let lock = NSLock()
    private var current: ActivationAccessDecision?
    private var observers: [UUID: @Sendable (ActivationAccessDecision) -> Void] = [:]
    /// Runs on every change, before the observers are called.
    private let willNotify: @Sendable (ActivationAccessDecision?, ActivationAccessDecision) -> Void

    init(willNotify: @escaping @Sendable (ActivationAccessDecision?, ActivationAccessDecision) -> Void) {
        self.willNotify = willNotify
    }

    var lastDecision: ActivationAccessDecision? {
        lock.withLock { current }
    }

    func seed(_ decision: ActivationAccessDecision) {
        lock.withLock { current = decision }
    }

    func publish(_ decision: ActivationAccessDecision) {
        let change: (ActivationAccessDecision?, [@Sendable (ActivationAccessDecision) -> Void])? = lock.withLock {
            guard current != decision else { return nil }
            let previous = current
            current = decision
            return (previous, Array(observers.values))
        }
        guard let (previous, handlers) = change else { return }
        willNotify(previous, decision)
        guard handlers.isEmpty == false else { return }
        ActivationLogger.runtime.info(
            "activation decision changed: \(decision.decision.rawValue, privacy: .public)"
        )
        for handler in handlers {
            handler(decision)
        }
    }

    func add(_ handler: @escaping @Sendable (ActivationAccessDecision) -> Void) -> ActivationObservation {
        let identifier = UUID()
        let initial: ActivationAccessDecision? = lock.withLock {
            observers[identifier] = handler
            return current
        }
        if let initial {
            handler(initial)
        }
        return ActivationObservation { [weak self] in
            self?.lock.withLock { _ = self?.observers.removeValue(forKey: identifier) }
        }
    }
}

private final class MonitorTaskBox: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, Never>?

    func replace(with newTask: Task<Void, Never>?) {
        let previous = lock.withLock {
            let previous = task
            task = newTask
            return previous
        }
        previous?.cancel()
    }
}

/// Lets the signing gate's explainer assessment reach the key store, which
/// is created after the gate.
private final class KeyStoreBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: IntermediateKeyStore?

    var keyStore: IntermediateKeyStore? {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

private struct MeasuredSignature: Sendable {
    let signature: ActivationChallengeSignature
    let keyUseDuration: TimeInterval
}

private final class ResultBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<Value, any Error>?

    func set(_ result: Result<Value, any Error>) {
        lock.withLock { self.result = result }
    }

    func get() throws -> Value {
        guard let result = lock.withLock({ result }) else {
            throw ActivationError.signingFailed("Signing finished without a result.")
        }
        return try result.get()
    }
}
