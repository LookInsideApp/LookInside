//
//  NSButton+LookinClient.swift
//  LookInside
//

import AppKit

extension NSButton {
    /// A rounded push button, already sized 84×40.
    @objc(lk_normalButtonWithTitle:target:action:)
    static func normalButton(withTitle title: String, target: AnyObject?, action: Selector?) -> NSButton {
        let button = NSButton()
        button.bezelStyle = .rounded
        button.title = title
        button.font = NSFont.systemFont(ofSize: 13)
        button.target = target
        button.action = action
        button.frame = NSRect(x: 0, y: 0, width: 84, height: 40)
        return button
    }

    /// A borderless image-only button; size it yourself.
    @objc(lk_buttonWithImage:target:action:)
    static func borderlessImageButton(with image: NSImage?, target: AnyObject?, action: Selector?) -> NSButton {
        let button = NSButton()
        button.image = image
        button.bezelStyle = .roundRect
        button.isBordered = false
        button.target = target
        button.action = action
        return button
    }
}
