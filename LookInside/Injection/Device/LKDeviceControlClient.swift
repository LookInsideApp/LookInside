import Foundation

/// Talks to the LookInside injector running on one attached iOS device.
///
/// The transport is the one the host already uses to reach a LookInside server
/// on a device — `Lookin_PTChannel` over usbmuxd — pointed at the injector's own
/// port instead of the server's range. Nothing here touches a network
/// interface: usbmuxd carries the bytes over the cable and dials 127.0.0.1
/// inside the device, so the feature needs no Wi-Fi, no pairing beyond what
/// Xcode already set up, and no change to anybody's network configuration.
///
/// `@MainActor` because `Lookin_PTChannel.channelWithDelegate:` binds the
/// channel to the main queue's protocol object, so every delegate callback
/// arrives there. Making that explicit is cheaper than defending the pending
/// table with a lock that would only ever be taken from one thread.
@MainActor
final class LKDeviceControlClient: NSObject, Lookin_PTChannelDelegate {
    /// Why a request did not produce an answer.
    enum Failure: LocalizedError {
        /// usbmuxd would not connect. By far the most common cause is the
        /// injector not running on the device, which is not an error state so
        /// much as the normal answer for a device that has never had it opened.
        case couldNotConnect(underlying: any Error)

        /// The channel closed while a request was in flight.
        case channelEnded

        /// Peertalk would not hand out a channel at all.
        ///
        /// Not reachable in practice — the factory allocates and returns, and
        /// the optional is only an artefact of Peertalk's headers carrying no
        /// nullability annotations. Stated as a case rather than force
        /// unwrapped, so an impossible state is reported instead of crashing
        /// the app.
        case channelUnavailable

        /// The device accepted the request and never answered.
        case timedOut(command: LKDeviceControlCommand)

        /// The injector answered, and its answer was that it would not do it.
        case deviceReported(message: String)

        /// The injector's answer did not decode. Reported as its own case
        /// because the remedy is a version mismatch between the two builds, not
        /// anything the user did.
        case malformedAnswer(command: LKDeviceControlCommand, underlying: any Error)

        var errorDescription: String? {
            switch self {
            case .couldNotConnect:
                NSLocalizedString(
                    "LookInside could not reach the injector on that device. Open the LookInside Injector app on the device once — it stays available in the background afterwards, until the device restarts.",
                    comment: ""
                )
            case .channelEnded:
                NSLocalizedString(
                    "The connection to the injector on the device closed before it answered.",
                    comment: ""
                )
            case .channelUnavailable:
                NSLocalizedString(
                    "LookInside could not open a USB connection to the device.",
                    comment: ""
                )
            case .timedOut:
                NSLocalizedString(
                    "The injector on the device accepted the request and did not answer it.",
                    comment: ""
                )
            case .deviceReported(let message):
                message
            case .malformedAnswer:
                NSLocalizedString(
                    "The injector on the device sent an answer LookInside could not read. The two are probably different versions.",
                    comment: ""
                )
            }
        }
    }

    /// usbmuxd's identifier for the device, as it appears in the attach
    /// notification. Not stable across replugs, which is why the serial number
    /// is what gets shown to the user.
    let deviceIdentifier: NSNumber

    /// The device's serial number, used as its name in the interface.
    ///
    /// Shown rather than a friendly name on purpose: iOS 16 stopped giving an
    /// unentitled app the user's name for the device, so the injector has
    /// nothing better to report, and with two devices plugged in an
    /// unambiguous identifier beats a pretty one.
    let serialNumber: String

    /// The usbmuxd connection these channels are opened through.
    ///
    /// The monitor's own hub rather than `Lookin_PTUSBHub.sharedHub`, and for a
    /// reason worth keeping: the shared hub posts its attach notifications for
    /// already-connected devices only when it *starts* listening, which the
    /// host's connection manager triggers at launch. A monitor built later
    /// would see nothing until the next replug, so it runs a hub of its own —
    /// and a client reaching a device that hub enumerated should go through the
    /// same one.
    private let usbHub: Lookin_PTUSBHub

    private var channel: Lookin_PTChannel?

    /// Requests sent and not yet answered, by frame tag.
    private var pendingByFrameTag: [UInt32: (Result<Data, Failure>) -> Void] = [:]

    /// Tags start at 1 because Peertalk reserves 0 for "no tag".
    private var nextFrameTag: UInt32 = 1

    init(deviceIdentifier: NSNumber, serialNumber: String, usbHub: Lookin_PTUSBHub) {
        self.deviceIdentifier = deviceIdentifier
        self.serialNumber = serialNumber
        self.usbHub = usbHub
        super.init()
    }

    // MARK: - Connecting

    func connect() async throws {
        // Swift imports `+[Lookin_PTChannel channelWithDelegate:]` as an
        // initializer, the way it does `+[NSString stringWithFormat:]`. That
        // factory is the one to use rather than `init()`: it binds the channel
        // to the main queue's protocol object — which is what puts every
        // delegate callback on the main thread, and therefore what makes this
        // class's `@MainActor` isolation true rather than hopeful.
        guard let newChannel = Lookin_PTChannel(delegate: self) else {
            throw Failure.channelUnavailable
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            newChannel.connect(
                toPort: LKDeviceControlWire.portNumber,
                overUSBHub: usbHub,
                deviceID: deviceIdentifier
            ) { error in
                if let error {
                    newChannel.close()
                    continuation.resume(throwing: Failure.couldNotConnect(underlying: error))
                } else {
                    continuation.resume()
                }
            }
        }
        channel = newChannel
    }

