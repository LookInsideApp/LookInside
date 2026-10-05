import SwiftUI

/// Current native regions are independent of historical SwiftUI log events.
struct LKNativeInteractionDetailView: View {
    let regions: [LKNativeInteractionRegion]
    let isRunning: Bool
    let overlayEnabled: Bool
    @State private var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Current page · \(regions.count) native regions")
                .font(.headline).padding(12)
            Text("Native controls and actionable list rows appear before interaction. Dashed outlines show view bounds; custom hit-test shapes may differ.")
                .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 12).padding(.bottom, 12)
            Divider()
            if regions.isEmpty {
                Text(isRunning ? "No supported native interactions on this page. Native collection currently supports UIKit." : "Start capture to inspect native regions.")
                    .foregroundStyle(.secondary).padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    List(regions, selection: $selection) { region in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(region.label).lineLimit(2)
                                if region.isActive {
                                    Text("Active").foregroundStyle(.green)
                                }
                            }
                            Text(region.source == "listSelection" ? "List selection" : "UIControl")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(region.viewAddress).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                        }.padding(.vertical, 3).tag(region.id)
                    }.frame(minWidth: 220, idealWidth: 270)
                    if let region = regions.first(where: { $0.id == selection }) {
                        detail(region).frame(minWidth: 280)
                    } else {
                        Text("Select a native region to inspect its handlers.")
                            .foregroundStyle(.secondary).frame(minWidth: 280, maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .onChange(of: regions.map(\.id)) { ids in
            if let selection, !ids.contains(selection) {
                self.selection = nil
            }
        }
    }

    private func detail(_ region: LKNativeInteractionRegion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                field("View", region.viewClass)
                field("Address", region.viewAddress)
                field("Window", region.windowAddress)
                field("State", region.isActive ? "Tracking / highlighted" : "Idle")
                field("Geometry", region.geometryKind == "swiftUIContentShape" ? "SwiftUI content shape on native control" : "View bounds (hit-test approximation)")
                if let x = region.geometry.x, let y = region.geometry.y, let width = region.geometry.width, let height = region.geometry.height {
                    field("Window coordinates", String(format: "(%.1f, %.1f) · %.1f × %.1f", x, y, width, height))
                }
                ForEach(Array(region.handlers.enumerated()), id: \.offset) { _, handler in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(handler.kind == "uiAction" ? "UIAction" : (handler.kind == "listSelection" ? "List selection callback" : "Target-action"))
                            .font(.caption).foregroundStyle(.secondary)
                        Text(handler.name).font(.system(.callout, design: .monospaced))
                        if let target = handler.target {
                            Text(target).font(.system(.caption, design: .monospaced))
                        }
                        if let events = handler.events {
                            Text("UIControl events: 0x\(String(events, radix: 16))").font(.caption)
                        }
                    }
                }
            }.textSelection(.enabled).padding(16).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func field(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.callout, design: .monospaced))
        }
    }
}
