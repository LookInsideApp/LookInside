//
//  ProgressIndicatorView.swift
//  LookInside
//

import AppKit

/// The progress shown once the hierarchy itself has arrived and only
/// screenshots are left to fetch.
let InitialIndicatorProgressWhenFetchHierarchy: CGFloat = 0.7

/// A thin accent-coloured bar that fills from the left.
class ProgressIndicatorView: BaseView {
    private let fillLayer = CALayer()

    /// 0...1. Animatable through `animator()`.
    @objc dynamic var progress: CGFloat = 0 {
        didSet { layoutFillLayer() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        fillLayer.backgroundColor = AppHelper.accentColor().cgColor
        layer?.addSublayer(fillLayer)
        fillLayer.removeImplicitAnimations()
        progress = 0
    }

    override func layout() {
        super.layout()
        layoutFillLayer()
    }

    private func layoutFillLayer() {
        fillLayer.frameLayout.x(0).width(frame.width * progress).height(frame.height).y(0)
    }

    override func animation(forKey key: NSAnimatablePropertyKey) -> Any? {
        if key == "progress" {
            return CABasicAnimation()
        }
        return super.animation(forKey: key)
    }

    @objc func resetToZero() {
        progress = 0
    }

    /// Animates over 0.5 seconds.
    @objc(animateToProgress:)
    func animate(toProgress progress: CGFloat) {
        animate(toProgress: progress, duration: 0.5)
    }

    @objc(animateToProgress:duration:)
    func animate(toProgress progress: CGFloat, duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            self.animator().progress = progress
        }
    }

    /// Fills the bar, calls `completion`, then empties the bar 0.2 seconds
    /// later.
    @objc(finishWithCompletion:)
    func finish(completion: (() -> Void)?) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().progress = 1
        } completionHandler: {
            if let completion {
                DispatchQueue.main.async(execute: completion)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.progress = 0
            }
        }
    }
}
