import AppKit
import Foundation
@testable import LookInsideActivation
@testable import LookInsideActivationUI
import Testing

/// The activation UI now runs inside the Host: closing it must never end the
/// process, and alerts raised by background flows must not run a modal loop.
@MainActor
struct ActivationWindowBehaviorTests {
    private func makeController() throws -> (ActivationWindowController, URL) {
        _ = NSApplication.shared
        let directory = try HelperFixtures.makeStateDirectory()
        let runtime = ActivationRuntime(
            configuration: HelperFixtures.isolatedConfiguration(stateDirectoryURL: directory),
            urlSession: .shared,
            now: { TestData.baseNow },
            silentRenewalEnabled: false
        )
        return (ActivationWindowController(model: runtime.activationModel()), directory)
    }

    /// The license summary's Done button calls `dismiss()`'s path; this test
    /// returning at all shows the process was not ended.
    @Test func doneClosesTheWindowAndKeepsTheProcess() throws {
        let (controller, directory) = try makeController()
        defer { try? FileManager.default.removeItem(at: directory) }

        controller.activationWindow.orderFront(nil)
        #expect(controller.activationWindow.isVisible)
        controller.dismiss()
        #expect(controller.activationWindow.isVisible == false)
        // Closed, not released: the window can be shown again.
        controller.activationWindow.orderFront(nil)
        #expect(controller.activationWindow.isVisible)
        controller.dismiss()
    }

    @Test func directActionsMayBeModalBackgroundFlowsNeverAre() {
        typealias Coordinator = ActivationWindowCoordinator
        #expect(Coordinator.alertTarget(for: .modal, activationWindowIsVisible: false) == .appModal)
        #expect(Coordinator.alertTarget(for: .modal, activationWindowIsVisible: true) == .activationWindow)
        #expect(
            Coordinator.alertTarget(for: .attached(to: nil), activationWindowIsVisible: true) == .activationWindow
        )
        #expect(
            Coordinator.alertTarget(for: .attached(to: nil), activationWindowIsVisible: false)
                == .shownActivationWindow
        )

        let hidden = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.titled],
            backing: .buffered,
            defer: true
        )
        hidden.isReleasedWhenClosed = false
        #expect(
            Coordinator.alertTarget(for: .attached(to: hidden), activationWindowIsVisible: false)
                == .shownActivationWindow
        )

        hidden.orderFront(nil)
        #expect(Coordinator.alertTarget(for: .attached(to: hidden), activationWindowIsVisible: false) == .sheet(hidden))
        hidden.orderOut(nil)
    }
}
