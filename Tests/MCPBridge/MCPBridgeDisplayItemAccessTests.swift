import AppKit
import Foundation

@main
@MainActor
struct MCPBridgeDisplayItemAccessTests {
    static func main() {
        let root = DisplayItem()
        let native = InspectedObject()
        native.oid = 42
        root.viewObject = native
        precondition(MCPBridgeDisplayItemAccess.objectIdentifier(for: root) == "0x2a")

        let nodes = (0 ..< 105).map { index in
            let item = DisplayItem()
            let info = CustomDisplayItemInfo()
            info.isSwiftUI = true
            info.title = "Text"
            info.swiftUIDisplayItemID = "swiftui:host:\(index)"
            info.detailObjectOid = UInt(index + 1000)
            item.customInfo = info
            return item
        }
        root.subitems = nodes
        let identifiers = nodes.map(MCPBridgeDisplayItemAccess.objectIdentifier)
        precondition(Set(identifiers).count == nodes.count)
        precondition(!identifiers.contains("0x0"))
        for (item, identifier) in zip(nodes, identifiers) {
            precondition(MCPBridgeDisplayItemAccess.find(in: [root], identifier: identifier) === item)
            precondition(UInt(identifier.dropFirst(2), radix: 16) == item.customInfo?.detailObjectOid)
        }
        precondition(MCPBridgeDisplayItemAccess.find(in: [root], identifier: "0x0") == nil)

        // Old SDKs have no deferred source, but send attributes inline.
        for item in nodes {
            item.customInfo?.detailObjectOid = 0
        }
        let inlineIdentifiers = nodes.map(MCPBridgeDisplayItemAccess.objectIdentifier)
        precondition(Set(inlineIdentifiers).count == nodes.count)
        for (item, identifier) in zip(nodes, inlineIdentifiers) {
            precondition(MCPBridgeDisplayItemAccess.find(in: [root], identifier: identifier) === item)
        }

        // Generic custom nodes don't even carry a SwiftUI ID. Their local
        // handles must stay unique and cannot collide with native IDs.
        for item in nodes {
            item.customInfo?.swiftUIDisplayItemID = nil
        }
        let genericIdentifiers = nodes.map(MCPBridgeDisplayItemAccess.objectIdentifier)
        precondition(Set(genericIdentifiers).count == nodes.count)
        precondition(genericIdentifiers.allSatisfy { $0.hasPrefix("custom:") })
        precondition(MCPBridgeDisplayItemAccess.objectIdentifier(for: nodes[0]) == genericIdentifiers[0])

        let text = nodes[0]
        precondition(!MCPBridgeDisplayItemAccess.hasCachedDetails(text))
        text.customAttrGroupList = [AttributesGroup()]
        precondition(MCPBridgeDisplayItemAccess.hasCachedDetails(text))
        text.customAttrGroupList = []
        precondition(MCPBridgeDisplayItemAccess.hasCachedDetails(text))
        text.customAttrGroupList = nil
        text.attributesGroupList = [AttributesGroup()]
        precondition(MCPBridgeDisplayItemAccess.hasCachedDetails(text))
        print("MCP display item identity and cache tests passed (105 virtual nodes)")
    }
}
