import Foundation

/// Talks to the LookInside injector running on one attached iOS device.
///
/// The transport is the one the host already uses to reach a LookInside server
/// on a device — a `FrameChannel` over a usbmuxd tunnel — pointed at the
/// injector's own port instead of the server's range. Nothing here touches a network
/// interface: usbmuxd carries the bytes over the cable and dials 127.0.0.1
/// inside the device, so the feature needs no Wi-Fi, no pairing beyond what
/// Xcode already set up, and no change to anybody's network configuration.
///
/// `@MainActor` because the usbmuxd client and the frame channel are both
/// given the main queue, so every callback arrives there. Making that explicit
/// is cheaper than defending the pending table with a lock that would only
/// ever be taken from one thread.
@MainActor
final class LKDeviceControlClient {
    /// Why a request did not produce an answer.
    enum Failure: LocalizedError {
        /// usbmuxd would not connect. By far the most common cause is the
        /// injector not running on the device, which is not an error state so
        /// much as the normal answer for a device that has never had it opened.
        case couldNotConnect(underlying: any Error)

        /// The channel closed while a request was in flight.
        case channelEnded

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
            case .timedOut:
                NSLocalizedString(
                    "The injector on the device accepted the request and did not answer it.",
                    comment: ""
                )
            case let .deviceReported(message):
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
    let deviceIdentifier: Int

    /// The device's serial number, used as its name in the interface.
    ///
    /// Shown rather than a friendly name on purpose: iOS 16 stopped giving an
    /// unentitled app the user's name for the device, so the injector has
    /// nothing better to report, and with two devices plugged in an
    /// unambiguous identifier beats a pretty one.
    let serialNumber: String

    /// The usbmuxd client the tunnel is opened through: the monitor's own,
    /// the one that enumerated the device (see `LKAttachedDeviceMonitor` for
    /// why it does not share the connection manager's).
    private let usbMuxClient: USBMuxClient

    private var channel: FrameChannel?

    /// Requests sent and not yet answered, by frame tag.
    private var pendingByFrameTag: [UInt32: (Result<Data, Failure>) -> Void] = [:]

    /// Tags start at 1 because the frame format reserves 0 for "no tag".
    private var nextFrameTag: UInt32 = 1

    init(deviceIdentifier: Int, serialNumber: String, usbMuxClient: USBMuxClient) {
        self.deviceIdentifier = deviceIdentifier
        self.serialNumber = serialNumber
        self.usbMuxClient = usbMuxClient
    }

    // MARK: - Connecting

    func connect() async throws {
        let tunnel: (fileDescriptor: Int32, initialBytes: Data) = try await withCheckedThrowingContinuation { continuation in
            usbMuxClient.connect(deviceID: deviceIdentifier, port: UInt16(LKDeviceControlWire.portNumber)) { result in
                switch result {
                case let .success(tunnel):
                    continuation.resume(returning: tunnel)
                case let .failure(error):
                    continuation.resume(throwing: Failure.couldNotConnect(underlying: error))
                }
            }
        }
        // Any payload size, as the server channel takes: a process list can
        // run long, and the device is the injector this build was paired with.
        let newChannel = FrameChannel(
            fileDescriptor: tunnel.fileDescriptor,
            queue: .main,
            maxPayloadSize: .max,
            initialBytes: tunnel.initialBytes
        )
        // Only answers are expected here. A frame of any other type is refused
        // rather than read: this channel's requests all travel the other way,
        // so one arriving would mean the two ends had swapped roles.
        newChannel.shouldAcceptFrame = { header in
            header.type == LKDeviceControlWire.responseFrameType
        }
        newChannel.onFrame = { [weak self] frame in
            // The channel calls back on the main queue, so this is already the
            // main thread; `MainActor.assumeIsolated` states that rather than
            // hopping and letting answers arrive out of order.
            MainActor.assumeIsolated {
                guard let self, let pending = self.pendingByFrameTag.removeValue(forKey: frame.tag) else { return }
                pending(.success(frame.payload))
            }
        }
        newChannel.onEnd = { [weak self, weak newChannel] _ in
            MainActor.assumeIsolated {
                guard let self, let newChannel, self.channel === newChannel else { return }
                self.channel = nil
                self.failAllPending(with: .channelEnded)
            }
        }
        newChannel.start()
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
        expecting _: Result.Type,
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

            channel.send(
                type: LKDeviceControlWire.requestFrameType,
                tag: frameTag,
                payload: requestData
            ) { [weak self] error in
                guard let error else { return }
                MainActor.assumeIsolated {
                    guard let self, let pending = self.pendingByFrameTag.removeValue(forKey: frameTag) else { return }
                    pending(.failure(.couldNotConnect(underlying: error)))
                }
            }
        }

        let outcome: LKDeviceControlOutcome<Result>
        do {
            outcome = try JSONDecoder().decode(LKDeviceControlOutcome<Result>.self, from: answer)
        } catch {
            throw Failure.malformedAnswer(command: command, underlying: error)
        }
        switch outcome {
        case let .succeeded(result):
            return result
        case let .failed(message):
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
}
