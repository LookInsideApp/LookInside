import Foundation
import LookinMCPCore

/// Emits a JSON snippet ready to paste into one of the common MCP-aware clients.
/// We resolve the absolute path of the running binary so users don't have to think
/// about $PATH; the snippet works copy-paste from any directory.
enum PrintConfigCommand {
    static func run(client: String) -> Int32 {
        let binary = currentExecutablePath()
        let snippet: String
        switch client {
        case "claude-desktop":
            snippet = """
            // Add into ~/Library/Application Support/Claude/claude_desktop_config.json
            {
              "mcpServers": {
                "lookinside": {
                  "command": "\(binary)",
                  "args": ["serve"]
                }
              }
            }
            """
        case "claude-code":
            snippet = """
            # Run once:
            claude mcp add lookinside \(binary) serve
            """
        case "cursor":
            snippet = """
            // ~/.cursor/mcp.json
            {
              "mcpServers": {
                "lookinside": { "command": "\(binary)", "args": ["serve"] }
              }
            }
            """
        case "windsurf":
            snippet = """
            // ~/.codeium/windsurf/mcp_config.json
            {
              "mcpServers": {
                "lookinside": { "command": "\(binary)", "args": ["serve"] }
              }
            }
            """
        case "vscode":
            snippet = """
            // VS Code settings.json under "mcp.servers" (Copilot Chat / Claude / continue.dev syntax)
            "lookinside": {
              "command": "\(binary)",
              "args": ["serve"]
            }
            """
        default:
            FileHandle.standardError.write(Data("Unknown client: \(client). Try one of: claude-desktop, claude-code, cursor, windsurf, vscode.\n".utf8))
            return 2
        }
        print(snippet)
        return 0
    }

    private static func currentExecutablePath() -> String {
        var buf = [CChar](repeating: 0, count: 1024)
        var size = UInt32(buf.count)
        if _NSGetExecutablePath(&buf, &size) == 0 {
            let resolved = URL(fileURLWithPath: String(cString: buf)).standardizedFileURL.path
            return resolved
        }
        return CommandLine.arguments[0]
    }
}

@_silgen_name("_NSGetExecutablePath")
private func _NSGetExecutablePath(_ buf: UnsafeMutablePointer<CChar>, _ bufsize: UnsafeMutablePointer<UInt32>) -> Int32
