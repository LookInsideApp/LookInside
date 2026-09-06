import LookInsideInspectionCore
import XCTest

@objc(LKInspectionSessionAccessTests)
final class InspectionSessionAccessTests: XCTestCase {
    @MainActor
    func testAsyncAdapterWaitsForCompletionAndCollectsEveryFrame() async throws {
        let responses = RACSubject<AnyObject>()
        let subscribed = expectation(description: "Subscribed to the response stream")
        let signal = RACSignal<AnyObject>.defer {
            subscribed.fulfill()
            return responses
        }
        let operation = Task { @MainActor in
            try await InspectionSignalAwaiter.allValues(of: signal, as: String.self)
        }
        await fulfillment(of: [subscribed], timeout: 2)
        responses.sendNext("first" as NSString)
        responses.sendNext("second" as NSString)
        responses.sendCompleted()
        let values = try await operation.value
        XCTAssertEqual(values, ["first", "second"])
    }

    @MainActor
    func testCancellationResumesAnAlreadySuspendedWaitWithoutAResponse() async {
        let responses = RACSubject<AnyObject>()
        let subscribed = expectation(description: "Subscribed before cancellation")
        let cancelled = expectation(description: "Cancellation resumes the waiter")
        let signal = RACSignal<AnyObject>.defer {
            subscribed.fulfill()
            return responses
        }
        let operation = Task { @MainActor in
            do {
                _ = try await InspectionSignalAwaiter.allValues(of: signal, as: String.self)
                XCTFail("A cancelled wait must fail")
            } catch is CancellationError {
                cancelled.fulfill()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        await fulfillment(of: [subscribed], timeout: 2)
        operation.cancel()
        await fulfillment(of: [cancelled], timeout: 2)
        responses.sendNext("late" as NSString)
        responses.sendCompleted()
    }

    @MainActor
    func testCancellationBeforeSubscriptionNeverStartsTheOperation() async {
        var subscriptionCount = 0
        let signal = RACSignal<AnyObject>.defer {
            subscriptionCount += 1
            return RACSignal<AnyObject>.empty()
        }
        let operation = Task { @MainActor in
            do {
                _ = try await InspectionSignalAwaiter.allValues(of: signal, as: String.self)
                XCTFail("A cancelled task must fail")
            } catch is CancellationError {
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        operation.cancel()
        await operation.value
        XCTAssertEqual(subscriptionCount, 0)
    }

    @MainActor
    func testSynchronousCompletionAndFailureResolveExactlyOnce() async throws {
        let value = RACSignal<AnyObject>.return("synchronous" as NSString)
        let values = try await InspectionSignalAwaiter.allValues(of: value, as: String.self)
        XCTAssertEqual(values, ["synchronous"])
        let expectedError = NSError(domain: "ControlledTarget", code: 42)
        do {
            _ = try await InspectionSignalAwaiter.allValues(
                of: RACSignal<AnyObject>.error(expectedError), as: String.self
            )
            XCTFail("The target error must reach the waiter")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
}
