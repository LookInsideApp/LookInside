import Foundation
import CoreGraphics
import LookinCore

/// Layout-shaped problems we can detect from a hierarchy snapshot alone — no need
/// to query intrinsic content size live. Heuristics intentionally err on the side
/// of false positives that a human can easily dismiss; missing real bugs is worse.
public enum LayoutDiagnostics {
    public static func run(on index: HierarchyIndex, scopeOid: UInt? = nil) -> [Finding] {
        var out: [Finding] = []
        let interactive = collectInteractive(index: index)

        index.walkAll { item in
            if let scope = scopeOid, HierarchyIndex.oid(of: item) != scope { return }
            check(item, index: index, into: &out)
        }
        out.append(contentsOf: overlapFindings(interactive, index: index))
        return out
    }

    private static func check(_ item: LookinDisplayItem, index: HierarchyIndex, into out: inout [Finding]) {
        guard let oid = HierarchyIndex.oid(of: item) else { return }
        let path = index.breadcrumb(of: oid)
        let className = JSONShape.primaryClassName(item)
        let frame = item.frame

        // Zero-size view that should have content
        if (frame.width <= 0 || frame.height <= 0), !item.isHidden, item.alpha > 0.01 {
            if className.hasSuffix("Label") || className.hasSuffix("Button") || className == "UIImageView" {
                out.append(Finding(oid: oid, severity: .warning, category: .layout,
                                   code: "layout.zero_size",
                                   message: "\(className) has zero-area frame \(frame).",
                                   suggestion: "Check constraints — the view may be missing width/height or have a content-hugging conflict.",
                                   path: path))
            }
        }

        // Offscreen relative to parent
        if let parentOid = index.ancestorOids(of: oid).first,
           let parent = index.find(oid: parentOid) {
            let pb = parent.bounds
            if !pb.isNull, !pb.isEmpty {
                let intersection = pb.intersection(frame)
                if intersection.isNull || intersection.isEmpty {
                    out.append(Finding(oid: oid, severity: .warning, category: .layout,
                                       code: "layout.offscreen_of_parent",
                                       message: "\(className) at \(frame) is fully outside its parent bounds \(pb).",
                                       suggestion: "If intentional, ensure parent has clipsToBounds=false; otherwise fix layout.",
                                       path: path))
                }
            }
        }

        // Tiny interactive target
        if ElementSearch.isVisible(item), isInteractive(item) {
            if frame.width < 44 || frame.height < 44 {
                out.append(Finding(oid: oid, severity: .warning, category: .layout,
                                   code: "layout.tap_target_small",
                                   message: "\(className) tap target is \(Int(frame.width))×\(Int(frame.height)) — Apple HIG recommends ≥ 44×44.",
                                   suggestion: "Expand the hit area or pad the view.",
                                   path: path))
            }
        }

        // Hidden but interactive
        if isInteractive(item), (item.isHidden || item.alpha < 0.01) {
            out.append(Finding(oid: oid, severity: .info, category: .layout,
                               code: "layout.interactive_but_invisible",
                               message: "\(className) is interactive but hidden=\(item.isHidden) alpha=\(item.alpha).",
                               suggestion: "Either disable user interaction or restore visibility — invisible interactive views confuse users and accessibility tools.",
                               path: path))
        }
    }

    private static func overlapFindings(_ interactive: [LookinDisplayItem],
                                        index: HierarchyIndex) -> [Finding] {
        var out: [Finding] = []
        // O(n²) but interactive set is small in practice; if it ever gets big, sweep on x.
        for i in 0..<interactive.count {
            for j in (i + 1)..<interactive.count {
                let a = interactive[i], b = interactive[j]
                guard ElementSearch.isVisible(a), ElementSearch.isVisible(b) else { continue }
                let inter = a.frame.intersection(b.frame)
                let minArea = min(a.frame.width * a.frame.height, b.frame.width * b.frame.height)
                if !inter.isNull, !inter.isEmpty, minArea > 0,
                   (inter.width * inter.height) / minArea > 0.5,
                   let oa = HierarchyIndex.oid(of: a), let ob = HierarchyIndex.oid(of: b) {
                    out.append(Finding(oid: oa, severity: .warning, category: .layout,
                                       code: "layout.interactive_overlap",
                                       message: "Interactive views overlap (oids \(oa), \(ob)).",
                                       suggestion: "One of them likely swallows taps. Inspect z-order and userInteractionEnabled.",
                                       path: index.breadcrumb(of: oa)))
                }
            }
        }
        return out
    }

    private static func collectInteractive(index: HierarchyIndex) -> [LookinDisplayItem] {
        var arr: [LookinDisplayItem] = []
        index.walkAll { item in
            if isInteractive(item) { arr.append(item) }
        }
        return arr
    }

    private static func isInteractive(_ item: LookinDisplayItem) -> Bool {
        let cn = JSONShape.primaryClassName(item)
        if cn.hasSuffix("Button") || cn == "UIControl" || cn == "NSControl" || cn == "UISwitch" || cn == "UISlider" {
            return true
        }
        if let chain = item.viewObject?.classChainList as? [String] {
            return chain.contains(where: { $0 == "UIControl" || $0 == "NSControl" || $0.hasSuffix("Button") })
        }
        return false
    }
}
