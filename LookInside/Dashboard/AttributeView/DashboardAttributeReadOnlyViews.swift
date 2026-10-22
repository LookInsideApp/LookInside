//
//  DashboardAttributeReadOnlyViews.swift
//  LookInside
//
//  Created by Li Kai on 2019/6/12.
//  https://lookin.work
//
//  Attributes that only display or act: table rows per section, shadow,
//  and the "Open Image with Preview" button.
//

import AppKit

/// The number of rows in each section of a table view.
final class DashboardAttributeRowsCountView: DashboardAttributeView {
    private var inputViews: [NumberInputView] = []

    override func layout() {
        super.layout()
        for (idx, view) in inputViews.enumerated() {
            let y = CGFloat(idx) * (DashboardMetrics.numberInputHorizontalHeight + DashboardMetrics.attrItemVerInterspace)
            view.dashboardLayout.fullWidth().height(DashboardMetrics.numberInputHorizontalHeight).y(y)
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        let count = CGFloat(inputViews.count)
        let height = (DashboardMetrics.numberInputHorizontalHeight + DashboardMetrics.attrItemVerInterspace) * count - DashboardMetrics.attrItemVerInterspace
        var size = limitedSize
        size.height = max(height, 0)
        return size
    }

    override func renderWithAttribute() {
        guard let numbers = attribute?.value as? [Any] else {
            assertionFailure()
            return
        }
        while inputViews.count > numbers.count {
            inputViews.removeLast().removeFromSuperview()
        }
        while inputViews.count < numbers.count {
            let view = NumberInputView()
            view.textFieldView.textField.isEditable = false
            view.viewStyle = .horizontal
            view.textFieldView.backgroundColorName = "DashboardCardValueBGColor"
            addSubview(view)
            inputViews.append(view)
        }
        for (idx, view) in inputViews.enumerated() {
            view.title = String(format: NSLocalizedString("Section %lld", comment: ""), idx)
            view.textFieldView.textField.stringValue = "\(numbers[idx])"
        }
        needsLayout = true
    }

    override func dashboardViewControllerDidChange() {
        for view in inputViews {
            view.textFieldView.backgroundColorName = "DashboardCardValueBGColor"
        }
    }
}

/// A layer shadow: colour, then opacity, radius and offset.
final class DashboardAttributeShadowView: DashboardAttributeView {
    private let colorContainerView = BaseView()
    private let colorIndicatorLayer = ColorIndicatorLayer()
    private let colorDescLabel = TextLabel()
    private var inputViews: [NumberInputView] = []
    private var rgbaFormatObservation: NSKeyValueObservation?

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        colorContainerView.layer?.cornerRadius = DashboardMetrics.cardControlCornerRadius
        colorContainerView.backgroundColorName = "DashboardCardValueBGColor"
        addSubview(colorContainerView)

        colorContainerView.layer?.addSublayer(colorIndicatorLayer)

        colorDescLabel.textColor = NSColor(named: "DashboardCardValueColor")
        colorDescLabel.font = DashboardStyle.font(13)
        colorContainerView.addSubview(colorDescLabel)

        inputViews = ["Opacity", "Radius", "OffsetW", "OffsetH"].map { title in
            let view = NumberInputView()
            view.textFieldView.textField.isEditable = false
            view.title = title
            view.viewStyle = .vertical
            addSubview(view)
            return view
        }

        // Re-render when the user switches between hex and RGBA.
        rgbaFormatObservation = PreferenceManager.shared.observe(\.rgbaFormat, options: [.new]) { [weak self] _, _ in
            runOnMain { self?.renderWithAttribute() }
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        colorContainerView.dashboardLayout.fullWidth().height(30).y(0)
        colorIndicatorLayer.dashboardLayout.width(16).height(16).x(8).verAlign()
        colorDescLabel.dashboardLayout.x(28).toRight(20).heightToFit().verAlign().offsetY(-1)

        let horSpace = DashboardMetrics.attrItemHorInterspace
        let itemWidth = (frame.width - horSpace * 3) / 4.0
        let y = colorContainerView.frame.maxY + DashboardMetrics.attrItemVerInterspace
        var x: CGFloat = 0
        for view in inputViews {
            view.dashboardLayout.width(itemWidth).height(DashboardMetrics.numberInputVerticalHeight).x(x).y(y)
            x += itemWidth + horSpace
        }
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        size.height = 30 + DashboardMetrics.attrItemVerInterspace + DashboardMetrics.numberInputVerticalHeight
        return size
    }

