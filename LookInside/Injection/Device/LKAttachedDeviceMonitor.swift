import AppKit

/// Which iOS devices are attached over USB right now.
///
/// A monitor of its own rather than a reading off `LKConnectionManager`, which
/// tracks the same attaches for a different purpose (it turns each one into
/// five server ports to probe) and keeps the result private.
///
/// It runs its **own** `Lookin_PTUSBHub`. The shared hub posts attach
/// notifications for already-connected devices when it starts listening — which
/// the connection manager causes at launch — so an observer registered later
/// sees nothing until the next replug. A private hub starts listening when this
/// does, and therefore reports the devices that are already there.
@MainActor
final class LKAttachedDeviceMonitor {
    struct Device: Hashable {
        /// usbmuxd's handle for the device. Not stable across replugs.
        let identifier: NSNumber

        /// The device's serial number, which is what identifies it to a person.
        let serialNumber: String
    }

    static let shared = LKAttachedDeviceMonitor()

    /// Attached devices, in the order they were reported.
    private(set) var devices: [Device] = []

    private let usbHub = Lookin_PTUSBHub()
    private var hasStartedListening = false
    private var observers: [any NSObjectProtocol] = []

    /// The hub a client should reach these devices through — the one that
    /// enumerated them.
    var connectionHub: Lookin_PTUSBHub { usbHub }

    private init() {}

    /// Starts listening, and waits long enough for usbmuxd to report what is
    /// already plugged in.
    ///
    /// The wait is why this is `async`. usbmuxd answers a fresh listen with one
    /// attach message per connected device, and those arrive over a socket
    /// rather than synchronously — so a caller that listed immediately would
    /// find nothing on the first run and everything on the second. The host
    /// already makes this allowance in its launch window, where the comment
    /// records the measurement: about 0.1 seconds in practice, with 0.2 taken
    /// for margin.
    func startAndWaitForInitialDevices() async {
        guard !hasStartedListening else { return }
        hasStartedListening = true

        let notificationCenter = NotificationCenter.default
        observers.append(
            notificationCenter.addObserver(
                forName: .Lookin_PTUSBDeviceDidAttach,
                object: usbHub,
                queue: .main
            ) { [weak self] notification in
                MainActor.assumeIsolated { self?.handleAttach(notification) }
            }
        )
        observers.append(
            notificationCenter.addObserver(
                forName: .Lookin_PTUSBDeviceDidDetach,
                object: usbHub,
                queue: .main
            ) { [weak self] notification in
                MainActor.assumeIsolated { self?.handleDetach(notification) }
            }
        )

        usbHub.listen(on: .main, onStart: nil, onEnd: nil)
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    private func handleAttach(_ notification: Notification) {
        guard let identifier = notification.userInfo?["DeviceID"] as? NSNumber else { return }
        let properties = notification.userInfo?["Properties"] as? [String: Any]

        // A simulator never shows up here, but a Mac paired over the network
        // does, and reaching it is not what this feature is for — the injector
        // is an iOS app on a cable.
        if let connectionType = properties?["ConnectionType"] as? String, connectionType != "USB" {
            return
        }

        let serialNumber = properties?["SerialNumber"] as? String ?? identifier.stringValue
        guard !devices.contains(where: { $0.identifier == identifier }) else { return }
        devices.append(Device(identifier: identifier, serialNumber: serialNumber))
    }

    private func handleDetach(_ notification: Notification) {
        guard let identifier = notification.userInfo?["DeviceID"] as? NSNumber else { return }
        devices.removeAll { $0.identifier == identifier }
    }
}
