//
//  ConnectionManager.swift
//  LookInside
//
//  Created by Li Kai on 2018/11/2.
//  https://lookin.work
//
//  The inspected app runs the Server; LookInside is the client.
//
//  - Moving the app to the background does not close its Server channel; the
//    port stays taken, but the app may not run code.
//  - Killing the app closes the channel and frees the port.
//  - Every app in every Simulator on a Mac shares one range of ports
//    (47164-47169): the first app to start takes 47164, the next 47165, and
//    so on. AppKit apps on the Mac use 47170-47174.
//  - Every app on one USB device shares 47175-47179; each device has its own
//    range, so apps on two devices can both take 47175.
//
//  Channels deliver frames, send completions and their end on the main
//  queue, a TCP connect finishes before it returns, and the usbmuxd client
//  calls back on the main queue, so all state here lives on the main actor.
//

import AppKit
import LookInsideHostCore
import FoundationToolbox

/// A push frame the Server sent without a request.
struct ConnectionPush {
    let channel: ServerChannel
    let type: UInt32
    let data: Any?
}

/// Connection state the manager keeps for one channel.
@MainActor
final class ServerChannelConnectionState {
    /// Requests sent on this channel whose responses have not all arrived.
    var activeRequests: [ConnectionRequest] = []
    let licenseHandshake = LicenseHandshakeGate()
    /// Identifies this channel to the activation runtime's signing policy,
    /// which remembers a failed handshake per channel.
    let licenseChannelID = UUID().uuidString
    /// The release the Server reported in its last 220 reply; nil before
    /// the first handshake. Drives the upgrade hint only.
    var serverRelease: ServerRelease?

    func activeRequest(type: UInt32, tag: UInt32) -> ConnectionRequest? {
        activeRequests.first { $0.type == type && $0.tag == tag }
    }

    func remove(_ request: ConnectionRequest) {
        activeRequests.removeAll { $0 === request }
    }
}

/// One port the Host tries, and the channel connected on it.
@MainActor
private final class ConnectionPort {
    let number: Int32
    let kind: ServerChannelKind
    var connectedChannel: ServerChannel?

    init(number: Int32, kind: ServerChannelKind) {
        self.number = number
        self.kind = kind
    }
}

@Loggable(.internal, subsystem: "com.lookinside.app")
@MainActor
final class ConnectionManager: NSObject {
    @objc(sharedInstance)
    static let shared = ConnectionManager()

    private let simulatorPorts: [ConnectionPort]
    private let macPorts: [ConnectionPort]
    private var usbPorts: [ConnectionPort] = []
    private let usbMuxClient = USBMuxClient(queue: .main)

    private let channelWillEndBroadcaster = AsyncBroadcaster<ServerChannel>()
    private let pushBroadcaster = AsyncBroadcaster<ConnectionPush>()

    /// Totals for the log line of a large multi-frame response.
    private var receivedResponseBytes = 0
    private var responseStartTime: CFTimeInterval = 0

    override private init() {
        simulatorPorts = (Int32(LookinSimulatorIPv4PortNumberStart) ... Int32(LookinSimulatorIPv4PortNumberEnd)).map {
            ConnectionPort(number: $0, kind: .simulator)
        }
        macPorts = (Int32(LookinMacIPv4PortNumberStart) ... Int32(LookinMacIPv4PortNumberEnd)).map {
            ConnectionPort(number: $0, kind: .mac)
        }
        super.init()

        startListeningForUSBDevices()
        let center = NotificationCenter.default
        center.addObserver(
            forName: SwiftUISupportGatekeeper.activationStateDidChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            runOnMain { self?.handleActivationStateDidChange() }
        }
        center.addObserver(
            forName: SwiftUISupportGatekeeper.licenseHandshakeAvailabilityDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            runOnMain { self?.handleLicenseHandshakeAvailabilityDidChange() }
        }
    }

    // MARK: - Events

    /// Channels that ended (the app was killed, the USB cable unplugged, or
    /// the Host closed the channel), delivered once the socket is closed.
    func channelWillEndEvents() -> AsyncStream<ServerChannel> {
        channelWillEndBroadcaster.subscribe()
    }

    /// Push frames from the Server.
    func pushEvents() -> AsyncStream<ConnectionPush> {
        pushBroadcaster.subscribe()
    }

    // MARK: - Connecting

