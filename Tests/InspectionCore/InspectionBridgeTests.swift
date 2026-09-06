import AppKit
import LookInsideInspectionCore
import XCTest

@objc(LKBridgeInspectableApplication)
private final class BridgeInspectableApplication: InspectableApp {
    let responses = RACSubject<AnyObject>()
    var requestStarted: (() -> Void)?

    override init() {
        super.init()
        let information = LookinAppInfo()
        information.appInfoIdentifier = 987_654
        information.appName = "Controlled target"
        information.deviceType = .mac
        appInfo = information
        transportIdentifier = UUID().uuidString
    }

    override func performInspectionRequest(withType _: UInt32, payload _: Any!) -> RACSignal<AnyObject>! {
        requestStarted?()
        return responses
    }
}

@objc(LKInspectionBridgeTests)
final class InspectionBridgeTests: XCTestCase {
    @MainActor
    func testBridgeListsReadsAndRefreshesASessionWithoutDocumentsOrWindows() async throws {
        XCTAssertNil(NSApp)
        let application = BridgeInspectableApplication()
        let session = InspectionSession(inspectableApp: application)
        let inspection = LKMCPBridgeInspectionService()
        let parameters: [String: LKMCPBridgeJSONValue] = ["targetIdentifier": .string("987654")]
        let listResponse = await inspection.handle(request: request("targets.list"))
        XCTAssertNil(listResponse.error)
        guard case let .object(list)? = listResponse.result, case let .array(targets)? = list["targets"] else {
            return XCTFail("Expected a target list")
        }
        XCTAssertTrue(targets.contains { target in
            guard case let .object(properties) = target,
                  case .string("987654")? = properties["targetIdentifier"] else { return false }
            return true
        })
        let beforeCapture = await inspection.handle(request: request("hierarchy.read", parameters: parameters))
        XCTAssertEqual(beforeCapture.error?.code, "hierarchy.notReady")

        let started = expectation(description: "The refresh reaches the target without a window")
        application.requestStarted = { started.fulfill() }
        let refresh = Task { @MainActor in
            await LKMCPBridgeRefreshService().handle(request: request("hierarchy.refresh", parameters: parameters))
        }
        await fulfillment(of: [started], timeout: 2)
        let hierarchy = LookinHierarchyInfo()
        hierarchy.appInfo = application.appInfo
        let root = LookinDisplayItem()
        let object = LookinObject()
        object.oid = 20
        object.classChainList = ["NSView", "NSResponder", "NSObject"]
        root.viewObject = object
        root.frame = CGRect(x: 4, y: 5, width: 60, height: 70)
        hierarchy.displayItems = [root]
        application.responses.sendNext(hierarchy)
        application.responses.sendCompleted()
        let refreshResponse = await refresh.value
        XCTAssertNil(refreshResponse.error)
        XCTAssertEqual(session.hierarchyRevision, 1)
        XCTAssertEqual(session.lastReloadInitiator, "agent")

        let presentation = try session.readHierarchy()
        presentation.displayItems.first?.frame = .zero
        let read = await inspection.handle(request: request("hierarchy.read", parameters: parameters))
        XCTAssertNil(read.error)
        guard case let .object(result)? = read.result,
              case let .array(roots)? = result["roots"],
              case let .object(firstRoot)? = roots.first,
              case let .object(frame)? = firstRoot["frame"]
        else {
            return XCTFail("Expected the captured root frame")
        }
        let encodedWidth = try JSONEncoder().encode(frame["width"])
        XCTAssertEqual(try JSONDecoder().decode(Double.self, from: encodedWidth), 60)
        XCTAssertNil(NSApp)
    }

    @MainActor
    func testBridgeCancellationResumesWithoutRequiringATargetReply() async {
        let subscribed = expectation(description: "Bridge subscribed")
        let cancelled = expectation(description: "Bridge waiter cancelled")
        let responses = RACSubject<AnyObject>()
        let signal = RACSignal<AnyObject>.defer {
            subscribed.fulfill()
            return responses
        }
        let operation = Task { @MainActor in
            do {
                _ = try await LKMCPBridgeRACBridge.awaitFirstValue(of: signal, as: NSString.self)
                XCTFail("Cancelled waiter must fail")
            } catch RACBridgeError.cancelled {
                cancelled.fulfill()
            } catch {
                XCTFail("Unexpected bridge error: \(error)")
            }
        }
        await fulfillment(of: [subscribed], timeout: 2)
        operation.cancel()
        await fulfillment(of: [cancelled], timeout: 2)
        responses.sendCompleted()
    }

    private func request(_ method: String, parameters: [String: LKMCPBridgeJSONValue]? = nil) -> LKMCPBridgeRequest {
        LKMCPBridgeRequest(kind: .request, identifier: UUID().uuidString, method: method, parameters: parameters)
    }
}
