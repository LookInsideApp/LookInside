//
//  DashboardLayout.swift
//  LookInside
//
//  Frame arithmetic for the Dashboard's hand-laid-out views.
//
//  The Dashboard lays its views out by hand. These helpers reproduce the
//  frame rules the Objective-C code used, so the cards keep their exact
//  geometry:
//
//  - position and size setters round up to the main screen's pixel grid;
//  - `sizeToFit()` / `heightToFit()` only measure `BaseView` and
//    `NSControl` (through `sizeThatFits(_:)`), do not round, and leave any
//    other view alone;
//  - `right`, `bottom`, the alignments and the `to…` edges are relative to
//    the superview (superlayer) bounds.
//

import AppKit

/// A view or layer whose frame is being set. Every setter returns the
/// layout again so calls chain in the order they are written.
@MainActor
struct DashboardLayout {
    private enum Target {
        case view(NSView)
        case layer(CALayer)
    }

    private let target: Target

    init(_ view: NSView) {
        target = .view(view)
    }

    init(_ layer: CALayer) {
        target = .layer(layer)
    }

    // MARK: - Pixel snapping

    /// Rounds `value` up to the main screen's pixel grid. The flag values
    /// `CGFloat.leastNormalMagnitude` and `.greatestFiniteMagnitude` pass
    /// through unchanged.
    static func snapToPixel(_ value: CGFloat) -> CGFloat {
        if value == .leastNormalMagnitude || value == .greatestFiniteMagnitude {
            return value
        }
        let scale = NSScreen.main?.backingScaleFactor ?? 1
        return ceil(value * scale) / scale
    }

    private static func sanitized(_ value: CGFloat) -> CGFloat {
        value.isNaN ? 0 : value
    }

    // MARK: - Frame access

    private var frame: CGRect {
        get {
            switch target {
            case let .view(view): return view.frame
            case let .layer(layer): return layer.frame
            }
        }
        nonmutating set {
            switch target {
            case let .view(view): view.frame = newValue
            case let .layer(layer): layer.frame = newValue
            }
        }
    }

    private var ownBounds: CGRect {
        switch target {
        case let .view(view): return view.bounds
        case let .layer(layer): return layer.bounds
        }
    }

    private var superBounds: CGRect {
        switch target {
        case let .view(view): return view.superview?.bounds ?? .zero
        case let .layer(layer): return layer.superlayer?.bounds ?? .zero
        }
    }

    private var superIsFlipped: Bool {
        switch target {
        case let .view(view): return view.superview?.isFlipped ?? false
        case let .layer(layer): return layer.superlayer?.contentsAreFlipped() ?? false
        }
    }

    // MARK: - Size and position

    @discardableResult
    func width(_ value: CGFloat) -> Self {
        var rect = frame
        rect.size.width = Self.snapToPixel(Self.sanitized(value))
        frame = rect
        return self
    }

    @discardableResult
    func height(_ value: CGFloat) -> Self {
        var rect = frame
        rect.size.height = Self.snapToPixel(Self.sanitized(value))
        frame = rect
        return self
    }

    @discardableResult
    func size(_ value: CGSize) -> Self {
        width(value.width).height(value.height)
    }

    @discardableResult
    func x(_ value: CGFloat) -> Self {
        var rect = frame
        rect.origin.x = Self.snapToPixel(Self.sanitized(value))
        frame = rect
        return self
    }

    @discardableResult
    func y(_ value: CGFloat) -> Self {
        var rect = frame
        rect.origin.y = Self.snapToPixel(Self.sanitized(value))
        frame = rect
        return self
    }

    @discardableResult
    func offsetY(_ value: CGFloat) -> Self {
        var rect = frame
        rect.origin.x = Self.snapToPixel(rect.minX)
        rect.origin.y = Self.snapToPixel(rect.minY + Self.sanitized(value))
        frame = rect
        return self
    }

    @discardableResult
    func midY(_ value: CGFloat) -> Self {
        y(Self.sanitized(value) - ownBounds.height / 2)
    }

    @discardableResult
    func maxX(_ value: CGFloat) -> Self {
        x(Self.sanitized(value) - ownBounds.width)
    }

    @discardableResult
    func maxY(_ value: CGFloat) -> Self {
        y(Self.sanitized(value) - ownBounds.height)
    }

