import LookInsideActivation
import Observation
import SwiftUI

struct ActivationFormView: View {
    private let spacing: CGFloat = 16

    @Bindable var model: ActivationModel

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Text("Activate", bundle: .activationUI).bold()
                Spacer()
            }
            .padding(spacing)

            Divider()

            Group {
                if model.isBusy {
                    HStack {
                        Text("Communicating with authorization server…", bundle: .activationUI)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ProgressView().scaleEffect(0.5)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledRow(label: "Email") {
                            TextField("you@example.com", text: $model.email)
                                .lineLimit(1)
                        }
                        LabeledRow(label: "License Key") {
                            TextField("XXXXX-XXXXX-XXXXX-XXXXX-XXXXX", text: $model.licenseKey)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(spacing)

            if let message = model.highlightedMessage, !message.isEmpty {
                Divider()
                Text(message)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(spacing)
            }

            Divider()

            HStack {
                if model.isTrialActive {
                    Button(String(localized: "View Trial License", bundle: .activationUI)) {
                        model.returnToTrialSummary()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isBusy)
                } else {
                    Button(String(localized: "Start Trial", bundle: .activationUI)) {
                        Task { await model.runTrialFlow() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isBusy)
                }
                Spacer()
                Button(String(localized: "Activate", bundle: .activationUI)) {
                    Task { await model.runActivationFlow() }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(model.isBusy || model.email.isEmpty || model.licenseKey.isEmpty)
            }
            .padding(spacing)
        }
        .disabled(model.isBusy)
    }
}
