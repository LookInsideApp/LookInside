//
//  ConnectionTipsBinding.swift
//  LookInside
//
//  Drives a view controller's "Reconnecting…" banner from its live
//  document: the banner shows (and pulses) while the document has a
//  connection-loss message and follows the document's current app icon.
//  A second, neutral banner shows the document's message while the app is
//  in the background.
//  Used by BaseViewController, which stays Objective-C while ObjC view
//  controllers still subclass it.
//

import AppKit

final class ConnectionTipsBinding: NSObject {
    private var observations: [NSKeyValueObservation] = []

    /// Starts observing right away and applies the current state. Holds the
    /// tips view and view controller weakly; observation stops when the
    /// binding is released.
    init(document: LiveDocument, tipsView: RedTipsView, backgroundTipsView: TipsView, viewController: NSViewController) {
        super.init()
        observations = [
            document.observe(\.connectionLossBannerMessage, options: [.initial, .new]) { [weak tipsView, weak viewController] document, _ in
                guard let tipsView, let viewController else { return }
                let containerView = viewController.view
                if (document.connectionLossBannerMessage ?? "").isEmpty {
                    tipsView.endAnimation()
                    tipsView.isHidden = true
                } else {
                    if tipsView.superview == nil {
                        containerView.addSubview(tipsView)
                    }
                    tipsView.isHidden = false
                    tipsView.startAnimation()
                    containerView.needsLayout = true
                }
            },
            document.observe(\.applicationInBackgroundBannerMessage, options: [.initial, .new]) { [weak backgroundTipsView, weak viewController] document, _ in
                guard let backgroundTipsView, let viewController else { return }
                let containerView = viewController.view
                let message = document.applicationInBackgroundBannerMessage ?? ""
                if message.isEmpty {
                    backgroundTipsView.isHidden = true
                } else {
                    if backgroundTipsView.superview == nil {
                        containerView.addSubview(backgroundTipsView)
                    }
                    backgroundTipsView.title = message
                    backgroundTipsView.isHidden = false
                    containerView.needsLayout = true
                }
            },
            // Auto-reconnect swaps the app; keep the banners' icons in step.
            document.observe(\.inspectableApp, options: [.initial, .new]) { [weak tipsView, weak backgroundTipsView] document, _ in
                tipsView?.setImage(byAppInfo: document.inspectableApp.appInfo)
                backgroundTipsView?.setImage(byAppInfo: document.inspectableApp.appInfo)
            },
        ]
    }
}
