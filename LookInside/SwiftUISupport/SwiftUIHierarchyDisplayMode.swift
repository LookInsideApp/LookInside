//
//  SwiftUIHierarchyDisplayMode.swift
//  LookInside
//

import AppKit

@objc enum SwiftUIHierarchyDisplayMode: Int {
    case verbose = 0
    case compact = 1
}

extension Notification.Name {
    /// Posted on the main thread whenever
    /// `SwiftUIHierarchyDisplayModeStore.currentMode()` changes.
    /// Notification object: the store class.
    static let swiftUIHierarchyDisplayModeDidChange = Notification.Name("LKSwiftUIHierarchyDisplayModeDidChangeNotification")
}

@objc(LKSwiftUIHierarchyDisplayModeStore)
final class SwiftUIHierarchyDisplayModeStore: NSObject {
    private static let defaultsKey = "LookInside.SwiftUIHierarchyDisplayMode"

    /// Default = compact when no value persisted yet.
    static func currentMode() -> SwiftUIHierarchyDisplayMode {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: defaultsKey) != nil else {
            return .compact
        }
        return SwiftUIHierarchyDisplayMode(rawValue: defaults.integer(forKey: defaultsKey)) ?? .compact
    }

    /// Persist the new mode to UserDefaults and post
    /// swiftUIHierarchyDisplayModeDidChange if the value actually changed.
    static func setCurrentMode(_ mode: SwiftUIHierarchyDisplayMode) {
        guard currentMode() != mode else {
            return
        }
        UserDefaults.standard.set(mode.rawValue, forKey: defaultsKey)
        NotificationCenter.default.post(name: .swiftUIHierarchyDisplayModeDidChange, object: self)
    }

    /// Action of an NSSegmentedControl whose segment 0 is Compact and
    /// segment 1 is Verbose. Writes the new mode through `setCurrentMode(_:)`,
    /// which posts the change notification.
    @objc(swiftUIModeSegmentChanged:)
    static func swiftUIModeSegmentChanged(_ sender: NSSegmentedControl) {
        setCurrentMode(sender.selectedSegment == 0 ? .compact : .verbose)
    }
}
