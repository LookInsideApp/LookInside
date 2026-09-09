import SwiftUI

struct LKGestureDebugView: View {
    @ObservedObject var session: LKGestureDebugSession
    let start: () -> Void
    let export: () -> Void
    @State private var section = Section.responders

    private enum Section: String, CaseIterable {
        case responders = "Responders"
        case gestures = "Gestures"
        case bindings = "Bindings"
        case hitTest = "Hit Test"
        case raw = "Raw Log"
    }

    var body: some View {
        VStack(spacing: 0) {
            controls
            Divider()
            status
            Divider()
            HSplitView {
                eventHistory.frame(minWidth: 190, idealWidth: 225, maxWidth: 310)
                VStack(spacing: 0) {
                    Picker("Details", selection: $section) {
                        ForEach(Section.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(12)
                    if let snapshot = session.selectedSnapshot {
                        snapshotContent(snapshot)
                    } else {
                        emptyState
                    }
                }
                .frame(minWidth: 620, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: session.overlayEnabled) { _ in session.updateOverlay() }
        .onChange(of: session.followsLatest) { _ in session.followLatest() }
        .onChange(of: section) { _ in session.selectedNodeID = nil }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Label(session.appName, systemImage: "hand.point.up.left")
                .font(.headline).lineLimit(1)
            Spacer()
            Toggle("Gesture borders", isOn: $session.overlayEnabled)
                .help("Interact with a region to reveal its reported borders. Borders persist until cleared; fill briefly indicates an observed binding.")
            Button("Clear Borders") { session.clearBorders() }
                .disabled(!session.isRunning || !session.overlayEnabled || session.overlayStatus?.mode != "persistentObserved")
            Button(session.isRunning || session.isStarting ? "Stop Capture" : "Start Capture") {
                if session.isRunning || session.isStarting {
                    session.stop()
                } else {
                    start()
                }
            }
            .disabled(!session.supported)
            .keyboardShortcut("r", modifiers: .command)
            Button("Export…", action: export)
                .disabled(session.records.isEmpty && session.snapshots.isEmpty)
        }
        .padding(12)
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(session.state == "capturing" ? Color.green : (session.state == "redacted" || session.state == "error" ? .orange : .secondary))
                    .frame(width: 7, height: 7).padding(.top, 4)
                Text(session.message).font(.callout).textSelection(.enabled)
                Spacer(minLength: 12)
                Text("\(session.recordCount) records · \(session.snapshots.count) events")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if session.redactedCount > 0 || session.droppedCount > 0 {
                Text("\(session.redactedCount) private records · \(session.droppedCount) dropped records")
                    .font(.caption).foregroundStyle(.orange)
            }
            if let latest = session.snapshots.last {
                Text("Latest event arrived \(max(0, latest.receivedAt - latest.timestamp), specifier: "%.2f") s late · system query \(session.pollDurationMS, specifier: "%.0f") ms")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let overlay = session.overlayStatus, overlay.isEnabled, session.isRunning {
                Text("\(overlay.regionCount) borders in target app · Interact to reveal regions. Clear after layout changes.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if session.state == "redacted" {
                DisclosureGroup("Target Debug build configuration") {
                    Text("""
                    Add OSLogPreferences to the target app’s Debug Info.plist:
                    com.apple.SwiftUI → Events → Enable-Private-Data = YES
                    com.apple.diagnostics.events → SwiftUI → Enable-Private-Data = YES
                    Relaunch the app, reconnect, and start a new capture.
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled).padding(.top, 4)
                }.font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var eventHistory: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Events").font(.headline)
                Spacer()
                Toggle("Follow latest", isOn: $session.followsLatest).toggleStyle(.checkbox).font(.caption)
            }.padding(12)
            ScrollViewReader { proxy in
                List {
                    ForEach(session.snapshots.reversed()) { snapshot in
                        Button {
                            session.selectSnapshot(snapshot.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(Date(timeIntervalSince1970: snapshot.timestamp).formatted(.dateTime.hour().minute().second().secondFraction(.fractional(3))))
                                    Spacer()
                                    Text(snapshot.phase ?? snapshot.inputPhase ?? "unknown")
                                }.font(.caption).foregroundStyle(.secondary)
                                Text(snapshot.title).font(.callout).lineLimit(2)
                                Text("\(snapshot.responders.count) responders · \(snapshot.gestures.count) gesture nodes")
                                    .font(.caption2).foregroundStyle(.secondary)
                                if !snapshot.complete {
                                    Label("Partial event", systemImage: "ellipsis.rectangle")
                                        .font(.caption2).foregroundStyle(.orange)
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(session.selectedSnapshotID == snapshot.id ? Color.accentColor.opacity(0.14) : .clear,
                                        in: RoundedRectangle(cornerRadius: 6))
                            .contentShape(Rectangle())
                        }.buttonStyle(.plain).id(snapshot.id)
                    }
                }.listStyle(.plain)
                    .onChange(of: session.snapshots.last?.id) { id in
                        if session.followsLatest, let id {
                            proxy.scrollTo(id, anchor: .top)
                        }
                    }
                    .onChange(of: session.followsLatest) { follows in
                        if follows, let id = session.snapshots.last?.id {
                            proxy.scrollTo(id, anchor: .top)
                        }
                    }
            }
        }
    }

    private func snapshotContent(_ snapshot: LKGestureCaptureSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Host: \(snapshot.hostAddress ?? "not reported")")
                Spacer()
                Text("Thread: \(snapshot.threadID)")
            }
            .font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
            .textSelection(.enabled).padding(.horizontal, 14).padding(.bottom, 8)
            if !snapshot.warnings.isEmpty {
                Text(snapshot.warnings.joined(separator: " "))
                    .font(.caption).foregroundStyle(.orange)
                    .padding(.horizontal, 14).padding(.bottom, 8)
            }
            switch section {
            case .responders: tree(snapshot.responders, snapshot: snapshot)
            case .gestures: tree(snapshot.gestures, snapshot: snapshot)
            case .bindings:
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(snapshot.eventText.isEmpty ? "No input event record." : snapshot.eventText)
                            .font(.system(.caption, design: .monospaced))
                        ForEach(Array(snapshot.bindings.enumerated()), id: \.offset) { _, binding in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(binding.eventID).font(.headline)
                                ForEach(Array(binding.responderAddresses.enumerated()), id: \.offset) { _, address in
                                    let node = snapshot.responders.first { $0.address == address }
                                    Text("→ \(address)  \(node?.typeName ?? "Responder outside this printed tree")")
                                        .font(.system(.callout, design: .monospaced))
                                }
                            }
                        }
                        if snapshot.bindings.isEmpty {
                            Text("No binding chain was reported.").foregroundStyle(.secondary)
                        }
                    }
                    .textSelection(.enabled).padding(16).frame(maxWidth: .infinity, alignment: .leading)
                }
            case .hitTest:
                rawText(snapshot.hitTest.isEmpty ? "No HIT TEST block was reported for this event." : snapshot.hitTest)
            case .raw:
                rawText(snapshot.rawRecords.map { "[\($0.sequence)] \($0.message)" }.joined(separator: "\n"))
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func tree(_ nodes: [LKGestureCaptureNode], snapshot: LKGestureCaptureSnapshot) -> some View {
        HSplitView {
            List(selection: $session.selectedNodeID) {
                OutlineGroup(LKGestureTreeItem.roots(from: nodes), children: \.children) { item in
                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: item.node.kind == "responder" ? "arrow.triangle.branch" : "hand.draw")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.node.typeName).font(.system(.callout, design: .monospaced)).lineLimit(2)
                            if let address = item.node.address {
                                Text(address).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                            } else if let phase = item.node.phase {
                                Text(phase).font(.caption).foregroundStyle(phase == "failed" ? .orange : .secondary)
                            }
                        }
                    }.padding(.vertical, 3).tag(item.id)
                }
            }
            .listStyle(.inset).frame(minWidth: 290, idealWidth: 380)
            if let node = nodes.first(where: { $0.id == session.selectedNodeID }) {
                LKGestureNodeDetailView(node: node, snapshot: snapshot)
                    .frame(minWidth: 250, idealWidth: 300)
            } else {
                Text(nodes.isEmpty ? "No nodes reported." : "Select a node to inspect its details.")
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 250, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.point.up.left").font(.system(size: 34)).foregroundStyle(.secondary)
            Text("Inspect a SwiftUI interaction").font(.title3)
            Text("Start capture and tap, press, or drag in the target app.\nResponder and gesture details appear after an event is observed.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            if !session.records.isEmpty {
                Text("Records are arriving, but no complete tree has been decoded yet. Export retains the raw evidence.")
                    .font(.caption).foregroundStyle(.secondary).frame(maxWidth: 430)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func rawText(_ text: String) -> some View {
        ScrollView([.horizontal, .vertical]) {
            Text(text).font(.system(.callout, design: .monospaced))
                .textSelection(.enabled).padding(16).frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
