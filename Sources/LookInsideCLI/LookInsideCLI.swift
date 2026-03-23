import ArgumentParser
import Foundation
import LookinCoreClient

private let supportedProtocolVersion = 7

@main
struct LookInside: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lookinside",
        abstract: "Inspect debuggable iOS apps from the command line.",
        discussion: """
        LookInside discovers inspectable simulator and USB-connected device targets,
        prints target metadata, fetches live view hierarchies, and exports hierarchy
        archives for later analysis.
        """,
        subcommands: [
            List.self,
            Inspect.self,
            Hierarchy.self,
            Export.self,
        ],
        defaultSubcommand: List.self
    )
}

private struct SharedTargetOptions: ParsableArguments {
    @Option(help: "Target identifier from `lookinside list`.")
    var target: String
}

private enum OutputFormat: String, ExpressibleByArgument, Codable, CaseIterable {
    case text
    case json
}

private enum HierarchyFormat: String, ExpressibleByArgument, Codable, CaseIterable {
    case tree
    case json
}

private enum TransportFilter: String, ExpressibleByArgument, Codable, CaseIterable {
    case simulator
    case usb
}

private enum ExportFormat: String, ExpressibleByArgument, Codable, CaseIterable {
    case auto
    case json
    case archive
}

private struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List currently inspectable apps."
    )

    @Option(help: "Output format.")
    var format: OutputFormat = .text

    @Option(help: "Restrict results to one transport.")
    var transport: TransportFilter?

    @Option(name: .customLong("bundle-id"), help: "Only include targets with an exact bundle identifier match.")
    var bundleIdentifier: String?

    @Option(name: .customLong("name-contains"), help: "Only include targets whose app name contains this text.")
    var nameContains: String?

    @Flag(name: .customLong("ids-only"), help: "Print only target IDs in text mode.")
    var idsOnly = false

    mutating func run() throws {
        var targets = try CLIClient().listTargets()
        targets = targets.filtered(by: transport, bundleIdentifier: bundleIdentifier, nameContains: nameContains)

        switch format {
        case .json:
            try StandardPrinter.printJSON(targets.map(TargetRecord.init))
        case .text:
            if targets.isEmpty {
                StandardPrinter.printLine("No inspectable apps found.")
                return
            }
            for target in targets {
                if idsOnly {
                    StandardPrinter.printLine(target.targetID)
                    continue
                }
                StandardPrinter.printLine(target.targetID)
                StandardPrinter.printLine("  \(target.appName) (\(target.bundleIdentifier))")
                StandardPrinter.printLine("  \(target.transport) port \(target.port) | \(target.deviceDescription) | iOS \(target.osDescription) | server \(target.serverReadableVersion)")
            }
        }
    }
}

private struct Inspect: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Inspect one target and print its metadata."
    )

    @OptionGroup var options: SharedTargetOptions

    @Option(help: "Output format.")
    var format: OutputFormat = .text

    mutating func run() throws {
        let target = try CLIClient().inspectTarget(id: options.target)
        switch format {
        case .json:
            try StandardPrinter.printJSON(InspectRecord(target: target))
        case .text:
            StandardPrinter.printLine("id: \(target.targetID)")
            StandardPrinter.printLine("app: \(target.appName)")
            StandardPrinter.printLine("bundle: \(target.bundleIdentifier)")
            StandardPrinter.printLine("transport: \(target.transport)")
            StandardPrinter.printLine("port: \(target.port)")
            if let deviceID = target.deviceID, !deviceID.isEmpty {
                StandardPrinter.printLine("deviceID: \(deviceID)")
            }
            StandardPrinter.printLine("device: \(target.deviceDescription)")
            StandardPrinter.printLine("os: \(target.osDescription)")
            StandardPrinter.printLine("server: \(target.serverReadableVersion) (\(target.serverVersion))")
            StandardPrinter.printLine("protocolVersion: \(supportedProtocolVersion)")
            StandardPrinter.printLine("connectionState: connected")
        }
    }
}

private struct Hierarchy: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Fetch a live view hierarchy as text or JSON."
    )

    @OptionGroup var options: SharedTargetOptions

    @Option(help: "Hierarchy render format.")
    var format: HierarchyFormat = .tree

    @Option(help: "Write the hierarchy to a file instead of stdout.")
    var output: String?

    mutating func run() throws {
        let rendered = try CLIClient().hierarchy(target: options.target, format: format)
        if let output, !output.isEmpty {
            let destination = try FileDestination(path: output)
            try destination.write(rendered)
            StandardPrinter.printLine("Wrote \(format.rawValue) hierarchy to \(destination.url.path)")
            return
        }
        StandardPrinter.printLine(rendered)
    }
}

