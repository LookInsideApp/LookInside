// Shared by two regression tools so their outputs stay comparable:
//   - lookin-probe (Scripts/reborn-e2e/LookinProbe), which links this file
//     through a symlink and defines LOOKIN_PROBE;
//   - the Host's DEBUG end-to-end dump (DebugE2EDump.swift).
// It needs only Foundation, AppKit and the LookinCore model classes, which
// the probe imports as a module and the Host sees through its bridging
// header. Release Host builds compile it out.
#if DEBUG || LOOKIN_PROBE
    import AppKit
    import CryptoKit
    import Foundation
    #if canImport(LookinCore)
        import LookinCore
        import LookinCoreImpl
    #endif

    struct SnapshotError: Error, CustomStringConvertible {
        let description: String

        init(_ description: String) {
            self.description = description
        }
    }

    /// Normalization rules for inspection snapshots: stable node ids,
    /// volatile-value masking, ordering of hash-table arrays, and the
    /// one-line-per-node JSON layout.
    enum SnapshotNormalizer {
        // MARK: - Nodes

        struct Node {
            let id: String
            let parentID: String
            let depth: Int
            let item: DisplayItem
        }

        static func className(of item: DisplayItem) -> String {
            for object in [item.viewObject, item.layerObject, item.windowObject, item.kindObject, item.cellObject] {
                if let object, let name = object.rawClassName(), !name.isEmpty {
                    return name
                }
            }
            if let title = item.customInfo?.title, !title.isEmpty {
                return "custom:" + title
            }
            return "node"
        }

        /// Depth-first nodes with stable ids: the class path from the root,
        /// each step suffixed with its index among same-class siblings. The
        /// ids survive oid / address churn.
        static func collectNodes(roots: [DisplayItem]) -> [Node] {
            var nodes: [Node] = []
            for (index, root) in roots.enumerated() {
                collect(root, parentID: "", siblingIndex: index, siblings: roots, depth: 0, into: &nodes)
            }
            return nodes
        }

        private static func collect(
            _ item: DisplayItem,
            parentID: String,
            siblingIndex: Int,
            siblings: [DisplayItem],
            depth: Int,
            into nodes: inout [Node]
        ) {
            let name = className(of: item)
            let sameClassBefore = siblings.prefix(siblingIndex).filter { className(of: $0) == name }.count
            let id = parentID + "/" + name + "[\(sameClassBefore)]"
            nodes.append(Node(id: id, parentID: parentID, depth: depth, item: item))
            let children = canonicalSiblingOrder(item.subitems ?? [])
            for (index, child) in children.enumerated() {
                collect(child, parentID: id, siblingIndex: index, siblings: children, depth: depth + 1, into: &nodes)
            }
        }

        /// `items` with SwiftUI siblings of the same class ordered by their
        /// frame in the window (x, y, width, height; a wrapper without a
        /// frame uses its first descendant's), in the slots they held; every
        /// other sibling keeps its place. The Server does not keep the order
        /// of identical SwiftUI views stable from launch to launch (a
        /// ZStack's ForEach circles come back in either direction).
        static func canonicalSiblingOrder(_ items: [DisplayItem]) -> [DisplayItem] {
            func frameKey(_ item: DisplayItem) -> [Double] {
                if let rect = item.customInfo?.frameInWindow?.rectValue {
                    return [rect.origin.x, rect.origin.y, rect.size.width, rect.size.height].map(Double.init)
                }
                for child in item.subitems ?? [] {
                    let key = frameKey(child)
                    if !key.isEmpty {
                        return key
                    }
                }
                return []
            }
            var slotsByClass: [String: [Int]] = [:]
            for (index, item) in items.enumerated() where item.customInfo?.isSwiftUI == true {
                slotsByClass[className(of: item), default: []].append(index)
            }
            var result = items
            for slots in slotsByClass.values where slots.count > 1 {
                let ordered = slots.map { items[$0] }.sorted { frameKey($0).lexicographicallyPrecedes(frameKey($1)) }
                for (slot, item) in zip(slots, ordered) {
                    result[slot] = item
                }
            }
            return result
        }

        // MARK: - Session state

        /// The session state a snapshot was taken in, written into the
        /// snapshot header (`host.session` / `probe.session`) and next to it
        /// as `session-state.json`. AppKit renders differently with the screen
        /// locked (blank window-server captures, window captures at 0.9x,
        /// opaque scroll pockets, no key window), with the display asleep, in
        /// another appearance, or with the inspected window key, so a golden
        /// only compares with a run taken in the same state: `lookin-probe
        /// diff` reports SKIP when the candidate's state differs from the
        /// golden's `session-state.json` and never loosens the comparison
        /// instead (SnapshotSessionState in LookinProbe).
        ///
        /// - `screenLocked`, `onConsole`: CGSessionCopyCurrentDictionary.
        /// - `displayAwake`: the main display is not asleep.
        /// - `appearance`, `inspectedAppActive`, `inspectedWindowKey`: what
        ///   the inspected app reports about itself through the file named by
        ///   `LOOKIN_E2E_INSPECTED_STATE_FILE` (written by
        ///   LookinProbe/support/pin-launch-state.m in the macOS Example);
        ///   "unavailable" when the variable is set but the file cannot be
        ///   read. Absent on iOS, where nothing sets the variable.
        /// - `hostAppearance`: the Host's own effective appearance (Host dump
        ///   only).
        static func sessionStateJSON(hostAppearance: String? = nil) -> [String: Any] {
            var state = systemSessionStateJSON()
            if let path = ProcessInfo.processInfo.environment[inspectedStateFileVariable], !path.isEmpty {
                let inspected = (try? Data(contentsOf: URL(fileURLWithPath: path)))
                    .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                for key in ["appearance", "inspectedAppActive", "inspectedWindowKey"] {
                    switch inspected?[key] {
                    case let flag as NSNumber where CFGetTypeID(flag) == CFBooleanGetTypeID():
                        // A Swift Bool, so the header normalization keeps it a boolean.
                        state[key] = flag.boolValue
                    case let value?:
                        state[key] = value
                    case nil:
                        state[key] = "unavailable"
                    }
                }
            }
            if let hostAppearance {
                state["hostAppearance"] = hostAppearance
            }
            return state
        }

        /// The part of the session state that does not depend on the
        /// inspected app; known before anything is launched.
        static func systemSessionStateJSON() -> [String: Any] {
            let session = (CGSessionCopyCurrentDictionary() as? [String: Any]) ?? [:]
            func flag(_ key: String) -> Bool {
                (session[key] as? NSNumber)?.boolValue ?? false
            }
            return [
                "onConsole": flag(kCGSessionOnConsoleKey),
                // Present (and true) only while the screen is locked.
                "screenLocked": flag("CGSSessionScreenIsLocked"),
                "displayAwake": CGDisplayIsAsleep(CGMainDisplayID()) == 0,
            ]
        }

        static let inspectedStateFileVariable = "LOOKIN_E2E_INSPECTED_STATE_FILE"
        static let sessionStateFileName = "session-state.json"

        /// Writes `state` as `session-state.json` into `directory`.
        static func writeSessionState(_ state: [String: Any], to directory: URL) throws {
            let data = try JSONSerialization.data(withJSONObject: state, options: [.prettyPrinted, .sortedKeys])
            try (data + Data("\n".utf8)).write(to: directory.appendingPathComponent(sessionStateFileName), options: .atomic)
        }

        /// Child ids per parent id ("" holds the roots), in tree order.
        static func childrenByParent(_ nodes: [Node]) -> [String: [String]] {
            var childrenByParent: [String: [String]] = [:]
            for node in nodes {
                childrenByParent[node.parentID, default: []].append(node.id)
            }
            return childrenByParent
        }

        /// The oid the Host puts in the detail task for this node; mirrors
        /// -[LKStaticAsyncUpdateManager _taskFromDisplayItem:type:] with the
        /// backing-layer toggle off.
        static func taskOid(for item: DisplayItem, macTarget: Bool) -> UInt {
            switch item.resolvedNodeKind() {
            case .window, .windowScene:
                return item.windowObject?.oid ?? 0
            case .layoutGuide, .cell:
                return item.kindObject?.oid ?? 0
            case .custom:
                return 0
            default:
                let viewOid = item.viewObject?.oid ?? 0
                let layerOid = item.layerObject?.oid ?? 0
                if macTarget, viewOid != 0 {
                    return viewOid
                }
                if layerOid != 0 {
                    return layerOid
                }
                return viewOid
            }
        }

        /// Windows always get a group screenshot: that is the picture of the
        /// whole UI. iOS reports a UIWindow as a plain view node under its scene.
        static func isWindow(_ item: DisplayItem) -> Bool {
            if item.resolvedNodeKind() == .window {
                return true
            }
            let chain = item.viewObject?.classChainList ?? []
            return chain.contains("UIWindow") || chain.contains("NSWindow")
        }

        // MARK: - Records

        /// InspectedAppInfo encodes its images under the short keys "1" (icon)
        /// and "2" (screenshot).
        static let appImageNames = ["1": "appIcon", "2": "screenshot"]

        /// `appInfo` as JSON with the machine-identifying fields masked.
        static func appInfoJSON(_ appInfo: InspectedAppInfo, imageSink: @escaping SnapshotWireJSON.ImageSink) -> [String: Any] {
            var json = SnapshotWireJSON(imageSink: imageSink).record(appInfo, keyPath: [])
            // "3" = deviceDescription: on a Mac that is the computer name, and
            // the model identifier names the hardware. Neither belongs in a
            // checked-in fixture; keep only whether they were sent.
            for key in ["3", "deviceModelIdentifier"] where json[key] is String {
                json[key] = "<present>"
            }
            return json
        }

        /// `hierarchy` as JSON without its display items ("1") and app info
        /// ("2"), which are recorded separately (LookinHierarchyInfo.m).
        static func hierarchyJSON(_ hierarchy: HierarchyInfo) -> [String: Any] {
            SnapshotWireJSON(skippedKeys: ["LookinHierarchyInfo": ["1", "2"]]) { _, _ in
                ["$image": "<unexpected>"]
            }.record(hierarchy, keyPath: [])
        }

        /// A display item or detail as JSON without its `subitems`; the tree
        /// is recorded through the node ids instead.
        static func nodeObjectJSON(_ object: NSObject, imageSink: @escaping SnapshotWireJSON.ImageSink) -> [String: Any] {
            SnapshotWireJSON(
                skippedKeys: [
                    "LookinDisplayItem": ["subitems"],
                    "LookinDisplayItemDetail": ["subitems"],
                ],
                imageSink: imageSink
            ).record(object, keyPath: [])
        }

        static func imageBaseName(for nodeID: String) -> String {
            let digest = Insecure.SHA1.hash(data: Data(nodeID.utf8)).map { String(format: "%02x", $0) }.joined()
            let leaf = nodeID.split(separator: "/").last.map(String.init) ?? "node"
            let safeLeaf = leaf.replacingOccurrences(of: "[^A-Za-z0-9_]+", with: "_", options: .regularExpression)
            return String(safeLeaf.prefix(40)) + "-" + digest.prefix(10)
        }

        // MARK: - Normalization

        /// Keys whose values change from launch to launch and carry no meaning
        /// for a regression diff.
        static let volatileKeys: Set<String> = [
            "oid", "memoryAddress", "displayItemOid", "recognizerOid",
            "appInfoIdentifier", "cachedTimestamp", "shouldUseCache",
            "constraintOid",
        ]

        /// Dashboard attributes whose value is a per-launch counter.
        static let volatileAttributeIdentifiers: Set<String> = [
            "NSWindow_Info_WindowNumber",
        ]

        /// AppKit caches that may or may not point at an object depending on
        /// when the last layer-geometry update ran; an ivar trace through them
        /// is timing, not structure.
        static let volatileIvarNames: Set<String> = [
            "_ancestorWithLayerForLastLayerGeometryUpdate",
        ]

        /// Arrays stored under these keys are read from unordered tables on the
        /// Server (a UIControl's target-action set), so they are sorted.
        static let unorderedArrayKeys: Set<String> = [
            "targetActions",
        ]

        /// Arrays of these classes come out in enumeration order of a hash
        /// table on the Server (constraints, ivar references), so their order is
        /// not semantic: they are sorted after normalization.
        static let unorderedElementClasses: Set<String> = [
            "LookinAutoLayoutConstraint", "LookinIvarTrace",
        ]

        private static let addressPattern = try! NSRegularExpression(pattern: "0x[0-9a-fA-F]{5,16}")

        /// SwiftUI node ids are `swiftui:<hosting view hash>:<index>`
        /// (LKS_SwiftUIDisplayItemsMaker). The hash is per launch, and the
        /// index follows the Server's creation order, which is not stable for
        /// identical views (see `canonicalSiblingOrder`).
        private static let swiftUIDisplayItemIDPattern = try! NSRegularExpression(pattern: "^swiftui:-?[0-9]+:[0-9]+$")

        /// Drops volatile keys, rounds doubles, and masks heap addresses inside
        /// strings (descriptions like `<UIView: 0x1234…>`).
        static func normalize(_ value: Any) -> Any {
            switch value {
            case let dictionary as [String: Any]:
                var out: [String: Any] = [:]
                for (key, element) in dictionary where !volatileKeys.contains(key) {
                    var normalized = normalize(element)
                    if key == "swiftUIDisplayItemID", let id = normalized as? String {
                        let range = NSRange(id.startIndex..., in: id)
                        normalized = swiftUIDisplayItemIDPattern.stringByReplacingMatches(
                            in: id, range: range, withTemplate: "swiftui:<host>:<index>"
                        )
                    }
                    if unorderedArrayKeys.contains(key), let array = normalized as? [Any] {
                        out[key] = array.sorted { SnapshotWireJSON.sortKey($0) < SnapshotWireJSON.sortKey($1) }
                    } else {
                        out[key] = normalized
                    }
                }
                // NSStackView keeps redundant edge / alignment
                // constraints and AppKit picks which ones are active per launch,
                // so `effective` on them is not reproducible.
                if dictionary["$class"] as? String == "LookinAutoLayoutConstraint",
                   (dictionary["identifier"] as? String)?.hasPrefix("NSStackView.") == true,
                   out["effective"] != nil
                {
                    out["effective"] = "<volatile>"
                }
                if dictionary["$class"] as? String == "LookinAttribute",
                   let identifier = dictionary["identifier"] as? String,
                   volatileAttributeIdentifiers.contains(identifier)
                {
                    out["value"] = "<volatile>"
                }
                return out
            case let array as [Any]:
                let normalized = array.filter { element in
                    guard let trace = element as? [String: Any], trace["$class"] as? String == "LookinIvarTrace",
                          let name = trace["ivarName"] as? String else { return true }
                    return !volatileIvarNames.contains(name)
                }.map(normalize)
                let classes = Set(normalized.compactMap { ($0 as? [String: Any])?["$class"] as? String })
                if classes.count == 1, normalized.count > 1, unorderedElementClasses.isSuperset(of: classes),
                   normalized.allSatisfy({ $0 is [String: Any] })
                {
                    return normalized.sorted { SnapshotWireJSON.sortKey($0) < SnapshotWireJSON.sortKey($1) }
                }
                return normalized
            case let double as Double:
                guard double.isFinite else { return "\(double)" }
                // Near CGFLOAT_MAX (unbounded SwiftUI sizes) the scaling
                // overflows to infinity, which JSON cannot hold.
                guard abs(double) < 1e300 else { return double }
                let rounded = (double * 10000).rounded() / 10000
                return rounded == 0 ? 0.0 : rounded
            case let string as String:
                let range = NSRange(string.startIndex..., in: string)
                return addressPattern.stringByReplacingMatches(in: string, range: range, withTemplate: "0x<addr>")
            default:
                return value
            }
        }

        /// The key path of the first value JSONSerialization cannot write
        /// (a non-finite number or a non-JSON type), or nil.
        static func firstUnwritablePath(_ value: Any, path: String) -> String? {
            switch value {
            case let dictionary as [String: Any]:
                for (key, element) in dictionary {
                    if let found = firstUnwritablePath(element, path: path + "." + key) {
                        return found
                    }
                }
                return nil
            case let array as [Any]:
                for (index, element) in array.enumerated() {
                    if let found = firstUnwritablePath(element, path: path + "[\(index)]") {
                        return found
                    }
                }
                return nil
            case is String, is NSNull:
                return nil
            default:
                return JSONSerialization.isValidJSONObject([value]) ? nil : path + " (\(type(of: value)) \(value))"
            }
        }

        /// Pretty-printed header, then one compact line per node: keeps the
        /// fixture small and makes a textual diff point at the changed node.
        static func serialize(_ snapshot: [String: Any]) throws -> Data {
            // JSONSerialization raises an Objective-C exception on a value it
            // cannot write; name the value instead.
            if let path = firstUnwritablePath(snapshot, path: "$") {
                throw SnapshotError("cannot write \(path) as JSON")
            }
            var header = snapshot
            let nodes = header.removeValue(forKey: "nodes") as? [Any] ?? []
            header["nodes"] = []
            var text = try String(decoding: JSONSerialization.data(withJSONObject: header, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]), as: UTF8.self)
            let lines = try nodes.map {
                try String(decoding: JSONSerialization.data(withJSONObject: $0, options: [.sortedKeys, .withoutEscapingSlashes]), as: UTF8.self)
            }
            guard let range = text.range(of: "\"nodes\" : [\n\n  ]") ?? text.range(of: "\"nodes\" : [\n  ]") ?? text.range(of: "\"nodes\" : []") else {
                throw SnapshotError("unexpected header layout")
            }
            text.replaceSubrange(range, with: "\"nodes\" : [\n" + lines.joined(separator: ",\n") + "\n  ]")
            return Data((text + "\n").utf8)
        }
    }

    /// Turns a decoded wire object into plain JSON by replaying the object's own
    /// `-encodeWithCoder:` into a recording coder. The output therefore lists
    /// exactly the keys that cross the wire, under their wire names, for every
    /// model class — no per-class field list to keep in sync with LookinCore,
    /// before or after the Swift rewrite.
    ///
    /// Images (NSImage, or NSData holding PNG / TIFF / JPEG bytes) are handed to
    /// `imageSink`, which returns the JSON that stands in for them.
    final class SnapshotWireJSON {
        typealias ImageSink = (_ image: CGImage, _ keyPath: [String]) -> Any

        private let imageSink: ImageSink
        /// Keys the caller handles itself (e.g. `subitems` on display items, so
        /// the tree walk can attach details and stable node ids).
        private let skippedKeys: [String: Set<String>]

        init(skippedKeys: [String: Set<String>] = [:], imageSink: @escaping ImageSink) {
            self.skippedKeys = skippedKeys
            self.imageSink = imageSink
        }

        func convert(_ value: Any?, keyPath: [String] = []) -> Any {
            guard let value else { return NSNull() }

            if value is NSNull {
                return NSNull()
            }
            if let number = value as? NSNumber {
                return Self.json(number)
            }
            if let string = value as? String {
                return string
            }
            if let data = value as? Data {
                if let image = Self.cgImage(fromEncoded: data) {
                    return imageSink(image, keyPath)
                }
                return ["$data": ["length": data.count]]
            }
            if let image = value as? NSImage {
                var rect = CGRect(origin: .zero, size: image.size)
                if let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) {
                    return imageSink(cgImage, keyPath)
                }
                return ["$image": NSNull()]
            }
            if let nsValue = value as? NSValue {
                return Self.json(nsValue)
            }
            if value is Date {
                return ["$date": "<volatile>"]
            }
            if let error = value as? NSError {
                return ["$error": ["domain": error.domain, "code": error.code]]
            }
            if let array = value as? [Any] {
                return array.enumerated().map { convert($0.element, keyPath: keyPath + ["\($0.offset)"]) }
            }
            if let set = value as? Set<AnyHashable> {
                let items = set.map { convert($0, keyPath: keyPath) }
                return items.sorted { Self.sortKey($0) < Self.sortKey($1) }
            }
            if let dictionary = value as? [AnyHashable: Any] {
                var out: [String: Any] = [:]
                for (key, element) in dictionary {
                    let name = "\(key)"
                    out[name] = convert(element, keyPath: keyPath + [name])
                }
                return out
            }
            if let object = value as? NSObject, object.conforms(to: NSCoding.self) {
                return record(object, keyPath: keyPath)
            }
            return ["$unsupported": String(describing: type(of: value))]
        }

        func record(_ object: NSObject, keyPath: [String]) -> [String: Any] {
            let className = NSStringFromClass(object.classForKeyedArchiver ?? type(of: object))
            let coder = SnapshotRecordingCoder(owner: self, keyPath: keyPath, skipped: skippedKeys[className] ?? [])
            (object as? NSCoding)?.encode(with: coder)
            var out = coder.fields
            out["$class"] = className
            return out
        }

        // MARK: - Leaf conversions

        static func json(_ number: NSNumber) -> Any {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue
            }
            switch String(cString: number.objCType) {
            case "f", "d":
                return number.doubleValue
            default:
                return number.int64Value
            }
        }

        /// Structs are written as their type encoding plus their scalar fields,
        /// e.g. `{"$value": "{CGRect={CGPoint=dd}{CGSize=dd}}", "v": [0,0,10,10]}`.
        static func json(_ value: NSValue) -> Any {
            let type = String(cString: value.objCType)
            var size = 0
            NSGetSizeAndAlignment(value.objCType, &size, nil)
            var bytes = [UInt8](repeating: 0, count: size)
            value.getValue(&bytes, size: size)

            let scalars = scalarLetters(of: type)
            if let scalars, scalars.allSatisfy({ $0 == "d" }), scalars.count * 8 == size {
                let doubles = bytes.withUnsafeBytes { Array($0.bindMemory(to: Double.self)) }
                return ["$value": type, "v": doubles]
            }
            if let scalars, scalars.allSatisfy({ $0 == "f" }), scalars.count * 4 == size {
                let floats = bytes.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
                return ["$value": type, "v": floats.map(Double.init)]
            }
            if let scalars, scalars.allSatisfy({ "qQlLiI".contains($0) }), scalars.count * 8 == size {
                let ints = bytes.withUnsafeBytes { Array($0.bindMemory(to: Int64.self)) }
                return ["$value": type, "v": ints]
            }
            return ["$value": type, "hex": bytes.map { String(format: "%02x", $0) }.joined()]
        }

        /// The scalar type letters of a struct encoding with the struct names
        /// removed, or nil when it holds pointers or other non-scalar members.
        private static func scalarLetters(of encoding: String) -> [Character]? {
            var letters: [Character] = []
            var insideName = false
            for character in encoding {
                switch character {
                case "{":
                    insideName = true
                case "=":
                    insideName = false
                case "}":
                    insideName = false
                default:
                    if insideName {
                        continue
                    }
                    guard "dfqQlLiIcCsSB".contains(character) else { return nil }
                    letters.append(character)
                }
            }
            return letters.isEmpty ? nil : letters
        }

        static func cgImage(fromEncoded data: Data) -> CGImage? {
            let magic = [UInt8](data.prefix(4))
            let isPNG = magic.starts(with: [0x89, 0x50, 0x4E, 0x47])
            let isTIFF = magic.starts(with: [0x49, 0x49, 0x2A, 0x00]) || magic.starts(with: [0x4D, 0x4D, 0x00, 0x2A])
            let isJPEG = magic.starts(with: [0xFF, 0xD8, 0xFF])
            guard isPNG || isTIFF || isJPEG,
                  let source = CGImageSourceCreateWithData(data as CFData, nil)
            else { return nil }
            return CGImageSourceCreateImageAtIndex(source, 0, nil)
        }

        static func sortKey(_ value: Any) -> String {
            if let data = try? JSONSerialization.data(withJSONObject: ["k": value], options: [.sortedKeys]) {
                return String(decoding: data, as: UTF8.self)
            }
            return "\(value)"
        }
    }

    /// A keyed NSCoder that only records. Scalars keep their JSON type; objects
    /// recurse through `SnapshotWireJSON.convert`.
    private final class SnapshotRecordingCoder: NSCoder {
        private(set) var fields: [String: Any] = [:]
        private let owner: SnapshotWireJSON
        private let keyPath: [String]
        private let skipped: Set<String>

        init(owner: SnapshotWireJSON, keyPath: [String], skipped: Set<String>) {
            self.owner = owner
            self.keyPath = keyPath
            self.skipped = skipped
            super.init()
        }

        override var allowsKeyedCoding: Bool {
            true
        }

        override var requiresSecureCoding: Bool {
            false
        }

        private func store(_ value: @autoclosure () -> Any, _ key: String) {
            guard !skipped.contains(key) else { return }
            fields[key] = value()
        }

        override func encode(_ object: Any?, forKey key: String) {
            store(owner.convert(object, keyPath: keyPath + [key]), key)
        }

        override func encodeConditionalObject(_ object: Any?, forKey key: String) {
            encode(object, forKey: key)
        }

        override func encode(_ value: Bool, forKey key: String) {
            store(value, key)
        }

        override func encodeCInt(_ value: Int32, forKey key: String) {
            store(Int64(value), key)
        }

        override func encode(_ value: Int32, forKey key: String) {
            store(Int64(value), key)
        }

        override func encode(_ value: Int64, forKey key: String) {
            store(value, key)
        }

        override func encode(_ value: Int, forKey key: String) {
            store(Int64(value), key)
        }

        override func encode(_ value: Float, forKey key: String) {
            store(Double(value), key)
        }

        override func encode(_ value: Double, forKey key: String) {
            store(value, key)
        }

        override func encodeBytes(_: UnsafePointer<UInt8>?, length: Int, forKey key: String) {
            store(["$bytes": length], key)
        }

        override func encode(_ rect: NSRect, forKey key: String) {
            store(["$rect": [rect.origin.x, rect.origin.y, rect.size.width, rect.size.height]], key)
        }

        override func encode(_ point: NSPoint, forKey key: String) {
            store(["$point": [point.x, point.y]], key)
        }

        override func encode(_ size: NSSize, forKey key: String) {
            store(["$size": [size.width, size.height]], key)
        }
    }
#endif
