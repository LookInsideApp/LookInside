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
            PrivateDiscriminatorFeatureSection(store: store)
            PrivateDiscriminatorDefaultLibrarySection(store: store, importError: $importError)

            if store.featureEnabled {
                PrivateDiscriminatorAutosaveSection(store: store)
                PrivateDiscriminatorModulesSection(store: store, importError: $importError)
                PrivateDiscriminatorProblemsSection(store: store, importError: importError)
            }
        }
        .onAppear {
            store.reloadFromDisk()
        }
    }
}

/// The feature switch.
private struct PrivateDiscriminatorFeatureSection: View {
    @Bindable var store: PrivateDiscriminatorStore

    var body: some View {
        Section {
            Toggle("Enable", isOn: $store.isFeatureEnabledSetting)
        } footer: {
            Text("Resolve Swift private-discriminator hashes from imported module CSVs. Disabled by default.")
        }
    }
}

/// Downloading the SwiftUI and SwiftUICore indexes, and how the last
/// download went.
private struct PrivateDiscriminatorDefaultLibrarySection: View {
    let store: PrivateDiscriminatorStore
    @Binding var importError: String?

    var body: some View {
        Section {
            // An HStack rather than LabeledContent, so the button stays
            // centered on the row once the status adds a second line.
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(PrivateDiscriminatorStore.defaultLibraryModuleNames, format: .list(type: .and))

                    if let message = store.lastDefaultLibraryUpdateMessage {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                if store.isUpdatingDefaultLibrary {
                    ProgressView()
                        .controlSize(.small)
                }

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
        } header: {
            Text("Default Library")
        } footer: {
            Text("Download SwiftUI and SwiftUICore indexes from GitHub into local imported CSVs.")
        }
    }
}

private struct PrivateDiscriminatorAutosaveSection: View {
    @Bindable var store: PrivateDiscriminatorStore

    var body: some View {
        Section {
            Toggle("Autosave", isOn: $store.isAutosaveEnabledSetting)
        } footer: {
            Text("Allow future guessed rows to use autosaved module CSVs.")
        }
    }
}

/// Importing a module, and the modules imported so far.
private struct PrivateDiscriminatorModulesSection: View {
    let store: PrivateDiscriminatorStore
    @Binding var importError: String?

    var body: some View {
        Section {
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

                Spacer()
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
        } header: {
            Text("Modules")
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

/// CSV files that failed to load, and the last error. Each shows only
/// while there is something to report.
private struct PrivateDiscriminatorProblemsSection: View {
    let store: PrivateDiscriminatorStore
    let importError: String?

    var body: some View {
        if !store.invalidDiagnostics.isEmpty {
            Section {
                ForEach(store.invalidDiagnostics) { diagnostic in
                    Text("\(diagnostic.module) \(diagnostic.source): \(diagnostic.message)")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text("Invalid CSV Diagnostics")
            }
        }

        if let errorMessage {
            Section {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
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
