import LookInsideActivation
import SwiftUI

public struct LicenseStatusView: View {
    private let spacing: CGFloat = 16

    private let status: EntitlementStatus?
    private let configuration: ActivationUIConfiguration

    public init(
        status: EntitlementStatus?,
        configuration: ActivationUIConfiguration = .init()
    ) {
        self.status = status
        self.configuration = configuration
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Text("License", bundle: .activationUI).bold()
                Spacer()
            }
            .padding(spacing)

            Divider()

            if let status {
                LicenseDetailRows(status: status)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(spacing)
            } else {
                Text("License status becomes available after activation.", bundle: .activationUI)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(spacing)
            }
        }
        .frame(width: 450)
    }
}
