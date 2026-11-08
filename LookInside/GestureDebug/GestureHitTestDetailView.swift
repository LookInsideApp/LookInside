import SwiftUI

struct GestureHitTestDetailView: View {
    let snapshot: GestureCaptureSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Point cloud").font(.headline)
                Text("Input coordinates, radius and bindings come from SwiftUI event logs. Sample points and weights are reconstructed, not recorded from the internal hit test.")
                    .font(.callout).foregroundStyle(.secondary)
                if let clouds = snapshot.pointClouds, !clouds.isEmpty {
                    ForEach(Array(clouds.prefix(10).enumerated()), id: \.offset) { _, cloud in
                        HStack(alignment: .top, spacing: 20) {
                            GesturePointCloudPreview(cloud: cloud)
                                .frame(width: 180, height: 180)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(cloud.eventID).font(.system(.callout, design: .monospaced))
                                Text("Center: (\(cloud.center.x, format: .number.precision(.fractionLength(1))), \(cloud.center.y, format: .number.precision(.fractionLength(1)))) pt")
                                Text("Reported radius: \(cloud.reportedRadius, format: .number.precision(.fractionLength(2))) pt")
                                Text("Sampling radius: \(cloud.samplingRadius, format: .number.precision(.fractionLength(2))) pt · \(cloud.points.count) estimated samples")
                                if cloud.points.count == 1 {
                                    Text("This input produces only a center sample; mouse and small simulator touches may have no outer rings.")
                                        .foregroundStyle(.secondary)
                                }
                                Text("Observed binding chain").font(.headline)
                                if cloud.responderAddresses.isEmpty {
                                    Text("Not reported").foregroundStyle(.secondary)
                                }
                                ForEach(Array(cloud.responderAddresses.prefix(128).enumerated()), id: \.offset) { _, address in
                                    let node = snapshot.responders.first { $0.address == address }
                                    Text("\(address)  \(node?.typeName ?? "")")
                                        .font(.system(.caption, design: .monospaced))
                                }
                            }.font(.callout)
                        }
                        Divider()
                    }
                } else {
                    Text("No point cloud for this event. Capture with Record SwiftUI events enabled, then start a new touch or click. Older Servers and incomplete input records may not supply this data.")
                        .foregroundStyle(.secondary)
                }
                DisclosureGroup("Raw HIT TEST log") {
                    Text(snapshot.hitTest.isEmpty ? NSLocalizedString("No HIT TEST block was reported for this event.", comment: "") : snapshot.hitTest)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .textSelection(.enabled).padding(16).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
