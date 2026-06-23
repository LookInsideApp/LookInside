import Foundation
import LookinCore

/// Reads a `.lookin` snapshot file (the same format the macOS LookInside.app exports
/// from File ▸ Save). Useful when:
///   1. A developer captures a problem state once and wants to iterate with the AI agent.
///   2. CI wants to attach a hierarchy artifact to a failed UI test.
///   3. Tests want a deterministic provider with no networking.
public final class FileHierarchyProvider: HierarchyProvider {
    private let info: LookinHierarchyInfo
    private let index: HierarchyIndex

    public var isLive: Bool { false }

    public init(fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        guard let info = try Self.decode(data: data) else {
            throw HierarchyProviderError.decodeFailure(reason: "no LookinHierarchyInfo root in \(fileURL.lastPathComponent)")
        }
        Self.applyKuGouCollapse(to: info)
        self.info = info
        self.index = HierarchyIndex(info: info)
    }

    public init(info: LookinHierarchyInfo) {
        Self.applyKuGouCollapse(to: info)
        self.info = info
        self.index = HierarchyIndex(info: info)
    }

    /// 酷狗（KuGou）：折叠 KGMainViewController 子树，使快照文件的层级输出与 macOS 客户端一致。
    /// 默认折叠、隐藏抽屉，可用环境变量 LOOKIN_MCP_SHOW_ALL_PAGES / LOOKIN_MCP_SHOW_DRAWER 控制。
    private static func applyKuGouCollapse(to info: LookinHierarchyInfo) {
        if let roots = info.displayItems as? [LookinDisplayItem] {
            LookinDisplayItem.lk_kg_applyKuGouCollapse(to: roots)
        }
    }

    public func appInfo() throws -> LookinAppInfo {
        guard let app = info.appInfo else {
            throw HierarchyProviderError.decodeFailure(reason: "snapshot has no appInfo")
        }
        return app
    }

    public func hierarchy() throws -> LookinHierarchyInfo { info }

    public func elementDetails(oid: UInt) throws -> ElementDetails? {
        guard let item = index.find(oid: oid) else { return nil }
        return ElementDetails(item: item,
                              attributeGroups: (item.attributesGroupList as? [LookinAttributesGroup]) ?? [],
                              soloScreenshot: item.soloScreenshot)
    }

    public func highlight(oid: UInt, durationMs: Int) throws {
        throw HierarchyProviderError.unsupported("highlight requires a live connection — snapshot files cannot drive in-app overlays.")
    }

    public func screenshot() throws -> PlatformImage? {
        info.appInfo?.screenshot
    }

    private static func decode(data: Data) throws -> LookinHierarchyInfo? {
        let allowed: [AnyClass] = [
            LookinHierarchyInfo.self,
            LookinDisplayItem.self,
            LookinAppInfo.self,
            LookinAttributesGroup.self,
            LookinAttribute.self,
            LookinObject.self,
            NSArray.self, NSDictionary.self, NSString.self, NSNumber.self, NSData.self, NSValue.self,
            PlatformImage.self,
        ]
        let nsClasses = Set(allowed.map { ObjectIdentifier($0) })
        _ = nsClasses // silence unused — informational; we use the array directly below
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        defer { unarchiver.finishDecoding() }
        // Snapshot files in the wild use root keys that vary; try the standard ones in order.
        for key in [NSKeyedArchiveRootObjectKey, "info", "hierarchyInfo"] {
            if let info = unarchiver.decodeObject(of: allowed, forKey: key) as? LookinHierarchyInfo {
                return info
            }
        }
        return nil
    }
}
