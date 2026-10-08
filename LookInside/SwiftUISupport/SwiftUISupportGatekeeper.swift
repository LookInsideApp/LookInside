import AppKit
import Foundation
import LookInsideActivation
import LookInsideActivationUI

@objc public enum SwiftUISupportActivationState: Int {
    case unknown
    case notActivated
    case activated

    init(_ decision: ActivationAccessDecision?) {
        guard let decision else {
            self = .unknown
            return
        }
        self = decision.grantsAccess ? .activated : .notActivated
    }

    var lkDebugDescription: String {
        switch self {
        case .unknown: return "unknown"
        case .notActivated: return "notActivated"
        case .activated: return "activated"
        }
    }
}

private enum SwiftUISupportGatekeeperConstants {
    /// How often the stored license state is re-evaluated, so a lease that runs
    /// out while LookInside is open closes access without a user action.
    static let monitoringInterval: Duration = .seconds(60)
}

/// Gate in front of LookInside Pro features, backed by the in-process
/// activation runtime (`LookInsideActivation`).
///
/// The Objective-C surface is the one the Auth helper bridge had, so the
/// connection, menu, launch and static-update code call it unchanged. The
/// runtime reads and writes the helper's `state.json` and keychain key; this
/// class never launches, updates or removes the helper.
@objcMembers
public final class SwiftUISupportGatekeeper: NSObject {
    private static let shared = SwiftUISupportGatekeeper(runtime: ActivationRuntime())

    public static let activationStateDidChangeNotification = Notification.Name(
        "LKSwiftUISupportActivationStateDidChangeNotification"
    )

    public static var activationStateDidChangeNotificationName: NSString {
        activationStateDidChangeNotification.rawValue as NSString
    }

    /// Posted on the main thread when license handshakes that were held back
    /// may start: the first window appeared, the keychain explainer's
    /// Continue let the held-back handshakes run, Try Again cleared the wait
    /// after a refused keychain prompt, or that wait ended. Connected channels that are not licensed should
    /// handshake again.
    public static let licenseHandshakeAvailabilityDidChangeNotification = Notification.Name(
        "LKSwiftUISupportLicenseHandshakeAvailabilityDidChangeNotification"
    )

    public static var licenseHandshakeAvailabilityDidChangeNotificationName: NSString {
        licenseHandshakeAvailabilityDidChangeNotification.rawValue as NSString
    }

    private let runtime: ActivationRuntime
    private let stateLock = NSLock()
    private var publishedState: SwiftUISupportActivationState
    private var publishedStatusSummary: String?
    private var stateRefreshInFlight = false
    private var licenseStatusRefreshInFlight = false
    private var lastPresentedWarning: String?
    private var decisionObservation: ActivationObservation?
    private var signingObservation: ActivationObservation?
    private var handshakeGeneration: Int?
    /// `false` without an app around the gatekeeper (tests, the end-to-end
    /// harness): no keychain explainer is shown.
    private let presentsKeychainExplainer: Bool

    private let activationPromptLock = NSLock()
    private var hasPendingDetectedSwiftUISupportPrompt = false
    private var hasPromptedForDetectedSwiftUISupport = false
    private var hasPendingDetectionPrompt = false
    private var hasInstalledKeyWindowObserver = false
    private var firstWindowObserver: NSObjectProtocol?

    @MainActor private var cachedWindowCoordinator: ActivationWindowCoordinator?

