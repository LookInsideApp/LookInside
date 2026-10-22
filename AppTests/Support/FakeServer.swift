//
//  FakeServer.swift
//  LookInsideAppTests
//
//  A stand-in for the Server an inspected app embeds. It speaks the real
//  frame protocol through LookinCore's FrameChannel and answers with real
//  ConnectionResponseAttachment objects, so the Host's ConnectionManager,
//  ServerChannel and LiveDocument run unchanged against it. A test connects
//  it to the Host over a socketpair (`connectChannel()`), or has it listen
//  on a free Mac port so the Host's own port scan finds it (`listen()`).
//

import Foundation
@testable import LookInside
import LookInsideHostCore

@MainActor
final class FakeServer {
    /// How the Server answers a request.
    enum Behavior {
        /// Answers every request at once.
        case answering
        /// Reads requests and never answers: an app stopped in a debugger,
        /// or a usbmuxd tunnel whose far end is gone.
        case silent
        /// Answers every request with `appIsInBackground`, as a Server
        /// does while its iOS app is in the background.
        case inBackground
    }

    var behavior: Behavior = .answering
    /// The version reported in each response; the Host checks the ping's.
    var serverVersion = Int32(LOOKIN_SERVER_VERSION)
    /// Requests of these types are recorded but not answered until
    /// `answerHeldRequests(with:)`.
    var heldRequestTypes: Set<UInt32> = []
    let appInfo: InspectedAppInfo

    /// The type of every request received, in order, from every channel.
    private(set) var receivedRequestTypes: [UInt32] = []
    /// Server ends of the channels the Host connected, oldest first.
    private(set) var connections: [FrameChannel] = []
    private var heldRequests: [(connection: FrameChannel, type: UInt32, tag: UInt32)] = []
    private var listener: FrameListener?

    init(appName: String = "FakeApp", bundleIdentifier: String = "com.lookinside.apptests.fake") {
        let info = InspectedAppInfo()
        info.appName = appName
        info.appBundleIdentifier = bundleIdentifier
        info.deviceDescription = "Test Mac"
        info.osDescription = "macOS"
        info.deviceType = .mac
        info.serverVersion = Int32(LOOKIN_SERVER_VERSION)
        info.hierarchyAcquisitionProtocolVersion = HierarchyAcquisitionSupport.requiredProtocolVersion
        appInfo = info
    }

    // MARK: - Connecting

    /// Connects a new Host channel to this Server over a socketpair. The
    /// channel's delegate is the app's `ConnectionManager.shared`, as for a
    /// channel the Host connected itself, but no port of the manager holds
    /// it, so the port scan never returns it.
    func connectChannel(port: Int32 = 0) -> ServerChannel {
        var descriptors: [Int32] = [-1, -1]
        let result = socketpair(AF_UNIX, SOCK_STREAM, 0, &descriptors)
        precondition(result == 0, "socketpair failed: \(errno)")
        accept(descriptors[1])
        return ServerChannel(fileDescriptor: descriptors[0], port: port, kind: .mac, delegate: ConnectionManager.shared)
    }

    /// Listens on the first free Mac port, where the Host's scan connects.
    /// Throws when every Mac port is taken.
    func listen() throws -> Int32 {
        var lastError: Error?
        for port in Int32(LookinMacIPv4PortNumberStart) ... Int32(LookinMacIPv4PortNumberEnd) {
            do {
                listener = try FrameListener.listen(port: UInt16(port), queue: .main) { [weak self] descriptor in
                    MainActor.assumeIsolated {
                        self?.accept(descriptor)
                    }
                }
                return port
            } catch {
                lastError = error
            }
        }
        throw lastError ?? CocoaError(.featureUnsupported)
    }

    /// Ends every channel from the Server's side, the way a killed app's
    /// socket closes. A listener keeps listening, as a relaunched app would.
    func disconnectAll() {
        for connection in connections {
            connection.close()
        }
        connections.removeAll()
        heldRequests.removeAll()
    }

    /// Disconnects and stops listening.
    func shutDown() {
        disconnectAll()
        listener?.cancel()
        listener = nil
    }

    // MARK: - Sending

    /// Sends the `LookinPush_ApplicationStateChanged` push on every channel.
    func pushApplicationState(isActive: Bool) {
        let payload = [ApplicationStatePush.isActiveKey: NSNumber(value: isActive)] as NSDictionary
        // The push decoder on the Host takes secure-coded Foundation types.
        let data = try! NSKeyedArchiver.archivedData(withRootObject: payload, requiringSecureCoding: true)
        for connection in connections {
            connection.send(type: UInt32(LookinPush_ApplicationStateChanged), tag: 0, payload: data)
        }
    }

    /// Answers every held request with `attachment`.
    func answerHeldRequests(with attachment: ConnectionResponseAttachment) {
        let held = heldRequests
        heldRequests.removeAll()
        for request in held {
            send(attachment, type: request.type, tag: request.tag, on: request.connection)
        }
    }

    // MARK: - Receiving

    private func accept(_ descriptor: Int32) {
        let connection = FrameChannel(fileDescriptor: descriptor, queue: .main)
        connection.onFrame = { [weak self, weak connection] frame in
            MainActor.assumeIsolated {
                guard let self, let connection else { return }
                self.didReceive(frame, on: connection)
            }
        }
        connections.append(connection)
        connection.start()
    }

    private func didReceive(_ frame: TransportFrame, on connection: FrameChannel) {
        receivedRequestTypes.append(frame.type)
        if heldRequestTypes.contains(frame.type) {
            heldRequests.append((connection, frame.type, frame.tag))
            return
        }
        let attachment = ConnectionResponseAttachment()
        attachment.lookinServerVersion = serverVersion
        switch behavior {
        case .silent:
            return
        case .inBackground:
            attachment.appIsInBackground = true
        case .answering:
            if frame.type == UInt32(LookinRequestTypeApp) {
                attachment.data = appInfo
            }
        }
        send(attachment, type: frame.type, tag: frame.tag, on: connection)
    }

    private func send(_ attachment: ConnectionResponseAttachment, type: UInt32, tag: UInt32, on connection: FrameChannel) {
        // The Server's send path: a non-secure archive of the attachment.
        let data = try! NSKeyedArchiver.archivedData(withRootObject: attachment, requiringSecureCoding: false)
        connection.send(type: type, tag: tag, payload: data)
    }
}
