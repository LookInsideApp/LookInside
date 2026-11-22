//
//  AttributeCatalogIdentifier.swift
//  LookinCore
//
//  The types of the identifiers AttributeIdentifiers.swift declares: one for
//  groups, one for sections and one for attributes, so the compiler keeps a
//  section's identifier from being passed where an attribute's is expected.
//  Each wraps the string that crosses the wire; the models keep storing and
//  archiving that string under the key "identifier".
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    /// The identifier of an entry in the dashboard's attribute catalog: a
    /// group, a section or an attribute.
    public protocol AttributeCatalogIdentifier: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible where RawValue == String {
        init(rawValue: String)
    }

    extension AttributeCatalogIdentifier {
        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }

        public var description: String {
            rawValue
        }
    }

    extension AttributesGroup {
        /// The identifier of an attribute group. The string crosses the wire.
        public struct Identifier: AttributeCatalogIdentifier {
            public let rawValue: String

            public init(rawValue: String) {
                self.rawValue = rawValue
            }
        }
    }

    extension AttributesSection {
        /// The identifier of an attribute section. The string crosses the wire
        /// and is stored in the Host's settings to remember which sections are
        /// shown.
        public struct Identifier: AttributeCatalogIdentifier {
            public let rawValue: String

            public init(rawValue: String) {
                self.rawValue = rawValue
            }
        }
    }

    extension InspectedAttribute {
        /// The identifier of an attribute. The string crosses the wire.
        public struct Identifier: AttributeCatalogIdentifier {
            public let rawValue: String

            public init(rawValue: String) {
                self.rawValue = rawValue
            }
        }
    }

#endif
