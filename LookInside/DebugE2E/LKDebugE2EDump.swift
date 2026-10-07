#if DEBUG
    import AppKit
    import Foundation

    /// DEBUG-only end-to-end dump. When LOOKINSIDE_DEBUG_E2E_DUMP_DIR is set,
    /// the Host waits for the first inspectable app after launch (optionally
    /// the one named by LOOKINSIDE_DEBUG_E2E_BUNDLE_ID), opens it through the
    /// same calls the launch window makes, waits for the hierarchy and every
    /// detail the async update manager requests, then writes into the directory:
    ///
    ///   snapshot.json    hierarchy + merged details, normalized like
    ///                    lookin-probe's snapshot (LookinSnapshotNormalizer)
    ///   host-window.png  the Host's own document window, drawn in process
    ///
    /// and exits 0. A step that runs past LOOKINSIDE_DEBUG_E2E_TIMEOUT seconds
    /// (default 240) exits non-zero with a message on stderr. The driver is
    /// Scripts/reborn-e2e/host-dump.sh; Release builds compile this file out.
    ///
    /// Licensed runs (host-dump.sh --licensed) use two more switches:
    ///
    ///   LOOKINSIDE_DEBUG_E2E_PREPARE_LICENSE_CSR=<path>
    ///       Instead of dumping, create the license key in the test file
    ///       keychain (LOOKINSIDE_ACTIVATION_KEYCHAIN_PATH) through the
    ///       activation runtime, write a certificate request for it to <path>
    ///       and exit. The driver issues the intermediate certificate under a
    ///       throwaway root, so the key the Host later signs with is one the
    ///       Host created and uses without a keychain prompt.
    ///   LOOKINSIDE_DEBUG_E2E_EXPECT_LICENSED=1
    ///       Open the app only after the 220/221 license handshake succeeded on
    ///       its channel, so the hierarchy is fetched licensed. The Host runs
    ///       behind other apps, so its window never becomes key; once one of its
    ///       windows is visible the dump satisfies the activation runtime's
    ///       first-window gate itself (debugNoteFirstWindowShown()).
    ///
    /// UI snapshots (Scripts/reborn-e2e/ui-snapshots.sh) add:
    ///
    ///   LOOKINSIDE_DEBUG_E2E_START_FILE=<path>
    ///       Look for the app only once <path> exists. The Host is launched
    ///       before the inspected app, so the launch window is captured with no
    ///       app; the driver then launches the app and creates the file.
    ///   LOOKINSIDE_DEBUG_UI_SNAPSHOT_DIR=<dir>
    ///       After writing the dump, run the UI scenes of LKDebugUISnapshots
    ///       against the loaded document instead of exiting; the Host exits
    ///       when they are done.
    @MainActor
    final class LKDebugE2EDump: NSObject {
        private static let directoryKey = "LOOKINSIDE_DEBUG_E2E_DUMP_DIR"
        private static let bundleIDKey = "LOOKINSIDE_DEBUG_E2E_BUNDLE_ID"
        private static let timeoutKey = "LOOKINSIDE_DEBUG_E2E_TIMEOUT"
        private static let prepareLicenseCSRKey = "LOOKINSIDE_DEBUG_E2E_PREPARE_LICENSE_CSR"
        private static let expectLicensedKey = "LOOKINSIDE_DEBUG_E2E_EXPECT_LICENSED"
        private static let startFileKey = "LOOKINSIDE_DEBUG_E2E_START_FILE"

        /// Exit statuses, so the driver script can tell the failing step.
        private enum ExitStatus: Int32 {
            case success = 0
            case timeout = 3
            case openFailed = 4
            case writeFailed = 5
            case licenseKeyFailed = 6
        }

        private enum Phase {
            case waitingForApp
            case opening
            case loadingDetails
            case settling
            case done
        }

        /// How often the driver checks its state, in seconds.
        private static let tickInterval: TimeInterval = 0.25
        /// How often the app list is fetched while waiting for the target.
        private static let appPollInterval: TimeInterval = 1
        /// The update manager must stay idle this long before details count as
        /// loaded: one detail reply can make the data source start another request.
        private static let idleInterval: TimeInterval = 2
        /// Wait after the details for the preview and outline to draw them.
        private static let settleInterval: TimeInterval = 1.5

        /// The running dump; it lives until the process exits.
        private static var current: LKDebugE2EDump?

        private let directory: String
        private let bundleID: String?
        private let startFile: String?
        private let timeout: TimeInterval
        private let expectsLicensed: Bool
        private var loggedStartWait = false
        private var loggedLicenseWait = false
        private var notedFirstWindow = false

        private var phase: Phase = .waitingForApp
        private var deadline = Date()
        private var timer: Timer?
        private var fetchingApps = false
        private var nextAppPoll: Date?
        private var lastAppListSummary: String?

        private var app: LKInspectableApp?
        private var document: LookinLiveDocument?
        private var sawUpdating = false
        private var idleSince: Date?
        private var settleUntil = Date()

        private init(directory: String, environment: [String: String]) {
            self.directory = directory
            bundleID = environment[Self.bundleIDKey]
            startFile = environment[Self.startFileKey].map { ($0 as NSString).standardizingPath }
            let timeout = (environment[Self.timeoutKey] as NSString?)?.doubleValue ?? 0
            self.timeout = timeout > 0 ? timeout : 240
            expectsLicensed = environment[Self.expectLicensedKey] == "1"
            super.init()
        }

        /// Called at the very start of the app's `main()`, before the app
        /// delegate is set, so the dump sees NSApplicationDidFinishLaunching
        /// before the delegate does.
        static func installIfRequested() {
            let environment = ProcessInfo.processInfo.environment
            if let csrPath = environment[prepareLicenseCSRKey], !csrPath.isEmpty {
                NotificationCenter.default.addObserver(
                    forName: NSApplication.didFinishLaunchingNotification,
                    object: nil,
                    queue: nil
                ) { _ in
                    MainActor.assumeIsolated {
                        prepareLicenseKeyWritingRequest(to: (csrPath as NSString).standardizingPath)
                    }
                }
                return
            }
            guard let directory = environment[directoryKey], !directory.isEmpty else {
                return
            }
            let dump = LKDebugE2EDump(directory: (directory as NSString).standardizingPath, environment: environment)
            current = dump
            NotificationCenter.default.addObserver(
                dump,
                selector: #selector(applicationDidFinishLaunching(_:)),
                name: NSApplication.didFinishLaunchingNotification,
                object: nil
            )
        }

        /// LOOKINSIDE_DEBUG_E2E_PREPARE_LICENSE_CSR: see the type comment.
        private static func prepareLicenseKeyWritingRequest(to path: String) {
            do {
                let pem = try LKSwiftUISupportGatekeeper.sharedInstance()
                    .debugMakeTestKeyCertificateSigningRequestPEM(commonName: "LookInside Host E2E Test Device")
                try pem.write(toFile: path, atomically: true, encoding: .utf8)
            } catch {
                fputs("[host-e2e-dump] FAIL: preparing the license key failed: \(error as NSError)\n", stderr)
                exit(ExitStatus.licenseKeyFailed.rawValue)
            }
            fputs("[host-e2e-dump] license key ready in the test keychain; wrote \(path)\n", stderr)
            exit(ExitStatus.success.rawValue)
        }

        @objc private func applicationDidFinishLaunching(_: Notification) {
            let target = (bundleID?.isEmpty == false) ? bundleID! : "the first inspectable app"
            log("waiting for \(target)\(expectsLicensed ? " on a licensed channel" : "") (timeout \(String(format: "%.0f", timeout))s per step)")
            enterPhase(.waitingForApp)
            if LKDebugUISnapshots.isEnabled {
                LKDebugUISnapshots.captureLaunchScene()
            }
            let timer = Timer.scheduledTimer(
                timeInterval: Self.tickInterval,
                target: self,
                selector: #selector(tick),
                userInfo: nil,
                repeats: true
            )
            self.timer = timer
            // Keep ticking while a menu or a modal sheet runs the loop.
            RunLoop.main.add(timer, forMode: .common)
        }

        // MARK: - Steps

        private func enterPhase(_ phase: Phase) {
            self.phase = phase
            deadline = Date(timeIntervalSinceNow: timeout)
        }

        @objc private func tick() {
            if phase == .done {
                return
            }
            if deadline.timeIntervalSinceNow < 0 {
                fail(.timeout, timeoutMessage())
                return
            }
            switch phase {
            case .waitingForApp:
                noteFirstWindowIfNeeded()
                if let startFile, !startFile.isEmpty, !FileManager.default.fileExists(atPath: startFile) {
                    if !loggedStartWait {
                        loggedStartWait = true
                        log("waiting for \(startFile) before looking for the app")
                    }
                    // The step deadline starts once the driver lets the dump go.
                    enterPhase(.waitingForApp)
                    break
                }
                pollApps()
            case .opening:
                break
            case .loadingDetails:
                checkDetails()
            case .settling:
                if settleUntil.timeIntervalSinceNow <= 0 {
                    writeAndExit()
                }
            case .done:
                break
            }
        }

        private func timeoutMessage() -> String {
            switch phase {
            case .waitingForApp:
                if loggedLicenseWait {
                    let state = LKSwiftUISupportGatekeeper.sharedInstance().activationState.rawValue
                    return "timed out waiting for the license handshake on \(bundleID ?? "the app") (activation state \(state))"
                }
                return "timed out waiting for an inspectable app; last app list: \(lastAppListSummary ?? "none received")"
            case .opening:
                return "timed out fetching the hierarchy and opening the live document"
            case .loadingDetails:
                let updating = document?.asyncUpdateManager?.isUpdating() == true
                return "timed out waiting for the display-item details (update manager \(updating ? "still updating" : "never started"))"
            default:
                return "timed out"
            }
        }

        private func noteFirstWindowIfNeeded() {
            guard expectsLicensed, !notedFirstWindow else {
                return
            }
            if NSApp.windows.contains(where: \.isVisible) {
                notedFirstWindow = true
                LKSwiftUISupportGatekeeper.sharedInstance().debugNoteFirstWindowShown()
                log("a Host window is visible; first-window signing gate satisfied")
            }
        }

        /// Same list the launch window shows: LKDebugE2EDumpWriter.fetchApps(completion:).
        private func pollApps() {
            if fetchingApps {
                return
            }
            if let nextAppPoll, nextAppPoll.timeIntervalSinceNow > 0 {
                return
            }
            fetchingApps = true
            nextAppPoll = Date(timeIntervalSinceNow: Self.appPollInterval)
            LKDebugE2EDumpWriter.fetchApps { [self] apps in
                fetchingApps = false
                guard phase == .waitingForApp else {
                    return
                }
                var summary: [String] = []
                var target: LKInspectableApp?
                for app in apps ?? [] {
                    let bundleID = app.appInfo?.appBundleIdentifier ?? "?"
                    if let error = app.serverVersionError {
                        summary.append("\(bundleID) (server version error \(error.code))")
                    } else {
                        summary.append(bundleID)
                    }
                    if target != nil || app.serverVersionError != nil || app.appInfo == nil {
                        continue
                    }
                    if self.bundleID?.isEmpty != false || bundleID == self.bundleID {
                        target = app
                    }
                }
                lastAppListSummary = summary.isEmpty ? "empty" : summary.joined(separator: ", ")
                guard let target else {
                    return
                }
                // Each app-list request runs the license handshake on the channel
                // first (once the activation runtime allows signing), so polling
                // again is what retries it.
                if expectsLicensed, !LKDebugE2EDumpWriter.isChannelLicensed(for: target) {
                    if !loggedLicenseWait {
                        loggedLicenseWait = true
                        log("found \(target.appInfo?.appBundleIdentifier ?? "(null)"); waiting for the license handshake")
                    }
                    return
                }
                open(target)
            }
        }

        /// Mirrors LKLaunchViewController's app entry: fetch the hierarchy, open
        /// a live document through LookinLiveDocumentController, prime its data
        /// source with that hierarchy, close the launch window. The SwiftUI
        /// activation prompt that follows there is licensing UI and is left out.
        private func open(_ app: LKInspectableApp) {
            let licensed = LKDebugE2EDumpWriter.isChannelLicensed(for: app) ? "YES" : "NO"
            log("opening \(app.appInfo?.appBundleIdentifier ?? "(null)") (channel licensed: \(licensed))")
            self.app = app
            enterPhase(.opening)
            LKDebugE2EDumpWriter.fetchHierarchy(for: app) { [self] info, error in
                if let error {
                    fail(.openFailed, "the hierarchy request failed: \(error as NSError)")
                    return
                }
                guard let info else {
                    fail(.openFailed, "the hierarchy request returned nothing")
                    return
                }
                let (document, alreadyOpen) = LookinLiveDocumentController.shared.openLiveDocument(for: app)
                self.document = document
                enterPhase(.loadingDetails)
                if !alreadyOpen {
                    document.hierarchyDataSource?.reload(with: info, keepState: false)
                }
                LKNavigationManager.shared.closeLaunch()
                log("hierarchy loaded, \(document.hierarchyDataSource?.flatItems?.count ?? 0) items; waiting for details")
            }
        }

        /// Details count as loaded once the document's update manager, which
        /// requests every detail the UI shows, has worked and then stayed idle for
        /// idleInterval.
        private func checkDetails() {
            guard let manager = document?.asyncUpdateManager else {
                return
            }
            if manager.isUpdating() {
                sawUpdating = true
                idleSince = nil
                return
            }
            guard let idleSince else {
                idleSince = Date()
                return
            }
            if !sawUpdating || -idleSince.timeIntervalSinceNow < Self.idleInterval {
                return
            }
            log("details loaded")
            settleUntil = Date(timeIntervalSinceNow: Self.settleInterval)
            enterPhase(.settling)
        }

        private func writeAndExit() {
            phase = .done
            // AppKit swallows an exception raised in a timer callback, which
            // would leave the dump waiting forever. Run the write from the main
            // queue instead, where an exception (from JSONSerialization, say)
            // is uncaught and ends the process with its reason on stderr.
            DispatchQueue.main.async { [self] in
                write()
            }
        }

        private func write() {
            guard let document, let dataSource = document.hierarchyDataSource else {
                fail(.writeFailed, "writing snapshot.json failed: the document has no data source")
                return
            }
            let directoryURL = URL(fileURLWithPath: directory, isDirectory: true)
            let platform = LKHelper.appInfoLooksLikeMacTarget(app?.appInfo) ? "macos" : "ios"
            do {
                try LKDebugE2EDumpWriter.writeSnapshot(for: dataSource, app: document.inspectableApp, platform: platform, to: directoryURL)
            } catch {
                fail(.writeFailed, "writing snapshot.json failed: \(error as NSError)")
                return
            }
            let window = document.windowControllers.first?.window
            let pngURL = directoryURL.appendingPathComponent("host-window.png")
            guard let png = LKDebugWindowImage.pngData(of: window), !png.isEmpty, (try? png.write(to: pngURL, options: .atomic)) != nil else {
                fail(.writeFailed, "capturing the Host window failed")
                return
            }
            log("wrote \(directory)")
            if LKDebugUISnapshots.isEnabled {
                timer?.invalidate()
                LKDebugUISnapshots.runScenes(for: document) { status in
                    exit(status)
                }
                return
            }
            exit(ExitStatus.success.rawValue)
        }

        // MARK: - Output

        private func log(_ message: String) {
            fputs("[host-e2e-dump] \(message)\n", stderr)
            fflush(stderr)
        }

        private func fail(_ status: ExitStatus, _ message: String) {
            phase = .done
            log("FAIL: \(message)")
            exit(status.rawValue)
        }
    }
#endif
