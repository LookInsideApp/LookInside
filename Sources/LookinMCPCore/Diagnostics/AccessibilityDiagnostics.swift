import Foundation
import LookinCore

/// Accessibility-shaped problems detectable from snapshot data. We don't try to
/// simulate VoiceOver — focus on findings every developer should address before
/// shipping (missing labels, undersized targets, duplicate labels).
public enum AccessibilityDiagnostics {
    public static func run(on index: HierarchyIndex, scopeOid: UInt? = nil) -> [Finding] {
        var out: [Finding] = []
        var seenLabels: [String: [(UInt, String)]] = [:]

        index.walkAll { item in
            if let scope = scopeOid, HierarchyIndex.oid(of: item) != scope { return }
            guard let oid = HierarchyIndex.oid(of: item), ElementSearch.isVisible(item) else { return }
            let className = JSONShape.primaryClassName(item)
            let role = JSONShape.inferRole(className: className)
            let path = index.breadcrumb(of: oid)

            // Missing label on interactive element.
            if role == "button" || role == "switch" || role == "slider" {
                let label = JSONShape.extractAttribute(item, identifier: "accessibilityLabel") as? String
                let text = JSONShape.extractText(item)
                if (label?.isEmpty ?? true), (text?.isEmpty ?? true) {
                    out.append(Finding(oid: oid, severity: .warning, category: .accessibility,
                                       code: "a11y.missing_label",
                                       message: "\(className) is interactive but has no accessibility label or visible text.",
                                       suggestion: "Set `accessibilityLabel` so VoiceOver users can identify the control.",
                                       path: path))
                }
            }

            // Tiny target, surface in accessibility too for severity-aware tooling.
            if (role == "button" || role == "switch") &&
                (item.frame.width < 44 || item.frame.height < 44) {
                out.append(Finding(oid: oid, severity: .info, category: .accessibility,
                                   code: "a11y.touch_target_small",
                                   message: "\(className) is \(Int(item.frame.width))×\(Int(item.frame.height)) — below the 44pt accessibility minimum.",
                                   suggestion: "Increase hit area.",
                                   path: path))
            }

            // Bucket labels to detect duplicates.
            if let label = JSONShape.extractAttribute(item, identifier: "accessibilityLabel") as? String, !label.isEmpty {
                seenLabels[label, default: []].append((oid, path))
            }
        }

        for (label, list) in seenLabels where list.count > 1 {
            for (oid, path) in list {
                out.append(Finding(oid: oid, severity: .info, category: .accessibility,
                                   code: "a11y.duplicate_label",
                                   message: "Multiple elements share the accessibility label \"\(label)\" (\(list.count) total).",
                                   suggestion: "Disambiguate with `accessibilityHint` or distinct labels — VoiceOver users can't tell them apart.",
                                   path: path))
            }
        }
        return out
    }
}
