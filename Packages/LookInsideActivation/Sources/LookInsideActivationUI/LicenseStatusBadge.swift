import LookInsideActivation
import SwiftUI

struct LicenseStatusBadge: View {
    let state: SummaryDisplayState

    var body: some View {
        Text(label, bundle: .activationUI)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(tint.opacity(0.15))
            )
            .foregroundStyle(tint)
    }

    private var label: LocalizedStringKey {
        switch state {
        case .trial:
            return "Trial"
        case .subscriptionActive:
            return "Subscription · Active"
        case .subscriptionCanceled:
            return "Subscription · Canceled"
        case .subscriptionExpired:
            return "Subscription · Expired"
        case .subscriptionRefunded:
            return "Subscription · Refunded"
        case .subscriptionInReview:
            return "Subscription · In Review"
        @unknown default:
            return "License"
        }
    }

    private var tint: Color {
        switch state {
        case .trial:
            return .accentColor
        case .subscriptionActive:
            return .green
        case .subscriptionCanceled, .subscriptionInReview:
            return .orange
        case .subscriptionExpired, .subscriptionRefunded:
            return .red
        @unknown default:
            return .orange
        }
    }
}
