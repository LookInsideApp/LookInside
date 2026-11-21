//
//  AttributePresentation.swift
//  LookinCore
//
//  How the Server hands an attribute's value to the Host when the Host has no
//  view for what the getter returns: option sets, structs and objects become
//  one line of text, arrays their element count, CGColor a color. The Host
//  only ever receives types it already shows (inspector-attribute-coverage-plan.md).
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation

    /// How an attribute's value reaches the Host.
    public enum AttributePresentation: Equatable, Sendable {
        /// The value as the getter returns it.
        case value
        /// An NS_OPTIONS value as "flexibleWidth | flexibleHeight"; the
        /// argument names the table in `AttributeOptionNames.tables`.
        case optionNames(String)
        /// A struct the Host has no view for (CGAffineTransform, CATransform3D,
        /// NSDirectionalEdgeInsets, UIOffset, NSRange, CGVector), as one line
        /// of text.
        case structure
        /// An object as one line of text.
        case summary(AttributeSummaryKind)
        /// An array, set or dictionary as its element count.
        case count
        /// A CGColor as a color.
        case cgColor
    }

    /// What a `.summary` attribute holds, and so which of its public
    /// properties make up the line of text.
    public enum AttributeSummaryKind: String, Sendable {
        /// Font name and point size: "SFUI-Regular 17".
        case font
        /// The asset name the image was loaded by, else its size.
        case image
        /// ISO 8601.
        case date
        /// The locale identifier.
        case locale
        /// The time zone name.
        case timeZone
        /// The calendar identifier.
        case calendar
        /// The plain text.
        case attributedString
        /// The absolute string.
        case url
        /// The appearance name.
        case appearance
        /// Title and item count.
        case menu
        /// Class name and title (button, background and content configurations).
        case configuration
        /// The class name (views, view controllers, responders).
        case className
        /// The screen's name, or its size and scale.
        case screen
        /// Identifier, display mode and item count.
        case toolbar
        /// The title.
        case navigationItem
        /// The title.
        case barItem
        /// Offset and blur radius.
        case shadow
        /// The bounding box.
        case path
        /// The object's description, on one line.
        case description
    }

    /// One named value of an option set the inspector shows as text.
    public struct AttributeOptionName: Equatable, Sendable {
        public let name: String
        public let value: UInt64

        public init(_ name: String, _ value: UInt64) {
            self.name = name
            self.value = value
        }
    }

    /// The option set tables `.optionNames` attributes name; filled in by
    /// AttributeOptionNames.swift, which Scripts/generate-enum-tables.py writes.
    public enum AttributeOptionNames {}

#endif
