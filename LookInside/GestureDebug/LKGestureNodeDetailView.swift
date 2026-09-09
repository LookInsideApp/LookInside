import SwiftUI

struct LKGestureNodeDetailView: View {
    let node: LKGestureCaptureNode
    let snapshot: LKGestureCaptureSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                field("Type", node.typeName)
                if let address = node.address {
                    field("Responder address", address)
                }
                if let attributeID = node.attributeID {
                    field("Gesture attribute ID", "#\(attributeID)")
                }
                if let phase = node.phase {
                    field("Observed phase", phase)
                }
                if let geometry = node.geometry {
                    field("Reported origin", "\(number(geometry.x)), \(number(geometry.y))")
                    field("Reported size", "\(number(geometry.width)) × \(number(geometry.height))")
                    Text("SwiftUI global coordinates. The log does not supply an exact contentShape or a complete transform.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let address = node.address {
                    let events = snapshot.bindings.filter { $0.responderAddresses.contains(address) }.map(\.eventID)
                    field("Observed bindings", events.isEmpty ? "None reported" : events.joined(separator: "\n"))
                }
                if !node.detail.isEmpty {
                    field("Properties", node.detail)
                }
                if let record = snapshot.rawRecords.first(where: { $0.sequence == node.recordSequence }) {
                    field("Source record \(record.sequence)", record.message)
                }
            }
            .textSelection(.enabled).padding(16).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func field(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.callout, design: .monospaced)).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func number(_ value: Double?) -> String {
        value.map { $0.formatted(.number.precision(.fractionLength(0 ... 3))) } ?? "not reported"
    }
}
