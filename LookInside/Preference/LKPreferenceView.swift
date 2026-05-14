import AppKit
import SwiftUI

@objc(LKPreferenceHostingController)
public final class LKPreferenceHostingController: NSViewController {
    override public func loadView() {
        view = NSHostingView(rootView: LKPreferenceRootView())
    }
}

private struct LKPreferenceRootView: View {
    @StateObject private var model = LKPreferenceViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Preferences")
                        .font(.system(size: 24, weight: .semibold))
                        .padding(.bottom, 18)

                    PreferenceRow(
                        title: "Appearance",
                        message: nil,
                        controlWidth: 300
                    ) {
                        Picker("Appearance", selection: model.appearanceTypeBinding) {
                            Text("Dark Mode").tag(0)
                            Text("Light Mode").tag(1)
                            Text("System Default").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }

                    PreferenceDivider()

                    PreferenceRow(
                        title: "Color Format",
                        message: model.colorFormatMessage,
                        controlWidth: 220
                    ) {
                        Picker("Color Format", selection: model.colorFormatBinding) {
                            Text(verbatim: "RGBA").tag(0)
                            Text(verbatim: "HEX").tag(1)
                        }
                        .pickerStyle(.segmented)
                    }

                    PreferenceDivider()

                    PreferenceRow(
                        title: "Image contrast",
                        message: "Adjust this option to use a deeper layer selection color.",
                        controlWidth: 300
                    ) {
                        Picker("Image contrast", selection: model.imageContrastBinding) {
                            Text("Normal").tag(0)
                            Text("Medium").tag(1)
                            Text("High").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }

                    PreferenceDivider()

                    PreferenceRow(
                        title: "Double click",
                        message: nil,
                        controlWidth: 300
                    ) {
                        Picker("Double click", selection: model.doubleClickBinding) {
                            Text("Expand or collapse layer").tag(0)
                            Text("Focus on layer").tag(1)
                        }
                        .pickerStyle(.segmented)
                    }

                    PreferenceDivider()

                    PreferenceRow(
                        title: "Remember expansion state per app",
                        message: "When on, the hierarchy expand/collapse state is restored per target-app bundle id across host and target-app restarts. The 20 most recently inspected apps are kept; toggling off preserves existing data but stops reading or writing it.",
                        controlWidth: 80
                    ) {
                        Toggle("Remember expansion state per app", isOn: model.rememberExpansionStateBinding)
                            .toggleStyle(.switch)
                    }

                    PreferenceDivider()

                    PreferenceRow(
                        title: "Hierarchy Timeout",
                        message: "Timeout for hierarchy and hierarchy-details requests, in seconds. Default: 15s.",
                        controlWidth: 168
                    ) {
                        TimeoutEditor(value: model.hierarchyTimeoutBinding)
                    }

                    #if DEBUG
                        PreferenceDivider()

                        PreferenceRow(
                            title: "License Timeout",
                            message: "Timeout for license challenge and verification requests, in seconds. Default: 5s.",
                            controlWidth: 168
                        ) {
                            TimeoutEditor(value: model.licenseTimeoutBinding)
                        }
                    #endif
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }

            Divider()

            HStack {
                Spacer()
                Button("Reset", role: .destructive) {
                    model.reset()
                }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(.bar)
        }
        .frame(minWidth: 640, idealWidth: 660, minHeight: minimumHeight)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            model.reload()
        }
    }

    private var minimumHeight: CGFloat {
        #if DEBUG
            520
        #else
            455
        #endif
    }
}

private struct PreferenceRow<Control: View>: View {
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

private struct PreferenceDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 0)
    }
}

private struct TimeoutEditor: View {
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 8) {
            TextField(Self.emptyTitle, value: $value, formatter: Self.formatter)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width: 72)

            Text(verbatim: "s")
                .foregroundStyle(.secondary)
                .frame(width: 12, alignment: .leading)

            Stepper("", value: $value, in: 0.1 ... 120, step: 1)
                .labelsHidden()
        }
    }

    private static let emptyTitle = ""

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimum = 0.1
        formatter.maximum = 120
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.allowsFloats = true
        return formatter
    }()
}

@MainActor
private final class LKPreferenceViewModel: ObservableObject {
    @Published private var appearanceType: Int
    @Published private var colorFormat: Int
    @Published private var imageContrast: Int
    @Published private var doubleClickBehavior: Int
    @Published private var rememberExpansionState: Bool
    @Published private var hierarchyTimeout: Double

    #if DEBUG
        @Published private var licenseTimeout: Double
    #endif

    private let manager: LKPreferenceManager

    init(manager: LKPreferenceManager = LKPreferenceManager.main()) {
        self.manager = manager
        appearanceType = manager.appearanceType.rawValue
        colorFormat = manager.rgbaFormat ? 0 : 1
        imageContrast = manager.imageContrastLevel
        doubleClickBehavior = manager.doubleClickBehavior.rawValue
        rememberExpansionState = manager.rememberExpansionState
        hierarchyTimeout = manager.hierarchyRequestTimeoutInterval
        #if DEBUG
            licenseTimeout = manager.licenseHandshakeTimeoutInterval
        #endif
    }

