//
//  DashboardSearchViews.swift
//  LookInside
//
//  Created by Li Kai on 2019/9/5.
//  https://lookin.work
//
//  The search results that replace the cards while searching: one card per
//  matching attribute, and a card of matching methods to invoke.
//

import AppKit

/// A search result card on a blurred background.
class DashboardSearchCardView: BaseView {
    private let backgroundEffectView = VisualEffectView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.cornerRadius = DashboardMetrics.cardCornerRadius
        backgroundEffectView.blendingMode = .withinWindow
        backgroundEffectView.state = .active
        addSubview(backgroundEffectView)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        backgroundEffectView.dashboardLayout.fullFrame()
    }
}

protocol DashboardSearchPropertyViewDelegate: AnyObject {
    func dashboardSearchPropView(_ view: DashboardSearchPropertyView, didClickRevealAttribute attribute: InspectedAttribute)
}

/// One matching attribute: its title, its value as text, and a button that
/// reveals it on its card.
final class DashboardSearchPropertyView: DashboardSearchCardView {
    private let contentLabelY: CGFloat = 21

    private let titleLabel = TextLabel()
    private let contentLabel = TextLabel()
    private let revealControl = TextControl()
    private var attribute: InspectedAttribute?

    weak var delegate: DashboardSearchPropertyViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        titleLabel.font = DashboardStyle.font(12)
        titleLabel.textColor = .secondaryLabelColor
        addSubview(titleLabel)

        contentLabel.font = DashboardStyle.font(15)
        addSubview(contentLabel)

        revealControl.addTarget(self, clickAction: #selector(handleRevealButton))
        revealControl.adjustAlphaWhenClick = true
        addSubview(revealControl)

        updateColors()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        let inset = DashboardMetrics.searchCardInset
        let width = frame.width - inset * 2
        titleLabel.dashboardLayout.x(inset).width(width).heightToFit().y(5)
        contentLabel.dashboardLayout.x(inset).width(width).heightToFit().y(contentLabelY)
        revealControl.dashboardLayout.sizeToFit().x(inset).bottom(inset)
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        let inset = DashboardMetrics.searchCardInset
        let width = limitedSize.width - inset * 2
        var size = limitedSize
        size.height = contentLabelY + contentLabel.height(forWidth: width) + inset + 25
        return size
    }

    override func updateColors() {
        super.updateColors()
        let isDarkMode = isDarkMode()
        contentLabel.textColor = isDarkMode ? DashboardStyle.rgb(250, 251, 252) : DashboardStyle.rgb(56, 57, 58)

        let text = DashboardText.attributed(
            NSLocalizedString("Reveal in panel…", comment: ""),
            font: DashboardStyle.font(11),
            color: isDarkMode ? DashboardStyle.rgb(245, 166, 30) : DashboardStyle.rgb(229, 135, 67)
        )
        DashboardText.appendImage(named: "icon_arrowRight_orange", baselineOffset: 0, marginLeft: 2, marginRight: 0, to: text)
        revealControl.label.attributedStringValue = text
    }

    func render(attribute: InspectedAttribute) {
        self.attribute = attribute
        titleLabel.stringValue = attribute.displayTitle ?? DashboardBlueprint.fullTitle(withAttrID: attribute.identifier) ?? ""
        contentLabel.stringValue = Self.stringValue(of: attribute)
        needsLayout = true
    }

    @objc private func handleRevealButton() {
        guard let attribute else { return }
        delegate?.dashboardSearchPropView(self, didClickRevealAttribute: attribute)
    }

    /// The attribute's value as one line of text.
    static func stringValue(of attribute: InspectedAttribute) -> String {
        switch attribute.attrType {
        case .none, .void, .customObj:
            assertionFailure()
            return ""

        case .char, .int, .short, .long, .longLong, .unsignedChar, .unsignedInt, .unsignedShort, .unsignedLong, .unsignedLongLong,
             .float, .double, .sel, .class, .cgVector, .cgAffineTransform, .uiOffset:
            return (attribute.value as? NSObject)?.description ?? ""

        case .BOOL:
            return (attribute.value as? NSNumber)?.boolValue == true ? "YES" : "NO"

        case .cgPoint:
            return NSString.string(from: (attribute.value as? NSValue)?.pointValue ?? .zero)

        case .cgSize:
            return NSString.string(from: (attribute.value as? NSValue)?.sizeValue ?? .zero)

        case .cgRect:
            return NSString.string(from: (attribute.value as? NSValue)?.rectValue ?? .zero)

        case .uiEdgeInsets:
            return NSString.string(fromInset: (attribute.value as? NSValue)?.edgeInsetsValue ?? NSEdgeInsetsZero)

        case .nsString, .enumString:
            return attribute.value as? String ?? ""

        case .enumInt, .enumLong:
            let enumValue = (attribute.value as? NSNumber)?.intValue ?? 0
            let enumListName = DashboardBlueprint.enumListName(withAttrID: attribute.identifier)
            return EnumListRegistry.shared.desc(forEnumName: enumListName, value: enumValue) ?? ""

        case .uiColor:
            guard let color = NSColor.sRGBColor(fromRGBAComponents: attribute.value as? [NSNumber]) else {
                return "nil"
            }
            return PreferenceManager.shared.rgbaFormat ? color.rgbaString() : color.hexString()

        case .shadow, .json:
            return "……"

        @unknown default:
            assertionFailure()
            return ""
        }
    }
}

