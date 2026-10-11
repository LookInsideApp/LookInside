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
            symbol: "gearshape",
            tint: .gray
        ) {
            GeneralSettingsPage(model: generalModel)
        }

        SettingsPage(
            String(localized: "Private Discriminator", comment: "Title of the Settings window's Private Discriminator page."),
            id: privateDiscriminatorIdentifier,
            symbol: "number",
            tint: .purple
        ) {
            PrivateDiscriminatorSettingsPage()
        }
    }
}

/// A form row whose label is a title above a secondary description, the way
/// System Settings lays out a setting that needs explaining.
struct DescribedSettingRow<Control: View>: View {
    private let title: LocalizedStringResource
    private let description: LocalizedStringResource
    private let control: Control

    init(
        _ title: LocalizedStringResource,
        description: LocalizedStringResource,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.description = description
        self.control = control()
    }

    var body: some View {
        LabeledContent {
            control
                .labelsHidden()
        } label: {
            Text(title)
            Text(description)
        }
    }
}
