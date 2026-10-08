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
        func mappedObjects(_ block: ((Any?) -> Any?)?) -> Set<AnyHashable>? {
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
            return bridgedSet(newSet)
        }

        @available(*, deprecated, renamed: "mappedObjects(_:)")
        func lookin_map(_ block: ((Any?) -> Any?)?) -> Set<AnyHashable>? {
            mappedObjects(block)
        }

        @objc(lookin_firstFiltered:)
        func firstFiltered(_ block: ((Any?) -> Bool)?) -> Any? {
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

        @available(*, deprecated, renamed: "firstFiltered(_:)")
        func lookin_firstFiltered(_ block: ((Any?) -> Bool)?) -> Any? {
            firstFiltered(block)
        }

        @objc(lookin_filter:)
        func filteredObjects(_ block: ((Any?) -> Bool)?) -> Set<AnyHashable>? {
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
            return bridgedSet(mSet)
        }

        @available(*, deprecated, renamed: "filteredObjects(_:)")
        func lookin_filter(_ block: ((Any?) -> Bool)?) -> Set<AnyHashable>? {
            filteredObjects(block)
        }

        @objc(lookin_any:)
        func anyObjectPasses(_ block: ((Any?) -> Bool)?) -> Bool {
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

        @available(*, deprecated, renamed: "anyObjectPasses(_:)")
        func lookin_any(_ block: ((Any?) -> Bool)?) -> Bool {
            anyObjectPasses(block)
        }
    }

    /// An immutable copy of `set`, handed to Objective-C without copying its
    /// elements: bridging an immutable NSSet to `Set` and back returns the same
    /// NSSet.
    private func bridgedSet(_ set: NSSet) -> Set<AnyHashable> {
        set.copy() as! Set<AnyHashable>
    }

#endif