    /// Connects every port that may have a Server and returns the connected
    /// channels: Simulator ports first, then Mac ports, then USB ports. A
    /// channel can be connected although its app is in the background and
    /// cannot answer.
    func connectAllPorts() async -> [ServerChannel] {
        await withCheckedContinuation { continuation in
            connectAllPorts { continuation.resume(returning: $0) }
        }
    }

    /// Callback form of `connectAllPorts()`. A TCP connect finishes before
    /// it returns, so with no USB device the completion runs synchronously.
    func connectAllPorts(completion: @escaping ([ServerChannel]) -> Void) {
        let ports = simulatorPorts + macPorts + usbPorts
        var channels = [ServerChannel?](repeating: nil, count: ports.count)
        var remaining = ports.count
        guard remaining > 0 else {
            completion([])
            return
        }
        for (index, port) in ports.enumerated() {
            connect(port) { channel in
                channels[index] = channel
                remaining -= 1
                if remaining == 0 {
                    completion(channels.compactMap { $0 })
                }
            }
        }
    }

    private func connect(_ port: ConnectionPort, completion: @escaping (ServerChannel?) -> Void) {
        if let connected = port.connectedChannel {
            completion(connected)
            return
        }
        switch port.kind {
        case .simulator, .mac:
            // A blocking connect: on loopback it succeeds or fails with
            // ECONNREFUSED at once, so the completion runs before this
            // returns.
            guard let fd = try? SocketConnector.connectLoopback(port: UInt16(port.number)) else {
                completion(nil)
                return
            }
            completion(attachChannel(fileDescriptor: fd, initialBytes: Data(), to: port))
        case let .usb(deviceID):
            usbMuxClient.connect(deviceID: deviceID, port: UInt16(port.number)) { [weak self, weak port] result in
                MainActor.assumeIsolated {
                    guard case let .success(stream) = result else {
                        // Refused (no Server on this port), timed out, or
                        // usbmuxd is gone.
                        completion(nil)
                        return
                    }
                    guard let self, let port else {
                        Darwin.close(stream.fileDescriptor)
                        completion(nil)
                        return
                    }
                    completion(self.attachChannel(fileDescriptor: stream.fileDescriptor, initialBytes: stream.initialBytes, to: port))
                }
            }
        }
    }

    private func attachChannel(fileDescriptor: Int32, initialBytes: Data, to port: ConnectionPort) -> ServerChannel {
        let channel = ServerChannel(
            fileDescriptor: fileDescriptor,
            initialBytes: initialBytes,
            port: port.number,
            kind: port.kind,
            delegate: self
        )
        port.connectedChannel = channel
        return channel
    }

    func connectedChannels() -> [ServerChannel] {
        (simulatorPorts + macPorts + usbPorts).compactMap { port in
            guard let channel = port.connectedChannel, channel.isConnected else { return nil }
            return channel
        }
    }

    /// Tracks USB devices through usbmuxd. A device's channels end on their
    /// own when it goes away.
    private func startListeningForUSBDevices() {
        usbMuxClient.startListening { [weak self] event in
            MainActor.assumeIsolated {
                guard let self else { return }
                switch event {
                case let .attached(deviceID, _):
                    // Each device has its own port range; see the file comment.
                    for number in Int32(LookinUSBDeviceIPv4PortNumberStart) ... Int32(LookinUSBDeviceIPv4PortNumberEnd) {
                        self.usbPorts.append(ConnectionPort(number: number, kind: .usb(deviceID: deviceID)))
                    }
                    #log(.default, "Lookin - USB device attached, DeviceID: \(NSNumber(value: deviceID), privacy: .public)")
                case let .detached(deviceID):
                    self.usbPorts.removeAll { port in
                        if case let .usb(portDeviceID) = port.kind {
                            return portDeviceID == deviceID
                        }
                        return false
                    }
                    #log(.default, "Lookin - USB device detached, DeviceID: \(NSNumber(value: deviceID), privacy: .public)")
                }
            }
        }
    }

    // MARK: - Requests

    /// Sends a push frame, which the Server does not answer. The Server may
    /// miss it while its app is in the background or stopped at a breakpoint.
    func push(type: UInt32, data: NSObject?, channel: ServerChannel?) {
        guard let channel, channel.isConnected else { return }
        let payload = archivedPayload(rootObject: data)
        #log(.default, "LookinClient - pushData, type:\(NSNumber(value: type), privacy: .public)")
        channel.send(type: type, tag: 0, payload: payload)
    }

