import Foundation
import LookinCore

/// Predicates for `search_elements`. Each field is optional and ANDed; missing
/// fields are skipped. Mirrors the LookInside.app sidebar filter (class chain,
/// display text, visibility) but expressed declaratively so it's trivial to
/// add new fields later.
public struct ElementQuery {
    public var text: String?
    public var accessibilityIdentifier: String?
    public var className: String?
    public var role: String?
    public var visibleOnly: Bool

    public init(text: String? = nil,
                accessibilityIdentifier: String? = nil,
                className: String? = nil,
                role: String? = nil,
                visibleOnly: Bool = false) {
        self.text = text
        self.accessibilityIdentifier = accessibilityIdentifier
        self.className = className
        self.role = role
        self.visibleOnly = visibleOnly
    }
}

public enum ElementSearch {
    public struct Hit: Codable {
        public let oid: UInt
        public let className: String
        public let role: String?
        public let text: String?
        public let path: String?
    }

    public static func run(_ q: ElementQuery, in index: HierarchyIndex) -> [Hit] {
        var hits: [Hit] = []
        index.walkAll { item in
            if q.visibleOnly, !isVisible(item) { return }
            let className = JSONShape.primaryClassName(item)
            if let c = q.className, !className.localizedCaseInsensitiveContains(c) { return }
            if let r = q.role, JSONShape.inferRole(className: className) != r { return }
            let text = JSONShape.extractText(item)
            if let t = q.text {
                guard let text = text, text.localizedCaseInsensitiveContains(t) else { return }
            }
            if let id = q.accessibilityIdentifier {
                let aid = JSONShape.extractAttribute(item, identifier: "accessibilityIdentifier") as? String
                guard let aid = aid, aid == id else { return }
            }
            guard let oid = HierarchyIndex.oid(of: item) else { return }
            hits.append(Hit(oid: oid,
                            className: className,
                            role: JSONShape.inferRole(className: className),
                            text: text,
                            path: index.breadcrumb(of: oid)))
        }
        return hits
    }

    public static func isVisible(_ item: LookinDisplayItem) -> Bool {
        guard !item.isHidden, item.alpha > 0.01 else { return false }
        return item.frame.size.width > 0 && item.frame.size.height > 0
    }
}
