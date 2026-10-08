//
//  LaunchViewController.swift
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

import AppKit

/// The launch window's content: the inspectable apps found so far, rescanned
/// every 1.5 seconds, and the attach-to-running-app button. Picking an app
/// fetches its hierarchy and opens a live document for it.
@objc(LKLaunchViewController)
final class LaunchViewController: BaseViewController {
    private static let appViewInterSpace: CGFloat = 10
    private static let contentHorInset: CGFloat = 30
    private static let contentHeight: CGFloat = 400
    /// A USB device that is plugged in takes about 0.1 seconds to reach the
    /// connection manager; the first scan waits a little longer than that.
    private static let initialScanDelay: TimeInterval = 0.2
    private static let rescanInterval: TimeInterval = 1.5

    private weak var window: NSWindow?
    private var autoEnterOnInitialReload: Bool

    private var appViews: [LaunchAppView] = []
    private let bottomIndicatorView = ProgressIndicatorView()
    private var reloadingIndicator: NSProgressIndicator?
    private var noAppsTitleLabel: TextLabel?
    private let attachToRunningAppButton = NSButton(
        title: NSLocalizedString("Attach to Running App…", comment: ""),
        target: nil,
        action: nil
    )

    private var isEnteringApp = false
    /// The infos of the last scan, so an unchanged app does not send its
    /// images again.
    private var appInfos: [InspectedAppInfo]?

    @objc(initWithWindow:)
    convenience init(window: NSWindow?) {
        self.init(window: window, autoEnterOnInitialReload: false)
    }

    @objc(initWithWindow:autoEnterOnInitialReload:)
    init(window: NSWindow?, autoEnterOnInitialReload: Bool) {
        self.window = window
        self.autoEnterOnInitialReload = autoEnterOnInitialReload
        super.init(containerView: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func makeContainerView() -> NSView {
        let containerView = VisualEffectView()
        containerView.blendingMode = .behindWindow
        containerView.state = .active

        containerView.addSubview(bottomIndicatorView)
        bottomIndicatorView.animate(toProgress: 0.7, duration: 0.5)

        // Attach-to-running-app entry: always visible (including the no-apps state)
        // so users can inject LookInsideServer.framework into an app that hasn't
        // statically linked the SDK.
        attachToRunningAppButton.target = self
        attachToRunningAppButton.action = #selector(handleAttachToRunningAppClick(_:))
        attachToRunningAppButton.bezelStyle = .rounded
        containerView.addSubview(attachToRunningAppButton)

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.initialScanDelay) {
            let autoEnter = self.autoEnterOnInitialReload
            self.autoEnterOnInitialReload = false
            self.reload(autoEntering: autoEnter)
        }
        return containerView
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        if let reloadingIndicator, let noAppsTitleLabel {
            reloadingIndicator.sizeToFit()
            ViewFrameLayout(noAppsTitleLabel).sizeToFit().x(reloadingIndicator.frame.maxX + 5).midY(reloadingIndicator.frame.midY)
            let views: [NSView] = [reloadingIndicator, noAppsTitleLabel]
            ViewFrameLayout.groupHorAlign(views)
            ViewFrameLayout.groupMidY(views, view.bounds.height * 0.35)
        }

        var posX = Self.contentHorInset
        for appView in appViews {
            ViewFrameLayout(appView).sizeToFit().x(posX).y(30)
            posX = appView.frame.maxX + Self.appViewInterSpace
        }

        ViewFrameLayout(bottomIndicatorView).fullWidth().height(3).bottom(0)

        attachToRunningAppButton.sizeToFit()
        ViewFrameLayout(attachToRunningAppButton)
            .midX(view.bounds.width / 2)
            .y(view.bounds.height - attachToRunningAppButton.frame.height - 14)
    }

    @objc private func handleAttachToRunningAppClick(_: Any?) {
        guard SwiftUISupportGatekeeper.sharedInstance().allowProtectedFeatureAccess(for: window) else {
            return
        }
        InjectionFlow.shared.startFromWindow(window)
    }

    // MARK: - Scanning

    private func reload(autoEntering autoEnter: Bool) {
        if isEnteringApp {
            return
        }
        Task { [weak self, appInfos] in
            let apps = await AppsManager.shared.fetchAppInfos(needImages: true, localInfos: appInfos)
            self?.didScan(apps, autoEnter: autoEnter)
        }
    }

    private func didScan(_ apps: [InspectableApp], autoEnter: Bool) {
        appInfos = apps.compactMap(\.appInfo)

        let canAutoEnter = LaunchRules.canAutoEnter(
            requested: autoEnter,
            appCount: apps.count,
            onlyAppHasServerVersionError: apps.first?.serverVersionError != nil,
            isActivated: SwiftUISupportGatekeeper.sharedInstance().activationState == .activated
        )
        if canAutoEnter, let app = apps.first {
            // The scan that runs as the window opens found exactly one app:
            // fetch its hierarchy right away.
            render(apps)
            enter(app)
            return
        }

        if bottomIndicatorView.progress > 0 {
            bottomIndicatorView.finish(completion: nil)
        }
        render(apps)

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.rescanInterval) {
            self.reload(autoEntering: false)
        }
    }

