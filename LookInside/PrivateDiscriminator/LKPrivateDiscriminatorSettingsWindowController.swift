import AppKit
import SwiftUI

@objc(LKPrivateDiscriminatorSettingsWindowController)
final class LKPrivateDiscriminatorSettingsWindowController: NSWindowController {
    private static let sharedController = LKPrivateDiscriminatorSettingsWindowController()

    @objc(showSettingsWindow)
    static func showSettingsWindow() {
        sharedController.showWindow(nil)
        sharedController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Private Discriminator Settings"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 640, height: 520)
        window.contentViewController = NSHostingController(rootView: LKPrivateDiscriminatorSettingsRootView())
        window.center()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct LKPrivateDiscriminatorSettingsRootView: View {
    @ObservedObject private var store = LKPrivateDiscriminatorStore.shared
    @State private var importError: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Private Discriminator")
                        .font(.system(size: 24, weight: .semibold))
                        .padding(.bottom, 18)

                    SettingsRow(
                        title: "Enable",
                        message: "Resolve Swift private-discriminator hashes from imported module CSVs. Disabled by default.",
                        controlWidth: 84
                    ) {
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { store.featureEnabled },
                                set: { store.setFeatureEnabled($0) }
                            )
                        )
                        .toggleStyle(.switch)
                    }

                    if store.featureEnabled {
                        SettingsDivider()

                        SettingsRow(
                            title: "Autosave",
                            message: "Allow future LookInside AI-generated rows to use autosaved module CSVs.",
                            controlWidth: 84
                        ) {
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { store.autosaveEnabled },
                                    set: { store.setAutosaveEnabled($0) }
                                )
                            )
                            .toggleStyle(.switch)
                        }

                        VStack(alignment: .leading, spacing: 10) {
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
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(store.moduleStatuses) { status in
                                        ModuleStatusRow(status: status, store: store) { message in
                                            importError = message
                                        }

                                        if status.id != store.moduleStatuses.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                            }

                            diagnosticsView
                            errorView
                        }
                        .padding(.vertical, 13)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    NSApp.keyWindow?.performClose(nil)
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(.bar)
        }
        .frame(minWidth: 640, idealWidth: 660, minHeight: 520, idealHeight: 640)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            store.reloadFromDisk()
        }
    }

    @ViewBuilder
    private var diagnosticsView: some View {
        if !store.invalidDiagnostics.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Invalid CSV Diagnostics")
                    .font(.system(size: 12, weight: .medium))
                ForEach(store.invalidDiagnostics) { diagnostic in
                    Text("\(diagnostic.module) \(diagnostic.source): \(diagnostic.message)")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private var errorView: some View {
        if let importError {
            Text(importError)
                .font(.system(size: 11))
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        } else if let error = store.lastSettingsError {
            Text(error)
                .font(.system(size: 11))
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
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
        panel.prompt = "Import"
        panel.message = "Choose the local Swift source folder for \(module)."

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
        alert.messageText = "Import Private Discriminator Module"
        alert.informativeText = "Enter the Swift module name for this source folder."
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        textField.placeholderString = "ModuleName"
        alert.accessoryView = textField

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        let module = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if module.isEmpty {
            importError = "Module name is required."
            return nil
        }
        return module
    }
}

private struct SettingsRow<Control: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let controlWidth: CGFloat
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 24) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                if let message {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            control
                .labelsHidden()
                .frame(width: controlWidth, alignment: .trailing)
        }
        .padding(.vertical, 13)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
    }
}

private struct ModuleStatusRow: View {
    let status: LKPrivateDiscriminatorModuleStatus
    let store: LKPrivateDiscriminatorStore
    let onError: (String) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Toggle(
                "",
                isOn: Binding(
                    get: { status.isEnabled },
                    set: { store.setModule(status.module, enabled: $0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 3) {
                Text(status.module)
                    .font(.system(size: 13, weight: .medium))

                Text(status.sourceSummary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if let diagnostic = status.diagnostic {
                    Text(diagnostic)
                        .font(.system(size: 11))
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
        .padding(.vertical, 8)
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
        alert.messageText = "Remove \(status.module)?"
        alert.informativeText = "This removes imported and autosaved CSVs for the module."
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
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
