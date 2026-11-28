//
//  LiveDocumentTests.swift
//  LookInsideAppTests
//
//  LiveDocument carrying out LiveSessionState's decisions against
//  FakeServers: the banners for a lost channel and an app in the
//  background, which channel's events count, the background probe, the
//  reconnect to the same app, and refreshing only when requested on iOS.
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

        private func makeIOSServer(bundleIdentifier: String) -> FakeServer {
            let server = FakeServer(bundleIdentifier: bundleIdentifier)
            server.appInfo.deviceDescription = "Test iPhone"
            server.appInfo.osDescription = "iOS 27.0"
            server.appInfo.deviceType = .others
            server.appInfo.appInfoIdentifier = 1
            server.appInfo.screenScale = 2
            return server
        }

        private func makeHierarchy(for appInfo: InspectedAppInfo?) -> HierarchyInfo {
            let hierarchy = HierarchyInfo()
            hierarchy.appInfo = appInfo
            hierarchy.displayItems = []
            return hierarchy
        }

        private func closeInspector(_ document: LiveDocument) {
            document.close()
            // Closing the window schedules reopening Launch on the main queue.
            // Its scans would reach the other tests' ports.
            DispatchQueue.main.async { NavigationManager.shared.closeLaunch() }
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
            #expect(endedChannelDocument.applicationStatusBannerMessage == nil)
        }

        /// Entering an app that is already open — from the launch window, the
        /// window's app picker, the auto-connect — hands its window the
        /// `InspectableApp` a scan just made. The window and its update
        /// manager hold the app weakly; the document is what keeps it alive.
        /// The window used to lose its app as soon as the scan's copy was let
        /// go, and Reload then said it was attached to none.
        @Test func aWindowHandedAnotherAppKeepsItOnceTheCallerLetsItGo() throws {
            let server = FakeServer()
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let document = LiveDocument(inspectableApp: makeApp(server, channel: channel))
            defer { document.close() }
            document.makeWindowControllers()
            let windowController = try #require(document.staticWindowController)

            let hierarchy = HierarchyInfo()
            hierarchy.appInfo = server.appInfo
            hierarchy.appInfo?.screenScale = 2
            hierarchy.displayItems = []
            weak var scannedAppReference: InspectableApp?
            do {
                let scannedApp = makeApp(server, channel: channel)
                scannedAppReference = scannedApp
                windowController.applyHierarchyInfo(hierarchy, for: scannedApp, keepState: true)
            }

            #expect(scannedAppReference != nil, "the document should keep the app its window was handed")
            #expect(windowController.inspectableApp != nil, "the window should keep its app")
            #expect(windowController.inspectableApp === document.inspectableApp)
            #expect(windowController.asyncUpdateManager.inspectableApp === document.inspectableApp)
            #expect(document.connectionLossBannerMessage == nil, "the same channel should stay watched")
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
            #expect(document.applicationStatusBannerMessage == nil)

            watchedServer.pushApplicationState(isActive: false)
            #expect(await waitUntil { document.applicationStatusBannerMessage != nil })
            #expect(document.connectionLossBannerMessage == nil)

            watchedServer.pushApplicationState(isActive: true)
            #expect(await waitUntil { document.applicationStatusBannerMessage == nil })
        }

        /// A Server that does not push its state: a refused request shows
        /// the banner, and only the background probe's ping can tell that
        /// the app is back.
        @Test(.timeLimit(.minutes(1)))
        func backgroundProbeClearsTheBannerOnceAPingIsAnswered() async throws {
            let server = makeIOSServer(bundleIdentifier: "com.lookinside.apptests.background-probe")
            server.behavior = .inBackground
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let document = LiveDocument(inspectableApp: makeApp(server, channel: channel))
            defer { closeInspector(document) }
            document.makeWindowControllers()

            await #expect(throws: (any Error).self) {
                try await ConnectionManager.shared.ping(channel: channel)
            }
            #expect(await waitUntil { document.applicationStatusBannerMessage != nil })
            let pingsBeforeProbe = server.receivedRequestTypes.count

            server.behavior = .answering
            let probeWindow = LiveSessionState.backgroundProbeInterval + .seconds(3)
            #expect(await waitUntil(timeout: probeWindow) { document.applicationStatusBannerMessage == nil })
            await drainMainQueue()
            #expect(server.receivedRequestTypes.count > pingsBeforeProbe)
            #expect(server.receivedRequestTypes.dropFirst(pingsBeforeProbe).allSatisfy { $0 == UInt32(RequestType.ping) })
        }

        /// The app's process went away and came back on a new channel: the
        /// scan every 3 seconds finds it by identity, and the document
        /// switches to it and refreshes the hierarchy on macOS.
        @Test(.timeLimit(.minutes(1)))
        func reconnectAdoptsAndRefreshesTheSameMacAppOnItsNewChannel() async throws {
            let server = FakeServer(appName: "Reconnect Target", bundleIdentifier: "com.lookinside.apptests.reconnect")
            server.appInfo.screenScale = 2
            let hierarchy = makeHierarchy(for: server.appInfo)
            server.responders[UInt32(RequestType.hierarchy)] = { _ in hierarchy }
            defer { server.shutDown() }
            let port = try server.listen()
            let apps = await AppsManager.shared.fetchAppInfos(needImages: false, localInfos: nil)
            let originalApp = try #require(apps.first { $0.origin?.port == port })
            let originalChannel = try #require(originalApp.channel)
            let document = LiveDocument(inspectableApp: originalApp)
            defer { closeInspector(document) }
            document.makeWindowControllers()

            server.disconnectAll()
            #expect(await waitUntil { document.connectionLossBannerMessage != nil })

            #expect(await waitUntil(timeout: .seconds(10)) { document.inspectableApp !== originalApp })
            let adoptedChannel = try #require(document.inspectableApp.channel)
            #expect(adoptedChannel !== originalChannel)
            #expect(adoptedChannel.isConnected)
            #expect(adoptedChannel.port == port)
            #expect(document.inspectableApp.appInfo?.appBundleIdentifier == "com.lookinside.apptests.reconnect")
            #expect(document.connectionLossBannerMessage == nil)
            #expect(await waitUntil { document.hierarchyDataSource?.rawHierarchyInfo?.appInfo?.appName == "Reconnect Target" })

            // The new channel is watched: its end shows the banner again.
            server.disconnectAll()
            #expect(await waitUntil { document.connectionLossBannerMessage != nil })
        }

        @Test(.timeLimit(.minutes(1)))
        func foregroundPushWaitsForExplicitRefresh() async throws {
            let server = makeIOSServer(bundleIdentifier: "com.lookinside.apptests.foreground")
            let hierarchy = makeHierarchy(for: server.appInfo)
            let hierarchyRequest = UInt32(RequestType.hierarchy)
            server.responders[hierarchyRequest] = { _ in hierarchy }
            defer { server.shutDown() }
            let channel = server.connectChannel()
            let document = LiveDocument(inspectableApp: makeApp(server, channel: channel))
            defer { closeInspector(document) }
            document.makeWindowControllers()
            let windowController = try #require(document.staticWindowController)

            server.pushApplicationState(isActive: false)
            #expect(await waitUntil { document.applicationStatusBannerMessage != nil })
            server.pushApplicationState(isActive: true)
            #expect(await waitUntil { document.applicationStatusBannerMessage == nil })
            await drainMainQueue()
            #expect(!server.receivedRequestTypes.contains(hierarchyRequest))

            let refreshed = try await windowController.reloadHierarchy(initiator: .host)
            #expect(refreshed?.appInfo?.appInfoIdentifier == 1)
            #expect(server.receivedRequestTypes.filter { $0 == hierarchyRequest }.count == 1)
        }

        @Test(.timeLimit(.minutes(1)))
        func reconnectingToTheSameIOSProcessDoesNotRefresh() async throws {
            let server = makeIOSServer(bundleIdentifier: "com.lookinside.apptests.same-ios-process")
            defer { server.shutDown() }
            let port = try server.listen()
            let apps = await AppsManager.shared.fetchAppInfos(needImages: false, localInfos: nil)
            let originalApp = try #require(apps.first { $0.origin?.port == port })
            let originalChannel = try #require(originalApp.channel)
            let document = LiveDocument(inspectableApp: originalApp)
            defer { closeInspector(document) }
            document.makeWindowControllers()

            server.disconnectAll()
            #expect(await waitUntil { document.connectionLossBannerMessage != nil })
            #expect(await waitUntil(timeout: .seconds(10)) { document.inspectableApp !== originalApp })
            #expect(document.inspectableApp.channel !== originalChannel)
            #expect(document.inspectableApp.channel?.isConnected == true)
            #expect(document.connectionLossBannerMessage == nil)
            await drainMainQueue()
            #expect(!server.receivedRequestTypes.contains(UInt32(RequestType.hierarchy)))

            server.disconnectAll()
            #expect(await waitUntil { document.connectionLossBannerMessage != nil })
        }

        @Test(.timeLimit(.minutes(1)))
        func reconnectingToANewIOSProcessWaitsForExplicitRefresh() async throws {
            let server = makeIOSServer(bundleIdentifier: "com.lookinside.apptests.new-ios-process")
            defer { server.shutDown() }
            let port = try server.listen()
            let apps = await AppsManager.shared.fetchAppInfos(needImages: false, localInfos: nil)
            let originalApp = try #require(apps.first { $0.origin?.port == port })
            let document = LiveDocument(inspectableApp: originalApp)
            defer { closeInspector(document) }
            document.makeWindowControllers()
            let windowController = try #require(document.staticWindowController)
            windowController.applyHierarchyInfo(makeHierarchy(for: originalApp.appInfo), for: originalApp, keepState: false)

            server.appInfo.appInfoIdentifier = 2
            let hierarchy = makeHierarchy(for: server.appInfo)
            let hierarchyRequest = UInt32(RequestType.hierarchy)
            server.disconnectAll()
            #expect(await waitUntil { document.connectionLossBannerMessage != nil })
            #expect(await waitUntil(timeout: .seconds(10)) { document.applicationStatusBannerMessage != nil })
            #expect(document.connectionLossBannerMessage == nil)
            await drainMainQueue()
            #expect(!server.receivedRequestTypes.contains(hierarchyRequest))
            #expect(document.inspectableApp === originalApp)
            #expect(document.inspectableApp.channel?.isConnected != true)
            #expect(windowController.hierarchyDataSource.rawHierarchyInfo?.appInfo?.appInfoIdentifier == 1)

            await #expect(throws: (any Error).self) {
                try await windowController.reloadHierarchy(initiator: .host)
            }
            #expect(document.inspectableApp === originalApp)
            #expect(document.applicationStatusBannerMessage != nil)
            #expect(windowController.hierarchyDataSource.rawHierarchyInfo?.appInfo?.appInfoIdentifier == 1)

            server.responders[hierarchyRequest] = { _ in hierarchy }
            let refreshed = try await windowController.reloadHierarchy(initiator: .host)
            #expect(refreshed?.appInfo?.appInfoIdentifier == 2)
            #expect(server.receivedRequestTypes.filter { $0 == hierarchyRequest }.count == 2)
            #expect(document.inspectableApp !== originalApp)
            #expect(windowController.hierarchyDataSource.rawHierarchyInfo?.appInfo?.appInfoIdentifier == 2)
            #expect(document.applicationStatusBannerMessage == nil)
            #expect(document.connectionLossBannerMessage == nil)
        }
    }
}
