//
//  WindowController.swift
//  Lookin
//
//  Created by Li Kai on 2019/4/18.
//  https://lookin.work
//

import AppKit
import FoundationToolbox

@Loggable(subsystem: "com.lookinside.app")
class WindowController: NSWindowController, AppMenuManagerDelegate {
    deinit {
        #log(.default, "\(NSStringFromClass(type(of: self)), privacy: .public) dealloc")
    }
}
