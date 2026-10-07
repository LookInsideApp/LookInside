import Foundation

public struct ActivationUIConfiguration: Sendable, Equatable {
    public let windowTitle: String
    public let requestedFeature: String
    public let frameworkVersion: String
    public let currentAccessCopy: String
    public let canceledSubscriptionCopy: String
    public let refundedPurchaseCopy: String
    public let multipleDevicesCopy: String

    public init(
        windowTitle: String? = nil,
        requestedFeature: String = "swiftui.support",
        frameworkVersion: String = "1.0.0",
        currentAccessCopy: String? = nil,
        canceledSubscriptionCopy: String? = nil,
        refundedPurchaseCopy: String? = nil,
        multipleDevicesCopy: String? = nil
    ) {
        self.windowTitle = windowTitle ?? String(localized: "LookInside Activation", bundle: .module)
        self.requestedFeature = requestedFeature
        self.frameworkVersion = frameworkVersion
        self.currentAccessCopy =
            currentAccessCopy ?? String(localized: "Current access remains available until", bundle: .module)
        self.canceledSubscriptionCopy =
            canceledSubscriptionCopy
                ?? String(
                    localized: "A new certificate will not be issued after expiry because this subscription is canceled.",
                    bundle: .module
                )
        self.refundedPurchaseCopy =
            refundedPurchaseCopy
                ?? String(
                    localized: "A new certificate will not be issued after expiry because this purchase was refunded.",
                    bundle: .module
                )
        self.multipleDevicesCopy =
            multipleDevicesCopy
                ?? String(
                    localized: "This license has been activated on multiple devices. Usage may be reviewed manually.",
                    bundle: .module
                )
    }
}
