import SwiftUI

struct GesturePointCloudPreview: View {
    let cloud: GestureCapturePointCloud

    var body: some View {
        Canvas { context, size in
            guard cloud.canDraw else { return }
            let scale = (min(size.width, size.height) - 32) / (max(cloud.samplingRadius, 8) * 2)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            if cloud.samplingRadius > 0 {
                let radius = cloud.samplingRadius * scale
                context.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                      width: radius * 2, height: radius * 2)),
                               with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            for sample in cloud.points {
                let x = center.x + (sample.x - cloud.center.x) * scale
                let y = center.y + (sample.y - cloud.center.y) * scale
                context.fill(Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)),
                             with: .color(.accentColor.opacity(0.35 + 0.65 * sqrt(sample.weight / 24))))
            }
            var cross = Path()
            cross.move(to: CGPoint(x: center.x - 6, y: center.y))
            cross.addLine(to: CGPoint(x: center.x + 6, y: center.y))
            cross.move(to: CGPoint(x: center.x, y: center.y - 6))
            cross.addLine(to: CGPoint(x: center.x, y: center.y + 6))
            context.stroke(cross, with: .foreground, lineWidth: 1.5)
        }
        .accessibilityElement()
        .accessibilityLabel("Reconstructed point cloud")
        .accessibilityValue("\(cloud.points.count) estimated samples")
    }
}
