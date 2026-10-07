#if os(macOS)
    import AppKit
    import Foundation
    import LookInsideActivation
    import SwiftUI

    @MainActor
    public final class ActivationWindowController: NSWindowController, NSWindowDelegate {
        public let model: ActivationModel
        public let configuration: ActivationUIConfiguration
        public let activationWindow: NSWindow

        public init(
            model: ActivationModel,
            configuration: ActivationUIConfiguration = .init()
        ) {
            self.model = model
            self.configuration = configuration

            let closer = WindowCloser()
            let hostingController = NSHostingController(
                rootView: ActivationView(model: model, onDone: { closer.close() })
            )
            hostingController.sizingOptions = [.preferredContentSize]
            let window = NSWindow(contentViewController: hostingController)
            window.title = configuration.windowTitle
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            activationWindow = window
            closer.window = window

            super.init(window: window)
            window.delegate = self
            shouldCascadeWindows = true
        }

        @available(*, unavailable)
        public required init?(coder _: NSCoder) {
            nil
        }

        public func present() {
            showWindow(nil)
            ActivationWindowPlacement.centerWindowOnMouseScreen(activationWindow)
            ActivationWindowPlacement.pinWindowAboveNormalWindows(activationWindow)
            activationWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        /// Closes the activation window, as the license summary's Done button
        /// does. The helper quit its process here; the Host keeps running.
        public func dismiss() {
            activationWindow.close()
        }

        /// The helper quit when its window closed; inside the Host the window
        /// only hides (`isReleasedWhenClosed` is `false`) and can be shown again.
        public func windowShouldClose(_: NSWindow) -> Bool {
            true
        }
    }

    /// Lets the SwiftUI view close the window that hosts it, which does not
    /// exist yet when the view is created.
    @MainActor
    private final class WindowCloser {
        weak var window: NSWindow?

        func close() {
            window?.close()
        }
    }

    enum ActivationWindowPlacement {
        struct ScreenBounds {
            let frame: CGRect
            let visibleFrame: CGRect
        }

        @MainActor static func centerWindowOnMouseScreen(_ window: NSWindow) {
            let bounds = screenBoundsContainingMouse(
                NSEvent.mouseLocation,
                screens: NSScreen.screens.map {
                    ScreenBounds(frame: $0.frame, visibleFrame: $0.visibleFrame)
                }
            )

            guard let bounds else {
                window.center()
                return
            }

            window.setFrame(
                centeredFrame(for: window.frame, in: bounds.visibleFrame),
                display: true
            )
        }

        @MainActor static func pinWindowAboveNormalWindows(_ window: NSWindow) {
            window.level = .floating
        }

        static func screenBoundsContainingMouse(
            _ mouseLocation: CGPoint,
            screens: [ScreenBounds]
        ) -> ScreenBounds? {
            screens.first { $0.frame.contains(mouseLocation) }
        }

        static func centeredFrame(for windowFrame: CGRect, in visibleFrame: CGRect) -> CGRect {
            CGRect(
                x: visibleFrame.midX - windowFrame.width / 2,
                y: visibleFrame.midY - windowFrame.height / 2,
                width: windowFrame.width,
                height: windowFrame.height
            )
        }
    }
#else
    import Foundation

    @available(iOS, unavailable)
    @MainActor
    public final class ActivationWindowController {
        public init(
            model _: ActivationModel,
            configuration _: ActivationUIConfiguration = .init()
        ) {}
    }
#endif
