//
//  KeyAppearanceSettingTests.swift
//  LookInsideAppTests
//
//  The Settings switch that lets a Mac app's Server draw the inspected
//  window as active while it takes images: it reaches the Server with the
//  app and hierarchy requests, and the General page writes it and follows
//  changes made elsewhere. The page runs against a preference set of its
//  own, which never writes user defaults; the request parameters are checked
//  against the shared set as it stands, so the tests change no setting of
//  the app they run in.
//

import Foundation
@testable import LookInside
import Testing

extension HostAppTests {
    @MainActor
    struct KeyAppearanceSettingTests {
        @Test func theAppAndHierarchyRequestsCarryTheSetting() {
            let setting = NSNumber(value: PreferenceManager.shared.drawsInspectedAppAsActive)

            let hierarchyParameters = InspectableApp.hierarchyRequestParameters()
            #expect(hierarchyParameters[LookinParam_KeepsKeyAppearance] as? NSNumber == setting)

            let localIdentifiers = NSArray(array: [NSNumber(value: 7)])
            let appParameters = AppsManager.appRequestParameters(needImages: true, localIdentifiers: localIdentifiers)
            #expect(appParameters[LookinParam_KeepsKeyAppearance] as? NSNumber == setting)
            #expect(appParameters["needImages"] as? NSNumber == NSNumber(value: true), "the keys the Server always read stay")
            #expect(appParameters["local"] as? NSArray == localIdentifiers)
        }

        @Test func thePageWritesTheSettingAndFollowsChangesMadeElsewhere() {
            let preferences = PreferenceManager()
            preferences.drawsInspectedAppAsActive = true
            let model = GeneralSettingsModel(preferences: preferences)
            #expect(model.drawsInspectedAppAsActive)

            model.drawsInspectedAppAsActive = false
            #expect(!preferences.drawsInspectedAppAsActive)
            #expect(!model.drawsInspectedAppAsActive)

            preferences.drawsInspectedAppAsActive = true
            #expect(model.drawsInspectedAppAsActive, "a change made elsewhere shows on the page")
        }
    }
}
