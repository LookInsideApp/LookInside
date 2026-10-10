//
//  NSArray+Lookin.swift
//  LookinCore
//
//  Was NSArray+Lookin.m. The
//  results are built as Foundation collections and handed back as-is, so the
//  Objective-C callers get the same NSArray contents as before.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    public extension NSArray {
        @objc(lookin_resizeWithCount:add:remove:doNext:)
        func resized(
            withCount count: UInt,
            add addBlock: ((UInt) -> Any?)?,
            remove removeBlock: ((UInt, Any?) -> Void)?,
            doNext doBlock: ((UInt, Any?) -> Void)?
        ) -> [Any] {
            let resultArray = NSMutableArray(capacity: Int(count))
            for i in 0 ..< count {
                if UInt(self.count) > i {
                    let obj = object(at: Int(i))
                    resultArray.add(obj)
                    doBlock?(i, obj)
                } else if let addBlock {
                    if let newObj = addBlock(i) {
                        resultArray.add(newObj)
                        doBlock?(i, newObj)
                    } else {
                        assertionFailure("")
                    }
                } else {
                    assertionFailure("")
                }
            }

            if let removeBlock, UInt(self.count) > count {
                for i in count ..< UInt(self.count) {
                    removeBlock(i, object(at: Int(i)))
                }
            }

            return bridgedArray(resultArray)
        }

        @available(*, deprecated, renamed: "resized(withCount:add:remove:doNext:)")
        func lookin_resize(
            withCount count: UInt,
            add addBlock: ((UInt) -> Any?)?,
            remove removeBlock: ((UInt, Any?) -> Void)?,
            doNext doBlock: ((UInt, Any?) -> Void)?
        ) -> [Any] {
            resized(withCount: count, add: addBlock, remove: removeBlock, doNext: doBlock)
        }

        @objc(lookin_arrayWithCount:block:)
        class func array(withCount count: UInt, block: ((UInt) -> Any?)?) -> [Any] {
            let array = NSMutableArray(capacity: Int(count))
            for i in 0 ..< count {
                // Calling a nil block crashed in Objective-C as well.
                if let obj = block!(i) {
                    array.add(obj)
                }
            }
            return bridgedArray(array)
        }

        @available(*, deprecated, renamed: "array(withCount:block:)")
        class func lookin_array(withCount count: UInt, block: ((UInt) -> Any?)?) -> [Any] {
            array(withCount: count, block: block)
        }

        @objc(lookin_hasIndex:)
        func hasIndex(_ index: Int) -> Bool {
            if index == NSNotFound || index < 0 {
                return false
            }
            return count > index
        }

        @available(*, deprecated, renamed: "hasIndex(_:)")
        func lookin_hasIndex(_ index: Int) -> Bool {
            hasIndex(index)
        }

        @objc(lookin_map:)
        func mappedObjects(_ block: ((UInt, Any?) -> Any?)?) -> [Any]? {
            guard let block else {
                assertionFailure("")
                return nil
            }
            let array = NSMutableArray(capacity: count)
            enumerateObjects { obj, idx, _ in
                if let newObj = block(UInt(idx), obj) {
                    array.add(newObj)
                }
            }
            return bridgedArray(array)
        }

        @available(*, deprecated, renamed: "mappedObjects(_:)")
        func lookin_map(_ block: ((UInt, Any?) -> Any?)?) -> [Any]? {
            mappedObjects(block)
        }

        @objc(lookin_filter:)
        func filteredObjects(_ block: ((Any?) -> Bool)?) -> [Any]? {
            guard let block else {
                assertionFailure("")
                return nil
            }
            let mArray = NSMutableArray()
            enumerateObjects { obj, _, _ in
                if block(obj) {
                    mArray.add(obj)
                }
            }
            return bridgedArray(mArray)
        }

        @available(*, deprecated, renamed: "filteredObjects(_:)")
        func lookin_filter(_ block: ((Any?) -> Bool)?) -> [Any]? {
            filteredObjects(block)
        }

        @objc(lookin_firstFiltered:)
        func firstFiltered(_ block: ((Any?) -> Bool)?) -> Any? {
            guard let block else {
                assertionFailure("")
                return nil
            }
            var targetObj: Any?
            enumerateObjects { obj, _, stop in
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

        @objc(lookin_lastFiltered:)
        func lastFiltered(_ block: ((Any?) -> Bool)?) -> Any? {
            guard let block else {
                assertionFailure("")
                return nil
            }
            var targetObj: Any?
            enumerateObjects(options: .reverse) { obj, _, stop in
                if block(obj) {
                    targetObj = obj
                    stop.pointee = true
                }
            }
            return targetObj
        }

        @available(*, deprecated, renamed: "lastFiltered(_:)")
        func lookin_lastFiltered(_ block: ((Any?) -> Bool)?) -> Any? {
            lastFiltered(block)
        }

        @objc(lookin_reduce:)
        func reduceObjects(_ block: ((Any?, UInt, Any?) -> Any?)?) -> Any? {
            guard let block else {
                assertionFailure("")
                return nil
            }
            var accumulator: Any?
            enumerateObjects { obj, idx, _ in
                accumulator = block(accumulator, UInt(idx), obj)
            }
            return accumulator
        }

        @available(*, deprecated, renamed: "reduceObjects(_:)")
        func lookin_reduce(_ block: ((Any?, UInt, Any?) -> Any?)?) -> Any? {
            reduceObjects(block)
        }

        @objc(lookin_reduceCGFloat:initialAccumlator:)
        func reduceCGFloat(_ block: ((CGFloat, UInt, Any?) -> CGFloat)?, initialAccumlator: CGFloat) -> CGFloat {
            guard let block else {
                assertionFailure("")
                return initialAccumlator
            }
            var accumulator = initialAccumlator
            enumerateObjects { obj, idx, _ in
                accumulator = block(accumulator, UInt(idx), obj)
            }
            return accumulator
        }

        @available(*, deprecated, renamed: "reduceCGFloat(_:initialAccumlator:)")
        func lookin_reduceCGFloat(_ block: ((CGFloat, UInt, Any?) -> CGFloat)?, initialAccumlator: CGFloat) -> CGFloat {
            reduceCGFloat(block, initialAccumlator: initialAccumlator)
        }

        @objc(lookin_reduceInteger:initialAccumlator:)
        func reduceInteger(_ block: ((Int, UInt, Any?) -> Int)?, initialAccumlator: Int) -> Int {
            guard let block else {
                assertionFailure("")
                return initialAccumlator
            }
            var accumulator = initialAccumlator
            enumerateObjects { obj, idx, _ in
                accumulator = block(accumulator, UInt(idx), obj)
            }
            return accumulator
        }

        @available(*, deprecated, renamed: "reduceInteger(_:initialAccumlator:)")
        func lookin_reduceInteger(_ block: ((Int, UInt, Any?) -> Int)?, initialAccumlator: Int) -> Int {
            reduceInteger(block, initialAccumlator: initialAccumlator)
        }

        @objc(lookin_all:)
        func allObjectsPass(_ block: ((Any?) -> Bool)?) -> Bool {
            guard let block else {
                assertionFailure("")
                return false
            }
            var allPass = true
            enumerateObjects { obj, _, stop in
                if !block(obj) {
                    allPass = false
                    stop.pointee = true
                }
            }
            return allPass
        }

        @available(*, deprecated, renamed: "allObjectsPass(_:)")
        func lookin_all(_ block: ((Any?) -> Bool)?) -> Bool {
            allObjectsPass(block)
        }

        @objc(lookin_any:)
        func anyObjectPasses(_ block: ((Any?) -> Bool)?) -> Bool {
            guard let block else {
                assertionFailure("")
                return false
            }
            var anyPass = false
            enumerateObjects { obj, _, stop in
                if block(obj) {
                    anyPass = true
                    stop.pointee = true
                }
            }
            return anyPass
        }

        @available(*, deprecated, renamed: "anyObjectPasses(_:)")
        func lookin_any(_ block: ((Any?) -> Bool)?) -> Bool {
            anyObjectPasses(block)
        }

        @objc(lookin_arrayByRemovingObject:)
        func array(byRemoving obj: Any?) -> [Any] {
            guard let obj, contains(obj) else {
                return bridgedArray(self)
            }
            let mutableArray = mutableCopy() as! NSMutableArray
            mutableArray.remove(obj)
            return bridgedArray(mutableArray)
        }

        @available(*, deprecated, renamed: "array(byRemoving:)")
        func lookin_array(byRemoving obj: Any?) -> [Any] {
            array(byRemoving: obj)
        }

        @objc(lookin_nonredundantArray)
        func nonredundantArray() -> [Any] {
            let set = NSSet(array: self as! [Any])
            return set.allObjects
        }

        @available(*, deprecated, renamed: "nonredundantArray()")
        func lookin_nonredundant() -> [Any] {
            nonredundantArray()
        }

        @objc(lookin_safeObjectAtIndex:)
        func safeObject(at idx: Int) -> Any? {
            if idx == NSNotFound || idx < 0 {
                return nil
            }
            if count <= idx {
                return nil
            }
            return object(at: idx)
        }

        @available(*, deprecated, renamed: "safeObject(at:)")
        func lookin_safeObject(at idx: Int) -> Any? {
            safeObject(at: idx)
        }

        @objc(lookin_sortedArrayByStringLength)
        func sortedArrayByStringLength() -> [Any] {
            return sortedArray(comparator: { obj1, obj2 in
                let length1 = (obj1 as! NSString).length
                let length2 = (obj2 as! NSString).length
                if length1 > length2 {
                    return .orderedDescending
                } else if length1 == length2 {
                    return .orderedSame
                } else {
                    return .orderedAscending
                }
            })
        }

        @available(*, deprecated, renamed: "sortedArrayByStringLength()")
        func lookin_sortedArrayByStringLength() -> [Any] {
            sortedArrayByStringLength()
        }
    }

    public extension NSMutableArray {
        @objc(lookin_dequeueWithCount:add:notDequeued:doNext:)
        func dequeue(
            withCount count: UInt,
            add addBlock: ((UInt) -> Any?)?,
            notDequeued notDequeuedBlock: ((UInt, Any?) -> Void)?,
            doNext doBlock: ((UInt, Any?) -> Void)?
        ) {
            for i in 0 ..< count {
                if hasIndex(Int(i)) {
                    let obj = object(at: Int(i))
                    doBlock?(i, obj)
                } else if let addBlock {
                    if let newObj = addBlock(i) {
                        add(newObj)
                        doBlock?(i, newObj)
                    } else {
                        assertionFailure("")
                    }
                } else {
                    assertionFailure("")
                }
            }

            if let notDequeuedBlock, UInt(self.count) > count {
                for i in count ..< UInt(self.count) {
                    notDequeuedBlock(i, object(at: Int(i)))
                }
            }
        }

        @available(*, deprecated, renamed: "dequeue(withCount:add:notDequeued:doNext:)")
        func lookin_dequeue(
            withCount count: UInt,
            add addBlock: ((UInt) -> Any?)?,
            notDequeued notDequeuedBlock: ((UInt, Any?) -> Void)?,
            doNext doBlock: ((UInt, Any?) -> Void)?
        ) {
            dequeue(withCount: count, add: addBlock, notDequeued: notDequeuedBlock, doNext: doBlock)
        }

        @objc(lookin_removeObjectsPassingTest:)
        func removeObjects(passingTest block: ((UInt, Any?) -> Bool)?) {
            guard let block else {
                return
            }
            let indexSet = NSMutableIndexSet()
            enumerateObjects { currentObj, idx, _ in
                if block(UInt(idx), currentObj) {
                    indexSet.add(idx)
                }
            }
            removeObjects(at: indexSet as IndexSet)
        }

        @available(*, deprecated, renamed: "removeObjects(passingTest:)")
        func lookin_removeObjects(passingTest block: ((UInt, Any?) -> Bool)?) {
            removeObjects(passingTest: block)
        }
    }

    /// An immutable copy of `array`, handed to Objective-C without copying its
    /// elements: bridging an immutable NSArray to `[Any]` and back returns the
    /// same NSArray.
    private func bridgedArray(_ array: NSArray) -> [Any] {
        array.copy() as! [Any]
    }

#endif
