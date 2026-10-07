//
//  NSSet+Lookin.swift
//  LookinCore
//
//  Was NSSet+Lookin.m. The results
//  are built as Foundation sets and handed back as-is.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    public extension NSSet {
        @objc(lookin_map:)
        func lookin_map(_ block: ((Any?) -> Any?)?) -> Set<AnyHashable>! {
            guard let block else {
                assertionFailure("")
                return nil
            }
            let newSet = NSMutableSet(capacity: count)
            enumerateObjects { obj, _ in
                if let newObj = block(obj) {
                    newSet.add(newObj)
                }
            }
            return lookinBridgedSet(newSet)
        }

        @objc(lookin_firstFiltered:)
        func lookin_firstFiltered(_ block: ((Any?) -> Bool)?) -> Any! {
            guard let block else {
                assertionFailure("")
                return nil
            }
            var targetObj: Any?
            enumerateObjects { obj, stop in
                if block(obj) {
                    targetObj = obj
                    stop.pointee = true
                }
            }
            return targetObj
        }

        @objc(lookin_filter:)
        func lookin_filter(_ block: ((Any?) -> Bool)?) -> Set<AnyHashable>! {
            guard let block else {
                assertionFailure("")
                return nil
            }
            let mSet = NSMutableSet()
            enumerateObjects { obj, _ in
                if block(obj) {
                    mSet.add(obj)
                }
            }
            return lookinBridgedSet(mSet)
        }

        @objc(lookin_any:)
        func lookin_any(_ block: ((Any?) -> Bool)?) -> Bool {
            guard let block else {
                assertionFailure("")
                return false
            }
            var boolValue = false
            enumerateObjects { obj, stop in
                if block(obj) {
                    boolValue = true
                    stop.pointee = true
                }
            }
            return boolValue
        }
    }

    /// An immutable copy of `set`, handed to Objective-C without copying its
    /// elements: bridging an immutable NSSet to `Set` and back returns the same
    /// NSSet.
    private func lookinBridgedSet(_ set: NSSet) -> Set<AnyHashable> {
        set.copy() as! Set<AnyHashable>
    }

#endif
