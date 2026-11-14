//
//  PreviewPortalOrderTests.swift
//  LookInsideAppTests
//
//  The 3D preview orders planes front to back by the hierarchy, except for a
//  node a portal draws elsewhere while hiding it in place
//  (`DisplayItem.previewPortalItem`): that node sits where the portal draws
//  it. An `NSGlassEffectView` draws its content over its glass that way.
//

import AppKit
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct PreviewPortalOrderTests {
        /// The nodes of an `NSGlassEffectView` as AppKit builds it, all over
        /// the same frame, in hierarchy order:
        ///
        ///     glass view
        ///       content holder       drawn by portal A
        ///         search field
        ///       glass layer
        ///         content group      drawn by portal B
        ///           tint
        ///           portal A
        ///         glass
        ///           backdrop
        ///           portal B
        private struct GlassViewNodes {
            let glassView: DisplayItem
            let contentHolder: DisplayItem
            let searchField: DisplayItem
            let glassLayer: DisplayItem
            let contentGroup: DisplayItem
            let tint: DisplayItem
            let portalA: DisplayItem
            let glass: DisplayItem
            let backdrop: DisplayItem
            let portalB: DisplayItem

            var inHierarchyOrder: [DisplayItem] {
                [glassView, contentHolder, searchField, glassLayer, contentGroup, tint, portalA, glass, backdrop, portalB]
            }
        }

        private static func makingGlassViewNodes() -> GlassViewNodes {
            var oid: UInt = 0
            func node(_ subitems: [DisplayItem] = []) -> DisplayItem {
                oid += 1
                let layerObject = InspectedObject()
                layerObject.oid = oid
                layerObject.classChainList = ["CALayer", "NSObject"]
                let item = DisplayItem()
                item.nodeKind = .layer
                item.layerObject = layerObject
                item.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
                item.bounds = item.frame
                // A node with no alpha counts as hidden, and hidden planes
                // take no part in the order.
                item.alpha = 1
                item.subitems = subitems
                item.isExpanded = true
                return item
            }
            let searchField = node()
            let contentHolder = node([searchField])
            let tint = node()
            let portalA = node()
            let contentGroup = node([tint, portalA])
            let backdrop = node()
            let portalB = node()
            let glass = node([backdrop, portalB])
            let glassLayer = node([contentGroup, glass])
            let glassView = node([contentHolder, glassLayer])
            return GlassViewNodes(
                glassView: glassView, contentHolder: contentHolder, searchField: searchField, glassLayer: glassLayer,
                contentGroup: contentGroup, tint: tint, portalA: portalA, glass: glass, backdrop: backdrop, portalB: portalB
            )
        }

        @Test func contentAPortalDrawsSitsInFrontOfTheGlass() {
            let nodes = Self.makingGlassViewNodes()
            nodes.contentHolder.previewPortalItem = nodes.portalA
            nodes.contentGroup.previewPortalItem = nodes.portalB
            let preview = PreviewView(dataSource: nil)
            preview.render(displayItems: nodes.inHierarchyOrder, discardCache: true)
            #expect(nodes.searchField.previewZIndex > nodes.backdrop.previewZIndex, "the search field should sit in front of the glass")
            #expect(nodes.tint.previewZIndex > nodes.backdrop.previewZIndex, "the tint the content group draws should sit in front of the glass")
        }

        @Test func withoutPortalsTheHierarchyOrderStands() {
            let nodes = Self.makingGlassViewNodes()
            let preview = PreviewView(dataSource: nil)
            preview.render(displayItems: nodes.inHierarchyOrder, discardCache: true)
            #expect(nodes.searchField.previewZIndex < nodes.backdrop.previewZIndex, "in hierarchy order the glass covers the search field")
        }
    }
}
