//
//  LookinConnectionResponseAttachment.swift
//  Lookin
//
//  Was LookinConnectionResponseAttachment.m. Every reply travels in one of these;
//  the coding keys and scalar encodings are pinned by Tests/WireFormatGolden
//  (Response-* fixtures and LivePayloadTests).
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinConnectionResponseAttachment)
    public class LookinConnectionResponseAttachment: LookinConnectionAttachment {
        @objc(lookinServerVersion)
        public var lookinServerVersion: Int32 = 0
        @objc(error)
        public var error: (any Error)!
        @objc(appIsInBackground)
        public var appIsInBackground: Bool = false
        @objc(dataTotalCount)
        public var dataTotalCount: UInt = 0
        @objc(currentDataCount)
        public var currentDataCount: UInt = 0

        /// `+attachmentWithError:`. An Objective-C factory must be a class
        /// method here: implemented as a Swift initializer it compiles but
        /// registers no class method.
        @objc(attachmentWithError:)
        public class func attachment(error: (any Error)?) -> Self! {
            let attachment = unsafeDowncast((self as NSObject.Type).init(), to: self)
            attachment.error = error
            return attachment
        }

        override public init() {
            super.init()
            lookinServerVersion = Int32(LOOKIN_SERVER_VERSION)
            dataTotalCount = 0
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        override public func encode(with aCoder: NSCoder) {
            super.encode(with: aCoder)
            aCoder.encodeCInt(lookinServerVersion, forKey: "lookinServerVersion")
            aCoder.encode(error, forKey: "error")
            aCoder.encode(NSNumber(value: dataTotalCount), forKey: "dataTotalCount")
            aCoder.encode(NSNumber(value: currentDataCount), forKey: "currentDataCount")
            aCoder.encode(appIsInBackground, forKey: "appIsInBackground")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            lookinServerVersion = aDecoder.decodeCInt(forKey: "lookinServerVersion")
            error = aDecoder.decodeObject(forKey: "error") as? NSError
            dataTotalCount = (aDecoder.decodeObject(forKey: "dataTotalCount") as? NSNumber)?.uintValue ?? 0
            currentDataCount = (aDecoder.decodeObject(forKey: "currentDataCount") as? NSNumber)?.uintValue ?? 0
            appIsInBackground = aDecoder.decodeBool(forKey: "appIsInBackground")
        }

        override public class var supportsSecureCoding: Bool {
            true
        }
    }

#endif
