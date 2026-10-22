import AppKit
@testable import LookInsideActivation
@testable import LookInsideActivationUI
import Testing

@MainActor
struct ActivationWindowPlacementTests {
    private typealias Placement = ActivationWindowPlacement

    @Test func screenBoundsContainingMouseUsesScreenUnderCursor() {
        let leftScreen = Placement.ScreenBounds(
            frame: CGRect(x: -1440, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: -1440, y: 25, width: 1440, height: 875)
        )
        let rightScreen = Placement.ScreenBounds(
            frame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
            visibleFrame: CGRect(x: 0, y: 38, width: 1728, height: 1079)
        )

        let bounds = Placement.screenBoundsContainingMouse(
            CGPoint(x: -240, y: 500),
            screens: [rightScreen, leftScreen]
        )

        #expect(bounds?.frame == leftScreen.frame)
        #expect(bounds?.visibleFrame == leftScreen.visibleFrame)
    }

    @Test func centeredFrameUsesScreenVisibleFrame() {
        let windowFrame = CGRect(x: 0, y: 0, width: 400, height: 200)
        let visibleFrame = CGRect(x: 100, y: 50, width: 1000, height: 700)

        let centeredFrame = Placement.centeredFrame(
            for: windowFrame,
            in: visibleFrame
        )

        #expect(centeredFrame == CGRect(x: 400, y: 300, width: 400, height: 200))
    }

    @Test func pinWindowAboveNormalWindowsUsesFloatingLevel() {
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        Placement.pinWindowAboveNormalWindows(window)

        #expect(window.level == .floating)
    }
}
