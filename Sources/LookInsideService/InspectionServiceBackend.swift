import AppKit
import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol

@MainActor
final class InspectionServiceBackend {
    var instanceIdentifier = ""
    var publish: ((InspectionEvent) -> Void)?
    let transfers = InspectionTransferStore()
    let compatibility = InspectionCompatibilityRoutes()
    var authorizationRequest: ((InspectionValue) async throws -> InspectionValue)?
    var observers: [NSObjectProtocol] = []
    var pushSubscription: RACDisposable?
    private let discoverApplications: () async throws -> [InspectableApp]
    let isConnected: (InspectableApp) -> Bool
    private let prepareAuthorization: () throws -> Void
    private let authorizationFailure: () -> InspectionFailure
    var targets: [String: InspectableApp] = [:]
    private var targetIdentifiers: [String: String] = [:]
    var sessions: [String: InspectionSession] = [:]
    var sessionTargets: [String: String] = [:]
    var sessionClients: [String: Set<String>] = [:]
    private var discoveryTask: Task<Void, Error>?
    private var initialCaptures: [String: Task<Void, Error>] = [:]

    init(discoverApplications: (() async throws -> [InspectableApp])? = nil,
         isConnected: @escaping (InspectableApp) -> Bool = { $0.channel?.isConnected == true },
         prepareAuthorization: @escaping () throws -> Void = {},
         authorizationFailure: @escaping () -> InspectionFailure = { .licenseRequired })
    {
        self.isConnected = isConnected
        self.prepareAuthorization = prepareAuthorization
        self.authorizationFailure = authorizationFailure
        self.discoverApplications = discoverApplications ?? {
            guard let signal = AppsManager.sharedInstance().fetchAppInfos(withImage: true, localInfos: []) else {
                throw InspectionFailure.internalError
            }
            return try await InspectionSignalAwaiter.allValues(of: signal.timeout(20, on: RACScheduler.mainThread()), as: [InspectableApp].self).flatMap { $0 }
        }
    }

    func disconnect(clientIdentifier: String) {
        transfers.disconnect(owner: clientIdentifier)
        for sessionIdentifier in Array(sessionClients.keys) {
            sessionClients[sessionIdentifier] = sessionClients[sessionIdentifier]?.filter {
                $0 != clientIdentifier && !$0.hasPrefix(clientIdentifier + ":")
            }
        }
    }

    func stop() {
        pushSubscription?.dispose()
        pushSubscription = nil
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        discoveryTask?.cancel()
        discoveryTask = nil
        for capture in initialCaptures.values {
            capture.cancel()
        }
        initialCaptures.removeAll()
        sessions.removeAll()
        sessionTargets.removeAll()
        sessionClients.removeAll()
        targets.removeAll()
    }