    /// Creates a gatekeeper over `runtime`. The app uses `sharedInstance()`,
    /// which runs on the standard (helper-compatible) configuration; tests
    /// pass a runtime with an isolated state directory and keychain.
    init(runtime: ActivationRuntime, monitorsState: Bool = true) {
        self.runtime = runtime
        let initialDecision = runtime.lastDecision
        publishedState = SwiftUISupportActivationState(initialDecision)
        publishedStatusSummary = initialDecision?.statusSummary
        presentsKeychainExplainer = monitorsState
        super.init()
        SwiftUISupportLogger.activation.info(
            // Logger interpolations are escaping autoclosures.
            // swiftformat:disable:next redundantSelf
            "activation runtime ready, state=\(self.publishedState.lkDebugDescription, privacy: .public)"
        )
        decisionObservation = runtime.addDecisionObserver { [weak self] decision in
            self?.recordDecision(decision)
        }
        signingObservation = runtime.addSigningStatusObserver { [weak self] status in
            self?.recordSigningStatus(status)
        }
        if monitorsState {
            runtime.startMonitoring(interval: SwiftUISupportGatekeeperConstants.monitoringInterval)
            allowSigningAfterFirstWindow()
        } else {
            // Without an app around it (tests, the end-to-end harness) there
            // is no window to wait for.
            runtime.noteFirstWindowShown()
        }
    }

