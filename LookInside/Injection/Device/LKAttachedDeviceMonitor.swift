import AppKit

/// Which iOS devices are attached over USB right now.
///
/// A monitor of its own rather than a reading off `LKConnectionManager`, which
/// tracks the same attaches for a different purpose (it turns each one into
/// five server ports to probe) and keeps the result private.
///
/// It runs its **own** `USBMuxClient`. usbmuxd answers a Listen request
/// with one Attached broadcast per device already connected, and only on the
/// socket that sent it — so the connection manager's subscription, opened at
/// launch, says nothing to an observer that arrives later. A private client
/// listens when this starts, and therefore reports the devices already there.
@MainActor
final class LKAttachedDeviceMonitor {
    struct Device: Hashable {
        /// usbmuxd's handle for the device. Not stable across replugs.
        let identifier: Int

        /// The device's serial number, which is what identifies it to a person.
        let serialNumber: String
    }

    static let shared = LKAttachedDeviceMonitor()

    /// Attached devices, in the order they were reported.
    private(set) var devices: [Device] = []

    private let usbMuxClient = USBMuxClient(queue: .main)
    private var hasStartedListening = false

    /// The usbmuxd client a control client should reach these devices
    /// through — the one that enumerated them.
    var connectionClient: USBMuxClient {
        usbMuxClient
    }

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

        usbMuxClient.startListening { [weak self] event in
            MainActor.assumeIsolated { self?.handle(event) }
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    private func handle(_ event: USBMuxClient.Event) {
        switch event {
        case let .attached(identifier, properties):
            // Deliberately **not** filtered by `ConnectionType`. A `Network`
            // entry is an iOS device paired over Wi-Fi, not some other kind of
            // machine, and usbmuxd's Connect reaches one exactly the same way —
            // so filtering to `USB` would hide a jailbroken iPhone that
            // happened to be off the cable. The host's own
            // `LKConnectionManager` does not filter either, and this list has
            // to agree with it: a device this skipped could still have its
            // injected server found afterwards, which would read as the
            // injector list being wrong.
            let serialNumber = (properties["Properties"] as? [String: Any])?["SerialNumber"] as? String
                ?? String(identifier)
            guard !devices.contains(where: { $0.identifier == identifier }) else { return }
            devices.append(Device(identifier: identifier, serialNumber: serialNumber))
        case let .detached(identifier):
            devices.removeAll { $0.identifier == identifier }
        }
    }
}
