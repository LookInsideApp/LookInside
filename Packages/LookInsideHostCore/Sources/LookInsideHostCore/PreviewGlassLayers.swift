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
}
