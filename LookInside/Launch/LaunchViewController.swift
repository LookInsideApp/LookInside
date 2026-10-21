//
//  LaunchViewController.swift
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

import AppKit

/// The launch window's content: a sidebar of the devices running
/// inspectable apps and of the recent documents, and a grid of the selected
/// device's apps. The apps are rescanned every 1.5 seconds while the window
/// is open. Picking an app fetches its hierarchy and opens a live document
/// for it.
final class LaunchViewController: NSSplitViewController {
    /// A USB device that is plugged in takes about 0.1 seconds to reach the
    /// connection manager; the first scan waits a little longer than that.
    private static let initialScanDelay: TimeInterval = 0.2
    private static let rescanInterval: TimeInterval = 1.5

    private var autoEnterOnInitialReload: Bool

    private let sidebarViewController = LaunchSidebarViewController()
    private let appGridViewController = LaunchAppGridViewController()

    private var deviceSelection = LaunchDeviceSelection()
    private var deviceGroups: [LaunchDeviceGroup<InspectableApp>] = []
    /// The info each app sent while it answered, so an app that went to the
    /// background or stopped answering keeps its name and screenshot.
    /// Dropped once the app's channel is gone.
    private var lastKnownAppInfoByOrigin: [InspectableAppOrigin: InspectedAppInfo] = [:]
    private var hasFinishedFirstScan = false

    private var pendingScan: DispatchWorkItem?
    private var isScanInFlight = false
    private var isScanningStopped = false
    private var isEnteringApp = false
    /// The infos of the last scan, so an unchanged app does not send its
    /// images again.
    private var appInfos: [InspectedAppInfo]?

    init(autoEnterOnInitialReload: Bool) {
        self.autoEnterOnInitialReload = autoEnterOnInitialReload
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.autosaveName = "LaunchWindowSplitView"

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 180
        sidebarItem.maximumThickness = 320
        sidebarItem.canCollapse = false
        addSplitViewItem(sidebarItem)

        let contentItem = NSSplitViewItem(viewController: appGridViewController)
        contentItem.minimumThickness = 360
        addSplitViewItem(contentItem)

        sidebarViewController.onSelectDevice = { [weak self] device in
            self?.userDidSelect(device)
        }
        sidebarViewController.onOpenRecentDocument = { [weak self] documentURL in
            self?.openRecentDocument(documentURL)
        }
        appGridViewController.onClickApp = { [weak self] app in
            self?.handleClick(on: app)
        }
        appGridViewController.progressIndicatorView.animate(toProgress: 0.7, duration: 0.5)
        render()
    }

    // MARK: - Scanning

    /// Starts the scans; the first one may open the only app it finds.
    func startScanning() {
        isScanningStopped = false
        let autoEnter = autoEnterOnInitialReload
        autoEnterOnInitialReload = false
        scheduleScan(after: Self.initialScanDelay, autoEntering: autoEnter)
    }

    /// Stops the scans for good: the window closed.
    func stopScanning() {
        isScanningStopped = true
        pendingScan?.cancel()
        pendingScan = nil
    }

