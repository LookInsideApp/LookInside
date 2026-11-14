import LookInsideHostCore
import Testing

/// Class chains as the Server reports them: NSStringFromClass of every class
/// from the object's own up to NSObject.
@Suite("Preview glass layers")
struct PreviewGlassLayersTests {
    @Test("SwiftUI's SDFLayer is a glass layer")
    func swiftUIGlassLayer() {
        #expect(PreviewGlassLayers.isGlassLayer(classChain: ["SwiftUI.SDFLayer", "CALayer", "NSObject"]))
    }

    @Test("A subclass of SwiftUI's SDFLayer is a glass layer")
    func swiftUIGlassLayerSubclass() {
        #expect(PreviewGlassLayers.isGlassLayer(classChain: ["SwiftUI.SDFLayerSubclass", "SwiftUI.SDFLayer", "CALayer", "NSObject"]))
    }

    @Test(
        "Other layers are not glass layers",
        arguments: [
            // An app's own class of the same name lives in another module.
            ["MyApp.SDFLayer", "CALayer", "NSObject"],
            // CoreAnimation's SDF layer sits inside the glass; the glass
            // layer above it is what the preview leaves out.
            ["CASDFLayer", "CALayer", "NSObject"],
            ["_TtC7SwiftUIP33_05C1F5BE6EE7940FED05100EA822F7B314SDFPortalLayer", "CAPortalLayer", "CALayer", "NSObject"],
            ["CALayer", "NSObject"],
            [],
        ]
    )
    func otherLayers(classChain: [String]) {
        #expect(!PreviewGlassLayers.isGlassLayer(classChain: classChain))
    }

    private static let glassView = ["NSGlassEffectView", "NSView", "NSResponder", "NSObject"]
    private static let wrapper = ["_NSSplitViewItemViewWrapper", "NSView", "NSResponder", "NSObject"]
    private static let hostingView = ["_TtGC6AppKit18_NSCoreHostingViewVSo17NSGlassEffectView8RootView_", "NSView", "NSResponder", "NSObject"]
    private static let plainView = ["NSView", "NSResponder", "NSObject"]

    @Test("The glass behind a split view item sits in a glass view right in the item's wrapper")
    func splitViewBackgroundGlass() {
        #expect(PreviewGlassLayers.isSplitViewBackgroundGlass(viewAncestorClassChains: [Self.hostingView, Self.glassView, Self.wrapper, Self.plainView]))
    }

    @Test(
        "A control's glass is not the split view's",
        arguments: [
            // A filter field's or a toolbar button's glass view in ordinary views.
            [hostingView, glassView, plainView, wrapper],
            // A glass view inside the sidebar's content, below the sidebar's glass.
            [hostingView, glassView, plainView, glassView, wrapper],
            // No glass view above it at all.
            [plainView, wrapper],
            [],
        ]
    )
    func controlGlass(viewAncestorClassChains: [[String]]) {
        #expect(!PreviewGlassLayers.isSplitViewBackgroundGlass(viewAncestorClassChains: viewAncestorClassChains))
    }
}
