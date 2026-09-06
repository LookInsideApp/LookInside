import Demangling
import Foundation

/// Text derived from the raw model. Graphical filename aliases remain local
/// presentation preferences applied after this shared base representation.
@MainActor
@objc(LKInspectionNodeText)
public final class InspectionNodeText: NSObject {
    @objc(titleForItem:)
    public static func title(for item: LookinDisplayItem) -> String? {
        if let custom = item.customInfo {
            return custom.title
        }
        if let title = item.customDisplayTitle, !title.isEmpty {
            return title
        }
        return simpleClassName(item.displayingObject())
    }

    @objc(subtitleForItem:)
    public static func subtitle(for item: LookinDisplayItem) -> String? {
        if let custom = item.customInfo {
            return custom.subtitle
        }
        if let name = simpleClassName(item.hostWindowControllerObject), !name.isEmpty {
            return name + ".window"
        }
        if let name = simpleClassName(item.hostViewControllerObject), !name.isEmpty {
            return name + ".view"
        }
        guard let object = item.displayingObject() else { return nil }
        if let trace = object.specialTrace, !trace.isEmpty {
            return trace
        }
        let names = Set((object.ivarTraces ?? []).compactMap(\.ivarName))
        return names.isEmpty ? nil : names.sorted().joined(separator: "   ")
    }

    private static func simpleClassName(_ object: LookinObject?) -> String? {
        guard let name = object?.rawClassName() else { return nil }
        let demangled = (try? demangleAsNode(name).print(using: .interfaceType)) ?? name
        let prefix = demangled.prefix(while: { $0 != "<" })
        guard let separator = prefix.lastIndex(of: ".") else { return demangled }
        return String(demangled[demangled.index(after: separator)...])
    }
}
