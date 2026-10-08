#if DEBUG
    import AppKit
    import Foundation

    /// DEBUG-only UI self-screenshots. When LOOKINSIDE_DEBUG_UI_SNAPSHOT_DIR
    /// is set (together with the end-to-end dump's LOOKINSIDE_DEBUG_E2E_*),
    /// the Host drives its own UI through a fixed list of scenes and writes
    /// one PNG per scene, drawn in process (DebugWindowImage: no
    /// Accessibility or Screen Recording permission), plus:
    ///
    ///   scenes.json         every scene: file, status (captured / skipped),
    ///                       skip reason, the session state at its capture
    ///   session-state.json  the run's session state (the first scene with
    ///                       the inspected app loaded), for
    ///                       LookinProbe/session-state.sh check
    ///   .launch-captured    marker: the no-app scene is done and the driver
    ///                       may launch the inspected app
    ///
    /// Flow (driver: Scripts/reborn-e2e/ui-snapshots.sh):
    ///  1. At launch, before any app is inspectable, the launch window is
    ///     captured ("launch-no-app"); then the marker is written. The dump
    ///     waits for LOOKINSIDE_DEBUG_E2E_START_FILE before it looks for the
    ///     app, so the driver launches the Example in between.
    ///  2. DebugE2EDump opens the app, waits for every detail and writes its
    ///     snapshot, then hands the live document to `runScenes`.
    ///  3. The scenes run one after another in this launch, and the Host
    ///     exits with 0 (all scenes captured or skipped), or non-zero.
    ///
    /// Determinism: windows get fixed sizes (split views laid out again with
    /// their own first-layout rule), nodes are chosen by their canonical
    /// snapshot id, indeterminate spinners are stopped before a capture, and
    /// every Host window ignores mouse events, so someone using the Mac
    /// cannot hover or scroll what is captured. The Host never activates
    /// itself; the activation window is shown without `present()`, which
    /// would. Appearance, scroll bars, language and locale come from the
    /// driver's launch arguments.
    ///
    /// Session state: each scene records the state it was captured in
    /// (screen lock, console, display sleep, the inspected Example's
    /// appearance and active / key state, the Host's appearance, whether the
    /// Host was active and the window key, the window's backing scale). The
    /// comparison (`lookin-probe ui-diff`) skips a scene whose state differs
    /// from the baseline's, and never loosens a threshold for it.
    @objc(LKDebugUISnapshots)
    @MainActor
    final class DebugUISnapshots: NSObject {
        static let directoryVariable = "LOOKINSIDE_DEBUG_UI_SNAPSHOT_DIR"
        static let launchMarkerName = ".launch-captured"

        /// Content size of the inspector and reader windows, in points.
        static let documentContentSize = NSSize(width: 1280, height: 800)
        /// Canonical snapshot ids (SnapshotNormalizer, as in
        /// host-dump-golden/macos) of the nodes the scenes select in
        /// LookInsideExampleAppKit's main window.
        static let contentStackID = "/NSWindow[0]/NSThemeFrame[0]/NSView[0]/NSSplitView[0]"
            + "/_NSSplitViewItemViewWrapper[0]/NSView[0]/NSView[0]/NSScrollView[0]/NSClipView[0]"
            + "/LookInsideExampleAppKit.FlippedView[0]/NSStackView[0]"
        /// `trackTitleLabel`, an NSTextField.
        static let labelID = contentStackID + "/NSStackView[0]/NSStackView[0]/NSTextField[0]"
        /// The artwork's `symbolImageView`, an NSImageView.
        static let imageViewID = contentStackID + "/NSStackView[0]/LookInsideExampleAppKit.AlbumArtworkView[0]/NSStackView[0]/NSImageView[0]"
        /// `contentStackView`, an NSStackView.
        static let stackViewID = contentStackID
        static let filterText = "TextField"

        private static var shared: DebugUISnapshots?

        private let directory: URL
        private var entries: [[String: Any]] = []
        private var runState: [String: Any]?

        private init(directory: URL) {
            self.directory = directory
        }

        @objc static var isEnabled: Bool {
            !(ProcessInfo.processInfo.environment[directoryVariable] ?? "").isEmpty
        }

        private static func instance() -> DebugUISnapshots? {
            if let shared {
                return shared
            }
            guard let path = ProcessInfo.processInfo.environment[directoryVariable], !path.isEmpty else {
                return nil
            }
            let snapshots = DebugUISnapshots(directory: URL(fileURLWithPath: (path as NSString).standardizingPath, isDirectory: true))
            shared = snapshots
            return snapshots
        }

        // MARK: - Entry points

        /// Step 1: captures the launch window before any app is inspectable,
        /// then writes the marker. Called once the app finished launching.
        @objc static func captureLaunchScene() {
            guard let snapshots = instance() else { return }
            Task { @MainActor in
                do {
                    try FileManager.default.createDirectory(at: snapshots.directory, withIntermediateDirectories: true)
                    try await snapshots.launchScene()
                    try snapshots.writeIndex()
                    try Data().write(to: snapshots.directory.appendingPathComponent(launchMarkerName))
                } catch {
                    log("FAIL: launch scene: \(error)")
                    exit(7)
                }
            }
        }

        /// Steps 2 and 3: runs every scene against the loaded live document,
        /// then calls `completion` with the exit status.
        @objc(runScenesForDocument:completion:)
        static func runScenes(for document: LiveDocument, completion: @escaping (Int32) -> Void) {
            guard let snapshots = instance() else {
                completion(0)
                return
            }
            Task { @MainActor in
                do {
                    try await snapshots.documentScenes(document)
                    try snapshots.writeIndex()
                    log("wrote \(snapshots.entries.count) scenes to \(snapshots.directory.path)")
                    completion(0)
                } catch {
                    try? snapshots.writeIndex()
                    log("FAIL: \(error)")
                    completion(7)
                }
            }
        }

        // MARK: - Scenes

        private func launchScene() async throws {
            let window = try await waitFor("the launch window") {
                NavigationManager.shared.launchWindowController?.window.flatMap { $0.isVisible ? $0 : nil }
            }
            quietWindows()
            // Two app-list rounds of the launch window (every 1.5 s), so its
            // "searching" state and progress bar have settled.
            await pause(3.5)
            let apps = await AppsManager.shared.fetchAppInfos(needImages: false, localInfos: nil)
            if !apps.isEmpty {
                let names = apps.map { $0.appInfo?.appBundleIdentifier ?? "?" }.joined(separator: ", ")
                skip("launch-no-app", reason: "\(apps.count) inspectable app(s) already running: \(names)")
                return
            }
            try await capture("launch-no-app", window: window, includesInspectedApp: false)
        }

        private func documentScenes(_ document: LiveDocument) async throws {
            guard let windowController = document.windowControllers.first as? StaticWindowController,
                  let window = windowController.window,
                  let viewController = windowController.viewController,
                  let dataSource = document.hierarchyDataSource
            else { throw SnapshotError("the live document has no inspector window") }
            let preferences = PreferenceManager.shared
            quietWindows()
            pinSize(of: window, to: Self.documentContentSize)
            logLayout(of: window)

            let nodes = SnapshotNormalizer.collectNodes(roots: dataSource.rawHierarchyInfo?.displayItems ?? [])
            let label = try node(Self.labelID, in: nodes)
            let imageView = try node(Self.imageViewID, in: nodes)
            let stackView = try node(Self.stackViewID, in: nodes)

            // Main window: hierarchy, preview and dashboard with the default
            // attribute groups (Class collapsed).
            select(label, in: dataSource)
            try await capture("main-selected-label", window: window, document: document)

            // Dashboard with every attribute group expanded, for a label, an
            // image view and a stack view: the window, and the dashboard's
            // whole scrollable content.
            preferences.collapsedAttrGroups = []
            for (name, item) in [("label", label), ("imageview", imageView), ("stackview", stackView)] {
                select(item, in: dataSource)
                try await capture("dashboard-\(name)", window: window, document: document)
                try await captureView("dashboard-\(name)-content", window: window,
                                      view: dashboardContentView(of: viewController))
            }

            // Measure: label selected, image view hovered, measuring locked.
            select(label, in: dataSource)
            preferences.measureState.setIntegerValue(MeasureState.locked.rawValue, ignoreSubscriber: nil)
            dataSource.hoveredItem = imageView
            try await capture("measure", window: window, document: document)
            dataSource.hoveredItem = nil
            preferences.measureState.setIntegerValue(MeasureState.no.rawValue, ignoreSubscriber: nil)

            // Console panel under the preview, label selected.
            viewController.showConsole = true
            try await capture("console", window: window, document: document)
            viewController.showConsole = false

            // Hierarchy filter active.
            try await filterHierarchy(viewController, text: Self.filterText)
            try await capture("hierarchy-filter", window: window, document: document)
            try await filterHierarchy(viewController, text: nil)

            // Export: the save panel runs out of process, so its accessory
            // view is captured on its own; the exported data is then opened
            // as a .lookin file (Export -> Read round trip).
            guard let hierarchyInfo = dataSource.rawHierarchyInfo else {
                throw SnapshotError("the data source has no hierarchy")
            }
            // Full image quality: below 1 the export scales every screenshot
            // down by drawing it, and that resampling is not pixel-stable
            // from run to run (measured: two variants of the reader's
            // preview at 50%). At 1 the images keep their size.
            var fileName: NSString?
            guard let exported = ExportManager.sharedInstance().data(
                from: hierarchyInfo, imageCompression: 1, fileName: &fileName
            )
            else { throw SnapshotError("exporting the hierarchy returned no data") }
            try await captureExportAccessory()
            try await readRoundTrip(exported)

            // Windows of their own.
            NavigationManager.shared.showPreference()
            try await captureStandaloneWindow("preferences", controllerKey: "preferenceWindowController")
            NavigationManager.shared.showAbout()
            try await captureStandaloneWindow("about", controllerKey: "aboutWindowController")
            try await captureActivationWindow()
        }

        private func readRoundTrip(_ data: Data) async throws {
            let work = directory.appendingPathComponent("work", isDirectory: true)
            try FileManager.default.createDirectory(at: work, withIntermediateDirectories: true)
            let url = work.appendingPathComponent("roundtrip.lookin")
            try data.write(to: url, options: .atomic)
            let document: NSDocument = try await withCheckedThrowingContinuation { continuation in
                NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { document, _, error in
                    if let document {
                        continuation.resume(returning: document)
                    } else {
                        continuation.resume(throwing: error ?? SnapshotError("opening \(url.path) failed"))
                    }
                }
            }
            let readViewController = try await waitFor("the reader to load the file") {
                (document.windowControllers.first?.contentViewController as? ReadViewController)
            }
            guard let window = document.windowControllers.first?.window,
                  let dataSource = readViewController.hierarchyDataSource
            else { throw SnapshotError("the reader has no window") }
            quietWindows()
            pinSize(of: window, to: Self.documentContentSize)
            let nodes = SnapshotNormalizer.collectNodes(roots: dataSource.rawHierarchyInfo?.displayItems ?? [])
            try select(node(Self.labelID, in: nodes), in: dataSource)
            try await capture("read-roundtrip", window: window)
            document.close()
        }

        /// The export size the accessory shows for the snapshot. The real
        /// size changes from run to run (the screenshots are JPEG-encoded,
        /// and the encoder's output is not byte-stable), so a fixed size
        /// stands in; the exported data itself is covered by the reader
        /// round trip.
        static let exportAccessoryDataSize: UInt = 46_200_000

        private func captureExportAccessory() async throws {
            let accessory = ExportAccessoryView()
            accessory.dataSize = Self.exportAccessoryDataSize
            accessory.setFrameSize(accessory.sizeThatFits(NSSize(width: CGFloat.greatestFiniteMagnitude,
                                                                 height: CGFloat.greatestFiniteMagnitude)))
            // Never shown: the view only needs a window for its appearance
            // and backing scale.
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: accessory.frame.size),
                                  styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = accessory
            await pause(0.5)
            try await captureView("export-accessory", window: window, view: accessory)
            window.close()
        }

        private func captureStandaloneWindow(_ name: String, controllerKey: String) async throws {
            let navigation = NavigationManager.shared
            let window = try await waitFor("the \(name) window") {
                (navigation.value(forKey: controllerKey) as? NSWindowController)?.window.flatMap { $0.isVisible ? $0 : nil }
            }
            quietWindows()
            window.center()
            try await capture(name, window: window)
            window.close()
        }

        private func captureActivationWindow() async throws {
            let window = await SwiftUISupportGatekeeper.sharedInstance().debugPreparedActivationWindow()
            window.center()
            window.orderFront(nil)
            quietWindows()
            try await capture("activation", window: window)
            window.close()
        }

        // MARK: - Driving the UI

        private func node(_ id: String, in nodes: [SnapshotNormalizer.Node]) throws -> DisplayItem {
            guard let node = nodes.first(where: { $0.id == id }) else {
                throw SnapshotError("no node \(id)")
            }
            return node.item
        }

        private func select(_ item: DisplayItem, in dataSource: HierarchyDataSource) {
            // A fresh selection, so the dashboard renders its cards again
            // with the current collapsed-group preference.
            dataSource.selectedItem = nil
            dataSource.selectAndRevealItem(item)
        }

        /// Types into the hierarchy's filter field as the user would; nil
        /// ends the filter through its close button path.
        private func filterHierarchy(_ viewController: StaticViewController, text: String?) async throws {
            guard let hierarchyView = viewController.currentHierarchyView(),
                  let field = hierarchyView.value(forKey: "searchTextFieldView") as? TextFieldView
            else { throw SnapshotError("the hierarchy view has no filter field") }
            field.textField.stringValue = text ?? ""
            hierarchyView.delegate?.hierarchyView(hierarchyView, didInputSearch: text)
        }

        private func dashboardContentView(of viewController: StaticViewController) throws -> NSView {
            guard let dashboard = viewController.value(forKey: "dashboardController") as? NSViewController,
                  let scrollView = dashboard.value(forKey: "scrollView") as? NSScrollView,
                  let content = scrollView.documentView
            else { throw SnapshotError("the dashboard has no scroll view") }
            return content
        }

        /// Sets the window's content size and lays its split views out again
        /// with their own first-layout rule, which otherwise ran for the
        /// size the window was created with (a share of the screen).
        private func pinSize(of window: NSWindow, to size: NSSize) {
            window.setContentSize(size)
            window.contentView?.layoutSubtreeIfNeeded()
            var splitViews: [SplitView] = []
            func collect(_ view: NSView) {
                if let split = view as? SplitView {
                    splitViews.append(split)
                }
                view.subviews.forEach(collect)
            }
            if let content = window.contentView {
                collect(content)
            }
            for split in splitViews {
                split.didFinishFirstLayout?(split)
            }
        }

        /// Logs where the split views, scroll views and SceneKit views sit,
        /// so a capture that looks wrong can be told from a layout change.
        private func logLayout(of window: NSWindow) {
            func walk(_ view: NSView, depth: Int) {
                if view is NSSplitView || view is NSScrollView || String(describing: type(of: view)).contains("SCNView") {
                    Self.log("layout \(String(repeating: "  ", count: depth))\(type(of: view)) \(NSStringFromRect(view.convert(view.bounds, to: nil)))")
                }
                for subview in view.subviews where !subview.isHidden {
                    walk(subview, depth: depth + 1)
                }
            }
            if let frameView = window.contentView?.superview {
                walk(frameView, depth: 0)
            }
        }

        /// Every Host window ignores the mouse, so a cursor over it cannot
        /// hover, scroll or click what is being captured.
        private func quietWindows() {
            for window in NSApp.windows {
                window.ignoresMouseEvents = true
            }
        }

        // MARK: - Capture

        private func capture(_ name: String, window: NSWindow, document: LiveDocument? = nil,
                             includesInspectedApp: Bool = true) async throws
        {
            try await settle(window, document: document)
            let restore = maskAddresses(in: window.contentView?.superview)
            defer { restore() }
            guard let png = DebugWindowImage.pngData(of: window) else {
                throw SnapshotError("capturing \(name) failed")
            }
            try write(png, scene: name, window: window, includesInspectedApp: includesInspectedApp)
        }

        private func captureView(_ name: String, window: NSWindow, view: NSView) async throws {
            try await settle(window, document: nil)
            let restore = maskAddresses(in: view)
            defer { restore() }
            guard let png = DebugWindowImage.pngData(of: view) else {
                throw SnapshotError("capturing \(name) failed")
            }
            try write(png, scene: name, window: window, includesInspectedApp: true)
        }

        private func settle(_ window: NSWindow, document: LiveDocument?) async throws {
            if let manager = document?.asyncUpdateManager {
                _ = try await waitFor("detail updates to finish") { manager.isUpdating() ? nil : true }
            }
            await pause(1.5)
            let frameView = window.contentView?.superview ?? window.contentView
            stopSpinners(in: frameView)
            // One full layout pass of every view, toolbar included: the
            // reader's app item otherwise keeps whichever layout it got
            // before its labels and icon were sized.
            invalidateLayout(in: frameView)
            frameView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
        }

        /// Object addresses of the inspected app ("<NSImage 0x6000…>" in the
        /// dashboard, the console's target) change with every launch. Each
        /// hex digit of an address shown in a text field or text view is drawn as 0 for
        /// the capture (same length, so the layout stays), the way the
        /// snapshot normalizer drops oids. Returns the undo.
        private func maskAddresses(in root: NSView?) -> () -> Void {
            guard let root,
                  let pattern = try? NSRegularExpression(pattern: "0x[0-9a-fA-F]{6,}")
            else { return {} }
            var undo: [() -> Void] = []
            // Replaces the hex digits of every address in `string` with 0,
            // keeping its attributes; false when it holds none.
            func mask(_ string: NSMutableAttributedString) -> Bool {
                let matches = pattern.matches(in: string.string, range: NSRange(location: 0, length: string.length))
                for match in matches {
                    let digits = NSRange(location: match.range.location + 2, length: match.range.length - 2)
                    string.replaceCharacters(in: digits, with: String(repeating: "0", count: digits.length))
                }
                return !matches.isEmpty
            }
            func walk(_ view: NSView) {
                if let field = view as? NSTextField {
                    let original = field.attributedStringValue
                    let masked = NSMutableAttributedString(attributedString: original)
                    if mask(masked) {
                        field.attributedStringValue = masked
                        undo.append { field.attributedStringValue = original }
                    }
                } else if let textView = view as? NSTextView, let storage = textView.textStorage {
                    let original = NSAttributedString(attributedString: storage)
                    let masked = NSMutableAttributedString(attributedString: original)
                    if mask(masked) {
                        storage.setAttributedString(masked)
                        undo.append { storage.setAttributedString(original) }
                    }
                }
                view.subviews.forEach(walk)
            }
            walk(root)
            if !undo.isEmpty {
                root.layoutSubtreeIfNeeded()
                root.displayIfNeeded()
            }
            return {
                undo.forEach { $0() }
            }
        }

        private func invalidateLayout(in view: NSView?) {
            guard let view else { return }
            view.needsLayout = true
            view.subviews.forEach(invalidateLayout)
        }

        /// An indeterminate spinner draws a different frame each time; a
        /// stopped one draws a fixed one.
        private func stopSpinners(in view: NSView?) {
            guard let view else { return }
            if let indicator = view as? NSProgressIndicator, indicator.isIndeterminate {
                indicator.stopAnimation(nil)
            }
            view.subviews.forEach(stopSpinners)
        }

        private func write(_ png: Data, scene name: String, window: NSWindow, includesInspectedApp: Bool) throws {
            let file = "\(name).png"
            try png.write(to: directory.appendingPathComponent(file), options: .atomic)
            let state = sessionState(window: window, includesInspectedApp: includesInspectedApp)
            if includesInspectedApp, runState == nil {
                runState = state
                try SnapshotNormalizer.writeSessionState(state, to: directory)
            }
            entries.append(["name": name, "file": file, "status": "captured", "state": state])
            Self.log("captured \(name)")
        }

        private func skip(_ name: String, reason: String) {
            entries.append(["name": name, "status": "skipped", "reason": reason])
            Self.log("SKIP \(name): \(reason)")
        }

        /// The session state now (SnapshotNormalizer.sessionStateJSON)
        /// plus what only the Host knows: whether it is active, whether the
        /// captured window is key, and the window's backing scale.
        private func sessionState(window: NSWindow, includesInspectedApp: Bool) -> [String: Any] {
            var state = includesInspectedApp
                ? SnapshotNormalizer.sessionStateJSON(hostAppearance: NSApp.effectiveAppearance.name.rawValue)
                : SnapshotNormalizer.systemSessionStateJSON()
            state["hostAppearance"] = NSApp.effectiveAppearance.name.rawValue
            state["hostAppActive"] = NSApp.isActive
            state["hostWindowKey"] = window.isKeyWindow
            state["hostBackingScale"] = Double(window.backingScaleFactor)
            return state
        }

        private func writeIndex() throws {
            let index: [String: Any] = ["format": 1, "scenes": entries]
            let data = try JSONSerialization.data(withJSONObject: index, options: [.prettyPrinted, .sortedKeys])
            try (data + Data("\n".utf8)).write(to: directory.appendingPathComponent("scenes.json"), options: .atomic)
        }

        // MARK: - Waiting

        private func pause(_ seconds: Double) async {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }

        private func waitFor<T>(_ what: String, timeout: Double = 60, _ probe: () -> T?) async throws -> T {
            let deadline = Date().addingTimeInterval(timeout)
            while true {
                if let value = probe() {
                    return value
                }
                if Date() > deadline {
                    throw SnapshotError("timed out waiting for \(what)")
                }
                await pause(0.25)
            }
        }

        private static func log(_ message: String) {
            FileHandle.standardError.write(Data("[host-ui-snapshots] \(message)\n".utf8))
        }
    }
#endif
