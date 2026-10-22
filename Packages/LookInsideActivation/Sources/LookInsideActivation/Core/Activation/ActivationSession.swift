import Foundation

public struct ActivationSession: Codable, Sendable, Equatable {
    public let sessionID: String
    public let licenseID: String
    public let orderID: String?
    public let email: String?
    public let deviceIdentifier: String
    public let token: String
    public let expiresAt: Date
    public let createdAt: Date

    public init(
        sessionID: String,
        licenseID: String,
        orderID: String?,
        email: String?,
        deviceIdentifier: String,
        token: String,
        expiresAt: Date,
        createdAt: Date
    ) {
        self.sessionID = sessionID
        self.licenseID = licenseID
        self.orderID = orderID
        self.email = email
        self.deviceIdentifier = deviceIdentifier
        self.token = token
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }
}
