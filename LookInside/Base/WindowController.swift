//
//  WindowController.swift
//  Lookin
//
//  Created by Li Kai on 2019/4/18.
//  https://lookin.work
//

import AppKit

@objc(LKWindowController)
class WindowController: NSWindowController, AppMenuManagerDelegate {
    deinit {
        NSLog("%@ dealloc", NSStringFromClass(type(of: self)))
    }
}
