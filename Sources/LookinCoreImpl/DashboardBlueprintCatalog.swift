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
        let identifier: LookinAttrIdentifier
        /// nil: the platforms of the section it is in.
        let platforms: BlueprintPlatforms?
        let info: DashboardBlueprintTables.AttributeInfo

        init(_ identifier: LookinAttrIdentifier, on platforms: BlueprintPlatforms? = nil, _ info: DashboardBlueprintTables.AttributeInfo) {
            self.identifier = identifier
            self.platforms = platforms
            self.info = info
        }
    }

    /// One section of a group, with its attributes in display order.
    struct BlueprintSection {
        let identifier: LookinAttrSectionIdentifier
        /// nil: the section has no title.
        let title: String?
        /// nil: the platforms of the group it is in.
        let platforms: BlueprintPlatforms?
        let attributes: [BlueprintAttribute]

        init(_ identifier: LookinAttrSectionIdentifier, title: String? = nil, on platforms: BlueprintPlatforms? = nil, attributes: [BlueprintAttribute]) {
            self.identifier = identifier
            self.title = title
            self.platforms = platforms
            self.attributes = attributes
        }
    }

    /// One attribute group, with its sections in display order.
    struct BlueprintGroup {
        let identifier: LookinAttrGroupIdentifier
        let title: String
        /// The platforms whose `groupIDs()` list the group.
        let platforms: BlueprintPlatforms
        let sections: [BlueprintSection]

        init(_ identifier: LookinAttrGroupIdentifier, title: String, on platforms: BlueprintPlatforms, sections: [BlueprintSection]) {
            self.identifier = identifier
            self.title = title
            self.platforms = platforms
            self.sections = sections
        }
    }

    /// The lookup tables `DashboardBlueprint` answers from, derived from a
    /// catalog for one platform:
    ///
    /// - `groupIDs`: the groups on the platform, in catalog order.
    /// - `sectionIDsByGroupID`: for each group, its sections on the platform; no
    ///   entry when it has none. The group itself need not be listed there: the
    ///   NSCell group's sections are on both platforms although only AppKit
    ///   lists the group.
    /// - `attrIDsBySectionID`: for each section on the platform, its attributes
    ///   on the platform.
    /// - `groupTitles`, `sectionTitles`, `attributeInfo`: every entry of the
    ///   catalog, whatever its platforms, because the macOS Host shows iOS data.
    ///   A section without a title has no entry.
    struct DashboardBlueprintDerivedTables {
        var groupIDs: [String] = []
        var sectionIDsByGroupID: [String: [String]] = [:]
        var attrIDsBySectionID: [String: [String]] = [:]
        var groupTitles: [String: String] = [:]
        var sectionTitles: [String: String] = [:]
        var attributeInfo: [String: DashboardBlueprintTables.AttributeInfo] = [:]

        init(catalog: [BlueprintGroup], platform: BlueprintPlatforms) {
            assert(Self.duplicateIdentifiers(in: catalog).isEmpty, "duplicate identifiers in the blueprint catalog: \(Self.duplicateIdentifiers(in: catalog))")
            for group in catalog {
                if group.platforms.contains(platform) {
                    groupIDs.append(group.identifier)
                }
                groupTitles[group.identifier] = group.title
                var sectionIDs: [String] = []
                for section in group.sections {
                    let sectionPlatforms = section.platforms ?? group.platforms
                    if let title = section.title {
                        sectionTitles[section.identifier] = title
                    }
                    var attrIDs: [String] = []
                    for attribute in section.attributes {
                        attributeInfo[attribute.identifier] = attribute.info
                        if (attribute.platforms ?? sectionPlatforms).contains(platform) {
                            attrIDs.append(attribute.identifier)
                        }
                    }
                    if sectionPlatforms.contains(platform) {
                        sectionIDs.append(section.identifier)
                        attrIDsBySectionID[section.identifier] = attrIDs
                    }
                }
                if !sectionIDs.isEmpty {
                    sectionIDsByGroupID[group.identifier] = sectionIDs
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
                visit(group.identifier)
                for section in group.sections {
                    visit(section.identifier)
                    for attribute in section.attributes {
                        visit(attribute.identifier)
                    }
                }
            }
            return duplicates
        }
    }

    extension DashboardBlueprintTables {
        /// The tables for the platform this code runs on, built on first use.
        static let derived = DashboardBlueprintDerivedTables(catalog: catalog, platform: .current)

        /// `+groupIDs`, in display order.
        static let groupIDs: [String] = derived.groupIDs
        /// `+sectionIDsForGroupID:`.
        static let sectionIDsByGroupID: [String: [String]] = derived.sectionIDsByGroupID
        /// `+attrIDsForSectionID:`, in display order.
        static let attrIDsBySectionID: [String: [String]] = derived.attrIDsBySectionID
        /// `+groupTitleWithGroupID:`.
        static let groupTitles: [String: String] = derived.groupTitles
        /// `+sectionTitleWithSectionID:`; a missing entry means no title.
        static let sectionTitles: [String: String] = derived.sectionTitles
        /// The per-attribute information behind the attribute queries.
        static let attributeInfo: [String: AttributeInfo] = derived.attributeInfo
    }

#endif
