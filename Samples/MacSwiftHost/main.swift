import AppKit
import LookinServer

@_silgen_name("LookinServerStart")
private func LookinServerStartBridge()

final class SwiftHostAppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private var windowController: NSWindowController!
    private let tableItems = ["Mercury", "Venus", "Earth", "Mars", "Jupiter"]

    func applicationDidFinishLaunching(_: Notification) {
        LookinServerStartBridge()

        let window = NSWindow(
            contentRect: NSRect(x: 180, y: 180, width: 900, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LookInside Swift Host"
        window.isReleasedWhenClosed = false
        window.contentViewController = buildContentViewController()
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.windowController = windowController
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }

    func numberOfRows(in _: NSTableView) -> Int {
        tableItems.count
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("PlanetCell")
        let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView ?? {
            let view = NSTableCellView(frame: .zero)
            view.identifier = identifier
            let textField = NSTextField(labelWithString: "")
            textField.frame = NSRect(x: 10, y: 2, width: 240, height: 20)
            textField.autoresizingMask = [.width]
            textField.wantsLayer = true
            view.addSubview(textField)
            view.textField = textField
            view.wantsLayer = true
            return view
        }()
        cell.textField?.stringValue = tableItems[row]
        return cell
    }

    private func buildContentViewController() -> NSViewController {
        let root = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 900, height: 620))
        root.material = .sidebar
        root.blendingMode = .behindWindow
        root.state = .active
        root.wantsLayer = true

        let card = NSView(frame: NSRect(x: 28, y: 28, width: 844, height: 564))
        card.wantsLayer = true
        card.layer?.cornerRadius = 18
        card.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.92).cgColor
        root.addSubview(card)

        let title = NSTextField(labelWithString: "Embedded macOS target")
        title.font = .systemFont(ofSize: 28, weight: .semibold)
        title.frame = NSRect(x: 24, y: 512, width: 320, height: 34)
        title.wantsLayer = true
        card.addSubview(title)

        let subtitle = NSTextField(labelWithString: "Swift validation host for LookInside")
        subtitle.textColor = .secondaryLabelColor
        subtitle.frame = NSRect(x: 24, y: 486, width: 360, height: 20)
        subtitle.wantsLayer = true
        card.addSubview(subtitle)

        let actionButton = NSButton(title: "Inspect Me", target: nil, action: nil)
        actionButton.frame = NSRect(x: 24, y: 436, width: 140, height: 32)
        actionButton.bezelStyle = .rounded
        actionButton.wantsLayer = true
        card.addSubview(actionButton)

        let secondaryButton = NSButton(checkboxWithTitle: "Layer-backed controls", target: nil, action: nil)
        secondaryButton.state = .on
        secondaryButton.frame = NSRect(x: 180, y: 438, width: 180, height: 24)
        secondaryButton.wantsLayer = true
        card.addSubview(secondaryButton)

        let imageView = NSImageView(frame: NSRect(x: 24, y: 270, width: 180, height: 140))
        imageView.imageScaling = .scaleAxesIndependently
        imageView.image = NSImage(systemSymbolName: "desktopcomputer", accessibilityDescription: nil)
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 12
        imageView.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
        card.addSubview(imageView)

        let infoField = NSTextField(string: "NSTextField with editable content")
        infoField.frame = NSRect(x: 228, y: 370, width: 250, height: 24)
        infoField.wantsLayer = true
        card.addSubview(infoField)

        let effect = NSVisualEffectView(frame: NSRect(x: 228, y: 270, width: 250, height: 80))
        effect.material = .hudWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 12
        card.addSubview(effect)

        let effectLabel = NSTextField(labelWithString: "NSVisualEffectView content")
        effectLabel.frame = NSRect(x: 16, y: 30, width: 180, height: 20)
        effectLabel.wantsLayer = true
        effect.addSubview(effectLabel)

        let scrollView = NSScrollView(frame: NSRect(x: 510, y: 180, width: 300, height: 250))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.wantsLayer = true

        let tableView = NSTableView(frame: scrollView.bounds)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("planet"))
        column.title = "Planets"
        column.width = 280
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 24
        tableView.wantsLayer = true
        scrollView.documentView = tableView
        card.addSubview(scrollView)

        let viewController = NSViewController()
        viewController.view = root
        return viewController
    }
}

let app = NSApplication.shared
let delegate = SwiftHostAppDelegate()
app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
