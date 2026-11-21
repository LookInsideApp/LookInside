//
//  DashboardRegistrationTests.swift
//  LookInsideAppTests
//
//  Everything the Host registers for the blueprint catalog's groups, checked
//  for every group of both platforms: an inspected iPhone app's groups are
//  shown by this macOS Host too, so a group compiled out of the Host's own
//  platform tables still needs its icon and enum lists.
//

@testable import LookInside
import Testing

extension HostAppTests {
    struct DashboardRegistrationTests {
        @Test("Every catalog group has a card icon")
        func everyGroupHasAnIcon() {
            let missing = DashboardBlueprintTables.catalog.map(\.identifier).filter { DashboardCardView.groupIconNames[$0] == nil }
            #expect(missing.isEmpty, "groups without a card icon: \(missing)")
        }

        @Test("Every enum list the catalog names is in the registry")
        func everyEnumListIsRegistered() {
            let attributes = DashboardBlueprintTables.catalog.flatMap(\.sections).flatMap(\.attributes)
            let enumNames = Set(attributes.compactMap(\.info.enumList))
            let missing = enumNames.filter { EnumListRegistry.shared.items(forEnumName: $0) == nil }.sorted()
            #expect(missing.isEmpty, "enum lists without cases: \(missing)")
        }
    }
}