    private func render(_ apps: [InspectableApp]) {
        if apps.isEmpty {
            window?.setContentSize(NSSize(width: 256, height: Self.contentHeight))
            showNoAppsViews()
            appViews.forEach { $0.isHidden = true }
        } else {
            while appViews.count < apps.count {
                let appView = LaunchAppView()
                view.addSubview(appView)
                appViews.append(appView)
            }
            while appViews.count > apps.count {
                appViews.removeLast().removeFromSuperview()
            }

            let unlimited = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
            var windowWidth = Self.contentHorInset * 2 + CGFloat(apps.count - 1) * Self.appViewInterSpace
            for (appView, app) in zip(appViews, apps) {
                appView.app = app
                appView.addTarget(self, clickAction: #selector(handleClickAppView(_:)))
                windowWidth += appView.sizeThatFits(unlimited).width
                appView.isHidden = false
            }
            window?.setContentSize(NSSize(width: windowWidth, height: Self.contentHeight))
            hideNoAppsViews()
        }
        view.needsLayout = true
    }

    // MARK: - Entering an app

    @objc private func handleClickAppView(_ appView: LaunchAppView) {
        if isEnteringApp {
            return
        }
        guard let app = appView.app else { return }
        if let error = app.serverVersionError {
            AppHelper.openLookinWebsite(withPath: LaunchRules.serverVersionHelpPath(errorCode: error.code))
        } else {
            bottomIndicatorView.animate(toProgress: 0.8, duration: 1)
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
        bottomIndicatorView.finish { [weak self] in
            self?.openLiveDocument(for: app, priming: info)
        }
    }

    private func openLiveDocument(for app: InspectableApp, priming info: HierarchyInfo) {
        let (document, alreadyOpen) = LiveDocumentController.shared.openLiveDocument(for: app)
        if !alreadyOpen {
            document.hierarchyDataSource?.reload(with: info, keepState: false)
        }
        NavigationManager.shared.closeLaunch()
        let liveWindow = document.windowControllers.first?.window
        SwiftUISupportGatekeeper.sharedInstance().promptForPendingDetectedSwiftUISupportIfNeeded(window: liveWindow)
        isEnteringApp = false
    }

    private func enterFailed(_ error: Error) {
        isEnteringApp = false
        bottomIndicatorView.resetToZero()
        let alert = NSAlert(error: error)
        guard let window else {
            // No window to hang the sheet on: the alert runs app-modal.
            alert.runModal()
            reload(autoEntering: false)
            return
        }
        alert.beginSheetModal(for: window) { _ in
            self.reload(autoEntering: false)
        }
    }

    // MARK: - No apps

    private func showNoAppsViews() {
        if noAppsTitleLabel == nil {
            let label = TextLabel()
            label.textColor = .labelColor
            label.font = NSFont.systemFont(ofSize: 14)
            label.stringValue = NSLocalizedString("Searching for inspectable apps", comment: "")
            view.addSubview(label)
            noAppsTitleLabel = label
        }
        if reloadingIndicator == nil {
            let indicator = NSProgressIndicator()
            indicator.isIndeterminate = true
            indicator.style = .spinning
            indicator.controlSize = .small
            view.addSubview(indicator)
            indicator.startAnimation(self)
            reloadingIndicator = indicator
        }
        view.needsLayout = true
    }

    private func hideNoAppsViews() {
        noAppsTitleLabel?.removeFromSuperview()
        noAppsTitleLabel = nil
        reloadingIndicator?.removeFromSuperview()
        reloadingIndicator = nil
    }
}