    /// Places the trailing edge `value` points inside the superview.
    @discardableResult
    func right(_ value: CGFloat) -> Self {
        maxX(superBounds.width - Self.sanitized(value))
    }

    /// Places the bottom edge `value` points inside the superview.
    @discardableResult
    func bottom(_ value: CGFloat) -> Self {
        if superIsFlipped {
            return maxY(superBounds.height - Self.sanitized(value))
        }
        return y(Self.sanitized(value))
    }

    @discardableResult
    func horAlign() -> Self {
        x(superBounds.width / 2 - ownBounds.width / 2)
    }

    @discardableResult
    func verAlign() -> Self {
        y(superBounds.height / 2 - ownBounds.height / 2)
    }

    @discardableResult
    func fullWidth() -> Self {
        x(0).toRight(0)
    }

    @discardableResult
    func fullHeight() -> Self {
        height(superBounds.height).y(0)
    }

    @discardableResult
    func fullFrame() -> Self {
        fullWidth().fullHeight()
    }

    // MARK: - Edges

    /// Stretches the width so the trailing edge is `value` points inside the
    /// superview; never narrower than zero.
    @discardableResult
    func toRight(_ value: CGFloat) -> Self {
        var rect = frame
        rect.size.width = max(Self.snapToPixel(superBounds.width - rect.minX - Self.sanitized(value)), 0)
        frame = rect
        return self
    }

    /// Moves the top edge to `value`, keeping the bottom edge.
    @discardableResult
    func toY(_ value: CGFloat) -> Self {
        var rect = frame
        let safeValue = min(Self.sanitized(value), rect.maxY)
        rect.size.height = Self.snapToPixel(rect.maxY - safeValue)
        rect.origin.y = Self.snapToPixel(safeValue)
        frame = rect
        return self
    }

    /// Moves the bottom edge to `value`, keeping the top edge.
    @discardableResult
    func toMaxY(_ value: CGFloat) -> Self {
        var rect = frame
        let safeValue = max(Self.sanitized(value), rect.minY)
        rect.size.height = Self.snapToPixel(safeValue - rect.minY)
        frame = rect
        return self
    }

    @discardableResult
    func toBottom(_ value: CGFloat) -> Self {
        if superIsFlipped {
            return toMaxY(superBounds.height - Self.sanitized(value))
        }
        return toY(Self.sanitized(value))
    }

    @discardableResult
    func minWidth(_ value: CGFloat) -> Self {
        var rect = frame
        if rect.size.width < value {
            rect.size.width = value
            frame = rect
        }
        return self
    }

    // MARK: - Fitting

    /// The view that can measure itself: an `BaseView` or an `NSControl`.
    private var measurableView: NSView? {
        guard case let .view(view) = target else { return nil }
        if view is BaseView || view is NSControl {
            return view
        }
        return nil
    }

    private static func fittingSize(of view: NSView, in limit: NSSize) -> NSSize {
        if let baseView = view as? BaseView {
            return baseView.sizeThatFits(limit)
        }
        if let control = view as? NSControl {
            var size = control.sizeThatFits(limit)
            if size.width.isNaN {
                size.width = 0
            }
            if size.height.isNaN {
                size.height = 0
            }
            return size
        }
        return view.frame.size
    }

    @discardableResult
    func sizeToFit() -> Self {
        guard let view = measurableView else { return self }
        var rect = view.frame
        rect.size = Self.fittingSize(of: view, in: NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        view.frame = rect
        return self
    }

    @discardableResult
    func heightToFit() -> Self {
        guard let view = measurableView else { return self }
        var rect = view.frame
        let limit = NSSize(width: view.bounds.width, height: .greatestFiniteMagnitude)
        if let baseView = view as? BaseView {
            rect.size.height = baseView.sizeThatFits(limit).height
        } else if let control = view as? NSControl {
            rect.size.height = control.sizeThatFits(limit).height
        }
        view.frame = rect
        return self
    }
}

extension NSView {
    /// Lays the view out with the Dashboard's frame rules.
    @MainActor
    var dashboardLayout: DashboardLayout {
        DashboardLayout(self)
    }
}

extension CALayer {
    /// Lays the layer out with the Dashboard's frame rules.
    @MainActor
    var dashboardLayout: DashboardLayout {
        DashboardLayout(self)
    }
}

/// The Dashboard's shared metrics, mirrored from `AppHelper.swift`.
enum DashboardMetrics {
    static let viewWidth = DashboardViewWidth
    static let horInset = DashboardHorInset
    static let attrItemHorInterspace = DashboardAttrItemHorInterspace
    static let attrItemVerInterspace = DashboardAttrItemVerInterspace
    static let cardControlCornerRadius = DashboardCardControlCornerRadius
    static let sectionMarginTop = DashboardSectionMarginTop
    static let cardCornerRadius = DashboardCardCornerRadius
    static let searchCardInset = DashboardSearchCardInset

