import Foundation
import LookinMCPCore
import LookinCore
import MCP

// MARK: - health_check

struct HealthCheckTool: LookinTool {
    let name = "health_check"
    let description = "Report whether a Debug build of a LookinServer-enabled app is reachable. Returns version, port info, and connected-app metadata when present."
    var inputSchema: Value { Schema.empty }

    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        struct Result: Codable { let ok: Bool; let version: String; let connectedApp: AppSummary?; let reason: String? }
        let probe = LiveLookinClient(connectTimeout: 0.8)
        let apps = probe.discover()
        if let first = apps.first {
            return try JSON.encode(Result(ok: true, version: LookinMCP.version, connectedApp: .from(first), reason: nil))
        }
        return try JSON.encode(Result(ok: false, version: LookinMCP.version, connectedApp: nil, reason: "no_target"))
    }
}

// MARK: - list_apps

struct ListAppsTool: LookinTool {
    let name = "list_apps"
    let description = "List every Debug app currently reachable on Peertalk ports — useful when multiple simulators or devices are running."
    var inputSchema: Value { Schema.empty }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        let client = LiveLookinClient(connectTimeout: 0.8)
        let apps = client.discover().map { AppSummary.from($0) }
        return try JSON.encode(["apps": apps])
    }
}

struct AppSummary: Codable {
    let name: String?
    let bundleIdentifier: String?
    let platform: String
    let port: Int
    let serverVersion: Int
    let device: String?
    let os: String?
    static func from(_ d: LiveLookinClient.DiscoveredApp) -> AppSummary {
        AppSummary(name: d.appInfo.appName, bundleIdentifier: d.appInfo.appBundleIdentifier,
                   platform: d.platform, port: d.port,
                   serverVersion: Int(d.appInfo.serverVersion),
                   device: d.appInfo.deviceDescription, os: d.appInfo.osDescription)
    }
}

// MARK: - current_screen

struct CurrentScreenTool: LookinTool {
    let name = "current_screen"
    let description = "One-shot summary of the active screen: key window class, top view controller, screenshot reference, and a shallow tree (depth 2)."
    var inputSchema: Value { Schema.empty }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        let provider = try (sharedProvider() ?? providerFactory())
        let info = try provider.hierarchy()
        let index = HierarchyIndex(info: info)
        let app = try? provider.appInfo()
        let keyWindow = (info.displayItems as? [LookinDisplayItem])?.first
        struct Summary: Codable {
            let app: String?
            let device: String?
            let keyWindow: JSONShape.Node?
            let hierarchyDepth: Int
        }
        let summary = Summary(
            app: app?.appName,
            device: app?.deviceDescription,
            keyWindow: keyWindow.map { JSONShape.node($0, index: index, maxDepth: 2, includeOffscreen: false) },
            hierarchyDepth: index.count
        )
        return try JSON.encode(summary)
    }
}

// MARK: - get_hierarchy

struct GetHierarchyTool: LookinTool {
    let name = "get_hierarchy"
    let description = "Return the view hierarchy of the key window as a tree of canonical nodes. Use maxDepth to cap traversal for large screens."
    var inputSchema: Value {
        Schema.obj([
            "maxDepth": Schema.prop(Schema.integer, description: "Cap traversal depth. -1 = unlimited. Default 8."),
            "includeOffscreen": Schema.prop(Schema.boolean, description: "Include views whose frame is fully outside their parent. Default false."),
        ])
    }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        let provider = try (sharedProvider() ?? providerFactory())
        let info = try provider.hierarchy()
        let index = HierarchyIndex(info: info)
        let depth = arguments["maxDepth"]?.asInt() ?? 8
        let includeOff = arguments["includeOffscreen"]?.asBool() ?? false
        let roots = (info.displayItems as? [LookinDisplayItem]) ?? []
        let nodes = roots.map { JSONShape.node($0, index: index, maxDepth: depth, includeOffscreen: includeOff) }
        return try JSON.encode(["windows": nodes])
    }
}

