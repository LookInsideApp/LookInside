//
//  LookinHierarchyInfo.swift
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

    private let LookinHierarchyInfoCodingKey_DisplayItems = "1"
    private let LookinHierarchyInfoCodingKey_AppInfo = "2"
    private let LookinHierarchyInfoCodingKey_ColorAlias = "3"
    private let LookinHierarchyInfoCodingKey_CollapsedClassList = "4"

    /// `+[LKS_HierarchyDisplayItemsMaker itemsWithScreenshots:attrList:lowImageQuality:readCustomInfo:saveCustomSetter:]`.
    /// LookinCore does not link against the server, so the maker is looked up
    /// and called through the runtime; without it (the host) the list is empty.
    private func lookinDisplayItems(screenshots hasScreenshots: Bool, attrList hasAttrList: Bool, lowImageQuality lowQuality: Bool, readCustomInfo: Bool, saveCustomSetter: Bool) -> [LookinDisplayItem] {
        let selector = NSSelectorFromString("itemsWithScreenshots:attrList:lowImageQuality:readCustomInfo:saveCustomSetter:")
        guard let makerClass = NSClassFromString("LKS_HierarchyDisplayItemsMaker"), (makerClass as AnyObject).responds(to: selector) else {
            return []
        }
        let arguments = [hasScreenshots, hasAttrList, lowQuality, readCustomInfo, saveCustomSetter].map { NSNumber(value: $0) }
        let items = LookinInvoke(makerClass, selector, arguments, nil)
        return (items as? [LookinDisplayItem]) ?? []
    }

    @objc(LookinHierarchyInfo)
    public class LookinHierarchyInfo: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(displayItems)
        public var displayItems: [LookinDisplayItem]!
        @objc(colorAlias)
        public var colorAlias: [String: Any]!
        @objc(collapsedClassList)
        public var collapsedClassList: [String]!
        @objc(appInfo)
        public var appInfo: LookinAppInfo!
        @objc(serverVersion)
        public var serverVersion: Int32 = 0

        /// `+staticInfoWithLookinVersion:`. `version` is nil for clients older
        /// than 1.0.4. An Objective-C factory must be a class method here.
        @objc(staticInfoWithLookinVersion:)
        public class func staticInfo(withLookinVersion version: String?) -> Self! {
            var readCustomInfo = false
            // Clients support customInfo from 1.0.4 on.
            if let version, (version as NSString).lookin_numbericOSVersion() >= 10004 {
                readCustomInfo = true
            }

            let info = unsafeDowncast((self as NSObject.Type).init(), to: self)
            info.serverVersion = Int32(LOOKIN_SERVER_VERSION)
            info.displayItems = lookinDisplayItems(screenshots: false, attrList: false, lowImageQuality: false, readCustomInfo: readCustomInfo, saveCustomSetter: true)
            info.appInfo = LookinAppInfo.currentInfo(withScreenshot: false, icon: true, localIdentifiers: nil)
            info.collapsedClassList = []
            info.colorAlias = [:]
            return info
        }

        /// `+exportedInfo`.
        @objc(exportedInfo)
        public class func exported() -> Self! {
            let info = unsafeDowncast((self as NSObject.Type).init(), to: self)
            info.serverVersion = Int32(LOOKIN_SERVER_VERSION)
            info.displayItems = lookinDisplayItems(screenshots: true, attrList: true, lowImageQuality: true, readCustomInfo: true, saveCustomSetter: false)
            info.appInfo = LookinAppInfo.currentInfo(withScreenshot: false, icon: true, localIdentifiers: nil)
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
            aCoder.encode(displayItems, forKey: LookinHierarchyInfoCodingKey_DisplayItems)
            aCoder.encode(colorAlias, forKey: LookinHierarchyInfoCodingKey_ColorAlias)
            aCoder.encode(collapsedClassList, forKey: LookinHierarchyInfoCodingKey_CollapsedClassList)
            aCoder.encode(appInfo, forKey: LookinHierarchyInfoCodingKey_AppInfo)
            aCoder.encodeCInt(serverVersion, forKey: "serverVersion")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            displayItems = aDecoder.decodeObject(forKey: LookinHierarchyInfoCodingKey_DisplayItems) as? [LookinDisplayItem]
            colorAlias = aDecoder.decodeObject(forKey: LookinHierarchyInfoCodingKey_ColorAlias) as? [String: Any]
            collapsedClassList = aDecoder.decodeObject(forKey: LookinHierarchyInfoCodingKey_CollapsedClassList) as? [String]
            appInfo = aDecoder.decodeObject(forKey: LookinHierarchyInfoCodingKey_AppInfo) as? LookinAppInfo
            serverVersion = aDecoder.decodeCInt(forKey: "serverVersion")
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newAppInfo = LookinHierarchyInfo()
            newAppInfo.serverVersion = serverVersion
            newAppInfo.appInfo = appInfo?.copy() as? LookinAppInfo
            newAppInfo.collapsedClassList = collapsedClassList
            newAppInfo.colorAlias = colorAlias
            newAppInfo.displayItems = displayItems?.map { $0.copy() as! LookinDisplayItem }
            return newAppInfo
        }
    }

#endif
