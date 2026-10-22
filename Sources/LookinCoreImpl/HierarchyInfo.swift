//
//  HierarchyInfo.swift
//  WeRead
//
//  Was LookinHierarchyInfo.m:
//  the 202 reply and the root of a .lookin document's hierarchy. The coding
//  keys are pinned by Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    private let displayItemsCodingKey = "1"
    private let appInfoCodingKey = "2"
    private let colorAliasCodingKey = "3"
    private let collapsedClassListCodingKey = "4"

    /// `+[LKS_HierarchyDisplayItemsMaker itemsWithScreenshots:attrList:lowImageQuality:readCustomInfo:saveCustomSetter:]`.
    /// LookinCore does not link against the server, so the maker is looked up
    /// and called through the runtime; without it (the host) the list is empty.
    private func makeDisplayItems(screenshots hasScreenshots: Bool, attrList hasAttrList: Bool, lowImageQuality lowQuality: Bool, readCustomInfo: Bool, saveCustomSetter: Bool) -> [DisplayItem] {
        let selector = NSSelectorFromString("itemsWithScreenshots:attrList:lowImageQuality:readCustomInfo:saveCustomSetter:")
        guard let makerClass = NSClassFromString("LKS_HierarchyDisplayItemsMaker"), (makerClass as AnyObject).responds(to: selector) else {
            return []
        }
        let arguments = [hasScreenshots, hasAttrList, lowQuality, readCustomInfo, saveCustomSetter].map { NSNumber(value: $0) }
        let items = LookinInvoke(makerClass, selector, arguments, nil)
        return (items as? [DisplayItem]) ?? []
    }

    @objc(LookinHierarchyInfo)
    public class HierarchyInfo: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(displayItems)
        public var displayItems: [DisplayItem]?
        @objc(colorAlias)
        public var colorAlias: [String: Any]?
        @objc(collapsedClassList)
        public var collapsedClassList: [String]?
        @objc(appInfo)
        public var appInfo: InspectedAppInfo?
        @objc(serverVersion)
        public var serverVersion: Int32 = 0

        /// `+staticInfoWithLookinVersion:`. `version` is nil for clients older
        /// than 1.0.4. An Objective-C factory must be a class method here.
        @objc(staticInfoWithLookinVersion:)
        public class func staticInfo(withLookinVersion version: String?) -> Self {
            var readCustomInfo = false
            // Clients support customInfo from 1.0.4 on.
            if let version, (version as NSString).numericOSVersion() >= 10004 {
                readCustomInfo = true
            }

            let info = unsafeDowncast((self as NSObject.Type).init(), to: self)
            info.serverVersion = Int32(LOOKIN_SERVER_VERSION)
            info.displayItems = makeDisplayItems(screenshots: false, attrList: false, lowImageQuality: false, readCustomInfo: readCustomInfo, saveCustomSetter: true)
            info.appInfo = InspectedAppInfo.currentInfo(withScreenshot: false, icon: true, localIdentifiers: nil)
            info.collapsedClassList = []
            info.colorAlias = [:]
            return info
        }

        /// `+exportedInfo`.
        @objc(exportedInfo)
        public class func exported() -> Self {
            let info = unsafeDowncast((self as NSObject.Type).init(), to: self)
            info.serverVersion = Int32(LOOKIN_SERVER_VERSION)
            info.displayItems = makeDisplayItems(screenshots: true, attrList: true, lowImageQuality: true, readCustomInfo: true, saveCustomSetter: false)
            info.appInfo = InspectedAppInfo.currentInfo(withScreenshot: false, icon: true, localIdentifiers: nil)
            info.collapsedClassList = []
            info.colorAlias = [:]
            return info
        }

        override public init() {
            super.init()
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(displayItems, forKey: displayItemsCodingKey)
            aCoder.encode(colorAlias, forKey: colorAliasCodingKey)
            aCoder.encode(collapsedClassList, forKey: collapsedClassListCodingKey)
            aCoder.encode(appInfo, forKey: appInfoCodingKey)
            aCoder.encodeCInt(serverVersion, forKey: "serverVersion")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            displayItems = aDecoder.decodeObject(forKey: displayItemsCodingKey) as? [DisplayItem]
            colorAlias = aDecoder.decodeObject(forKey: colorAliasCodingKey) as? [String: Any]
            collapsedClassList = aDecoder.decodeObject(forKey: collapsedClassListCodingKey) as? [String]
            appInfo = aDecoder.decodeObject(forKey: appInfoCodingKey) as? InspectedAppInfo
            serverVersion = aDecoder.decodeCInt(forKey: "serverVersion")
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newAppInfo = HierarchyInfo()
            newAppInfo.serverVersion = serverVersion
            newAppInfo.appInfo = appInfo?.copy() as? InspectedAppInfo
            newAppInfo.collapsedClassList = collapsedClassList
            newAppInfo.colorAlias = colorAlias
            newAppInfo.displayItems = displayItems?.map { $0.copy() as! DisplayItem }
            return newAppInfo
        }
    }

#endif
