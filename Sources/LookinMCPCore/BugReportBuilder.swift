import Foundation
import LookinCore
#if canImport(AppKit)
import AppKit
#endif

/// Bundles everything an agent or developer needs to reproduce a UI bug into one
/// JSON payload. Tools producing different views of the same data (hierarchy,
/// diagnostics, screenshot) all flow through this one builder so the format stays
/// consistent — bug reports across teams should look identical.
public enum BugReportBuilder {
    public struct Report: Codable {
        public let generatedAt: String
        public let mcpVersion: String
        public let app: AppMeta
        public let device: DeviceMeta
        public let hierarchy: JSONShape.Node?
        public let screenshotBase64PNG: String?
        public let layoutFindings: [Finding]
        public let accessibilityFindings: [Finding]
    }

    public struct AppMeta: Codable {
        public let name: String?
        public let bundleIdentifier: String?
        public let serverVersion: Int
    }

    public struct DeviceMeta: Codable {
        public let description: String?
        public let os: String?
        public let screenWidth: Double
        public let screenHeight: Double
        public let screenScale: Double
    }

    public static func build(provider: HierarchyProvider,
                             includeScreenshot: Bool) throws -> Report {
        let info = try provider.hierarchy()
        let index = HierarchyIndex(info: info)
        let app = try provider.appInfo()
        let root = (info.displayItems as? [LookinDisplayItem])?.first
        let rootNode = root.map { JSONShape.node($0, index: index, maxDepth: -1, includeOffscreen: false) }
        return Report(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            mcpVersion: LookinMCP.version,
            app: AppMeta(name: app.appName, bundleIdentifier: app.appBundleIdentifier, serverVersion: Int(app.serverVersion)),
            device: DeviceMeta(description: app.deviceDescription, os: app.osDescription,
                               screenWidth: app.screenWidth, screenHeight: app.screenHeight, screenScale: app.screenScale),
            hierarchy: rootNode,
            screenshotBase64PNG: includeScreenshot ? Self.pngBase64(try provider.screenshot()) : nil,
            layoutFindings: LayoutDiagnostics.run(on: index),
            accessibilityFindings: AccessibilityDiagnostics.run(on: index)
        )
    }

    public static func pngBase64(_ image: PlatformImage?) -> String? {
        guard let image else { return nil }
        #if canImport(AppKit)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else { return nil }
        return png.base64EncodedString()
        #else
        return nil
        #endif
    }
}
