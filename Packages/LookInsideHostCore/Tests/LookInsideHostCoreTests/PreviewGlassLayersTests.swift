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
}
