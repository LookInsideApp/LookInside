//
//  LaunchDeviceList.swift
//  LookInside
//
//  How the launch window groups the apps it found by device, and which
//  device its sidebar selects. Kept free of AppKit views so it can be tested
//  on its own.
//

import Foundation

/// One device in the launch window's sidebar.
enum LaunchDeviceIdentity: Hashable {
    /// A device the app info named: its name, its OS and its kind.
    case reported(deviceDescription: String, osDescription: String, deviceType: LookinAppInfoDevice)
    /// Apps that sent no app info (an app in the background, or a Server
    /// whose version this Host does not support) and could not be placed on
    /// a reported device. `originGroupKey` names where their channels come
    /// from: the Simulator ports, the Mac ports or one USB device.
    case unidentified(originGroupKey: String)
}

/// One app of a scan, as the device list sees it.
struct LaunchDeviceListEntry<App> {
    let app: App
    /// The device the app's info names; nil when the app sent no info.
    let reportedDevice: LaunchDeviceIdentity?
    /// Where the app's channel comes from: the same key for every app on the
    /// Simulator ports, on the Mac ports, or on one USB device.
    let originGroupKey: String
    /// Whether a click opens the app: it is in the foreground and its Server
    /// version is supported.
    let isConnectable: Bool
}

/// The apps of one device, in scan order.
struct LaunchDeviceGroup<App> {
    let identity: LaunchDeviceIdentity
    var apps: [App]
    /// How many of `apps` a click opens.
    var connectableAppCount: Int
}

enum LaunchDeviceGrouping {
    /// Groups a scan's apps by device, devices in the order their first app
    /// was found.
    ///
    /// An app without info joins the one reported device that shares its
    /// origin (a background app on a USB device whose other apps answered),
    /// and otherwise gets a device of its own per origin: Simulator ports are
    /// shared by every running Simulator, so with two of them there is no
    /// telling which one the app runs on.
    static func groups<App>(of entries: [LaunchDeviceListEntry<App>]) -> [LaunchDeviceGroup<App>] {
        var reportedDevicesByOrigin: [String: [LaunchDeviceIdentity]] = [:]
        for entry in entries {
            guard let reportedDevice = entry.reportedDevice else { continue }
            var devices = reportedDevicesByOrigin[entry.originGroupKey, default: []]
            if !devices.contains(reportedDevice) {
                devices.append(reportedDevice)
            }
            reportedDevicesByOrigin[entry.originGroupKey] = devices
        }

        var groups: [LaunchDeviceGroup<App>] = []
        var groupIndexByIdentity: [LaunchDeviceIdentity: Int] = [:]
        for entry in entries {
            let identity: LaunchDeviceIdentity
            if let reportedDevice = entry.reportedDevice {
                identity = reportedDevice
            } else if let devicesOfOrigin = reportedDevicesByOrigin[entry.originGroupKey], devicesOfOrigin.count == 1 {
                identity = devicesOfOrigin[0]
            } else {
                identity = .unidentified(originGroupKey: entry.originGroupKey)
            }
            let groupIndex: Int
            if let existingIndex = groupIndexByIdentity[identity] {
                groupIndex = existingIndex
            } else {
                groupIndex = groups.count
                groupIndexByIdentity[identity] = groupIndex
                groups.append(LaunchDeviceGroup(identity: identity, apps: [], connectableAppCount: 0))
            }
            groups[groupIndex].apps.append(entry.app)
            if entry.isConnectable {
                groups[groupIndex].connectableAppCount += 1
            }
        }
        return groups
    }
}

/// Which device the sidebar selects across scans.
///
/// Until the user picks one, the first device with an app a click opens is
/// selected, and that selection stays put while devices come and go around
/// it. A device the user picked stays selected through every scan that
/// still finds it, and is selected again when it comes back. When the
/// selected device disappears, the one after it in the previous scan takes
/// over, or the one before it when it was the last.
struct LaunchDeviceSelection {
    private(set) var selectedDevice: LaunchDeviceIdentity?
    private var userChosenDevice: LaunchDeviceIdentity?
    private var previousDeviceOrder: [LaunchDeviceIdentity] = []

    /// The user picked `device` in the sidebar.
    mutating func userDidSelect(_ device: LaunchDeviceIdentity) {
        userChosenDevice = device
        selectedDevice = device
    }

    /// Applies a new scan's devices, in sidebar order.
    mutating func update<App>(with groups: [LaunchDeviceGroup<App>]) {
        let currentDevices = groups.map(\.identity)
        defer { previousDeviceOrder = currentDevices }

        if let userChosenDevice, currentDevices.contains(userChosenDevice) {
            selectedDevice = userChosenDevice
            return
        }
        if let selectedDevice, currentDevices.contains(selectedDevice) {
            return
        }
        if let vanishedDevice = selectedDevice,
           let replacement = Self.replacement(for: vanishedDevice, previousOrder: previousDeviceOrder, currentDevices: currentDevices)
        {
            selectedDevice = replacement
            return
        }
        selectedDevice = groups.first { $0.connectableAppCount > 0 }?.identity ?? currentDevices.first
    }

    /// The nearest device to `vanishedDevice` in the previous order that is
    /// still there: the following ones first, then the preceding ones.
    private static func replacement(
        for vanishedDevice: LaunchDeviceIdentity,
        previousOrder: [LaunchDeviceIdentity],
        currentDevices: [LaunchDeviceIdentity]
    ) -> LaunchDeviceIdentity? {
        guard let vanishedIndex = previousOrder.firstIndex(of: vanishedDevice) else {
            return nil
        }
        let followingDevices = previousOrder[previousOrder.index(after: vanishedIndex)...]
        if let following = followingDevices.first(where: currentDevices.contains) {
            return following
        }
        let precedingDevices = previousOrder[..<vanishedIndex].reversed()
        return precedingDevices.first(where: currentDevices.contains)
    }
}
