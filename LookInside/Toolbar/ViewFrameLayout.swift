//
//  ViewFrameLayout.swift
//  LookInside
//
//  Manual frame layout for the Launch, Toolbar and Read views, with the
//  rules ShortCocoa's `$(view)` chains used there: positions and fixed sizes
//  are rounded up to the screen's pixel grid, sizes measured by
//  `sizeThatFits` are taken as they are, and edges measure against the
//  superview's bounds.
//

import AppKit

@MainActor
struct ViewFrameLayout {
    let view: NSView

    init(_ view: NSView) {
        self.view = view
    }

    /// Rounds `value` up to the main screen's pixel grid.
    static func snap(_ value: CGFloat) -> CGFloat {
        if value == .leastNormalMagnitude || value == .greatestFiniteMagnitude {
            return value
        }
        let scale = NSScreen.main?.backingScaleFactor ?? 1
        return (value * scale).rounded(.up) / scale
    }

    private var superSize: NSSize {
        view.superview?.bounds.size ?? .zero
    }

    private func edit(_ change: (inout NSRect) -> Void) -> Self {
        var frame = view.frame
        change(&frame)
        view.frame = frame
        return self
    }

    // MARK: Position

    @discardableResult func x(_ value: CGFloat) -> Self {
        edit { $0.origin.x = Self.snap(value) }
    }

    @discardableResult func y(_ value: CGFloat) -> Self {
        edit { $0.origin.y = Self.snap(value) }
    }

    @discardableResult func midX(_ value: CGFloat) -> Self {
        x(value - view.bounds.width / 2)
    }

    @discardableResult func midY(_ value: CGFloat) -> Self {
        y(value - view.bounds.height / 2)
    }

    @discardableResult func maxX(_ value: CGFloat) -> Self {
        x(value - view.bounds.width)
    }

    @discardableResult func maxY(_ value: CGFloat) -> Self {
        y(value - view.bounds.height)
    }

    /// The right edge `inset` points from the superview's right edge.
    @discardableResult func right(_ inset: CGFloat) -> Self {
        guard view.superview != nil else { return self }
        return maxX(superSize.width - inset)
    }

    /// The bottom edge `inset` points from the superview's bottom edge.
    @discardableResult func bottom(_ inset: CGFloat) -> Self {
        guard let superview = view.superview else { return self }
        return superview.isFlipped ? maxY(superview.bounds.height - inset) : y(inset)
    }

    /// Centered horizontally in the superview.
    @discardableResult func horAlign() -> Self {
        guard view.superview != nil else { return self }
        return midX(superSize.width / 2)
    }

    /// Centered vertically in the superview.
    @discardableResult func verAlign() -> Self {
        guard view.superview != nil else { return self }
        return midY(superSize.height / 2)
    }

    @discardableResult func offsetX(_ delta: CGFloat) -> Self {
        x(view.frame.minX + delta)
    }

    @discardableResult func offsetY(_ delta: CGFloat) -> Self {
        y(view.frame.minY + delta)
    }

    // MARK: Size

    @discardableResult func width(_ value: CGFloat) -> Self {
        edit { $0.size.width = Self.snap(value) }
    }

    @discardableResult func height(_ value: CGFloat) -> Self {
        edit { $0.size.height = Self.snap(value) }
    }

    @discardableResult func size(_ value: NSSize) -> Self {
        width(value.width).height(value.height)
    }

    /// Stretches the right edge to `inset` points from the superview's right edge.
    @discardableResult func toRight(_ inset: CGFloat) -> Self {
        let width = max(Self.snap(superSize.width - view.frame.minX - inset), 0)
        return edit { $0.size.width = width }
    }

    /// Stretches the right edge to `value`, never past the left edge.
    @discardableResult func toMaxX(_ value: CGFloat) -> Self {
        let width = Self.snap(max(value, view.frame.minX) - view.frame.minX)
        return edit { $0.size.width = width }
    }

    @discardableResult func fullWidth() -> Self {
        x(0).toRight(0)
    }

    @discardableResult func fullHeight() -> Self {
        guard view.superview != nil else { return self }
        return height(superSize.height).y(0)
    }

    @discardableResult func fullFrame() -> Self {
        fullWidth().fullHeight()
    }

    /// The size `sizeThatFits` asks for with no limit.
    @discardableResult func sizeToFit() -> Self {
        var size = Self.fittingSize(of: view, limit: NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        if size.width.isNaN {
            size.width = 0
        }
        if size.height.isNaN {
            size.height = 0
        }
        return edit { $0.size = size }
    }

    /// The height `sizeThatFits` asks for at the current width.
    @discardableResult func heightToFit() -> Self {
        let height = Self.fittingSize(of: view, limit: NSSize(width: view.bounds.width, height: .greatestFiniteMagnitude)).height
        return edit { $0.size.height = height }
    }

    /// `sizeThatFits` of a control or an `BaseView`; other views keep their size.
    static func fittingSize(of view: NSView, limit: NSSize) -> NSSize {
        if let control = view as? NSControl {
            return control.sizeThatFits(limit)
        }
        if let baseView = view as? BaseView {
            return baseView.sizeThatFits(limit)
        }
        return view.frame.size
    }

    // MARK: Groups

    /// Moves `views` together so their union is centered horizontally in
    /// their common superview.
    static func groupHorAlign(_ views: [NSView]) {
        guard let superview = commonSuperview(of: views) else { return }
        groupMidX(views, superview.bounds.width / 2)
    }

    /// Moves `views` together so their union is centered vertically in
    /// their common superview.
    static func groupVerAlign(_ views: [NSView]) {
        guard let superview = commonSuperview(of: views) else { return }
        groupMidY(views, superview.bounds.height / 2)
    }

    static func groupMidX(_ views: [NSView], _ value: CGFloat) {
        guard let union = union(of: views) else { return }
        views.forEach { ViewFrameLayout($0).offsetX(value - union.midX) }
    }

    static func groupMidY(_ views: [NSView], _ value: CGFloat) {
        guard let union = union(of: views) else { return }
        views.forEach { ViewFrameLayout($0).offsetY(value - union.midY) }
    }

    private static func union(of views: [NSView]) -> NSRect? {
        guard let first = views.first else { return nil }
        if views.count > 1, commonSuperview(of: views) == nil {
            return nil
        }
        return views.dropFirst().reduce(first.frame) { $0.union($1.frame) }
    }

    private static func commonSuperview(of views: [NSView]) -> NSView? {
        guard let superview = views.first?.superview,
              views.allSatisfy({ $0.superview === superview })
        else { return nil }
        return superview
    }
}
