//
//  LKPeripheralAlerts.swift
//  LookInside
//
//  Swift counterparts of the `LookinErrorMake`, `AlertError` and
//  `AlertErrorText` macros for the peripheral modules.
//

import AppKit

enum LKPeripheralAlerts {
    /// `LookinErrorMake(title, detail)`: a default-code Lookin error.
    static func error(title: String, detail: String) -> NSError {
        NSError(domain: LookinErrorDomain, code: LookinErrCode_Default, userInfo: [
            NSLocalizedDescriptionKey: title,
            NSLocalizedRecoverySuggestionErrorKey: detail,
        ])
    }

    /// `AlertError(error, window)`: shows `error` as a sheet unless it is a
    /// discarded request. Without a window the alert runs app-modal.
    @MainActor
    static func show(_ error: Error, in window: NSWindow?) {
        let error = error as NSError
        guard error.code != LookinErrCode_Discard else { return }
        let alert = NSAlert(error: error)
        if let window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }

    /// `AlertErrorText(title, detail, window)`.
    @MainActor
    static func show(title: String, detail: String, in window: NSWindow?) {
        show(error(title: title, detail: detail), in: window)
    }

    /// `CurrentKeyWindow`.
    @MainActor
    static var keyWindow: NSWindow? {
        NSApp.keyWindow
    }
}
