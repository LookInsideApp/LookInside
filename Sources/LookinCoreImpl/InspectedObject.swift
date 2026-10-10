//
//  InspectedObject.swift
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
    @objc private protocol ObjectServerBridge {
        @objc(lks_registerOid) func registerOid() -> UInt
        @objc(lks_classChainList) func classChainList() -> [String]?
        @objc(lks_specialTrace) var associatedSpecialTrace: String? { get }
        @objc(lks_ivarTraces) var instanceVariableTraces: [InstanceVariableTrace]? { get }
    }

    @objc(LookinObject)
    public class InspectedObject: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(oid)
        public var oid: UInt = 0
        @objc(memoryAddress)
        public var memoryAddress: String?
        @objc(classChainList)
        public var classChainList: [String]?
        @objc(specialTrace)
        public var specialTrace: String?
        @objc(ivarTraces)
        public var ivarTraces: [InstanceVariableTrace]?

        /// `+instanceWithObject:`. An Objective-C factory must be a class
        /// method here.
        @objc(instanceWithObject:)
        public class func instance(with object: NSObject?) -> Self {
            let inspectedObject = unsafeDowncast((self as NSObject.Type).init(), to: self)
            guard let object else {
                // Messages to nil answer 0 / nil; "%p" of nil is "0x0".
                inspectedObject.memoryAddress = "0x0"
                return inspectedObject
            }
            let bridged = unsafeBitCast(object, to: ObjectServerBridge.self)
            inspectedObject.oid = bridged.registerOid()

            inspectedObject.memoryAddress = String(format: "%p", OpaquePointer(Unmanaged.passUnretained(object).toOpaque()))
            inspectedObject.classChainList = bridged.classChainList()

            inspectedObject.specialTrace = bridged.associatedSpecialTrace
            inspectedObject.ivarTraces = bridged.instanceVariableTraces

            return inspectedObject
        }

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newObject = InspectedObject()
            newObject.oid = oid
            newObject.memoryAddress = memoryAddress
            newObject.classChainList = classChainList
            newObject.specialTrace = specialTrace
            newObject.ivarTraces = ivarTraces?.map { $0.copy() as! InstanceVariableTrace }
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
            ivarTraces = aDecoder.decodeObject(forKey: "ivarTraces") as? [InstanceVariableTrace]
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        @objc(rawClassName)
        public func rawClassName() -> String? {
            classChainList?.first
        }
    }

#endif
