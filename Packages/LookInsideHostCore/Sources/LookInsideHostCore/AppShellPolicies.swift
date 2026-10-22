//
//  AppShellPolicies.swift
//  LookInsideHostCore
//
//  Pure decisions of the Host's app shell: the per-app expansion state
//  stored in user defaults, the Server version comparison and the SwiftUI
//  selection hand-over after a display-mode reload. The app target wraps
//  them (LKPreferenceManager, LKVersionComparer, LKStaticWindowController);
//  keeping them here lets `swift test` cover them without the app.
//

import Foundation

/// How the per-app hierarchy expansion state is kept in user defaults.
///
/// Each app's state lives under `ExpansionState.<bundle id>`; the bundle
/// ids are ordered most recent first under `ExpansionStateBundleLRU`, and
/// only the 20 most recent keep their state.
public enum ExpansionStatePolicy {
    public static let lruKey = "ExpansionStateBundleLRU"
    public static let stateKeyPrefix = "ExpansionState."
    public static let capacity = 20

    public static func stateKey(forBundleIdentifier bundleIdentifier: String) -> String {
        stateKeyPrefix + bundleIdentifier
    }

    /// The LRU list with `bundleIdentifier` first. Earlier entries for the
    /// same id, and malformed entries (not strings, or empty) left by a
    /// damaged plist, are dropped.
    public static func lru(movingToFront bundleIdentifier: String, in storedLRU: Any?) -> [String] {
        var result = [bundleIdentifier]
        if let entries = storedLRU as? [Any] {
            for entry in entries {
                guard let identifier = entry as? String, !identifier.isEmpty, identifier != bundleIdentifier else {
                    continue
                }
                result.append(identifier)
            }
        }
        return result
    }

    /// Splits an LRU list into the entries that stay and the ones past the
    /// capacity, whose state is removed.
    public static func evicting(_ lru: [String], capacity: Int = capacity) -> (kept: [String], evicted: [String]) {
        guard lru.count > capacity else {
            return (lru, [])
        }
        return (Array(lru[..<capacity]), Array(lru[capacity...]))
    }

    /// Whether moving `bundleIdentifier` to the front changes the stored
    /// list: only a recorded id that is not already first moves.
    public static func shouldBump(_ bundleIdentifier: String, in storedLRU: Any?) -> Bool {
        guard let entries = storedLRU as? [Any] else {
            return false
        }
        let contains = entries.contains { ($0 as? String) == bundleIdentifier }
        guard contains else {
            return false
        }
        return (entries.first as? String) != bundleIdentifier
    }

    /// Reads a stored expansion state: path → expanded.
    ///
    /// The current format is a dictionary of path to boolean; entries with
    /// an empty or non-string key or a non-number value are skipped. The
    /// legacy format, an array of the expanded paths, reads as all of them
    /// expanded. Anything else reads as empty.
    public static func decodeState(_ stored: Any?) -> [String: Bool] {
        if let dictionary = stored as? NSDictionary {
            var result: [String: Bool] = [:]
            for (key, value) in dictionary {
                guard let path = key as? String, !path.isEmpty, let number = value as? NSNumber else {
                    continue
                }
                result[path] = number.boolValue
            }
            return result
        }
        if let array = stored as? NSArray {
            var result: [String: Bool] = [:]
            for entry in array {
                guard let path = entry as? String, !path.isEmpty else {
                    continue
                }
                result[path] = true
            }
            return result
        }
        return [:]
    }
}

/// The Server version comparison used to gate features on old Servers.
public enum ServerVersionComparison {
    /// `"1.2.7"` → 10207: the first three dot-separated components, each
    /// read like `-[NSString integerValue]`, weighted 10000, 100 and 1.
    /// An empty string reads as 0.
    public static func numericVersion(_ version: String) -> Int {
        guard !version.isEmpty else {
            return 0
        }
        let components = version.components(separatedBy: ".")
        var result = 0
        for (position, component) in components.prefix(3).enumerated() {
            let weight = [10000, 100, 1][position]
            result += (component as NSString).integerValue * weight
        }
        return result
    }

    /// Whether `realVersion` is at least `expectedVersion`; nil when either
    /// reads as 0 (unparseable), which callers treat as unsupported.
    public static func satisfies(expectedVersion: String, realVersion: String) -> Bool? {
        let expected = numericVersion(expectedVersion)
        let real = numericVersion(realVersion)
        guard expected != 0, real != 0 else {
            return nil
        }
        return real >= expected
    }
}

/// Keeps a SwiftUI selection across a display-mode reload. SwiftUI display
/// item ids look like `swiftui:<hostHash>:<pre-order index>`; compact mode
/// folds some items away, so a selected id may be gone after the reload.
public enum SwiftUISelectionMigration {
    public static let idPrefix = "swiftui:"

    public enum Outcome: Equatable, Sendable {
        /// The prior id is still in the tree, at this index of the list.
        case exact(Int)
        /// The prior id is gone; this index holds the SwiftUI item with
        /// the smallest pre-order index after the prior one.
        case migrated(Int)
        case none
    }

    public static func isSwiftUIID(_ identifier: String?) -> Bool {
        identifier?.hasPrefix(idPrefix) ?? false
    }

    /// The last `:`-separated component as an integer, or nil when there is
    /// no colon or the tail is not an integer (surrounding whitespace is
    /// allowed, as `NSScanner` allows it).
    public static func preOrderIndex(of identifier: String) -> Int? {
        guard let lastColon = identifier.range(of: ":", options: .backwards) else {
            return nil
        }
        let scanner = Scanner(string: String(identifier[lastColon.upperBound...]))
        guard let value = scanner.scanInt(), scanner.isAtEnd else {
            return nil
        }
        return value
    }

    /// Where the selection goes in the reloaded list `identifiers` (the
    /// display item ids in display order; nil for items without one).
    public static func target(priorIdentifier: String, in identifiers: [String?]) -> Outcome {
        guard !priorIdentifier.isEmpty else {
            return .none
        }
        if let index = identifiers.firstIndex(where: { $0 == priorIdentifier }) {
            return .exact(index)
        }
        guard let priorIndex = preOrderIndex(of: priorIdentifier), priorIndex >= 0 else {
            return .none
        }
        var best: (listIndex: Int, preOrder: Int)?
        for (listIndex, identifier) in identifiers.enumerated() {
            guard let identifier, isSwiftUIID(identifier), let candidate = preOrderIndex(of: identifier) else {
                continue
            }
            if candidate > priorIndex, candidate < (best?.preOrder ?? Int.max) {
                best = (listIndex, candidate)
            }
        }
        return best.map { .migrated($0.listIndex) } ?? .none
    }
}
