//
//  BaseViewController.swift
//  Lookin
//
//  Created by Li Kai on 2018/8/28.
//  https://lookin.work
//

import AppKit

@objc(LKBaseViewController)
@objcMembers
class BaseViewController: NSViewController {
    private(set) var isViewAppeared = false

    private(set) var connectionTipsView: RedTipsView?

    private var connectionTipsBinding: ConnectionTipsBinding?

    /// 如果使用该初始化方法，则 controller.view 会被赋值为传入的 view。
    /// 如果使用普通的 init 方法，或该方法传入 nil，则 controller 会自动创建一个 view，即 makeContainerView()
    init(containerView view: NSView?) {
        super.init(nibName: nil, bundle: nil)
        self.view = view ?? makeContainerView()
    }

    override convenience init(nibName _: NSNib.Name?, bundle _: Bundle?) {
        self.init(containerView: nil)
    }

    required convenience init?(coder _: NSCoder) {
        self.init(containerView: nil)
    }

    deinit {
        NSLog("%@ dealloc", NSStringFromClass(type(of: self)))
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        isViewAppeared = true
    }

    override var view: NSView {
        get {
            super.view
        }
        set {
            super.view = newValue
            if shouldShowConnectionTips() {
                let tipsView = RedTipsView()
                tipsView.isHidden = true
                tipsView.title = NSLocalizedString("Reconnecting…", comment: "")
                tipsView.buttonText = NSLocalizedString("Change App", comment: "")
                tipsView.target = self
                tipsView.clickAction = #selector(handleClickReconnectTips)
                connectionTipsView = tipsView
            }
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        guard shouldShowConnectionTips(), let connectionTipsView else {
            return
        }
        // Phase F: drive the per-window banner from the host Live Doc's
        // `connectionLossBannerMessage` (set when the channel dies, cleared
        // when Phase D auto-reconnect succeeds). The lookup happens once
        // here because the window↔doc binding is fixed for this controller's
        // lifetime once the doc has called `-makeWindowControllers`.
        guard let document = LiveDocument.document(in: view.window) else {
            return
        }
        // The binding also follows inspectableApp swaps (Phase D auto-reconnect)
        // so the banner image stays in sync with the currently-bound app.
        connectionTipsBinding = ConnectionTipsBinding(document: document, tipsView: connectionTipsView, viewController: self)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        if let connectionTipsView, connectionTipsView.isVisible {
            let windowTitleHeight = NavigationManager.shared.windowTitleBarHeight
            connectionTipsView.frameLayout.sizeToFit().horAlign().y(windowTitleHeight + 10)
        }
    }

    @objc private func handleClickReconnectTips() {
        // Phase F: each Live Doc owns its own banner now, so clicking the
        // "Change App" pill on this window's banner pops up the picker on
        // *this* window (rather than routing through a global Static
        // workspace singleton).
        if let windowController = view.window?.windowController as? StaticWindowController {
            windowController.popupAllInspectableApps(with: .noConnectionTips)
        }
    }

    // MARK: - Subclassing hooks

    func makeContainerView() -> NSView {
        BaseView()
    }

    /// 是否在连接断开时显示 tips，默认为 NO
    func shouldShowConnectionTips() -> Bool {
        false
    }
}
