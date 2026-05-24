import AppKit

final class LKInstallerProgressWindowController: NSWindowController, NSWindowDelegate {
    private let titleLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
    private let progressIndicator = NSProgressIndicator()
    var onCancel: (() -> Void)?

    init(title: String, initialStatus: String) {
        let contentRect = NSRect(x: 0, y: 0, width: 360, height: 140)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "LookInside"
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .modalPanel

        super.init(window: window)
        window.delegate = self

        titleLabel.stringValue = title
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.stringValue = initialStatus
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.lineBreakMode = .byTruncatingTail

        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        container.addSubview(statusLabel)
        container.addSubview(progressIndicator)

        window.contentView = container

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            progressIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 14),
            progressIndicator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            progressIndicator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            progressIndicator.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20),
        ])

        progressIndicator.startAnimation(nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
    }

    func updateStatus(_ text: String) {
        statusLabel.stringValue = text
    }

    func windowShouldClose(_: NSWindow) -> Bool {
        onCancel?()
        return true
    }
}
