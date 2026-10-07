//
//  LookinCustomAttrModification.swift
//  LookinShared
//
//  Was LookinCustomAttrModification.m. The coding keys and value encodings are
//  pinned by Tests/WireFormatGolden (the 214 request).
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinCustomAttrModification)
    public class LookinCustomAttrModification: NSObject, NSCoding, NSSecureCoding {
        @objc(attrType)
        public var attrType: LookinAttrType = .none
        @objc(customSetterID)
        public var customSetterID: String!
        @objc(value)
        public var value: Any!

        override public init() {
            super.init()
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(attrType.rawValue, forKey: "attrType")
            aCoder.encode(value, forKey: "value")
            aCoder.encode(customSetterID, forKey: "customSetterID")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            attrType = LookinAttrType(rawValue: aDecoder.decodeInteger(forKey: "attrType")) ?? .none
            value = aDecoder.decodeObject(forKey: "value")
            customSetterID = aDecoder.decodeObject(forKey: "customSetterID") as? String
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }
    }

#endif
