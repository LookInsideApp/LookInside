//
//  StaticConstants.swift
//  LookInside
//
//  The constants of the inspector window and its 3D preview, shared by the
//  classes that own them.
//

import CoreGraphics

/// Posted with a DisplayItem as the object to show the console and
/// print that item's view in it.
let appShowConsoleNotificationName = "LKAppShowConsoleNotificationName"

/// Message identifiers of MessageManager.
let jobsMessageIdentifier = "LKMessage_Jobs"
let swiftSubspecMessageIdentifier = "LKMessage_SwiftSubspec"

/// Bounds of PreviewView's scale and zInterspace (and of the preference
/// values that drive them).
let previewMinScale: CGFloat = 0
let previewMaxScale: CGFloat = 1
let previewMinZInterspace: CGFloat = 0
let previewMaxZInterspace: CGFloat = 1

@objc enum PreviewDimension: UInt {
    case dimension2D
    case dimension3D
}
