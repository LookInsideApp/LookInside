import Darwin
import Foundation
import LookInsideInspectionProtocol
import Testing

@objc(LKHeadlessTestBundleAnchor)
private final class HeadlessTestBundleAnchor: NSObject {}

@Suite(.serialized)
@MainActor
struct InspectionProcessTests {
    private var productsDirectory: URL {
        Bundle(for: HeadlessTestBundleAnchor.self).bundleURL.deletingLastPathComponent()
    }

    @Test func `a symlinked bundled CLI starts one service that survives both launching clients`() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let contents = directory.appendingPathComponent("LookInside.app/Contents")
        let executables = contents.appendingPathComponent("MacOS")
        let resources = contents.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: executables, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: productsDirectory.appendingPathComponent("lookinside-service-fixture"), to: executables.appendingPathComponent("lookinside-service"))
        try FileManager.default.copyItem(at: productsDirectory.appendingPathComponent("lookinside-cli"), to: resources.appendingPathComponent("lookinside-cli"))
        try FileManager.default.createSymbolicLink(at: contents.appendingPathComponent("Frameworks"), withDestinationURL: productsDirectory)
        let commandURL = directory.appendingPathComponent("inspect")
        try FileManager.default.createSymbolicLink(at: commandURL, withDestinationURL: resources.appendingPathComponent("lookinside-cli"))
        var environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("DYLD_") }
        let runtime = directory.appendingPathComponent("run")
        environment["LOOKINSIDE_INSPECTION_RUNTIME_DIRECTORY"] = runtime.path
        let status = try await command(["service", "status"], executableURL: commandURL, environment: environment)
        #expect(status.status == 3)
        #expect(!FileManager.default.fileExists(atPath: runtime.path))
        async let first = command(["targets", "discover"], executableURL: commandURL, environment: environment)
        async let second = command(["targets", "discover"], executableURL: commandURL, environment: environment)
        let responses = try await [first, second]
        #expect(responses.allSatisfy { $0.status == 0 })
        let firstInstance = try envelope(responses[0].output)["serviceInstanceIdentifier"] as? String
        #expect(firstInstance != nil)
        #expect(try envelope(responses[1].output)["serviceInstanceIdentifier"] as? String == firstInstance)
        let health = try await command(["service", "status"], executableURL: commandURL, environment: environment)
        #expect(health.status == 0)
        let processIdentifier = try #require(try (envelope(health.output)["result"] as? [String: Any])?["processIdentifier"] as? Int32)
        kill(processIdentifier, SIGTERM)
        let socketPath = runtime.appendingPathComponent("lookinside-inspection.sock").path
        let deadline = ProcessInfo.processInfo.systemUptime + 3
        while FileManager.default.fileExists(atPath: socketPath), ProcessInfo.processInfo.systemUptime < deadline {
            try await Task.sleep(for: .milliseconds(25))
        }
        #expect(!FileManager.default.fileExists(atPath: socketPath))
    }

    @Test func `argument failures use JSON and the documented usage exit code`() async throws {
        let failure = try await command(["hierarchy", "read", "--depth", "-1"])
        #expect(failure.status == 2)
        #expect(try envelope(failure.output)["schemaVersion"] as? Int == 1)
        #expect(try (envelope(failure.output)["error"] as? [String: Any])?["code"] as? String == "arguments.invalid")
    }

    @Test func `an incompatible service is reported without replacing or stopping it`() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("inspection.sock").path
        let fixture = Process()
        fixture.executableURL = productsDirectory.appendingPathComponent("lookinside-service-fixture")
        fixture.arguments = [socketPath, "--status-only"]
        fixture.standardOutput = FileHandle.nullDevice
        fixture.standardError = FileHandle.nullDevice
        try fixture.run()
        defer { stop(fixture) }
        let initialStatus = try await waitForService(socketPath: socketPath)
        let discovery = try await command(["targets", "discover", "--socket-path", socketPath])
        #expect(discovery.status == 3)
        #expect(discovery.output.contains("service.incompatible"))
        let sessions = try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "sessions.list"), socketPath: socketPath)
        #expect(sessions.result?.objectValue?["sessions"] == .array([]))
        #expect(throws: InspectionFailure.self) {
            try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "fixture.incompatible"), socketPath: socketPath)
        }
        #expect(fixture.isRunning)
        let finalStatus = try await waitForService(socketPath: socketPath)
        #expect(finalStatus.metadata?.serviceInstanceIdentifier == initialStatus.metadata?.serviceInstanceIdentifier)
    }

    @Test func `a session cannot close while another connected CLI is capturing it`() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("inspection.sock").path
        let fixture = Process()
        fixture.executableURL = productsDirectory.appendingPathComponent("lookinside-service-fixture")
        fixture.arguments = [socketPath]
        fixture.standardOutput = FileHandle.nullDevice
        fixture.standardError = FileHandle.nullDevice
        try fixture.run()
        defer { stop(fixture) }
        _ = try await waitForService(socketPath: socketPath)
        let discovery = try await command(["targets", "discover", "--socket-path", socketPath])
        let targets = try #require(try (envelope(discovery.output)["result"] as? [String: Any])?["targets"] as? [[String: Any]])
        let targetIdentifier = try #require(targets.first?["targetIdentifier"] as? String)
        let opened = try await command(["sessions", "open", "--target", targetIdentifier, "--socket-path", socketPath])
        let sessionIdentifier = try #require(try envelope(opened.output)["sessionIdentifier"] as? String)
        let options = ["--session", sessionIdentifier, "--socket-path", socketPath]
        _ = try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "fixture.delay", parameters: ["seconds": .double(0.8)]), socketPath: socketPath)
        async let pendingRead = command(["hierarchy", "read"] + options)
        let deadline = ProcessInfo.processInfo.systemUptime + 3
        while true {
            let state = try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "fixture.state"), socketPath: socketPath)
            if state.result?.objectValue?["captures"]?.integerValue == 1 {
                break
            }
            guard ProcessInfo.processInfo.systemUptime < deadline else { throw InspectionFailure.internalError }
            try await Task.sleep(for: .milliseconds(10))
        }
        let busy = try await command(["sessions", "close"] + options)
        #expect(busy.status == 7)
        #expect(busy.output.contains("session.inUse"))
        let captured = try await pendingRead
        #expect(captured.status == 0)
        let closed = try await command(["sessions", "close"] + options)
        #expect(closed.status == 0)
    }

    @Test func `separate CLI invocations share captures and reject disconnected sessions`() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("inspection.sock").path
        let fixture = Process()
        fixture.executableURL = productsDirectory.appendingPathComponent("lookinside-service-fixture")
        fixture.arguments = [socketPath]
        fixture.standardOutput = FileHandle.nullDevice
        fixture.standardError = FileHandle.nullDevice
        try fixture.run()
        defer { stop(fixture) }
        _ = try await waitForService(socketPath: socketPath)

        let discovery = try await command(["targets", "discover", "--socket-path", socketPath])
        #expect(discovery.status == 0)
        let targets = try #require(try (envelope(discovery.output)["result"] as? [String: Any])?["targets"] as? [[String: Any]])
        #expect(targets.count == 2)
        let targetIdentifier = try #require(targets.first?["targetIdentifier"] as? String)
        #expect(targetIdentifier != targets.last?["targetIdentifier"] as? String)
        let opened = try await command(["sessions", "open", "--target", targetIdentifier, "--socket-path", socketPath])
        #expect(opened.status == 0)
        let sessionIdentifier = try #require(try envelope(opened.output)["sessionIdentifier"] as? String)
        let sessionOptions = ["--session", sessionIdentifier, "--socket-path", socketPath]
        let protectedRead = try await command(["hierarchy", "read", "--require-capability", "swiftui"] + sessionOptions)
        #expect(protectedRead.status == 5)

        let firstRead = try await command(["hierarchy", "read"] + sessionOptions)
        #expect(firstRead.status == 0)
        #expect(try envelope(firstRead.output)["hierarchyRevision"] as? Int == 1)
        #expect(try envelope(firstRead.output)["fromCache"] as? Bool == false)
        let cachedRead = try await command(["hierarchy", "read"] + sessionOptions)
        #expect(cachedRead.status == 0)
        #expect(try envelope(cachedRead.output)["hierarchyRevision"] as? Int == 1)
        #expect(try envelope(cachedRead.output)["fromCache"] as? Bool == true)

        let found = try await command(["views", "find", "--class-name", "NSButton"] + sessionOptions)
        #expect(found.status == 0)
        let attributes = try await command(["attributes", "read", "--object", "0x14"] + sessionOptions)
        #expect(attributes.status == 0)
        #expect(attributes.output.contains("Fixture button"))
        let outputPath = directory.appendingPathComponent("capture.png").path
        let screenshot = try await command(["screenshot", "--output", outputPath, "--fresh"] + sessionOptions)
        #expect(screenshot.status == 0)
        #expect(try Data(contentsOf: URL(fileURLWithPath: outputPath)).prefix(8) == Data([137, 80, 78, 71, 13, 10, 26, 10]))
        #expect(!screenshot.output.contains("imageBase64"))
        #expect(try envelope(screenshot.output)["hierarchyRevision"] as? Int == 2)
        let refreshed = try await command(["hierarchy", "refresh"] + sessionOptions)
        #expect(refreshed.status == 0)
        #expect(try envelope(refreshed.output)["hierarchyRevision"] as? Int == 3)

        let state = try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "fixture.state"), socketPath: socketPath)
        #expect(state.result?.objectValue?["headless"]?.booleanValue == true)
        #expect(state.result?.objectValue?["captures"]?.integerValue == 3)
        let otherTargetIdentifier = try #require(targets.last?["targetIdentifier"] as? String)
        let otherOpened = try await command(["sessions", "open", "--target", otherTargetIdentifier, "--socket-path", socketPath])
        let otherSessionIdentifier = try #require(try envelope(otherOpened.output)["sessionIdentifier"] as? String)
        let transportIdentifier = try #require(targets.first?["transportIdentifier"] as? String)
        _ = try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "fixture.disconnect", parameters: ["transportIdentifier": .string(transportIdentifier)]), socketPath: socketPath)
        let disconnected = try await command(["hierarchy", "read"] + sessionOptions)
        #expect(disconnected.status == 4)
        #expect(disconnected.output.contains("session.disconnected"))
        let closed = try await command(["sessions", "close"] + sessionOptions)
        #expect(closed.status == 0)
        let missing = try await command(["hierarchy", "read"] + sessionOptions)
        #expect(missing.status == 4)
        #expect(missing.output.contains("session.notFound"))
        let otherRead = try await command(["hierarchy", "read", "--session", otherSessionIdentifier, "--socket-path", socketPath])
        #expect(otherRead.status == 0)
    }

    private func envelope(_ output: String) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: Data(output.utf8)) as? [String: Any])
    }

    @Test func `help and an unavailable explicit socket never start a service`() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("inspection.sock").path
        let help = try await command(["--help"])
        #expect(help.status == 0)
        #expect(help.output.contains("lookinside-cli"))
        let status = try await command(["service", "status", "--socket-path", socketPath])
        #expect(status.status == 3)
        let response = try #require(JSONSerialization.jsonObject(with: Data(status.output.utf8)) as? [String: Any])
        #expect((response["error"] as? [String: Any])?["code"] as? String == "service.unavailable")
        let discovery = try await command(["targets", "discover", "--socket-path", socketPath])
        #expect(discovery.status == 3)
        #expect(!FileManager.default.fileExists(atPath: socketPath))
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
    }

    @Test func `concurrent services preserve one private socket and one instance`() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("inspection.sock").path
        let first = try service(socketPath: socketPath)
        let second = try service(socketPath: socketPath)
        defer { stop(first); stop(second) }
        let health = try await waitForService(socketPath: socketPath)
        let instance = try #require(health.metadata?.serviceInstanceIdentifier)
        try await Task.sleep(for: .milliseconds(100))
        #expect(first.isRunning != second.isRunning)
        let attributes = try FileManager.default.attributesOfItem(atPath: socketPath)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o600)
        let directoryAttributes = try FileManager.default.attributesOfItem(atPath: directory.path)
        #expect((directoryAttributes[.posixPermissions] as? NSNumber)?.intValue == 0o700)
        let status = try await command(["service", "status", "--socket-path", socketPath])
        #expect(status.status == 0)
        let response = try #require(JSONSerialization.jsonObject(with: Data(status.output.utf8)) as? [String: Any])
        #expect(response["serviceInstanceIdentifier"] as? String == instance)
        #expect(response["schemaVersion"] as? Int == 1)
    }

    @Test func `idle exit removes its socket and restart creates a new instance`() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("inspection.sock").path
        let first = try service(socketPath: socketPath, idleTimeout: "0.5")
        defer { stop(first) }
        let original = try await waitForService(socketPath: socketPath)
        try await waitForExit(first)
        #expect(first.terminationStatus == 0)
        #expect(!FileManager.default.fileExists(atPath: socketPath))
        let replacement = try service(socketPath: socketPath)
        defer { stop(replacement) }
        let renewed = try await waitForService(socketPath: socketPath)
        #expect(renewed.metadata?.serviceInstanceIdentifier != original.metadata?.serviceInstanceIdentifier)
    }

    @Test func `a stale socket is recovered without replacing unrelated files`() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("inspection.sock").path
        let original = try service(socketPath: socketPath)
        defer { stop(original) }
        _ = try await waitForService(socketPath: socketPath)
        kill(original.processIdentifier, SIGKILL)
        try await waitForExit(original)
        #expect(FileManager.default.fileExists(atPath: socketPath))
        let replacement = try service(socketPath: socketPath)
        defer { stop(replacement) }
        _ = try await waitForService(socketPath: socketPath)
        replacement.terminate()
        try await waitForExit(replacement)
        try Data("keep this file".utf8).write(to: URL(fileURLWithPath: socketPath))
        let refused = try service(socketPath: socketPath)
        defer { stop(refused) }
        try await waitForExit(refused)
        #expect(refused.terminationStatus != 0)
        #expect(try String(contentsOfFile: socketPath, encoding: .utf8) == "keep this file")
    }

    @Test func `the detached launcher creates a separate process session`() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("inspection.sock").path
        let childIdentifier = try InspectionServiceLauncher.launch(executableURL: productsDirectory.appendingPathComponent("lookinside-service"),
                                                                   arguments: ["--socket-path", socketPath, "--idle-timeout", "1"])
        defer { kill(childIdentifier, SIGTERM); var status: Int32 = 0; waitpid(childIdentifier, &status, WNOHANG) }
        let health = try await waitForService(socketPath: socketPath)
        #expect(health.result?.objectValue?["processIdentifier"]?.integerValue == Int64(childIdentifier))
        #expect(getsid(childIdentifier) == childIdentifier)
    }

    @Test func `injection returns a verified session and repeated calls reuse it`() async throws {
        try await withInjectionFixture("ready") { socketPath in
            let injected = try await command(["inject", "--process-identifier", "12345", "--socket-path", socketPath])
            #expect(injected.status == 0)
            let result = try #require(try envelope(injected.output)["result"] as? [String: Any])
            #expect(result["injectionStage"] as? String == "sessionReady")
            #expect(result["processIdentifier"] as? Int == 12345)
            let sessionIdentifier = try #require(result["sessionIdentifier"] as? String)
            let hierarchy = try await command(["hierarchy", "read", "--session", sessionIdentifier, "--socket-path", socketPath])
            #expect(hierarchy.status == 0)
            let repeated = try await command(["inject", "--process-identifier", "12345", "--socket-path", socketPath])
            #expect(repeated.status == 0)
            #expect(try (envelope(repeated.output)["result"] as? [String: Any])?["sessionIdentifier"] as? String == sessionIdentifier)
            let state = try injectionFixtureState(socketPath)
            #expect(state["injections"] == .integer(1))
            #expect(state["headless"] == .bool(true))
        }
    }

    @Test(arguments: [
        ("license", "injection.licenseRequired", Int32(5)),
        ("missing", "injection.helperMissing", 3),
        ("requiresApproval", "injection.approvalRequired", 3),
        ("notRegistered", "injection.helperNotEnabled", 3),
        ("unsupportedLocation", "injection.unsupportedLocation", 3),
        ("framework", "injection.preparationRequired", 3),
        ("changed", "injection.targetChanged", 4),
        ("absent", "injection.targetNotFound", 4),
    ])
    func `failed preparation never submits injection`(_ scenario: String, _ errorCode: String, _ exitStatus: Int32) async throws {
        try await withInjectionFixture(scenario) { socketPath in
            let response = try await command(["inject", "--process-identifier", "12345", "--socket-path", socketPath])
            #expect(response.status == exitStatus)
            let error = try #require(try envelope(response.output)["error"] as? [String: Any])
            #expect(error["code"] as? String == errorCode)
            #expect((error["details"] as? [String: Any])?["injectionStage"] as? String == "notSubmitted")
            #expect(try injectionFixtureState(socketPath)["injections"] == .integer(0))
        }
    }

    @Test func `injector status does not activate a license or submit injection`() async throws {
        try await withInjectionFixture("license") { socketPath in
            let response = try await command(["injector", "status", "--socket-path", socketPath])
            #expect(response.status == 0)
            #expect(try (envelope(response.output)["result"] as? [String: Any])?["state"] as? String == "enabled")
            #expect(try injectionFixtureState(socketPath)["injections"] == .integer(0))
        }
    }

    @Test(arguments: [
        ("oldServer", "injection.targetUnverified", "injected"),
        ("otherProcess", "injection.discoveryTimeout", "injected"),
        ("portReused", "injection.discoveryTimeout", "injected"),
        ("reused", "injection.targetChanged", "injected"),
        ("exited", "injection.targetNotFound", "injected"),
        ("lostReply", "injection.helperTimeout", "submissionUnknown"),
    ])
    func `unverified injection never connects to a different process or resubmits`(_ scenario: String, _ errorCode: String, _ stage: String) async throws {
        try await withInjectionFixture(scenario) { socketPath in
            let request = InspectionRequest(identifier: UUID().uuidString, method: "injection.inject",
                                            parameters: ["processIdentifier": .integer(12345), "waitTimeout": .double(0.2)])
            let response = try await Task.detached {
                try InspectionSocketClient.request(request, socketPath: socketPath, timeout: 3)
            }.value
            #expect(response.error?.code == errorCode)
            #expect(response.error?.details?["injectionStage"] == .string(stage))
            #expect(response.result == nil)
            if ["oldServer", "otherProcess", "portReused", "lostReply"].contains(scenario) {
                let repeated = try await Task.detached {
                    try InspectionSocketClient.request(request, socketPath: socketPath, timeout: 3)
                }.value
                #expect(repeated.error?.code == "injection.targetUnverified")
                #expect(repeated.error?.details?["injectionStage"] == .string(stage))
            }
            let state = try injectionFixtureState(socketPath)
            #expect(state["injections"] == .integer(1))
            #expect(state["sessions"] == .integer(0))
        }
    }

    @Test func `concurrent callers submit only one injection for the same process`() async throws {
        try await withInjectionFixture("delayed") { socketPath in
            let request = InspectionRequest(identifier: UUID().uuidString, method: "injection.inject",
                                            parameters: ["processIdentifier": .integer(12345)])
            let first = Task.detached { try InspectionSocketClient.request(request, socketPath: socketPath, timeout: 5) }
            defer { first.cancel() }
            let deadline = ProcessInfo.processInfo.systemUptime + 2
            while try injectionFixtureState(socketPath)["injections"] != .integer(1) {
                try #require(ProcessInfo.processInfo.systemUptime < deadline)
                try await Task.sleep(for: .milliseconds(10))
            }
            let second = try await Task.detached { try InspectionSocketClient.request(request, socketPath: socketPath, timeout: 3) }.value
            #expect(second.error?.code == "injection.alreadyInProgress")
            #expect(try await first.value.result?.objectValue?["injectionStage"] == .string("sessionReady"))
            #expect(try injectionFixtureState(socketPath)["injections"] == .integer(1))
        }
    }

    @Test func `cancelling a submitted injection never makes it safe to replay`() async throws {
        try await withInjectionFixture("cancelled") { socketPath in
            let connection = InspectionServiceConnection()
            try connection.connect(socketPath: socketPath)
            let first = Task {
                try await connection.request("injection.inject", parameters: ["processIdentifier": .integer(12345)])
            }
            let deadline = ProcessInfo.processInfo.systemUptime + 2
            while try injectionFixtureState(socketPath)["injections"] != .integer(1) {
                try #require(ProcessInfo.processInfo.systemUptime < deadline)
                try await Task.sleep(for: .milliseconds(10))
            }
            first.cancel()
            connection.close()
            _ = await first.result
            let request = InspectionRequest(identifier: UUID().uuidString, method: "injection.inject",
                                            parameters: ["processIdentifier": .integer(12345), "waitTimeout": .double(0.2)])
            // Wait for cancellation to cross the process boundary.
            var repeated: InspectionResponse
            repeat {
                try await Task.sleep(for: .milliseconds(25))
                repeated = try await Task.detached { try InspectionSocketClient.request(request, socketPath: socketPath, timeout: 3) }.value
            } while repeated.error?.code == "injection.alreadyInProgress" && ProcessInfo.processInfo.systemUptime < deadline
            #expect(repeated.error?.code == "injection.targetUnverified")
            #expect(try injectionFixtureState(socketPath)["injections"] == .integer(1))
        }
    }

    @Test func submittedInjectionDoesNotRestartServiceAfterLostReply() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("lookinside-inspection.sock").path
        let fixture = Process()
        fixture.executableURL = productsDirectory.appendingPathComponent("lookinside-service-fixture")
        fixture.arguments = [socketPath, "--lose-service-reply"]
        fixture.standardOutput = FileHandle.nullDevice
        fixture.standardError = FileHandle.nullDevice
        try fixture.run()
        defer { stop(fixture) }
        _ = try await waitForService(socketPath: socketPath)
        var environment = ProcessInfo.processInfo.environment
        environment["LOOKINSIDE_INSPECTION_RUNTIME_DIRECTORY"] = directory.path
        // Leave the default startup path enabled. A replay attempt would fail
        // with service.launchFailed because this test CLI is outside an App.
        let response = try await command(["inject", "--process-identifier", "12345"], environment: environment)
        let failure = try #require(try envelope(response.output)["error"] as? [String: Any])
        #expect(response.status == 3)
        #expect(failure["code"] as? String == "service.unavailable")
        #expect((failure["details"] as? [String: Any])?["injectionStage"] as? String == "submissionUnknown")
        try await waitForExit(fixture)
        #expect(fixture.terminationStatus == 73)
    }

    @Test(arguments: ["0", "-1", "1", "2147483648"])
    func `injection rejects invalid process identifiers before connecting`(_ identifier: String) async throws {
        let response = try await command(["inject", "--process-identifier", identifier])
        #expect(response.status == 2)
        #expect(try (envelope(response.output)["error"] as? [String: Any])?["code"] as? String == "arguments.invalid")
    }

    private func injectionFixtureState(_ socketPath: String) throws -> [String: InspectionValue] {
        try #require(InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "fixture.state"),
                                                    socketPath: socketPath).result?.objectValue)
    }

    private func withInjectionFixture(_ scenario: String, operation: (String) async throws -> Void) async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let socketPath = directory.appendingPathComponent("inspection.sock").path
        let fixture = Process()
        fixture.executableURL = productsDirectory.appendingPathComponent("lookinside-service-fixture")
        fixture.arguments = [socketPath, "--injection", scenario]
        fixture.standardOutput = FileHandle.nullDevice
        fixture.standardError = FileHandle.nullDevice
        fixture.standardInput = FileHandle.nullDevice
        try fixture.run()
        defer { stop(fixture) }
        _ = try await waitForService(socketPath: socketPath)
        try await operation(socketPath)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = URL(fileURLWithPath: "/tmp").appendingPathComponent("lookinside-headless-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        return directory
    }

    private func service(socketPath: String, idleTimeout: String = "30") throws -> Process {
        let process = Process()
        process.executableURL = productsDirectory.appendingPathComponent("lookinside-service")
        process.arguments = ["--socket-path", socketPath, "--idle-timeout", idleTimeout]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        return process
    }

    private func command(_ arguments: [String], executableURL: URL? = nil, environment: [String: String]? = nil) async throws -> (status: Int32, output: String) {
        let process = Process()
        let output = Pipe()
        process.executableURL = executableURL ?? productsDirectory.appendingPathComponent("lookinside-cli")
        // XCTest's loader overrides can hide invalid framework install names in
        // bundled command-line tools. Exercise the paths an installed App uses.
        process.environment = (environment ?? ProcessInfo.processInfo.environment).filter { !$0.key.hasPrefix("DYLD_") }
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        try process.run()
        defer { stop(process) }
        try await waitForExit(process)
        return (process.terminationStatus, String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self))
    }

    private func waitForService(socketPath: String) async throws -> InspectionResponse {
        let deadline = ProcessInfo.processInfo.systemUptime + 5
        while true {
            do { return try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "service.status"), socketPath: socketPath, timeout: 0.2) }
            catch {
                guard ProcessInfo.processInfo.systemUptime < deadline else { throw error }
                try await Task.sleep(for: .milliseconds(25))
            }
        }
    }

    private func waitForExit(_ process: Process) async throws {
        let deadline = ProcessInfo.processInfo.systemUptime + 8
        while process.isRunning {
            guard ProcessInfo.processInfo.systemUptime < deadline else { throw InspectionFailure(code: "operation.timeout", message: "The child process did not exit.") }
            try await Task.sleep(for: .milliseconds(25))
        }
    }

    private func stop(_ process: Process) {
        guard process.isRunning else { return }
        process.terminate()
    }
}
