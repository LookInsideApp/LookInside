//
//  AttributesSection.swift
//  Lookin
//
//  Was LookinAttributesSection.m. The coding keys are pinned by
//  Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinAttributesSection)
    public class AttributesSection: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(identifier)
        public var identifier: String?
        @objc(attributes)
        public var attributes: [InspectedAttribute]?

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newSection = AttributesSection()
            newSection.identifier = identifier
            newSection.attributes = attributes?.map { $0.copy() as! InspectedAttribute }
            return newSection
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(identifier, forKey: "identifier")
            aCoder.encode(attributes, forKey: "attributes")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            identifier = aDecoder.decodeObject(forKey: "identifier") as? String
            attributes = aDecoder.decodeObject(forKey: "attributes") as? [InspectedAttribute]
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        @objc(isUserCustom)
        public func isUserCustom() -> Bool {
            stringsEqual(identifier, LookinAttrSec_UserCustom)
        }
    }

#endif
