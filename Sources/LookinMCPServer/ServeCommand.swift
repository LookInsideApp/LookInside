import Foundation
import LookinMCPCore
import MCP

/// `serve` — boots the stdio MCP server. Tools are registered once via `ToolRegistry`;
/// adding a new tool means dropping a new conformance, not touching this file.
enum ServeCommand {
    static func run(snapshotPath: String?) async -> Int32 {
        let providerFactory: () throws -> HierarchyProvider = {
            if let path = snapshotPath {
                return try FileHierarchyProvider(fileURL: URL(fileURLWithPath: path))
            }
            let client = LiveLookinClient()
            _ = try client.connectToFirstAvailable()
            return client
        }
        let registry = ToolRegistry(providerFactory: providerFactory)

        let server = Server(
            name: "lookinside",
            version: LookinMCP.version,
            instructions: """
                LookInside's MCP integration. Use tools to inspect a running iOS or macOS app's
                UI hierarchy, capture screenshots, find elements, and diagnose layout or
                accessibility problems. The target app must be a Debug build with LookinServer
                embedded; `health_check` reports connection status. Tools never expose
                secure-text-field contents.
                """,
            capabilities: .init(tools: .init(listChanged: false))
        )

        await server.withMethodHandler(ListTools.self) { _ in
            return .init(tools: registry.allTools)
        }

        await server.withMethodHandler(CallTool.self) { params in
            do {
                let result = try await registry.call(name: params.name, arguments: params.arguments ?? [:])
                return .init(content: [.text(text: result, annotations: nil, _meta: nil)], isError: false)
            } catch {
                let payload = #"{"error":"\#(escape("\(error)"))"}"#
                return .init(content: [.text(text: payload, annotations: nil, _meta: nil)], isError: true)
            }
        }

        FileHandle.standardError.write(Data("lookinside-mcp \(LookinMCP.version) listening on stdio\n".utf8))
        do {
            try await server.start(transport: StdioTransport())
            await server.waitUntilCompleted()
            return 0
        } catch {
            FileHandle.standardError.write(Data("Fatal: \(error)\n".utf8))
            return 1
        }
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
