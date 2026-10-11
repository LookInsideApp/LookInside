//
//  SettingsPages.swift
//  LookInside
//
//  The pages of the Settings window, which is UIFoundation's
//  SettingsWindowController (NavigationManager holds it). The window only
//  changes how the settings are shown: PreferenceManager keeps the general
//  ones in the standard user defaults, PrivateDiscriminatorStore keeps its
//  own in config.json.
//
//  The pages are laid out the way RuntimeViewer lays out its settings with
//  the same window: plain glyphs in the sidebar, a header over each group,
//  and what a setting does in the footer under its group.
//

import SwiftUI
import UIFoundationSettingsUI

enum SettingsPages {
    /// Page identifiers. Unlike the titles they do not change with the
    /// language, so they are what selects a page.
    static let generalIdentifier = "general"
    static let privateDiscriminatorIdentifier = "privateDiscriminator"

    /// The sidebar, in order.
    @MainActor
    @SettingsPageBuilder
    static func make() -> [SettingsPage] {
        // Made once per window, so the page keeps one model however often
        // SwiftUI rebuilds it.
        let generalModel = GeneralSettingsModel()

        SettingsPage(
            String(localized: "General", comment: "Title of the Settings window's General page."),
            id: generalIdentifier,
            plainSymbol: "gearshape"
        ) {
            GeneralSettingsPage(model: generalModel)
        }

        SettingsPage(
            String(localized: "Private Discriminator", comment: "Title of the Settings window's Private Discriminator page."),
            id: privateDiscriminatorIdentifier,
            plainSymbol: "number"
        ) {
            PrivateDiscriminatorSettingsPage()
        }
    }
}
