//
//  LaunchSidebarViewController.swift
//  LookInside
//
//  The launch window's sidebar: the devices the scan found, each with its
//  icon, name, OS and app count, and the recently opened documents.
//  Selecting a device shows its apps; clicking a recent document opens it.
//

import AppKit
import UIFoundationAppKit
import UIFoundationToolbox

/// One device row of the sidebar.
struct LaunchSidebarDevice: Equatable {
    let identity: LaunchDeviceIdentity
    let name: String
    let systemDescription: String
    let appCount: Int
    /// An app info of the device, for its icon; nil when no app sent one.
    let iconAppInfo: InspectedAppInfo?
    /// The asset shown when no app info names the device.
    let fallbackIconName: String

    static func == (lhs: LaunchSidebarDevice, rhs: LaunchSidebarDevice) -> Bool {
        // The icon follows the identity; comparing the info objects would
        // see a change with every scan.
        lhs.identity == rhs.identity && lhs.name == rhs.name && lhs.systemDescription == rhs.systemDescription
            && lhs.appCount == rhs.appCount && (lhs.iconAppInfo == nil) == (rhs.iconAppInfo == nil)
    }
}

/// An outline view item. A class, because the outline view keys rows by
/// item identity.
private final class LaunchSidebarItem: NSObject {
    enum Content {
        case section(title: String)
        case device(LaunchSidebarDevice)
        case recentDocument(URL)
    }

    var content: Content
    var children: [LaunchSidebarItem]

    init(_ content: Content, children: [LaunchSidebarItem] = []) {
        self.content = content
        self.children = children
    }

    var deviceIdentity: LaunchDeviceIdentity? {
        if case let .device(device) = content {
            return device.identity
        }
        return nil
    }
}

final class LaunchSidebarViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    /// Runs when the user selects a device row.
    var onSelectDevice: ((LaunchDeviceIdentity) -> Void)?
    /// Runs when the user clicks a recent document row.
    var onOpenRecentDocument: ((URL) -> Void)?

    private let (scrollView, outlineView): (NSScrollView, OutlineView) = OutlineView.scrollableSingleColumnOutlineView()

    private let devicesSection = LaunchSidebarItem(.section(title: NSLocalizedString("Devices", comment: "Launch window sidebar section of the devices running inspectable apps")))
    private let recentSection = LaunchSidebarItem(.section(title: NSLocalizedString("Recent", comment: "Launch window sidebar section of the recently opened documents")))
    private var displayedDevices: [LaunchSidebarDevice] = []
    private var displayedRecentDocumentURLs: [URL] = []
    private var selectedDevice: LaunchDeviceIdentity?
    /// Set while the selection is changed from code, so it is not taken
    /// for the user's pick.
    private var isApplyingSelection = false

    override func loadView() {
        outlineView.style = .sourceList
        outlineView.floatsGroupRows = false
        outlineView.indentationPerLevel = 0
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.target = self
        outlineView.action = #selector(handleClick(_:))
        scrollView.drawsBackground = false
        view = scrollView
        reloadOutline()
    }

    /// Shows `devices` and `recentDocumentURLs`, and selects `selectedDevice`.
    func show(devices: [LaunchSidebarDevice], recentDocumentURLs: [URL], selectedDevice: LaunchDeviceIdentity?) {
        loadViewIfNeeded()
        let didChangeRows = devices.map(\.identity) != displayedDevices.map(\.identity) || recentDocumentURLs != displayedRecentDocumentURLs
        let didChangeContent = devices != displayedDevices
        displayedDevices = devices
        displayedRecentDocumentURLs = recentDocumentURLs
        self.selectedDevice = selectedDevice

        if didChangeRows {
            reloadOutline()
        } else if didChangeContent {
            // Same rows: refresh the device cells in place, so neither the
            // selection nor the scroll position moves.
            for (deviceItem, device) in zip(devicesSection.children, devices) {
                deviceItem.content = .device(device)
                let row = outlineView.row(forItem: deviceItem)
                guard row >= 0 else { continue }
                (outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? LaunchSidebarDeviceCellView)?.configure(with: device)
            }
        }
        applySelection()
    }

    private func reloadOutline() {
        devicesSection.children = displayedDevices.map { LaunchSidebarItem(.device($0)) }
        recentSection.children = displayedRecentDocumentURLs.map { LaunchSidebarItem(.recentDocument($0)) }
        isApplyingSelection = true
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
        isApplyingSelection = false
    }

    private func applySelection() {
        let row = devicesSection.children
            .first { $0.deviceIdentity == selectedDevice }
            .map { outlineView.row(forItem: $0) } ?? -1
        isApplyingSelection = true
        if row >= 0 {
            if outlineView.selectedRow != row {
                outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            }
        } else {
            outlineView.deselectAll(nil)
        }
        isApplyingSelection = false
    }

    private var rootItems: [LaunchSidebarItem] {
        displayedRecentDocumentURLs.isEmpty ? [devicesSection] : [devicesSection, recentSection]
    }

    @objc private func handleClick(_: Any?) {
        let clickedRow = outlineView.clickedRow
        guard clickedRow >= 0,
              let item = outlineView.item(atRow: clickedRow) as? LaunchSidebarItem,
              case let .recentDocument(url) = item.content
        else {
            return
        }
        onOpenRecentDocument?(url)
    }

    // MARK: - NSOutlineViewDataSource

    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item as? LaunchSidebarItem else { return rootItems.count }
        return item.children.count
    }

    func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item as? LaunchSidebarItem else { return rootItems[index] }
        return item.children[index]
    }

    func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let item = item as? LaunchSidebarItem, case .section = item.content else { return false }
        return true
    }

    // MARK: - NSOutlineViewDelegate

    func outlineView(_: NSOutlineView, isGroupItem item: Any) -> Bool {
        guard let item = item as? LaunchSidebarItem, case .section = item.content else { return false }
        return true
    }

    func outlineView(_: NSOutlineView, shouldShowOutlineCellForItem _: Any) -> Bool {
        false
    }

    func outlineView(_: NSOutlineView, shouldCollapseItem _: Any) -> Bool {
        false
    }

    func outlineView(_: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        (item as? LaunchSidebarItem)?.deviceIdentity != nil
    }

    func outlineView(_: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let item = item as? LaunchSidebarItem, case .device = item.content else { return 24 }
        return 40
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? LaunchSidebarItem else { return nil }
        switch item.content {
        case let .section(title):
            let cellView = outlineView.box.makeView(ofClass: LaunchSidebarSectionCellView.self)
            cellView.configure(title: title)
            return cellView
        case let .device(device):
            let cellView = outlineView.box.makeView(ofClass: LaunchSidebarDeviceCellView.self)
            cellView.configure(with: device)
            return cellView
        case let .recentDocument(url):
            let cellView = outlineView.box.makeView(ofClass: LaunchSidebarRecentDocumentCellView.self)
            cellView.configure(with: url)
            return cellView
        }
    }

    func outlineViewSelectionDidChange(_: Notification) {
        guard !isApplyingSelection,
              let item = outlineView.item(atRow: outlineView.selectedRow) as? LaunchSidebarItem,
              let identity = item.deviceIdentity
        else {
            return
        }
        selectedDevice = identity
        onSelectDevice?(identity)
    }
}

