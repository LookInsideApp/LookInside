import Darwin
import Foundation
import IOKit

enum ActivationDeviceFingerprint {
    /// The helper reported its own bundle identifier as `appBundleID`; the
    /// runtime passes the same value so device bindings stay unchanged.
    ///
    /// Throws `ActivationError.activationFailed` when IOKit does not report
    /// this Mac's `IOPlatformUUID`; activation needs it to bind the license.
    static func current(
        appBundleID: String = ActivationConfiguration.helperBundleIdentifier,
        platformUUID: () -> String? = readPlatformUUID
    ) throws -> DeviceFingerprint {
        let processInfo = ProcessInfo.processInfo
        guard let deviceID = platformUUID(), deviceID.isEmpty == false else {
            throw ActivationError.activationFailed(
                "LookInside could not read this Mac's hardware identifier, which activation requires."
            )
        }
        return DeviceFingerprint(
            deviceID: deviceID,
            hardwareModel: hardwareModel(),
            operatingSystemVersion: processInfo.operatingSystemVersionString,
            appBundleID: appBundleID
        )
    }

    /// `IOPlatformUUID` from the registry, or `nil` when it is unavailable.
    static func readPlatformUUID() -> String? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        guard service != 0 else {
            return nil
        }
        defer { IOObjectRelease(service) }

        return IORegistryEntryCreateCFProperty(
            service,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String
    }

    private static func hardwareModel() -> String {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0 else {
            return "Mac"
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &buffer, &size, nil, 0) == 0 else {
            return "Mac"
        }
        let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }
}
