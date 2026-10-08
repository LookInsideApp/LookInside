//
//  ConnectionTipsBinding.swift
//  LookInside
//
//  Drives a view controller's "Reconnecting…" banner from its live
//  document: the banner shows (and pulses) while the document has a
//  connection-loss message and follows the document's current app icon.
//  Used by BaseViewController, which stays Objective-C while ObjC view
//  controllers still subclass it.
//

import AppKit

@objc(LKConnectionTipsBinding)
final class ConnectionTipsBinding: NSObject {
    private var observations: [NSKeyValueObservation] = []

    /// Starts observing right away and applies the current state. Holds the
    /// tips view and view controller weakly; observation stops when the
    /// binding is released.
    @objc(initWithDocument:tipsView:viewController:)
    init(document: LiveDocument, tipsView: RedTipsView, viewController: NSViewController) {
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
            // Auto-reconnect swaps the app; keep the banner's icon in step.
            document.observe(\.inspectableApp, options: [.initial, .new]) { [weak tipsView] document, _ in
                tipsView?.setImage(byAppInfo: document.inspectableApp.appInfo)
            },
        ]
    }
}
