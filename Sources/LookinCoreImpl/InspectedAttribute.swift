//
//  InspectedAttribute.swift
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
    public class InspectedAttribute: NSObject, NSCoding, NSSecureCoding, NSCopying {
        public var identifier: Identifier?
        /// `identifier` as Objective-C, KVC and the archive see it.
        @objc(identifier)
        public var rawIdentifier: String? {
            get { identifier?.rawValue }
            set { identifier = newValue.map(Identifier.init(rawValue:)) }
        }
        @objc(displayTitle)
        public var displayTitle: String?
        @objc(attrType)
        public var attrType: InspectedAttribute.ValueType = .none
        @objc(value)
        public var value: Any?
        @objc(extraValue)
        public var extraValue: Any?
        @objc(customSetterID)
        public var customSetterID: String?
        @objc(targetDisplayItem)
        public weak var targetDisplayItem: DisplayItem?

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newAttr = InspectedAttribute()
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
            aCoder.encode(rawIdentifier, forKey: "identifier")
            aCoder.encode(attrType.rawValue, forKey: "attrType")
            aCoder.encode(value, forKey: "value")
            aCoder.encode(extraValue, forKey: "extraValue")
            aCoder.encode(customSetterID, forKey: "customSetterID")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            displayTitle = aDecoder.decodeObject(forKey: "displayTitle") as? String
            rawIdentifier = aDecoder.decodeObject(forKey: "identifier") as? String
            attrType = InspectedAttribute.ValueType(rawValue: aDecoder.decodeInteger(forKey: "attrType")) ?? .none
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
            identifier == .userCustom
        }
    }

#endif
