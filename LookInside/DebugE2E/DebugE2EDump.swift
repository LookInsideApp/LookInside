#if DEBUG
    import AppKit
    import Foundation
    import FoundationToolbox

    /// DEBUG-only end-to-end dump. When LOOKINSIDE_DEBUG_E2E_DUMP_DIR is set,
    /// the Host waits for the first inspectable app after launch (optionally
    /// the one named by LOOKINSIDE_DEBUG_E2E_BUNDLE_ID), opens it through the
    /// same calls the launch window makes, waits for the hierarchy and every
    /// detail the async update manager requests, then writes into the directory:
    ///
    ///   snapshot.json    hierarchy + merged details, normalized like
    ///                    lookin-probe's snapshot (SnapshotNormalizer)
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
    /// Every dump also writes timings.json: how long the hierarchy request,
    /// the data source reload and the detail fetch took, and how many items
    /// the hierarchy had. The detail time ends at the first idle tick of the
    /// update manager, so it is accurate to tickInterval. Refresh benchmark
    /// drivers read it. The prefetch that follows the displayed items is
    /// waited for too, so a refresh never overlaps one.
    ///
    /// While details load, each tick is a "Driver tick" signpost event inside
    /// a "Driver loading details" interval (subsystem com.lookinside.app,
    /// category RefreshPerformance): a long gap between ticks is a time the
    /// main thread kept its run loop waiting.
    ///
    ///   LOOKINSIDE_DEBUG_E2E_REFRESH_COUNT=<n>
    ///       After the first load, reload the hierarchy n more times the way
    ///       the toolbar button does, each once the previous one's details
    ///       are in, and add a `refreshes` entry per reload to timings.json.
    ///       The first load builds every preview node; a refresh in an open
    ///       window reuses them, so the two cost differently.
    ///   LOOKINSIDE_DEBUG_E2E_WHOLE_TREE=1
    ///       After the last load's details, fetch what the whole tree misses
    ///       the way an export does first (`fetchWholeTree(then:)`), then
    ///       write: snapshot.json shows whether every node got its
    ///       attributes and screenshots, and timings.json gets
    ///       `wholeTreeMilliseconds`.
    ///
    /// UI snapshots (Scripts/reborn-e2e/ui-snapshots.sh) add:
    ///
    ///   LOOKINSIDE_DEBUG_E2E_START_FILE=<path>
    ///       Look for the app only once <path> exists. The Host is launched
    ///       before the inspected app, so the launch window is captured with no
    ///       app; the driver then launches the app and creates the file.
    ///   LOOKINSIDE_DEBUG_UI_SNAPSHOT_DIR=<dir>
    ///       After writing the dump, run the UI scenes of DebugUISnapshots
    ///       against the loaded document instead of exiting; the Host exits
    ///       when they are done.
    @MainActor
    @Signpostable(subsystem: "com.lookinside.app", category: "RefreshPerformance")
    final class DebugE2EDump: NSObject {
        private static let directoryKey = "LOOKINSIDE_DEBUG_E2E_DUMP_DIR"
        private static let bundleIDKey = "LOOKINSIDE_DEBUG_E2E_BUNDLE_ID"
        private static let timeoutKey = "LOOKINSIDE_DEBUG_E2E_TIMEOUT"
        private static let prepareLicenseCSRKey = "LOOKINSIDE_DEBUG_E2E_PREPARE_LICENSE_CSR"
        private static let expectLicensedKey = "LOOKINSIDE_DEBUG_E2E_EXPECT_LICENSED"
        private static let startFileKey = "LOOKINSIDE_DEBUG_E2E_START_FILE"
        private static let refreshCountKey = "LOOKINSIDE_DEBUG_E2E_REFRESH_COUNT"
        private static let wholeTreeKey = "LOOKINSIDE_DEBUG_E2E_WHOLE_TREE"

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
            case fetchingWholeTree
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
        private static var current: DebugE2EDump?

        private let directory: String
        private let bundleID: String?
        private let startFile: String?
        private let timeout: TimeInterval
        private let expectsLicensed: Bool
        private let refreshCount: Int
        private let fetchesWholeTree: Bool
        private var loggedStartWait = false
        private var loggedLicenseWait = false
        private var notedFirstWindow = false

        private var phase: Phase = .waitingForApp
        private var deadline = Date()
        private var timer: Timer?
        private var fetchingApps = false
        private var nextAppPoll: Date?
        private var lastAppListSummary: String?

        private var app: InspectableApp?
        private var document: LiveDocument?
        private var sawUpdating = false
        private var idleSince: Date?
        /// Phase boundaries for timings.json.
        private var hierarchyRequestInstant: ContinuousClock.Instant?
        private var hierarchyResponseInstant: ContinuousClock.Instant?
        private var reloadEndInstant: ContinuousClock.Instant?
        private var detailsIdleInstant: ContinuousClock.Instant?
        /// The reload in progress after the first load, and those done.
        private var refreshStartInstant: ContinuousClock.Instant?
        private var refreshReloadedInstant: ContinuousClock.Instant?
        private var refreshTimings: [[String: Double]] = []
        /// `detailsIdleInstant` of the first load, kept once refreshes start.
        private var firstLoadDetailsIdleInstant: ContinuousClock.Instant?
        /// The whole tree fetch of LOOKINSIDE_DEBUG_E2E_WHOLE_TREE.
        private var wholeTreeStartInstant: ContinuousClock.Instant?
        private var wholeTreeEndInstant: ContinuousClock.Instant?
        /// Open while the phase is loadingDetails.
        private var loadingDetailsSignpostInterval: SignpostInterval?
        private var settleUntil = Date()

        private init(directory: String, environment: [String: String]) {
            self.directory = directory
            bundleID = environment[Self.bundleIDKey]
            startFile = environment[Self.startFileKey].map { ($0 as NSString).standardizingPath }
            let timeout = (environment[Self.timeoutKey] as NSString?)?.doubleValue ?? 0
            self.timeout = timeout > 0 ? timeout : 240
            expectsLicensed = environment[Self.expectLicensedKey] == "1"
            refreshCount = max(Int(environment[Self.refreshCountKey] ?? "") ?? 0, 0)
            fetchesWholeTree = environment[Self.wholeTreeKey] == "1"
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
            let dump = DebugE2EDump(directory: (directory as NSString).standardizingPath, environment: environment)
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
                let pem = try SwiftUISupportGatekeeper.sharedInstance()
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
            if DebugUISnapshots.isEnabled {
                DebugUISnapshots.captureLaunchScene()
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
            if phase != .loadingDetails, let loadingDetailsSignpostInterval {
                #signpost(.end, loadingDetailsSignpostInterval)
                self.loadingDetailsSignpostInterval = nil
            } else if phase == .loadingDetails, loadingDetailsSignpostInterval == nil {
                loadingDetailsSignpostInterval = #signpost(.begin, "Driver loading details")
            }
            self.phase = phase
            deadline = Date(timeIntervalSinceNow: timeout)
        }

        @objc private func tick() {
            if phase == .done {
                return
            }
            if phase == .loadingDetails {
                #signpost(.event, "Driver tick")
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
            case .fetchingWholeTree:
                break
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
                    let state = SwiftUISupportGatekeeper.sharedInstance().activationState.rawValue
                    return "timed out waiting for the license handshake on \(bundleID ?? "the app") (activation state \(state))"
                }
                return "timed out waiting for an inspectable app; last app list: \(lastAppListSummary ?? "none received")"
            case .opening:
                return "timed out fetching the hierarchy and opening the live document"
            case .loadingDetails:
                let updating = document?.asyncUpdateManager?.isUpdating() == true
                return "timed out waiting for the display-item details (update manager \(updating ? "still updating" : "never started"))"
            case .fetchingWholeTree:
                return "timed out fetching what the whole tree misses"
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
                SwiftUISupportGatekeeper.sharedInstance().debugNoteFirstWindowShown()
                log("a Host window is visible; first-window signing gate satisfied")
            }
        }

        /// Same list the launch window shows: DebugE2EDumpWriter.fetchApps(completion:).
        private func pollApps() {
            if fetchingApps {
                return
            }
            if let nextAppPoll, nextAppPoll.timeIntervalSinceNow > 0 {
                return
            }
            fetchingApps = true
            nextAppPoll = Date(timeIntervalSinceNow: Self.appPollInterval)
            DebugE2EDumpWriter.fetchApps { [self] apps in
                fetchingApps = false
                guard phase == .waitingForApp else {
                    return
                }
                var summary: [String] = []
                var target: InspectableApp?
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
                if expectsLicensed, !DebugE2EDumpWriter.isChannelLicensed(for: target) {
                    if !loggedLicenseWait {
                        loggedLicenseWait = true
                        log("found \(target.appInfo?.appBundleIdentifier ?? "(null)"); waiting for the license handshake")
                    }
                    return
                }
                open(target)
            }
        }

        /// Mirrors LaunchViewController's app entry: fetch the hierarchy, open
        /// a live document through LiveDocumentController, prime its data
        /// source with that hierarchy, close the launch window. The SwiftUI
        /// activation prompt that follows there is licensing UI and is left out.
        private func open(_ app: InspectableApp) {
            let licensed = DebugE2EDumpWriter.isChannelLicensed(for: app) ? "YES" : "NO"
            log("opening \(app.appInfo?.appBundleIdentifier ?? "(null)") (channel licensed: \(licensed))")
            self.app = app
            enterPhase(.opening)
            hierarchyRequestInstant = .now
            DebugE2EDumpWriter.fetchHierarchy(for: app) { [self] info, error in
                hierarchyResponseInstant = .now
                if let error {
                    fail(.openFailed, "the hierarchy request failed: \(error as NSError)")
                    return
                }
                guard let info else {
                    fail(.openFailed, "the hierarchy request returned nothing")
                    return
                }
                let (document, alreadyOpen) = LiveDocumentController.shared.openLiveDocument(for: app)
                self.document = document
                if !alreadyOpen {
                    document.hierarchyDataSource?.reload(with: info, keepState: false)
                }
                // After the reload, as for a refresh, so the details phase
                // (and its signpost interval) holds no reload work.
                enterPhase(.loadingDetails)
                reloadEndInstant = .now
                NavigationManager.shared.closeLaunch()
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
                detailsIdleInstant = .now
                return
            }
            if !sawUpdating || -idleSince.timeIntervalSinceNow < Self.idleInterval {
                return
            }
            // The displayed items are in; the prefetch is waited for too.
            if manager.isPrefetching() {
                return
            }
            if let refreshStartInstant {
                recordRefresh(startedAt: refreshStartInstant)
                self.refreshStartInstant = nil
            }
            if refreshTimings.count < refreshCount {
                if firstLoadDetailsIdleInstant == nil {
                    firstLoadDetailsIdleInstant = detailsIdleInstant
                }
                startRefresh()
                return
            }
            log("details loaded")
            if fetchesWholeTree, wholeTreeStartInstant == nil {
                startWholeTreeFetch(with: manager)
                return
            }
            settleUntil = Date(timeIntervalSinceNow: Self.settleInterval)
            enterPhase(.settling)
        }

        /// What an export does before it writes the file.
        private func startWholeTreeFetch(with manager: StaticAsyncUpdateManager) {
            log("fetching what the whole tree misses")
            enterPhase(.fetchingWholeTree)
            wholeTreeStartInstant = .now
            manager.fetchWholeTree { [self] in
                wholeTreeEndInstant = .now
                let milliseconds = Self.milliseconds(from: wholeTreeStartInstant, to: wholeTreeEndInstant) ?? 0
                log("whole tree fetched in \(String(format: "%.0f", milliseconds)) ms")
                settleUntil = Date(timeIntervalSinceNow: Self.settleInterval)
                enterPhase(.settling)
            }
        }

        /// Reloads the hierarchy through the window controller, the path the
        /// toolbar button takes, then waits for the details as after the first
        /// load.
        private func startRefresh() {
            guard let windowController = document?.staticWindowController else {
                fail(.openFailed, "refresh \(refreshTimings.count + 1): the document has no inspector window")
                return
            }
            log("refresh \(refreshTimings.count + 1) of \(refreshCount)")
            enterPhase(.opening)
            sawUpdating = false
            idleSince = nil
            refreshReloadedInstant = nil
            refreshStartInstant = .now
            Task { @MainActor [self] in
                do {
                    _ = try await windowController.reloadHierarchy(initiator: .host)
                } catch {
                    fail(.openFailed, "refresh \(refreshTimings.count + 1) failed: \(error as NSError)")
                    return
                }
                refreshReloadedInstant = .now
                enterPhase(.loadingDetails)
            }
        }

        private func recordRefresh(startedAt startInstant: ContinuousClock.Instant) {
            var timing: [String: Double] = [:]
            timing["reloadMilliseconds"] = Self.milliseconds(from: startInstant, to: refreshReloadedInstant)
            timing["detailsMilliseconds"] = Self.milliseconds(from: refreshReloadedInstant, to: detailsIdleInstant)
            timing["totalMilliseconds"] = Self.milliseconds(from: startInstant, to: detailsIdleInstant)
            refreshTimings.append(timing)
            log("refresh \(refreshTimings.count) done in \(String(format: "%.0f", timing["totalMilliseconds"] ?? 0)) ms")
        }

        private static func milliseconds(from start: ContinuousClock.Instant?, to end: ContinuousClock.Instant?) -> Double? {
            guard let start, let end else { return nil }
            let components = (end - start).components
            return Double(components.seconds) * 1000 + Double(components.attoseconds) / 1_000_000_000_000_000
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
            let platform = AppHelper.appInfoLooksLikeMacTarget(app?.appInfo) ? "macos" : "ios"
            do {
                try DebugE2EDumpWriter.writeSnapshot(for: dataSource, app: document.inspectableApp, platform: platform, to: directoryURL)
            } catch {
                fail(.writeFailed, "writing snapshot.json failed: \(error as NSError)")
                return
            }
            do {
                try writeTimings(itemCount: dataSource.flatItems?.count ?? 0, to: directoryURL.appendingPathComponent("timings.json"))
            } catch {
                fail(.writeFailed, "writing timings.json failed: \(error as NSError)")
                return
            }
            let window = document.windowControllers.first?.window
            let pngURL = directoryURL.appendingPathComponent("host-window.png")
            guard let png = DebugWindowImage.pngData(of: window), !png.isEmpty, (try? png.write(to: pngURL, options: .atomic)) != nil else {
                fail(.writeFailed, "capturing the Host window failed")
                return
            }
            log("wrote \(directory)")
            if DebugUISnapshots.isEnabled {
                timer?.invalidate()
                DebugUISnapshots.runScenes(for: document) { status in
                    exit(status)
                }
                return
            }
            exit(ExitStatus.success.rawValue)
        }

        private func writeTimings(itemCount: Int, to url: URL) throws {
            var timings: [String: Any] = ["itemCount": itemCount]
            timings["hierarchyRequestMilliseconds"] = Self.milliseconds(from: hierarchyRequestInstant, to: hierarchyResponseInstant)
            timings["reloadMilliseconds"] = Self.milliseconds(from: hierarchyResponseInstant, to: reloadEndInstant)
            timings["detailsMilliseconds"] = Self.milliseconds(from: reloadEndInstant, to: firstLoadDetailsIdleInstant ?? detailsIdleInstant)
            timings["totalMilliseconds"] = Self.milliseconds(from: hierarchyRequestInstant, to: firstLoadDetailsIdleInstant ?? detailsIdleInstant)
            if !refreshTimings.isEmpty {
                timings["refreshes"] = refreshTimings
            }
            timings["wholeTreeMilliseconds"] = Self.milliseconds(from: wholeTreeStartInstant, to: wholeTreeEndInstant)
            let data = try JSONSerialization.data(withJSONObject: timings, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: url, options: .atomic)
            log("timings: \(String(data: data, encoding: .utf8) ?? "")")
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