private struct Export: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Export a hierarchy archive or JSON payload to disk."
    )

    @OptionGroup var options: SharedTargetOptions

    @Option(help: "Destination path.")
    var output: String

    @Option(help: "Export format. `auto` infers from the output extension.")
    var format: ExportFormat = .auto

    mutating func validate() throws {
        _ = try ExportDestination(path: output, format: format)
    }

    mutating func run() throws {
        let destination = try ExportDestination(path: output, format: format)
        let writtenURL = try CLIClient().export(target: options.target, to: destination.path)
        StandardPrinter.printLine("Wrote hierarchy export to \(writtenURL.path)")
    }
}

private struct CLIClient {
    private let client = LICClient()

    func listTargets() throws -> [LICDiscoveredTarget] {
        var error: NSError?
        let targets = client.listTargets(&error)
        if let error {
            throw error
        }
        return targets
    }

    func inspectTarget(id: String) throws -> LICDiscoveredTarget {
        do {
            return try client.inspectTarget(withID: id)
        } catch {
            throw error
        }
    }

    func hierarchy(target: String, format: HierarchyFormat) throws -> String {
        do {
            return try client.hierarchy(forTargetID: target, format: format.rawValue)
        } catch {
            throw error
        }
    }

    func export(target: String, to outputPath: String) throws -> URL {
        do {
            return try client.exportTargetID(target, outputPath: outputPath)
        } catch {
            throw error
        }
    }
}

private struct FileDestination {
    let url: URL

    init(path: String) throws {
        let expandedPath = NSString(string: path).expandingTildeInPath
        guard !expandedPath.isEmpty else {
            throw CLIError("Output path cannot be empty.")
        }
        url = URL(fileURLWithPath: expandedPath)
    }

    func write(_ string: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try string.write(to: url, atomically: true, encoding: .utf8)
    }
}

private struct ExportDestination {
    let path: String

    init(path: String, format: ExportFormat) throws {
        let expandedPath = NSString(string: path).expandingTildeInPath
        guard !expandedPath.isEmpty else {
            throw CLIError("Output path cannot be empty.")
        }

        let url = URL(fileURLWithPath: expandedPath)
        let ext = url.pathExtension.lowercased()

        switch format {
        case .auto:
            if ext.isEmpty {
                throw CLIError("Export format could not be inferred from '\(expandedPath)'. Use --format json or --format archive, or provide an extension.")
            }
            self.path = expandedPath
        case .json:
            if ext.isEmpty || ext == "json" {
                self.path = ext == "json" ? expandedPath : url.appendingPathExtension("json").path
            } else {
                throw CLIError("JSON exports must use a .json extension.")
            }
        case .archive:
            let allowed = Set(["archive", "lookin", "lookinside"])
            if ext.isEmpty {
                self.path = url.appendingPathExtension("lookinside").path
            } else if allowed.contains(ext) {
                self.path = expandedPath
            } else {
                throw CLIError("Archive exports must use .archive, .lookin, or .lookinside.")
            }
        }
    }
}

private enum StandardPrinter {
    static func printLine(_ string: String) {
        Swift.print(string)
    }

    static func printJSON(_ value: some Encodable) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CLIError("Failed to encode UTF-8 output.")
        }
        printLine(string)
    }
}

private struct TargetRecord: Codable {
    let targetID: String
    let transport: String
    let port: Int
    let deviceID: String?
    let appName: String
    let bundleIdentifier: String
    let deviceDescription: String
    let osDescription: String
    let serverVersion: Int
    let serverReadableVersion: String
    let appInfoIdentifier: Int

    init(_ target: LICDiscoveredTarget) {
        targetID = target.targetID
        transport = target.transport
        port = target.port
        deviceID = target.deviceID
        appName = target.appName
        bundleIdentifier = target.bundleIdentifier
        deviceDescription = target.deviceDescription
        osDescription = target.osDescription
        serverVersion = target.serverVersion
        serverReadableVersion = target.serverReadableVersion
        appInfoIdentifier = target.appInfoIdentifier
    }
}

private struct InspectRecord: Codable {
    let target: TargetRecord
    let protocolVersion: Int
    let connectionState: String

    init(target: LICDiscoveredTarget) {
        self.target = TargetRecord(target)
        protocolVersion = supportedProtocolVersion
        connectionState = "connected"
    }
}

private struct CLIError: LocalizedError, CustomStringConvertible {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }

    var description: String {
        message
    }
}

private extension [LICDiscoveredTarget] {
    func filtered(
        by transport: TransportFilter?,
        bundleIdentifier: String?,
        nameContains: String?
    ) -> [LICDiscoveredTarget] {
        filter { target in
            if let transport, target.transport.caseInsensitiveCompare(transport.rawValue) != .orderedSame {
                return false
            }
            if let bundleIdentifier, target.bundleIdentifier != bundleIdentifier {
                return false
            }
            if let nameContains, !nameContains.isEmpty {
                return target.appName.range(of: nameContains, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
            return true
        }
    }
}
