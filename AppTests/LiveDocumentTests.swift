//
//  LiveDocumentTests.swift
//  LookInsideAppTests
//
//  LiveDocument carrying out LiveSessionState's decisions against
//  FakeServers: the banners for a lost channel and an app in the
//  background, which channel's events count, the background probe, the
//  reconnect to the same app, and the retried refresh after it returns.
//

import AppKit
@testable import LookInside
import LookInsideHostCore
import Testing

extension HostAppTests {
    @MainActor
    struct LiveDocumentTests {
        /// An app on `channel`, described by `server`'s app info.
        private func makeApp(_ server: FakeServer, channel: ServerChannel?) -> InspectableApp {
            let app = InspectableApp()
            app.appInfo = server.appInfo
            app.channel = channel
            return app
        }

        /// Lets events already queued on the main queue reach the document.
        private func drainMainQueue() async {
            try? await Task.sleep(for: .milliseconds(200))
        }

        /// The app holds its channel weakly: a channel that was released or
        /// ended before the document watched it counts as lost.
        @Test func channelGoneBeforeTheDocumentOpenedShowsConnectionLost() {
            let server = FakeServer()
            defer { server.shutDown() }

            let releasedChannelDocument = LiveDocument(inspectableApp: makeApp(server, channel: nil))
            defer { releasedChannelDocument.close() }
            #expect(releasedChannelDocument.connectionLossBannerMessage != nil)

            let endedChannel = server.connectChannel()
            endedChannel.close()
            let endedChannelDocument = LiveDocument(inspectableApp: makeApp(server, channel: endedChannel))
            defer { endedChannelDocument.close() }
            #expect(endedChannelDocument.connectionLossBannerMessage != nil)
            #expect(endedChannelDocument.applicationInBackgroundBannerMessage == nil)
        }

        @Test func onlyTheWatchedChannelsEndShowsConnectionLost() async {
            let watchedServer = FakeServer()
            let otherServer = FakeServer()
            defer {
                watchedServer.shutDown()
                otherServer.shutDown()
            }
            let watchedChannel = watchedServer.connectChannel()
            let otherChannel = otherServer.connectChannel()
            let endedChannels = StreamCollector(ConnectionManager.shared.channelWillEndEvents())
            defer { endedChannels.stop() }
            let document = LiveDocument(inspectableApp: makeApp(watchedServer, channel: watchedChannel))
            defer { document.close() }
            #expect(document.connectionLossBannerMessage == nil)

            otherServer.disconnectAll()
            #expect(await waitUntil { endedChannels.elements.contains { $0 === otherChannel } })
            await drainMainQueue()
            #expect(document.connectionLossBannerMessage == nil)

            watchedServer.disconnectAll()
            #expect(await waitUntil { document.connectionLossBannerMessage != nil })
            #expect(document.connectionLossBannerMessage?.contains(watchedServer.appInfo.appName ?? "") == true)
        }

        @Test func backgroundPushShowsTheBannerUntilTheAppReturns() async {
            let watchedServer = FakeServer()
            let otherServer = FakeServer()
            defer {
                watchedServer.shutDown()
                otherServer.shutDown()
            }
            let watchedChannel = watchedServer.connectChannel()
            let otherChannel = otherServer.connectChannel()
            defer { otherChannel.close() }
            let reports = StreamCollector(ConnectionManager.shared.applicationStateEvents())
            defer { reports.stop() }
            let document = LiveDocument(inspectableApp: makeApp(watchedServer, channel: watchedChannel))
            defer { document.close() }

            otherServer.pushApplicationState(isActive: false)
            #expect(await waitUntil { reports.elements.contains { $0.channel === otherChannel } })
            await drainMainQueue()
            #expect(document.applicationInBackgroundBannerMessage == nil)

            watchedServer.pushApplicationState(isActive: false)
            #expect(await waitUntil { document.applicationInBackgroundBannerMessage != nil })
            #expect(document.connectionLossBannerMessage == nil)

            watchedServer.pushApplicationState(isActive: true)
            #expect(await waitUntil { document.applicationInBackgroundBannerMessage == nil })
        }

