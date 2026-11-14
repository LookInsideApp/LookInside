import Foundation

/// Which layers are Liquid Glass, so the preview can leave them out.
///
/// macOS 26 and later render AppKit's glass (NSGlassEffectView, the toolbar
/// glass, a segmented control's glass) through SwiftUI's `SDFLayer`. Below it
/// sits an opaque white fill of the glass shape, the source its signed
/// distance field is generated from, which never reaches the screen; the
/// glass itself is composited by the render server. An offscreen capture can
/// only draw that fill, so every piece of glass would show up in the preview
/// as a white block over the content under it. Nothing below an `SDFLayer`
/// has pixels a capture reproduces, which is why the whole subtree goes.
public enum PreviewGlassLayers {
    /// SwiftUI's glass layer as a class chain names it: NSStringFromClass
    /// writes a Swift class as module and name.
    public static let glassLayerClassName = "SwiftUI.SDFLayer"

    /// Whether an object with this class chain is a glass layer. Only the
    /// SwiftUI class counts, exactly: an app's own class that happens to be
    /// called `SDFLayer` lives in another module.
    public static func isGlassLayer(classChain: [String]) -> Bool {
        classChain.contains(glassLayerClassName)
    }

    /// The view AppKit wraps each split view item in, and the glass view it
    /// puts there behind a sidebar or an inspector.
    public static let splitViewItemWrapperClassName = "_NSSplitViewItemViewWrapper"
    public static let glassEffectViewClassName = "NSGlassEffectView"

    /// Whether a glass layer is the glass AppKit puts behind a split view
    /// item — a sidebar's or an inspector's — given the class chains of the
    /// views above it, nearest first: the nearest `NSGlassEffectView` sits
    /// right in the item's wrapper view. That glass covers the item's content
    /// in the preview, and it is what the Liquid Glass setting's Hide leaves
    /// out where LookInside draws glass; a control's glass stays.
    public static func isSplitViewBackgroundGlass(viewAncestorClassChains: some Sequence<[String]>) -> Bool {
        var iterator = viewAncestorClassChains.makeIterator()
        while let classChain = iterator.next() {
            if classChain.contains(glassEffectViewClassName) {
                return iterator.next()?.contains(splitViewItemWrapperClassName) == true
            }
        }
        return false
    }
}
