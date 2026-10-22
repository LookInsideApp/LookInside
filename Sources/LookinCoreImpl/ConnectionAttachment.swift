//
//  ConnectionAttachment.swift
//  Lookin
//
//  Was LookinConnectionAttachment.m. Every request body travels in one of these;
//  the coding keys "0" / "1" are pinned by Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    private let Key_Data = "0"
    private let Key_DataType = "1"

    @objc(LookinConnectionAttachment)
    public class ConnectionAttachment: NSObject, NSCoding, NSSecureCoding {
        @objc(dataType)
        public var dataType: LookinCodingValueType = .unknown
        @objc(data)
        public var data: Any?

        override public init() {
            super.init()
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode((data as? NSObject)?.encodedObject(with: dataType), forKey: Key_Data)
            aCoder.encode(dataType.rawValue, forKey: Key_DataType)
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            dataType = LookinCodingValueType(rawValue: aDecoder.decodeInteger(forKey: Key_DataType)) ?? .unknown
            data = (aDecoder.decodeObject(forKey: Key_Data) as? NSObject)?.decodedObject(with: dataType)
        }

        public class var supportsSecureCoding: Bool {
            true
        }
    }

#endif