    func handleCommand(_ request: InspectionRequest, clientIdentifier: String) async -> InspectionResponse {
        var session: InspectionSession?
        var fromCache = true
        do {
            let result: InspectionValue
            switch request.method {
            case "targets.discover":
                result = try await discover()
                fromCache = false
            case "sessions.list":
                result = .object(["sessions": .array(sessions.keys.sorted().compactMap { identifier in
                    guard let session = sessions[identifier] else { return nil }
                    return sessionDescription(session)
                })])
            case "sessions.open":
                let targetIdentifier = try requiredString("targetIdentifier", in: request)
                guard let application = targets[targetIdentifier], isConnected(application) else {
                    throw InspectionFailure(code: "target.notFound", message: "Discover targets again and open a currently connected target.")
                }
                if let existing = sessions.values.first(where: { sessionTargets[$0.sessionIdentifier] == targetIdentifier }) {
                    if existing.inspectableApp.channel !== application.channel {
                        existing.replaceInspectableApp(application)
                    }
                    session = existing
                } else {
                    if let options = request.parameters?["initialCaptureOptions"] {
                        guard let dictionary = try JSONSerialization.jsonObject(with: JSONEncoder().encode(options)) as? [String: Any]
                        else { throw InspectionFailure.invalidParameters }
                        session = InspectionSession(inspectableApp: application, captureOptions: dictionary)
                    } else {
                        session = InspectionSession(inspectableApp: application)
                    }
                }
                let openedSession = session!
                sessions[openedSession.sessionIdentifier] = openedSession
                sessionTargets[openedSession.sessionIdentifier] = targetIdentifier
                sessionClients[openedSession.sessionIdentifier, default: []].insert(clientIdentifier)
                result = sessionDescription(openedSession)
            case "sessions.close":
                let identifier = try requiredString("sessionIdentifier", in: request)
                guard let existing = sessions[identifier] else { throw missingSession() }
                guard sessionClients[identifier, default: []].subtracting([clientIdentifier]).isEmpty else {
                    throw InspectionFailure(code: "session.inUse", message: "Another connected client is using this session.")
                }
                session = existing
                sessions.removeValue(forKey: identifier)
                sessionTargets.removeValue(forKey: identifier)
                sessionClients.removeValue(forKey: identifier)
                result = .object(["closed": .bool(true)])
            case "hierarchy.read", "hierarchy.refresh", "views.find", "attributes.read", "screenshot.read":
                let identifier = try requiredString("sessionIdentifier", in: request)
                guard let existing = sessions[identifier] else { throw missingSession() }
                session = existing
                guard isConnected(existing.inspectableApp), existing.connectionLossBannerMessage == nil else {
                    throw InspectionFailure(code: "session.disconnected", message: "The target disconnected. Discover targets and open a new connection.")
                }
                if let generation = request.parameters?["connectionGeneration"]?.integerValue,
                   generation < 0 || UInt64(generation) != existing.connectionGeneration
                {
                    throw InspectionFailure(code: "session.stale", message: "The target connection generation changed.")
                }
                if let revision = request.parameters?["hierarchyRevision"]?.integerValue,
                   revision < 0 || UInt64(revision) != existing.hierarchyRevision
                {
                    throw InspectionFailure(code: "session.stale", message: "The hierarchy revision changed. Read the hierarchy again.")
                }
                sessionClients[identifier, default: []].insert(clientIdentifier)
                if let capability = request.parameters?["requiredCapability"]?.stringValue {
                    guard capability == "swiftui" else { throw InspectionFailure.invalidParameters }
                    guard ConnectionManager.sharedInstance().isLicenseVerified(for: existing.inspectableApp.channel) else { throw authorizationFailure() }
                }
                if request.method == "hierarchy.refresh" || request.parameters?["fresh"]?.booleanValue == true {
                    _ = try await existing.refreshHierarchy()
                    fromCache = false
                } else if existing.captureDate == nil {
                    try await ensureInitialCapture(existing)
                    fromCache = false
                }
                result = try await read(request, session: existing, fromCache: &fromCache)
            default:
                throw InspectionFailure.unknownMethod
            }
            return InspectionResponse(identifier: request.identifier, result: result, error: nil, metadata: metadata(session: session, fromCache: fromCache))
        } catch {
            return InspectionResponse(identifier: request.identifier, result: nil, error: failure(for: error), metadata: metadata(session: session, fromCache: fromCache))
        }
    }

    func ensureInitialCapture(_ session: InspectionSession, initiator: String = "host") async throws {
        guard session.captureDate == nil else { return }
        let identifier = session.sessionIdentifier
        let capture: Task<Void, Error>
        if let existing = initialCaptures[identifier] {
            capture = existing
        } else {
            capture = Task {
                defer { initialCaptures.removeValue(forKey: identifier) }
                _ = try await InspectionSignalAwaiter.allValues(of: session.refreshHierarchy(initiator: initiator), as: LookinHierarchyInfo.self)
            }
            initialCaptures[identifier] = capture
        }
        try await capture.value
        try Task.checkCancellation()
    }

