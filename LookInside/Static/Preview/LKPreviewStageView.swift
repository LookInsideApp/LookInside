//
//  LKPreviewStageView.swift
//  LookInside
//
//  Created by Li Kai on 2018/8/6.
//  https://lookin.work
//

import AppKit

@MainActor
protocol LKPreviewStageViewDelegate: AnyObject {
    func previewStageView(_ view: LKPreviewStageView, mouseMoved event: NSEvent)
    func didResetCursorRects(in view: LKPreviewStageView)
}

/// The preview controller's root view: reports mouse moves anywhere over it
/// and lets the delegate add cursor rects.
@objc(LKPreviewStageView)
final class LKPreviewStageView: LKBaseView {
    weak var delegate: LKPreviewStageViewDelegate?

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        delegate?.previewStageView(self, mouseMoved: event)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        delegate?.didResetCursorRects(in: self)
    }
}

/// The preview's pan gesture: rotates the preview, or moves it while space
/// is held.
@objc(LKPreviewPanGestureRecognizer)
final class LKPreviewPanGestureRecognizer: NSPanGestureRecognizer {
    enum Purpose {
        case rotate
        case translate
    }

    var purpose: Purpose = .rotate
    var initialRotation: CGPoint = .zero
    var initialTranslation: NSPoint = .zero
}
