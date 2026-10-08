//
//  TwoTuple.swift
//  LookinCore
//
//  Was LookinTuple.m. The archived class names, coding keys and value types
//  are pinned by Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinTwoTuple)
    public class TwoTuple: NSObject, NSCoding, NSSecureCoding {
        @objc(first)
        public var first: NSObject?
        @objc(second)
        public var second: NSObject?

        // MARK: NSSecureCoding

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(first, forKey: "first")
            aCoder.encode(second, forKey: "second")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            first = aDecoder.decodeObject(forKey: "first") as? NSObject
            second = aDecoder.decodeObject(forKey: "second") as? NSObject
        }

        override public init() {
            super.init()
        }

        // MARK: Equality

        override open var hash: Int {
            (first?.hash ?? 0) ^ (second?.hash ?? 0)
        }

        override open func isEqual(_ object: Any?) -> Bool {
            if let object = object as? NSObject, object === self {
                return true
            }
            guard let compared = object as? TwoTuple else {
                return false
            }
            // [nil isEqual:] is NO in Objective-C, so two nil members never match.
            guard let first, let second else {
                return false
            }
            return first.isEqual(compared.first) && second.isEqual(compared.second)
        }
    }

    @objc(LookinStringTwoTuple)
    public class StringTwoTuple: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(first)
        public var first: String?
        @objc(second)
        public var second: String?

        /// `+tupleWithFirst:second:`. An Objective-C factory must be a class
        /// method here: implemented as a Swift initializer it compiles but
        /// registers no class method.
        @objc(tupleWithFirst:second:)
        public class func tuple(first firstString: String?, second secondString: String?) -> Self {
            let tuple = unsafeDowncast((self as NSObject.Type).init(), to: self)
            tuple.first = firstString
            tuple.second = secondString
            return tuple
        }

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let tuple = StringTwoTuple()
            tuple.first = first
            tuple.second = second
            return tuple
        }

        // MARK: NSSecureCoding

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(first, forKey: "first")
            aCoder.encode(second, forKey: "second")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            first = aDecoder.decodeObject(forKey: "first") as? String
            second = aDecoder.decodeObject(forKey: "second") as? String
        }
    }

    /// Swift spelling the Host has always used; the factory class method is
    /// `tuple(first:second:)`.
    public extension StringTwoTuple {
        convenience init(first firstString: String?, second secondString: String?) {
            self.init()
            first = firstString
            second = secondString
        }
    }

#endif
