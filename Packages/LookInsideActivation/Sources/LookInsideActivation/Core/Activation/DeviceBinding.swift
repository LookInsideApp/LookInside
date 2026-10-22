import Foundation

public struct DeviceBinding: Codable, Sendable, Equatable {
    public let licenseID: String
    public let udid: String
    public let machineName: String?
    public let hardwareModel: String
    public let operatingSystemVersion: String
    public let appBundleID: String
    public let status: DeviceBindingStatus
    public let firstSeenAt: Date
    public let lastSeenAt: Date
    public let reviewNote: String?

    public init(
        licenseID: String,
        udid: String,
        machineName: String? = nil,
        hardwareModel: String,
        operatingSystemVersion: String,
        appBundleID: String,
        status: DeviceBindingStatus = .active,
        firstSeenAt: Date,
        lastSeenAt: Date,
        reviewNote: String? = nil
    ) {
        self.licenseID = licenseID
        self.udid = udid
        self.machineName = machineName
        self.hardwareModel = hardwareModel
        self.operatingSystemVersion = operatingSystemVersion
        self.appBundleID = appBundleID
        self.status = status
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
        self.reviewNote = reviewNote
    }
}
