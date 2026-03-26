import AppKit

final class ProbeDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let rows = [
        ("Title", "First row"),
        ("Status", "Inspector sample"),
        ("Count", "3")
    ]

    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = rows[row]
        let identifier = NSUserInterfaceItemIdentifier(rawValue: tableColumn?.identifier.rawValue ?? "cell")

        let textField: NSTextField
        if let reused = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTextField {
            textField = reused
        } else {
            textField = NSTextField(labelWithString: "")
            textField.identifier = identifier
            textField.lineBreakMode = .byTruncatingTail
        }

        textField.stringValue = tableColumn?.identifier.rawValue == "name" ? item.0 : item.1
        return textField
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let tableSource = ProbeDataSource()
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "LookInside AppKit Probe"
        window.isReleasedWhenClosed = false
        window.contentView = makeContentView(frame: window.contentLayoutRect)
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func makeContentView(frame: NSRect) -> NSView {
        let root = NSVisualEffectView(frame: frame)
        root.autoresizingMask = [.width, .height]
        root.material = .sidebar
        root.blendingMode = .behindWindow
        root.state = .active
        root.wantsLayer = true
        root.layer?.cornerRadius = 18
        root.layer?.borderWidth = 1
        root.layer?.borderColor = NSColor.separatorColor.cgColor

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "AppKit Inspector Probe")
        title.font = .systemFont(ofSize: 30, weight: .bold)
        title.textColor = .labelColor
        title.lineBreakMode = .byWordWrapping
        title.maximumNumberOfLines = 2

        let subtitle = NSTextField(string: "Editable text field")
        subtitle.placeholderString = "Type here"
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .left
        subtitle.bezelStyle = .roundedBezel

        let imageView = NSImageView()
        imageView.image = NSImage(named: NSImage.folderName)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 64).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let button = NSButton(title: "Toggle Sidebar Style", target: nil, action: nil)
        button.setButtonType(.toggle)
        button.state = .on

        let textView = NSTextView()
        textView.string = "NSTextView content\nwith multiple lines"
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor
        textView.alignment = .left
        textView.isEditable = true
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 12, height: 10)

        let textScroll = NSScrollView()
        textScroll.drawsBackground = true
        textScroll.backgroundColor = .textBackgroundColor
        textScroll.borderType = .bezelBorder
        textScroll.hasVerticalScroller = true
        textScroll.allowsMagnification = true
        textScroll.magnification = 1
        textScroll.contentInsets = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        textScroll.documentView = textView
        textScroll.translatesAutoresizingMaskIntoConstraints = false
        textScroll.widthAnchor.constraint(equalToConstant: 360).isActive = true
        textScroll.heightAnchor.constraint(equalToConstant: 140).isActive = true

        let tableView = NSTableView()
        tableView.headerView = nil
        tableView.rowHeight = 28
        tableView.gridStyleMask = [.solidHorizontalGridLineMask]
        tableView.gridColor = .separatorColor
        tableView.dataSource = tableSource
        tableView.delegate = tableSource

        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.width = 140
        let valueColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("value"))
        valueColumn.width = 200
        tableView.addTableColumn(nameColumn)
        tableView.addTableColumn(valueColumn)

        let tableScroll = NSScrollView()
        tableScroll.hasVerticalScroller = true
        tableScroll.borderType = .bezelBorder
        tableScroll.documentView = tableView
        tableScroll.contentInsets = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        tableScroll.translatesAutoresizingMaskIntoConstraints = false
        tableScroll.widthAnchor.constraint(equalToConstant: 360).isActive = true
        tableScroll.heightAnchor.constraint(equalToConstant: 140).isActive = true

        let mediaRow = NSStackView(views: [imageView, button])
        mediaRow.orientation = .horizontal
        mediaRow.alignment = .centerY
        mediaRow.spacing = 14

        stack.addArrangedSubview(title)
        stack.addArrangedSubview(subtitle)
        stack.addArrangedSubview(mediaRow)
        stack.addArrangedSubview(textScroll)
        stack.addArrangedSubview(tableScroll)

        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 28)
        ])

        return root
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.regular)
app.delegate = delegate
app.activate(ignoringOtherApps: true)
app.run()
