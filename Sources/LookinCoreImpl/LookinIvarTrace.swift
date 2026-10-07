//
//  LookinIvarTrace.swift
//  Lookin
//
//  Was LookinIvarTrace.m. The exported LookinIvarTraceRelationValue_Self stays in
//  LookinServerBase/LookinIvarTraceConstants.m. The coding keys are pinned by
//  Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
        import LookinServerBase
    #endif

    @objc(LookinIvarTrace)
    public class LookinIvarTrace: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(relation)
        public var relation: String?
        @objc(hostClassName)
        public var hostClassName: String?
        @objc(ivarName)
        public var ivarName: String?
        @objc(hostObject)
        public weak var hostObject: AnyObject?

        override public init() {
            super.init()
        }

        // MARK: Equality

        override open var hash: Int {
            lookinStringHash(hostClassName) ^ lookinStringHash(ivarName)
        }

        override open func isEqual(_ object: Any?) -> Bool {
            if let object = object as? NSObject, object === self {
                return true
            }
            guard let compared = object as? LookinIvarTrace else {
                return false
            }
            return lookinStringsEqual(hostClassName, compared.hostClassName) && lookinStringsEqual(ivarName, compared.ivarName)
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newTrace = LookinIvarTrace()
            newTrace.relation = relation
            newTrace.hostClassName = hostClassName
            newTrace.ivarName = ivarName
            return newTrace
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(relation, forKey: "relation")
            aCoder.encode(hostClassName, forKey: "hostClassName")
            aCoder.encode(ivarName, forKey: "ivarName")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            relation = aDecoder.decodeObject(forKey: "relation") as? String
            hostClassName = aDecoder.decodeObject(forKey: "hostClassName") as? String
            ivarName = aDecoder.decodeObject(forKey: "ivarName") as? String
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }
    }

#endif
