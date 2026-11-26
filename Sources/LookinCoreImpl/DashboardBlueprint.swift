//
//  DashboardBlueprint.swift
//  LookinCore
//
//  Was LookinDashboardBlueprint.m. The groups, sections and attributes are
//  one nested catalog (DashboardBlueprint+Catalog.swift and the per-platform
//  group files); DashboardBlueprintCatalog.swift derives the lookup tables the
//  class methods below answer from. The output of every class method is
//  pinned by Tests/LookinServerHierarchyTests/BlueprintEquivalenceTests.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    /// Namespace for the blueprint's static tables. Each table is built once,
    /// on first use, like the `dispatch_once` dictionaries it replaces.
    enum DashboardBlueprintTables {
        // Class name of an attribute that lives on the platform view.
        #if canImport(UIKit)
            static let viewClassName = "UIView"
            static let layoutGuideClassName = "UILayoutGuide"
        #else
            static let viewClassName = "NSView"
            static let layoutGuideClassName = "NSLayoutGuide"
        #endif

        /// What the blueprint knows about one attribute.
        struct AttributeInfo {
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
            var objectValueType: InspectedAttribute.ValueType?
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
            /// The attribute catalog revision that introduced the attribute
            /// (`DashboardBlueprint.currentCatalogRevision`); a Host that declares an
            /// older revision does not get it. Everything before revisions
            /// existed is 0.
            var revision: Int = 0
            /// How the value reaches the Host (AttributePresentation.swift).
            /// Anything but `.value` is read-only, so give it `setterString: ""`.
            var presentation: AttributePresentation = .value
        }

        /// `%@` of a possibly nil string, as `+[NSString stringWithFormat:]`
        /// writes it. Only reached in release builds for an attribute without
        /// a title, where the Objective-C implementation produced
        /// "(null)(null)".
        static func formatted(_ string: String?) -> String {
            string ?? "(null)"
        }

        static func info(_ attribute: InspectedAttribute.Identifier?) -> AttributeInfo? {
            attribute.flatMap { attributeInfo[$0] }
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

    /// What the dashboard shows for each group, section and attribute: their
    /// order on this platform, titles, and how each attribute is read and
    /// written. Swift asks with typed identifiers; Objective-C keeps the
    /// string selectors `core-objc-surface.json` records, which Swift does not
    /// see.
    @objc(LookinDashboardBlueprint)
    public class DashboardBlueprint: NSObject {
        /// The newest attribute catalog revision this build knows. Raise it by
        /// one for each batch of attributes that needs a matching Host (new
        /// groups, sections or enum lists), and give that batch the new
        /// revision.
        public static let currentCatalogRevision = 2

        // MARK: Groups and sections

        /// The groups on this platform, in display order.
        public static var groupIdentifiers: [AttributesGroup.Identifier] {
            DashboardBlueprintTables.groupIdentifiers
        }

        /// The sections of `group` on this platform, in display order; nil
        /// when it has none here.
        public static func sectionIdentifiers(in group: AttributesGroup.Identifier) -> [AttributesSection.Identifier]? {
            DashboardBlueprintTables.sectionIdentifiersByGroup[group]
        }

        /// The attributes of `section` on this platform, in display order; nil
        /// when the section is not on this platform.
        public static func attributeIdentifiers(in section: AttributesSection.Identifier) -> [InspectedAttribute.Identifier]? {
            DashboardBlueprintTables.attributeIdentifiersBySection[section]
        }

        /// The group and section that list `attribute` on this platform.
        public static func location(of attribute: InspectedAttribute.Identifier) -> (group: AttributesGroup.Identifier, section: AttributesSection.Identifier)? {
            for group in groupIdentifiers {
                for section in sectionIdentifiers(in: group) ?? [] where attributeIdentifiers(in: section)?.contains(attribute) == true {
                    return (group, section)
                }
            }
            return nil
        }

        /// The title of `group`. Asserts that it has one.
        public static func title(of group: AttributesGroup.Identifier) -> String? {
            assertedTitle(of: group)
        }

        /// The title of `section`; nil when it has none.
        public static func title(of section: AttributesSection.Identifier) -> String? {
            DashboardBlueprintTables.sectionTitles[section]
        }

        /// The class every attribute of `section` belongs to, when they all
        /// belong to the same one; the Server skips the whole section for a
        /// target of another class.
        public static func uniformClassName(of section: AttributesSection.Identifier) -> String? {
            DashboardBlueprintTables.sectionClassNames[section]
        }

        // MARK: Attributes

        /// The concrete object type of `attribute`'s value when it is an
        /// object; `.none` otherwise.
        public static func objectValueType(of attribute: InspectedAttribute.Identifier) -> InspectedAttribute.ValueType {
            DashboardBlueprintTables.info(attribute)?.objectValueType ?? .none
        }

        /// The class that owns `attribute`. Asserts that it has one.
        public static func className(of attribute: InspectedAttribute.Identifier) -> String? {
            assertedClassName(of: attribute)
        }

        /// The object `attribute` is read from and written to.
        public static func targetKind(of attribute: InspectedAttribute.Identifier) -> InspectedAttribute.TargetKind {
            targetKind(forClassName: assertedClassName(of: attribute))
        }

        /// The object an attribute of `className` is read from. Decided by the
        /// name alone, so the Host (which cannot load UIKit classes) and every
        /// Server agree: Core Animation classes are layers, AppKit classes
        /// ending in "Cell" are cells (NSTableCellView ends in "CellView" and
        /// stays a view), the window classes are windows, UIKit and AppKit
        /// classes ending in "LayoutGuide" are layout guides, the rest views.
        static func targetKind(forClassName className: String?) -> InspectedAttribute.TargetKind {
            guard let className else {
                return .view
            }
            if className == "UIWindowScene" || className == "NSWindow" {
                return .window
            }
            if className.hasSuffix("LayoutGuide"), className.hasPrefix("UI") || className.hasPrefix("NS") {
                return .layoutGuide
            }
            if className.hasPrefix("CA") {
                return .layer
            }
            if className.hasPrefix("NS"), className.hasSuffix("Cell") {
                return .cell
            }
            return .view
        }

        /// Whether `attribute` is read from the window.
        public static func isWindowProperty(_ attribute: InspectedAttribute.Identifier) -> Bool {
            targetKind(of: attribute) == .window
        }

        /// Whether `attribute` is read from the view.
        public static func isUIViewProperty(_ attribute: InspectedAttribute.Identifier) -> Bool {
            targetKind(of: attribute) == .view
        }

        /// The name of `attribute`'s enum (for example "NSTextAlignment") when
        /// its value is one; the Host looks up the cases by this name.
        public static func enumListName(of attribute: InspectedAttribute.Identifier) -> String? {
            DashboardBlueprintTables.info(attribute)?.enumList
        }

        /// Whether the Host refetches frames and screenshots after the user
        /// modifies `attribute`.
        public static func needsPatchAfterModification(_ attribute: InspectedAttribute.Identifier) -> Bool {
            DashboardBlueprintTables.info(attribute)?.patch ?? false
        }

        /// The full name of `attribute`: its search keyword and search result
        /// title.
        public static func fullTitle(of attribute: InspectedAttribute.Identifier) -> String? {
            DashboardBlueprintTables.info(attribute)?.fullTitle
        }

        /// The short name of `attribute`, falling back to its full name.
        public static func briefTitle(of attribute: InspectedAttribute.Identifier) -> String? {
            let info = DashboardBlueprintTables.info(attribute)
            return info?.briefTitle ?? info?.fullTitle
        }

        /// The getter of `attribute`; nil pins its value to nil.
        public static func getter(of attribute: InspectedAttribute.Identifier) -> Selector? {
            resolvedGetter(of: attribute)
        }

        /// The setter of `attribute`; nil makes it read-only.
        public static func setter(of attribute: InspectedAttribute.Identifier) -> Selector? {
            resolvedSetter(of: attribute)
        }

        /// Whether a nil value of `attribute` is left out of the transfer.
        public static func hidesWhenNil(_ attribute: InspectedAttribute.Identifier) -> Bool {
            DashboardBlueprintTables.info(attribute)?.hideIfNil ?? false
        }

        /// The OS major version `attribute` needs; 0 for no limit.
        public static func minimumAvailableOSVersion(of attribute: InspectedAttribute.Identifier) -> Int {
            DashboardBlueprintTables.info(attribute)?.osVersion ?? 0
        }

        /// The attribute catalog revision that introduced `attribute`, 0 for
        /// an unknown identifier.
        public static func catalogRevision(of attribute: InspectedAttribute.Identifier) -> Int {
            DashboardBlueprintTables.info(attribute)?.revision ?? 0
        }

        /// How the value of `attribute` reaches the Host; `.value` for an
        /// unknown identifier.
        public static func presentation(of attribute: InspectedAttribute.Identifier) -> AttributePresentation {
            DashboardBlueprintTables.info(attribute)?.presentation ?? .value
        }

        /// Whether `attribute` reaches the Host converted by its presentation
        /// (as text, a count or a color) rather than as the getter returns it;
        /// such attributes need no `objectValueType`.
        public static func isPresented(_ attribute: InspectedAttribute.Identifier) -> Bool {
            presentation(of: attribute) != .value
        }

        // MARK: Shared by both front ends

        private static func assertedTitle(of group: AttributesGroup.Identifier?) -> String? {
            let title = group.flatMap { DashboardBlueprintTables.groupTitles[$0] }
            blueprintAssert(!(title ?? "").isEmpty, method: NSSelectorFromString("groupTitleWithGroupID:"))
            return title
        }

        private static func assertedClassName(of attribute: InspectedAttribute.Identifier?) -> String? {
            let className = DashboardBlueprintTables.info(attribute)?.className
            blueprintAssert(!(className ?? "").isEmpty, method: NSSelectorFromString("classNameWithAttrID:"))
            return className
        }

        private static func resolvedGetter(of attribute: InspectedAttribute.Identifier?) -> Selector? {
            let info = DashboardBlueprintTables.info(attribute)
            if let getterString = info?.getterString {
                // An empty string (for example image_open_open) pins the
                // value to nil.
                return getterString.isEmpty ? nil : NSSelectorFromString(getterString)
            }
            let fullTitle = info?.fullTitle
            blueprintAssert(!(fullTitle ?? "").isEmpty, method: NSSelectorFromString("getterWithAttrID:"))
            return NSSelectorFromString(
                DashboardBlueprintTables.formatted(fullTitle?.prefix(1).lowercased()) +
                    DashboardBlueprintTables.formatted(fullTitle.map { String($0.dropFirst()) })
            )
        }

        private static func resolvedSetter(of attribute: InspectedAttribute.Identifier?) -> Selector? {
            let info = DashboardBlueprintTables.info(attribute)
            if let setterString = info?.setterString {
                // An empty string means the client cannot modify the
                // attribute.
                return setterString.isEmpty ? nil : NSSelectorFromString(setterString)
            }
            let fullTitle = info?.fullTitle
            blueprintAssert(!(fullTitle ?? "").isEmpty, method: NSSelectorFromString("setterWithAttrID:"))
            return NSSelectorFromString(
                "set" + DashboardBlueprintTables.formatted(fullTitle?.prefix(1).uppercased()) +
                    DashboardBlueprintTables.formatted(fullTitle.map { String($0.dropFirst()) }) + ":"
            )
        }

        // MARK: Objective-C

        // The selectors core-objc-surface.json records, for the Objective-C
        // tests. Swift uses the typed methods above instead.

        @available(swift, obsoleted: 1)
        @objc(groupIDs)
        public class func objectiveCGroupIDs() -> [String] {
            groupIdentifiers.map(\.rawValue)
        }

        @available(swift, obsoleted: 1)
        @objc(sectionIDsForGroupID:)
        public class func objectiveCSectionIDs(forGroupID groupID: String?) -> [String]? {
            groupID.flatMap { sectionIdentifiers(in: AttributesGroup.Identifier(rawValue: $0))?.map(\.rawValue) }
        }

        @available(swift, obsoleted: 1)
        @objc(attrIDsForSectionID:)
        public class func objectiveCAttributeIDs(forSectionID sectionID: String?) -> [String]? {
            sectionID.flatMap { attributeIdentifiers(in: AttributesSection.Identifier(rawValue: $0))?.map(\.rawValue) }
        }

        @available(swift, obsoleted: 1)
        @objc(getHostGroupID:sectionID:fromAttrID:)
        public class func objectiveCGetHostGroupID(
            _ groupID: AutoreleasingUnsafeMutablePointer<NSString?>?,
            sectionID: AutoreleasingUnsafeMutablePointer<NSString?>?,
            fromAttrID attributeID: String?
        ) {
            guard let location = attributeID.flatMap({ location(of: InspectedAttribute.Identifier(rawValue: $0)) }) else {
                return
            }
            groupID?.pointee = location.group.rawValue as NSString
            sectionID?.pointee = location.section.rawValue as NSString
        }

        @available(swift, obsoleted: 1)
        @objc(groupTitleWithGroupID:)
        public class func objectiveCGroupTitle(withGroupID groupID: String?) -> String? {
            assertedTitle(of: groupID.map(AttributesGroup.Identifier.init(rawValue:)))
        }

        @available(swift, obsoleted: 1)
        @objc(sectionTitleWithSectionID:)
        public class func objectiveCSectionTitle(withSectionID sectionID: String?) -> String? {
            sectionID.flatMap { title(of: AttributesSection.Identifier(rawValue: $0)) }
        }

        @available(swift, obsoleted: 1)
        @objc(objectAttrTypeWithAttrID:)
        public class func objectiveCObjectAttributeType(withAttrID attributeID: String?) -> InspectedAttribute.ValueType {
            DashboardBlueprintTables.info(attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))?.objectValueType ?? .none
        }

        @available(swift, obsoleted: 1)
        @objc(classNameWithAttrID:)
        public class func objectiveCClassName(withAttrID attributeID: String?) -> String? {
            assertedClassName(of: attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))
        }

        @available(swift, obsoleted: 1)
        @objc(targetKindForAttrID:)
        public class func objectiveCTargetKind(forAttrID attributeID: String?) -> InspectedAttribute.TargetKind {
            targetKind(forClassName: assertedClassName(of: attributeID.map(InspectedAttribute.Identifier.init(rawValue:))))
        }

        @available(swift, obsoleted: 1)
        @objc(isWindowPropertyWithAttrID:)
        public class func objectiveCIsWindowProperty(withAttrID attributeID: String?) -> Bool {
            targetKind(forClassName: assertedClassName(of: attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))) == .window
        }

        @available(swift, obsoleted: 1)
        @objc(isUIViewPropertyWithAttrID:)
        public class func objectiveCIsUIViewProperty(withAttrID attributeID: String?) -> Bool {
            targetKind(forClassName: assertedClassName(of: attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))) == .view
        }

        @available(swift, obsoleted: 1)
        @objc(enumListNameWithAttrID:)
        public class func objectiveCEnumListName(withAttrID attributeID: String?) -> String? {
            DashboardBlueprintTables.info(attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))?.enumList
        }

        @available(swift, obsoleted: 1)
        @objc(needPatchAfterModificationWithAttrID:)
        public class func objectiveCNeedsPatchAfterModification(withAttrID attributeID: String?) -> Bool {
            DashboardBlueprintTables.info(attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))?.patch ?? false
        }

        @available(swift, obsoleted: 1)
        @objc(fullTitleWithAttrID:)
        public class func objectiveCFullTitle(withAttrID attributeID: String?) -> String? {
            DashboardBlueprintTables.info(attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))?.fullTitle
        }

        @available(swift, obsoleted: 1)
        @objc(briefTitleWithAttrID:)
        public class func objectiveCBriefTitle(withAttrID attributeID: String?) -> String? {
            let info = DashboardBlueprintTables.info(attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))
            return info?.briefTitle ?? info?.fullTitle
        }

        @available(swift, obsoleted: 1)
        @objc(getterWithAttrID:)
        public class func objectiveCGetter(withAttrID attributeID: String?) -> Selector? {
            resolvedGetter(of: attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))
        }

        @available(swift, obsoleted: 1)
        @objc(setterWithAttrID:)
        public class func objectiveCSetter(withAttrID attributeID: String?) -> Selector? {
            resolvedSetter(of: attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))
        }

        @available(swift, obsoleted: 1)
        @objc(hideIfNilWithAttrID:)
        public class func objectiveCHidesWhenNil(withAttrID attributeID: String?) -> Bool {
            DashboardBlueprintTables.info(attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))?.hideIfNil ?? false
        }

        @available(swift, obsoleted: 1)
        @objc(minAvailableOSVersionWithAttrID:)
        public class func objectiveCMinimumAvailableOSVersion(withAttrID attributeID: String?) -> Int {
            DashboardBlueprintTables.info(attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))?.osVersion ?? 0
        }

        @available(swift, obsoleted: 1)
        @objc(isPresentedWithAttrID:)
        public class func objectiveCIsPresented(withAttrID attributeID: String?) -> Bool {
            (DashboardBlueprintTables.info(attributeID.map(InspectedAttribute.Identifier.init(rawValue:)))?.presentation ?? .value) != .value
        }
    }

#endif
