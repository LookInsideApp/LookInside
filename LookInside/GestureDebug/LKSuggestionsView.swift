import SwiftUI

struct LKSuggestionsView: View {
    let report: LKSuggestionReport
    let platform: LKSuggestionPlatform
    @State private var selectedID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("\(report.warnings.count) warnings", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(report.warnings.isEmpty ? Color.secondary : .orange)
                    .font(.headline)
                Spacer()
                if let minimum = platform.minimumTargetSize {
                    Text("\(platform == .iPhone ? "iPhone" : "Mac") · \(minimum, specifier: "%.0f") × \(minimum, specifier: "%.0f") pt minimum")
                        .font(.callout)
                }
            }
            Text("\(report.inspectedCount) current interaction regions inspected. \(report.coverageMessage)")
                .font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            if report.warnings.isEmpty {
                Text(report.inspectedCount == 0
                    ? LocalizedStringKey("No interaction regions are currently available for this check.")
                    : LocalizedStringKey("No small targets found in the inspected regions."))
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    List(report.warnings, selection: $selectedID) { warning in
                        VStack(alignment: .leading, spacing: 4) {
                            Label(warning.title, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange).font(.callout)
                            Text(warning.target.name).lineLimit(2).font(.caption)
                            size(warning.target).font(.caption).monospacedDigit()
                        }
                        .padding(.vertical, 4).tag(warning.id)
                    }
                    .accessibilityIdentifier("gesture.suggestions.list")
                    .frame(minWidth: 240, idealWidth: 300)
                    if let warning = report.warnings.first(where: { $0.id == selectedID }) {
                        detail(warning).frame(minWidth: 250)
                    } else {
                        Text("Select a warning to inspect its target.")
                            .foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(14)
        .onChange(of: report.warnings.map(\.id)) { _, ids in
            if let selectedID, !ids.contains(selectedID) {
                self.selectedID = nil
            }
        }
    }

    private func size(_ target: LKInteractionTarget) -> some View {
        Text("\(target.geometry.width ?? 0, specifier: "%.1f") × \(target.geometry.height ?? 0, specifier: "%.1f") pt")
    }

    private func detail(_ warning: LKSuggestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(warning.title).font(.headline)
                Text(warning.target.name).font(.system(.callout, design: .monospaced))
                size(warning.target).font(.title2).monospacedDigit()
                Text("The width or height is below \(warning.minimumSize, specifier: "%.0f") pt. Increase the interactive area to at least \(warning.minimumSize, specifier: "%.0f") × \(warning.minimumSize, specifier: "%.0f") pt.")
                if warning.target.usesEstimatedBounds {
                    Label("Estimated bounds", systemImage: "info.circle")
                    Text("These bounds may differ from the effective hit target. Check custom hit testing before changing the control.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Measured from the reported \(warning.target.shapeKind ?? NSLocalizedString("interaction", comment: "")) content shape and its bounds.")
                        .foregroundStyle(.secondary)
                }
                Text("For SwiftUI, apply padding before the interaction contentShape / gesture. Padding outside a Button may only change layout.")
                Divider()
                Text("Target: \(warning.target.targetAddress)")
                if let host = warning.target.hostAddress {
                    Text("Host: \(host)")
                }
                if let window = warning.target.windowAddress {
                    Text("Window: \(window)")
                }
                Text("Source: \(warning.target.source) · \(warning.target.geometryKind)")
                Text("Origin: (\(warning.target.geometry.x ?? 0, specifier: "%.1f"), \(warning.target.geometry.y ?? 0, specifier: "%.1f")) pt · \(warning.target.geometry.coordinateSpace)")
            }
            .font(.callout).textSelection(.enabled).padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
