//
//  ConnectionManagerTests.swift
//  LookInsideAppTests
//
//  ConnectionManager against a FakeServer: the request path, how requests
//  end when their channel ends or goes quiet, what the Server's background
//  reports turn into, and reusing a channel the scan connected before.
//

import Foundation
@testable import LookInside
import LookInsideHostCore
import Testing

extension HostAppTests {
    @MainActor
    struct ConnectionManagerTests {
        private let manager = ConnectionManager.shared

        @Test func requestRunsPingThenTheRequestAndReturnsTheResponse() async throws {
            let server = FakeServer(appName: "Request Round Trip")
            defer { server.shutDown() }
            let channel = server.connectChannel()

            let response = try await manager.request(type: UInt32(LookinRequestTypeApp), data: nil, channel: channel)

            let info = try #require(response.data as? InspectedAppInfo)
            #expect(info.appName == "Request Round Trip")
            #expect(server.receivedRequestTypes == [UInt32(LookinRequestTypePing), UInt32(LookinRequestTypeApp)])
            #expect(!manager.isRequestInFlight(type: UInt32(LookinRequestTypeApp), channel: channel))
        }

        @Test func serverBelowTheSupportedVersionFailsTheRequestUnsent() async {
            let server = FakeServer()
            server.serverVersion = Int32(LOOKIN_SUPPORTED_SERVER_MIN) - 1
            defer { server.shutDown() }
            let channel = server.connectChannel()

            await #expect {
                _ = try await manager.request(type: UInt32(LookinRequestTypeApp), data: nil, channel: channel)
            } throws: { error in
                (error as NSError).code == LookinErrCode_ServerVersionTooLow
            }
            #expect(server.receivedRequestTypes == [UInt32(LookinRequestTypePing)])
        }

        /// A hierarchy fetch must not wait out its timeout once its app is
        /// gone, or the refresh after a reconnect is refused as running.
        @Test func channelEndFailsRequestsInFlightAndIsBroadcast() async {
            let server = FakeServer()
            server.behavior = .silent
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let endedChannels = StreamCollector(manager.channelWillEndEvents())
            defer { endedChannels.stop() }
            let recorder = ResponseRecorder()
            manager.sendFrame(type: UInt32(LookinRequestTypeHierarchy), channel: channel, data: nil, timeoutInterval: 60, sink: recorder.sink)
            #expect(await waitUntil { server.receivedRequestTypes.contains(UInt32(LookinRequestTypeHierarchy)) })
            #expect(manager.isRequestInFlight(type: UInt32(LookinRequestTypeHierarchy), channel: channel))

            server.disconnectAll()

            #expect(await waitUntil { recorder.hasEnded })
            #expect(recorder.failure?.code == LookinErrCode_NoConnect)
            #expect(!manager.isRequestInFlight(type: UInt32(LookinRequestTypeHierarchy), channel: channel))
            #expect(await waitUntil { endedChannels.elements.contains { $0 === channel } })
            #expect(!channel.isConnected)
        }

        @Test func requestOnAnEndedChannelFailsAtOnce() {
            let server = FakeServer()
            defer { server.shutDown() }
            let channel = server.connectChannel()
            channel.close()
            let recorder = ResponseRecorder()

            manager.sendFrame(type: UInt32(LookinRequestTypePing), channel: channel, data: nil, timeoutInterval: 60, sink: recorder.sink)

            #expect(recorder.failure?.code == LookinErrCode_NoConnect)
        }

        /// A probe that times out on a channel that received bytes a moment
        /// ago is a busy app, not a dead channel; a hierarchy request that
        /// times out never closes its channel.
        @Test func timeoutFailsTheRequestAndKeepsAChannelThatIsNotSilent() async {
            let server = FakeServer()
            server.behavior = .silent
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let ping = ResponseRecorder()
            let hierarchy = ResponseRecorder()

            manager.sendFrame(type: UInt32(LookinRequestTypePing), channel: channel, data: nil, timeoutInterval: 0.2, sink: ping.sink)
            manager.sendFrame(type: UInt32(LookinRequestTypeHierarchy), channel: channel, data: nil, timeoutInterval: 0.2, sink: hierarchy.sink)

            #expect(await waitUntil { ping.hasEnded && hierarchy.hasEnded })
            #expect(ping.failure?.code == LookinErrCode_Timeout)
            #expect(hierarchy.failure?.code == LookinErrCode_Timeout)
            #expect(!manager.isRequestInFlight(type: UInt32(LookinRequestTypeHierarchy), channel: channel))
            #expect(channel.isConnected)
        }

