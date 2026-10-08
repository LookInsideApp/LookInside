//
//  MenuPopoverAppsListController.swift
//  Lookin
//
//  Created by Li Kai on 2018/11/5.
//  https://lookin.work
//

import AppKit

/// The popover that lists the inspectable apps, opened from the app button,
/// the reload button or the connection-lost tips.
@objc(LKMenuPopoverAppsListController)
final class MenuPopoverAppsListController: BaseViewController {
    private let insets = NSEdgeInsets(top: 9, left: 18, bottom: 35, right: 14)
    private let titleMarginBottom: CGFloat = 3
    private let subtitleMarginBottom: CGFloat = 5
    private let appViewInterSpace: CGFloat = 1

    private var appViews: [LaunchAppView] = []
    private var titleLabel: TextLabel?
    private var subtitleLabel: TextLabel?

    @objc var didSelectApp: ((InspectableApp) -> Void)?

    @objc(initWithApps:source:)
    init(apps: [InspectableApp]?, source: MenuPopoverAppsListControllerEventSource) {
        // The apps scan sends nil when no port is connected.
        let apps = apps ?? []
        super.init(containerView: nil)

        let copy = ToolbarRules.appsPopoverCopy(source: source, appCount: apps.count)

        appViews = apps.map { app in
            let appView = LaunchAppView()
            appView.compactLayout = true
            appView.app = app
            appView.addTarget(self, clickAction: #selector(handleClickAppView(_:)))
            view.addSubview(appView)
            return appView
        }

        if let title = copy.title, !title.isEmpty {
            titleLabel = makeLabel(title, fontSize: 14)
        }
        if let subtitle = copy.subtitle, !subtitle.isEmpty {
            subtitleLabel = makeLabel(subtitle, fontSize: 12)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func makeLabel(_ text: String, fontSize: CGFloat) -> TextLabel {
        let label = TextLabel()
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: fontSize)
        label.textColor = .labelColor
        label.stringValue = text
        view.addSubview(label)
        return label
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        var y = insets.top
        if let titleLabel {
            ViewFrameLayout(titleLabel).fullWidth().heightToFit().y(y)
            y = titleLabel.frame.maxY + titleMarginBottom
        }
        if let subtitleLabel {
            ViewFrameLayout(subtitleLabel).fullWidth().heightToFit().y(y)
            y = subtitleLabel.frame.maxY + subtitleMarginBottom
        }

        if appViews.isEmpty {
            let labels = [titleLabel, subtitleLabel].compactMap { $0 }.filter { !$0.isHidden }
            ViewFrameLayout.groupVerAlign(labels)
        } else {
            var posX: CGFloat = 0
            for appView in appViews {
                ViewFrameLayout(appView).sizeToFit().x(posX).y(y)
                posX = appView.frame.maxX + appViewInterSpace
            }
            ViewFrameLayout.groupHorAlign(appViews)
        }
    }

    @objc private func handleClickAppView(_ appView: LaunchAppView) {
        guard let app = appView.app else { return }
        didSelectApp?(app)
    }

    @objc func bestSize() -> NSSize {
        guard !appViews.isEmpty else {
            return NSSize(width: 245, height: 80)
        }
        let unlimited = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        var width = insets.left + insets.right + CGFloat(appViews.count - 1) * appViewInterSpace
        var appViewMaxHeight: CGFloat = 0
        for appView in appViews {
            let size = appView.sizeThatFits(unlimited)
            width += size.width
            appViewMaxHeight = max(appViewMaxHeight, size.height)
        }

        var height = insets.top + insets.bottom + appViewMaxHeight
        if let titleLabel {
            let titleSize = titleLabel.sizeThatFits(unlimited)
            height += titleSize.height + titleMarginBottom
            width = max(width, titleSize.width + insets.left + insets.right)
        }
        if let subtitleLabel {
            let subtitleSize = subtitleLabel.sizeThatFits(unlimited)
            height += subtitleSize.height + subtitleMarginBottom
            width = max(width, subtitleSize.width + insets.left + insets.right)
        }
        return NSSize(width: width, height: height)
    }
}
