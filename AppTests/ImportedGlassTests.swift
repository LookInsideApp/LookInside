//
//  ImportedGlassTests.swift
//  LookInsideAppTests
//
//  An imported Core Animation archive follows the Liquid Glass setting as a
//  live session does: Hide leaves the glass AppKit puts behind a split view
//  item out of the images, and a control's glass stays. Decoding keeps
//  QuartzCore's own classes only — SwiftUI's glass layer comes back a plain
//  CALayer — so the import finds the glass by its backdrop and judges it by
//  the views AppKit wrote onto the layers above it.
//

import AppKit
import Foundation
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct ImportedGlassTests {
        /// A window's content as Dump Layer would write it: a split view
        /// item's wrapper holding a glass view, and beside it a control's
        /// glass view, both over a dark window.
        private struct DumpedWindow {
            let window: NSWindow
            let archiveData: Data
            let tree: CoreAnimationArchiveLayerTree
            let sidebarGlassViewLayer: CALayer
            let controlGlassViewLayer: CALayer
        }

        @available(macOS 26.0, *)
        private static func dumpingWindow() -> DumpedWindow? {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            window.appearance = NSAppearance(named: .darkAqua)
            let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
            contentView.wantsLayer = true
            let wrapperView = NSView(frame: NSRect(x: 0, y: 100, width: 300, height: 100))
            wrapperView.wantsLayer = true
            let sidebarGlassView = NSGlassEffectView(frame: NSRect(x: 20, y: 30, width: 200, height: 40))
            sidebarGlassView.contentView = NSTextField(labelWithString: "Filter")
            wrapperView.addSubview(sidebarGlassView)
            let controlGlassView = NSGlassEffectView(frame: NSRect(x: 20, y: 30, width: 200, height: 40))
            controlGlassView.contentView = NSTextField(labelWithString: "Search")
            contentView.addSubview(wrapperView)
            contentView.addSubview(controlGlassView)
            window.contentView = contentView
            window.displayIfNeeded()
            CATransaction.flush()
            // The name AppKit gives the layer of the wrapper a split view puts
            // around an item, the view's class name.
            wrapperView.layer?.name = "_NSSplitViewItemViewWrapper"

            guard let contentLayer = contentView.layer,
                  let archiveData = encodingLayerTree(contentLayer),
                  let contents = try? CoreAnimationArchive.decodingContents(of: archiveData)
            else {
                window.close()
                return nil
            }
            let tree = CoreAnimationArchiveLayerTree(contents: contents)
            let glassViewLayers = tree.layers.filter {
                CoreAnimationArchiveViewIdentity(layer: $0)?.viewClassChain.first == "NSGlassEffectView"
            }
            guard glassViewLayers.count == 2,
                  let sidebarGlassViewLayer = glassViewLayers.first(where: { isInsideTheWrapper($0) }),
                  let controlGlassViewLayer = glassViewLayers.first(where: { !isInsideTheWrapper($0) })
            else {
                window.close()
                return nil
            }
            return DumpedWindow(
                window: window,
                archiveData: archiveData,
                tree: tree,
                sidebarGlassViewLayer: sidebarGlassViewLayer,
                controlGlassViewLayer: controlGlassViewLayer
            )
        }

        private static func isInsideTheWrapper(_ layer: CALayer) -> Bool {
            CoreAnimationArchiveViewIdentity(layer: layer.superlayer ?? layer)?.viewClassChain.first == "_NSSplitViewItemViewWrapper"
        }

        /// `root`'s layer tree as QuartzCore encodes it for Dump Layer.
        private static func encodingLayerTree(_ root: CALayer) -> Data? {
            typealias EncodeLayerTreeFunction = @convention(c) (CALayer) -> Unmanaged<NSData>?
            guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CAEncodeLayerTree") else { return nil }
            let encode = unsafeBitCast(symbol, to: EncodeLayerTreeFunction.self)
            return encode(root)?.takeRetainedValue() as Data?
        }

        /// Whether `layer` is `ancestor` or below it.
        private static func isLayer(_ layer: CALayer, inside ancestor: CALayer) -> Bool {
            var current: CALayer? = layer
            while let candidate = current {
                if candidate === ancestor {
                    return true
                }
                current = candidate.superlayer
            }
            return false
        }

        /// The share of an image's pixels that are opaque, and that show at
        /// all.
        private static func coverage(ofPNG data: Data?) -> (opaque: Double, visible: Double)? {
            guard let data, let image = NSBitmapImageRep(data: data)?.cgImage,
                  let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                      data: nil,
                      width: image.width,
                      height: image.height,
                      bitsPerComponent: 8,
                      bytesPerRow: image.width * 4,
                      space: colorSpace,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  )
            else { return nil }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            guard let buffer = context.data else { return nil }
            let pixels = buffer.bindMemory(to: UInt8.self, capacity: image.width * image.height * 4)
            var opaque = 0
            var visible = 0
            for index in stride(from: 3, to: image.width * image.height * 4, by: 4) {
                if pixels[index] > 200 {
                    opaque += 1
                }
                if pixels[index] > 16 {
                    visible += 1
                }
            }
            let count = Double(image.width * image.height)
            return (Double(opaque) / count, Double(visible) / count)
        }

        /// Only the glass of the glass view in the split view item's wrapper
        /// is the glass Hide leaves out; the control's is not.
        @Test func onlyTheSplitViewItemsGlassIsPicked() {
            guard #available(macOS 26.0, *) else { return }
            guard let dumped = Self.dumpingWindow() else {
                Issue.record("the window should dump with both glass views")
                return
            }
            defer { dumped.window.close() }
            let picked = dumped.tree.layers.filter(CoreAnimationArchiveImporter.isSplitViewBackgroundGlass)
            #expect(picked.count == 1, "one glass layer should be picked, got \(picked.count)")
            #expect(
                picked.allSatisfy { Self.isLayer($0, inside: dumped.sidebarGlassViewLayer) },
                "the picked glass should be the split view item's"
            )
            let controlGlass = dumped.tree.layers.filter {
                Self.isLayer($0, inside: dumped.controlGlassViewLayer)
                    && CoreAnimationArchiveGlass.viewAncestorClassChains(ofGlassLayer: $0) != nil
            }
            #expect(controlGlass.count == 1, "the control's glass should be found as glass too, got \(controlGlass.count)")
        }

        /// Imported with Hide, the split view item's glass view shows its
        /// label and no glass; imported without, it shows its glass. The
        /// control's glass shows either way.
        @Test func hideLeavesTheSplitViewGlassOutOfTheImportsImages() throws {
            guard #available(macOS 26.0, *) else { return }
            guard let dumped = Self.dumpingWindow() else {
                Issue.record("the window should dump with both glass views")
                return
            }
            defer { dumped.window.close() }
            let sidebarOid = NSNumber(value: dumped.tree.objectIdentifier(of: dumped.sidebarGlassViewLayer))
            let controlOid = NSNumber(value: dumped.tree.objectIdentifier(of: dumped.controlGlassViewLayer))

            let hidden = try CoreAnimationArchiveImporter.importingHierarchyFile(
                from: dumped.archiveData,
                fileName: "Window.caar",
                hidingSplitViewGlass: true
            )
            let shown = try CoreAnimationArchiveImporter.importingHierarchyFile(
                from: dumped.archiveData,
                fileName: "Window.caar",
                hidingSplitViewGlass: false
            )
            guard let sidebarHidden = Self.coverage(ofPNG: hidden.groupScreenshots?[sidebarOid]),
                  let sidebarShown = Self.coverage(ofPNG: shown.groupScreenshots?[sidebarOid]),
                  let controlHidden = Self.coverage(ofPNG: hidden.groupScreenshots?[controlOid]),
                  let controlShown = Self.coverage(ofPNG: shown.groupScreenshots?[controlOid])
            else {
                Issue.record("both glass views should have group images in both imports")
                return
            }
            #expect(sidebarHidden.opaque < 0.3, "with Hide only the label should be opaque, got \(sidebarHidden.opaque)")
            #expect(sidebarHidden.visible > 0.005, "with Hide the label should still show, got \(sidebarHidden.visible)")
            #expect(sidebarShown.opaque > 0.6, "without Hide the glass should cover the view, got \(sidebarShown.opaque)")
            #expect(controlHidden.opaque > 0.6, "with Hide a control's glass should stay, got \(controlHidden.opaque)")
            #expect(controlShown.opaque > 0.6, "without Hide a control's glass should show, got \(controlShown.opaque)")
        }
    }
}
