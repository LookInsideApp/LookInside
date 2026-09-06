import ArgumentParser
import Darwin
import Foundation
import LookInsideInspectionProtocol

@main
struct InspectionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lookinside-cli", abstract: "Inspect applications through LookInside's headless service.", version: "1",
        subcommands: [ServiceCommand.self, TargetsCommand.self, SessionsCommand.self, HierarchyCommand.self, ViewsCommand.self, AttributesCommand.self, ScreenshotCommand.self, InjectorCommand.self, InjectCommand.self]
    )

    static func main() {
        var command: any ParsableCommand
        do { command = try parseAsRoot() }
        catch {
            if exitCode(for: error) == .success {
                exit(withError: error)
            }
            emitFailure(InspectionFailure(code: "arguments.invalid", message: message(for: error)))
            Darwin.exit(2)
        }
        do { try command.run() }
        catch let status as ExitCode { Darwin.exit(status.rawValue) }
        catch {
            if exitCode(for: error) == .success {
                exit(withError: error)
            }
            emitFailure(InspectionFailure(code: "dispatch.internalError", message: error.localizedDescription))
            Darwin.exit(1)
        }
    }

    private static func emitFailure(_ failure: InspectionFailure) {
        let envelope: InspectionValue = .object(["schemaVersion": .integer(1), "error": .object(["code": .string(failure.code), "message": .string(failure.message)])])
        if let data = try? JSONEncoder().encode(envelope) {
            FileHandle.standardOutput.write(data + Data([0x0A]))
        }
    }
}

struct CommandOptions: ParsableArguments {
    @Option(help: "Connect to this absolute socket path without starting a service.") var socketPath: String?
    @Option(help: "Output format: json or text.") var format: OutputFormat = .json
    @Option(help: "Request timeout in seconds.") var timeout: Double = 30
    @Option(help: "Require a verified target capability (swiftui).") var requireCapability: String?

    mutating func validate() throws {
        guard timeout.isFinite, timeout > 0, timeout <= 300 else { throw ValidationError("--timeout must be greater than zero and at most 300 seconds.") }
        if let requireCapability, requireCapability != "swiftui" {
            throw ValidationError("--require-capability supports swiftui.")
        }
        _ = try InspectionRuntimePaths(socketPath: socketPath)
    }

    func perform(method: String, parameters: [String: InspectionValue] = [:], startsService: Bool = true,
                 outputFile: String? = nil) throws
    {
        var commandWasSubmitted = false
        do {
            let paths = try InspectionRuntimePaths(socketPath: socketPath)
            var parameters = parameters
            if let requireCapability {
                parameters["requiredCapability"] = .string(requireCapability)
            }
            let request = InspectionRequest(identifier: UUID().uuidString, method: method, parameters: parameters)
            func sendCommand() throws -> InspectionResponse {
                let statusRequest = method == "service.status" ? request : InspectionRequest(identifier: UUID().uuidString, method: "service.status")
                let status = try InspectionSocketClient.request(statusRequest, socketPath: paths.socketPath, timeout: timeout)
                try InspectionCapabilities.validate(status, supporting: method)
                if method == "service.status" {
                    return status
                }
                commandWasSubmitted = true
                let response = try InspectionSocketClient.request(request, socketPath: paths.socketPath, timeout: timeout)
                guard response.metadata?.serviceInstanceIdentifier == status.metadata?.serviceInstanceIdentifier else {
                    throw InspectionFailure(code: "service.restarted", message: "The service restarted during the command. Discover targets and open a new session.")
                }
                return response
            }
            var response: InspectionResponse
            do {
                response = try sendCommand()
            } catch let failure as InspectionFailure where failure.code == "service.unavailable" && !commandWasSubmitted && startsService && socketPath == nil {
                let executableURL = Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0])
                let serviceURL = try InspectionServiceLauncher.bundledServiceURL(executableURL: executableURL)
                _ = try InspectionServiceLauncher.launch(executableURL: serviceURL)
                let deadline = ProcessInfo.processInfo.systemUptime + min(timeout, 10)
                while true {
                    do {
                        _ = try InspectionSocketClient.request(InspectionRequest(identifier: UUID().uuidString, method: "service.status"),
                                                               socketPath: paths.socketPath, timeout: min(timeout, 1))
                        break
                    } catch let startupFailure as InspectionFailure where startupFailure.code == "service.unavailable" {
                        guard ProcessInfo.processInfo.systemUptime < deadline else { throw startupFailure }
                        Thread.sleep(forTimeInterval: 0.05)
                    }
                }
                response = try sendCommand()
            }
            if let outputFile, response.error == nil {
                guard let encodedImage = response.result?.objectValue?["imageBase64"]?.stringValue,
                      let image = Data(base64Encoded: encodedImage), !image.isEmpty
                else {
                    throw InspectionFailure(code: "service.invalidResponse", message: "The service did not return a screenshot.")
                }
                do { try image.write(to: URL(fileURLWithPath: outputFile), options: .atomic) }
                catch { throw InspectionFailure(code: "output.invalid", message: "Cannot write the screenshot: \(error.localizedDescription)") }
                var result = response.result?.objectValue ?? [:]
                result.removeValue(forKey: "imageBase64")
                result["outputPath"] = .string(URL(fileURLWithPath: outputFile).standardizedFileURL.path)
                response = InspectionResponse(identifier: response.identifier, result: .object(result), error: nil, metadata: response.metadata)
            }
            try emit(response)
            if let failure = response.error {
                throw ExitCode(InspectionExitStatus.code(for: failure))
            }
        } catch let failure as InspectionFailure {
            var reported = failure
            if method == "injection.inject", commandWasSubmitted, failure.details == nil {
                reported = InspectionFailure(code: failure.code, message: failure.message,
                                             details: ["injectionStage": .string("submissionUnknown")])
            }
            try emit(InspectionResponse(identifier: "", result: nil, error: reported, metadata: InspectionMetadata()))
            throw ExitCode(InspectionExitStatus.code(for: failure))
        }
    }

    private func emit(_ response: InspectionResponse) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var envelope = try (JSONSerialization.jsonObject(with: encoder.encode(response.metadata ?? InspectionMetadata()))) as? [String: Any] ?? [:]
        if let result = response.result {
            envelope["result"] = try JSONSerialization.jsonObject(with: encoder.encode(result), options: .fragmentsAllowed)
        }
        if let failure = response.error {
            envelope["error"] = try JSONSerialization.jsonObject(with: encoder.encode(failure))
        }
        let data = try JSONSerialization.data(withJSONObject: envelope, options: format == .text ? [.prettyPrinted, .sortedKeys] : [.sortedKeys])
        FileHandle.standardOutput.write(data + Data([0x0A]))
    }
}

