//
//  GeneralSettingsPage.swift
//  LookInside
//
//  The General page of the Settings window: what the Preferences window
//  used to hold. PreferenceManager.shared still owns every value here and
//  stores it in the standard user defaults under its original key.
//

import AppKit
import Foundation
import LookInsideHostCore
import SwiftUI
import UIFoundationSettingsUI

struct GeneralSettingsPage: View {
    let model: GeneralSettingsModel

    var body: some View {
        SettingsForm {
            GeneralAppearanceSection(model: model)
            GeneralColorFormatSection(model: model)
            GeneralImageContrastSection(model: model)
            GeneralHierarchySection(model: model)
            GeneralTimeoutSection(model: model)
            #if DEBUG
                GeneralLicenseTimeoutSection(model: model)
            #endif
            GeneralResetSection(model: model)
        }
    }
}

/// Dark, light, or whichever the system uses: picked from the pictures
/// System Settings shows for the same choice, or from a menu when this
/// macOS does not have them where they are looked for.
private struct GeneralAppearanceSection: View {
    @Bindable var model: GeneralSettingsModel

    var body: some View {
        Section {
            if let thumbnails = SystemAppearanceThumbnails.current {
                LabeledContent("Appearance") {
                    AppearanceThumbnailPicker(selection: $model.appearanceType, thumbnails: thumbnails)
                }
            } else {
                Picker("Appearance", selection: $model.appearanceType) {
                    Text("Dark Mode").tag(PreferredAppearanceType.dark)
                    Text("Light Mode").tag(PreferredAppearanceType.light)
                    Text("System Default").tag(PreferredAppearanceType.system)
                }
            }
        }
    }
}

/// How colors are written out: RGBA components or a hex string.
private struct GeneralColorFormatSection: View {
    @Bindable var model: GeneralSettingsModel

    var body: some View {
        Section {
            LabeledContent("Color Format") {
                Picker("Color Format", selection: $model.usesRGBAColorFormat) {
                    Text(verbatim: "RGBA").tag(true)
                    Text(verbatim: "HEX").tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
        } header: {
            Text("Display")
        } footer: {
            Text(colorFormatDescription)
        }
    }

    private var colorFormatDescription: LocalizedStringResource {
        model.usesRGBAColorFormat
            ? "Color will be displayed in format like (255, 12, 34, 0.5). Alpha value is between 0 and 1."
            : "Color will be displayed in format like #7e7e7eff. The components are #RRGGBBAA."
    }
}

/// How deep the selected layer's color is.
private struct GeneralImageContrastSection: View {
    @Bindable var model: GeneralSettingsModel

    var body: some View {
        Section {
            LabeledContent("Image contrast") {
                Picker("Image contrast", selection: $model.imageContrastLevel) {
                    Text("Normal").tag(0)
                    Text("Medium").tag(1)
                    Text("High").tag(2)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
        } footer: {
            Text("Adjust this option to use a deeper layer selection color.")
        }
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

            Toggle("Remember expansion state per app", isOn: $model.remembersExpansionState)
        } header: {
            Text("Hierarchy")
        } footer: {
            Text("When on, the hierarchy expand/collapse state is restored per target-app bundle id across host and target-app restarts. The 20 most recently inspected apps are kept; toggling off preserves existing data but stops reading or writing it.")
        }
    }
}

/// How long the hierarchy requests may take.
private struct GeneralTimeoutSection: View {
    @Bindable var model: GeneralSettingsModel

    var body: some View {
        Section {
            LabeledContent("Hierarchy Timeout") {
                TimeoutStepper("Hierarchy Timeout", seconds: $model.hierarchyRequestTimeout)
            }
        } header: {
            Text("Timeouts")
        } footer: {
            Text("Timeout for hierarchy and hierarchy-details requests, in seconds. Default: 15s.")
        }
    }
}

#if DEBUG
    /// The license handshake's timeout, there for debugging the handshake.
    private struct GeneralLicenseTimeoutSection: View {
        @Bindable var model: GeneralSettingsModel

        var body: some View {
            Section {
                LabeledContent("License Timeout") {
                    TimeoutStepper("License Timeout", seconds: $model.licenseHandshakeTimeout)
                }
            } footer: {
                Text("Timeout for license challenge and verification requests, in seconds. Default: 5s.")
            }
        }
    }
#endif

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

/// Seconds, typed into the field or stepped a whole second at a time.
private struct TimeoutStepper: View {
    private let title: LocalizedStringKey
    @Binding private var seconds: Double

    init(_ title: LocalizedStringKey, seconds: Binding<Double>) {
        self.title = title
        _seconds = seconds
    }

    var body: some View {
        Stepper(
            title,
            value: $seconds,
            in: PreferenceValuePolicy.timeoutRange,
            step: 1,
            format: .number.precision(.fractionLength(0 ... 2))
        )
        .labelsHidden()
    }
}

// MARK: - Appearance thumbnails

/// The pictures System Settings shows for its three appearance choices.
/// They are Apple's artwork, so the app reads them out of the system's
/// Appearance settings extension at run time instead of shipping copies.
private struct SystemAppearanceThumbnails {
    let system: NSImage
    let light: NSImage
    let dark: NSImage

    /// Nil when this version of macOS has moved or renamed the pictures.
    @MainActor static let current = SystemAppearanceThumbnails(
        settingsExtensionPath: "/System/Library/ExtensionKit/Extensions/Appearance.appex"
    )

    init?(settingsExtensionPath: String) {
        guard
            let settingsExtension = Bundle(path: settingsExtensionPath),
            let system = settingsExtension.image(forResource: "AppearanceAuto"),
            let light = settingsExtension.image(forResource: "AppearanceLight"),
            let dark = settingsExtension.image(forResource: "AppearanceDark")
        else {
            return nil
        }
        self.system = system
        self.light = light
        self.dark = dark
    }
}

/// System, light and dark side by side, the chosen one outlined.
private struct AppearanceThumbnailPicker: View {
    @Binding var selection: PreferredAppearanceType
    let thumbnails: SystemAppearanceThumbnails

    var body: some View {
        HStack(spacing: 5) {
            AppearanceThumbnailOption(image: thumbnails.system, title: "System", isSelected: selection == .system) {
                selection = .system
            }
            AppearanceThumbnailOption(image: thumbnails.light, title: "Light", isSelected: selection == .light) {
                selection = .light
            }
            AppearanceThumbnailOption(image: thumbnails.dark, title: "Dark", isSelected: selection == .dark) {
                selection = .dark
            }
        }
        .padding(.vertical, 8)
    }
}

private struct AppearanceThumbnailOption: View {
    let image: NSImage
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 72, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    }
                    .shadow(color: .black.opacity(isHovering ? 0.15 : 0.1), radius: isHovering ? 3 : 2, x: 0, y: 1)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Model

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
