//
//  AttributesGroup.swift
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
    public class AttributesGroup: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(userCustomTitle)
        public var userCustomTitle: String?
        public var identifier: Identifier?
        /// `identifier` as Objective-C, KVC and the archive see it.
        @objc(identifier)
        public var rawIdentifier: String? {
            get { identifier?.rawValue }
            set { identifier = newValue.map(Identifier.init(rawValue:)) }
        }
        @objc(attrSections)
        public var attrSections: [AttributesSection]?
        @objc(isSwiftUIGroup)
        public var isSwiftUIGroup: Bool = false

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newGroup = AttributesGroup()
            newGroup.userCustomTitle = userCustomTitle
            newGroup.identifier = identifier
            newGroup.attrSections = attrSections?.map { $0.copy() as! AttributesSection }
            newGroup.isSwiftUIGroup = isSwiftUIGroup
            return newGroup
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(userCustomTitle, forKey: "userCustomTitle")
            aCoder.encode(rawIdentifier, forKey: "identifier")
            aCoder.encode(attrSections, forKey: "attrSections")
            aCoder.encode(isSwiftUIGroup, forKey: "isSwiftUIGroup")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            userCustomTitle = aDecoder.decodeObject(forKey: "userCustomTitle") as? String
            rawIdentifier = aDecoder.decodeObject(forKey: "identifier") as? String
            attrSections = aDecoder.decodeObject(forKey: "attrSections") as? [AttributesSection]
            isSwiftUIGroup = aDecoder.decodeBool(forKey: "isSwiftUIGroup")
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        // MARK: Equality

        override open var hash: Int {
            stringHash(uniqueKey())
        }

        override open func isEqual(_ object: Any?) -> Bool {
            if let object = object as? NSObject, object === self {
                return true
            }
            guard let targetObject = object as? AttributesGroup else {
                return false
            }
            if !stringsEqual(rawIdentifier, targetObject.rawIdentifier) {
                return false
            }
            if identifier == .userCustom {
                return stringsEqual(userCustomTitle, targetObject.userCustomTitle)
            }
            return true
        }

        @objc(uniqueKey)
        public func uniqueKey() -> String? {
            if identifier == .userCustom {
                return userCustomTitle
            }
            return rawIdentifier
        }

        @objc(isUserCustom)
        public func isUserCustom() -> Bool {
            identifier == .userCustom
        }

        @objc(groupsByKeepingFirstGroupForEachUniqueKey:)
        public class func groupsByKeepingFirstGroup(forEachUniqueKey groups: [AttributesGroup]?) -> [AttributesGroup] {
            // NSMutableSet compares through -isEqual: / -hash, like the original.
            let seenUniqueKeys = NSMutableSet()
            var deduplicatedGroups: [AttributesGroup] = []
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