    /// Pings the Server, checks its version, runs the license handshake when
    /// the request type allows one, then sends the request. `sink` receives
    /// each response frame, then a failure or a completion.
    ///
    /// An older request of the same type still waiting on this channel fails
    /// with `LookinErrCode_Discard` when this one is sent.
    func request(type: UInt32, data: NSObject?, channel: ServerChannel, sink: ResponseSink) {
        // An app in the background keeps its channel but cannot answer; a
        // long ping timeout would hold up the launch window's app list.
        let pingTimeout: TimeInterval = type == UInt32(LookinRequestTypeApp) ? 0.5 : 2

        let pingSink = ResponseSink { [weak self] event in
            guard let self else { return }
            switch event {
            case let .response(pingResponse):
                if let versionError = serverVersionError(for: pingResponse) {
                    sink.send(.failure(versionError))
                    return
                }
                let sendRequest = { [weak self] in
                    self?.sendFrame(
                        type: type,
                        channel: channel,
                        data: data,
                        timeoutInterval: Self.timeoutInterval(forRequestType: type),
                        sink: sink
                    )
                }
                guard Self.canStartLicenseHandshake(forRequestType: type) else {
                    sendRequest()
                    return
                }
                ensureLicenseHandshake(on: channel, force: false) { _ in
                    sendRequest()
                }
            case let .failure(error):
                sink.send(.failure(error))
            case .completion:
                break
            }
        }
        sendFrame(type: UInt32(LookinRequestTypePing), channel: channel, data: nil, timeoutInterval: pingTimeout, sink: pingSink)
    }

    /// Ends the waiting request of `type` on `channel` and reports it as
    /// completed.
    func cancelRequest(type: UInt32, channel: ServerChannel?) {
        guard let state = channel?.connectionState,
              let request = state.activeRequests.first(where: { $0.type == type })
        else {
            return
        }
        request.endTimeoutCount()
        state.remove(request)
        request.sink.send(.completion)
        #log(.default, "Lookin - request cancelled by the user, type:\(NSNumber(value: type), privacy: .public)")
    }

    /// Response frames of one request, until it completes. The stream
    /// throws the transport error or, for a frame that cannot be decoded,
    /// `LookinErr_Inner`. Cancelling the consuming task stops the delivery;
    /// the request on the channel runs to its end or its timeout.
    func responses(type: UInt32, data: NSObject?, channel: ServerChannel) -> AsyncThrowingStream<ConnectionResponseAttachment, Error> {
        AsyncThrowingStream { continuation in
            let sink = ResponseSink { event in
                switch event {
                case let .response(attachment):
                    if let attachment {
                        continuation.yield(attachment)
                    } else {
                        continuation.finish(throwing: ConnectionError.inner)
                    }
                case let .failure(error):
                    continuation.finish(throwing: error)
                case .completion:
                    continuation.finish()
                }
            }
            continuation.onTermination = { _ in
                Task { @MainActor in sink.detach() }
            }
            request(type: type, data: data, channel: channel, sink: sink)
        }
    }

    /// The first response of a request that answers once.
    func request(type: UInt32, data: NSObject?, channel: ServerChannel) async throws -> ConnectionResponseAttachment {
        for try await attachment in responses(type: type, data: data, channel: channel) {
            return attachment
        }
        throw ConnectionError.inner
    }

    // MARK: - Request policy

    /// Ping and the license exchange itself never wait for a handshake.
    nonisolated static func canStartLicenseHandshake(forRequestType type: UInt32) -> Bool {
        switch Int(type) {
        case LookinRequestTypePing, LookinRequestTypeLicenseChallenge, LookinRequestTypeLicenseVerify:
            false
        default:
            true
        }
    }

    static func timeoutInterval(forRequestType type: UInt32) -> TimeInterval {
        switch Int(type) {
        case LookinRequestTypeHierarchy, LookinRequestTypeHierarchyDetails:
            PreferenceManager.shared.hierarchyRequestTimeoutInterval
        default:
            5
        }
    }

    private func serverVersionError(for pingResponse: ConnectionResponseAttachment?) -> NSError? {
        let serverVersion = Int(pingResponse?.lookinServerVersion ?? 0)
        let supported = Int(LOOKIN_SUPPORTED_SERVER_MIN) ... Int(LOOKIN_SUPPORTED_SERVER_MAX)
        switch ServerVersionCompatibility(serverVersion: serverVersion, supported: supported) {
        case .compatible:
            return nil
        case .serverTooOld:
            return ConnectionError.serverVersionTooLow
        case .serverTooNew:
            return ConnectionError.serverVersionTooHigh
        }
    }

