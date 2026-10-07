//
//  LKHierarchyHandlersPopoverController.swift
//  LookInside
//
//  Created by Li Kai on 2019/8/11.
//  https://lookin.work
//

import AppKit

/// The popover a hierarchy row's event-handler button opens: one item per
/// gesture recognizer or target-action of the node.
final class LKHierarchyHandlersPopoverController: LKBaseViewController {
    private let scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        return scrollView
    }()

    private var itemViews: [LKHierarchyHandlersPopoverItemView] = []
    private let verInset: CGFloat = 0

    /// - Parameter editable: false in read mode, where a gesture recognizer
    ///   cannot be switched on or off.
    init(displayItem: LookinDisplayItem, editable: Bool) {
        super.init(containerView: nil)
        let documentView = LKBaseView()
        scrollView.documentView = documentView

        itemViews = (displayItem.eventHandlers ?? []).enumerated().map { index, handler in
            let view = LKHierarchyHandlersPopoverItemView(eventHandler: handler, editable: editable)
            documentView.addSubview(view)
            view.needTopBorder = index > 0
            view.isHidden = false
            return view
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("LKHierarchyHandlersPopoverController is not loaded from archives")
    }

    override func makeContainerView() -> NSView {
        scrollView
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        guard let documentView = scrollView.documentView else {
            return
        }
        LKHierarchyFrameLayout(documentView).fullWidth().y(0)

        // Item views are LKBaseViews: the height fit sizes them with
        // sizeThatFits, as LookInside's ShortCocoa fitting did.
        var maxY: CGFloat = 0
        let visibleViews = itemViews.filter { !$0.isHidden }
        for (index, view) in visibleViews.enumerated() {
            let y = index > 0 ? itemViews[index - 1].frame.maxY : verInset
            LKHierarchyFrameLayout(view).fullWidth().heightToFit().y(y)
            if index == visibleViews.count - 1 {
                maxY = view.frame.maxY
            }
        }
        LKHierarchyFrameLayout(documentView).height(maxY)
    }

    func neededSize() -> NSSize {
        var size = NSSize(width: 0, height: verInset * 2)
        for itemView in itemViews where !itemView.isHidden {
            let itemSize = itemView.sizeThatFits(NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
            size.width = max(size.width, itemSize.width)
            size.height += itemSize.height
        }
        return size
    }
}

/// One event handler in the popover: its name, targets and actions, and
/// for a gesture recognizer its delegate, ivar traces and an enabled switch.
final class LKHierarchyHandlersPopoverItemView: LKBaseView {
    var needTopBorder = false {
        didSet {
            topSepLayer.isHidden = !needTopBorder
        }
    }

    private let eventHandler: LookinEventHandler
    private let iconImageView = NSImageView()
    private let titleLabel = LKLabel()
    private var subtitleLabel: LKLabel?
    private var recognizerEnableButton: NSButton?
    private let contentView = LKTextsMenuView()
    private let topSepLayer = CALayer()

    private let contentX: CGFloat = 28
    private let insetRight: CGFloat = 16
    private let verInset: CGFloat = 10
    private let contentMarginTop: CGFloat = 4
    private let subtitleMarginTop: CGFloat = 3

    /// - Parameter editable: false in read mode.
    init(eventHandler: LookinEventHandler, editable: Bool) {
        self.eventHandler = eventHandler
        super.init(frame: .zero)

        layer?.addSublayer(topSepLayer)
        addSubview(iconImageView)

        titleLabel.isSelectable = true
        titleLabel.maximumNumberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingMiddle
        addSubview(titleLabel)

        contentView.font = .systemFont(ofSize: 13)
        addSubview(contentView)

        topSepLayer.backgroundColor = isDarkMode()
            ? NSColor(red: 1, green: 1, blue: 1, alpha: 0.15).cgColor
            : NSColor(red: 0, green: 0, blue: 0, alpha: 0.12).cgColor

        let isGesture = eventHandler.handlerType == .gesture
        var texts: [LookinStringTwoTuple] = []
        if isGesture {
            texts.append(LookinStringTwoTuple(first: "Enabled", second: ""))
            if editable {
                let button = NSButton()
                button.setButtonType(.switch)
                button.title = ""
                button.target = self
                button.action = #selector(handleGestureButton(_:))
                recognizerEnableButton = button
                renderRecognizerEnabledButton()
                contentView.add(button, at: 0)
            } else {
                texts.append(LookinStringTwoTuple(first: "Enabled", second: eventHandler.gestureRecognizerIsEnabled ? "YES" : "NO"))
            }
            texts.append(LookinStringTwoTuple(first: "Delegate", second: eventHandler.gestureRecognizerDelegator ?? "nil"))
            // Gesture recognizer names are long; use a smaller title.
            titleLabel.font = .boldSystemFont(ofSize: 12)
        } else {
            titleLabel.font = .boldSystemFont(ofSize: 13)
        }

        let targetActions = eventHandler.targetActions ?? []
        switch targetActions.count {
        case 0:
            texts.append(LookinStringTwoTuple(first: "Target", second: "nil"))
            texts.append(LookinStringTwoTuple(first: "Action", second: "NULL"))
        case 1:
            texts.append(LookinStringTwoTuple(first: "Target", second: targetActions[0].first))
            texts.append(LookinStringTwoTuple(first: "Action", second: targetActions[0].second))
        default:
            for (index, tuple) in targetActions.enumerated() {
                texts.append(LookinStringTwoTuple(first: "Target \(index + 1)", second: tuple.first))
                texts.append(LookinStringTwoTuple(first: "Action \(index + 1)", second: tuple.second))
            }
        }
        contentView.texts = texts

        titleLabel.stringValue = eventHandler.eventName ?? ""
        if isGesture {
            iconImageView.image = NSImage(named: "icon_gesture_tap")
        } else if eventHandler.eventName?.hasPrefix("UIControlEventEditing") == true {
            iconImageView.image = NSImage(named: "icon_targetaction_edit")
        } else {
            iconImageView.image = NSImage(named: "icon_targetaction_touch")
        }

        if isGesture {
            var lines: [String] = []
            if let inherited = eventHandler.inheritedRecognizerName {
                lines.append("\(NSLocalizedString("Inherits from", comment: "")) \(inherited)")
            }
            lines.append(contentsOf: eventHandler.recognizerIvarTraces ?? [])
            if !lines.isEmpty {
                let label = LKLabel()
                // LKHelper's NSColorGray9 / NSColorGray1.
                label.textColor = isDarkMode()
                    ? NSColor(red: 216 / 255, green: 220 / 255, blue: 228 / 255, alpha: 1).withAlphaComponent(0.5)
                    : NSColor(red: 53 / 255, green: 60 / 255, blue: 70 / 255, alpha: 1).withAlphaComponent(0.6)
                label.stringValue = lines.joined(separator: "\n")
                label.isSelectable = true
                label.font = .systemFont(ofSize: 12)
                label.maximumNumberOfLines = 0
                label.lineBreakMode = .byTruncatingMiddle
                addSubview(label)
                subtitleLabel = label
            }
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("LKHierarchyHandlersPopoverItemView is not loaded from archives")
    }

    override func layout() {
        super.layout()
        LKHierarchyFrameLayout(topSepLayer).x(contentX).toRight(insetRight).y(0).height(1)

        LKHierarchyFrameLayout(titleLabel).x(contentX).toRight(insetRight).heightToFit().y(verInset)

        var y = titleLabel.frame.maxY
        if let subtitleLabel {
            LKHierarchyFrameLayout(subtitleLabel).x(contentX).toRight(insetRight).heightToFit().y(y + subtitleMarginTop)
            y = subtitleLabel.frame.maxY
        }

        LKHierarchyFrameLayout(contentView).x(contentX).toRight(insetRight).heightToFit().y(y + contentMarginTop)
        LKHierarchyFrameLayout(iconImageView).sizeToFit().midX(contentX / 2 + 1).midY(titleLabel.frame.midY)
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        let unlimited = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        let titleSize = titleLabel.sizeThatFits(unlimited)
        let contentSize = contentView.sizeThatFits(unlimited)
        let subtitleSize = subtitleLabel?.sizeThatFits(unlimited) ?? .zero
        var size = limitedSize
        // 2 more points absorb the pixel rounding of the layout.
        size.width = max(titleSize.width, contentSize.width, subtitleSize.width) + contentX + insetRight + 2
        size.height = titleSize.height + contentSize.height + contentMarginTop + verInset * 2
        if subtitleLabel != nil {
            size.height += subtitleMarginTop + subtitleSize.height
        }
        return size
    }

    @objc private func handleGestureButton(_ button: NSButton) {
        // The popover sits on the Live Doc that hosts it, so the app and the
        // alert's window both come from `window`.
        let hostWindow = window
        guard let inspectableApp = LookinLiveDocument.document(in: hostWindow)?.inspectableApp else {
            Self.present(LKConnectionError.noConnect, in: hostWindow)
            renderRecognizerEnabledButton()
            return
        }
        let shouldEnable = button.state == .on
        let oid = UInt(eventHandler.recognizerOid)
        Task { @MainActor [weak self] in
            do {
                let isEnabled = try await inspectableApp.setGestureRecognizer(oid: oid, enabled: shouldEnable)
                guard let self else { return }
                eventHandler.gestureRecognizerIsEnabled = isEnabled
                renderRecognizerEnabledButton()
            } catch {
                Self.present(error as NSError, in: hostWindow)
                self?.renderRecognizerEnabledButton()
            }
        }
    }

    private func renderRecognizerEnabledButton() {
        recognizerEnableButton?.state = eventHandler.gestureRecognizerIsEnabled ? .on : .off
    }

    /// LKHelper's AlertError: a sheet for every error except a discarded
    /// request.
    private static func present(_ error: NSError, in window: NSWindow?) {
        guard error.code != LookinErrCode_Discard, let window else {
            return
        }
        NSAlert(error: error).beginSheetModal(for: window, completionHandler: nil)
    }
}
