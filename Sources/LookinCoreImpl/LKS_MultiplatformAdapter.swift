//
//  LKS_MultiplatformAdapter.swift
//  LookinCore
//
//  Was LKS_MultiplatformAdapter.m.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif
    #if canImport(UIKit)
        import UIKit
    #elseif os(macOS)
        import AppKit
    #endif

    @objc(LKS_MultiplatformAdapter)
    public class LKS_MultiplatformAdapter: NSObject {
        @objc(isiPad)
        public class func isiPad() -> Bool {
            #if canImport(UIKit)
                return lookinIsiPad
            #else
                return false
            #endif
        }

        @objc(isMac)
        public class func isMac() -> Bool {
            #if os(macOS)
                return true
            #else
                return false
            #endif
        }

        @objc(isMacCatalyst)
        public class func isMacCatalyst() -> Bool {
            #if targetEnvironment(macCatalyst)
                return true
            #else
                return false
            #endif
        }

        @objc(mainScreenBounds)
        public class func mainScreenBounds() -> CGRect {
            #if os(visionOS) || targetEnvironment(macCatalyst)
                return lookinFirstActiveWindowScene()?.coordinateSpace.bounds ?? .zero
            #elseif canImport(UIKit)
                return UIScreen.main.bounds
            #elseif os(macOS)
                // Not the screen's bounds: a Mac window need not fill the
                // screen, and Lookin is window based (on iOS the screen bounds
                // are the window bounds), so return the largest window size.
                var maxWidth: CGFloat = 0
                var maxHeight: CGFloat = 0
                for window in NSApplication.shared.windows {
                    maxWidth = max(maxWidth, window.frame.size.width)
                    maxHeight = max(maxHeight, window.frame.size.height)
                }
                return CGRect(x: 0, y: 0, width: maxWidth, height: maxHeight)
            #else
                return .zero
            #endif
        }

        @objc(mainScreenScale)
        public class func mainScreenScale() -> CGFloat {
            #if os(visionOS)
                return 2
            #elseif canImport(UIKit)
                return UIScreen.main.scale
            #elseif os(macOS)
                // [NSScreen mainScreen] is nil without a screen; the message to
                // nil answered 0.
                return NSScreen.main?.backingScaleFactor ?? 0
            #else
                return 1
            #endif
        }

        @objc(keyWindow)
        public class func keyWindow() -> LookinWindow? {
            #if os(visionOS)
                return lookinFirstActiveWindowScene()?.keyWindow
            #elseif canImport(UIKit)
                return lookinSharedApplication()?.keyWindow
            #elseif os(macOS)
                return NSApplication.shared.keyWindow
            #endif
        }

        @objc(allWindows)
        public class func allWindows() -> [LookinWindow] {
            #if canImport(UIKit)
                let scenes = allWindowScenes()
                if !scenes.isEmpty {
                    // NSMutableArray, so -containsObject: compares with
                    // -isEqual: as the original did.
                    let windows = NSMutableArray()
                    for windowScene in scenes {
                        for window in allWindows(for: windowScene) where !windows.contains(window) {
                            windows.add(window)
                        }

                        // UIModalPresentationFormSheet uses a private window that
                        // is missing from scene.windows but reachable via
                        // scene.keyWindow (iOS 15+).
                        if #available(iOS 15.0, tvOS 15.0, macCatalyst 15.0, *) {
                            if let sceneKeyWindow = windowScene.keyWindow, !windows.contains(sceneKeyWindow) {
                                if !NSStringFromClass(lookinObjCClass(of: sceneKeyWindow)).contains("HUD") {
                                    windows.add(sceneKeyWindow)
                                }
                            }
                        }
                    }
                    if windows.count > 0 {
                        return windows.copy() as! [LookinWindow]
                    }
                }
                #if os(visionOS)
                    // visionOS has no global window list to fall back to.
                    return []
                #else
                    return lookinSharedApplication()?.windows ?? []
                #endif
            #else
                return NSApplication.shared.windows
            #endif
        }

        #if canImport(UIKit)
            @objc(allWindowScenes)
            public class func allWindowScenes() -> [UIWindowScene] {
                var allScenes: [UIScene] = []
                // Private +[UIScene _scenesIncludingInternal:], available since
                // iOS 13: every scene, including the ones connectedScenes hides
                // (e.g. _UIKeyboardWindowScene on iOS 17+).
                let selector = NSSelectorFromString("_scenesIncludingInternal:")
                if UIScene.responds(to: selector) {
                    typealias ScenesIncludingInternal = @convention(c) (AnyClass, Selector, ObjCBool) -> Unmanaged<NSArray>?
                    let function = unsafeBitCast(UIScene.method(for: selector), to: ScenesIncludingInternal.self)
                    if let scenes = function(UIScene.self, selector, true)?.takeUnretainedValue() as? [UIScene] {
                        allScenes = scenes
                    }
                }
                if allScenes.isEmpty {
                    if let connectedScenes = lookinSharedApplication()?.connectedScenes {
                        allScenes = (connectedScenes as NSSet).allObjects as! [UIScene]
                    }
                }

                var windowScenes: [UIWindowScene] = []
                windowScenes.reserveCapacity(allScenes.count)
                for scene in allScenes {
                    if let windowScene = scene as? UIWindowScene {
                        windowScenes.append(windowScene)
                    }
                }
                return windowScenes
            }

            @objc(allWindowsForWindowScene:)
            public class func allWindows(for scene: UIWindowScene?) -> [UIWindow] {
                guard let scene else {
                    return []
                }
                // Private -[UIWindowScene _allWindowsIncludingInternalWindows:
                // onlyVisibleWindows:]. The public `windows` getter passes
                // includeInternal=NO, which drops every window whose
                // -isInternalWindow is YES; on iOS 26+ that includes
                // UIRemoteKeyboardWindow, the soft keyboard.
                let selector = NSSelectorFromString("_allWindowsIncludingInternalWindows:onlyVisibleWindows:")
                if scene.responds(to: selector) {
                    typealias AllWindows = @convention(c) (AnyObject, Selector, ObjCBool, ObjCBool) -> Unmanaged<NSArray>?
                    let function = unsafeBitCast(scene.method(for: selector), to: AllWindows.self)
                    if let windows = function(scene, selector, true, false)?.takeUnretainedValue() as? [UIWindow],
                       !windows.isEmpty
                    {
                        return windows
                    }
                }
                return scene.windows
            }
        #endif
    }

    #if canImport(UIKit)
        /// `[UIApplication sharedApplication]`, which is nil outside an app
        /// (an XCTest bundle, an extension); the Objective-C messages to it then
        /// answered nil. `UIApplication.shared` is implicitly unwrapped and
        /// would trap instead.
        private func lookinSharedApplication() -> UIApplication? {
            return UIApplication.shared
        }

        /// `+isiPad`'s dispatch_once value; a global `let` is initialized once,
        /// thread-safely, on first use.
        private let lookinIsiPad: Bool = UIDevice.current.model.hasPrefix("iPad")

        /// `[object class]`, not `type(of:)`: for a KVO-observed object the
        /// former is the original class.
        private func lookinObjCClass(of object: NSObject) -> AnyClass {
            object.perform(NSSelectorFromString("class"))
                .map { $0.takeUnretainedValue() as! AnyClass } ?? type(of: object)
        }
    #endif

    #if os(visionOS) || targetEnvironment(macCatalyst)
        /// `+getFirstActiveWindowScene`: the first foreground-active window
        /// scene.
        private func lookinFirstActiveWindowScene() -> UIWindowScene? {
            for scene in lookinSharedApplication()?.connectedScenes ?? [] {
                guard let windowScene = scene as? UIWindowScene else {
                    continue
                }
                if windowScene.activationState == .foregroundActive {
                    return windowScene
                }
            }
            return nil
        }
    #endif

#endif
