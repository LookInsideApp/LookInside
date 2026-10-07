//
//  LookinAutoLayoutConstraint.swift
//  Lookin
//
//  Was LookinAutoLayoutConstraint.m. The coding keys and scalar encodings are
//  pinned by Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif
    #if canImport(UIKit)
        import UIKit
    #elseif os(macOS)
        import AppKit
    #endif

    /// View endpoints have always had a node to land on; layout guide
    /// endpoints gained one when guides entered the hierarchy tree.
    private func LookinConstraintItemTypeIsJumpable(_ itemType: LookinConstraintItemType) -> Bool {
        itemType == .view || itemType == .layoutGuide
    }

    /// The asserts help find attributes private to the system; the original
    /// notes they should go before a release.
    private func lookinAssertUnknownAttribute(_ attribute: Int) {
        if attribute > 20, attribute < 32 {
            assertionFailure()
        }
        if attribute > 37 {
            assertionFailure()
        }
    }

    @objc(LookinAutoLayoutConstraint)
    public class LookinAutoLayoutConstraint: NSObject, NSCoding, NSSecureCoding {
        @objc(effective)
        public var effective: Bool = false
        @objc(active)
        public var active: Bool = false
        @objc(shouldBeArchived)
        public var shouldBeArchived: Bool = false
        @objc(firstItem)
        public var firstItem: LookinObject!
        @objc(firstItemType)
        public var firstItemType: LookinConstraintItemType = .unknown
        @objc(firstAttribute)
        public var firstAttribute: Int = 0 {
            didSet {
                lookinAssertUnknownAttribute(firstAttribute)
            }
        }

        @objc(relation)
        public var relation: NSLayoutConstraint.Relation = .equal
        @objc(secondItem)
        public var secondItem: LookinObject!
        @objc(secondItemType)
        public var secondItemType: LookinConstraintItemType = .unknown
        @objc(secondAttribute)
        public var secondAttribute: Int = 0 {
            didSet {
                lookinAssertUnknownAttribute(secondAttribute)
            }
        }

        @objc(multiplier)
        public var multiplier: CGFloat = 0
        @objc(constant)
        public var constant: CGFloat = 0
        @objc(priority)
        public var priority: CGFloat = 0
        @objc(identifier)
        public var identifier: String!
        @objc(constraintOid)
        public var constraintOid: UInt = 0

        /// `+instanceFromNSConstraint:isEffective:firstItemType:secondItemType:`.
        /// An Objective-C factory must be a class method here.
        @objc(instanceFromNSConstraint:isEffective:firstItemType:secondItemType:)
        public class func instance(fromNSConstraint constraint: NSLayoutConstraint?, isEffective: Bool, firstItemType: LookinConstraintItemType, secondItemType: LookinConstraintItemType) -> Self! {
            let instance = unsafeDowncast((self as NSObject.Type).init(), to: self)
            instance.effective = isEffective
            instance.active = constraint?.isActive ?? false
            instance.shouldBeArchived = constraint?.shouldBeArchived ?? false
            instance.firstItem = LookinObject.instance(with: constraint?.firstItem as? NSObject)
            instance.firstItemType = firstItemType
            instance.firstAttribute = constraint?.firstAttribute.rawValue ?? 0
            instance.relation = constraint?.relation ?? NSLayoutConstraint.Relation(rawValue: 0)!
            instance.secondItem = LookinObject.instance(with: constraint?.secondItem as? NSObject)
            instance.secondItemType = secondItemType
            instance.secondAttribute = constraint?.secondAttribute.rawValue ?? 0
            instance.multiplier = constraint?.multiplier ?? 0
            instance.constant = constraint?.constant ?? 0
            instance.priority = CGFloat(constraint?.priority.rawValue ?? 0)
            instance.identifier = constraint?.identifier
            return instance
        }

        override public init() {
            super.init()
        }

        // MARK: NSSecureCoding

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(effective, forKey: "effective")
            aCoder.encode(active, forKey: "active")
            aCoder.encode(shouldBeArchived, forKey: "shouldBeArchived")
            aCoder.encode(firstItem, forKey: "firstItem")
            aCoder.encode(firstItemType.rawValue, forKey: "firstItemType")
            aCoder.encode(firstAttribute, forKey: "firstAttribute")
            aCoder.encode(relation.rawValue, forKey: "relation")
            aCoder.encode(secondItem, forKey: "secondItem")
            aCoder.encode(secondItemType.rawValue, forKey: "secondItemType")
            aCoder.encode(secondAttribute, forKey: "secondAttribute")
            aCoder.encode(Double(multiplier), forKey: "multiplier")
            aCoder.encode(Double(constant), forKey: "constant")
            aCoder.encode(Double(priority), forKey: "priority")
            aCoder.encode(identifier, forKey: "identifier")
            aCoder.encode(Int(bitPattern: constraintOid), forKey: "constraintOid")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            effective = aDecoder.decodeBool(forKey: "effective")
            active = aDecoder.decodeBool(forKey: "active")
            shouldBeArchived = aDecoder.decodeBool(forKey: "shouldBeArchived")
            firstItem = aDecoder.decodeObject(forKey: "firstItem") as? LookinObject
            firstItemType = LookinConstraintItemType(rawValue: aDecoder.decodeInteger(forKey: "firstItemType")) ?? .unknown
            firstAttribute = aDecoder.decodeInteger(forKey: "firstAttribute")
            relation = NSLayoutConstraint.Relation(rawValue: aDecoder.decodeInteger(forKey: "relation")) ?? .equal
            secondItem = aDecoder.decodeObject(forKey: "secondItem") as? LookinObject
            secondItemType = LookinConstraintItemType(rawValue: aDecoder.decodeInteger(forKey: "secondItemType")) ?? .unknown
            secondAttribute = aDecoder.decodeInteger(forKey: "secondAttribute")
            multiplier = CGFloat(aDecoder.decodeDouble(forKey: "multiplier"))
            constant = CGFloat(aDecoder.decodeDouble(forKey: "constant"))
            priority = CGFloat(aDecoder.decodeDouble(forKey: "priority"))
            identifier = aDecoder.decodeObject(forKey: "identifier") as? String
            // Absent in old archives: decodeInteger returns 0, which is exactly
            // the "no identity" contract.
            constraintOid = UInt(bitPattern: aDecoder.decodeInteger(forKey: "constraintOid"))
        }

        @objc(jumpableItemObjectForEndpoint:)
        public func jumpableItemObject(for endpoint: LookinConstraintEndpoint) -> LookinObject! {
            switch endpoint {
            case .first:
                return LookinConstraintItemTypeIsJumpable(firstItemType) ? firstItem : nil
            case .second:
                return LookinConstraintItemTypeIsJumpable(secondItemType) ? secondItem : nil
            @unknown default:
                return nil
            }
        }
    }

#endif
