//
//  PreferenceWindowController.swift
//  LookInside
//
//  The Preferences window. Its content is the SwiftUI preference form
//  (PreferenceView.swift) hosted inside an BaseViewController.
//

import AppKit

@objc(LKPreferenceWindowController)
final class PreferenceWindowController: WindowController {
    @objc init() {
        #if DEBUG
            let windowHeight: CGFloat = 520
        #else
            let windowHeight: CGFloat = 455
        #endif
        let window = AppWindow(contentRect: NSRect(x: 0, y: 0, width: 660, height: windowHeight),
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered, defer: true)
        window.isMovableByWindowBackground = true
        window.title = NSLocalizedString("Preferences", comment: "")
        window.titlebarAppearsTransparent = true
        window.center()

        super.init(window: window)
        let viewController = PreferenceViewController()
        window.contentView = viewController.view
        contentViewController = viewController
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

@objc(LKPreferenceViewController)
final class PreferenceViewController: BaseViewController {
    init() {
        super.init(containerView: nil)
        installPreferenceForm()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func installPreferenceForm() {
        let hostingController = PreferenceHostingController()
        addChild(hostingController)
        let hostedView = hostingController.view
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostedView)
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: view.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
