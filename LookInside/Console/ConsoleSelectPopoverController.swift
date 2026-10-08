//
//  ConsoleSelectPopoverController.swift
//  LookInside
//
//  The Console's target picker: objects recent calls returned, objects of
//  the item highlighted in the hierarchy, and the switch that makes the
//  highlighted item the target automatically.
//

import AppKit

final class ConsoleSelectPopoverController: BaseViewController {
    private static let insets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    private static let titleMarginTop: CGFloat = 16
    private static let itemControlMarginTop: CGFloat = 5
    private static let toggleButtonMarginTop: CGFloat = 22

    var needShowError: ((Error) -> Void)?
    var needClose: (() -> Void)?

    private let dataSource: ConsoleDataSource
    private let historyTitleView = ImageTextView()
    private let highlightTitleView = ImageTextView()
    private let toggleButton = NSButton()
    private let separatorLayer = CALayer()
    private var historyControls: [ConsoleSelectPopoverItemControl] = []
    private var highlightControls: [ConsoleSelectPopoverItemControl] = []
    private var syncObservation: NSKeyValueObservation?

    init(dataSource: ConsoleDataSource) {
        self.dataSource = dataSource
        super.init(containerView: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func makeContainerView() -> NSView {
        let view = BaseView()

        historyTitleView.imageMargins = HorizontalMargins(left: 0, right: 5)
        historyTitleView.imageView.image = NSImage(named: "console_history")
        historyTitleView.label.stringValue = NSLocalizedString("Objects returned recently in console", comment: "")
        view.addSubview(historyTitleView)

        highlightTitleView.imageMargins = HorizontalMargins(left: 0, right: 5)
        highlightTitleView.imageView.image = NSImage(named: "icon_cursor")
        highlightTitleView.label.stringValue = NSLocalizedString("Objects highlighted in hierarchy panel", comment: "")
        view.addSubview(highlightTitleView)

        toggleButton.setButtonType(.switch)
        toggleButton.title = NSLocalizedString("Automatically make highlighted view in hierarchy panel as console target", comment: "")
        toggleButton.font = .systemFont(ofSize: 12)
        toggleButton.target = self
        toggleButton.action = #selector(handleToggleSyncButton)
        view.addSubview(toggleButton)

        syncObservation = PreferenceManager.shared.observe(\.syncConsoleTarget, options: [.initial, .new]) {
            [weak self] manager, _ in
            let isOn = manager.syncConsoleTarget
            MainActor.assumeIsolated {
                self?.toggleButton.state = isOn ? .on : .off
            }
        }

        separatorLayer.removeImplicitAnimations()
        view.layer?.addSublayer(separatorLayer)
        view.didChangeAppearanceBlock = { [weak self] _, isDarkMode in
            self?.separatorLayer.backgroundColor = isDarkMode
                ? NSColor(white: 1, alpha: 0.2).cgColor
                : NSColor(white: 0, alpha: 0.12).cgColor
        }
        return view
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        let insets = Self.insets
        var y = insets.top

        func layoutControls(_ controls: [ConsoleSelectPopoverItemControl]) {
            for control in controls {
                control.lkpSetX(insets.left)
                control.lkpToRight(insets.right)
                control.lkpHeightToFit()
                control.lkpSetY(y + Self.itemControlMarginTop)
                y = control.frame.maxY
            }
        }

        if historyTitleView.isVisible {
            historyTitleView.lkpSizeToFit()
            historyTitleView.lkpSetX(insets.left)
            historyTitleView.lkpSetY(y)
            y = historyTitleView.frame.maxY
        }
        layoutControls(historyControls)
        if highlightTitleView.isVisible {
            if historyTitleView.isVisible {
                y += Self.titleMarginTop
            }
            highlightTitleView.lkpSizeToFit()
            highlightTitleView.lkpSetX(insets.left)
            highlightTitleView.lkpSetY(y)
            y = highlightTitleView.frame.maxY
        }
        layoutControls(highlightControls)

        toggleButton.lkpSetX(insets.left)
        toggleButton.lkpToRight(insets.right)
        toggleButton.lkpSetY(y + Self.toggleButtonMarginTop)
        toggleButton.lkpSetHeight(toggleButton.sizeThatFits(lkpMaxSize).height + 2)

        separatorLayer.lkpSetFrame(x: insets.left)
        separatorLayer.lkpToRight(insets.right)
        separatorLayer.lkpSetFrame(y: toggleButton.frame.minY - 7, height: 1)
    }

    func bestHeight() -> CGFloat {
        let insets = Self.insets
        var height = insets.top + insets.bottom
        if historyTitleView.isVisible {
            height += historyTitleView.sizeThatFits(lkpMaxSize).height
        }
        if highlightTitleView.isVisible {
            height += highlightTitleView.sizeThatFits(lkpMaxSize).height
            if historyTitleView.isVisible {
                height += Self.titleMarginTop
            }
        }
        for control in historyControls + highlightControls {
            height += control.sizeThatFits(lkpMaxSize).height + Self.itemControlMarginTop
        }
        height += toggleButton.sizeThatFits(lkpMaxSize).height + Self.toggleButtonMarginTop
        return height
    }

    /// Rebuilds the rows from the data source's recent and highlighted objects.
    func reRender() {
        let currentOid = dataSource.currentObject?.oid
        let recentObjects = dataSource.recentObjects.entries.map(\.element)
        if recentObjects.isEmpty {
            historyControls = resizedControls(historyControls, count: 1) { _, control in
                control.title = NSLocalizedString("No object was returned yet", comment: "")
                control.isChecked = false
                control.representedObject = nil
            }
        } else {
            historyControls = resizedControls(historyControls, count: recentObjects.count) { index, control in
                let recent = recentObjects[index]
                control.title = Self.title(of: recent.object)
                control.subtitle = recent.message
                control.isChecked = currentOid == recent.object.oid
                control.representedObject = recent.object
            }
        }

        let selectedObjects = dataSource.selectedObjects
        highlightTitleView.isHidden = selectedObjects.isEmpty
        highlightControls = resizedControls(highlightControls, count: selectedObjects.count) { index, control in
            let object = selectedObjects[index]
            control.title = Self.title(of: object)
            control.isChecked = currentOid == object.oid
            control.representedObject = object
        }
        view.needsLayout = true
    }

    private static func title(of object: InspectedObject) -> String {
        "<\(object.lk_simpleDemangledClassName()): \(object.memoryAddress ?? "(null)")>"
    }

    /// Keeps the first `count` controls, adds new ones as needed, removes the
    /// rest, and configures each kept or added control.
    private func resizedControls(
        _ controls: [ConsoleSelectPopoverItemControl],
        count: Int,
        configure: (Int, ConsoleSelectPopoverItemControl) -> Void
    ) -> [ConsoleSelectPopoverItemControl] {
        var result: [ConsoleSelectPopoverItemControl] = []
        for index in 0 ..< count {
            let control: ConsoleSelectPopoverItemControl
            if index < controls.count {
                control = controls[index]
            } else {
                control = ConsoleSelectPopoverItemControl()
                control.addTarget(self, clickAction: #selector(handleControl(_:)))
                view.addSubview(control)
            }
            result.append(control)
            configure(index, control)
        }
        for control in controls.dropFirst(count) {
            control.removeFromSuperview()
        }
        return result
    }

    @objc private func handleControl(_ control: ConsoleSelectPopoverItemControl) {
        guard let object = control.representedObject else { return }
        Task {
            do {
                try await dataSource.makeObjectCurrent(object)
                if object.oid != dataSource.selectedObjects.last?.oid {
                    PreferenceManager.shared.syncConsoleTarget = false
                }
                needClose?()
            } catch {
                needShowError?(ConnectionError.noConnect)
            }
        }
    }

    @objc private func handleToggleSyncButton() {
        let manager = PreferenceManager.shared
        manager.syncConsoleTarget = !manager.syncConsoleTarget
        guard manager.syncConsoleTarget else { return }
        Task {
            if (try? await dataSource.makeObjectCurrent(dataSource.selectedObjects.last)) != nil {
                reRender()
            }
        }
    }
}

/// One object in the target picker: a check mark when it is the target, its
/// class and address, and optionally the call that returned it.
final class ConsoleSelectPopoverItemControl: BaseControl {
    private static let subtitleMarginTop: CGFloat = 0

    var isChecked = false {
        didSet { imageView.isHidden = !isChecked }
    }

    var title: String? {
        didSet {
            titleLabel.stringValue = title ?? ""
            needsLayout = true
        }
    }

    var subtitle: String? {
        didSet {
            subtitleLabel.stringValue = subtitle ?? ""
            subtitleLabel.isHidden = (subtitle ?? "").isEmpty
            needsLayout = true
        }
    }

    var representedObject: InspectedObject? {
        didSet {
            titleLabel.textColor = representedObject == nil ? .secondaryLabelColor : .labelColor
        }
    }

    private let imageView = NSImageView()
    private let titleLabel = TextLabel()
    private let subtitleLabel = TextLabel()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        imageView.image = NSImage(named: "Console_Checked")
        addSubview(imageView)

        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.maximumNumberOfLines = 1
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingMiddle
        addSubview(titleLabel)

        subtitleLabel.maximumNumberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingMiddle
        subtitleLabel.font = .systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.isHidden = true
        addSubview(subtitleLabel)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        imageView.lkpSizeToFit()
        imageView.lkpSetX(3)
        imageView.lkpVerAlign()

        titleLabel.lkpSetX(imageView.frame.maxX + 4)
        titleLabel.lkpToRight(0)
        titleLabel.lkpHeightToFit()
        if subtitleLabel.lkpIsVisibleLabel {
            subtitleLabel.lkpSetX(titleLabel.frame.minX)
            subtitleLabel.lkpToRight(0)
            subtitleLabel.lkpHeightToFit()
            subtitleLabel.lkpSetY(titleLabel.frame.maxY + Self.subtitleMarginTop)
        }

        // Center the visible labels vertically as a group.
        let labels = [titleLabel, subtitleLabel].filter(\.lkpIsShown)
        guard let top = labels.map(\.frame.minY).min(), let bottom = labels.map(\.frame.maxY).max() else { return }
        let delta = bounds.height / 2 - (top + (bottom - top) / 2)
        for label in labels {
            label.lkpOffsetY(delta)
        }
    }

    override func sizeThatFits(_ size: NSSize) -> NSSize {
        let imageHeight = imageView.image?.size.height ?? 0
        var textHeight = titleLabel.sizeThatFits(lkpMaxSize).height
        if subtitleLabel.lkpIsVisibleLabel {
            textHeight += subtitleLabel.sizeThatFits(lkpMaxSize).height + Self.subtitleMarginTop
        }
        return NSSize(width: size.width, height: max(imageHeight, textHeight))
    }

    override func sizeToFit() {
        lkpSetSize(sizeThatFits(lkpMaxSize))
    }
}

private extension NSView {
    /// `-[NSView isVisible]` from NSView+LookinClient: not hidden and not transparent.
    var lkpIsVisibleLabel: Bool {
        !isHidden && alphaValue > 0
    }
}
