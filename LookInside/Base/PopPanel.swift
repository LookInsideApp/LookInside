//
//  PopPanel.swift
//  LookInside
//

import AppKit

/// A borderless rounded panel for small editors that pop up over a window.
class PopPanel: NSPanel {
    @objc(initWithSize:)
    init(size: NSSize) {
        // Without NSWindowStyleMaskNonactivatingPanel, clicking another app
        // while the panel is shown hides every LookInside window.
        super.init(contentRect: NSRect(origin: .zero, size: size), styleMask: .nonactivatingPanel, backing: .buffered, defer: true)
        let contentView = BaseView()
        contentView.layer?.cornerRadius = 6
        contentView.layer?.borderWidth = 1
        contentView.didChangeAppearanceBlock = { view, isDarkMode in
            view?.backgroundColor = isDarkMode ? .rgb255(44, 44, 44) : .rgb255(236, 236, 236)
            view?.layer?.borderColor = (isDarkMode ? NSColor.rgb255(67, 67, 69) : NSColor.rgb255(215, 215, 215)).cgColor
        }
        self.contentView = contentView
        backgroundColor = .clear
    }

    /// Without this, text fields in the panel cannot start editing.
    override var canBecomeKey: Bool {
        true
    }
}
