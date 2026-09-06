import AppKit
import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol
import Testing

@objc(LKSharedClientsTestAnchor)
private final class SharedClientsTestAnchor: NSObject {}

@Suite(.serialized) @MainActor
struct InspectionSharedClientsTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["LOOKINSIDE_MCP_TEST_EXECUTABLE"] != nil))
    func `a bundled MCP starts the service without a graphical application`() async throws {
        let executable = try #require(ProcessInfo.processInfo.environment["LOOKINSIDE_MCP_TEST_EXECUTABLE"])
        let directory = URL(fileURLWithPath: "/tmp/codex").appendingPathComponent("mcp-start-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let contents = directory.appendingPathComponent("LookInside.app/Contents")
        let resources = contents.appendingPathComponent("Resources")
        let executables = contents.appendingPathComponent("MacOS")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: executables, withIntermediateDirectories: true)
        let products = Bundle(for: SharedClientsTestAnchor.self).bundleURL.deletingLastPathComponent()
        try FileManager.default.copyItem(at: products.appendingPathComponent("lookinside-service-fixture"), to: executables.appendingPathComponent("lookinside-service"))
        let bundledClient = resources.appendingPathComponent("lookinside-mcp")
        try FileManager.default.copyItem(at: URL(fileURLWithPath: executable), to: bundledClient)
        try FileManager.default.createSymbolicLink(at: contents.appendingPathComponent("Frameworks"), withDestinationURL: products)
        let runtime = directory.appendingPathComponent("run")
        let client = try InspectionTestProcess(executable: bundledClient, runtimeDirectory: runtime)
        defer { client.stop() }
        try await client.initialize()
        #expect(!FileManager.default.fileExists(atPath: runtime.path))
        let targets = try await client.tool("discover_targets")
        #expect((targets as? [Any])?.count == 2)
        let socketPath = runtime.appendingPathComponent("lookinside-inspection.sock").path
        let status = try InspectionSocketClient.request(.init(identifier: UUID().uuidString, method: "service.status"), socketPath: socketPath)
        let processIdentifier = try #require(status.result?.objectValue?["processIdentifier"]?.integerValue)
        defer { kill(pid_t(processIdentifier), SIGTERM) }
        #expect(try fixtureState(socketPath)["headless"] == .bool(true))
        client.stop()
        let afterClientExit = try InspectionSocketClient.request(.init(identifier: UUID().uuidString, method: "service.status"), socketPath: socketPath)
        #expect(afterClientExit.metadata?.serviceInstanceIdentifier == status.metadata?.serviceInstanceIdentifier)
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["LOOKINSIDE_MCP_TEST_EXECUTABLE"] != nil))
    func `two MCP executables CLI and the graphical adapter share sessions mutations and events`() async throws {
        let executable = try #require(ProcessInfo.processInfo.environment["LOOKINSIDE_MCP_TEST_EXECUTABLE"])
        let directory = URL(fileURLWithPath: "/tmp/codex").appendingPathComponent("four-clients-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("service.sock").path
        let products = Bundle(for: SharedClientsTestAnchor.self).bundleURL.deletingLastPathComponent()
        let fixture = try InspectionTestProcess(executable: products.appendingPathComponent("lookinside-service-fixture"), arguments: [socketPath])
        defer { fixture.stop() }
        let graphicalClient = InspectionServiceClient(socketPath: socketPath)
        graphicalClient.initialCaptureOptionsProvider = { ["showBackingLayers": true] }
        defer { graphicalClient.disconnect() }
        try await waitUntil {
            do { try await graphicalClient.connect(); return true } catch { return false }
        }
        let first = try InspectionTestProcess(executable: URL(fileURLWithPath: executable), socketPath: socketPath)
        let second = try InspectionTestProcess(executable: URL(fileURLWithPath: executable), socketPath: socketPath)
        defer { first.stop(); second.stop() }
        try await first.initialize()
        try await second.initialize()
        let discovered = try await first.tool("discover_targets")
        let targets = try #require(discovered as? [[String: Any]], "\(discovered)")
        let targetIdentifier = try #require(targets.first?["targetIdentifier"] as? String)
        let attached = try await first.tool("attach_target", arguments: ["targetIdentifier": targetIdentifier])
        let sessionIdentifier = try #require((attached as? [String: Any])?["targetIdentifier"] as? String)
        let secondAttached = try await second.tool("attach_target", arguments: ["targetIdentifier": targetIdentifier])
        #expect((secondAttached as? [String: Any])?["targetIdentifier"] as? String == sessionIdentifier)
        let applications = try await InspectionSignalAwaiter.allValues(of: graphicalClient.discoverApplications(), as: [InspectableApp].self)
        let application = try #require(applications.first?.first)
        let session = try #require(application.inspectionSession)
        session.retainClientReference()
        let graphicalHierarchy = Task { @MainActor in
            _ = try await InspectionSignalAwaiter.allValues(of: application.fetchHierarchyData(), as: LookinHierarchyInfo.self)
        }
        let automationHierarchy = Task { @MainActor in
            _ = try await first.tool("get_hierarchy", arguments: ["targetIdentifier": sessionIdentifier])
        }
        defer { graphicalHierarchy.cancel(); automationHierarchy.cancel() }
        try await graphicalHierarchy.value
        try await automationHierarchy.value
        #expect(session.sessionIdentifier == sessionIdentifier)
        #expect(session.captureOptions["showBackingLayers"] as? Bool != true)
        #expect(try fixtureState(socketPath)["captures"] == .integer(1))
        #expect(try fixtureState(socketPath)["sessions"] == .integer(1))
        #expect(application.channel == nil)
        #expect(NSApp == nil)

        let command = try InspectionTestProcess(executable: products.appendingPathComponent("lookinside-cli"),
                                                arguments: ["hierarchy", "read", "--session", sessionIdentifier, "--socket-path", socketPath])
        defer { command.stop() }
        try await waitUntil { !command.process.isRunning }
        #expect(command.process.terminationStatus == 0)
        #expect(command.output.messages().first?["hierarchyRevision"] as? Int == 1)
        #expect(try fixtureState(socketPath)["captures"] == .integer(1))

        let snapshot = try await first.tool("capture_snapshot", arguments: ["targetIdentifier": sessionIdentifier, "refreshFirst": false])
        #expect((snapshot as? [String: Any])?["snapshot"] != nil)
        let otherSnapshots = try await second.tool("list_snapshots")
        #expect((otherSnapshots as? [Any])?.isEmpty == true)
        let hierarchyResource = "lookinside://targets/\(sessionIdentifier)/hierarchy"
        _ = try await first.request("resources/subscribe", parameters: ["uri": hierarchyResource])
        _ = try await second.request("resources/subscribe", parameters: ["uri": hierarchyResource])
        let firstStart = first.output.messages().count
        let secondStart = second.output.messages().count
        _ = try await first.tool("refresh_hierarchy", arguments: ["targetIdentifier": sessionIdentifier])
        try await waitUntil {
            session.hierarchyRevision == 2 && second.output.hasResourceUpdate(hierarchyResource, after: secondStart)
        }
        #expect(!first.output.hasResourceUpdate(hierarchyResource, after: firstStart))
        #expect(try session.readHierarchy().displayItems.first?.frame.width == 42)

        _ = try await first.tool("read_view_details", arguments: ["targetIdentifier": sessionIdentifier, "objectIdentifiers": ["0x14"]])
        let selectors = try await second.tool("list_class_methods", arguments: ["targetIdentifier": sessionIdentifier, "objectIdentifier": "0x14"])
        #expect((selectors as? [String: Any])?["selectors"] as? [String] == ["description", "title", "performClick:"])
        let modified = try await first.tool("modify_attribute", arguments: [
            "targetIdentifier": sessionIdentifier, "objectIdentifier": "0x14", "attributeIdentifier": "NSButton_Title_Title",
            "value": ["kind": "string", "data": "Changed through MCP"],
        ])
        #expect((modified as? [String: Any])?["effectiveMatchesRequested"] as? Bool == true)
        try await waitUntil {
            let attributes = session.rawHierarchyInfo?.displayItems.first?.attributesGroupList.first?.attrSections.first?.attributes
            return attributes?.first?.value as? String == "Changed through MCP"
        }
        let invoked = try await second.tool("invoke_method", arguments: [
            "targetIdentifier": sessionIdentifier, "objectIdentifier": "0x14", "selector": "description",
        ])
        #expect((invoked as? [String: Any])?["description"] as? String == "Fixture invocation 1")
        let invocationState = (invoked as? [String: Any])?["inspectionState"] as? [String: Any]
        #expect(invocationState?["requiresRefresh"] as? Bool == true)
        #expect(invocationState?["hierarchyRevision"] as? Int == 2)
        #expect(try fixtureState(socketPath)["invocations"] == .integer(1))

        _ = try await first.tool("detach_target", arguments: ["targetIdentifier": sessionIdentifier])
        first.stop()
        session.releaseClientReference()
        _ = try await second.tool("get_hierarchy", arguments: ["targetIdentifier": sessionIdentifier])
        _ = try InspectionSocketClient.request(.init(identifier: UUID().uuidString, method: "fixture.loseInvocationReply"), socketPath: socketPath)
        let uncertain = try await second.request("tools/call", parameters: [
            "name": "invoke_method", "arguments": ["targetIdentifier": sessionIdentifier, "objectIdentifier": "0x14", "selector": "description"],
        ])
        #expect(uncertain["isError"] as? Bool == true)
        #expect(String(describing: uncertain).contains("invoke.executionUnknown"))
        #expect(try fixtureState(socketPath)["invocations"] == .integer(2))
        #expect(try fixtureState(socketPath)["headless"] == .bool(true))
    }

    private func fixtureState(_ socketPath: String) throws -> [String: InspectionValue] {
        try #require(InspectionSocketClient.request(.init(identifier: UUID().uuidString, method: "fixture.state"),
                                                    socketPath: socketPath).result?.objectValue)
    }

    private func waitUntil(_ condition: () async throws -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while try await !condition() {
            guard ContinuousClock.now < deadline else { throw InspectionFailure(code: "test.timeout", message: "A shared-client condition did not become true.") }
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    @Test func `graphical projections CLI and another client share one authoritative capture`() async throws {
        let directory = URL(fileURLWithPath: "/tmp/codex").appendingPathComponent("shared-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("service.sock").path
        let products = Bundle(for: SharedClientsTestAnchor.self).bundleURL.deletingLastPathComponent()
        let fixture = Process()
        fixture.executableURL = products.appendingPathComponent("lookinside-service-fixture")
        fixture.arguments = [socketPath]
        fixture.standardOutput = FileHandle.nullDevice
        fixture.standardError = FileHandle.nullDevice
        try fixture.run()
        defer {
            fixture.terminate()
            fixture.waitUntilExit()
        }
        let graphicalClient = InspectionServiceClient(socketPath: socketPath)
        defer { graphicalClient.disconnect() }
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while true {
            do { try await graphicalClient.connect(); break }
            catch {
                guard ContinuousClock.now < deadline else { throw error }
                try await Task.sleep(for: .milliseconds(20))
            }
        }
        let applications = try await InspectionSignalAwaiter.allValues(of: graphicalClient.discoverApplications(), as: [InspectableApp].self)
        let application = try #require(applications.first?.first)
        let session = try #require(application.inspectionSession)
        session.retainClientReference()
        let hierarchies = try await InspectionSignalAwaiter.allValues(of: application.fetchHierarchyData(), as: LookinHierarchyInfo.self)
        #expect(hierarchies.count == 1)
        #expect(session.hierarchyRevision == 1)
        #expect(application.channel == nil)
        #expect(NSApp == nil)

        let secondClient = InspectionServiceConnection()
        try secondClient.connect(socketPath: socketPath)
        defer { secondClient.close() }
        let retained = try await secondClient.request("sessions.retain", parameters: ["sessionIdentifier": .string(session.sessionIdentifier)])
        #expect(retained.error == nil)
        let hierarchy = try await secondClient.request("hierarchy.read", parameters: ["targetIdentifier": .string(session.sessionIdentifier)])
        #expect(hierarchy.error == nil)
        let state = try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "fixture.state"), socketPath: socketPath)
        #expect(state.result?.objectValue?["captures"] == .integer(1))

        let refreshed = try await secondClient.request("hierarchy.refresh", parameters: [
            "targetIdentifier": .string(session.sessionIdentifier), "clientIdentifier": .string("second-agent"),
        ])
        #expect(refreshed.error == nil)
        let refreshDeadline = ContinuousClock.now.advanced(by: .seconds(5))
        while session.hierarchyRevision < 2 {
            guard ContinuousClock.now < refreshDeadline else {
                Issue.record("The graphical mirror did not receive the other client's committed capture.")
                return
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(try session.readHierarchy().displayItems.first?.frame.width == 42)
        let changedOptions = try await secondClient.request("session.captureOptions", parameters: [
            "sessionIdentifier": .string(session.sessionIdentifier), "connectionGeneration": .integer(1),
            "hierarchyRevision": .integer(1), "options": .object(["showBackingLayers": .bool(true)]),
        ])
        #expect(changedOptions.error?.code == "session.stale")
        #expect(session.captureOptions["showBackingLayers"] as? Bool != true)

        _ = try await secondClient.request("session.request", parameters: [
            "sessionIdentifier": .string(session.sessionIdentifier), "requestType": .integer(203),
        ])
        _ = try InspectionSocketClient.request(.init(identifier: UUID().uuidString, method: "fixture.partialDetails"), socketPath: socketPath)
        _ = try await secondClient.request("session.request", parameters: [
            "sessionIdentifier": .string(session.sessionIdentifier), "requestType": .integer(203),
        ])
        let accumulated = try await secondClient.request("hierarchy.cachedDetails", parameters: ["sessionIdentifier": .string(session.sessionIdentifier)])
        let transfer = try #require(accumulated.result?.objectValue?["transfer"])
        let completeDetails = try #require(InspectionModelArchive.decode(await secondClient.download(transfer.decode(InspectionTransferManifest.self))) as? [LookinDisplayItemDetail])
        #expect(completeDetails.first?.attributesGroupList?.first?.attrSections?.first?.attributes?.first?.value as? String == "Fixture button")
        #expect(completeDetails.first?.alphaValue == 0.25)

        _ = try InspectionSocketClient.request(.init(identifier: UUID().uuidString, method: "fixture.disconnect", parameters: [
            "transportIdentifier": .string(application.transportIdentifier),
        ]), socketPath: socketPath)
        do { try await waitUntil { session.connectionLossBannerMessage != nil } }
        catch { throw InspectionFailure(code: "test.disconnect", message: "The mirror missed the disconnect event: \(application.transportIdentifier ?? "nil")") }
        #expect(try session.readHierarchy().displayItems.first?.frame.width == 42)
        _ = try InspectionSocketClient.request(.init(identifier: UUID().uuidString, method: "fixture.reconnect", parameters: [
            "transportIdentifier": .string(application.transportIdentifier),
        ]), socketPath: socketPath)
        do { try await waitUntil { session.connectionGeneration == 2 && session.hierarchyRevision == 3 } }
        catch {
            let state = try await secondClient.request("session.state", parameters: ["sessionIdentifier": .string(session.sessionIdentifier)])
            throw InspectionFailure(code: "test.reconnect", message: "Mirror generation \(session.connectionGeneration), revision \(session.hierarchyRevision), error \(session.connectionLossBannerMessage ?? "nil"); service \(state)")
        }
        #expect(session.connectionLossBannerMessage == nil)
        #expect(try session.readHierarchy().displayItems.first?.frame.width == 41)

        session.releaseClientReference()
        let stillReadable = try await secondClient.request("hierarchy.read", parameters: ["targetIdentifier": .string(session.sessionIdentifier)])
        #expect(stillReadable.error == nil)
        let cannotClose = try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "sessions.close",
                                                                               parameters: ["sessionIdentifier": .string(session.sessionIdentifier)]), socketPath: socketPath)
        #expect(cannotClose.error?.code == "session.inUse")
        #expect(NSApp == nil)
    }
}

