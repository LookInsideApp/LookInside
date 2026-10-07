import ConfettiSwiftUI
import LookInsideActivation
import SwiftUI

struct LicenseSummaryView: View {
    private let spacing: CGFloat = 16

    let status: EntitlementStatus
    let isTrial: Bool
    let keychainAccessNotice: String?
    let offersKeychainAccessRetry: Bool
    let isRetryingKeychainAccess: Bool
    let onRetryKeychainAccess: () -> Void
    let onDone: () -> Void
    let onUpgradeFromTrial: () -> Void

    @State private var confetti: Int = 0
    @State private var hasFiredConfetti: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Text("License", bundle: .activationUI).bold()
                Spacer()
            }
            .padding(spacing)

            Divider()

            LicenseDetailRows(status: status)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(spacing)

            if let keychainAccessNotice {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Label(keychainAccessNotice, systemImage: "key")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if offersKeychainAccessRetry {
                        Button(String(localized: "Try Again", bundle: .activationUI), action: onRetryKeychainAccess)
                            .controlSize(.small)
                            .disabled(isRetryingKeychainAccess)
                    }
                }
                .padding([.horizontal, .bottom], spacing)
            }

            Divider()

            HStack {
                if isTrial {
                    Button(
                        String(localized: "Activate Full Version", bundle: .activationUI), action: onUpgradeFromTrial
                    )
                    .buttonStyle(.bordered)
                }
                Spacer()
                Button(String(localized: "Done", bundle: .activationUI), action: onDone)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(spacing)
        }
        .background(
            Color.clear
                .confettiCannon(
                    trigger: $confetti,
                    num: 60,
                    openingAngle: .degrees(0),
                    closingAngle: .degrees(360),
                    radius: 260
                )
        )
        .onAppear {
            guard !hasFiredConfetti else { return }
            hasFiredConfetti = true
            confetti += 1
        }
    }
}
