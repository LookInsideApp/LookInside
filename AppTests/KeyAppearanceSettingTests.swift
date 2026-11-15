//
//  KeyAppearanceSettingTests.swift
//  LookInsideAppTests
//
//  The Settings choice of how far a Mac app's Server shows the inspected app
//  as active while it takes images: it reaches the Server with the app and
//  hierarchy requests — the level, and the switch older Servers read — the
//  General page writes it and follows changes made elsewhere, and it carries
//  over from the switch it replaced. The page runs against a preference set
//  of its own, which never writes user defaults; the request parameters are
//  checked against the shared set as it stands and the carry-over against a
//  defaults suite of its own, so the tests change no setting of the app they
//  run in.
//

import Foundation
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct KeyAppearanceSettingTests {
        @Test func theAppAndHierarchyRequestsCarryTheSetting() {
            let level = PreferenceManager.shared.inspectedAppKeyAppearanceLevel

            let hierarchyParameters = InspectableApp.hierarchyRequestParameters()
            #expect(hierarchyParameters[LookinParam_KeyAppearanceLevel] as? NSNumber == NSNumber(value: level.serverLevel.rawValue))
            #expect(hierarchyParameters[LookinParam_KeepsKeyAppearance] as? NSNumber == NSNumber(value: level != .off))

            let localIdentifiers = NSArray(array: [NSNumber(value: 7)])
            let appParameters = AppsManager.appRequestParameters(needImages: true, localIdentifiers: localIdentifiers)
            #expect(appParameters[LookinParam_KeyAppearanceLevel] as? NSNumber == NSNumber(value: level.serverLevel.rawValue))
            #expect(appParameters[LookinParam_KeepsKeyAppearance] as? NSNumber == NSNumber(value: level != .off))
            #expect(appParameters["needImages"] as? NSNumber == NSNumber(value: true), "the keys the Server always read stay")
            #expect(appParameters["local"] as? NSArray == localIdentifiers)
        }

        /// An older Server reads only the switch: it draws the window as key
        /// at either level above off.
        @Test func eachLevelSendsTheSwitchOlderServersRead() {
            let expected: [(InspectedAppKeyAppearanceLevel, LookinKeyAppearanceLevel, Bool)] = [
                (.off, .off, false),
                (.drawsAsKey, .drawsAsKey, true),
                (.treatsAsKey, .treatsAsKey, true),
            ]
            #expect(expected.map(\.0) == InspectedAppKeyAppearanceLevel.allCases)
            for (level, serverLevel, keepsKeyAppearance) in expected {
                let parameters = level.requestParameters
                #expect(level.serverLevel == serverLevel)
                #expect(parameters[LookinParam_KeyAppearanceLevel as NSString] == NSNumber(value: serverLevel.rawValue))
                #expect(parameters[LookinParam_KeepsKeyAppearance as NSString] == NSNumber(value: keepsKeyAppearance))
            }
        }

        @Test func thePageWritesTheSettingAndFollowsChangesMadeElsewhere() {
            let preferences = PreferenceManager()
            preferences.inspectedAppKeyAppearanceLevel = .drawsAsKey
            let model = GeneralSettingsModel(preferences: preferences)
            #expect(model.inspectedAppKeyAppearanceLevel == .drawsAsKey)

            model.inspectedAppKeyAppearanceLevel = .treatsAsKey
            #expect(preferences.inspectedAppKeyAppearanceLevel == .treatsAsKey)
            #expect(model.inspectedAppKeyAppearanceLevel == .treatsAsKey)

            preferences.inspectedAppKeyAppearanceLevel = .off
            #expect(model.inspectedAppKeyAppearanceLevel == .off, "a change made elsewhere shows on the page")
        }

        @Test func theLevelCarriesOverFromTheSwitchItReplaced() throws {
            func level(
                storedSwitch: Bool?,
                storedLevel: Int? = nil
            ) throws -> (level: InspectedAppKeyAppearanceLevel, writtenBack: Int?) {
                let suiteName = "LookInsideAppTests.KeyAppearanceLevel.\(UUID().uuidString)"
                let defaults = try #require(UserDefaults(suiteName: suiteName))
                defer { defaults.removePersistentDomain(forName: suiteName) }
                if let storedSwitch {
                    defaults.set(storedSwitch, forKey: "drawsInspectedAppAsActive")
                }
                if let storedLevel {
                    defaults.set(storedLevel, forKey: "inspectedAppKeyAppearanceLevel")
                }
                let level = PreferenceManager.storedInspectedAppKeyAppearanceLevel(defaults)
                return (level, defaults.object(forKey: "inspectedAppKeyAppearanceLevel") as? Int)
            }
            let fresh = try level(storedSwitch: nil)
            #expect(fresh.level == .drawsAsKey, "nothing stored: draw as key")
            #expect(fresh.writtenBack == InspectedAppKeyAppearanceLevel.drawsAsKey.rawValue, "the level is written back")
            #expect(try level(storedSwitch: true).level == .drawsAsKey, "the switch on: draw as key")
            #expect(try level(storedSwitch: false).level == .off, "the switch off: off")
            #expect(
                try level(storedSwitch: false, storedLevel: InspectedAppKeyAppearanceLevel.treatsAsKey.rawValue).level == .treatsAsKey,
                "a stored level wins over the old switch"
            )
            #expect(try level(storedSwitch: false, storedLevel: 9).level == .off, "an unknown level falls back to the switch")
        }
    }
}