@MainActor
private final class InspectionTestProcess {
    let process = Process()
    let output = InspectionTestOutput()
    private let input = Pipe()
    private let resultPipe = Pipe()

    init(executable: URL, arguments: [String] = [], socketPath: String? = nil, runtimeDirectory: URL? = nil) throws {
        process.executableURL = executable
        process.arguments = arguments
        var environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("DYLD_") }
        if let socketPath {
            environment["LOOKINSIDE_MCP_SOCKET_PATH"] = socketPath
        }
        if let runtimeDirectory {
            environment.removeValue(forKey: "LOOKINSIDE_MCP_SOCKET_PATH")
            environment["LOOKINSIDE_INSPECTION_RUNTIME_DIRECTORY"] = runtimeDirectory.path
        }
        process.environment = environment
        process.standardInput = input
        process.standardOutput = resultPipe
        process.standardError = FileHandle.nullDevice
        let output = output
        resultPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
            } else {
                output.append(data)
            }
        }
        try process.run()
    }

    func stop() {
        try? input.fileHandleForWriting.close()
        if process.isRunning {
            process.terminate(); process.waitUntilExit()
        }
        resultPipe.fileHandleForReading.readabilityHandler = nil
    }

    func initialize() async throws {
        _ = try await request("initialize", parameters: [
            "protocolVersion": "2024-11-05", "capabilities": [:],
            "clientInfo": ["name": "shared-inspection-test", "version": "1"],
        ])
        try write(["jsonrpc": "2.0", "method": "notifications/initialized"])
    }

    func tool(_ name: String, arguments: [String: Any] = [:]) async throws -> Any {
        let result = try await request("tools/call", parameters: ["name": name, "arguments": arguments])
        guard result["isError"] as? Bool != true else {
            throw InspectionFailure(code: "test.toolFailed", message: "\(name): \(result)")
        }
        if let structured = result["structuredContent"] {
            return structured
        }
        let contents = result["content"] as? [[String: Any]]
        let text = try #require(contents?.first?["text"] as? String, "\(name): \(result)")
        return try JSONSerialization.jsonObject(with: Data(text.utf8), options: .fragmentsAllowed)
    }

    func request(_ method: String, parameters: [String: Any]) async throws -> [String: Any] {
        let identifier = UUID().uuidString
        try write(["jsonrpc": "2.0", "id": identifier, "method": method, "params": parameters])
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while true {
            if let response = output.messages().first(where: { $0["id"] as? String == identifier }) {
                guard let result = response["result"] as? [String: Any] else {
                    throw InspectionFailure(code: "test.invalidResponse", message: "\(method): \(response)")
                }
                return result
            }
            guard process.isRunning, ContinuousClock.now < deadline else {
                throw InspectionFailure(code: "test.timeout", message: "\(method): \(output.messages())")
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    private func write(_ message: [String: Any]) throws {
        var data = try JSONSerialization.data(withJSONObject: message)
        data.append(10)
        try input.fileHandleForWriting.write(contentsOf: data)
    }
}

private final class InspectionTestOutput: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ bytes: Data) {
        lock.withLock { data.append(bytes) }
    }

    func messages() -> [[String: Any]] {
        let bytes = lock.withLock { data }
        return bytes.split(separator: 10).compactMap { try? JSONSerialization.jsonObject(with: Data($0)) as? [String: Any] }
    }

    func hasResourceUpdate(_ resource: String, after index: Int) -> Bool {
        messages().dropFirst(index).contains {
            $0["method"] as? String == "notifications/resources/updated"
                && ($0["params"] as? [String: Any])?["uri"] as? String == resource
        }
    }
}