    /// License handshakes and silent renewal sign with the license key. For
    /// a key the 2.3.x helper created, the first use raises a login-keychain
    /// prompt, which must not appear while LookInside is still launching.
    /// Both are held back until a window has been shown (renewal also waits
    /// for the runtime's launch delay).
    private func allowSigningAfterFirstWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if NSApp?.windows.contains(where: { $0.isVisible }) == true {
                self.runtime.noteFirstWindowShown()
                return
            }
            self.firstWindowObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self, let observer = self.firstWindowObserver else { return }
                NotificationCenter.default.removeObserver(observer)
                self.firstWindowObserver = nil
                self.runtime.noteFirstWindowShown()
            }
        }
    }

    /// Posts the handshake-availability notification when held-back
    /// handshakes may start, and shows the keychain explainer when an
    /// automatic use of the license key waits for it.
    private func recordSigningStatus(_ status: ActivationSigningStatus) {
        if status.needsKeychainAccessExplainer, presentsKeychainExplainer {
            presentKeychainAccessExplainer()
        }
        let shouldNotify: Bool = stateLock.withLock {
            defer { handshakeGeneration = status.handshakeGeneration }
            guard let handshakeGeneration else { return false }
            return handshakeGeneration != status.handshakeGeneration
        }
        guard shouldNotify else { return }
        SwiftUISupportLogger.activation.info(
            "license handshakes may start again (generation \(status.handshakeGeneration, privacy: .public))"
        )
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.licenseHandshakeAvailabilityDidChangeNotification, object: self)
        }
    }

    /// For a license key the 2.3.x helper created, macOS asks before
    /// LookInside may use it. The runtime asks for this explainer on the
    /// first automatic use (a handshake or silent renewal), which only
    /// happens after the first window appeared. It is a panel over the main
    /// window that does not take keyboard focus.
    private func presentKeychainAccessExplainer() {
        let runtime = runtime
        onMain { coordinator in
            guard runtime.signingStatus.needsKeychainAccessExplainer else { return }
            let window = NSApp.mainWindow ?? NSApp.keyWindow ?? NSApp.windows.first { $0.isVisible }
            SwiftUISupportLogger.activation.info("showing the keychain access explainer")
            coordinator.showKeychainAccessExplainer(over: window)
        }
    }

    @objc public class func sharedInstance() -> SwiftUISupportGatekeeper {
        shared
    }

    // MARK: - State

    public var activationState: SwiftUISupportActivationState {
        stateLock.withLock { publishedState }
    }

    /// Re-evaluates the stored license state off the main thread. Posts the
    /// state-change notification when the result differs.
    public func refreshActivationStateInBackground() {
        let shouldStart: Bool = stateLock.withLock {
            guard !stateRefreshInFlight else { return false }
            stateRefreshInFlight = true
            return true
        }
        guard shouldStart else { return }
        let runtime = runtime
        Task.detached(priority: .utility) { [weak self] in
            await runtime.currentDecision()
            self?.stateLock.withLock { self?.stateRefreshInFlight = false }
        }
    }

    /// Stops the periodic re-evaluation when LookInside quits. The activation
    /// state on disk is left as it is.
    @objc(shutdownRuntime)
    public func shutdownRuntime() {
        runtime.stopMonitoring()
    }

    private func recordDecision(_ decision: ActivationAccessDecision) {
        let newState = SwiftUISupportActivationState(decision)
        var previousState = SwiftUISupportActivationState.unknown
        let shouldNotify: Bool = stateLock.withLock {
            let stateChanged = publishedState != newState
            let licenseMaterialMayHaveChanged = newState == .activated
                && publishedStatusSummary != decision.statusSummary
            guard stateChanged || licenseMaterialMayHaveChanged else { return false }
            previousState = publishedState
            publishedState = newState
            publishedStatusSummary = decision.statusSummary
            return true
        }
        guard shouldNotify else { return }
        SwiftUISupportLogger.activation.info(
            "activation state changed: \(previousState.lkDebugDescription, privacy: .public) -> \(newState.lkDebugDescription, privacy: .public) (decision=\(decision.decision.rawValue, privacy: .public))"
        )
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Self.activationStateDidChangeNotification,
                object: self,
                userInfo: ["activationState": NSNumber(value: newState.rawValue)]
            )
        }
    }

    // MARK: - Protected features

    /// Callers include reloads and connection flows, so the alert for a
    /// warning or a block is a sheet on `window` and never a modal loop.
    @objc(allowProtectedFeatureAccessForWindow:)
    public func allowProtectedFeatureAccess(for window: NSWindow?) -> Bool {
        let decision = accessDecisionForSynchronousCaller()
        switch decision.decision {
        case .allow:
            return true
        case .allowWithWarning:
            presentWarningOnce(title: decision.title, message: decision.message, window: window)
            return true
        case .block:
            presentAlert(
                title: decision.title,
                message: decision.message,
                style: .warning,
                presentation: .attached(to: window)
            )
            return false
        }
    }

    @objc(canUseProtectedFeatureWithoutPrompt)
    public func canUseProtectedFeatureWithoutPrompt() -> Bool {
        accessDecisionForSynchronousCaller().grantsAccess
    }

    /// The main thread answers from the last published decision and refreshes
    /// it in the background; other threads wait for a fresh evaluation, which
    /// is local and does not touch the network.
    private func accessDecisionForSynchronousCaller() -> ActivationAccessDecision {
        if Thread.isMainThread, let decision = runtime.lastDecision {
            refreshActivationStateInBackground()
            return decision
        }
        return evaluateDecisionBlocking()
    }

    private func evaluateDecisionBlocking() -> ActivationAccessDecision {
        let runtime = runtime
        let box = SwiftUISupportDecisionBox()
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached(priority: .userInitiated) {
            box.decision = await runtime.currentDecision()
            semaphore.signal()
        }
        semaphore.wait()
        return box.decision ?? runtime.lastDecision ?? Self.activationRequiredDecision
    }

    private static var activationRequiredDecision: ActivationAccessDecision {
        ActivationAccessDecision(
            decision: .block,
            title: NSLocalizedString("Activation Required", comment: ""),
            message: NSLocalizedString(
                "Activate LookInside Pro from the LookInside Pro menu before using this feature.",
                comment: ""
            ),
            statusSummary: nil
        )
    }

    // MARK: - License handshake (220 / 221)

    /// `YES` when a license handshake may start on `channelID` now. It may
    /// not before LookInside shows its first window, before the user
    /// confirmed the keychain explainer for a key LookInside did not create
    /// (this call then asks for the explainer), while automatic signing
    /// waits after a refused keychain prompt (an hour, then a day, until Try
    /// Again in the license window), or after a handshake failed on this
    /// channel until it reconnects, the activation changes or the denial
    /// wait ends. Every handshake attempt, including a retry with a fresh
    /// challenge, asks first. A request on a channel without a handshake
    /// still runs; the Server then withholds the Pro features.
    @objc(shouldStartLicenseHandshakeOnChannel:)
    public func shouldStartLicenseHandshake(onChannel channelID: String) -> Bool {
        runtime.allowsLicenseHandshake(onChannel: channelID)
    }

    /// Records that the Server on `channelID` rejected the 221 or sent a
    /// malformed 220, so the handshake is not repeated on that channel.
    @objc(noteLicenseHandshakeFailedOnChannel:)
    public func noteLicenseHandshakeFailed(onChannel channelID: String) {
        runtime.noteLicenseHandshakeFailed(onChannel: channelID)
    }

    /// Forgets `channelID` after it disconnected.
    @objc(licenseHandshakeChannelDidEnd:)
    public func licenseHandshakeChannelDidEnd(_ channelID: String) {
        runtime.noteLicenseHandshakeChannelEnded(channelID)
    }

    /// Signs `nonce || server_instance_id.utf8` with this Mac's intermediate
    /// key. On success writes the RSA-PKCS1v15-SHA256 signature to
    /// `signatureOut`, the DER-encoded intermediate certificate to
    /// `intermediateCertDEROut`, and the device UDID to `udidOut`. Returns
    /// `NO` and populates `error` when the license is not activated, the
    /// lease has expired, the request is malformed, the signing policy holds
    /// the key back or signing fails.
    ///
    /// Blocks until the signature is ready; call it off the main thread.
    @objc(signChallengeWithNonce:serverInstanceID:signature:intermediateCertDER:udid:error:)
    public func signChallenge(
        nonce: Data,
        serverInstanceID: String,
        signature signatureOut: AutoreleasingUnsafeMutablePointer<NSData?>,
        intermediateCertDER intermediateCertDEROut: AutoreleasingUnsafeMutablePointer<NSData?>,
        udid udidOut: AutoreleasingUnsafeMutablePointer<NSString?>
    ) throws {
        try signChallenge(
            nonce: nonce,
            serverInstanceID: serverInstanceID,
            channelID: nil,
            signature: signatureOut,
            intermediateCertDER: intermediateCertDEROut,
            udid: udidOut,
            keyUseDuration: nil
        )
    }

    /// `signChallengeWithNonce:serverInstanceID:signature:...` for the
    /// handshake on `channelID`: a signing that fails there is not repeated
    /// on that channel. `keyUseDuration`, when given, receives how long the
    /// key took in its turn (the keychain's time, including a prompt),
    /// without the time this call waited behind other uses of the key.
    @objc(signChallengeWithNonce:serverInstanceID:channelID:signature:intermediateCertDER:udid:keyUseDuration:error:)
    public func signChallenge(
        nonce: Data,
        serverInstanceID: String,
        channelID: String?,
        signature signatureOut: AutoreleasingUnsafeMutablePointer<NSData?>,
        intermediateCertDER intermediateCertDEROut: AutoreleasingUnsafeMutablePointer<NSData?>,
        udid udidOut: AutoreleasingUnsafeMutablePointer<NSString?>,
        keyUseDuration keyUseDurationOut: UnsafeMutablePointer<TimeInterval>?
    ) throws {
        let result: ActivationChallengeSignature
        do {
            let measured = try runtime.signChallengeMeasuredBlocking(
                nonce: nonce,
                serverInstanceID: serverInstanceID,
                channel: channelID
            )
            result = measured.signature
            keyUseDurationOut?.pointee = measured.keyUseDuration
        } catch let error as ActivationError {
            SwiftUISupportLogger.activation.error(
                "sign_challenge failed code=\(error.errorCode, privacy: .public)"
            )
            throw error
        }
        signatureOut.pointee = result.signature as NSData
        intermediateCertDEROut.pointee = result.intermediateCertificateDER as NSData
        udidOut.pointee = result.udid as NSString
    }

    // MARK: - Windows

    @objc(showActivationWindow)
    public func showActivationWindow() {
        onMain { coordinator in
            Task { await coordinator.showActivationWindow() }
        }
    }

    @objc(showLicenseWindow)
    public func showLicenseWindow() {
        onMain { coordinator in
            Task { await coordinator.showLicenseWindow() }
        }
    }

    /// Fetches the license status from the activation service, shows it in
    /// the license window and reports the result in an alert.
    @objc(refreshLicenseStatus)
    public func refreshLicenseStatus() {
        let shouldStart: Bool = stateLock.withLock {
            guard !licenseStatusRefreshInFlight else { return false }
            licenseStatusRefreshInFlight = true
            return true
        }
        guard shouldStart else { return }

        let runtime = runtime
        onMain { [weak self] coordinator in
            Task { @MainActor in
                defer {
                    self?.stateLock.withLock { self?.licenseStatusRefreshInFlight = false }
                }
                guard await runtime.hasLicenseMaterial() else {
                    let decision = Self.activationRequiredDecision
                    coordinator.showAlert(
                        ActivationAlert(title: decision.title, message: decision.message, style: .warning)
                    )
                    return
                }
                do {
                    let decision = try await coordinator.refreshLicenseStatus()
                    coordinator.showAlert(
                        ActivationAlert(title: decision.title, message: decision.message, style: .warning)
                    )
                } catch {
                    SwiftUISupportLogger.activation.error(
                        "license status refresh failed: \(error.localizedDescription, privacy: .public)"
                    )
                    coordinator.showAlert(
                        ActivationAlert(
                            title: NSLocalizedString("Unable to Refresh License Status", comment: ""),
                            message: error.localizedDescription,
                            style: .warning
                        )
                    )
                }
            }
        }
    }

    // MARK: - SwiftUI detection prompt

    @objc(promptForDetectedSwiftUISupportIfNeededForWindow:)
    public func promptForDetectedSwiftUISupportIfNeeded(window: NSWindow?) {
        noteDetectedSwiftUISupport()
        promptForPendingDetectedSwiftUISupportIfNeeded(window: window)
    }

    @objc(noteDetectedSwiftUISupport)
    public func noteDetectedSwiftUISupport() {
        guard activationState != .activated else { return }

        activationPromptLock.withLock {
            guard !hasPromptedForDetectedSwiftUISupport else { return }
            hasPendingDetectedSwiftUISupportPrompt = true
        }
    }

    @objc(promptForPendingDetectedSwiftUISupportIfNeededForWindow:)
    public func promptForPendingDetectedSwiftUISupportIfNeeded(window: NSWindow?) {
        guard activationState != .activated else { return }

        if isInspectorWindow(window) {
            let shouldPrompt = activationPromptLock.withLock {
                guard !hasPromptedForDetectedSwiftUISupport else { return false }
                hasPromptedForDetectedSwiftUISupport = true
                hasPendingDetectionPrompt = false
                return true
            }
            guard shouldPrompt else { return }
            presentSwiftUISupportActivationPrompt(window: window)
            return
        }

        let needsObserver = activationPromptLock.withLock { () -> Bool in
            guard !hasPromptedForDetectedSwiftUISupport else { return false }
            hasPendingDetectionPrompt = true
            guard !hasInstalledKeyWindowObserver else { return false }
            hasInstalledKeyWindowObserver = true
            return true
        }
        guard needsObserver else { return }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.handleKeyWindowChange(note.object as? NSWindow)
        }
    }

    private func handleKeyWindowChange(_ window: NSWindow?) {
        let alreadyDone = activationPromptLock.withLock {
            hasPromptedForDetectedSwiftUISupport || !hasPendingDetectionPrompt
        }
        guard !alreadyDone else { return }
        guard isInspectorWindow(window) else { return }

        let shouldPrompt = activationPromptLock.withLock {
            guard hasPendingDetectedSwiftUISupportPrompt,
                  !hasPromptedForDetectedSwiftUISupport
            else { return false }
            hasPendingDetectedSwiftUISupportPrompt = false
            hasPromptedForDetectedSwiftUISupport = true
            hasPendingDetectionPrompt = false
            return true
        }
        guard shouldPrompt else { return }
        presentSwiftUISupportActivationPrompt(window: window)
    }

    private func isInspectorWindow(_ window: NSWindow?) -> Bool {
        guard let wc = window?.windowController else { return false }
        return NSStringFromClass(type(of: wc)) == "LKStaticWindowController"
    }

    /// Shown as a sheet on the inspector window that triggered it. As in
    /// 2.3.x, a Mac without stored license material (no activation, lease
    /// or trial) gets no automatic prompt; the LookInside Pro menu still
    /// opens the activation window.
    private func presentSwiftUISupportActivationPrompt(window: NSWindow?) {
        let runtime = runtime
        Task { [weak self, weak window] in
            guard await runtime.hasLicenseMaterial() else {
                SwiftUISupportLogger.activation.info(
                    "activation prompt skipped: no local license material"
                )
                return
            }
            self?.onMain { [weak self] coordinator in
                guard self?.activationState != .activated else { return }
                coordinator.showActivationPrompt(presentation: .attached(to: window))
            }
        }
    }

    // MARK: - Alerts

    /// A warning that still grants access is shown once per message.
    private func presentWarningOnce(title: String, message: String, window: NSWindow?) {
        let shouldPresent: Bool = stateLock.withLock {
            guard lastPresentedWarning != message else { return false }
            lastPresentedWarning = message
            return true
        }
        guard shouldPresent else { return }
        presentAlert(title: title, message: message, style: .warning, presentation: .attached(to: window))
    }

    private func presentAlert(
        title: String,
        message: String,
        style: ActivationAlert.Style,
        presentation: ActivationAlertPresentation
    ) {
        onMain { coordinator in
            coordinator.showAlert(
                ActivationAlert(title: title, message: message, style: style),
                presentation: presentation
            )
        }
    }

    // MARK: - Main thread

    /// Runs `work` on the main thread with the activation window coordinator.
    /// Always asynchronous, so callers on any thread return before an alert or
    /// window appears.
    private func onMain(_ work: @escaping @MainActor (ActivationWindowCoordinator) -> Void) {
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                work(self.windowCoordinator())
            }
        }
    }

    @MainActor
    private func windowCoordinator() -> ActivationWindowCoordinator {
        if let cachedWindowCoordinator {
            return cachedWindowCoordinator
        }
        let coordinator = ActivationWindowCoordinator(runtime: runtime)
        cachedWindowCoordinator = coordinator
        return coordinator
    }
}

