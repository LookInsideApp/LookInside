//
//  LookinEventHandler.swift
//  Lookin
//
//  Was LookinEventHandler.m.
//  The coding keys and scalar encodings are pinned by Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinEventHandler)
    public class LookinEventHandler: NSObject, NSCoding, NSSecureCoding {
        @objc(handlerType)
        public var handlerType: LookinEventHandlerType = .targetAction
        @objc(eventName)
        public var eventName: String!
        @objc(targetActions)
        public var targetActions: [LookinStringTwoTuple]!
        @objc(inheritedRecognizerName)
        public var inheritedRecognizerName: String!
        @objc(gestureRecognizerIsEnabled)
        public var gestureRecognizerIsEnabled: Bool = false
        @objc(gestureRecognizerDelegator)
        public var gestureRecognizerDelegator: String!
        @objc(recognizerIvarTraces)
        public var recognizerIvarTraces: [String]!
        @objc(recognizerOid)
        public var recognizerOid: UInt64 = 0

        override public init() {
            super.init()
        }

        // MARK: NSCopying

        /// The class does not adopt NSCopying, but the original implemented
        /// -copyWithZone: (LookinDisplayItem copies its handlers with -copy).
        @objc(copyWithZone:)
        final func copy(with _: NSZone? = nil) -> Any {
            let newHandler = LookinEventHandler()
            newHandler.handlerType = handlerType
            newHandler.eventName = eventName
            newHandler.targetActions = targetActions?.map { $0.copy() as! LookinStringTwoTuple }
            newHandler.gestureRecognizerIsEnabled = gestureRecognizerIsEnabled
            newHandler.gestureRecognizerDelegator = gestureRecognizerDelegator
            newHandler.inheritedRecognizerName = inheritedRecognizerName
            newHandler.recognizerIvarTraces = recognizerIvarTraces
            newHandler.recognizerOid = recognizerOid
            return newHandler
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(handlerType.rawValue, forKey: "handlerType")
            aCoder.encode(gestureRecognizerIsEnabled, forKey: "gestureRecognizerIsEnabled")
            aCoder.encode(eventName, forKey: "eventName")
            aCoder.encode(gestureRecognizerDelegator, forKey: "gestureRecognizerDelegator")
            aCoder.encode(targetActions, forKey: "targetActions")
            aCoder.encode(inheritedRecognizerName, forKey: "inheritedRecognizerName")
            aCoder.encode(recognizerIvarTraces, forKey: "recognizerIvarTraces")
            aCoder.encode(NSNumber(value: recognizerOid), forKey: "recognizerOid")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            handlerType = LookinEventHandlerType(rawValue: aDecoder.decodeInteger(forKey: "handlerType")) ?? .targetAction
            gestureRecognizerIsEnabled = aDecoder.decodeBool(forKey: "gestureRecognizerIsEnabled")
            eventName = aDecoder.decodeObject(forKey: "eventName") as? String
            gestureRecognizerDelegator = aDecoder.decodeObject(forKey: "gestureRecognizerDelegator") as? String
            targetActions = aDecoder.decodeObject(forKey: "targetActions") as? [LookinStringTwoTuple]
            inheritedRecognizerName = aDecoder.decodeObject(forKey: "inheritedRecognizerName") as? String
            recognizerIvarTraces = aDecoder.decodeObject(forKey: "recognizerIvarTraces") as? [String]
            // The original read it back through -unsignedLongValue.
            recognizerOid = UInt64((aDecoder.decodeObject(forKey: "recognizerOid") as? NSNumber)?.uintValue ?? 0)
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }
    }

#endif
