//
//  LookinObject.swift
//  Lookin
//
//  Was LookinObject.m. The coding
//  keys are pinned by Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
        import LookinServerBase
    #endif

    /// The LookinServer categories +instanceWithObject: reads. LookinCore does
    /// not link against the server, so they are sent dynamically, exactly as
    /// the original's forward declaration did: a missing method raises
    /// "unrecognized selector" as before.
    @objc private protocol LookinObjectServerBridge {
        func lks_registerOid() -> UInt
        func lks_classChainList() -> [String]?
        var lks_specialTrace: String? { get }
        var lks_ivarTraces: [LookinIvarTrace]? { get }
    }

    @objc(LookinObject)
    public class LookinObject: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(oid)
        public var oid: UInt = 0
        @objc(memoryAddress)
        public var memoryAddress: String!
        @objc(classChainList)
        public var classChainList: [String]!
        @objc(specialTrace)
        public var specialTrace: String!
        @objc(ivarTraces)
        public var ivarTraces: [LookinIvarTrace]!

        /// `+instanceWithObject:`. An Objective-C factory must be a class
        /// method here.
        @objc(instanceWithObject:)
        public class func instance(with object: NSObject?) -> Self! {
            let lookinObj = unsafeDowncast((self as NSObject.Type).init(), to: self)
            guard let object else {
                // Messages to nil answer 0 / nil; "%p" of nil is "0x0".
                lookinObj.memoryAddress = "0x0"
                return lookinObj
            }
            let bridged = unsafeBitCast(object, to: LookinObjectServerBridge.self)
            lookinObj.oid = bridged.lks_registerOid()

            lookinObj.memoryAddress = String(format: "%p", OpaquePointer(Unmanaged.passUnretained(object).toOpaque()))
            lookinObj.classChainList = bridged.lks_classChainList()

            lookinObj.specialTrace = bridged.lks_specialTrace
            lookinObj.ivarTraces = bridged.lks_ivarTraces

            return lookinObj
        }

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newObject = LookinObject()
            newObject.oid = oid
            newObject.memoryAddress = memoryAddress
            newObject.classChainList = classChainList
            newObject.specialTrace = specialTrace
            newObject.ivarTraces = ivarTraces?.map { $0.copy() as! LookinIvarTrace }
            return newObject
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(NSNumber(value: oid), forKey: "oid")
            aCoder.encode(memoryAddress, forKey: "memoryAddress")
            aCoder.encode(classChainList, forKey: "classChainList")
            aCoder.encode(specialTrace, forKey: "specialTrace")
            aCoder.encode(ivarTraces, forKey: "ivarTraces")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            oid = (aDecoder.decodeObject(forKey: "oid") as? NSNumber)?.uintValue ?? 0
            memoryAddress = aDecoder.decodeObject(forKey: "memoryAddress") as? String
            classChainList = aDecoder.decodeObject(forKey: "classChainList") as? [String]
            specialTrace = aDecoder.decodeObject(forKey: "specialTrace") as? String
            ivarTraces = aDecoder.decodeObject(forKey: "ivarTraces") as? [LookinIvarTrace]
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        @objc(rawClassName)
        public func rawClassName() -> String! {
            classChainList?.first
        }
    }

#endif
