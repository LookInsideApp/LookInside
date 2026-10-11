//
//  GeneralSettingsPage.swift
//  LookInside
//
//  The General page of the Settings window: what the Preferences window
//  used to hold. PreferenceManager.shared still owns every value here and
//  stores it in the standard user defaults under its original key.
//

import Foundation
import LookInsideHostCore
import SwiftUI
import UIFoundationSettingsUI

struct GeneralSettingsPage: View {
    let model: GeneralSettingsModel

    var body: some View {
        SettingsForm {
            GeneralDisplaySection(model: model)
            GeneralHierarchySection(model: model)
            GeneralTimeoutSection(model: model)
            GeneralResetSection(model: model)
        }
    }
}

/// Appearance, the color format and the image contrast.
private struct GeneralDisplaySection: View {
    @Bindable var model: GeneralSettingsModel

    var body: some View {
        Section {
            Picker("Appearance", selection: $model.appearanceType) {
                Text("Dark Mode").tag(PreferredAppearanceType.dark)
                Text("Light Mode").tag(PreferredAppearanceType.light)
                Text("System Default").tag(PreferredAppearanceType.system)
            }

            DescribedSettingRow("Color Format", description: colorFormatDescription) {
                Picker("Color Format", selection: $model.usesRGBAColorFormat) {
                    Text(verbatim: "RGBA").tag(true)
                    Text(verbatim: "HEX").tag(false)
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            DescribedSettingRow("Image contrast", description: "Adjust this option to use a deeper layer selection color.") {
                Picker("Image contrast", selection: $model.imageContrastLevel) {
                    Text("Normal").tag(0)
                    Text("Medium").tag(1)
                    Text("High").tag(2)
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
        }
    }

    private var colorFormatDescription: LocalizedStringResource {
        model.usesRGBAColorFormat
            ? "Color will be displayed in format like (255, 12, 34, 0.5). Alpha value is between 0 and 1."
            : "Color will be displayed in format like #7e7e7eff. The components are #RRGGBBAA."
    }
}

/// What a double click does in the hierarchy, and whether its expansion
/// state is kept per app.
private struct GeneralHierarchySection: View {
    @Bindable var model: GeneralSettingsModel

    var body: some View {
        Section {
            Picker("Double click", selection: $model.doubleClickBehavior) {
                Text("Expand or collapse layer").tag(DoubleClickBehavior.collapse)
                Text("Focus on layer").tag(DoubleClickBehavior.focus)
            }

            DescribedSettingRow(
                "Remember expansion state per app",
                description: "When on, the hierarchy expand/collapse state is restored per target-app bundle id across host and target-app restarts. The 20 most recently inspected apps are kept; toggling off preserves existing data but stops reading or writing it."
            ) {
                Toggle("Remember expansion state per app", isOn: $model.remembersExpansionState)
                    .toggleStyle(.switch)
            }
        }
    }
}

/// Request timeouts. The license one is for debugging the handshake only.
private struct GeneralTimeoutSection: View {
    @Bindable var model: GeneralSettingsModel

    var body: some View {
        Section {
            DescribedSettingRow("Hierarchy Timeout", description: "Timeout for hierarchy and hierarchy-details requests, in seconds. Default: 15s.") {
                TimeoutField("Hierarchy Timeout", seconds: $model.hierarchyRequestTimeout)
            }

            #if DEBUG
                DescribedSettingRow("License Timeout", description: "Timeout for license challenge and verification requests, in seconds. Default: 5s.") {
                    TimeoutField("License Timeout", seconds: $model.licenseHandshakeTimeout)
                }
            #endif
        }
    }
}

private struct GeneralResetSection: View {
    let model: GeneralSettingsModel

    var body: some View {
        Section {
            Button("Reset", role: .destructive) {
                model.resetToDefaults()
            }
            .keyboardShortcut(.delete, modifiers: [.command, .shift])
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

/// Seconds, typed or stepped.
private struct TimeoutField: View {
    private let title: LocalizedStringKey
    @Binding private var seconds: Double

    init(_ title: LocalizedStringKey, seconds: Binding<Double>) {
        self.title = title
        _seconds = seconds
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField(title, value: $seconds, format: .number.precision(.fractionLength(0 ... 2)))
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width: 72)

            Text(verbatim: "s")
                .foregroundStyle(.secondary)

            Stepper(title, value: $seconds, in: PreferenceValuePolicy.timeoutRange, step: 1)
        }
        .labelsHidden()
    }
}

/// The General page's side of PreferenceManager.shared. Setting a property
/// writes the manager, and KVO brings every change back, including the ones
/// made elsewhere (the Dashboard switches the color format too), so the page
/// never shows a stale value.
@MainActor
@Observable
final class GeneralSettingsModel {
    private let preferences: PreferenceManager
    @ObservationIgnored private var observations: [NSKeyValueObservation] = []

    // What the manager holds, as of its last KVO notification.
    private var currentAppearanceType: PreferredAppearanceType
    private var currentUsesRGBAColorFormat: Bool
    private var currentImageContrastLevel: Int
    private var currentDoubleClickBehavior: DoubleClickBehavior
    private var currentRemembersExpansionState: Bool
    private var currentHierarchyRequestTimeout: TimeInterval
    private var currentLicenseHandshakeTimeout: TimeInterval

    init(preferences: PreferenceManager = .shared) {
        self.preferences = preferences
        currentAppearanceType = preferences.appearanceType
        currentUsesRGBAColorFormat = preferences.rgbaFormat
        currentImageContrastLevel = preferences.imageContrastLevel
        currentDoubleClickBehavior = preferences.doubleClickBehavior
        currentRemembersExpansionState = preferences.rememberExpansionState
        currentHierarchyRequestTimeout = preferences.hierarchyRequestTimeoutInterval
        currentLicenseHandshakeTimeout = preferences.licenseHandshakeTimeoutInterval

        observations = [
            preferences.observe(\.appearanceType, options: [.new]) { [weak self] preferences, _ in
                MainActor.assumeIsolated { self?.currentAppearanceType = preferences.appearanceType }
            },
            preferences.observe(\.rgbaFormat, options: [.new]) { [weak self] preferences, _ in
                MainActor.assumeIsolated { self?.currentUsesRGBAColorFormat = preferences.rgbaFormat }
            },
            preferences.observe(\.imageContrastLevel, options: [.new]) { [weak self] preferences, _ in
                MainActor.assumeIsolated { self?.currentImageContrastLevel = preferences.imageContrastLevel }
            },
            preferences.observe(\.doubleClickBehavior, options: [.new]) { [weak self] preferences, _ in
                MainActor.assumeIsolated { self?.currentDoubleClickBehavior = preferences.doubleClickBehavior }
            },
            preferences.observe(\.rememberExpansionState, options: [.new]) { [weak self] preferences, _ in
                MainActor.assumeIsolated { self?.currentRemembersExpansionState = preferences.rememberExpansionState }
            },
            preferences.observe(\.hierarchyRequestTimeoutInterval, options: [.new]) { [weak self] preferences, _ in
                MainActor.assumeIsolated { self?.currentHierarchyRequestTimeout = preferences.hierarchyRequestTimeoutInterval }
            },
            preferences.observe(\.licenseHandshakeTimeoutInterval, options: [.new]) { [weak self] preferences, _ in
                MainActor.assumeIsolated { self?.currentLicenseHandshakeTimeout = preferences.licenseHandshakeTimeoutInterval }
            },
        ]
    }

    var appearanceType: PreferredAppearanceType {
        get { currentAppearanceType }
        set { preferences.appearanceType = newValue }
    }

    var usesRGBAColorFormat: Bool {
        get { currentUsesRGBAColorFormat }
        set { preferences.rgbaFormat = newValue }
    }

    var imageContrastLevel: Int {
        get { currentImageContrastLevel }
        set { preferences.imageContrastLevel = PreferenceValuePolicy.clampedImageContrastLevel(newValue) }
    }

    var doubleClickBehavior: DoubleClickBehavior {
        get { currentDoubleClickBehavior }
        set { preferences.doubleClickBehavior = newValue }
    }

    var remembersExpansionState: Bool {
        get { currentRemembersExpansionState }
        set { preferences.rememberExpansionState = newValue }
    }

    var hierarchyRequestTimeout: TimeInterval {
        get { currentHierarchyRequestTimeout }
        set {
            preferences.hierarchyRequestTimeoutInterval = PreferenceValuePolicy.sanitizedTimeout(
                newValue, defaultValue: defaultHierarchyRequestTimeoutInterval
            )
        }
    }

    var licenseHandshakeTimeout: TimeInterval {
        get { currentLicenseHandshakeTimeout }
        set {
            preferences.licenseHandshakeTimeoutInterval = PreferenceValuePolicy.sanitizedTimeout(
                newValue, defaultValue: defaultLicenseHandshakeTimeoutInterval
            )
        }
    }

    /// Every value on the page back to its default. Debug builds also forget
    /// the dismissed tips, as the Preferences window's Reset did.
    func resetToDefaults() {
        appearanceType = .system
        usesRGBAColorFormat = true
        imageContrastLevel = 0
        doubleClickBehavior = .collapse
        remembersExpansionState = true
        hierarchyRequestTimeout = defaultHierarchyRequestTimeoutInterval

        #if DEBUG
            licenseHandshakeTimeout = defaultLicenseHandshakeTimeoutInterval
            MessageManager.sharedInstance().reset()
            preferences.reset()
            UserDefaults.standard.removeObject(forKey: "IgnoreFastModeTips")
        #endif
    }
}
