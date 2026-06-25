import Foundation
import CoreGraphics
import LookinCore

/// Canonical JSON shape every MCP tool returns. Keeping one shape — instead of one
/// per tool — means the agent learns the schema once, and downstream additions are
/// purely additive.
///
/// Secure-text redaction happens here, at the model boundary, so no tool can leak
/// secure-text-field contents even if a future tool reaches around the data layer.
public enum JSONShape {
    public static var redactor: SecureTextRedactor = SecureTextRedactor()

    public struct Node: Codable {
        public let oid: UInt
        public let className: String
        public let role: String?
        public let frame: Rect
        public let bounds: Rect
        public let alpha: Double
        public let hidden: Bool
        public let text: String?
        public let accessibilityIdentifier: String?
        public let accessibilityLabel: String?
        public let path: String?
        public var children: [Node]
    }

    public struct Rect: Codable {
        public let x: Double; public let y: Double
        public let width: Double; public let height: Double
        public init(_ r: CGRect) {
            self.x = Double(r.origin.x); self.y = Double(r.origin.y)
            self.width = Double(r.size.width); self.height = Double(r.size.height)
        }
    }

    /// Build a node, optionally walking children up to `maxDepth` levels deep
    /// (-1 = unlimited). `includeOffscreen` keeps nodes whose frame is fully
    /// outside their parent — useful when diagnosing layout escapes.
    public static func node(_ item: LookinDisplayItem,
                            index: HierarchyIndex,
                            maxDepth: Int,
                            includeOffscreen: Bool = true,
                            depth: Int = 0) -> Node {
        let oid = HierarchyIndex.oid(of: item) ?? 0
        let className = primaryClassName(item)
        let role = inferRole(className: className)
        let secure = redactor.isSecure(item: item)

        let kids: [Node]
        if maxDepth >= 0 && depth >= maxDepth {
            kids = []
        } else {
            kids = ((item.subitems as? [LookinDisplayItem]) ?? [])
                .filter { includeOffscreen || isOnscreen($0) }
                .map { node($0, index: index, maxDepth: maxDepth, includeOffscreen: includeOffscreen, depth: depth + 1) }
        }
        return Node(
            oid: oid,
            className: className,
            role: role,
            frame: Rect(item.frame),
            bounds: Rect(item.bounds),
            alpha: Double(item.alpha),
            hidden: item.isHidden,
            text: secure ? nil : extractText(item),
            accessibilityIdentifier: extractAttribute(item, identifier: "accessibilityIdentifier") as? String,
            accessibilityLabel: extractAttribute(item, identifier: "accessibilityLabel") as? String,
            path: index.breadcrumb(of: oid),
            children: kids
        )
    }

    public static func shortLabel(_ item: LookinDisplayItem) -> String {
        primaryClassName(item)
    }

    public static func primaryClassName(_ item: LookinDisplayItem) -> String {
        if let chain = item.viewObject?.classChainList as? [String], let head = chain.first { return head }
        if let chain = item.layerObject?.classChainList as? [String], let head = chain.first { return head }
        if let chain = item.windowObject?.classChainList as? [String], let head = chain.first { return head }
        return "UnknownView"
    }

    public static func inferRole(className: String) -> String? {
        switch className {
        case "UIButton", "NSButton": return "button"
        case "UILabel", "NSTextField": return "label"
        case "UIImageView", "NSImageView": return "image"
        case "UITextField": return "textInput"
        case "UITextView", "NSTextView": return "textArea"
        case "UISwitch": return "switch"
        case "UISlider": return "slider"
        case "UIScrollView", "NSScrollView": return "scroll"
        case "UITableView", "NSTableView": return "table"
        case "UICollectionView", "NSCollectionView": return "collection"
        case "UIStackView", "NSStackView": return "stack"
        case "UIWindow", "NSWindow": return "window"
        default:
            if className.contains("Button") { return "button" }
            if className.contains("Label") { return "label" }
            return nil
        }
    }

    public static func isOnscreen(_ item: LookinDisplayItem) -> Bool {
        let f = item.frame
        return f.size.width > 0 && f.size.height > 0
    }

    public static func extractText(_ item: LookinDisplayItem) -> String? {
        // Pull from common attribute identifiers across UILabel/UIButton/UITextField/NSTextField.
        for id in ["text", "title", "stringValue", "attributedText"] {
            if let s = extractAttribute(item, identifier: id) as? String, !s.isEmpty { return s }
        }
        return nil
    }

    public static func extractAttribute(_ item: LookinDisplayItem, identifier: String) -> Any? {
        guard let groups = item.attributesGroupList as? [LookinAttributesGroup] else { return nil }
        for group in groups {
            guard let sections = group.attrSections as? [LookinAttributesSection] else { continue }
            for section in sections {
                guard let attrs = section.attributes as? [LookinAttribute] else { continue }
                for a in attrs where (a.identifier as String).contains(identifier) {
                    return a.value
                }
            }
        }
        return nil
    }
}
