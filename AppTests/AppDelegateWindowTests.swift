//
//  AppDelegateWindowTests.swift
//  LookInsideAppTests
//
//  The app's window lifecycle, run by the real AppDelegate: closing the last
//  window brings the launch window back, closing the launch window leaves
//  none, and a Dock click with no window shows the launch window again.
//  Under the test host the app starts with no window (AppDelegate skips the
//  launch window then), so each test starts from none and closes what it
//  opened.
//

import AppKit
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct AppDelegateWindowTests {
        private var appDelegate: AppDelegate {
            get throws {
                try #require(NSApp.delegate as? AppDelegate)
            }
        }

        private var launchWindow: NSWindow? {
            NavigationManager.shared.launchWindowController?.window
        }

        private var isLaunchWindowOnScreen: Bool {
            launchWindow?.isVisible == true
        }

        /// A titled window, as the inspector and reader windows are.
        private func makeAppWindow() -> NSWindow {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            return window
        }

        /// Closes the launch window and waits out the turn its close is
        /// handled on, so the next test starts with no window.
        private func closeLaunchWindow() async {
            NavigationManager.shared.closeLaunch()
            try? await Task.sleep(for: .milliseconds(100))
        }

        @Test func closingTheLastWindowShowsTheLaunchWindow() async {
            await closeLaunchWindow()
            let window = makeAppWindow()
            window.makeKeyAndOrderFront(nil)
            #expect(!isLaunchWindowOnScreen)

            window.close()

            #expect(await waitUntil { isLaunchWindowOnScreen })
            await closeLaunchWindow()
        }

        @Test func closingOneOfTwoWindowsDoesNotShowTheLaunchWindow() async {
            await closeLaunchWindow()
            let closedWindow = makeAppWindow()
            let remainingWindow = makeAppWindow()
            closedWindow.makeKeyAndOrderFront(nil)
            remainingWindow.makeKeyAndOrderFront(nil)

            closedWindow.close()
            try? await Task.sleep(for: .milliseconds(300))
            #expect(!isLaunchWindowOnScreen)

            remainingWindow.close()
            #expect(await waitUntil { isLaunchWindowOnScreen })
            await closeLaunchWindow()
        }

        /// A panel is not one of the app's windows: closing it with nothing
        /// else open leaves the app without a window.
        @Test func closingAPanelDoesNotShowTheLaunchWindow() async {
            await closeLaunchWindow()
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            panel.isReleasedWhenClosed = false
            panel.orderFront(nil)

            panel.close()
            try? await Task.sleep(for: .milliseconds(300))

            #expect(!isLaunchWindowOnScreen)
        }

        @Test func closingTheLaunchWindowLeavesNoWindow() async throws {
            NavigationManager.shared.showLaunch()
            let launch = try #require(launchWindow)
            #expect(launch.isVisible)

            launch.close()
            try? await Task.sleep(for: .milliseconds(300))

            #expect(!isLaunchWindowOnScreen)
            #expect(!NSApp.windows.contains { $0.isVisible && $0.styleMask.contains(.titled) && !($0 is NSPanel) })
            await closeLaunchWindow()
        }

        @Test func dockClickWithNoWindowShowsTheLaunchWindow() async throws {
            await closeLaunchWindow()

            let appKitShouldReopen = try appDelegate.applicationShouldHandleReopen(NSApp, hasVisibleWindows: false)

            #expect(!appKitShouldReopen, "handled here, so AppKit does not reopen a window itself")
            #expect(isLaunchWindowOnScreen)
            await closeLaunchWindow()
        }

        @Test func dockClickWithAWindowOnScreenOnlyBringsItForward() async throws {
            await closeLaunchWindow()
            let window = makeAppWindow()
            window.orderFront(nil)

            _ = try appDelegate.applicationShouldHandleReopen(NSApp, hasVisibleWindows: false)

            #expect(!isLaunchWindowOnScreen)
            #expect(window.isVisible)
            window.close()
            #expect(await waitUntil { isLaunchWindowOnScreen })
            await closeLaunchWindow()
        }
    }
}
