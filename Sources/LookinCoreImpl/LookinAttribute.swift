//
//  LookinAttribute.swift
//  qmuidemo
//
//  Was LookinAttribute.m. The
//  coding keys and value encodings are pinned by Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinAttribute)
    public class LookinAttribute: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(identifier)
        public var identifier: String!
        @objc(displayTitle)
        public var displayTitle: String!
        @objc(attrType)
        public var attrType: LookinAttrType = .none
        @objc(value)
        public var value: Any!
        @objc(extraValue)
        public var extraValue: Any!
        @objc(customSetterID)
        public var customSetterID: String!
        @objc(targetDisplayItem)
        public weak var targetDisplayItem: LookinDisplayItem?

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newAttr = LookinAttribute()
            newAttr.identifier = identifier
            newAttr.displayTitle = displayTitle
            newAttr.value = value
            newAttr.attrType = attrType
            newAttr.extraValue = extraValue
            newAttr.customSetterID = customSetterID
            return newAttr
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(displayTitle, forKey: "displayTitle")
            aCoder.encode(identifier, forKey: "identifier")
            aCoder.encode(attrType.rawValue, forKey: "attrType")
            aCoder.encode(value, forKey: "value")
            aCoder.encode(extraValue, forKey: "extraValue")
            aCoder.encode(customSetterID, forKey: "customSetterID")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            displayTitle = aDecoder.decodeObject(forKey: "displayTitle") as? String
            identifier = aDecoder.decodeObject(forKey: "identifier") as? String
            attrType = LookinAttrType(rawValue: aDecoder.decodeInteger(forKey: "attrType")) ?? .none
            value = aDecoder.decodeObject(forKey: "value")
            extraValue = aDecoder.decodeObject(forKey: "extraValue")
            customSetterID = aDecoder.decodeObject(forKey: "customSetterID") as? String
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        @objc(isUserCustom)
        public func isUserCustom() -> Bool {
            lookinStringsEqual(identifier, LookinAttr_UserCustom)
        }
    }

#endif
