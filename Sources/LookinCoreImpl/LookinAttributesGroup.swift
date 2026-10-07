//
//  LookinAttributesGroup.swift
//  Lookin
//
//  Was LookinAttributesGroup.m. The coding keys are pinned by
//  Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinAttributesGroup)
    public class LookinAttributesGroup: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(userCustomTitle)
        public var userCustomTitle: String!
        @objc(identifier)
        public var identifier: String!
        @objc(attrSections)
        public var attrSections: [LookinAttributesSection]!
        @objc(isSwiftUIGroup)
        public var isSwiftUIGroup: Bool = false

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newGroup = LookinAttributesGroup()
            newGroup.userCustomTitle = userCustomTitle
            newGroup.identifier = identifier
            newGroup.attrSections = attrSections?.map { $0.copy() as! LookinAttributesSection }
            newGroup.isSwiftUIGroup = isSwiftUIGroup
            return newGroup
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(userCustomTitle, forKey: "userCustomTitle")
            aCoder.encode(identifier, forKey: "identifier")
            aCoder.encode(attrSections, forKey: "attrSections")
            aCoder.encode(isSwiftUIGroup, forKey: "isSwiftUIGroup")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            userCustomTitle = aDecoder.decodeObject(forKey: "userCustomTitle") as? String
            identifier = aDecoder.decodeObject(forKey: "identifier") as? String
            attrSections = aDecoder.decodeObject(forKey: "attrSections") as? [LookinAttributesSection]
            isSwiftUIGroup = aDecoder.decodeBool(forKey: "isSwiftUIGroup")
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        // MARK: Equality

        override open var hash: Int {
            lookinStringHash(uniqueKey())
        }

        override open func isEqual(_ object: Any?) -> Bool {
            if let object = object as? NSObject, object === self {
                return true
            }
            guard let targetObject = object as? LookinAttributesGroup else {
                return false
            }
            if !lookinStringsEqual(identifier, targetObject.identifier) {
                return false
            }
            if lookinStringsEqual(identifier, LookinAttrGroup_UserCustom) {
                return lookinStringsEqual(userCustomTitle, targetObject.userCustomTitle)
            }
            return true
        }

        @objc(uniqueKey)
        public func uniqueKey() -> String! {
            if lookinStringsEqual(identifier, LookinAttrGroup_UserCustom) {
                return userCustomTitle
            }
            return identifier
        }

        @objc(isUserCustom)
        public func isUserCustom() -> Bool {
            lookinStringsEqual(identifier, LookinAttrGroup_UserCustom)
        }

        @objc(groupsByKeepingFirstGroupForEachUniqueKey:)
        public class func groupsByKeepingFirstGroup(forEachUniqueKey groups: [LookinAttributesGroup]?) -> [LookinAttributesGroup]! {
            // NSMutableSet compares through -isEqual: / -hash, like the original.
            let seenUniqueKeys = NSMutableSet()
            var deduplicatedGroups: [LookinAttributesGroup] = []
            for group in groups ?? [] {
                if let uniqueKey = group.uniqueKey() {
                    if seenUniqueKeys.contains(uniqueKey) {
                        continue
                    }
                    seenUniqueKeys.add(uniqueKey)
                }
                deduplicatedGroups.append(group)
            }
            return deduplicatedGroups
        }
    }

#endif
