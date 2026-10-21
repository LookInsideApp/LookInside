@testable import LookInsideHostCore
import Testing

private final class SampleRequest: ChannelRequest {
    let type: UInt32

    init(type: UInt32) {
        self.type = type
    }
}

@MainActor
struct ActiveRequestsTests {
    private static let pingType: UInt32 = 200
    private static let hierarchyType: UInt32 = 202
    private static let detailsType: UInt32 = 203

    private func makeActiveRequests() -> ActiveRequests<SampleRequest> {
        ActiveRequests(typesThatMayOverlap: [Self.pingType])
    }

    /// The requests an admission replaced; nil when it was refused.
    private func replacedRequests(_ admission: ActiveRequests<SampleRequest>.Admission) -> [SampleRequest]? {
        switch admission {
        case let .admitted(replacedRequests):
            replacedRequests
        case .refused:
            nil
        }
    }

    @Test func aNewerRequestReplacesTheOneOfItsTypeInFlight() throws {
        let activeRequests = makeActiveRequests()
        let older = SampleRequest(type: Self.detailsType)
        let newer = SampleRequest(type: Self.detailsType)
        _ = activeRequests.admit(older, yieldsToRequestInFlight: false)

        let replaced = try #require(replacedRequests(activeRequests.admit(newer, yieldsToRequestInFlight: false)))
        #expect(replaced.map(ObjectIdentifier.init) == [ObjectIdentifier(older)])
        #expect(activeRequests.requests.map(ObjectIdentifier.init) == [ObjectIdentifier(newer)])
    }

    /// The inspector's own detail requests yield, so they never knock out
    /// the one the MCP bridge sent.
    @Test func aRequestThatYieldsIsNotAddedWhileOneOfItsTypeIsInFlight() {
        let activeRequests = makeActiveRequests()
        let inFlight = SampleRequest(type: Self.detailsType)
        _ = activeRequests.admit(inFlight, yieldsToRequestInFlight: false)

        let admission = activeRequests.admit(SampleRequest(type: Self.detailsType), yieldsToRequestInFlight: true)
        #expect(replacedRequests(admission) == nil)
        #expect(activeRequests.requests.map(ObjectIdentifier.init) == [ObjectIdentifier(inFlight)])
    }

    @Test func aRequestThatYieldsIsAddedWhenNoneOfItsTypeIsInFlight() throws {
        let activeRequests = makeActiveRequests()
        let hierarchy = SampleRequest(type: Self.hierarchyType)
        let details = SampleRequest(type: Self.detailsType)
        _ = activeRequests.admit(hierarchy, yieldsToRequestInFlight: false)

        let replaced = try #require(replacedRequests(activeRequests.admit(details, yieldsToRequestInFlight: true)))
        #expect(replaced.isEmpty)
        #expect(activeRequests.requests.map(ObjectIdentifier.init) == [ObjectIdentifier(hierarchy), ObjectIdentifier(details)])
    }

    @Test func aRemovedRequestNoLongerHoldsItsType() throws {
        let activeRequests = makeActiveRequests()
        let finished = SampleRequest(type: Self.detailsType)
        _ = activeRequests.admit(finished, yieldsToRequestInFlight: false)
        activeRequests.remove(finished)

        #expect(activeRequests.containsRequest(ofType: Self.detailsType) == false)
        let replaced = try #require(replacedRequests(activeRequests.admit(SampleRequest(type: Self.detailsType), yieldsToRequestInFlight: true)))
        #expect(replaced.isEmpty)
    }

    @Test func pingsDoNotReplaceOneAnother() throws {
        let activeRequests = makeActiveRequests()
        let firstPing = SampleRequest(type: Self.pingType)
        let secondPing = SampleRequest(type: Self.pingType)
        _ = activeRequests.admit(firstPing, yieldsToRequestInFlight: false)

        let replaced = try #require(replacedRequests(activeRequests.admit(secondPing, yieldsToRequestInFlight: false)))
        #expect(replaced.isEmpty)
        #expect(activeRequests.requests.count == 2)
    }

    /// A channel that ended fails what it still waits for at once; until
    /// then a hierarchy request kept the window "fetching" until its own
    /// timeout and the refresh after a reconnect was refused.
    @Test("an ended channel hands back every request still waiting, pings included")
    func anEndedChannelHandsBackEveryWaitingRequest() {
        let activeRequests = makeActiveRequests()
        let ping = SampleRequest(type: Self.pingType)
        let hierarchy = SampleRequest(type: Self.hierarchyType)
        let details = SampleRequest(type: Self.detailsType)
        for request in [ping, hierarchy, details] {
            _ = activeRequests.admit(request, yieldsToRequestInFlight: false)
        }

        let removed = activeRequests.removeAll()

        #expect(removed.map(ObjectIdentifier.init) == [ObjectIdentifier(ping), ObjectIdentifier(hierarchy), ObjectIdentifier(details)])
        #expect(activeRequests.requests.isEmpty)
        #expect(activeRequests.containsRequest(ofType: Self.hierarchyType) == false)
    }
}
