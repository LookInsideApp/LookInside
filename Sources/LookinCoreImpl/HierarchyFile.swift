//
//  HierarchyFile.swift
//  Lookin
//
//  Was LookinHierarchyFile.m,
//  the root object of a .lookin document. The coding keys are pinned by
//  Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinHierarchyFile)
    public class HierarchyFile: NSObject, NSCoding, NSSecureCoding {
        @objc(serverVersion)
        public var serverVersion: Int32 = 0
        @objc(hierarchyInfo)
        public var hierarchyInfo: HierarchyInfo?
        /// The screenshot dictionaries are kept as the Foundation objects they
        /// were set or decoded as. Bridging them through `[NSNumber: Data]`
        /// would turn the NSMutableData values a .lookin document holds into
        /// Swift Data, which archives inline instead of as NSMutableData
        /// objects; storing the NSDictionary re-archives a document unchanged.
        private var _soloScreenshots: NSDictionary?
        private var _groupScreenshots: NSDictionary?

        @objc(soloScreenshots)
        public var soloScreenshots: [NSNumber: Data]? {
            get { _soloScreenshots as? [NSNumber: Data] }
            set { _soloScreenshots = newValue.map { $0 as NSDictionary } }
        }

        @objc(groupScreenshots)
        public var groupScreenshots: [NSNumber: Data]? {
            get { _groupScreenshots as? [NSNumber: Data] }
            set { _groupScreenshots = newValue.map { $0 as NSDictionary } }
        }

        override public init() {
            super.init()
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encodeCInt(serverVersion, forKey: "serverVersion")
            aCoder.encode(hierarchyInfo, forKey: "hierarchyInfo")
            aCoder.encode(_soloScreenshots, forKey: "soloScreenshots")
            aCoder.encode(_groupScreenshots, forKey: "groupScreenshots")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            serverVersion = aDecoder.decodeCInt(forKey: "serverVersion")
            hierarchyInfo = aDecoder.decodeObject(forKey: "hierarchyInfo") as? HierarchyInfo
            _soloScreenshots = aDecoder.decodeObject(forKey: "soloScreenshots") as? NSDictionary
            _groupScreenshots = aDecoder.decodeObject(forKey: "groupScreenshots") as? NSDictionary
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        @objc(verifyHierarchyFile:)
        public class func verifyHierarchyFile(_ hierarchyFile: HierarchyFile?) -> (any Error)? {
            guard let hierarchyFile, hierarchyFile.isKind(of: HierarchyFile.self) else {
                return LookinErr_Inner
            }

            if hierarchyFile.serverVersion < LOOKIN_SUPPORTED_SERVER_MIN {
                // The document is too old. A missing serverVersion field means
                // version 6.
                let fileVersion = hierarchyFile.serverVersion != 0 ? hierarchyFile.serverVersion : 6
                let detail = String(format: NSLocalizedString("The document was created by a LookInside app with too old version. Current LookInside app version is %@, but the document version is %@.", comment: ""), NSNumber(value: LOOKIN_CLIENT_VERSION), NSNumber(value: fileVersion))
                return NSError(domain: LookinErrorDomain, code: Int(LookinErrCode_ServerVersionTooLow), userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to open the document.", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: detail,
                ])
            }

            if hierarchyFile.serverVersion > LOOKIN_SUPPORTED_SERVER_MAX {
                // The document is too new.
                let detail = String(format: NSLocalizedString("Current LookInside app is too old to open this document. Current LookInside app version is %@, but the document version is %@.", comment: ""), NSNumber(value: LOOKIN_CLIENT_VERSION), NSNumber(value: hierarchyFile.serverVersion))
                return NSError(domain: LookinErrorDomain, code: Int(LookinErrCode_ServerVersionTooHigh), userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Failed to open the document.", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey: detail,
                ])
            }

            return nil
        }
    }

#endif
