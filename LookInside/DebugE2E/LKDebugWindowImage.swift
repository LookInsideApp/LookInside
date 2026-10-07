#if DEBUG
    import AppKit
    import SceneKit

    /// Draws a Host window or view into a bitmap in process, so no
    /// screen-recording permission is involved. Shared by the end-to-end
    /// dump (LKDebugE2EDump.swift, host-window.png) and the UI snapshots
    /// (LKDebugUISnapshots.swift).
    ///
    /// SceneKit views render through Metal, which `cacheDisplay(in:to:)` does
    /// not capture, so each one's `SCNView.snapshot()` is drawn over its area,
    /// clipped away from the views that sit on top of it (outline, dashboard,
    /// toolbar).
    @objc(LKDebugWindowImage)
    final class LKDebugWindowImage: NSObject {
        /// PNG of `window`'s frame view: title bar and toolbar included.
        @objc(pngDataOfWindow:)
        static func pngData(of window: NSWindow?) -> Data? {
            guard let window, let frameView = window.contentView?.superview ?? window.contentView else {
                return nil
            }
            return pngData(of: frameView)
        }

        /// PNG of `view`'s whole bounds, including parts scrolled out of
        /// sight.
        static func pngData(of view: NSView) -> Data? {
            let bounds = view.bounds
            guard bounds.width > 0, bounds.height > 0,
                  let rep = view.bitmapImageRepForCachingDisplay(in: bounds)
            else { return nil }
            view.cacheDisplay(in: bounds, to: rep)

            var sceneViews: [SCNView] = []
            collectSceneViews(in: view, into: &sceneViews)
            if !sceneViews.isEmpty, let context = NSGraphicsContext(bitmapImageRep: rep) {
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = context
                for sceneView in sceneViews {
                    let sceneRect = rect(sceneView.bounds, of: sceneView, in: view)
                    // Only the part its ancestors show: the preview's scene
                    // view reaches under the hierarchy outline, which the
                    // window clips away.
                    let clip = NSBezierPath(rect: rect(sceneView.visibleRect, of: sceneView, in: view))
                    clip.windingRule = .evenOdd
                    for cover in views(above: sceneView, upTo: view) {
                        clip.appendRect(rect(cover.bounds, of: cover, in: view))
                    }
                    NSGraphicsContext.saveGraphicsState()
                    clip.addClip()
                    sceneView.snapshot().draw(in: sceneRect)
                    NSGraphicsContext.restoreGraphicsState()
                }
                context.flushGraphics()
                NSGraphicsContext.restoreGraphicsState()
            }
            guard let png = rep.representation(using: .png, properties: [:]), !png.isEmpty else {
                return nil
            }
            return png
        }

        /// `rect` of `view` in the bitmap's (unflipped) coordinates.
        private static func rect(_ rect: NSRect, of view: NSView, in root: NSView) -> NSRect {
            var converted = view.convert(rect, to: root)
            if root.isFlipped {
                converted.origin.y = root.bounds.height - converted.maxY
            }
            return converted
        }

        /// Visible views drawn after `view`'s branch at each level up to
        /// `root`, i.e. the ones that cover it.
        private static func views(above view: NSView, upTo root: NSView) -> [NSView] {
            var covers: [NSView] = []
            let target = view.convert(view.bounds, to: nil)
            var branch = view
            while let superview = branch.superview, branch !== root {
                let siblings = superview.subviews
                if let index = siblings.firstIndex(where: { $0 === branch }) {
                    for sibling in siblings[(index + 1)...] {
                        if sibling.isHiddenOrHasHiddenAncestor || sibling.alphaValue == 0 {
                            continue
                        }
                        if sibling.convert(sibling.bounds, to: nil).intersects(target) {
                            covers.append(sibling)
                        }
                    }
                }
                branch = superview
            }
            return covers
        }

        private static func collectSceneViews(in view: NSView, into sceneViews: inout [SCNView]) {
            if view.isHiddenOrHasHiddenAncestor {
                return
            }
            if let sceneView = view as? SCNView {
                sceneViews.append(sceneView)
                return
            }
            for subview in view.subviews {
                collectSceneViews(in: subview, into: &sceneViews)
            }
        }
    }
#endif