private final class SwiftUISupportDecisionBox: @unchecked Sendable {
    var decision: ActivationAccessDecision?
}

#if DEBUG
    public extension SwiftUISupportGatekeeper {
        /// DEBUG end-to-end hook (DebugE2EDump.swift): creates the license key
        /// in the test file keychain and returns a certificate request for
        /// it. See `ActivationRuntime.debugMakeTestKeyCertificateSigningRequestPEM`.
        @objc(debugMakeTestKeyCertificateSigningRequestPEMWithCommonName:error:)
        func debugMakeTestKeyCertificateSigningRequestPEM(commonName: String) throws -> String {
            try runtime.debugMakeTestKeyCertificateSigningRequestPEM(commonName: commonName)
        }

        /// DEBUG end-to-end hook (DebugE2EDump.swift): the Host runs behind
        /// other apps there, so its window never becomes key. The dump calls
        /// this once a Host window is visible, the condition this gatekeeper
        /// itself accepts when it is created after the first window.
        @objc(debugNoteFirstWindowShown)
        func debugNoteFirstWindowShown() {
            runtime.noteFirstWindowShown()
        }

        /// DEBUG UI snapshot hook (DebugUISnapshots.swift): the activation
        /// window with its model restored from the activation state, as
        /// `showActivationWindow()` prepares it, but not presented: the
        /// snapshot shows it without activating the app or floating it.
        @MainActor
        internal func debugPreparedActivationWindow() async -> NSWindow {
            let coordinator = windowCoordinator()
            await runtime.restoreActivationModel()
            return coordinator.activationWindow
        }
    }
#endif
