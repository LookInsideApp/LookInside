//
//  MessageAttribute.swift
//  LookInside
//
//  A value with target-action subscribers. Setting a different value sends the
//  subscribers' actions through `NSApp.sendAction(_:to:from:)` with a
//  `MessageActionParameters` as the sender. Targets and related objects are held
//  weakly; subscribers whose target is gone are dropped on the next change.
//
//  The class names and selectors are the ones the Objective-C version had:
//  `PreferenceManager` and the inspector controllers still call them.
//

import AppKit

/// The sender of a subscriber's action.
final class MessageActionParameters: NSObject {
    var value: Any?
    weak var relatedObject: AnyObject?
    var userInfo: Any?

    var doubleValue: Double {
        guard let number = value as? NSNumber else {
            assertionFailure("MessageActionParameters.value is not a number")
            return 0
        }
        return number.doubleValue
    }

    var integerValue: Int {
        guard let number = value as? NSNumber else {
            assertionFailure("MessageActionParameters.value is not a number")
            return 0
        }
        return number.intValue
    }

    var boolValue: Bool {
        guard let number = value as? NSNumber else {
            assertionFailure("MessageActionParameters.value is not a number")
            return false
        }
        return number.boolValue
    }
}

class MessageAttribute: NSObject {
    /// One target-action pair. Two subscriptions are the same when the target
    /// and the related object are the same objects and the action has the same name.
    private final class Subscriber {
        weak var target: AnyObject?
        let action: Selector
        weak var relatedObject: AnyObject?

        init(target: AnyObject, action: Selector, relatedObject: AnyObject?) {
            self.target = target
            self.action = action
            self.relatedObject = relatedObject
        }

        func matches(target: AnyObject, action: Selector, relatedObject: AnyObject?) -> Bool {
            self.target === target && self.action == action && self.relatedObject === relatedObject
        }
    }

    /// Identifies a subscription by object identity, for the duplicate check.
    /// An identity outlives its object, so a hit only counts when the stored
    /// subscriber still points at the very same objects.
    private struct SubscriptionKey: Hashable {
        let target: ObjectIdentifier
        let action: Selector
        let relatedObject: ObjectIdentifier?
    }

    private(set) var currentValue: Any?

    /// In subscription order, which is the order actions are sent in.
    private var subscribers: [Subscriber] = []
    /// The duplicate check: a linear scan of `subscribers` made subscribing n
    /// targets O(n²), and the 3D preview subscribes each of its nodes to three
    /// shared preference attributes, so opening a 6,000-node document spent
    /// seconds in it.
    private var subscribersByKey: [SubscriptionKey: Subscriber] = [:]
    /// Subscriptions added since subscribers whose target went away were last
    /// dropped.
    private var subscriptionsSincePruning = 0

    override init() {
        super.init()
    }

    /// Creates an attribute holding `value`.
    convenience init(value: Any?) {
        self.init()
        currentValue = value
    }

    class func attribute(withValue value: Any?) -> MessageAttribute {
        MessageAttribute(value: value)
    }

    /// Stores `value` and sends every subscriber's action, except the subscriber
    /// whose target is `ignoreSubscriber`. Does nothing when `value` equals the
    /// current value. `userInfo` reaches the subscribers through the params.
    func setValue(_ value: Any?, ignoreSubscriber: Any?, userInfo: Any?) {
        if let current = currentValue as? NSObject, current.isEqual(value) {
            return
        }
        currentValue = value

        let ignored = ignoreSubscriber as AnyObject?
        pruneSubscribersWhoseTargetWentAway()
        for subscriber in subscribers {
            guard let target = subscriber.target, target !== ignored else {
                continue
            }
            let params = MessageActionParameters()
            params.userInfo = userInfo
            params.value = value
            params.relatedObject = subscriber.relatedObject
            NSApp.sendAction(subscriber.action, to: target, from: params)
        }
    }

    /// Adds a subscriber. Subscribing the same target, action and related object
    /// again has no effect.
    func subscribe(_ target: Any?, action: Selector?, relatedObject: Any?) {
        subscribe(target, action: action, relatedObject: relatedObject, sendAtOnce: false)
    }

    /// Like `subscribe(_:action:relatedObject:)`; with `sendAtOnce` the action is
    /// also sent right away with the current value.
    func subscribe(_ target: Any?, action: Selector?, relatedObject: Any?, sendAtOnce: Bool) {
        guard let target = target as AnyObject?, let action else {
            return
        }
        let related = relatedObject as AnyObject?
        let key = SubscriptionKey(target: ObjectIdentifier(target), action: action, relatedObject: related.map { ObjectIdentifier($0) })
        if let existing = subscribersByKey[key], existing.matches(target: target, action: action, relatedObject: related) {
            return
        }
        let subscriber = Subscriber(target: target, action: action, relatedObject: related)
        subscribers.append(subscriber)
        subscribersByKey[key] = subscriber

        // Preview nodes go away with their document while the preference
        // attributes they subscribed to live on, and only a value change used
        // to drop them.
        subscriptionsSincePruning += 1
        if subscriptionsSincePruning >= max(subscribers.count / 2, 1024) {
            pruneSubscribersWhoseTargetWentAway()
        }

        if sendAtOnce {
            let params = MessageActionParameters()
            params.value = currentValue
            params.relatedObject = related
            NSApp.sendAction(action, to: target, from: params)
        }
    }

    private func pruneSubscribersWhoseTargetWentAway() {
        subscriptionsSincePruning = 0
        guard subscribers.contains(where: { $0.target == nil }) else {
            return
        }
        subscribers.removeAll { $0.target == nil }
        subscribersByKey = subscribersByKey.filter { $0.value.target != nil }
    }
}

final class DoubleMessageAttribute: MessageAttribute {
    convenience init(double value: Double) {
        self.init(value: NSNumber(value: value))
    }

    class func attribute(withDouble value: Double) -> DoubleMessageAttribute {
        DoubleMessageAttribute(double: value)
    }

    var currentDoubleValue: Double {
        (currentValue as? NSNumber)?.doubleValue ?? 0
    }

    func setDoubleValue(_ doubleValue: Double, ignoreSubscriber: Any?) {
        setValue(NSNumber(value: doubleValue), ignoreSubscriber: ignoreSubscriber, userInfo: nil)
    }
}

final class IntegerMessageAttribute: MessageAttribute {
    convenience init(integer value: Int) {
        self.init(value: NSNumber(value: value))
    }

    class func attribute(withInteger value: Int) -> IntegerMessageAttribute {
        IntegerMessageAttribute(integer: value)
    }

    var currentIntegerValue: Int {
        (currentValue as? NSNumber)?.intValue ?? 0
    }

    func setIntegerValue(_ integerValue: Int, ignoreSubscriber: Any?) {
        setValue(NSNumber(value: integerValue), ignoreSubscriber: ignoreSubscriber, userInfo: nil)
    }
}

final class BoolMessageAttribute: MessageAttribute {
    convenience init(bool value: Bool) {
        self.init(value: NSNumber(value: value))
    }

    class func attribute(withBOOL value: Bool) -> BoolMessageAttribute {
        BoolMessageAttribute(bool: value)
    }

    var currentBOOLValue: Bool {
        (currentValue as? NSNumber)?.boolValue ?? false
    }

    func setBOOLValue(_ boolValue: Bool, ignoreSubscriber: Any?) {
        setValue(NSNumber(value: boolValue), ignoreSubscriber: ignoreSubscriber, userInfo: nil)
    }
}
