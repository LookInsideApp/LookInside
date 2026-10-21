import Foundation

/// A request a channel sent, as `ActiveRequests` sees it.
@MainActor
public protocol ChannelRequest: AnyObject {
    var type: UInt32 { get }
}

/// The requests one channel sent and has not heard the end of.
///
/// One request of a type is in flight at a time: a response carries only its
/// request's type and tag, and the tag is the send time in seconds, so two
/// requests of a type in flight could not be told apart. A new request either
/// replaces the one of its type in flight, which the caller then fails as
/// discarded, or yields to it and is not sent. Upstream Lookin only
/// replaced; the inspector's own detail requests yield, so that resuming its
/// fetch never knocks out the one the MCP bridge sent. Requests of the types
/// in `typesThatMayOverlap` (pings) never replace one another.
@MainActor
public final class ActiveRequests<Request: ChannelRequest> {
    public enum Admission {
        /// The request is in flight now. `replacedRequests` were in flight
        /// with its type and are not any more.
        case admitted(replacedRequests: [Request])
        /// The request yields to one of its type in flight; it was not
        /// added.
        case refused
    }

    public private(set) var requests: [Request] = []
    private let typesThatMayOverlap: Set<UInt32>

    public init(typesThatMayOverlap: Set<UInt32>) {
        self.typesThatMayOverlap = typesThatMayOverlap
    }

    /// Adds `request` unless it yields to one of its type in flight;
    /// otherwise the ones of its type in flight make way.
    public func admit(_ request: Request, yieldsToRequestInFlight: Bool) -> Admission {
        var replacedRequests: [Request] = []
        if !typesThatMayOverlap.contains(request.type) {
            replacedRequests = requests.filter { $0.type == request.type }
            if yieldsToRequestInFlight, !replacedRequests.isEmpty {
                return .refused
            }
            requests.removeAll { $0.type == request.type }
        }
        requests.append(request)
        return .admitted(replacedRequests: replacedRequests)
    }

    public func remove(_ request: Request) {
        requests.removeAll { $0 === request }
    }

    /// Takes every request out, for a channel that ended: none of them can
    /// be answered any more, and the caller fails each one.
    public func removeAll() -> [Request] {
        let removed = requests
        requests = []
        return removed
    }

    public func contains(_ request: Request) -> Bool {
        requests.contains { $0 === request }
    }

    public func containsRequest(ofType type: UInt32) -> Bool {
        requests.contains { $0.type == type }
    }

    public func first(where predicate: (Request) -> Bool) -> Request? {
        requests.first(where: predicate)
    }
}
