//
//  LKDashboardAttributePrivateDiscriminatorView.swift
//  LookInside
//
//  The Swift private-discriminator card: the hash ID, and its module and
//  file name, matched from the imported indexes or typed in, imported from
//  a codebase, or guessed by swift-pd-guess.
//

import AppKit

private enum LKPrivateDiscriminatorMetrics {
    static let rowTitleWidth: CGFloat = 64
    static let cardPaddingLeft: CGFloat = 8
    static let cardPaddingRight: CGFloat = 4
    static let cardInnerSpacing: CGFloat = 6
    static let cardVerticalPadding: CGFloat = 4
    static let copySize: CGFloat = 20
    static let rowMinHeight: CGFloat = 24
    static let buttonHeight: CGFloat = 24
}

/// A value that copies itself when clicked.
private final class LKPrivateDiscriminatorCopyLabel: LKLabel {
    var fieldName: String?
    var onCopy: ((LKPrivateDiscriminatorCopyLabel) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        font = LKDashboardStyle.font(12)
        textColor = NSColor(named: "DashboardCardValueColor")
        lineBreakMode = .byCharWrapping
        maximumNumberOfLines = 0
        toolTip = NSLocalizedString("Click to copy", comment: "")
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func mouseDown(with event: NSEvent) {
        if stringValue.isEmpty {
            super.mouseDown(with: event)
            return
        }
        onCopy?(self)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

@objc(LKDashboardAttributePrivateDiscriminatorView)
final class LKDashboardAttributePrivateDiscriminatorView: LKDashboardAttributeView {
    private typealias Metrics = LKPrivateDiscriminatorMetrics

    private static let dashboardStateDidChangeNotification = Notification.Name("LKPrivateDiscriminatorDashboardStateDidChange")

    private let idCard = LKBaseView()
    private let idTitleLabel = LKLabel()
    private let idValueLabel = LKPrivateDiscriminatorCopyLabel()
    private var idCopyButton: NSButton!

    private let moduleCard = LKBaseView()
    private let moduleTitleLabel = LKLabel()
    private let moduleField = NSTextField()
    private let moduleValueLabel = LKPrivateDiscriminatorCopyLabel()
    private var moduleCopyButton: NSButton!

    private let filenameCard = LKBaseView()
    private let filenameTitleLabel = LKLabel()
    private let filenameField = NSTextField()
    private let filenameValueLabel = LKPrivateDiscriminatorCopyLabel()
    private var filenameCopyButton: NSButton!

    private let sourceLabel = LKLabel()
    private let messageLabel = LKLabel()

    private var importButton: NSButton!
    private var guessButton: NSButton!
    private var cancelButton: NSButton!

    private let toastView = LKBaseView()
    private let toastLabel = LKLabel()
    private var hideToastWorkItem: DispatchWorkItem?

    private var payload: LKPrivateDiscriminatorDashboardPayload?
    private var localMessage: String?
    private var localMessageIsError = false
    private var stateObserver: NSObjectProtocol?

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setUpCard(idCard, titleLabel: idTitleLabel, title: NSLocalizedString("ID", comment: ""))
        setUpCopyLabel(idValueLabel, name: NSLocalizedString("ID", comment: ""))
        idValueLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        idCopyButton = makeCopyButton()
        idCard.addSubview(idTitleLabel)
        idCard.addSubview(idValueLabel)
        idCard.addSubview(idCopyButton)

        setUpCard(moduleCard, titleLabel: moduleTitleLabel, title: NSLocalizedString("Module", comment: ""))
        setUpTextField(moduleField, placeholder: NSLocalizedString("ModuleName", comment: ""))
        setUpCopyLabel(moduleValueLabel, name: NSLocalizedString("Module", comment: ""))
        moduleCopyButton = makeCopyButton()
        moduleCard.addSubview(moduleTitleLabel)
        moduleCard.addSubview(moduleField)
        moduleCard.addSubview(moduleValueLabel)
        moduleCard.addSubview(moduleCopyButton)

        setUpCard(filenameCard, titleLabel: filenameTitleLabel, title: NSLocalizedString("Filename", comment: ""))
        setUpTextField(filenameField, placeholder: NSLocalizedString("File.swift", comment: ""))
        setUpCopyLabel(filenameValueLabel, name: NSLocalizedString("Filename", comment: ""))
        filenameCopyButton = makeCopyButton()
        filenameCard.addSubview(filenameTitleLabel)
        filenameCard.addSubview(filenameField)
        filenameCard.addSubview(filenameValueLabel)
        filenameCard.addSubview(filenameCopyButton)

        sourceLabel.font = LKDashboardStyle.font(11)
        sourceLabel.textColor = NSColor(named: "DashboardInputAccessoryColor")
        sourceLabel.maximumNumberOfLines = 0
        sourceLabel.lineBreakMode = .byWordWrapping

        messageLabel.font = LKDashboardStyle.font(11)
        messageLabel.maximumNumberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping

        importButton = NSButton.lk_normalButton(withTitle: NSLocalizedString("Import from your codebase", comment: ""), target: self, action: #selector(handleImportButton(_:)))
        importButton.font = LKDashboardStyle.font(12)

        guessButton = NSButton.lk_normalButton(withTitle: NSLocalizedString("Guess by swift-pd-guess", comment: ""), target: self, action: #selector(handleGuessButton(_:)))
        guessButton.font = LKDashboardStyle.font(12)

        cancelButton = NSButton.lk_normalButton(withTitle: NSLocalizedString("Cancel", comment: ""), target: self, action: #selector(handleCancelButton(_:)))
        cancelButton.font = LKDashboardStyle.font(12)

        toastView.layer?.cornerRadius = LKDashboardMetrics.cardControlCornerRadius
        toastView.isHidden = true
        toastView.alphaValue = 0

        toastLabel.stringValue = NSLocalizedString("Copied", comment: "")
        toastLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        toastLabel.textColor = .white
        toastLabel.alignment = .center
        toastView.addSubview(toastLabel)

        let subviews: [NSView] = [
            idCard,
            moduleCard,
            filenameCard,
            sourceLabel,
            messageLabel,
            importButton,
            guessButton,
            cancelButton,
            toastView,
        ]
        subviews.forEach(addSubview)

        updateColors()

        stateObserver = NotificationCenter.default.addObserver(forName: Self.dashboardStateDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            lkRunOnMain { self?.dashboardViewController?.reloadCurrentDisplayItem() }
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        if let stateObserver {
            NotificationCenter.default.removeObserver(stateObserver)
        }
    }

    override func renderWithAttribute() {
        super.renderWithAttribute()

        payload = attribute?.value as? LKPrivateDiscriminatorDashboardPayload

        idValueLabel.stringValue = payload?.discriminatorID ?? ""
        moduleField.stringValue = payload?.module ?? ""
        filenameField.stringValue = payload?.filename ?? ""
        moduleValueLabel.stringValue = payload?.module ?? ""
        filenameValueLabel.stringValue = payload?.filename ?? ""

        let isMatched = payload?.isMatched ?? false
        let isGuessRunning = payload?.isGuessRunning ?? false
        let canEdit = payload != nil && !isMatched && !isGuessRunning
        for field in [moduleField, filenameField] {
            field.isEditable = canEdit
            field.isEnabled = canEdit
            field.isHidden = !canEdit
        }
        moduleValueLabel.isHidden = canEdit
        filenameValueLabel.isHidden = canEdit
        idCopyButton.isHidden = idValueLabel.stringValue.isEmpty
        moduleCopyButton.isHidden = canEdit || moduleValueLabel.stringValue.isEmpty
        filenameCopyButton.isHidden = canEdit || filenameValueLabel.stringValue.isEmpty

        importButton.isHidden = isMatched || isGuessRunning
        guessButton.isHidden = isMatched || isGuessRunning
        cancelButton.isHidden = !isGuessRunning

        if let payload, isMatched {
            let source = payload.source.isEmpty ? "matched" : payload.source
            let format = payload.isVerified ? NSLocalizedString("Verified from %@.", comment: "") : NSLocalizedString("Matched from %@.", comment: "")
            sourceLabel.stringValue = String(format: format, source)
            sourceLabel.isHidden = false
        } else {
            sourceLabel.stringValue = ""
            sourceLabel.isHidden = true
        }

        renderMessage()
        needsLayout = true
    }

    // MARK: - Layout

    private func valueWidth(forCardWidth cardWidth: CGFloat, copyHidden: Bool) -> CGFloat {
        var width = cardWidth - Metrics.cardPaddingLeft - Metrics.rowTitleWidth - Metrics.cardInnerSpacing
        if copyHidden {
            width -= Metrics.cardPaddingLeft
        } else {
            width -= Metrics.copySize + Metrics.cardInnerSpacing + Metrics.cardPaddingRight
        }
        return max(width, 1)
    }

    private func cardHeight(for label: LKPrivateDiscriminatorCopyLabel, cardWidth: CGFloat, copyHidden: Bool) -> CGFloat {
        let width = valueWidth(forCardWidth: cardWidth, copyHidden: copyHidden)
        let valueHeight = max(18, label.sizeThatFits(NSSize(width: width, height: .greatestFiniteMagnitude)).height)
        return max(valueHeight + Metrics.cardVerticalPadding * 2, Metrics.rowMinHeight)
    }

    private func moduleCardHeight(forCardWidth cardWidth: CGFloat) -> CGFloat {
        if moduleField.isHidden {
            return cardHeight(for: moduleValueLabel, cardWidth: cardWidth, copyHidden: moduleCopyButton.isHidden)
        }
        return Metrics.rowMinHeight
    }

    private func filenameCardHeight(forCardWidth cardWidth: CGFloat) -> CGFloat {
        if filenameField.isHidden {
            return cardHeight(for: filenameValueLabel, cardWidth: cardWidth, copyHidden: filenameCopyButton.isHidden)
        }
        return Metrics.rowMinHeight
    }

    override func layout() {
        super.layout()

        let width = max(frame.width, 1)
        let verSpacing = LKDashboardMetrics.attrItemVerInterspace
        var y: CGFloat = 0

        let idHeight = cardHeight(for: idValueLabel, cardWidth: width, copyHidden: idCopyButton.isHidden)
        idCard.dashboardLayout.x(0).y(y).width(width).height(idHeight)
        layoutCard(idCard, titleLabel: idTitleLabel, field: nil, valueLabel: idValueLabel, copyButton: idCopyButton)
        y += idHeight + verSpacing

        let moduleHeight = moduleCardHeight(forCardWidth: width)
        moduleCard.dashboardLayout.x(0).y(y).width(width).height(moduleHeight)
        layoutCard(moduleCard, titleLabel: moduleTitleLabel, field: moduleField, valueLabel: moduleValueLabel, copyButton: moduleCopyButton)
        y += moduleHeight + verSpacing

        let filenameHeight = filenameCardHeight(forCardWidth: width)
        filenameCard.dashboardLayout.x(0).y(y).width(width).height(filenameHeight)
        layoutCard(filenameCard, titleLabel: filenameTitleLabel, field: filenameField, valueLabel: filenameValueLabel, copyButton: filenameCopyButton)
        y += filenameHeight + verSpacing

        let sideTextWidth = max(width - Metrics.cardPaddingLeft * 2, 1)
        if !sourceLabel.isHidden {
            sourceLabel.dashboardLayout.x(Metrics.cardPaddingLeft).y(y).width(sideTextWidth).heightToFit()
            y = sourceLabel.frame.maxY + verSpacing
        }
        if !messageLabel.isHidden {
            messageLabel.dashboardLayout.x(Metrics.cardPaddingLeft).y(y).width(sideTextWidth).heightToFit()
            y = messageLabel.frame.maxY + verSpacing
        }
        if !importButton.isHidden {
            importButton.dashboardLayout.x(0).y(y).width(width).height(Metrics.buttonHeight)
            y = importButton.frame.maxY + 6
        }
        if !guessButton.isHidden {
            guessButton.dashboardLayout.x(0).y(y).width(width).height(Metrics.buttonHeight)
            y = guessButton.frame.maxY + 2
        }
        if !cancelButton.isHidden {
            cancelButton.dashboardLayout.x(0).y(y).width(86).height(Metrics.buttonHeight)
        }
        if !toastView.isHidden {
            toastLabel.dashboardLayout.x(8).toRight(8).heightToFit().verAlign()
        }
    }

    private func layoutCard(_ card: LKBaseView, titleLabel: LKLabel, field: NSTextField?, valueLabel: LKPrivateDiscriminatorCopyLabel, copyButton: NSButton) {
        let cardWidth = card.frame.width
        let cardHeight = card.frame.height
        let fieldVisible = field.map { !$0.isHidden } ?? false
        let copyVisible = !copyButton.isHidden

        let titleHeight = max(14, titleLabel.sizeThatFits(NSSize(width: Metrics.rowTitleWidth, height: .greatestFiniteMagnitude)).height)
        titleLabel.dashboardLayout.x(Metrics.cardPaddingLeft).y(max(0, (cardHeight - titleHeight) / 2.0)).width(Metrics.rowTitleWidth).height(titleHeight)

        let contentX = Metrics.cardPaddingLeft + Metrics.rowTitleWidth + Metrics.cardInnerSpacing
        let contentRightX = copyVisible
            ? cardWidth - Metrics.cardPaddingRight - Metrics.copySize - Metrics.cardInnerSpacing
            : cardWidth - Metrics.cardPaddingLeft
        let contentWidth = max(contentRightX - contentX, 1)

        if let field, fieldVisible {
            valueLabel.isHidden = true
            let fieldHeight = max(18, field.intrinsicContentSize.height)
            field.dashboardLayout.x(contentX - 3).y(max(0, (cardHeight - fieldHeight) / 2.0)).width(contentWidth + 6).height(fieldHeight)
        } else {
            // A hidden field stays hidden; renderWithAttribute decides.
            let valueHeight = max(18, valueLabel.sizeThatFits(NSSize(width: contentWidth, height: .greatestFiniteMagnitude)).height)
            valueLabel.dashboardLayout.x(contentX).y(max(0, (cardHeight - valueHeight) / 2.0)).width(contentWidth).height(valueHeight)
        }

        if copyVisible {
            let copyY = max(0, (cardHeight - Metrics.copySize) / 2.0)
            copyButton.dashboardLayout.x(cardWidth - Metrics.cardPaddingRight - Metrics.copySize).y(copyY).width(Metrics.copySize).height(Metrics.copySize)
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        let width = max(limitedSize.width, 1)
        let verSpacing = LKDashboardMetrics.attrItemVerInterspace

        var height: CGFloat = 0
        height += cardHeight(for: idValueLabel, cardWidth: width, copyHidden: idCopyButton.isHidden)
        height += verSpacing
        height += moduleCardHeight(forCardWidth: width)
        height += verSpacing
        height += filenameCardHeight(forCardWidth: width)

        let sideTextWidth = max(width - Metrics.cardPaddingLeft * 2, 1)
        if !sourceLabel.isHidden {
            height += verSpacing
            height += sourceLabel.sizeThatFits(NSSize(width: sideTextWidth, height: .greatestFiniteMagnitude)).height
        }
        if !messageLabel.isHidden {
            height += verSpacing
            height += messageLabel.sizeThatFits(NSSize(width: sideTextWidth, height: .greatestFiniteMagnitude)).height
        }
        if !importButton.isHidden {
            height += verSpacing
            height += Metrics.buttonHeight
        }
        if !guessButton.isHidden {
            height += importButton.isHidden ? verSpacing : 6
            height += Metrics.buttonHeight
        }
        if !cancelButton.isHidden {
            height += (importButton.isHidden && guessButton.isHidden) ? verSpacing : 2
            height += Metrics.buttonHeight
        }

        var size = limitedSize
        size.height = height
        return size
    }

    override func numberOfColumnsOccupied() -> Int {
        1
    }

    // MARK: - Actions

    @objc private func submitManualValue(_: Any?) {
        guard let payload, !payload.isMatched, let item = attribute?.targetDisplayItem else { return }
        var error: NSError?
        let saved = LKPrivateDiscriminatorStore.shared.submitPrivateDiscriminator(for: item, module: moduleField.stringValue, filename: filenameField.stringValue, error: &error)
        if saved {
            localMessage = NSLocalizedString("Saved.", comment: "")
            localMessageIsError = false
            dashboardViewController?.reloadCurrentDisplayItem()
        } else {
            localMessage = error?.localizedDescription ?? NSLocalizedString("Verification failed.", comment: "")
            localMessageIsError = true
            renderMessage()
            window?.makeFirstResponder(nil)
            needsLayout = true
        }
    }

    @objc private func handleImportButton(_: NSButton) {
        guard let item = attribute?.targetDisplayItem else { return }
        var error: NSError?
        let imported = LKPrivateDiscriminatorStore.shared.importPrivateDiscriminatorFromCodebase(for: item, window: window, error: &error)
        if imported {
            localMessage = nil
            dashboardViewController?.reloadCurrentDisplayItem()
        } else if let error {
            localMessage = error.localizedDescription
            localMessageIsError = true
            renderMessage()
            needsLayout = true
        }
    }

    @objc private func handleGuessButton(_: NSButton) {
        guard let item = attribute?.targetDisplayItem else { return }
        LKPrivateDiscriminatorStore.shared.beginSwiftPDGuess(for: item, window: window)
        dashboardViewController?.reloadCurrentDisplayItem()
    }

    @objc private func handleCancelButton(_: NSButton) {
        guard let item = attribute?.targetDisplayItem else { return }
        LKPrivateDiscriminatorStore.shared.cancelSwiftPDGuess(for: item)
    }

    @objc private func handleCopyButton(_ button: NSButton) {
        if button === idCopyButton {
            copy(idValueLabel.stringValue, sourceView: button)
        } else if button === moduleCopyButton {
            copy(moduleValueLabel.stringValue, sourceView: button)
        } else if button === filenameCopyButton {
            copy(filenameValueLabel.stringValue, sourceView: button)
        }
    }

    private func hideCopyToast() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            self.toastView.animator().alphaValue = 0
        } completionHandler: {
            self.toastView.isHidden = true
        }
    }

    // MARK: - Views

    private func setUpCard(_ card: LKBaseView, titleLabel: LKLabel, title: String) {
        card.layer?.cornerRadius = LKDashboardMetrics.cardControlCornerRadius
        card.backgroundColorName = "DashboardCardValueBGColor"
        titleLabel.stringValue = title
        titleLabel.font = LKDashboardStyle.font(11)
        titleLabel.textColor = NSColor(named: "DashboardInputAccessoryColor")
    }

    private func setUpCopyLabel(_ label: LKPrivateDiscriminatorCopyLabel, name: String) {
        label.fieldName = name
        label.onCopy = { [weak self] label in
            self?.copy(label.stringValue, sourceView: label)
        }
    }

    private func makeCopyButton() -> NSButton {
        let image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: NSLocalizedString("Copy", comment: ""))
        let button = NSButton.lk_button(with: image ?? NSImage(), target: self, action: #selector(handleCopyButton(_:)))
        button.imagePosition = .imageOnly
        button.toolTip = NSLocalizedString("Copy", comment: "")
        image?.isTemplate = true
        return button
    }

    private func setUpTextField(_ field: NSTextField, placeholder: String) {
        field.placeholderString = placeholder
        field.font = LKDashboardStyle.font(12)
        field.isBezeled = false
        field.drawsBackground = false
        field.textColor = NSColor(named: "DashboardCardValueColor")
        field.focusRingType = .none
        field.target = self
        field.action = #selector(submitManualValue(_:))
    }

    private func copy(_ value: String, sourceView: NSView) {
        guard !value.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        showCopyToast(near: sourceView)
    }

    private func showCopyToast(near sourceView: NSView) {
        toastLabel.stringValue = NSLocalizedString("Copied", comment: "")
        toastLabel.sizeToFit()

        let toastWidth = ceil(toastLabel.frame.width) + 18
        let toastHeight: CGFloat = 22
        let sourceFrame = sourceView.convert(sourceView.bounds, to: self)
        var toastX = sourceFrame.midX - toastWidth / 2.0
        toastX = min(max(toastX, 6), max(frame.width - toastWidth - 6, 6))
        var toastY = sourceFrame.minY - toastHeight - 4
        if toastY < 4 {
            toastY = sourceFrame.maxY + 4
        }

        toastView.dashboardLayout.x(toastX).y(toastY).width(toastWidth).height(toastHeight)
        toastLabel.dashboardLayout.x(8).toRight(8).heightToFit().verAlign()
        toastView.isHidden = false
        toastView.alphaValue = 1

        hideToastWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hideCopyToast()
        }
        hideToastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    override func updateColors() {
        super.updateColors()
        let isDarkMode = isDarkMode()
        let iconColor: NSColor = isDarkMode ? .secondaryLabelColor : .tertiaryLabelColor
        idCopyButton?.contentTintColor = iconColor
        moduleCopyButton?.contentTintColor = iconColor
        filenameCopyButton?.contentTintColor = iconColor
        toastView.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(isDarkMode ? 0.9 : 0.85)
    }

    private func renderMessage() {
        var message = localMessage
        var isError = localMessageIsError

        if let warningText = payload?.warningText, !warningText.isEmpty {
            message = warningText
            isError = true
        } else if let guessStatusText = payload?.guessStatusText, !guessStatusText.isEmpty {
            message = guessStatusText
            isError = payload?.isGuessFailed ?? false
        }

        messageLabel.stringValue = message ?? ""
        messageLabel.textColor = isError ? .systemRed : NSColor(named: "DashboardInputAccessoryColor")
        messageLabel.isHidden = (message ?? "").isEmpty
    }
}
