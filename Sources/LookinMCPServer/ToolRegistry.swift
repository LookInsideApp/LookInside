import Foundation
import LookinMCPCore
import MCP

/// Registry pattern so adding a new tool is one new file + one line in `tools` below.
/// The provider is created lazily on first call — discovery TCP probes are expensive
/// and we don't want to do them just to answer `tools/list`.
final class ToolRegistry {
    private let providerFactory: () throws -> HierarchyProvider
    private var provider: HierarchyProvider?
    private let lock = NSLock()
    let definitions: [LookinTool]

    init(providerFactory: @escaping () throws -> HierarchyProvider) {
        self.providerFactory = providerFactory
        self.definitions = [
            HealthCheckTool(), ListAppsTool(),
            CurrentScreenTool(), GetHierarchyTool(),
            SearchElementsTool(), GetElementTool(),
            CaptureScreenshotTool(), HighlightElementTool(),
            DiagnoseLayoutTool(), DiagnoseAccessibilityTool(),
            ExportBugReportTool(),
        ]
    }

    var allTools: [Tool] { definitions.map(\.asTool) }

    func call(name: String, arguments: [String: Value]) async throws -> String {
        guard let def = definitions.first(where: { $0.name == name }) else {
            throw RegistryError.unknown(name)
        }
        return try def.invoke(arguments: arguments, providerFactory: providerFactory) { [weak self] in
            try self?.sharedProvider()
        }
    }

    private func sharedProvider() throws -> HierarchyProvider {
        lock.lock(); defer { lock.unlock() }
        if let p = provider { return p }
        let p = try providerFactory()
        provider = p
        return p
    }

    enum RegistryError: Error, CustomStringConvertible {
        case unknown(String)
        var description: String {
            switch self { case .unknown(let n): return "Unknown tool: \(n)" }
        }
    }
}

/// One file per tool, but they all conform to this. Returning a `String` (raw JSON)
/// keeps the layer below this independent of the MCP SDK's `Value` so we can swap
/// SDK versions without rewriting tool bodies.
protocol LookinTool {
    var name: String { get }
    var description: String { get }
    var inputSchema: Value { get }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String
}

extension LookinTool {
    var asTool: Tool {
        Tool(name: name, description: description, inputSchema: inputSchema)
    }
}