    func discover() async throws -> InspectionValue {
        let pending: Task<Void, Error>
        if let discoveryTask {
            pending = discoveryTask
        } else {
            pending = Task {
                defer { discoveryTask = nil }
                try await updateDiscoveredTargets()
            }
            discoveryTask = pending
        }
        try await pending.value
        try Task.checkCancellation()
        let descriptions = targets.keys.sorted().compactMap { identifier -> InspectionValue? in
            guard let application = targets[identifier], isConnected(application), let information = application.appInfo else { return nil }
            return .object([
                "targetIdentifier": .string(identifier), "applicationInstanceIdentifier": .string(String(information.appInfoIdentifier)),
                "transportIdentifier": .string(application.transportIdentifier ?? "unknown"),
                "applicationName": .string(information.appName ?? ""), "bundleIdentifier": .string(information.appBundleIdentifier ?? ""),
                "deviceDescription": .string(information.deviceDescription ?? ""), "serverVersion": .integer(Int64(information.serverVersion)),
                "protectedCapabilitiesVerified": .bool(ConnectionManager.sharedInstance().isLicenseVerified(for: application.channel)),
            ])
        }
        return .object(["targets": .array(descriptions)])
    }

    private func updateDiscoveredTargets() async throws {
        try prepareAuthorization()
        let applications = try await discoverApplications()
        for application in applications {
            guard let information = application.appInfo, application.serverVersionError == nil, isConnected(application) else { continue }
            let identity = "\(application.transportIdentifier ?? "unknown"):\(information.appInfoIdentifier)"
            let identifier = targetIdentifiers[identity] ?? UUID().uuidString
            targetIdentifiers[identity] = identifier
            targets[identifier] = application
        }
    }