// MARK: - search_elements

struct SearchElementsTool: LookinTool {
    let name = "search_elements"
    let description = "Find UI elements matching text content, accessibility id, class name, role, and/or visibility. All filters AND together."
    var inputSchema: Value {
        Schema.obj([
            "text": Schema.prop(Schema.string, description: "Substring match against displayed text / title (case-insensitive)."),
            "accessibilityId": Schema.prop(Schema.string, description: "Exact match against accessibilityIdentifier."),
            "className": Schema.prop(Schema.string, description: "Substring match against the primary class name (e.g. \"Button\", \"UILabel\")."),
            "role": Schema.prop(Schema.string, description: "Semantic role (button|label|image|textInput|textArea|switch|slider|scroll|table|collection|stack|window)."),
            "visibleOnly": Schema.prop(Schema.boolean, description: "Restrict to visible elements (not hidden, alpha > 0, non-zero frame)."),
        ])
    }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        let provider = try (sharedProvider() ?? providerFactory())
        let info = try provider.hierarchy()
        let index = HierarchyIndex(info: info)
        let q = ElementQuery(
            text: arguments["text"]?.asString(),
            accessibilityIdentifier: arguments["accessibilityId"]?.asString(),
            className: arguments["className"]?.asString(),
            role: arguments["role"]?.asString(),
            visibleOnly: arguments["visibleOnly"]?.asBool() ?? false
        )
        return try JSON.encode(["matches": ElementSearch.run(q, in: index)])
    }
}

// MARK: - get_element

struct GetElementTool: LookinTool {
    let name = "get_element"
    let description = "Full attributes for a single element. Pass the oid returned by `search_elements` or any node in the hierarchy."
    var inputSchema: Value {
        Schema.obj(["oid": Schema.prop(Schema.integer, description: "Element oid (from get_hierarchy or search_elements).")],
                   required: ["oid"])
    }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        guard let oid = arguments["oid"]?.asUInt() else { throw HierarchyProviderError.unsupported("oid is required") }
        let provider = try (sharedProvider() ?? providerFactory())
        let info = try provider.hierarchy()
        let index = HierarchyIndex(info: info)
        guard let details = try provider.elementDetails(oid: oid),
              let item = index.find(oid: oid) else {
            return try JSON.encode(["error": "oid not found"])
        }
        struct ElementJSON: Codable {
            let node: JSONShape.Node
            let attributes: [AttributeJSON]
        }
        struct AttributeJSON: Codable {
            let group: String
            let identifier: String
            let title: String?
            let value: String?
        }
        let attrs: [AttributeJSON] = details.attributeGroups.flatMap { group -> [AttributeJSON] in
            let sections = (group.attrSections as? [LookinAttributesSection]) ?? []
            return sections.flatMap { section -> [AttributeJSON] in
                ((section.attributes as? [LookinAttribute]) ?? []).map { attr in
                    AttributeJSON(group: group.identifier as String,
                                  identifier: attr.identifier as String,
                                  title: attr.displayTitle,
                                  value: String(describing: attr.value ?? "nil"))
                }
            }
        }
        return try JSON.encode(ElementJSON(
            node: JSONShape.node(item, index: index, maxDepth: 0, includeOffscreen: true),
            attributes: attrs))
    }
}

// MARK: - capture_screenshot

struct CaptureScreenshotTool: LookinTool {
    let name = "capture_screenshot"
    let description = "Capture the current key-window screenshot as a base64 PNG. Optionally overlay bounding boxes for one or more oids."
    var inputSchema: Value {
        Schema.obj([
            "highlightOids": .object(["type": .string("array"), "items": Schema.prop(Schema.integer)]),
            "drawBounds": Schema.prop(Schema.boolean, description: "Draw frame rectangles for the highlighted oids. Default true."),
        ])
    }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        let provider = try (sharedProvider() ?? providerFactory())
        guard let image = try provider.screenshot() else {
            return try JSON.encode(["error": "no screenshot available"])
        }
        let b64 = BugReportBuilder.pngBase64(image)
        return try JSON.encode(["mimeType": "image/png", "base64": b64])
    }
}