    /// Schedules the next scan, replacing one already scheduled, so there
    /// is only ever one chain of scans.
    private func scheduleScan(after delay: TimeInterval, autoEntering autoEnter: Bool = false) {
        pendingScan?.cancel()
        guard !isScanningStopped else { return }
        let scan = DispatchWorkItem { [weak self] in
            self?.scan(autoEntering: autoEnter)
        }
        pendingScan = scan
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: scan)
    }

    private func scan(autoEntering autoEnter: Bool) {
        pendingScan = nil
        guard !isScanningStopped, !isScanInFlight else {
            // A scan in flight schedules the next one when it ends.
            return
        }
        if isEnteringApp {
            // The hierarchy request has the app's attention; skip this round,
            // but keep the scans going in case entering fails.
            scheduleScan(after: Self.rescanInterval)
            return
        }
        isScanInFlight = true
        Task { [weak self, appInfos] in
            let apps = await AppsManager.shared.fetchAppInfos(needImages: true, localInfos: appInfos, includingUnresponsiveApps: true)
            guard let self else { return }
            isScanInFlight = false
            didScan(apps, autoEnter: autoEnter)
        }
    }

    private func didScan(_ apps: [InspectableApp], autoEnter: Bool) {
        guard !isScanningStopped else { return }
        let answeringApps = apps.filter { !$0.isUnresponsive }
        appInfos = answeringApps.compactMap(\.appInfo)
        updateDeviceGroups(with: apps)
        render()

        // Unresponsive apps are only shown: the rule counts the apps
        // the scan could have opened, as before they were listed.
        let canAutoEnter = LaunchRules.canAutoEnter(
            requested: autoEnter,
            appCount: answeringApps.count,
            onlyAppHasServerVersionError: answeringApps.first?.serverVersionError != nil,
            isActivated: SwiftUISupportGatekeeper.sharedInstance().activationState == .activated
        )
        if !hasFinishedFirstScan {
            hasFinishedFirstScan = true
            // The bar the window opened with goes on into the hierarchy
            // fetch when the scan opens the app itself.
            if !canAutoEnter {
                appGridViewController.progressIndicatorView.finish(completion: nil)
            }
        }
        if canAutoEnter, let app = answeringApps.first {
            // The scan that runs as the window opens found exactly one app:
            // fetch its hierarchy right away.
            enter(app)
        }
        scheduleScan(after: Self.rescanInterval)
    }

    private func updateDeviceGroups(with apps: [InspectableApp]) {
        var currentOrigins = Set<InspectableAppOrigin>()
        for app in apps {
            guard let origin = app.origin else { continue }
            currentOrigins.insert(origin)
            if let appInfo = app.appInfo {
                lastKnownAppInfoByOrigin[origin] = appInfo
            }
        }
        lastKnownAppInfoByOrigin = lastKnownAppInfoByOrigin.filter { currentOrigins.contains($0.key) }

        let entries = apps.map { app in
            let appInfo = displayedAppInfo(of: app)
            return LaunchDeviceListEntry(
                app: app,
                reportedDevice: appInfo.map(Self.deviceIdentity(of:)),
                originGroupKey: app.origin.map(Self.originGroupKey(of:)) ?? "",
                originIdentifiesDevice: app.origin.map(Self.originIdentifiesDevice(_:)) ?? false,
                isConnectable: !app.isUnresponsive && app.serverVersionError == nil
            )
        }
        deviceGroups = LaunchDeviceGrouping.groups(of: entries)
        deviceSelection.update(with: deviceGroups)
    }

    /// The app's info, or for an unresponsive app the one it sent before.
    private func displayedAppInfo(of app: InspectableApp) -> InspectedAppInfo? {
        if let appInfo = app.appInfo {
            return appInfo
        }
        guard app.isUnresponsive, let origin = app.origin else { return nil }
        return lastKnownAppInfoByOrigin[origin]
    }

    private func userDidSelect(_ device: LaunchDeviceIdentity) {
        deviceSelection.userDidSelect(device)
        render()
    }

    // MARK: - Rendering

    private func render() {
        let devices = deviceGroups.map(sidebarDevice(for:))
        let recentDocumentURLs = NSDocumentController.shared.recentDocumentURLs
        sidebarViewController.show(devices: devices, recentDocumentURLs: recentDocumentURLs, selectedDevice: deviceSelection.selectedDevice)

        let selectedGroup = deviceGroups.first { $0.identity == deviceSelection.selectedDevice }
        let cards = (selectedGroup?.apps ?? []).compactMap { app -> LaunchAppCard? in
            guard let origin = app.origin else { return nil }
            return LaunchAppCard(origin: origin, app: app, displayedAppInfo: displayedAppInfo(of: app))
        }
        appGridViewController.show(cards, of: deviceSelection.selectedDevice, isSearching: deviceGroups.isEmpty)
    }

    private func sidebarDevice(for group: LaunchDeviceGroup<InspectableApp>) -> LaunchSidebarDevice {
        let iconAppInfo = group.apps.lazy.compactMap { self.displayedAppInfo(of: $0) }.first
        switch group.identity {
        case let .reported(deviceDescription, osDescription, _, _):
            return LaunchSidebarDevice(
                identity: group.identity,
                name: deviceDescription.isEmpty ? NSLocalizedString("Unknown", comment: "") : deviceDescription,
                systemDescription: osDescription,
                appCount: group.apps.count,
                iconAppInfo: iconAppInfo,
                fallbackIconName: "icon_iphone_big"
            )
        case let .unidentified(originGroupKey):
            let (name, fallbackIconName) = Self.unidentifiedDeviceNameAndIcon(originGroupKey: originGroupKey)
            return LaunchSidebarDevice(
                identity: group.identity,
                name: name,
                systemDescription: "",
                appCount: group.apps.count,
                iconAppInfo: nil,
                fallbackIconName: fallbackIconName
            )
        }
    }

    private static func deviceIdentity(of appInfo: InspectedAppInfo) -> LaunchDeviceIdentity {
        .reported(
            deviceDescription: appInfo.deviceDescription ?? "",
            osDescription: appInfo.osDescription ?? "",
            deviceType: appInfo.deviceType
        )
    }

    private static let simulatorOriginGroupKey = "simulator"
    private static let macOriginGroupKey = "mac"
    private static let usbOriginGroupKeyPrefix = "usb:"

    /// Every app on the Simulator ports shares a key, every app on the Mac
    /// ports another, and every app on one USB device a key of its own.
    private static func originGroupKey(of origin: InspectableAppOrigin) -> String {
        switch origin.kind {
        case .simulator:
            simulatorOriginGroupKey
        case .mac:
            macOriginGroupKey
        case let .usb(deviceID):
            usbOriginGroupKeyPrefix + String(deviceID)
        }
    }

    /// Every app on one USB device runs on that device; the Simulator ports
    /// are shared by every running Simulator.
    private static func originIdentifiesDevice(_ origin: InspectableAppOrigin) -> Bool {
        if case .usb = origin.kind {
            return true
        }
        return false
    }

    private static func unidentifiedDeviceNameAndIcon(originGroupKey: String) -> (name: String, iconName: String) {
        switch originGroupKey {
        case simulatorOriginGroupKey:
            (NSLocalizedString("Simulator", comment: "Launch window sidebar: apps on the Simulator ports whose device is not known"), "icon_simulator_big")
        case macOriginGroupKey:
            (NSLocalizedString("This Mac", comment: "Launch window sidebar: apps on this Mac whose device is not known"), "icon_mac_big")
        default:
            (NSLocalizedString("USB Device", comment: "Launch window sidebar: apps on a USB device whose name is not known"), "icon_iphone_big")
        }
    }

    // MARK: - Toolbar and sidebar actions

    func attachToRunningApp() {
        AppMenuManager.attachToRunningApp(presentingIn: view.window)
    }

    func attachToAppOnDevice() {
        AppMenuManager.attachToAppOnDevice(presentingIn: view.window)
    }

    func openFile() {
        NSDocumentController.shared.openDocument(nil)
    }

    /// Opens a recent document; the launch window closes once it opened, as
    /// it does when an app is picked.
    private func openRecentDocument(_ documentURL: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: documentURL, display: true) { document, _, error in
            if let error {
                NSApp.presentError(error)
                return
            }
            if document != nil {
                NavigationManager.shared.closeLaunch()
            }
        }
    }

    // MARK: - Entering an app

    private func handleClick(on app: InspectableApp) {
        if isEnteringApp || app.isUnresponsive {
            return
        }
        if let error = app.serverVersionError {
            ServerVersionAlert.present(for: app, error: error, in: view.window)
        } else {
            appGridViewController.progressIndicatorView.animate(toProgress: 0.8, duration: 1)
            enter(app)
        }
    }

    private func enter(_ app: InspectableApp) {
        if isEnteringApp {
            return
        }
        isEnteringApp = true
        PerformanceReporter.sharedInstance().willStartReload()

        Task { [weak self] in
            let info: HierarchyInfo
            do {
                info = try await app.hierarchy()
            } catch {
                self?.enterFailed(error)
                return
            }
            self?.didFetchHierarchy(info, of: app)
            PerformanceReporter.sharedInstance().didFetchHierarchy()
        }
    }

    /// A successful pick opens a live document, which owns its own data
    /// source and update manager. The hierarchy just fetched primes the new
    /// document so its window opens populated.
    private func didFetchHierarchy(_ info: HierarchyInfo, of app: InspectableApp) {
        appGridViewController.progressIndicatorView.finish { [weak self] in
            self?.openLiveDocument(for: app, priming: info)
        }
    }

    /// An app already open in a document brings that window forward and
    /// gives it the hierarchy just fetched, keeping its expansion and
    /// selection, as the window's app picker does: the user asked to
    /// inspect the app now, so the tree it shows should be this one.
    private func openLiveDocument(for app: InspectableApp, priming info: HierarchyInfo) {
        let (document, alreadyOpen) = LiveDocumentController.shared.openLiveDocument(for: app)
        document.staticWindowController?.applyHierarchyInfo(info, for: app, keepState: alreadyOpen)
        NavigationManager.shared.closeLaunch()
        let liveWindow = document.windowControllers.first?.window
        SwiftUISupportGatekeeper.sharedInstance().promptForPendingDetectedSwiftUISupportIfNeeded(window: liveWindow)
        isEnteringApp = false
    }

    private func enterFailed(_ error: Error) {
        isEnteringApp = false
        appGridViewController.progressIndicatorView.resetToZero()
        let alert = NSAlert(error: error)
        guard let window = view.window else {
            // No window to hang the sheet on: the alert runs app-modal.
            alert.runModal()
            scheduleScan(after: 0)
            return
        }
        alert.beginSheetModal(for: window) { [weak self] _ in
            self?.scheduleScan(after: 0)
        }
    }
}