    private func read(_ request: InspectionRequest, session: InspectionSession, fromCache: inout Bool) async throws -> InspectionValue {
        let hierarchy = try session.readHierarchy()
        let roots = hierarchy.displayItems ?? []
        switch request.method {
        case "hierarchy.read", "hierarchy.refresh":
            let depth = request.parameters?["depth"]?.integerValue ?? 4
            guard depth >= 0, depth <= 100 else { throw InspectionFailure.invalidParameters }
            return .object(["roots": .array(roots.map { InspectionSnapshotEncoder.node($0, remainingDepth: Int(depth)) })])
        case "views.find":
            let className = try requiredString("className", in: request)
            let matches = (session.rawFlatItems ?? []).filter { $0.displayingObject()?.classChainList?.contains(className) == true }
            return .object(["matches": .array(matches.map { InspectionSnapshotEncoder.node($0, remainingDepth: 1) })])
        case "attributes.read":
            let objectIdentifier = try requiredString("objectIdentifier", in: request)
            var item = try findItem(objectIdentifier: objectIdentifier, session: session)
            if item.attributesGroupList == nil {
                try await fetchDetails(for: item, session: session, screenshot: false)
                item = try findItem(objectIdentifier: objectIdentifier, session: session)
                fromCache = false
            }
            return try InspectionSnapshotEncoder.attributes(item)
        case "screenshot.read":
            var item: LookinDisplayItem
            if let objectIdentifier = request.parameters?["objectIdentifier"]?.stringValue {
                item = try findItem(objectIdentifier: objectIdentifier, session: session)
            } else {
                guard let window = roots.first(where: { $0.representedAsKeyWindow }) ?? roots.first else {
                    throw InspectionFailure(code: "object.notFound", message: "The hierarchy does not contain a window to capture.")
                }
                item = window
            }
            let identifier = InspectionSnapshotEncoder.objectIdentifier(item)
            if item.groupScreenshot == nil || request.parameters?["fresh"]?.booleanValue == true {
                try await fetchDetails(for: item, session: session, screenshot: true)
                item = try findItem(objectIdentifier: identifier, session: session)
                fromCache = false
            }
            guard let image = item.groupScreenshot, let representation = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: representation), let imageData = bitmap.representation(using: .png, properties: [:])
            else {
                throw InspectionFailure(code: "screenshot.unavailable", message: "The target returned no image for this object.")
            }
            return .object(["objectIdentifier": .string(identifier), "imageBase64": .string(imageData.base64EncodedString()),
                            "mimeType": .string("image/png"), "pixelWidth": .integer(Int64(bitmap.pixelsWide)), "pixelHeight": .integer(Int64(bitmap.pixelsHigh))])
        default: throw InspectionFailure.unknownMethod
        }
    }

    private func fetchDetails(for item: LookinDisplayItem, session: InspectionSession, screenshot: Bool) async throws {
        guard let objectIdentifier = item.displayingObject()?.oid, objectIdentifier != 0 else { throw InspectionFailure.invalidParameters }
        let task = LookinStaticAsyncUpdateTask()
        task.oid = objectIdentifier
        task.taskType = screenshot ? .groupScreenshot : .noScreenshot
        task.attrRequest = screenshot ? .notNeed : .need
        task.needBasisVisualInfo = !screenshot
        task.needSubitems = false
        task.clientReadableVersion = InspectionEnvironment.shared().clientReadableVersion
        let package = LookinStaticAsyncUpdateTasksPackage()
        package.tasks = [task]
        let details = try await session.fetchDetails(packages: [package])
        guard let detail = details.first(where: { $0.displayItemOid == objectIdentifier }), detail.failureCode == 0 else {
            throw InspectionFailure(code: "object.notFound", message: "The target could not read this object. Refresh the hierarchy and retry.")
        }
    }

    private func findItem(objectIdentifier: String, session: InspectionSession) throws -> LookinDisplayItem {
        guard let item = session.rawFlatItems?.first(where: { InspectionSnapshotEncoder.objectIdentifier($0) == objectIdentifier }) else {
            throw InspectionFailure(code: "object.notFound", message: "The object is absent from this session's hierarchy.")
        }
        return item
    }

    func sessionDescription(_ session: InspectionSession) -> InspectionValue {
        .object(["sessionIdentifier": .string(session.sessionIdentifier), "targetIdentifier": .string(sessionTargets[session.sessionIdentifier] ?? ""),
                 "connected": .bool(isConnected(session.inspectableApp)), "connectionGeneration": .integer(Int64(session.connectionGeneration)),
                 "hierarchyRevision": .integer(Int64(session.hierarchyRevision))])
    }

    func metadata(session: InspectionSession?, fromCache: Bool) -> InspectionMetadata {
        InspectionMetadata(serviceInstanceIdentifier: instanceIdentifier, sessionIdentifier: session?.sessionIdentifier,
                           connectionGeneration: session?.connectionGeneration, hierarchyRevision: session?.hierarchyRevision,
                           captureDate: session?.captureDate, fromCache: fromCache, requiresRefresh: session?.requiresRefresh)
    }

    func requiredString(_ name: String, in request: InspectionRequest) throws -> String {
        guard let value = request.parameters?[name]?.stringValue, !value.isEmpty else { throw InspectionFailure.invalidParameters }
        return value
    }

    func missingSession() -> InspectionFailure {
        InspectionFailure(code: "session.notFound", message: "The session does not belong to this service instance. Discover a target and open a session.")
    }

    func failure(for error: Error) -> InspectionFailure {
        if let failure = error as? InspectionFailure {
            return failure
        }
        if error is CancellationError {
            return InspectionFailure(code: "operation.cancelled", message: "The client cancelled its inspection request.")
        }
        let error = error as NSError
        if error.domain == RACSignalErrorDomain {
            return InspectionFailure(code: "operation.timeout", message: "Target discovery timed out.")
        }
        if error.code == LookinErrCode_LicenseRequired {
            return authorizationFailure()
        }
        if error.code == LookinErrCode_Timeout || error.code == LookinErrCode_PingFailForTimeout {
            return InspectionFailure(code: "operation.timeout", message: error.localizedDescription)
        }
        if let code = error.userInfo["inspectionFailureCode"] as? String {
            return InspectionFailure(code: code, message: error.localizedDescription)
        }
        if error.domain == InspectionSessionErrorDomain {
            switch error.code {
            case InspectionSessionErrorCode.staleConnection.rawValue: return InspectionFailure(code: "session.disconnected", message: error.localizedDescription)
            case InspectionSessionErrorCode.staleHierarchy.rawValue: return InspectionFailure(code: "session.stale", message: error.localizedDescription)
            default: break
            }
        }
        return InspectionFailure(code: "inspection.failed", message: error.localizedDescription)
    }
}
