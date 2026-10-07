import LookInsideActivation
import SwiftUI

/// Status-aware license detail block shared by `LicenseSummaryView`
/// (the activation flow's "you're in" panel) and the standalone
/// `LicenseStatusView` exposed to the host app.
struct LicenseDetailRows: View {
    let status: EntitlementStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                LicenseStatusBadge(state: status.displayState)
                Spacer(minLength: 0)
            }

            if let issuedTo = status.license.issuedTo, !issuedTo.isEmpty {
                LicenseDetailRow(
                    icon: "person.crop.circle",
                    title: "Licensed to",
                    value: issuedTo
                )
            }

            LicenseDetailRow(
                icon: "calendar",
                title: accessRowTitle,
                value: accessRowValue
            )

            if let warning = status.warningMessage ?? status.license.deviceWarning,
               !warning.isEmpty
            {
                LicenseDetailRow(
                    icon: "exclamationmark.triangle",
                    title: "Notice",
                    value: warning,
                    valueColor: .orange
                )
            }
        }
    }

    private var accessRowTitle: LocalizedStringKey {
        switch status.displayState {
        case .trial:
            return "Trial"
        case .subscriptionActive:
            return "Renews on"
        case .subscriptionCanceled:
            return "Access until"
        case .subscriptionExpired, .subscriptionRefunded:
            return "Ended on"
        case .subscriptionInReview:
            return "Access until"
        @unknown default:
            return "Access until"
        }
    }

    private var accessRowValue: String {
        // Show the entitlement end date (subscription `current_period_end_date`
        // or trial `expires_at`). Certificate leases are an internal renewal pulse.
        let endsAt = status.entitlementEndsAt
        switch status.displayState {
        case let .trial(daysRemaining):
            let startedAt = status.license.issuedAt.formatted(date: .long, time: .omitted)
            guard let endsAt else {
                return String(localized: "Started \(startedAt)", bundle: .activationUI)
            }
            let endedAt = endsAt.formatted(date: .long, time: .omitted)
            if daysRemaining <= 0 {
                return String(localized: "Started \(startedAt) · Ended \(endedAt)", bundle: .activationUI)
            }
            return String(
                localized: "Started \(startedAt) · Ends \(endedAt) · \(daysRemaining) days left", bundle: .activationUI
            )
        case .subscriptionActive,
             .subscriptionCanceled,
             .subscriptionExpired,
             .subscriptionRefunded,
             .subscriptionInReview:
            guard let endsAt else {
                return String(localized: "Never Expires", bundle: .activationUI)
            }
            return endsAt.formatted(date: .long, time: .omitted)
        @unknown default:
            guard let endsAt else {
                return String(localized: "Never Expires", bundle: .activationUI)
            }
            return endsAt.formatted(date: .long, time: .omitted)
        }
    }
}