    override func renderWithAttribute() {
        guard let info = attribute?.value as? [String: Any],
              let offsetValue = info["offset"] as? NSValue,
              let opacityNumber = info["opacity"] as? NSNumber,
              let radiusNumber = info["radius"] as? NSNumber
        else {
            assertionFailure()
            return
        }
        // The colour may be nil.
        let color = NSColor.sRGBColor(fromRGBAComponents: info["color"] as? [NSNumber])
        let offset = offsetValue.sizeValue

        colorIndicatorLayer.color = color
        if let color {
            colorDescLabel.stringValue = PreferenceManager.shared.rgbaFormat ? color.rgbaString() : color.hexString()
        } else {
            colorDescLabel.stringValue = "nil"
        }

        let strings = [opacityNumber.doubleValue, radiusNumber.doubleValue, Double(offset.width), Double(offset.height)].map {
            NSString.string(from: $0, decimal: 2)
        }
        for (view, string) in zip(inputViews, strings) {
            view.textFieldView.textField.stringValue = string
        }
    }
}

/// Opens the image of an image view in Preview, fetched from the app (or
/// taken from an imported Xcode capture).
final class DashboardAttributeOpenImageView: DashboardAttributeView {
    private let control = TextControl()

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        layer?.borderWidth = 1
        layer?.cornerRadius = DashboardMetrics.cardControlCornerRadius
        borderColors = TwoColors(colorInLightMode: DashboardStyle.rgb(181, 181, 181), colorInDarkMode: DashboardStyle.rgb(83, 83, 83))

        control.adjustAlphaWhenClick = true
        control.label.stringValue = NSLocalizedString("Open Image with Preview…", comment: "")
        control.label.font = DashboardStyle.font(11)
        control.addTarget(self, clickAction: #selector(handleClick))
        addSubview(control)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        control.dashboardLayout.fullFrame()
    }

    override func sizeThatFits(_ limitedSize: NSSize) -> NSSize {
        var size = limitedSize
        size.height = DashboardMetrics.numberInputHorizontalHeight
        return size
    }

    @objc private func handleClick() {
        // An imported Xcode capture carries the image's own bytes: there is
        // no process to fetch them from, and none is needed.
        if let imageData = attribute?.value as? Data {
            openImageData(imageData)
            return
        }

        guard let imageViewOid = (attribute?.value as? NSNumber)?.uintValue else {
            DashboardStyle.alert(ConnectionError.inner, window: window)
            assertionFailure()
            return
        }

        guard dashboardViewController?.isStaticMode == true else {
            DashboardStyle.alert(
                title: NSLocalizedString("The feature is not available in current mode.", comment: ""),
                detail: NSLocalizedString("You must connect LookInside with target iOS app before using this feature.", comment: ""),
                window: window
            )
            return
        }

        // The inspectable app of the document that owns this view's window.
        guard let inspectableApp = LiveDocument.document(in: window)?.inspectableApp else {
            DashboardStyle.alert(ConnectionError.noConnect, window: window)
            return
        }

        Task { @MainActor [weak self] in
            do {
                let imageData = try await inspectableApp.image(imageViewOid: imageViewOid)
                guard let self else { return }
                guard let imageData else {
                    DashboardStyle.alert(
                        title: NSLocalizedString("Operation failed. The image property value of selected UIImageView is nil.", comment: ""),
                        detail: "",
                        window: self.window
                    )
                    return
                }
                self.openImageData(imageData)
            } catch {
                DashboardStyle.alert(error, window: self?.window)
            }
        }
    }

    /// Writes the encoded image to a temporary file and opens it with
    /// Preview. The file is deleted when LookInside quits.
    private func openImageData(_ imageData: Data) {
        let fileName = String(format: "%.0f", Date().timeIntervalSince1970)
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("LookInside_UIImageView_\(fileName).png")
        do {
            try imageData.write(to: URL(fileURLWithPath: filePath))
        } catch {
            assertionFailure()
            DashboardStyle.alert(error, window: window)
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: filePath))

        AppHelper.sharedInstance().tempImageFiles.append(filePath)
    }
}
