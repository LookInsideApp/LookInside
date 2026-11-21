//
//  LookinCoreTypes.swift
//  LookinCore
//
//  The enums and option sets the Host and the Server share, formerly C
//  NS_ENUM / NS_OPTIONS declarations. Each type keeps the Swift name, raw
//  type, raw values and case names the C declaration was imported with, and
//  every case keeps its C name for Objective-C through `@objc(...)`, so no
//  caller changed. The types are `@frozen`: the XCFramework builds with
//  library evolution and the tests without it, and frozen enums switch the
//  same way in both.
//
//  An enum decoded from the wire answers nil for a raw value it does not
//  know, where the imported C enum carried the value through; the decoders
//  fall back to their documented default then (protocol.md, "Wire enums").
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    // MARK: - Key appearance

    /// How far a macOS Server goes to show the inactive app as it looks in
    /// front while it takes images (`LookinParam_KeyAppearanceLevel`). Each
    /// level does what the one below it does, and more.
    @frozen
    @objc(LookinKeyAppearanceLevel)
    public enum LookinKeyAppearanceLevel: Int, Sendable {
        /// The window keeps the inactive look.
        @objc(LookinKeyAppearanceLevelOff)
        case off = 0

        /// The would-be key window is drawn as key (AppKit's private
        /// -acquireKeyAppearance): AppKit's own views look active; the window
        /// does not become key and the app is not told anything.
        @objc(LookinKeyAppearanceLevelDrawsAsKey)
        case drawsAsKey = 1

        /// As `drawsAsKey`, and the window answers true from -isKeyWindow and
        /// the app gets NSWindowDidBecomeKeyNotification /
        /// NSWindowDidResignKeyNotification, so views the app draws from
        /// -isKeyWindow look active too. The app's own become-key and
        /// resign-key code runs on every refresh.
        @objc(LookinKeyAppearanceLevelTreatsAsKey)
        case treatsAsKey = 2
    }

    // MARK: - Preview

    /// The SceneKit category bits the Host's preview gives its nodes.
    public struct LookinPreviewBitMask: OptionSet, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let selectable = LookinPreviewBitMask(rawValue: 1 << 1)
        public static let unselectable = LookinPreviewBitMask(rawValue: 1 << 2)
        public static let hasLight = LookinPreviewBitMask(rawValue: 1 << 3)
        public static let noLight = LookinPreviewBitMask(rawValue: 1 << 4)
    }

#endif
