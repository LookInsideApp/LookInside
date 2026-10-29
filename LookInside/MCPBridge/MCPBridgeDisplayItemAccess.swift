import Foundation

/// Identifiers belong to a hierarchy snapshot. A virtual node is addressable
/// even when it has no UIView/CALayer and an older Server sent details inline.
@MainActor
enum MCPBridgeDisplayItemAccess {
    static func objectIdentifier(for item: DisplayItem) -> String {
        if let customInfo = item.customInfo {
            if customInfo.detailObjectOid != 0 {
                return "0x" + String(customInfo.detailObjectOid, radix: 16)
            }
            if let identifier = customInfo.swiftUIDisplayItemID, !identifier.isEmpty {
                return identifier
            }
        } else if let oid = item.displayingObject()?.oid, oid != 0 {
            return "0x" + String(oid, radix: 16)
        }
        // Generic custom nodes predate deferred detail IDs. Keep their
        // host-local identity in a namespace separate from target object IDs.
        let address = UInt(bitPattern: Unmanaged.passUnretained(item).toOpaque())
        return "custom:0x" + String(address, radix: 16)
    }

    static func find(in roots: [DisplayItem], identifier: String) -> DisplayItem? {
        var queue = roots
        var index = 0
        while index < queue.count {
            let item = queue[index]
            index += 1
            if objectIdentifier(for: item) == identifier {
                return item
            }
            queue.append(contentsOf: item.subitems ?? [])
        }
        return nil
    }

    static func hasCachedDetails(_ item: DisplayItem) -> Bool {
        item.attributesGroupList != nil || item.customAttrGroupList != nil
    }
}
