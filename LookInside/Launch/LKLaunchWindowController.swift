//
//  LKLaunchWindowController.swift
//  Lookin
//
//  Created by Li Kai on 2018/11/3.
//  https://lookin.work
//

import AppKit

/// The small launch window that lists the inspectable apps.
@objc(LKLaunchWindowController)
final class LKLaunchWindowController: LKWindowController {
    @objc let launchViewController: LKLaunchViewController

    /// - Parameter autoEnterOnInitialReload: whether the first scan opens
    ///   the only app it finds by itself.
    @objc(initWithAutoEnterOnInitialReload:)
    init(autoEnterOnInitialReload: Bool) {
        let window = LKWindow(
            contentRect: NSRect(x: 0, y: 0, width: 252, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()

        launchViewController = LKLaunchViewController(window: window, autoEnterOnInitialReload: autoEnterOnInitialReload)
        super.init(window: window)
        window.contentView = launchViewController.view
        contentViewController = launchViewController
    }

    @objc convenience init() {
        self.init(autoEnterOnInitialReload: false)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
