//
//  LKStaticConstants.swift
//  LookInside
//
//  The constants of the inspector window and its 3D preview, shared by the
//  classes that own them.
//

import CoreGraphics

/// Posted with a DisplayItem as the object to show the console and
/// print that item's view in it.
let LKAppShowConsoleNotificationName = "LKAppShowConsoleNotificationName"

/// Message identifiers of LKMessageManager.
let LKMessage_Jobs = "LKMessage_Jobs"
let LKMessage_SwiftSubspec = "LKMessage_SwiftSubspec"

/// Bounds of LKPreviewView's scale and zInterspace (and of the preference
/// values that drive them).
let LookinPreviewMinScale: CGFloat = 0
let LookinPreviewMaxScale: CGFloat = 1
let LookinPreviewMinZInterspace: CGFloat = 0
let LookinPreviewMaxZInterspace: CGFloat = 1

@objc enum LookinPreviewDimension: UInt {
    case dimension2D
    case dimension3D
}
