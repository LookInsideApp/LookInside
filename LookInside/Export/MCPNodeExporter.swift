//
//  MCPNodeExporter.swift
//  LookInside
//
//  从 ObjC 版 LKMCPNodeExporter 移植。把一个 DisplayItem（可选连同整棵子树）导出为
//  MCP 风格的 JSON（oid / className / role / frame / bounds / alpha / hidden / text /
//  accessibilityIdentifier / accessibilityLabel / path / children），并附带属性面板里
//  展示的完整 attributes 分组。字段名与之前酷狗版导出的格式保持一致。
//

import AppKit

enum MCPNodeExporter {
    /// 生成 item 的 MCP 格式字典。recursive 为 true 时 children 包含完整子树，否则为空数组。
    /// isMacTarget 描述被检查的 App（不是宿主），只影响部分属性分组的标题。
    static func mcpDictionary(for item: DisplayItem, recursive: Bool, isMacTarget: Bool) -> [String: Any] {
        nodeDictionary(for: item, recursive: recursive, isMacTarget: isMacTarget)
    }

    /// mcpDictionary(for:recursive:) 的格式化 UTF-8 JSON 数据。
    static func jsonData(for item: DisplayItem, recursive: Bool, isMacTarget: Bool) throws -> Data {
        let dictionary = mcpDictionary(for: item, recursive: recursive, isMacTarget: isMacTarget)
        guard JSONSerialization.isValidJSONObject(dictionary) else {
            throw NSError(domain: "MCPNodeExporter", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Generated object is not valid JSON.",
            ])
        }
        return try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
    }

    /// 导出文件的建议文件名（不含目录），例如 `UILabel_140234_analysis.json`、
    /// `UIView_140234_analysis_tree.json`。
    static func suggestedFileName(for item: DisplayItem, recursive: Bool) -> String {
        // 只保留文件名中合法的字符
        let illegalCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let className = (objectClassName(of: item) ?? "Node")
            .components(separatedBy: illegalCharacters)
            .joined(separator: "_")
        let oid = objectOID(of: item)
        let suffix = recursive ? "analysis_tree" : "analysis"
        if oid != 0 {
            return "\(className)_\(oid)_\(suffix).json"
        }
        return "\(className)_\(suffix).json"
    }

    /// 节点属性面板数据的可读文本（按分组，"标题: 值"），用于放到剪贴板，与 GUI 面板展示一致。
    static func readableAttributesText(for item: DisplayItem, isMacTarget: Bool) -> String {
        var text = ""

        let className = objectClassName(of: item) ?? ""
        let oid = objectOID(of: item)
        if oid != 0 {
            text += "\(className)  (oid: \(oid))\n"
        } else {
            text += "\(className)\n"
        }
        let path = breadcrumbPath(of: item)
        if !path.isEmpty {
            text += "path: \(path)\n"
        }

        for group in item.queryAllAttrGroupList() {
            let groupTitle = group.queryDisplayTitle(forMacTarget: isMacTarget)
            text += "\n[\(groupTitle.isEmpty ? "-" : groupTitle)]\n"

            for section in group.attrSections ?? [] {
                let sectionTitle = displayTitle(of: section) ?? ""
                if !sectionTitle.isEmpty {
                    text += "  \(sectionTitle)\n"
                }
                let indent = sectionTitle.isEmpty ? "  " : "    "
                for attribute in section.attributes ?? [] {
                    let attributeTitle = displayTitle(of: attribute) ?? ""
                    let valueString = readableString(fromJSONValue: jsonValue(of: attribute))
                    if attributeTitle.isEmpty {
                        text += "\(indent)\(valueString)\n"
                    } else {
                        text += "\(indent)\(attributeTitle): \(valueString)\n"
                    }
                }
            }
        }
        return text
    }

    // MARK: - 节点组装

    private static func nodeDictionary(for item: DisplayItem, recursive: Bool, isMacTarget: Bool) -> [String: Any] {
        var node: [String: Any] = [:]

        node["oid"] = objectOID(of: item)
        let className = objectClassName(of: item) ?? "UnknownView"
        node["className"] = className
        node["role"] = role(forClassName: className) ?? NSNull()
        node["frame"] = rectDictionary(item.frame)
        node["bounds"] = rectDictionary(item.bounds)
        node["alpha"] = number(Double(item.alpha))
        node["hidden"] = item.isHidden

        let text = stringAttribute(of: item, identifiers: ["text", "title", "stringValue", "attributedText"])
        node["text"] = text ?? NSNull()
        node["accessibilityIdentifier"] = stringAttribute(of: item, identifiers: ["accessibilityIdentifier"]) ?? NSNull()
        node["accessibilityLabel"] = stringAttribute(of: item, identifiers: ["accessibilityLabel"]) ?? NSNull()

        let path = breadcrumbPath(of: item)
        node["path"] = path.isEmpty ? NSNull() : path

        // 与属性面板展示一致的完整属性分组
        node["attributes"] = attributeGroupsArray(of: item, isMacTarget: isMacTarget)

        var children: [[String: Any]] = []
        if recursive {
            for subitem in item.subitems ?? [] {
                children.append(nodeDictionary(for: subitem, recursive: true, isMacTarget: isMacTarget))
            }
        }
        node["children"] = children
        return node
    }

    /// JSON 安全的数字：非有限值（NaN / ±Inf）转成 NSNull，避免序列化失败。
    private static func number(_ value: Double) -> Any {
        value.isFinite ? value : NSNull()
    }

    private static func rectDictionary(_ rect: CGRect) -> [String: Any] {
        [
            "x": number(Double(rect.origin.x)),
            "y": number(Double(rect.origin.y)),
            "width": number(Double(rect.size.width)),
            "height": number(Double(rect.size.height)),
        ]
    }

    /// 优先取 view，其次 layer，再次 window 的 oid。
    private static func objectOID(of item: DisplayItem) -> UInt {
        for object in [item.viewObject, item.layerObject, item.windowObject] {
            if let oid = object?.oid, oid != 0 {
                return oid
            }
        }
        return 0
    }

    private static func objectClassName(of item: DisplayItem) -> String? {
        for object in [item.viewObject, item.layerObject, item.windowObject] {
            if let name = object?.classChainList?.first {
                return name
            }
        }
        return nil
    }

    private static let roleMap: [String: String] = [
        "UIButton": "button", "NSButton": "button",
        "UILabel": "label", "NSTextField": "label",
        "UIImageView": "image", "NSImageView": "image",
        "UITextField": "textInput",
        "UITextView": "textArea", "NSTextView": "textArea",
        "UISwitch": "switch",
        "UISlider": "slider",
        "UIScrollView": "scroll", "NSScrollView": "scroll",
        "UITableView": "table", "NSTableView": "table",
        "UICollectionView": "collection", "NSCollectionView": "collection",
        "UIStackView": "stack", "NSStackView": "stack",
        "UIWindow": "window", "NSWindow": "window",
    ]

    private static func role(forClassName className: String) -> String? {
        if let role = roleMap[className] {
            return role
        }
        if className.contains("Button") {
            return "button"
        }
        if className.contains("Label") {
            return "label"
        }
        return nil
    }

    /// 根节点到当前节点的类名链，用 " ▸ " 连接。
    private static func breadcrumbPath(of item: DisplayItem) -> String {
        var chain: [String] = []
        var current: DisplayItem? = item
        while let node = current {
            chain.insert(objectClassName(of: node) ?? "UnknownView", at: 0)
            current = node.super
        }
        return chain.joined(separator: " ▸ ")
    }

    // MARK: - 属性提取

    /// 在 attributesGroupList 里按 identifier 子串匹配，取第一个非空字符串值。
    private static func stringAttribute(of item: DisplayItem, identifiers: [String]) -> String? {
        for wanted in identifiers {
            for group in item.attributesGroupList ?? [] {
                for section in group.attrSections ?? [] {
                    for attribute in section.attributes ?? [] {
                        guard let identifier = attribute.identifier, identifier.contains(wanted) else {
                            continue
                        }
                        if let value = attribute.value as? String, !value.isEmpty {
                            return value
                        }
                    }
                }
            }
        }
        return nil
    }

    private static func attributeGroupsArray(of item: DisplayItem, isMacTarget: Bool) -> [[String: Any]] {
        var groupsArray: [[String: Any]] = []
        for group in item.queryAllAttrGroupList() {
            var sectionsArray: [[String: Any]] = []
            for section in group.attrSections ?? [] {
                var attributesArray: [[String: Any]] = []
                for attribute in section.attributes ?? [] {
                    var attributeDictionary: [String: Any] = [:]
                    if let identifier = attribute.identifier, !identifier.isEmpty {
                        attributeDictionary["id"] = identifier
                    }
                    if let title = displayTitle(of: attribute), !title.isEmpty {
                        attributeDictionary["title"] = title
                    }
                    attributeDictionary["value"] = jsonValue(of: attribute)
                    attributesArray.append(attributeDictionary)
                }
                if attributesArray.isEmpty {
                    continue
                }
                var sectionDictionary: [String: Any] = ["attributes": attributesArray]
                if let title = displayTitle(of: section), !title.isEmpty {
                    sectionDictionary["title"] = title
                }
                sectionsArray.append(sectionDictionary)
            }
            if sectionsArray.isEmpty {
                continue
            }
            var groupDictionary: [String: Any] = ["sections": sectionsArray]
            let groupTitle = group.queryDisplayTitle(forMacTarget: isMacTarget)
            if !groupTitle.isEmpty {
                groupDictionary["title"] = groupTitle
            }
            groupsArray.append(groupDictionary)
        }
        return groupsArray
    }

    // MARK: - 标题

    private static func displayTitle(of section: AttributesSection) -> String? {
        if section.isUserCustom() {
            return section.attributes?.first?.displayTitle
        }
        return DashboardBlueprint.sectionTitle(withSectionID: section.identifier)
    }

    private static func displayTitle(of attribute: InspectedAttribute) -> String? {
        if attribute.isUserCustom() {
            return attribute.displayTitle
        }
        if let title = DashboardBlueprint.briefTitle(withAttrID: attribute.identifier), !title.isEmpty {
            return title
        }
        return DashboardBlueprint.fullTitle(withAttrID: attribute.identifier)
    }

    // MARK: - 值格式化

    private static func jsonValue(of attribute: InspectedAttribute) -> Any {
        guard let value = attribute.value else {
            return NSNull()
        }

        switch attribute.attrType {
        case .BOOL:
            if let number = value as? NSNumber {
                return number.boolValue
            }
        case .cgRect:
            if let nsValue = value as? NSValue {
                var rect = CGRect.zero
                nsValue.getValue(&rect, size: MemoryLayout<CGRect>.size)
                return rectDictionary(rect)
            }
        case .cgPoint:
            if let nsValue = value as? NSValue {
                var point = CGPoint.zero
                nsValue.getValue(&point, size: MemoryLayout<CGPoint>.size)
                return ["x": number(Double(point.x)), "y": number(Double(point.y))]
            }
        case .cgSize:
            if let nsValue = value as? NSValue {
                var size = CGSize.zero
                nsValue.getValue(&size, size: MemoryLayout<CGSize>.size)
                return ["width": number(Double(size.width)), "height": number(Double(size.height))]
            }
        case .cgVector:
            if let nsValue = value as? NSValue {
                var vector = CGVector.zero
                nsValue.getValue(&vector, size: MemoryLayout<CGVector>.size)
                return ["dx": number(Double(vector.dx)), "dy": number(Double(vector.dy))]
            }
        case .uiEdgeInsets:
            if let nsValue = value as? NSValue {
                // UIEdgeInsets 与 NSEdgeInsets 内存布局一致：top / left / bottom / right
                var insets: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
                nsValue.getValue(&insets, size: MemoryLayout.size(ofValue: insets))
                return [
                    "top": number(Double(insets.0)),
                    "left": number(Double(insets.1)),
                    "bottom": number(Double(insets.2)),
                    "right": number(Double(insets.3)),
                ]
            }
        case .uiOffset:
            if let nsValue = value as? NSValue {
                var offset: (CGFloat, CGFloat) = (0, 0)
                nsValue.getValue(&offset, size: MemoryLayout.size(ofValue: offset))
                return ["horizontal": number(Double(offset.0)), "vertical": number(Double(offset.1))]
            }
        case .uiColor:
            // LookinServer 把颜色编码为 RGBA 四个 NSNumber
            if let components = value as? [Any] {
                if components.count == 4 {
                    return ["r": components[0], "g": components[1], "b": components[2], "a": components[3]]
                }
                return sanitizedJSONValue(components)
            }
        case .json:
            if let string = value as? String {
                if let data = string.data(using: .utf8),
                   let parsed = try? JSONSerialization.jsonObject(with: data) {
                    return parsed
                }
                return string
            }
            return sanitizedJSONValue(value)
        default:
            break
        }
        return sanitizedJSONValue(value)
    }

    /// 把任意对象转换为可 JSON 序列化的表示。
    private static func sanitizedJSONValue(_ value: Any?) -> Any {
        guard let value, !(value is NSNull) else {
            return NSNull()
        }
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.doubleValue.isFinite ? number : NSNull()
        case let array as [Any]:
            return array.map { sanitizedJSONValue($0) }
        case let dictionary as [AnyHashable: Any]:
            var result: [String: Any] = [:]
            for (key, element) in dictionary {
                result[String(describing: key)] = sanitizedJSONValue(element)
            }
            return result
        case let nsValue as NSValue:
            // 按编码类型尽量解出常见的几何结构体
            let type = String(cString: nsValue.objCType)
            if type == String(cString: NSValue(rect: .zero).objCType) {
                return rectDictionary(nsValue.rectValue)
            }
            if type == String(cString: NSValue(point: .zero).objCType) {
                let point = nsValue.pointValue
                return ["x": Double(point.x), "y": Double(point.y)]
            }
            if type == String(cString: NSValue(size: .zero).objCType) {
                let size = nsValue.sizeValue
                return ["width": Double(size.width), "height": Double(size.height)]
            }
            return nsValue.description
        default:
            return String(describing: value)
        }
    }

    private static func readableString(fromJSONValue value: Any) -> String {
        switch value {
        case is NSNull:
            return "nil"
        case let string as String:
            return string
        case let number as NSNumber:
            if isBoolNumber(number) {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        case let array as [Any]:
            return "[" + array.map { readableString(fromJSONValue: $0) }.joined(separator: ", ") + "]"
        case let dictionary as [String: Any]:
            let parts = dictionary.map { "\($0.key): \(readableString(fromJSONValue: $0.value))" }
            return "{" + parts.joined(separator: ", ") + "}"
        default:
            return String(describing: value)
        }
    }

    /// NSNumber 是否由 Bool 装箱而来。
    private static func isBoolNumber(_ number: NSNumber) -> Bool {
        CFGetTypeID(number) == CFBooleanGetTypeID()
    }
}