    // MARK: - Frames

    /// The keyed archive the Server expects: secure coding, and a nil root
    /// written as `$null`, the bytes `+archivedDataWithRootObject:
    /// requiringSecureCoding:YES error:` produced in the ObjC original.
    ///
    /// A non-nil root goes through that same throwing class method, so an
    /// object that does not adopt `NSSecureCoding` comes back as an error
    /// instead of an uncaught exception. As before, an archiving failure
    /// sends the frame with no payload (an empty payload is the header only,
    /// the bytes Peertalk sent for a nil payload). Swift cannot pass a nil
    /// root to the class method (it would box it as `NSNull`), so a nil root
    /// is encoded with an archiver instance, which cannot fail on nil.
    private func archivedPayload(rootObject: Any?) -> Data {
        guard let rootObject else {
            let archiver = NSKeyedArchiver(requiringSecureCoding: true)
            archiver.encode(nil as Any?, forKey: NSKeyedArchiveRootObjectKey)
            archiver.finishEncoding()
            return archiver.encodedData
        }
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: rootObject, requiringSecureCoding: true)
        } catch {
            assertionFailure("archiving the request failed: \(error)")
            return Data()
        }
    }

    /// Sends one frame and tracks it until its last response, a failure or
    /// its timeout.
    func sendFrame(type: UInt32, channel: ServerChannel, data: NSObject?, timeoutInterval: TimeInterval, sink: ResponseSink) {
        guard channel.isConnected else {
            sink.send(.failure(ConnectionError.noConnect))
            return
        }
        let state = channel.connectionState
        if type != UInt32(LookinRequestTypePing) {
            // A newer request replaces an older one of the same type, which
            // fails.
            for discarded in state.activeRequests where discarded.type == type {
                discarded.sink.send(.failure(ConnectionError.discarded))
                discarded.endTimeoutCount()
                state.remove(discarded)
                #log(.default, "LookinClient - will discard request, type:\(NSNumber(value: discarded.type), privacy: .public), tag:\(NSNumber(value: discarded.tag), privacy: .public)")
            }
        }

        let tag = UInt32(truncatingIfNeeded: Int64(Date().timeIntervalSince1970))
        let request = ConnectionRequest(type: type, tag: tag, timeoutInterval: timeoutInterval, sink: sink) { [weak channel] request in
            request.sink.send(.failure(ConnectionError.timeout))
            channel?.connectionState.remove(request)
        }

        let attachment = ConnectionAttachment()
        attachment.data = data
        let payload = archivedPayload(rootObject: attachment)
        // Track the request before the write: the write completion and the
        // reply reach the main queue independently, and on loopback the
        // reply can come first. A request registered only on completion
        // refuses its own reply and then times out.
        state.activeRequests.append(request)
        request.resetTimeoutCount()
        channel.send(type: type, tag: tag, payload: payload) { error in
            guard error != nil, state.activeRequests.contains(where: { $0 === request }) else { return }
            request.endTimeoutCount()
            state.remove(request)
            sink.send(.failure(ConnectionError.transport))
        }
    }

    // MARK: - Frame delivery

    private static let pushFrameTypes: Set<UInt32> = [
        UInt32(LookinPush_SwiftUISupportDetected),
        UInt32(LookinPush_GestureDebug),
    ]

    private func shouldAcceptFrame(on channel: ServerChannel, type: UInt32, tag: UInt32) -> Bool {
        if Self.pushFrameTypes.contains(type) {
            return true
        }
        if channel.connectionState.activeRequest(type: type, tag: tag) != nil {
            return true
        }
        #log(.default, "LookinClient - will refuse, type:\(NSNumber(value: type), privacy: .public), tag:\(NSNumber(value: tag), privacy: .public)")
        return false
    }

    private func didReceiveFrame(on channel: ServerChannel, type: UInt32, tag: UInt32, data: Data) {
        if Self.pushFrameTypes.contains(type) {
            let unarchived = try? NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSString.self, NSDictionary.self, NSArray.self, NSNumber.self, NSData.self, NSNull.self],
                from: data
            )
            pushBroadcaster.yield(ConnectionPush(channel: channel, type: type, data: unarchived))
            handlePush(type: type, data: unarchived, channel: channel)
            return
        }

        let state = channel.connectionState
        guard let request = state.activeRequest(type: type, tag: tag) else {
            // The request may have timed out between shouldAccept and now.
            return
        }

        // Wire compatibility with upstream Lookin and the LookInside Server
        // send path: the payload is a non-secure archive of
        // ConnectionResponseAttachment whose `data` is an arbitrary
        // graph of Lookin models and Foundation collections. Secure coding
        // with NSObject as the allowed class warns on every frame, so the
        // receive path stays non-secure on purpose.
        let attachment = Self.unarchiveResponse(data)

        if attachment?.appIsInBackground == true {
            request.endTimeoutCount()
            state.remove(request)
            request.sink.send(.failure(ConnectionError.appInBackground))
            #log(.default, "Lookin - the iOS app reported that it is in the background; request failed")
            return
        }

        request.sink.send(.response(attachment))

        if request.frameProgress.isAtFirstFrame {
            receivedResponseBytes = 0
            responseStartTime = CACurrentMediaTime()
        }
        receivedResponseBytes += data.count

        let isComplete = request.frameProgress.record(
            currentDataCount: Int(attachment?.currentDataCount ?? 0),
            dataTotalCount: Int(attachment?.dataTotalCount ?? 0)
        )
        if isComplete {
            request.endTimeoutCount()
            state.remove(request)
            request.sink.send(.completion)

            let duration = CACurrentMediaTime() - responseStartTime
            let megabytes = Double(receivedResponseBytes) / 1024 / 1024
            if megabytes > 0.5 {
                #log(.default, "Lookin - received all responses \(NSNumber(value: request.frameProgress.receivedDataCount), privacy: .public) / \(NSNumber(value: attachment?.dataTotalCount ?? 0), privacy: .public), \(duration, format: .fixed(precision: 2), privacy: .public)s, \(megabytes, format: .fixed(precision: 2), privacy: .public)M")
            }
        } else {
            // A multi-frame response restarts the timeout with each frame.
            request.resetTimeoutCount()
        }
    }

    private static func unarchiveResponse(_ data: Data) -> ConnectionResponseAttachment? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else {
            return nil
        }
        unarchiver.requiresSecureCoding = false
        defer { unarchiver.finishDecoding() }
        return unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? ConnectionResponseAttachment
    }

    private func handlePush(type: UInt32, data: Any?, channel: ServerChannel) {
        guard type == UInt32(LookinPush_SwiftUISupportDetected) else { return }
        #log(.default, "LookinClient - received SwiftUI support detection push from channel:\(channel, privacy: .public) data:\(data.map { String(describing: $0) } ?? "(null)", privacy: .public)")
        DispatchQueue.main.async {
            let gatekeeper = SwiftUISupportGatekeeper.sharedInstance()
            gatekeeper.noteDetectedSwiftUISupport()
            let keyWindow = NSApplication.shared.keyWindow
            let launchWindow = NavigationManager.shared.launchWindowController?.window
            if let keyWindow, keyWindow !== launchWindow {
                gatekeeper.promptForPendingDetectedSwiftUISupportIfNeeded(window: keyWindow)
            }
        }
    }

    private func endChannel(_ channel: ServerChannel) {
        for port in simulatorPorts + macPorts + usbPorts where port.connectedChannel === channel {
            port.connectedChannel = nil
        }
        channelWillEndBroadcaster.yield(channel)
        SwiftUISupportGatekeeper.sharedInstance().licenseHandshakeChannelDidEnd(channel.connectionState.licenseChannelID)
        channel.close()
    }
}

// MARK: - ServerChannelDelegate

extension ConnectionManager: ServerChannelDelegate {
    func channel(_ channel: ServerChannel, shouldAcceptFrameOfType type: UInt32, tag: UInt32) -> Bool {
        shouldAcceptFrame(on: channel, type: type, tag: tag)
    }

    func channel(_ channel: ServerChannel, didReceiveFrameOfType type: UInt32, tag: UInt32, payload: Data) {
        didReceiveFrame(on: channel, type: type, tag: tag, data: payload)
    }

    func channelDidEnd(_ channel: ServerChannel) {
        endChannel(channel)
    }
}

/// Runs `body` on the main actor: at once on the main thread, otherwise on
/// the next turn of the main queue.
func runOnMain(_ body: @escaping @MainActor () -> Void) {
    if Thread.isMainThread {
        MainActor.assumeIsolated(body)
    } else {
        DispatchQueue.main.async(execute: body)
    }
}
