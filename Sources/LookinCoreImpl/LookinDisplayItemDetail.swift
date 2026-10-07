//
//  LookinDisplayItemDetail.swift
//  Lookin
//
//  Was LookinDisplayItemDetail.m: the 203 reply. The coding keys, the
//  screenshots-as-data encoding and the conditional subitems key are pinned by
//  Tests/WireFormatGolden.
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

    @objc(LookinDisplayItemDetail)
    public class LookinDisplayItemDetail: NSObject, NSCoding, NSSecureCoding {
        @objc(displayItemOid)
        public var displayItemOid: UInt = 0
        @objc(groupScreenshot)
        public var groupScreenshot: LookinImage!
        @objc(soloScreenshot)
        public var soloScreenshot: LookinImage!
        @objc(frameValue)
        public var frameValue: NSValue!
        @objc(boundsValue)
        public var boundsValue: NSValue!
        @objc(hiddenValue)
        public var hiddenValue: NSNumber!
        @objc(alphaValue)
        public var alphaValue: NSNumber!
        @objc(customDisplayTitle)
        public var customDisplayTitle: String!
        @objc(danceUISource)
        public var danceUISource: String!
        @objc(attributesGroupList)
        public var attributesGroupList: [LookinAttributesGroup]!
        @objc(customAttrGroupList)
        public var customAttrGroupList: [LookinAttributesGroup]!
        @objc(subitems)
        public var subitems: [LookinDisplayItem]!
        @objc(failureCode)
        public var failureCode: Int = 0

        override public init() {
            super.init()
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(NSNumber(value: displayItemOid), forKey: "displayItemOid")
            aCoder.encode(lookinScreenshotData(groupScreenshot), forKey: "groupScreenshot")
            aCoder.encode(lookinScreenshotData(soloScreenshot), forKey: "soloScreenshot")
            aCoder.encode(frameValue, forKey: "frameValue")
            aCoder.encode(boundsValue, forKey: "boundsValue")
            aCoder.encode(hiddenValue, forKey: "hiddenValue")
            aCoder.encode(alphaValue, forKey: "alphaValue")
            aCoder.encode(attributesGroupList, forKey: "attributesGroupList")
            aCoder.encode(customAttrGroupList, forKey: "customAttrGroupList")
            aCoder.encode(customDisplayTitle, forKey: "customDisplayTitle")
            aCoder.encode(danceUISource, forKey: "danceUISource")
            aCoder.encode(failureCode, forKey: "failureCode")
            if let subitems {
                aCoder.encode(subitems, forKey: "subitems")
            }
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            displayItemOid = (aDecoder.decodeObject(forKey: "displayItemOid") as? NSNumber)?.uintValue ?? 0
            groupScreenshot = (aDecoder.decodeObject(forKey: "groupScreenshot") as? Data).flatMap { LookinImage(data: $0) }
            soloScreenshot = (aDecoder.decodeObject(forKey: "soloScreenshot") as? Data).flatMap { LookinImage(data: $0) }
            frameValue = aDecoder.decodeObject(forKey: "frameValue") as? NSValue
            boundsValue = aDecoder.decodeObject(forKey: "boundsValue") as? NSValue
            hiddenValue = aDecoder.decodeObject(forKey: "hiddenValue") as? NSNumber
            alphaValue = aDecoder.decodeObject(forKey: "alphaValue") as? NSNumber
            attributesGroupList = aDecoder.decodeObject(forKey: "attributesGroupList") as? [LookinAttributesGroup]
            customAttrGroupList = aDecoder.decodeObject(forKey: "customAttrGroupList") as? [LookinAttributesGroup]
            customDisplayTitle = aDecoder.decodeObject(forKey: "customDisplayTitle") as? String
            danceUISource = aDecoder.decodeObject(forKey: "danceUISource") as? String

            if aDecoder.containsValue(forKey: "failureCode") {
                failureCode = aDecoder.decodeInteger(forKey: "failureCode")
            } else {
                failureCode = 0
            }

            if aDecoder.containsValue(forKey: "subitems") {
                subitems = aDecoder.decodeObject(forKey: "subitems") as? [LookinDisplayItem]
            }
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }
    }

#endif