    var appearanceTypeBinding: Binding<Int> {
        Binding(
            get: { self.appearanceType },
            set: { self.setAppearanceType($0) }
        )
    }

    var colorFormatBinding: Binding<Int> {
        Binding(
            get: { self.colorFormat },
            set: { self.setColorFormat($0) }
        )
    }

    var imageContrastBinding: Binding<Int> {
        Binding(
            get: { self.imageContrast },
            set: { self.setImageContrast($0) }
        )
    }

    var doubleClickBinding: Binding<Int> {
        Binding(
            get: { self.doubleClickBehavior },
            set: { self.setDoubleClickBehavior($0) }
        )
    }

    var rememberExpansionStateBinding: Binding<Bool> {
        Binding(
            get: { self.rememberExpansionState },
            set: { self.setRememberExpansionState($0) }
        )
    }

    var hierarchyTimeoutBinding: Binding<Double> {
        Binding(
            get: { self.hierarchyTimeout },
            set: { self.setHierarchyTimeout($0) }
        )
    }

    #if DEBUG
        var licenseTimeoutBinding: Binding<Double> {
            Binding(
                get: { self.licenseTimeout },
                set: { self.setLicenseTimeout($0) }
            )
        }
    #endif

    var colorFormatMessage: LocalizedStringKey {
        if colorFormat == 0 {
            return "Color will be displayed in format like (255, 12, 34, 0.5). Alpha value is between 0 and 1."
        }
        return "Color will be displayed in format like #7e7e7eff. The components are #RRGGBBAA."
    }

    func reload() {
        appearanceType = manager.appearanceType.rawValue
        colorFormat = manager.rgbaFormat ? 0 : 1
        imageContrast = manager.imageContrastLevel
        doubleClickBehavior = manager.doubleClickBehavior.rawValue
        rememberExpansionState = manager.rememberExpansionState
        hierarchyTimeout = manager.hierarchyRequestTimeoutInterval
        #if DEBUG
            licenseTimeout = manager.licenseHandshakeTimeoutInterval
        #endif
    }

    func reset() {
        setAppearanceType(LookinPreferredAppeanranceType.system.rawValue)
        setColorFormat(0)
        setImageContrast(0)
        setDoubleClickBehavior(LookinDoubleClickBehavior.collapse.rawValue)
        setRememberExpansionState(true)
        setHierarchyTimeout(LKDefaultHierarchyRequestTimeoutInterval)
        setLicenseTimeoutIfAvailable(LKDefaultLicenseHandshakeTimeoutInterval)

        #if DEBUG
            LKMessageManager.sharedInstance().reset()
            manager.reset()
            UserDefaults.standard.removeObject(forKey: "IgnoreFastModeTips")
        #endif
    }

    private func setAppearanceType(_ rawValue: Int) {
        guard let type = LookinPreferredAppeanranceType(rawValue: rawValue) else {
            return
        }
        appearanceType = rawValue
        manager.appearanceType = type
    }

    private func setColorFormat(_ rawValue: Int) {
        colorFormat = rawValue
        manager.rgbaFormat = rawValue == 0
    }

    private func setImageContrast(_ rawValue: Int) {
        let clampedValue = min(max(rawValue, 0), 2)
        imageContrast = clampedValue
        manager.imageContrastLevel = clampedValue
    }

    private func setDoubleClickBehavior(_ rawValue: Int) {
        guard let behavior = LookinDoubleClickBehavior(rawValue: rawValue) else {
            return
        }
        doubleClickBehavior = rawValue
        manager.doubleClickBehavior = behavior
    }

    private func setRememberExpansionState(_ newValue: Bool) {
        rememberExpansionState = newValue
        manager.rememberExpansionState = newValue
    }

    private func setHierarchyTimeout(_ value: Double) {
        let sanitizedValue = sanitizedTimeout(value, defaultValue: LKDefaultHierarchyRequestTimeoutInterval)
        hierarchyTimeout = sanitizedValue
        manager.hierarchyRequestTimeoutInterval = sanitizedValue
    }

    private func setLicenseTimeoutIfAvailable(_ value: Double) {
        #if DEBUG
            setLicenseTimeout(value)
        #else
            _ = value
        #endif
    }

    #if DEBUG
        private func setLicenseTimeout(_ value: Double) {
            let sanitizedValue = sanitizedTimeout(value, defaultValue: LKDefaultLicenseHandshakeTimeoutInterval)
            licenseTimeout = sanitizedValue
            manager.licenseHandshakeTimeoutInterval = sanitizedValue
        }
    #endif

    private func sanitizedTimeout(_ value: Double, defaultValue: Double) -> Double {
        guard value.isFinite, value > 0 else {
            return defaultValue
        }
        return min(max(value, 0.1), 120)
    }
}
