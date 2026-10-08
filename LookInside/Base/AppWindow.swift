//
//  AppWindow.swift
//  LookInside
//

import AppKit

/// The app's window class: dropping a file onto it opens it in the reader.
@objc(LKWindow)
class AppWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        registerForDraggedTypes([.fileURL])
    }

    @objc func draggingEntered(_: NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    @objc func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let path = NSURL(from: sender.draggingPasteboard)?.path else {
            return false
        }
        do {
            try NavigationManager.shared.showReader(withFilePath: path)
            return true
        } catch {
            let nsError = error as NSError
            if nsError.code != LookinErrCode_Discard {
                NSAlert(error: nsError).beginSheetModal(for: self, completionHandler: nil)
            }
            return false
        }
    }
}