        /// Over usbmuxd a channel whose far end is gone can stay "connected"
        /// forever; a probe timing out after `ChannelLivenessPolicy`'s
        /// silence closes it, so its port is probed again.
        @Test(.timeLimit(.minutes(1)))
        func probeTimeoutOnASilentChannelClosesIt() async {
            let server = FakeServer()
            server.behavior = .silent
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let endedChannels = StreamCollector(manager.channelWillEndEvents())
            defer { endedChannels.stop() }
            let ping = ResponseRecorder()

            let timeout = ChannelLivenessPolicy.defaultSilenceBeforeClosing + 0.3
            manager.sendFrame(type: UInt32(LookinRequestTypePing), channel: channel, data: nil, timeoutInterval: timeout, sink: ping.sink)

            #expect(await waitUntil(timeout: .seconds(timeout + 3)) { ping.hasEnded })
            #expect(ping.failure?.code == LookinErrCode_Timeout)
            #expect(await waitUntil { endedChannels.elements.contains { $0 === channel } })
            #expect(!channel.isConnected)
        }

        @Test func backgroundReplyFailsTheRequestAndReportsTheChannel() async {
            let server = FakeServer()
            server.behavior = .inBackground
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let reports = StreamCollector(manager.applicationStateEvents())
            defer { reports.stop() }

            await #expect {
                try await manager.ping(channel: channel)
            } throws: { error in
                (error as NSError).code == LookinErrCode_PingFailForBackgroundState
            }

            #expect(await waitUntil { !reports.elements.isEmpty })
            let report = reports.elements.first
            #expect(report?.channel === channel)
            guard case .requestRefusedInBackground = report?.kind else {
                Issue.record("expected requestRefusedInBackground, got \(String(describing: report?.kind))")
                return
            }
            #expect(!manager.isRequestInFlight(type: UInt32(LookinRequestTypePing), channel: channel))
        }

        @Test func applicationStatePushIsReportedForItsChannel() async {
            let server = FakeServer()
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let reports = StreamCollector(manager.applicationStateEvents())
            defer { reports.stop() }
            let pushes = StreamCollector(manager.pushEvents())
            defer { pushes.stop() }

            server.pushApplicationState(isActive: false)
            #expect(await waitUntil { reports.elements.count == 1 })
            server.pushApplicationState(isActive: true)
            #expect(await waitUntil { reports.elements.count == 2 })

            let states: [Bool?] = reports.elements.map { report in
                #expect(report.channel === channel)
                if case let .serverReported(isActive) = report.kind {
                    return isActive
                }
                return nil
            }
            #expect(states == [false, true])
            #expect(pushes.elements.map(\.type) == [UInt32(LookinPush_ApplicationStateChanged), UInt32(LookinPush_ApplicationStateChanged)])
        }

        /// A channel the Host closed is reported as ended a main-queue turn
        /// later; a scan in between must connect its port again instead of
        /// handing back the closed channel.
        @Test func scanReplacesACachedChannelThatClosed() async throws {
            let server = FakeServer()
            defer { server.shutDown() }
            let port = try server.listen()

            let firstScan = await manager.connectAllPorts()
            let first = try #require(firstScan.first { $0.port == port })
            let rescan = await manager.connectAllPorts()
            #expect(rescan.first { $0.port == port } === first, "a connected channel is reused")

            first.close()
            let second = try #require(await connectAllPortsBeforeTheEndIsDelivered().first { $0.port == port })

            #expect(second !== first)
            #expect(second.isConnected)
            #expect(await waitUntil { server.connections.count == 2 })
            #expect(manager.connectedChannels().contains { $0 === second })
        }

        /// `connectAllPorts()` from this main-queue turn: the loopback ports
        /// connect before it returns, ahead of any channel end queued on
        /// the main queue.
        private func connectAllPortsBeforeTheEndIsDelivered() async -> [ServerChannel] {
            await withCheckedContinuation { continuation in
                manager.connectAllPorts { continuation.resume(returning: $0) }
            }
        }
    }
}
