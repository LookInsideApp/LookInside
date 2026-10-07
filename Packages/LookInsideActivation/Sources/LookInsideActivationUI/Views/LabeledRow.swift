import LookInsideActivation
import SwiftUI

struct LabeledRow<Content: View>: View {
    let label: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label, bundle: .activationUI)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            content()
        }
    }
}
