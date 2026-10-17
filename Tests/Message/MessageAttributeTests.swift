import AppKit

/// Counts the actions a `MessageAttribute` sends it.
final class RecordingTarget: NSObject {
    private(set) var receivedValues: [Any?] = []

    @objc func handleChange(_ parameters: MessageActionParameters) {
        receivedValues.append(parameters.value)
    }
}

@main
struct MessageAttributeTests {
    static func main() {
        _ = NSApplication.shared
        testDuplicateSubscriptionsAreIgnored()
        testRelatedObjectsMakeSubscriptionsDistinct()
        testATargetThatWentAwayDoesNotBlockANewOne()
        testSubscribingManyTargetsStaysLinear()
        print("MessageAttribute tests passed")
    }

    private static let action = #selector(RecordingTarget.handleChange(_:))

    static func testDuplicateSubscriptionsAreIgnored() {
        let attribute = MessageAttribute(value: NSNumber(value: false))
        let target = RecordingTarget()
        attribute.subscribe(target, action: action, relatedObject: nil)
        attribute.subscribe(target, action: action, relatedObject: nil)
        attribute.setValue(NSNumber(value: true), ignoreSubscriber: nil, userInfo: nil)
        verify(target.receivedValues.count == 1, "a second identical subscription has no effect")
    }

    static func testRelatedObjectsMakeSubscriptionsDistinct() {
        let attribute = MessageAttribute(value: NSNumber(value: 0))
        let target = RecordingTarget()
        let firstRelatedObject = NSObject()
        let secondRelatedObject = NSObject()
        attribute.subscribe(target, action: action, relatedObject: firstRelatedObject)
        attribute.subscribe(target, action: action, relatedObject: secondRelatedObject)
        attribute.subscribe(target, action: action, relatedObject: firstRelatedObject)
        attribute.setValue(NSNumber(value: 1), ignoreSubscriber: nil, userInfo: nil)
        verify(target.receivedValues.count == 2, "one action per related object")
        withExtendedLifetime((firstRelatedObject, secondRelatedObject)) {}
    }

    /// Preview nodes come and go with every document; a node created where
    /// an old one used to be must still be subscribed, even when it reuses
    /// the old node's address.
    static func testATargetThatWentAwayDoesNotBlockANewOne() {
        let attribute = MessageAttribute(value: NSNumber(value: 0))
        for round in 1 ... 200 {
            autoreleasepool {
                let departingTarget = RecordingTarget()
                attribute.subscribe(departingTarget, action: action, relatedObject: nil)
            }
            let arrivingTarget = RecordingTarget()
            attribute.subscribe(arrivingTarget, action: action, relatedObject: nil)
            attribute.setValue(NSNumber(value: round), ignoreSubscriber: nil, userInfo: nil)
            verify(arrivingTarget.receivedValues.count == 1, "round \(round): a new target is subscribed even where an old one went away")
        }
    }

    /// The 3D preview subscribes every one of its nodes to three preference
    /// attributes; a 6,000-node hierarchy spent seconds here while a document
    /// opened when every subscription scanned all the earlier ones.
    static func testSubscribingManyTargetsStaysLinear() {
        let attribute = MessageAttribute(value: NSNumber(value: false))
        let targets = (0 ..< 20000).map { _ in RecordingTarget() }
        let start = ContinuousClock.now
        for target in targets {
            attribute.subscribe(target, action: action, relatedObject: nil)
        }
        let elapsed = ContinuousClock.now - start
        verify(elapsed < .seconds(2), "subscribing 20,000 targets took \(elapsed)")
        attribute.setValue(NSNumber(value: true), ignoreSubscriber: nil, userInfo: nil)
        verify(targets.allSatisfy { $0.receivedValues.count == 1 }, "every target receives the change once")
    }
}

/// Prints the failure and exits non-zero: an optimized build's
/// `precondition` would trap without saying which check failed.
func verify(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String) {
    guard condition() else {
        FileHandle.standardError.write(Data("MessageAttribute test failed: \(message())\n".utf8))
        exit(1)
    }
}
