//
//  CustomDisplayItemInfo.swift
//  LookinServer
//
//  Was LookinCustomDisplayItemInfo.m. The coding keys are pinned by
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

    @objc(LookinCustomDisplayItemInfo)
    public class CustomDisplayItemInfo: NSObject, NSCoding, NSSecureCoding, NSCopying {
        @objc(frameInWindow)
        public var frameInWindow: NSValue?
        @objc(title)
        public var title: String?
        @objc(subtitle)
        public var subtitle: String?
        @objc(danceuiSource)
        public var danceuiSource: String?
        @objc(isSwiftUI)
        public var isSwiftUI: Bool = false
        @objc(swiftUIDisplayItemID)
        public var swiftUIDisplayItemID: String?
        /// The oid a detail request (203) uses for this node's screenshots and
        /// attribute groups, when the Server left them out of the hierarchy
        /// (`LookinParam_AsyncAcquisition`). Zero when the details came inline
        /// or the node has none. Archived only when non-zero.
        @objc(detailObjectOid)
        public var detailObjectOid: UInt = 0
        /// Whether the node has a layer of its own to screenshot, so a
        /// screenshot is worth asking for; false for layout-only nodes. The
        /// layer may still render nothing. Meaningful only with a
        /// `detailObjectOid`.
        @objc(detailHasScreenshots)
        public var detailHasScreenshots: Bool = false

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        @objc(copyWithZone:)
        public func copy(with _: NSZone? = nil) -> Any {
            let newInstance = CustomDisplayItemInfo()
            if let frameInWindow {
                #if canImport(UIKit)
                    newInstance.frameInWindow = NSValue(cgRect: frameInWindow.cgRectValue)
                #elseif os(macOS)
                    newInstance.frameInWindow = NSValue(rect: frameInWindow.rectValue)
                #endif
            }
            newInstance.title = title
            newInstance.subtitle = subtitle
            newInstance.danceuiSource = danceuiSource
            newInstance.isSwiftUI = isSwiftUI
            newInstance.swiftUIDisplayItemID = swiftUIDisplayItemID
            newInstance.detailObjectOid = detailObjectOid
            newInstance.detailHasScreenshots = detailHasScreenshots
            return newInstance
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(frameInWindow, forKey: "frameInWindow")
            aCoder.encode(title, forKey: "title")
            aCoder.encode(subtitle, forKey: "subtitle")
            aCoder.encode(danceuiSource, forKey: "danceuiSource")
            aCoder.encode(isSwiftUI, forKey: "isSwiftUI")
            aCoder.encode(swiftUIDisplayItemID, forKey: "swiftUIDisplayItemID")
            if detailObjectOid != 0 {
                aCoder.encode(Int(bitPattern: detailObjectOid), forKey: "detailObjectOid")
                aCoder.encode(detailHasScreenshots, forKey: "detailHasScreenshots")
            }
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            frameInWindow = aDecoder.decodeObject(of: NSValue.self, forKey: "frameInWindow")
            title = aDecoder.decodeObject(of: NSString.self, forKey: "title") as String?
            subtitle = aDecoder.decodeObject(of: NSString.self, forKey: "subtitle") as String?
            danceuiSource = aDecoder.decodeObject(of: NSString.self, forKey: "danceuiSource") as String?
            isSwiftUI = aDecoder.decodeBool(forKey: "isSwiftUI")
            swiftUIDisplayItemID = aDecoder.decodeObject(of: NSString.self, forKey: "swiftUIDisplayItemID") as String?
            detailObjectOid = UInt(bitPattern: aDecoder.decodeInteger(forKey: "detailObjectOid"))
            detailHasScreenshots = aDecoder.decodeBool(forKey: "detailHasScreenshots")
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        @objc(hasValidFrame)
        public func hasValidFrame() -> Bool {
            guard let frameInWindow else {
                return false
            }
            #if canImport(UIKit)
                return LookinIsUsableRect(frameInWindow.cgRectValue)
            #else
                return LookinIsUsableRect(frameInWindow.rectValue)
            #endif
        }
    }

#endif
