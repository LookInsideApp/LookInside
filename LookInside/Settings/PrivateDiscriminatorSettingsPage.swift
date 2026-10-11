//
//  PrivateDiscriminatorSettingsPage.swift
//  LookInside
//
//  The Private Discriminator page of the Settings window: the feature
//  switch, the default library download and the imported modules.
//  PrivateDiscriminatorStore.shared owns all of it and its config.json.
//

import AppKit
import SwiftUI
import UIFoundationSettingsUI

struct PrivateDiscriminatorSettingsPage: View {
    private let store = PrivateDiscriminatorStore.shared

    /// The last import, reimport or removal failure. It outranks the
    /// store's own error, which covers loading and saving.
    @State private var importError: String?

    var body: some View {
        SettingsForm {
            PrivateDiscriminatorFeatureSection(store: store, importError: $importError)

            if store.featureEnabled {
                PrivateDiscriminatorModulesSection(store: store, importError: $importError)
                PrivateDiscriminatorProblemsSection(store: store, importError: importError)
            }
        }
        .onAppear {
            store.reloadFromDisk()
        }
    }
}

/// The feature switch and the default library download.
private struct PrivateDiscriminatorFeatureSection: View {
    @Bindable var store: PrivateDiscriminatorStore
    @Binding var importError: String?

    var body: some View {
        Section {
            DescribedSettingRow("Enable", description: "Resolve Swift private-discriminator hashes from imported module CSVs. Disabled by default.") {
                Toggle("Enable", isOn: $store.isFeatureEnabledSetting)
                    .toggleStyle(.switch)
            }

            DescribedSettingRow("Default Library", description: "Download SwiftUI and SwiftUICore indexes from GitHub into local imported CSVs.") {
                Button {
                    importError = nil
                    store.updateDefaultLibrary()
                } label: {
                    if store.isUpdatingDefaultLibrary {
                        Label("Updating…", systemImage: "arrow.down.circle")
                    } else {
                        Label("Update Default Library", systemImage: "arrow.down.circle")
                    }
                }
                .disabled(store.isUpdatingDefaultLibrary)
            }

            if let message = store.lastDefaultLibraryUpdateMessage {
                HStack(spacing: 8) {
                    if store.isUpdatingDefaultLibrary {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

/// Autosave, importing a module, and the modules imported so far.
private struct PrivateDiscriminatorModulesSection: View {
    @Bindable var store: PrivateDiscriminatorStore
    @Binding var importError: String?

    var body: some View {
        Section {
            DescribedSettingRow("Autosave", description: "Allow future guessed rows to use autosaved module CSVs.") {
                Toggle("Autosave", isOn: $store.isAutosaveEnabledSetting)
                    .toggleStyle(.switch)
            }

            HStack(spacing: 8) {
                Button {
                    beginImport()
                } label: {
                    Label("Import Module", systemImage: "square.and.arrow.down")
                }

                Button {
                    store.revealStorageDirectory()
                } label: {
                    Label("Reveal Storage", systemImage: "folder")
                }
            }

            if store.moduleStatuses.isEmpty {
                Text("No modules imported yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.moduleStatuses) { status in
                    PrivateDiscriminatorModuleRow(status: status, store: store) { message in
                        importError = message
                    }
                }
            }
        }
    }

    private func beginImport() {
        importError = nil
        guard let module = promptForModuleName() else {
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Import")
        panel.message = String(localized: "Choose the local Swift source folder for \(module).")

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try store.importModule(named: module, from: url)
        } catch {
            importError = error.localizedDescription
        }
    }

    private func promptForModuleName() -> String? {
        let alert = NSAlert()
        alert.messageText = String(localized: "Import Private Discriminator Module")
        alert.informativeText = String(localized: "Enter the Swift module name for this source folder.")
        alert.addButton(withTitle: String(localized: "Continue"))
        alert.addButton(withTitle: String(localized: "Cancel"))

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        textField.placeholderString = String(localized: "ModuleName")
        alert.accessoryView = textField

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        let module = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if module.isEmpty {
            importError = String(localized: "Module name is required.")
            return nil
        }
        return module
    }
}

/// CSV files that failed to load, and the last error.
private struct PrivateDiscriminatorProblemsSection: View {
    let store: PrivateDiscriminatorStore
    let importError: String?

    var body: some View {
        if !store.invalidDiagnostics.isEmpty || errorMessage != nil {
            Section {
                if !store.invalidDiagnostics.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invalid CSV Diagnostics")
                        ForEach(store.invalidDiagnostics) { diagnostic in
                            Text("\(diagnostic.module) \(diagnostic.source): \(diagnostic.message)")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var errorMessage: String? {
        importError ?? store.lastSettingsError
    }
}

private struct PrivateDiscriminatorModuleRow: View {
    let status: PrivateDiscriminatorModuleStatus
    @Bindable var store: PrivateDiscriminatorStore
    let onError: (String) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Toggle(status.module, isOn: $store[isModuleEnabled: status.module])
                .labelsHidden()
                .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 3) {
                Text(status.module)

                Text(status.sourceSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let diagnostic = status.diagnostic {
                    Text(diagnostic)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Button {
                reimport()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Reimport from saved source folder")
            .disabled(status.sourceFolderPath == nil)

            Button {
                store.revealModule(status.module)
            } label: {
                Image(systemName: "folder")
            }
            .buttonStyle(.borderless)
            .help("Reveal CSV")

            Button(role: .destructive) {
                remove()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Remove module CSVs")
        }
    }

    private func reimport() {
        do {
            try store.reimportModule(status.module)
        } catch {
            onError(error.localizedDescription)
        }
    }

    private func remove() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Remove \(status.module)?")
        alert.informativeText = String(localized: "This removes imported and autosaved CSVs for the module.")
        alert.addButton(withTitle: String(localized: "Remove"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        alert.alertStyle = .warning

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        do {
            try store.removeModule(status.module)
        } catch {
            onError(error.localizedDescription)
        }
    }
}

/// The store's switches as read-write properties, so the page can bind them
/// by key path; writing one saves config.json and reloads the store.
private extension PrivateDiscriminatorStore {
    var isFeatureEnabledSetting: Bool {
        get { featureEnabled }
        set { setFeatureEnabled(newValue) }
    }

    var isAutosaveEnabledSetting: Bool {
        get { autosaveEnabled }
        set { setAutosaveEnabled(newValue) }
    }

    subscript(isModuleEnabled module: String) -> Bool {
        get { moduleStatuses.first { $0.module == module }?.isEnabled ?? false }
        set { setModule(module, enabled: newValue) }
    }
}