protocol DashboardSearchMethodsViewDelegate: AnyObject {
    func dashboardSearchMethodsView(_ view: DashboardSearchMethodsView, requestToInvokeMethod method: String, oid: UInt)
}

/// The methods without arguments that match the search; a click invokes
/// one.
final class DashboardSearchMethodsView: DashboardSearchCardView {
    private let insetTop: CGFloat = 5
    private let contentMarginTop: CGFloat = 10
    private let itemInterspace: CGFloat = 8

    private let titleLabel = TextLabel()
    private var errorLabel: TextLabel?
    private var itemViews: [TextControl] = []
    private var methodNames: [ObjectIdentifier: String] = [:]
    private var oid: UInt = 0

    weak var delegate: DashboardSearchMethodsViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        titleLabel.font = DashboardStyle.font(12)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.stringValue = NSLocalizedString("Click to invoke methods below and get the return value.", comment: "")
        addSubview(titleLabel)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        let inset = DashboardMetrics.searchCardInset
        let width = frame.width - inset * 2
        if titleLabel.isVisible {
            titleLabel.dashboardLayout.x(inset).width(width).heightToFit().y(insetTop)
            var y = titleLabel.frame.maxY + contentMarginTop
            for view in itemViews where !view.isHidden {
                let size = view.sizeThatFits(NSSize(width: width, height: .greatestFiniteMagnitude))
                view.dashboardLayout.size(size).x(inset).y(y)
                y = view.frame.maxY + itemInterspace
            }
        } else if let errorLabel, errorLabel.isVisible {
            errorLabel.dashboardLayout.x(inset).width(width).heightToFit().y(insetTop)
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        let contentWidth = limitedSize.width - DashboardMetrics.searchCardInset * 2
        var size = limitedSize
        if titleLabel.isVisible {
            var height = titleLabel.height(forWidth: contentWidth) + insetTop + contentMarginTop
            // Hidden items count too, as they always have.
            for view in itemViews {
                height += view.height(forWidth: contentWidth) + itemInterspace
            }
            size.height = height
        } else {
            size.height = (errorLabel?.height(forWidth: contentWidth) ?? 0) + insetTop * 2
        }
        return size
    }

    func render(methods: [String], oid: UInt) {
        self.oid = oid
        titleLabel.isHidden = false
        errorLabel?.isHidden = true

        while itemViews.count < methods.count {
            let control = TextControl()
            control.label.alignment = .left
            control.label.maximumNumberOfLines = 0
            control.adjustAlphaWhenClick = true
            control.addTarget(self, clickAction: #selector(handleMethodControl(_:)))
            addSubview(control)
            itemViews.append(control)
        }
        for (idx, view) in itemViews.enumerated() {
            guard idx < methods.count else {
                view.isHidden = true
                continue
            }
            view.isHidden = false
            methodNames[ObjectIdentifier(view)] = methods[idx]
            let text = DashboardText.attributed(methods[idx], font: DashboardStyle.font(13), color: DashboardStyle.rgb(74, 144, 226))
            DashboardText.appendImage(named: "icon_arrowRight_blue", baselineOffset: -1, marginLeft: 2, marginRight: 0, to: text)
            view.label.attributedStringValue = text
            view.needsLayout = true
        }
        needsLayout = true
    }

    func render(error: Error) {
        NSLog("%@", String(describing: error))
        itemViews.forEach { $0.isHidden = true }
        titleLabel.isHidden = true
        let label: TextLabel
        if let errorLabel {
            label = errorLabel
        } else {
            label = TextLabel()
            label.textColor = .labelColor
            label.font = DashboardStyle.font(12)
            addSubview(label)
            errorLabel = label
        }
        label.isHidden = false
        label.stringValue = NSLocalizedString("Failed to search related methods: ", comment: "") + error.localizedDescription
        needsLayout = true
    }

    @objc private func handleMethodControl(_ control: NSControl) {
        guard let methodName = methodNames[ObjectIdentifier(control)], !methodName.isEmpty else {
            assertionFailure()
            return
        }
        delegate?.dashboardSearchMethodsView(self, requestToInvokeMethod: methodName, oid: oid)
    }
}

/// The selectors without arguments of each class, fetched once per class
/// until the hierarchy reloads.
final class DashboardSearchMethodsDataSource {
    /// The live document whose app answers; nil for a document read from a
    /// file.
    weak var liveDocument: LiveDocument?

    /// Class name to selector names.
    private var classesToSelectors: [String: [String]] = [:]

    @MainActor
    func nonArgMethods(ofClass className: String?) async throws -> [String] {
        guard let className, !className.isEmpty else {
            throw ConnectionError.inner
        }
        guard let inspectableApp = liveDocument?.inspectableApp else {
            throw ConnectionError.noConnect
        }
        if let cached = classesToSelectors[className] {
            return cached
        }
        let selectors = try await inspectableApp.selectorNames(className: className, hasArg: false)
        classesToSelectors[className] = selectors
        return selectors
    }

    func clearAllCache() {
        classesToSelectors.removeAll()
    }
}
