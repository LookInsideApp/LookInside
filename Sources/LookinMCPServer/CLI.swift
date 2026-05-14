import Foundation
import LookinMCPCore

/// Tiny subcommand dispatcher. We deliberately avoid `swift-argument-parser` —
/// every dependency the executable carries pushes the cold-start cost an MCP
/// client pays on every prompt. Keep it lean.
enum CLI {
    static func dispatch(_ args: [String]) async -> Int32 {
        let cmd = args.first ?? "serve"
        switch cmd {
        case "--version", "-V":
            print("lookinside-mcp \(LookinMCP.version)")
            return 0
        case "--help", "-h", "help":
            printUsage()
            return 0
        case "serve":
            return await ServeCommand.run(snapshotPath: argValue(args, "--snapshot"))
        case "health":
            return HealthCommand.run()
        case "print-config":
            let client = args.dropFirst().first ?? ""
            return PrintConfigCommand.run(client: client)
        default:
            FileHandle.standardError.write(Data("Unknown command: \(cmd)\n".utf8))
            printUsage()
            return 2
        }
    }

    static func printUsage() {
        let usage = """
        lookinside-mcp \(LookinMCP.version)

        USAGE
          lookinside-mcp serve [--snapshot <path>]
              Run the MCP server over stdio. With --snapshot, serves from a `.lookin`
              file instead of probing for a live target app (great for offline analysis).
          lookinside-mcp health
              Print connection status and exit nonzero if no Debug build is reachable.
          lookinside-mcp print-config <client>
              Print a ready-to-paste config snippet for one of:
              claude-desktop | claude-code | cursor | windsurf | vscode

        FLAGS
          --version, -V        Print version and exit.
          --help, -h           Show this message.

        Logs are written to stderr to keep stdout reserved for the MCP transport.
        """
        print(usage)
    }

    private static func argValue(_ args: [String], _ flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}
