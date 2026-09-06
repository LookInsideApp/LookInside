import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol

@MainActor
final class InspectionCompatibilityRoutes {
    static let methods = ["ping", "targets.list", "hierarchy.read", "hierarchy.find", "hierarchy.refresh",
                          "attributes.read", "details.read", "screenshot.read", "selectors.list", "invoke.method", "attribute.modify"]

    private let inspection = LKMCPBridgeInspectionService()
    private let invocation = LKMCPBridgeInvocationService()
    private let modification = LKMCPBridgeModificationService()
    private let details = LKMCPBridgeDetailsService()
    private let screenshot = LKMCPBridgeScreenshotService()
    private let search = LKMCPBridgeSearchService()
    private let selectors = LKMCPBridgeSelectorService()
    private let refresh = LKMCPBridgeRefreshService()

    func handle(_ request: InspectionRequest, sessions: [InspectionSession]) async -> InspectionResponse {
        await InspectionSessionLookup.$visibleSessions.withValue(sessions) {
            switch request.method {
            case "ping":
                return .success(identifier: request.identifier, result: .object([
                    "pong": .bool(true), "serverVersion": .string(InspectionEnvironment.shared().clientReadableVersion),
                    "backend": .string("inspectionService"),
                ]))
            case "invoke.method": return await invocation.handle(request: request)
            case "attribute.modify": return await modification.handle(request: request)
            case "details.read": return await details.handle(request: request)
            case "screenshot.read": return await screenshot.handle(request: request)
            case "hierarchy.find": return await search.handle(request: request)
            case "selectors.list": return await selectors.handle(request: request)
            case "hierarchy.refresh": return await refresh.handle(request: request)
            default: return await inspection.handle(request: request)
            }
        }
    }
}
