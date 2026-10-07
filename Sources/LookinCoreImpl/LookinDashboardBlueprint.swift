//
//  LookinDashboardBlueprint.swift
//  LookinCore
//
//  Was LookinDashboardBlueprint.m. The tables
//  live in LookinDashboardBlueprint+Groups.swift, +Sections.swift and
//  +AttrInfo.swift; the output of every class method below is pinned by
//  Tests/LookinServerHierarchyTests/BlueprintEquivalenceTests.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    /// Namespace for the blueprint's static tables. Each table is built once,
    /// on first use, like the `dispatch_once` dictionaries it replaces.
    enum LookinDashboardBlueprintTables {
        // Class name of an attribute that lives on the platform view.
        #if canImport(UIKit)
            static let viewClassName = "UIView"
            static let layoutGuideClassName = "UILayoutGuide"
        #else
            static let viewClassName = "NSView"
            static let layoutGuideClassName = "NSLayoutGuide"
        #endif

        /// What the blueprint knows about one attribute.
        struct AttrInfo {
            /// Required: the class that owns the attribute.
            var className: String?
            /// Full name. It is the search keyword and the search result
            /// title; nil keeps the attribute out of search.
            var fullTitle: String?
            /// Short name, only for checkboxes and inputs with a built-in
            /// title. Falls back to `fullTitle` when nil.
            var briefTitle: String?
            /// Getter selector. nil derives it from `fullTitle` (first letter
            /// lowercased); "" pins the value to nil.
            var getterString: String?
            /// Setter selector. nil derives it from `fullTitle`
            /// (`set<FullTitle>:`); "" makes the attribute read-only.
            var setterString: String?
            /// The concrete object type when the value is an object.
            var typeIfObj: LookinAttrType?
            /// The enum's name (for example "NSTextAlignment") when the value
            /// is an enum; the host looks up its cases by this name.
            var enumList: String?
            /// Whether the host refetches frames and screenshots after the
            /// user modifies the value. nil means NO.
            var patch: Bool?
            /// Whether a nil value is left out of the transfer. nil means NO.
            var hideIfNil: Bool?
            /// Minimum OS major version; nil means no limit.
            var osVersion: Int?
        }

        /// `%@` of a possibly nil string, as `+[NSString stringWithFormat:]`
        /// writes it. Only reached in release builds for an attribute without
        /// a title, where the Objective-C implementation produced
        /// "(null)(null)".
        static func formatted(_ string: String?) -> String {
            string ?? "(null)"
        }

        static func info(_ attrID: String?) -> AttrInfo? {
            guard let attrID else {
                return nil
            }
            return attrInfo[attrID]
        }
    }

    /// `NSAssert(condition, @"")` from Objective-C: in debug builds a failed
    /// condition raises NSInternalInconsistencyException, which Objective-C
    /// callers can catch; in release builds it does nothing.
    /// (NSAssertionHandler's failure methods are unavailable in Swift.)
    private func blueprintAssert(_ condition: @autoclosure () -> Bool, method: Selector) {
        #if DEBUG
            if !condition() {
                NSException(
                    name: .internalInconsistencyException,
                    reason: "Assertion failure in +[LookinDashboardBlueprint \(NSStringFromSelector(method))]",
                    userInfo: nil
                ).raise()
            }
        #endif
    }

    @objc(LookinDashboardBlueprint)
    public class LookinDashboardBlueprint: NSObject {
        @objc(groupIDs)
        public class func groupIDs() -> [String]! {
            LookinDashboardBlueprintTables.groupIDs
        }

        @objc(sectionIDsForGroupID:)
        public class func sectionIDs(forGroupID groupID: String?) -> [String]! {
            guard let groupID else {
                return nil
            }
            return LookinDashboardBlueprintTables.sectionIDsByGroupID[groupID]
        }

        @objc(attrIDsForSectionID:)
        public class func attrIDs(forSectionID sectionID: String?) -> [String]! {
            guard let sectionID else {
                return nil
            }
            return LookinDashboardBlueprintTables.attrIDsBySectionID[sectionID]
        }

        @objc(getHostGroupID:sectionID:fromAttrID:)
        public class func getHostGroupID(
            _ groupID: AutoreleasingUnsafeMutablePointer<NSString?>?,
            sectionID: AutoreleasingUnsafeMutablePointer<NSString?>?,
            fromAttrID targetAttrID: String?
        ) {
            var targetGroupID: String?
            var targetSectionID: String?
            search: for candidateGroupID in groupIDs() ?? [] {
                for candidateSectionID in sectionIDs(forGroupID: candidateGroupID) ?? [] {
                    for attrID in attrIDs(forSectionID: candidateSectionID) ?? [] where attrID == targetAttrID {
                        targetGroupID = candidateGroupID
                        targetSectionID = candidateSectionID
                        break search
                    }
                }
            }
            if let groupID, let targetGroupID {
                groupID.pointee = targetGroupID as NSString
            }
            if let sectionID, let targetSectionID {
                sectionID.pointee = targetSectionID as NSString
            }
        }

        @objc(groupTitleWithGroupID:)
        public class func groupTitle(withGroupID groupID: String?) -> String! {
            let title = groupID.flatMap { LookinDashboardBlueprintTables.groupTitles[$0] }
            blueprintAssert(!(title ?? "").isEmpty, method: #selector(groupTitle(withGroupID:)))
            return title
        }

        @objc(sectionTitleWithSectionID:)
        public class func sectionTitle(withSectionID secID: String?) -> String! {
            secID.flatMap { LookinDashboardBlueprintTables.sectionTitles[$0] }
        }

        @objc(objectAttrTypeWithAttrID:)
        public class func objectAttrType(withAttrID attrID: String?) -> LookinAttrType {
            LookinDashboardBlueprintTables.info(attrID)?.typeIfObj ?? LookinAttrType.none
        }

        @objc(classNameWithAttrID:)
        public class func className(withAttrID attrID: String?) -> String! {
            let className = LookinDashboardBlueprintTables.info(attrID)?.className
            blueprintAssert(!(className ?? "").isEmpty, method: #selector(className(withAttrID:)))
            return className
        }

        @objc(targetKindForAttrID:)
        public class func targetKind(forAttrID attrID: String?) -> LookinAttrTargetKind {
            switch className(withAttrID: attrID) {
            case "CALayer":
                .layer
            case "UIWindowScene", "NSWindow":
                .window
            case "NSCell", "NSButtonCell", "NSTextFieldCell":
                .cell
            default:
                .view
            }
        }

        @objc(isWindowPropertyWithAttrID:)
        public class func isWindowProperty(withAttrID attrID: String?) -> Bool {
            targetKind(forAttrID: attrID) == .window
        }

        @objc(isUIViewPropertyWithAttrID:)
        public class func isUIViewProperty(withAttrID attrID: String?) -> Bool {
            targetKind(forAttrID: attrID) == .view
        }

        @objc(enumListNameWithAttrID:)
        public class func enumListName(withAttrID attrID: String?) -> String! {
            LookinDashboardBlueprintTables.info(attrID)?.enumList
        }

        @objc(needPatchAfterModificationWithAttrID:)
        public class func needPatchAfterModification(withAttrID attrID: String?) -> Bool {
            LookinDashboardBlueprintTables.info(attrID)?.patch ?? false
        }

        @objc(fullTitleWithAttrID:)
        public class func fullTitle(withAttrID attrID: String?) -> String! {
            LookinDashboardBlueprintTables.info(attrID)?.fullTitle
        }

        @objc(briefTitleWithAttrID:)
        public class func briefTitle(withAttrID attrID: String?) -> String! {
            let info = LookinDashboardBlueprintTables.info(attrID)
            return info?.briefTitle ?? info?.fullTitle
        }

        @objc(getterWithAttrID:)
        public class func getter(withAttrID attrID: String?) -> Selector! {
            let info = LookinDashboardBlueprintTables.info(attrID)
            if let getterString = info?.getterString {
                // An empty string (for example image_open_open) pins the
                // value to nil.
                return getterString.isEmpty ? nil : NSSelectorFromString(getterString)
            }
            let fullTitle = info?.fullTitle
            blueprintAssert(!(fullTitle ?? "").isEmpty, method: #selector(getter(withAttrID:)))
            return NSSelectorFromString(
                LookinDashboardBlueprintTables.formatted(fullTitle?.prefix(1).lowercased()) +
                    LookinDashboardBlueprintTables.formatted(fullTitle.map { String($0.dropFirst()) })
            )
        }

        @objc(setterWithAttrID:)
        public class func setter(withAttrID attrID: String?) -> Selector! {
            let info = LookinDashboardBlueprintTables.info(attrID)
            if let setterString = info?.setterString {
                // An empty string means the client cannot modify the
                // attribute.
                return setterString.isEmpty ? nil : NSSelectorFromString(setterString)
            }
            let fullTitle = info?.fullTitle
            blueprintAssert(!(fullTitle ?? "").isEmpty, method: #selector(setter(withAttrID:)))
            return NSSelectorFromString(
                "set" + LookinDashboardBlueprintTables.formatted(fullTitle?.prefix(1).uppercased()) +
                    LookinDashboardBlueprintTables.formatted(fullTitle.map { String($0.dropFirst()) }) + ":"
            )
        }

        @objc(hideIfNilWithAttrID:)
        public class func hideIfNil(withAttrID attrID: String?) -> Bool {
            LookinDashboardBlueprintTables.info(attrID)?.hideIfNil ?? false
        }

        @objc(minAvailableOSVersionWithAttrID:)
        public class func minAvailableOSVersion(withAttrID attrID: String?) -> Int {
            LookinDashboardBlueprintTables.info(attrID)?.osVersion ?? 0
        }
    }

#endif