    static let numberInputHorizontalHeight = LKNumberInputHorizontalHeight
    static let numberInputVerticalHeight = LKNumberInputVerticalHeight

    static let maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
}

/// Colour, image and alert helpers that replace the old `LKHelper.h` macros.
enum DashboardStyle {
    static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
        NSColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }

    static var separatorLightModeColor: NSColor {
        rgb(215, 215, 215)
    }

    static var separatorDarkModeColor: NSColor {
        rgb(67, 67, 69)
    }

    static func separatorColor(isDarkMode: Bool) -> NSColor {
        isDarkMode ? separatorDarkModeColor : separatorLightModeColor
    }

    /// `NSFontMake`: the system font at `size`.
    static func font(_ size: CGFloat) -> NSFont {
        NSFont.systemFont(ofSize: size)
    }

    /// `NSImageMake`: a named image, possibly missing.
    static func image(_ name: String) -> NSImage? {
        NSImage(named: name)
    }

    /// `AlertError`: shows `error` as a sheet on `window`, except the
    /// discarded-request error.
    static func alert(_ error: Error, window: NSWindow?) {
        let error = error as NSError
        guard error.code != LookinErrCode_Discard else { return }
        let alert = NSAlert(error: error)
        if let window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }

    /// `AlertErrorText`: an error with a title and a recovery suggestion.
    static func alert(title: String, detail: String, window: NSWindow?) {
        let error = NSError(domain: LookinErrorDomain, code: LookinErrCode_Default, userInfo: [
            NSLocalizedDescriptionKey: title,
            NSLocalizedRecoverySuggestionErrorKey: detail,
        ])
        alert(error, window: window)
    }
}

/// Builders for the attributed strings the Objective-C code made with
/// ShortCocoa's string helpers.
enum DashboardText {
    /// `$(string)` with optional `.font`, `.textColor` and `.lineHeight`,
    /// each applied to the whole string; an empty string stays plain.
    static func attributed(_ string: String, font: NSFont? = nil, color: NSColor? = nil, lineHeight: CGFloat? = nil) -> NSMutableAttributedString {
        let result = NSMutableAttributedString(string: string)
        guard result.length > 0 else { return result }
        let range = NSRange(location: 0, length: result.length)
        if let color {
            result.addAttribute(.foregroundColor, value: color, range: range)
        }
        if let font {
            result.addAttribute(.font, value: font, range: range)
        }
        if let lineHeight {
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = lineHeight
            style.maximumLineHeight = lineHeight
            result.addAttribute(.paragraphStyle, value: style.copy(), range: range)
        }
        return result
    }

    /// ShortCocoa's `addImage(name, baselineOffset, marginLeft, marginRight)`:
    /// the image as an attachment, with fixed-width blank images for the
    /// margins.
    static func appendImage(named name: String, baselineOffset: CGFloat, marginLeft: CGFloat, marginRight: CGFloat, to string: NSMutableAttributedString) {
        guard let image = NSImage(named: name) else { return }
        let imageString = NSMutableAttributedString(attributedString: attachment(image, baselineOffset: baselineOffset))
        if marginLeft > 0 {
            imageString.insert(fixedSpace(marginLeft), at: 0)
        }
        if marginRight > 0 {
            imageString.append(fixedSpace(marginRight))
        }
        string.append(imageString)
    }

    private static func attachment(_ image: NSImage, baselineOffset: CGFloat) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let string = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        string.addAttribute(.baselineOffset, value: baselineOffset, range: NSRange(location: 0, length: string.length))
        return string
    }

    private static func fixedSpace(_ width: CGFloat) -> NSAttributedString {
        attachment(NSImage(size: NSSize(width: width, height: 1)), baselineOffset: 0)
    }
}
