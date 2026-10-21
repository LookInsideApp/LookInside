//
//  ReconnectPolicies.swift
//  LookInsideHostCore
//
//  Pure decisions of the Connection layer around a lost or silent channel:
//  when a probe that timed out means the channel is dead, which app a live
//  window takes over after its channel ended, and what the Server's
//  application state push says.
//

import Foundation

/// When a channel that stopped answering is closed.
///
/// Over usbmuxd a channel whose other end went away often never reports an
/// end and keeps claiming to be connected; reusing it forever is what kept
/// a port from being probed again until the Host restarted. A probe (ping,
/// app info) that times out is the hint, but not proof: an app busy with a
/// large refresh can miss a short ping on a healthy channel. Such a channel
/// still receives frames, so it is only closed when nothing arrived on it
/// for `silenceBeforeClosing` as well.
public struct ChannelLivenessPolicy: Sendable {
    public static let defaultSilenceBeforeClosing: TimeInterval = 5

    public let probeRequestTypes: Set<UInt32>
    public let silenceBeforeClosing: TimeInterval

    public init(probeRequestTypes: Set<UInt32>, silenceBeforeClosing: TimeInterval = Self.defaultSilenceBeforeClosing) {
        self.probeRequestTypes = probeRequestTypes
        self.silenceBeforeClosing = silenceBeforeClosing
    }

    /// Whether a request of `requestType` that just timed out ends its
    /// channel, on which bytes last arrived `secondsSinceLastReceive` ago.
    public func shouldCloseChannel(afterTimeoutOfRequestType requestType: UInt32, secondsSinceLastReceive: TimeInterval) -> Bool {
        probeRequestTypes.contains(requestType) && secondsSinceLastReceive >= silenceBeforeClosing
    }
}

/// What identifies an inspected app across a reconnect: its process is
/// gone, so nothing that names the process (the app info identifier, the
/// port) carries over.
public struct InspectedAppIdentity: Equatable, Sendable {
    public var appName: String?
    public var bundleIdentifier: String?
    public var deviceDescription: String?
    /// "iPhone16,2", "Mac15,14"; nil from Servers that predate it.
    public var deviceModelIdentifier: String?
    public var osDescription: String?
    /// `LookinAppInfoDevice`'s raw value.
    public var deviceType: Int

    public init(
        appName: String?,
        bundleIdentifier: String?,
        deviceDescription: String?,
        deviceModelIdentifier: String?,
        osDescription: String?,
        deviceType: Int
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.deviceDescription = deviceDescription
        self.deviceModelIdentifier = deviceModelIdentifier
        self.osDescription = osDescription
        self.deviceType = deviceType
    }
}

/// One app a reconnect scan found.
public struct ReconnectCandidate: Equatable, Sendable {
    public var identity: InspectedAppIdentity
    /// False for an app the Host cannot inspect: no channel (its Server is
    /// too old or too new) or a version error. Taking such an app over would
    /// clear the connection-loss banner and leave the window with nothing to
    /// watch, so it would never reconnect again.
    public var canBeInspected: Bool

    public init(identity: InspectedAppIdentity, canBeInspected: Bool) {
        self.identity = identity
        self.canBeInspected = canBeInspected
    }
}

/// Which app found by a reconnect scan a live window takes over.
public enum ReconnectTargetSelection {
    /// The index in `candidates` of the one app that is `target` again, or
    /// nil: none is, or several are and picking one by port order could hand
    /// the window to the wrong process.
    ///
    /// The fields `InspectedAppInfo.isEqual(to:)` compares (app name, device
    /// description, OS description, device type) must match, with its
    /// Objective-C string semantics (a nil string matches nothing). The
    /// bundle identifier and the device model identifier must also match when
    /// both sides report one; Servers that predate a field report nil.
    public static func candidateIndex(for target: InspectedAppIdentity, among candidates: [ReconnectCandidate]) -> Int? {
        let matchingIndices = candidates.indices.filter { index in
            let candidate = candidates[index]
            return candidate.canBeInspected && isSameApp(target, candidate.identity)
        }
        guard matchingIndices.count == 1 else {
            return nil
        }
        return matchingIndices.first
    }

    static func isSameApp(_ firstIdentity: InspectedAppIdentity, _ secondIdentity: InspectedAppIdentity) -> Bool {
        fieldsOfIsEqualMatch(firstIdentity, secondIdentity)
            && optionalFieldsMatch(firstIdentity.bundleIdentifier, secondIdentity.bundleIdentifier)
            && optionalFieldsMatch(firstIdentity.deviceModelIdentifier, secondIdentity.deviceModelIdentifier)
    }

    /// Equal when both are reported; a side that reports nothing (or an
    /// empty string) does not decide.
    static func optionalFieldsMatch(_ firstValue: String?, _ secondValue: String?) -> Bool {
        guard let firstValue, !firstValue.isEmpty, let secondValue, !secondValue.isEmpty else {
            return true
        }
        return firstValue == secondValue
    }

    /// `InspectedAppInfo.isEqual(to:)`.
    static func fieldsOfIsEqualMatch(_ firstIdentity: InspectedAppIdentity, _ secondIdentity: InspectedAppIdentity) -> Bool {
        objectiveCStringsEqual(firstIdentity.appName, secondIdentity.appName)
            && objectiveCStringsEqual(firstIdentity.deviceDescription, secondIdentity.deviceDescription)
            && objectiveCStringsEqual(firstIdentity.osDescription, secondIdentity.osDescription)
            && firstIdentity.deviceType == secondIdentity.deviceType
    }

    /// `[receiver isEqualToString:argument]`: NO when either is nil.
    static func objectiveCStringsEqual(_ receiver: String?, _ argument: String?) -> Bool {
        guard let receiver, let argument else { return false }
        return receiver == argument
    }
}

/// The payload of the Server's application state push
/// (`LookinPush_ApplicationStateChanged`, 307): a dictionary whose
/// `LookinParam_ApplicationIsActive` ("active") entry is a boxed BOOL.
public enum ApplicationStatePush {
    /// `LookinParam_ApplicationIsActive` in LookinDefines.h.
    public static let isActiveKey = "active"

    /// Whether the push says the app is active; nil for a payload without
    /// the entry, which the Host ignores.
    public static func isActive(inPayload payload: Any?) -> Bool? {
        guard let dictionary = payload as? NSDictionary,
              let value = dictionary[isActiveKey] as? NSNumber
        else {
            return nil
        }
        return value.boolValue
    }
}
