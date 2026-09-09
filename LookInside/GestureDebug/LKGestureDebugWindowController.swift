import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@objc(LKGestureDebugWindowController)
final class LKGestureDebugWindowController: NSWindowController, NSWindowDelegate {
    private let session = LKGestureDebugSession()
    private var appObservation: NSKeyValueObservation?
    private weak var inspectionOwner: LKStaticWindowController?

    @objc(initWithOwner:)
    init(owner: LKStaticWindowController) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 740),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        super.init(window: window)
        inspectionOwner = owner
        window.title = "Gesture Debug"
        window.minSize = NSSize(width: 880, height: 540)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.setFrameAutosaveName("LookInside.GestureDebug")
        window.center()
        window.contentView = NSHostingView(rootView: LKGestureDebugView(
            session: session,
            start: { [weak self] in self?.session.start(window: self?.window) },
            export: { [weak self] in self?.exportCapture() }
        ))
        session.bind(to: owner.inspectableApp)
        appObservation = owner.observe(\.inspectableApp, options: [.new]) { [weak self] owner, _ in
            Task { @MainActor [weak self] in self?.session.bind(to: owner.inspectableApp) }
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(ownerWillClose), name: NSWindow.willCloseNotification, object: owner.window
        )
    }

    required init?(coder _: NSCoder) {
        nil
    }

    func windowWillClose(_: Notification) {
        session.stop()
    }

    @objc private func ownerWillClose() {
        session.dispose()
        appObservation?.invalidate()
        appObservation = nil
        close()
        NotificationCenter.default.removeObserver(self)
    }

    private func exportCapture() {
        guard let window else { return }
        Task {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "Gesture-Capture.json"
            guard await panel.beginSheetModal(for: window) == .OK, let url = panel.url else { return }
            do {
                try session.archiveData().write(to: url, options: .atomic)
            } catch {
                session.message = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}
