import Foundation
import LookInsideActivation
import Observation
import SwiftUI
import WindowAnimation

public struct ActivationView: View {
    @Bindable private var model: ActivationModel
    private let onDone: () -> Void

    /// `onDone` runs when the license summary's Done button is clicked. The
    /// window controller passes a closure that closes the activation window.
    public init(model: ActivationModel, onDone: @escaping () -> Void = {}) {
        _model = Bindable(model)
        self.onDone = onDone
    }

    public var body: some View {
        Group {
            if model.isRefreshingLicenseStatus {
                LicenseStatusRefreshProgressView(
                    message: model.licenseStatusRefreshMessage
                        ?? String(localized: "Refreshing license status…", bundle: .activationUI)
                )
            } else if let status = model.entitlementStatus,
                      model.currentStep == .licenseStatus,
                      !model.isShowingActivationForm
            {
                LicenseSummaryView(
                    status: status,
                    isTrial: model.isTrialActive,
                    keychainAccessNotice: model.keychainAccessNotice,
                    offersKeychainAccessRetry: model.offersKeychainAccessRetry,
                    isRetryingKeychainAccess: model.isRetryingKeychainAccess,
                    onRetryKeychainAccess: { Task { await model.retryKeychainAccess() } },
                    onDone: onDone,
                    onUpgradeFromTrial: { model.beginFullActivationFromTrial() }
                )
            } else {
                ActivationFormView(model: model)
            }
        }
        .frame(width: 450)
        .animation(.spring, value: model.activationResponse?.activation.activationID)
        .animation(.spring, value: model.highlightedMessage)
        .animation(.spring, value: model.isBusy)
        .animation(.spring, value: model.isShowingActivationForm)
        .animation(.spring, value: model.licenseStatusRefreshMessage)
        .animation(.spring, value: model.keychainAccessNotice)
        .modifier(WindowAnimationModifier())
    }
}

private struct LicenseStatusRefreshProgressView: View {
    private let spacing: CGFloat = 16

    let message: String

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Text("License", bundle: .activationUI).bold()
                Spacer()
            }
            .padding(spacing)

            Divider()

            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text(message)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(spacing)
        }
    }
}
