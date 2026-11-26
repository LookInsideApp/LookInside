//
//  LayoutGuideAttributesHostTests.swift
//  LookInsideAppTests
//
//  The Host's side of the keyboard and tracking layout guide sections
//  (tracking-layout-guide-attributes-plan.md): a modification of a guide
//  attribute names the guide, the tracked constraints use the constraint rows
//  and say which edges they are registered under, the new sections show by
//  default, and MCP carries the edges.
//

import AppKit
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct LayoutGuideAttributesHostTests {
        private static func layoutGuideItem(oid: UInt) -> DisplayItem {
            let guideObject = InspectedObject()
            guideObject.oid = oid
            guideObject.classChainList = ["UIKeyboardLayoutGuide", "UITrackingLayoutGuide", "UILayoutGuide", "NSObject"]
            let item = DisplayItem()
            item.nodeKind = .layoutGuide
            item.kindObject = guideObject
            return item
        }

        private static func trackedConstraint(edges: NSDirectionalRectEdge) -> AutoLayoutConstraint {
            let constraint = AutoLayoutConstraint()
            constraint.firstItemType = .view
            constraint.firstAttribute = Int(NSLayoutConstraint.Attribute.bottom.rawValue)
            constraint.relation = .equal
            constraint.secondItemType = .`self`
            constraint.secondAttribute = Int(NSLayoutConstraint.Attribute.top.rawValue)
            constraint.multiplier = 1
            constraint.priority = 1000
            constraint.trackingEdges = edges
            return constraint
        }

        @Test func aLayoutGuideAttributeModificationTargetsTheGuide() throws {
            let item = Self.layoutGuideItem(oid: 4242)
            let attribute = InspectedAttribute()
            attribute.identifier = InspectedAttribute.Identifier.LayoutGuide.KeyboardLayoutGuide.followsUndockedKeyboard
            attribute.attrType = .bool
            attribute.targetDisplayItem = item
            let modification = try #require(DashboardModification.inbuilt(attribute: attribute, newValue: NSNumber(value: true), clientReadableVersion: "3.3.0"))
            #expect(modification.targetOid == 4242)
            #expect(modification.setterSelector == NSSelectorFromString("setFollowsUndockedKeyboard:"))
        }

        @Test func trackedConstraintsUseTheConstraintRows() {
            for identifier in [
                InspectedAttribute.Identifier.LayoutGuide.ConstraintsActiveNearEdges.constraints,
                InspectedAttribute.Identifier.LayoutGuide.ConstraintsActiveAwayFromEdges.constraints,
            ] {
                #expect(DashboardSectionView.attrViewClass(for: .customObject, identifier: identifier) == DashboardAttributeConstraintsView.self)
            }
        }

        @Test func aConstraintRowStartsWithTheEdgesItIsRegisteredUnder() {
            let tracked = DashboardAttributeConstraintsItemControl.string(from: Self.trackedConstraint(edges: [.leading, .top]))
            #expect(tracked.hasPrefix("top + leading · "))
            let plain = DashboardAttributeConstraintsItemControl.string(from: Self.trackedConstraint(edges: []))
            #expect(!plain.contains(" · "))
            #expect(tracked == "top + leading · " + plain)
        }

        @Test func theConstraintPopoverListsTheTrackingEdges() {
            let trackedRows = ConstraintPopoverController.rows(for: Self.trackedConstraint(edges: .bottom))
            #expect(trackedRows.last?.first == "TrackingEdges")
            #expect(trackedRows.last?.second == "bottom")
            let plainRows = ConstraintPopoverController.rows(for: Self.trackedConstraint(edges: []))
            #expect(!plainRows.contains { $0.first == "TrackingEdges" })
            #expect(trackedRows.count == plainRows.count + 1)
        }

        @Test func theKeyboardAndTrackingSectionsShowByDefault() {
            for section in [
                AttributesSection.Identifier.LayoutGuide.keyboardLayoutGuide,
                AttributesSection.Identifier.LayoutGuide.constraintsActiveNearEdges,
                AttributesSection.Identifier.LayoutGuide.constraintsActiveAwayFromEdges,
            ] {
                #expect(PreferenceManager.sectionsShowingByDefault.contains(section))
            }
        }

        @Test func mcpConstraintsCarryTrackingEdgesOnlyWhenTheyHaveSome() throws {
            func encodedFields(of constraint: AutoLayoutConstraint) throws -> [String: MCPBridgeJSONValue] {
                let attribute = InspectedAttribute()
                attribute.identifier = InspectedAttribute.Identifier.LayoutGuide.ConstraintsActiveNearEdges.constraints
                attribute.attrType = .customObject
                attribute.value = [constraint]
                let encoded = MCPBridgeAttributeEncoder.encode(attribute, redactingSecureContent: false)
                guard case let .array(constraints)? = encoded.value, case let .object(fields)? = constraints.first else {
                    Issue.record("expected one encoded constraint, got \(String(describing: encoded.value))")
                    return [:]
                }
                return fields
            }
            let tracked = try encodedFields(of: Self.trackedConstraint(edges: [.top, .trailing]))
            guard case let .array(edges)? = tracked["trackingEdges"] else {
                Issue.record("tracked constraint has no trackingEdges array")
                return
            }
            #expect(edges.count == 2)
            if case let .string(first) = edges.first, case let .string(last) = edges.last {
                #expect(first == "top")
                #expect(last == "trailing")
            } else {
                Issue.record("trackingEdges holds something other than strings")
            }
            let plain = try encodedFields(of: Self.trackedConstraint(edges: []))
            #expect(plain["trackingEdges"] == nil)
        }
    }
}
