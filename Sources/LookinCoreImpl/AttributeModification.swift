//
//  AttributeModification.swift
//  Lookin
//
//  Was LookinAttributeModification.m. The coding keys and value encodings are
//  pinned by Tests/WireFormatGolden (the 204 request).
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinAttributeModification)
    public class AttributeModification: NSObject, NSCoding, NSSecureCoding {
        @objc(targetOid)
        public var targetOid: UInt = 0
        @objc(setterSelector)
        public var setterSelector: Selector?
        /// Not archived.
        @objc(getterSelector)
        public var getterSelector: Selector?
        @objc(attrType)
        public var attrType: LookinAttrType = .none
        @objc(value)
        public var value: Any?
        @objc(clientReadableVersion)
        public var clientReadableVersion: String?

        override public init() {
            super.init()
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(NSNumber(value: targetOid), forKey: "targetOid")
            // NSStringFromSelector(NULL) is nil.
            aCoder.encode(setterSelector.map { NSStringFromSelector($0) }, forKey: "setterSelector")
            aCoder.encode(attrType.rawValue, forKey: "attrType")
            aCoder.encode(value, forKey: "value")
            aCoder.encode(clientReadableVersion, forKey: "clientReadableVersion")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            targetOid = (aDecoder.decodeObject(forKey: "targetOid") as? NSNumber)?.uintValue ?? 0
            // NSSelectorFromString(nil) is NULL.
            setterSelector = (aDecoder.decodeObject(forKey: "setterSelector") as? String).map { NSSelectorFromString($0) }
            attrType = LookinAttrType(rawValue: aDecoder.decodeInteger(forKey: "attrType")) ?? .none
            value = aDecoder.decodeObject(forKey: "value")
            clientReadableVersion = aDecoder.decodeObject(forKey: "clientReadableVersion") as? String
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }
    }

#endif
