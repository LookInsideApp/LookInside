//
//  WeakContainer.swift
//  Lookin
//
//  Was LookinWeakContainer.m.
//

#if SHOULD_COMPILE_LOOKIN_SERVER

    import Foundation
    #if SWIFT_PACKAGE
        import LookinCore
    #endif

    @objc(LookinWeakContainer)
    public class WeakContainer: NSObject {
        @objc(object)
        public weak var object: AnyObject?

        /// `+containerWithObject:`. An Objective-C factory must be a class
        /// method here: implemented as a Swift initializer it compiles but
        /// registers no class method.
        @objc(containerWithObject:)
        public class func container(object: Any?) -> Self {
            let container = unsafeDowncast((self as NSObject.Type).init(), to: self)
            container.object = object as AnyObject?
            return container
        }

        override public init() {
            super.init()
        }

        // MARK: Equality

        override open var hash: Int {
            (object as? NSObjectProtocol)?.hash ?? 0
        }

        override open func isEqual(_ object: Any?) -> Bool {
            if let object = object as? NSObject, object === self {
                return true
            }
            guard let compared = object as? WeakContainer else {
                return false
            }
            // [nil isEqual:] is NO.
            guard let contained = self.object as? NSObjectProtocol else {
                return false
            }
            return contained.isEqual(compared.object)
        }
    }

#endif
