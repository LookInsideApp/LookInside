//
//  DashboardBlueprintCatalog.swift
//  LookinCore
//
//  The entry types of the blueprint catalog and the lookup tables derived from
//  it. The catalog itself (DashboardBlueprint+Catalog.swift and the per-platform
//  group files) names every group once, with its sections and their attributes
//  nested inside, in display order; `DashboardBlueprint` answers from the
//  tables derived here. Before, the same facts were kept by hand in four
//  separate tables, and an attribute had to be registered in all of them.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    /// The platforms a catalog entry is on.
    struct BlueprintPlatforms: OptionSet, Sendable {
        let rawValue: Int

        static let uiKit = BlueprintPlatforms(rawValue: 1 << 0)
        static let appKit = BlueprintPlatforms(rawValue: 1 << 1)
        static let all: BlueprintPlatforms = [.uiKit, .appKit]

        /// The platform this code is compiled for. Mac Catalyst is UIKit.
        static var current: BlueprintPlatforms {
            #if canImport(UIKit)
                .uiKit
            #else
                .appKit
            #endif
        }
    }

    /// One attribute: its identifier and what the blueprint knows about it.
    struct BlueprintAttribute {
        let identifier: InspectedAttribute.Identifier
        /// nil: the platforms of the section it is in.
        let platforms: BlueprintPlatforms?
        let info: DashboardBlueprintTables.AttributeInfo

        init(_ identifier: InspectedAttribute.Identifier, on platforms: BlueprintPlatforms? = nil, _ info: DashboardBlueprintTables.AttributeInfo) {
            self.identifier = identifier
            self.platforms = platforms
            self.info = info
        }
    }

    /// One section of a group, with its attributes in display order.
    struct BlueprintSection {
        let identifier: AttributesSection.Identifier
        /// nil: the section has no title.
        let title: String?
        /// nil: the platforms of the group it is in.
        let platforms: BlueprintPlatforms?
        let attributes: [BlueprintAttribute]

        init(_ identifier: AttributesSection.Identifier, title: String? = nil, on platforms: BlueprintPlatforms? = nil, attributes: [BlueprintAttribute]) {
            self.identifier = identifier
            self.title = title
            self.platforms = platforms
            self.attributes = attributes
        }
    }

    /// One attribute group, with its sections in display order.
    struct BlueprintGroup {
        let identifier: AttributesGroup.Identifier
        let title: String
        /// The platforms whose `DashboardBlueprint.groupIdentifiers` list the group.
        let platforms: BlueprintPlatforms
        let sections: [BlueprintSection]

        init(_ identifier: AttributesGroup.Identifier, title: String, on platforms: BlueprintPlatforms, sections: [BlueprintSection]) {
            self.identifier = identifier
            self.title = title
            self.platforms = platforms
            self.sections = sections
        }
    }

    /// The lookup tables `DashboardBlueprint` answers from, derived from a
    /// catalog for one platform:
    ///
    /// - `groupIdentifiers`: the groups on the platform, in catalog order.
    /// - `sectionIdentifiersByGroup`: for each group, its sections on the
    ///   platform; no entry when it has none. The group itself need not be
    ///   listed there: the NSCell group's sections are on both platforms
    ///   although only AppKit lists the group.
    /// - `attributeIdentifiersBySection`: for each section on the platform, its
    ///   attributes on the platform.
    /// - `groupTitles`, `sectionTitles`, `attributeInfo`: every entry of the
    ///   catalog, whatever its platforms, because the macOS Host shows iOS data.
    ///   A section without a title has no entry.
    struct DashboardBlueprintDerivedTables {
        var groupIdentifiers: [AttributesGroup.Identifier] = []
        var sectionIdentifiersByGroup: [AttributesGroup.Identifier: [AttributesSection.Identifier]] = [:]
        var attributeIdentifiersBySection: [AttributesSection.Identifier: [InspectedAttribute.Identifier]] = [:]
        var groupTitles: [AttributesGroup.Identifier: String] = [:]
        var sectionTitles: [AttributesSection.Identifier: String] = [:]
        var attributeInfo: [InspectedAttribute.Identifier: DashboardBlueprintTables.AttributeInfo] = [:]
        /// The class of a section whose attributes on this platform all belong
        /// to one class.
        var sectionClassNames: [AttributesSection.Identifier: String] = [:]

        init(catalog: [BlueprintGroup], platform: BlueprintPlatforms) {
            assert(Self.duplicateIdentifiers(in: catalog).isEmpty, "duplicate identifiers in the blueprint catalog: \(Self.duplicateIdentifiers(in: catalog))")
            for group in catalog {
                if group.platforms.contains(platform) {
                    groupIdentifiers.append(group.identifier)
                }
                groupTitles[group.identifier] = group.title
                var sectionIdentifiers: [AttributesSection.Identifier] = []
                for section in group.sections {
                    let sectionPlatforms = section.platforms ?? group.platforms
                    if let title = section.title {
                        sectionTitles[section.identifier] = title
                    }
                    var attributeIdentifiers: [InspectedAttribute.Identifier] = []
                    for attribute in section.attributes {
                        attributeInfo[attribute.identifier] = attribute.info
                        if (attribute.platforms ?? sectionPlatforms).contains(platform) {
                            attributeIdentifiers.append(attribute.identifier)
                        }
                    }
                    if sectionPlatforms.contains(platform) {
                        sectionIdentifiers.append(section.identifier)
                        attributeIdentifiersBySection[section.identifier] = attributeIdentifiers
                        let classNames = Set(attributeIdentifiers.map { attributeInfo[$0]?.className })
                        if classNames.count == 1, let className = classNames.first ?? nil {
                            sectionClassNames[section.identifier] = className
                        }
                    }
                }
                if !sectionIdentifiers.isEmpty {
                    sectionIdentifiersByGroup[group.identifier] = sectionIdentifiers
                }
            }
        }

        /// The identifiers that appear more than once in `catalog`, counting
        /// groups, sections and attributes together: they share one namespace
        /// on the wire and in the Host's preferences, and a second entry would
        /// silently replace the first in the derived tables.
        static func duplicateIdentifiers(in catalog: [BlueprintGroup]) -> [String] {
            var seen = Set<String>()
            var duplicates: [String] = []
            func visit(_ identifier: String) {
                if !seen.insert(identifier).inserted {
                    duplicates.append(identifier)
                }
            }
            for group in catalog {
                visit(group.identifier.rawValue)
                for section in group.sections {
                    visit(section.identifier.rawValue)
                    for attribute in section.attributes {
                        visit(attribute.identifier.rawValue)
                    }
                }
            }
            return duplicates
        }
    }

    extension DashboardBlueprintTables {
        /// The tables for the platform this code runs on, built on first use.
        static let derived = DashboardBlueprintDerivedTables(catalog: catalog, platform: .current)

        /// `DashboardBlueprint.groupIdentifiers`, in display order.
        static let groupIdentifiers: [AttributesGroup.Identifier] = derived.groupIdentifiers
        /// `DashboardBlueprint.sectionIdentifiers(in:)`.
        static let sectionIdentifiersByGroup: [AttributesGroup.Identifier: [AttributesSection.Identifier]] = derived.sectionIdentifiersByGroup
        /// `DashboardBlueprint.attributeIdentifiers(in:)`, in display order.
        static let attributeIdentifiersBySection: [AttributesSection.Identifier: [InspectedAttribute.Identifier]] = derived.attributeIdentifiersBySection
        /// `DashboardBlueprint.title(of:)` for groups.
        static let groupTitles: [AttributesGroup.Identifier: String] = derived.groupTitles
        /// `DashboardBlueprint.title(of:)` for sections; a missing entry means
        /// no title.
        static let sectionTitles: [AttributesSection.Identifier: String] = derived.sectionTitles
        /// The per-attribute information behind the attribute queries.
        static let attributeInfo: [InspectedAttribute.Identifier: AttributeInfo] = derived.attributeInfo
        static let sectionClassNames: [AttributesSection.Identifier: String] = derived.sectionClassNames
    }

#endif
