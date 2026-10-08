//
//  BaseControl.swift
//  Lookin
//
//  Created by Li Kai on 2018/8/28.
//  https://lookin.work
//

import AppKit

@objc(LKBaseControl)
class BaseControl: NSControl {
    @objc var clickAction: Selector?

    @objc var adjustAlphaWhenClick = false

    @objc var didChangeAppearance: ((BaseControl?, Bool) -> Void)? {
        didSet {
            triggerDidChangeAppearanceBlock()
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var isFlipped: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if adjustAlphaWhenClick {
            alphaValue = 0.8
        }
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        triggerClickAction()
        if adjustAlphaWhenClick {
            alphaValue = 1
        }
    }

    @objc(addTarget:clickAction:)
    func addTarget(_ target: AnyObject?, clickAction action: Selector?) {
        self.target = target
        clickAction = action
    }

    @objc func triggerClickAction() {
        if let clickAction, target != nil {
            sendAction(clickAction, to: target)
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        triggerDidChangeAppearanceBlock()
    }

    private func triggerDidChangeAppearanceBlock() {
        if let didChangeAppearance {
            didChangeAppearance(self, effectiveAppearance.isDarkMode)
        }
    }

    override func sizeToFit() {
        frameLayout.size(bestSize())
    }

    /// 如果子类返回 true，则 mouseEntered: 和 mouseExited: 会被调用。默认为 false
    @objc func shouldTrackMouseEnteredAndExited() -> Bool {
        false
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        guard shouldTrackMouseEnteredAndExited() else {
            return
        }
        for oldArea in trackingAreas {
            removeTrackingArea(oldArea)
        }

        let newArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(newArea)
    }
}