enum OutputFormat: String, ExpressibleByArgument { case json, text }

struct ServiceCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "service", subcommands: [Status.self])
    struct Status: ParsableCommand {
        @OptionGroup var options: CommandOptions
        mutating func run() throws {
            try options.perform(method: "service.status", startsService: false)
        }
    }
}

struct InjectorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "injector", subcommands: [Status.self])
    struct Status: ParsableCommand {
        @OptionGroup var options: CommandOptions
        mutating func run() throws {
            try options.perform(method: "injector.status")
        }
    }
}

struct InjectCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "inject", abstract: "Inject the prepared LookInsideServer into a selected running macOS application and open its inspection session.")
    @OptionGroup var options: CommandOptions
    @Option(help: "The explicitly selected process identifier. The process must belong to the current user.")
    var processIdentifier: Int32

    mutating func validate() throws {
        guard processIdentifier > 1 else { throw ValidationError("--process-identifier must identify a running application, greater than 1.") }
        guard options.timeout >= 5 else { throw ValidationError("Injection requires --timeout of at least 5 seconds.") }
        guard options.requireCapability == nil else { throw ValidationError("Use --require-capability when reading the returned inspection session.") }
    }

    mutating func run() throws {
        try options.perform(method: "injection.inject", parameters: [
            "processIdentifier": .integer(Int64(processIdentifier)),
            "waitTimeout": .double(min(25, options.timeout - 1)),
        ])
    }
}

struct TargetsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "targets", subcommands: [Discover.self])
    struct Discover: ParsableCommand {
        @OptionGroup var options: CommandOptions
        mutating func run() throws {
            try options.perform(method: "targets.discover")
        }
    }
}

struct SessionsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "sessions", subcommands: [Open.self, List.self, Close.self])
    struct Open: ParsableCommand {
        @OptionGroup var options: CommandOptions
        @Option var target: String
        mutating func run() throws {
            try options.perform(method: "sessions.open", parameters: ["targetIdentifier": .string(target)])
        }
    }

    struct List: ParsableCommand {
        @OptionGroup var options: CommandOptions
        mutating func run() throws {
            try options.perform(method: "sessions.list")
        }
    }

    struct Close: ParsableCommand {
        @OptionGroup var options: CommandOptions
        @Option var session: String
        mutating func run() throws {
            try options.perform(method: "sessions.close", parameters: ["sessionIdentifier": .string(session)])
        }
    }
}

struct HierarchyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "hierarchy", subcommands: [Read.self, Refresh.self])
    struct Read: ParsableCommand {
        @OptionGroup var options: CommandOptions
        @Option var session: String
        @Option var depth: Int = 4
        mutating func validate() throws {
            guard depth >= 0, depth <= 100 else { throw ValidationError("--depth must be between 0 and 100.") }
        }

        mutating func run() throws {
            try options.perform(method: "hierarchy.read", parameters: ["sessionIdentifier": .string(session), "depth": .integer(Int64(depth))])
        }
    }

    struct Refresh: ParsableCommand {
        @OptionGroup var options: CommandOptions
        @Option var session: String
        mutating func run() throws {
            try options.perform(method: "hierarchy.refresh", parameters: ["sessionIdentifier": .string(session)])
        }
    }
}

struct ViewsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "views", subcommands: [Find.self])
    struct Find: ParsableCommand {
        @OptionGroup var options: CommandOptions
        @Option var session: String
        @Option var className: String
        mutating func run() throws {
            try options.perform(method: "views.find", parameters: ["sessionIdentifier": .string(session), "className": .string(className)])
        }
    }
}

struct AttributesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "attributes", subcommands: [Read.self])
    struct Read: ParsableCommand {
        @OptionGroup var options: CommandOptions
        @Option var session: String
        @Option var object: String
        mutating func run() throws {
            try options.perform(method: "attributes.read", parameters: ["sessionIdentifier": .string(session), "objectIdentifier": .string(object)])
        }
    }
}

struct ScreenshotCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "screenshot")
    @OptionGroup var options: CommandOptions
    @Option var session: String
    @Option var object: String?
    @Option var output: String
    @Flag var fresh = false
    mutating func run() throws {
        var parameters: [String: InspectionValue] = ["sessionIdentifier": .string(session), "fresh": .bool(fresh)]
        if let object {
            parameters["objectIdentifier"] = .string(object)
        }
        try options.perform(method: "screenshot.read", parameters: parameters, outputFile: output)
    }
}
