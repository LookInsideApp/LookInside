import AppKit
import SwiftUI

/// Tells an upgraded user what the coming keychain prompt is for before
/// LookInside first uses a license key it did not create.
struct KeychainAccessExplainerView: View {
    let onContinue: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Allow Access to Your License Key", bundle: .activationUI)
                        .font(.headline)
                    Text(
                        "LookInside needs to use the license key saved when you activated. macOS will ask for keychain access next. Choose “Always Allow”, otherwise you will be asked again every time LookInside connects to an app.",
                        bundle: .activationUI
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack {
                Spacer()
                Button(action: onNotNow) {
                    Text("Not Now", bundle: .activationUI)
                }
                .keyboardShortcut(.cancelAction)
                Button(action: onContinue) {
                    Text("Continue", bundle: .activationUI)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
