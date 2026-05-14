import Foundation
import LookinCore

/// Flat index over a `LookinHierarchyInfo` tree. Built once per hierarchy fetch;
/// every subsequent oid lookup is O(1). Indices also retain the path from each item
/// up to the root so tools can surface a stable, human-readable breadcrumb.
public final class HierarchyIndex {
    public let info: LookinHierarchyInfo
    private var byOid: [UInt: LookinDisplayItem] = [:]
    private var parents: [UInt: UInt] = [:]

    public init(info: LookinHierarchyInfo) {
        self.info = info
        for window in (info.displayItems as? [LookinDisplayItem]) ?? [] {
            walk(window, parentOid: nil)
        }
    }

    public func find(oid: UInt) -> LookinDisplayItem? { byOid[oid] }

    public func ancestorOids(of oid: UInt) -> [UInt] {
        var out: [UInt] = []
        var cur = parents[oid]
        while let next = cur {
            out.append(next)
            cur = parents[next]
        }
        return out
    }

    public func breadcrumb(of oid: UInt) -> String {
        let chain = ([oid] + ancestorOids(of: oid)).reversed()
        return chain.compactMap { byOid[$0].flatMap(JSONShape.shortLabel(_:)) }.joined(separator: " ▸ ")
    }

    /// In-order walk over every node, root-to-leaf. Provider-agnostic so diagnostics,
    /// search, and bug-report builders share one iteration shape.
    public func walkAll(_ body: (LookinDisplayItem) -> Void) {
        for window in (info.displayItems as? [LookinDisplayItem]) ?? [] {
            walkVisit(window, body)
        }
    }

    public var count: Int { byOid.count }

    private func walk(_ item: LookinDisplayItem, parentOid: UInt?) {
        if let oid = Self.oid(of: item) {
            byOid[oid] = item
            if let p = parentOid { parents[oid] = p }
        }
        for sub in (item.subitems as? [LookinDisplayItem]) ?? [] {
            walk(sub, parentOid: Self.oid(of: item))
        }
    }

    private func walkVisit(_ item: LookinDisplayItem, _ body: (LookinDisplayItem) -> Void) {
        body(item)
        for sub in (item.subitems as? [LookinDisplayItem]) ?? [] {
            walkVisit(sub, body)
        }
    }

    static func oid(of item: LookinDisplayItem) -> UInt? {
        // Prefer viewObject, fall back to layer/window. This matches the macOS app's
        // display logic where each row is keyed by the underlying view's oid.
        if let v = item.viewObject?.oid, v != 0 { return UInt(v) }
        if let l = item.layerObject?.oid, l != 0 { return UInt(l) }
        if let w = item.windowObject?.oid, w != 0 { return UInt(w) }
        return nil
    }
}