// MARK: - Cells

private final class LaunchSidebarSectionCellView: NSTableCellView {
    private let titleLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(title: String) {
        titleLabel.stringValue = title
    }
}

private final class LaunchSidebarDeviceCellView: NSTableCellView {
    private static let iconPointSize: CGFloat = 24

    private let iconImageView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let systemLabel = NSTextField(labelWithString: "")
    private let appCountLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        nameLabel.font = .systemFont(ofSize: NSFont.systemFontSize)
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        systemLabel.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        systemLabel.textColor = .secondaryLabelColor
        systemLabel.lineBreakMode = .byTruncatingTail
        systemLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        appCountLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        appCountLabel.textColor = .secondaryLabelColor
        appCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        appCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let labelsStackView = NSStackView(views: [nameLabel, systemLabel])
        labelsStackView.orientation = .vertical
        labelsStackView.alignment = .leading
        labelsStackView.spacing = 0
        labelsStackView.setHuggingPriority(.defaultLow - 1, for: .horizontal)

        for subview in [iconImageView, labelsStackView, appCountLabel] as [NSView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: Self.iconPointSize),
            iconImageView.heightAnchor.constraint(equalToConstant: Self.iconPointSize),

            labelsStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 7),
            labelsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            appCountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: labelsStackView.trailingAnchor, constant: 6),
            appCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            appCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with device: LaunchSidebarDevice) {
        nameLabel.stringValue = device.name
        systemLabel.stringValue = device.systemDescription
        systemLabel.isHidden = device.systemDescription.isEmpty
        appCountLabel.stringValue = String(device.appCount)
        if let iconAppInfo = device.iconAppInfo {
            iconImageView.image = DeviceIconProvider.deviceIconWithAssetFallback(forAppInfo: iconAppInfo, pointSize: Self.iconPointSize)
        } else {
            iconImageView.image = NSImage(named: device.fallbackIconName)
        }
        toolTip = device.systemDescription.isEmpty ? device.name : "\(device.name) · \(device.systemDescription)"
    }
}

private final class LaunchSidebarRecentDocumentCellView: NSTableCellView {
    private let iconImageView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        for subview in [iconImageView, nameLabel] as [NSView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with url: URL) {
        nameLabel.stringValue = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        iconImageView.image = NSWorkspace.shared.icon(forFile: url.path)
        toolTip = url.path
    }
}