    func close() {
        channel?.close()
        channel = nil
        failAllPending(with: .channelEnded)
    }

    // MARK: - Commands

    /// Whether this device can inject, and when it cannot, why.
    func injectionCapability() async throws -> LKDeviceControlCapability {
        try await send(.injectionCapability, expecting: LKDeviceControlCapability.self, timeout: Self.quickTimeout)
    }

    /// What the device can be asked to inject into.
    func processList() async throws -> [LKDeviceControlProcess] {
        try await send(.processList, expecting: [LKDeviceControlProcess].self, timeout: Self.listTimeout)
    }

    /// Loads the device's own payload into one of its processes.
    ///
    /// Throwing and the returned result are different things: a throw is the
    /// request not arriving or not being answered, the result is the injection
    /// itself ending one way or another. Only the second has a remedy worth
    /// naming to the user.
    func injectIntoProcess(withIdentifier processIdentifier: pid_t) async throws -> LKDeviceControlInjectionResult {
        try await send(
            .injectIntoProcess,
            processIdentifier: processIdentifier,
            expecting: LKDeviceControlInjectionResult.self,
            timeout: Self.injectionTimeout
        )
    }

    /// Capability and the process list are a round trip over a cable and a
    /// `proc_listallpids` sweep; neither should ever be slow.
    private static let quickTimeout: TimeInterval = 10
    private static let listTimeout: TimeInterval = 20

    /// The device's own verdict budget is twenty seconds — it waits that long
    /// for the injected thread to report what its `dlopen` did — and it has
    /// staging and an assertion to take before that starts. A budget shorter
    /// than the device's own would report a timeout for an injection that was
    /// still going to succeed.
    private static let injectionTimeout: TimeInterval = 45

    // MARK: - Sending

    private func send<Result: Codable & Hashable>(
        _ command: LKDeviceControlCommand,
        processIdentifier: pid_t? = nil,
        expecting resultType: Result.Type,
        timeout: TimeInterval
    ) async throws -> Result {
        guard let channel, channel.isConnected else {
            throw Failure.channelEnded
        }

        let request = LKDeviceControlRequest(command, processIdentifier: processIdentifier)
        let requestData = try JSONEncoder().encode(request)

        let frameTag = nextFrameTag
        nextFrameTag += 1

        let answer: Data = try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            pendingByFrameTag[frameTag] = { result in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(with: result)
            }

            // The device may simply never answer — a wedged injection, a
            // process that went away mid-request — and without this the sheet
            // would spin for as long as the app runs.
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard let self, let pending = pendingByFrameTag.removeValue(forKey: frameTag) else { return }
                pending(.failure(.timedOut(command: command)))
            }

            channel.sendFrame(
                ofType: LKDeviceControlWire.requestFrameType,
                tag: frameTag,
                withPayload: (requestData as NSData).createReferencingDispatchData()
            ) { [weak self] error in
                guard let error else { return }
                guard let self, let pending = pendingByFrameTag.removeValue(forKey: frameTag) else { return }
                pending(.failure(.couldNotConnect(underlying: error)))
            }
        }

        let outcome: LKDeviceControlOutcome<Result>
        do {
            outcome = try JSONDecoder().decode(LKDeviceControlOutcome<Result>.self, from: answer)
        } catch {
            throw Failure.malformedAnswer(command: command, underlying: error)
        }
        switch outcome {
        case .succeeded(let result):
            return result
        case .failed(let message):
            throw Failure.deviceReported(message: message)
        }
    }

    private func failAllPending(with failure: Failure) {
        let pending = pendingByFrameTag
        pendingByFrameTag.removeAll()
        for complete in pending.values {
            complete(.failure(failure))
        }
    }

    // MARK: - Lookin_PTChannelDelegate

    /// Only answers are expected here. A frame of any other type is refused
    /// rather than read: this channel's requests all travel the other way, so
    /// one arriving would mean the two ends had swapped roles.
    nonisolated func ioFrameChannel(
        _: Lookin_PTChannel!,
        shouldAcceptFrameOfType type: UInt32,
        tag _: UInt32,
        payloadSize _: UInt32
    ) -> Bool {
        type == LKDeviceControlWire.responseFrameType
    }

    nonisolated func ioFrameChannel(
        _: Lookin_PTChannel!,
        didReceiveFrameOfType _: UInt32,
        tag: UInt32,
        payload: Lookin_PTData!
    ) {
        // Peertalk binds this channel to the main queue, so this is already the
        // main thread; `MainActor.assumeIsolated` states that rather than
        // hopping and letting answers arrive out of order.
        let answer: Data = if let payload, payload.length > 0, let bytes = payload.data {
            Data(bytes: bytes, count: payload.length)
        } else {
            Data()
        }
        MainActor.assumeIsolated {
            guard let pending = pendingByFrameTag.removeValue(forKey: tag) else { return }
            pending(.success(answer))
        }
    }

    nonisolated func ioFrameChannel(_: Lookin_PTChannel!, didEndWithError _: Error!) {
        MainActor.assumeIsolated {
            channel = nil
            failAllPending(with: .channelEnded)
        }
    }
}