        /// A Server that does not push its state: a refused request shows
        /// the banner, and only the background probe's ping can tell that
        /// the app is back.
        @Test(.timeLimit(.minutes(1)))
        func backgroundProbeClearsTheBannerOnceAPingIsAnswered() async throws {
            let server = FakeServer()
            server.behavior = .inBackground
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let document = LiveDocument(inspectableApp: makeApp(server, channel: channel))
            defer { document.close() }

            await #expect(throws: (any Error).self) {
                try await ConnectionManager.shared.ping(channel: channel)
            }
            #expect(await waitUntil { document.applicationInBackgroundBannerMessage != nil })
            let pingsBeforeProbe = server.receivedRequestTypes.count

            server.behavior = .answering
            let probeWindow = LiveSessionState.backgroundProbeInterval + .seconds(3)
            #expect(await waitUntil(timeout: probeWindow) { document.applicationInBackgroundBannerMessage == nil })
            #expect(server.receivedRequestTypes.count > pingsBeforeProbe)
            #expect(server.receivedRequestTypes.dropFirst(pingsBeforeProbe).allSatisfy { $0 == UInt32(LookinRequestTypePing) })
        }

        /// The app's process went away and came back on a new channel: the
        /// scan every 3 seconds finds it by identity, and the document
        /// switches to it and clears the banner.
        @Test(.timeLimit(.minutes(1)))
        func reconnectAdoptsTheSameAppOnItsNewChannel() async throws {
            let server = FakeServer(appName: "Reconnect Target", bundleIdentifier: "com.lookinside.apptests.reconnect")
            defer { server.shutDown() }
            let port = try server.listen()
            let apps = await AppsManager.shared.fetchAppInfos(needImages: false, localInfos: nil)
            let originalApp = try #require(apps.first { $0.origin?.port == port })
            let originalChannel = try #require(originalApp.channel)
            let document = LiveDocument(inspectableApp: originalApp)
            defer { document.close() }

            server.disconnectAll()
            #expect(await waitUntil { document.connectionLossBannerMessage != nil })

            #expect(await waitUntil(timeout: .seconds(10)) { document.inspectableApp !== originalApp })
            let adoptedChannel = try #require(document.inspectableApp.channel)
            #expect(adoptedChannel !== originalChannel)
            #expect(adoptedChannel.isConnected)
            #expect(adoptedChannel.port == port)
            #expect(document.inspectableApp.appInfo?.appBundleIdentifier == "com.lookinside.apptests.reconnect")
            #expect(document.connectionLossBannerMessage == nil)

            // The new channel is watched: its end shows the banner again.
            server.disconnectAll()
            #expect(await waitUntil { document.connectionLossBannerMessage != nil })
        }

        /// The refresh after the app returns is refused while the window
        /// still fetches; it is tried again until that fetch is over.
        @Test(.timeLimit(.minutes(1)))
        func refreshAfterReturnWaitsForTheRunningFetch() async throws {
            let server = FakeServer()
            server.heldRequestTypes = [UInt32(LookinRequestTypeHierarchy)]
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let document = LiveDocument(inspectableApp: makeApp(server, channel: channel))
            defer { document.close() }
            document.makeWindowControllers()
            let windowController = try #require(document.staticWindowController)
            let hierarchyRequestCount = { server.receivedRequestTypes.filter { $0 == UInt32(LookinRequestTypeHierarchy) }.count }

            let runningFetch = Task { try? await windowController.reloadHierarchy(initiator: .host) }
            #expect(await waitUntil { hierarchyRequestCount() == 1 })

            server.pushApplicationState(isActive: false)
            #expect(await waitUntil { document.applicationInBackgroundBannerMessage != nil })
            server.pushApplicationState(isActive: true)
            #expect(await waitUntil { document.applicationInBackgroundBannerMessage == nil })
            // The refresh was refused; give it a retry or two while the
            // first fetch still runs.
            try await Task.sleep(for: AutomaticRefreshRetryPolicy.defaultRetryInterval * 3)
            #expect(hierarchyRequestCount() == 1)

            server.answerHeldRequests(with: ConnectionResponseAttachment.attachment(error: ConnectionError.inner))
            _ = await runningFetch.value
            #expect(await waitUntil { hierarchyRequestCount() == 2 })

            server.answerHeldRequests(with: ConnectionResponseAttachment.attachment(error: ConnectionError.inner))

            // Closing the inspector window brings the launch window back
            // (AppDelegate), whose scans would reach the other tests' ports.
            document.close()
            _ = await waitUntil(timeout: .seconds(1)) { NavigationManager.shared.launchWindowController != nil }
            NavigationManager.shared.closeLaunch()
        }
    }
}