// MARK: - highlight_element

struct HighlightElementTool: LookinTool {
    let name = "highlight_element"
    let description = "Ask the running app to flash a highlight overlay around an element. Useful for visually confirming the AI agent picked the right view."
    var inputSchema: Value {
        Schema.obj([
            "oid": Schema.prop(Schema.integer, description: "Element oid."),
            "durationMs": Schema.prop(Schema.integer, description: "How long to keep the highlight visible. Default 1500."),
        ], required: ["oid"])
    }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        guard let oid = arguments["oid"]?.asUInt() else { throw HierarchyProviderError.unsupported("oid is required") }
        let duration = arguments["durationMs"]?.asInt() ?? 1500
        let provider = try (sharedProvider() ?? providerFactory())
        do {
            try provider.highlight(oid: oid, durationMs: duration)
            return try JSON.encode(["ok": true])
        } catch HierarchyProviderError.unsupported(let why) {
            struct OKResult: Codable { let ok: Bool; let reason: String }
            return try JSON.encode(OKResult(ok: false, reason: why))
        }
    }
}

// MARK: - diagnose_layout

struct DiagnoseLayoutTool: LookinTool {
    let name = "diagnose_layout"
    let description = "Run layout heuristics over the current screen (or a subtree): zero-size views, offscreen children, tiny tap targets, interactive overlaps, hidden-but-interactive."
    var inputSchema: Value {
        Schema.obj([
            "scope": Schema.prop(Schema.string, description: "\"screen\" (default) or \"oid\""),
            "oid": Schema.prop(Schema.integer, description: "Element oid when scope=\"oid\"."),
        ])
    }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        let provider = try (sharedProvider() ?? providerFactory())
        let info = try provider.hierarchy()
        let index = HierarchyIndex(info: info)
        let oid: UInt? = (arguments["scope"]?.asString() == "oid") ? arguments["oid"]?.asUInt() : nil
        return try JSON.encode(["findings": LayoutDiagnostics.run(on: index, scopeOid: oid)])
    }
}

// MARK: - diagnose_accessibility

struct DiagnoseAccessibilityTool: LookinTool {
    let name = "diagnose_accessibility"
    let description = "Run accessibility heuristics: missing labels on interactive elements, duplicate labels, undersized touch targets."
    var inputSchema: Value {
        Schema.obj([
            "scope": Schema.prop(Schema.string, description: "\"screen\" (default) or \"oid\""),
            "oid": Schema.prop(Schema.integer, description: "Element oid when scope=\"oid\"."),
        ])
    }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        let provider = try (sharedProvider() ?? providerFactory())
        let info = try provider.hierarchy()
        let index = HierarchyIndex(info: info)
        let oid: UInt? = (arguments["scope"]?.asString() == "oid") ? arguments["oid"]?.asUInt() : nil
        return try JSON.encode(["findings": AccessibilityDiagnostics.run(on: index, scopeOid: oid)])
    }
}

// MARK: - export_bug_report

struct ExportBugReportTool: LookinTool {
    let name = "export_bug_report"
    let description = "Bundle app+device metadata, hierarchy, screenshot, and all diagnostic findings into one JSON object suitable for pasting into an issue."
    var inputSchema: Value {
        Schema.obj([
            "includeScreenshot": Schema.prop(Schema.boolean, description: "Embed the base64 PNG screenshot. Default true."),
        ])
    }
    func invoke(arguments: [String: Value],
                providerFactory: @escaping () throws -> HierarchyProvider,
                sharedProvider: () throws -> HierarchyProvider?) throws -> String {
        let provider = try (sharedProvider() ?? providerFactory())
        let includeScreenshot = arguments["includeScreenshot"]?.asBool() ?? true
        let report = try BugReportBuilder.build(provider: provider, includeScreenshot: includeScreenshot)
        return try JSON.encode(report)
    }
}
