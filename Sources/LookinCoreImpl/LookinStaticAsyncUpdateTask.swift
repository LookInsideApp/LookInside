//
//  LookinStaticAsyncUpdateTask.swift
//  Lookin
//
//  Was LookinStaticAsyncUpdateTask.m: the 203 request's tasks. The coding keys,
//  decode defaults and range check are pinned by Tests/WireFormatGolden.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinStaticAsyncUpdateTask)
    public class LookinStaticAsyncUpdateTask: NSObject, NSCoding, NSSecureCoding {
        @objc(oid)
        public var oid: UInt = 0
        @objc(taskType)
        public var taskType: LookinStaticAsyncUpdateTaskType = .noScreenshot
        @objc(attrRequest)
        public var attrRequest: LookinDetailUpdateTaskAttrRequest = .automatic
        @objc(needBasisVisualInfo)
        public var needBasisVisualInfo: Bool = false
        @objc(needSubitems)
        public var needSubitems: Bool = false
        @objc(clientReadableVersion)
        public var clientReadableVersion: String!
        /// Not archived.
        @objc(frameSize)
        public var frameSize: CGSize = .zero

        override public init() {
            super.init()
        }

        // MARK: NSSecureCoding

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(NSNumber(value: oid), forKey: "oid")
            aCoder.encode(taskType.rawValue, forKey: "taskType")
            aCoder.encode(clientReadableVersion, forKey: "clientReadableVersion")
            aCoder.encode(attrRequest.rawValue, forKey: "attrRequest")
            aCoder.encode(needBasisVisualInfo, forKey: "needBasisVisualInfo")
            aCoder.encode(needSubitems, forKey: "needSubitems")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            oid = (aDecoder.decodeObject(forKey: "oid") as? NSNumber)?.uintValue ?? 0
            taskType = LookinStaticAsyncUpdateTaskType(rawValue: aDecoder.decodeInteger(forKey: "taskType")) ?? .noScreenshot
            clientReadableVersion = aDecoder.decodeObject(forKey: "clientReadableVersion") as? String
            if aDecoder.containsValue(forKey: "attrRequest") {
                let value = aDecoder.decodeInteger(forKey: "attrRequest")
                if value >= LookinDetailUpdateTaskAttrRequest.automatic.rawValue, value <= LookinDetailUpdateTaskAttrRequest.notNeed.rawValue {
                    attrRequest = LookinDetailUpdateTaskAttrRequest(rawValue: value) ?? .automatic
                } else {
                    attrRequest = .automatic
                }
            } else {
                attrRequest = .automatic
            }

            if aDecoder.containsValue(forKey: "needBasisVisualInfo") {
                needBasisVisualInfo = aDecoder.decodeBool(forKey: "needBasisVisualInfo")
            } else {
                needBasisVisualInfo = false
            }

            if aDecoder.containsValue(forKey: "needSubitems") {
                needSubitems = aDecoder.decodeBool(forKey: "needSubitems")
            } else {
                needSubitems = false
            }
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }

        // MARK: Equality

        override open var hash: Int {
            Int(bitPattern: oid) ^ taskType.rawValue ^ attrRequest.rawValue ^ (needBasisVisualInfo ? 1 : 0) ^ (needSubitems ? 1 : 0)
        }

        override open func isEqual(_ object: Any?) -> Bool {
            if let object = object as? NSObject, object === self {
                return true
            }
            guard let targetTask = object as? LookinStaticAsyncUpdateTask else {
                return false
            }
            return oid == targetTask.oid
                && taskType == targetTask.taskType
                && attrRequest == targetTask.attrRequest
                && needBasisVisualInfo == targetTask.needBasisVisualInfo
                && needSubitems == targetTask.needSubitems
        }
    }

    @objc(LookinStaticAsyncUpdateTasksPackage)
    public class LookinStaticAsyncUpdateTasksPackage: NSObject, NSCoding, NSSecureCoding {
        @objc(tasks)
        public var tasks: [LookinStaticAsyncUpdateTask]!

        override public init() {
            super.init()
        }

        @objc(encodeWithCoder:)
        public func encode(with aCoder: NSCoder) {
            aCoder.encode(tasks, forKey: "tasks")
        }

        public required init?(coder aDecoder: NSCoder) {
            super.init()
            tasks = aDecoder.decodeObject(forKey: "tasks") as? [LookinStaticAsyncUpdateTask]
        }

        @objc(supportsSecureCoding)
        public class var supportsSecureCoding: Bool {
            true
        }
    }

#endif
