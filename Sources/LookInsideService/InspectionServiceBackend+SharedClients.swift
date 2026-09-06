import Foundation
import LookInsideInspectionCore
import LookInsideInspectionProtocol

extension InspectionServiceBackend {
    static let sharedMethods = ["authorization.request", "targets.models", "targets.attach", "targets.detach", "sessions.retain", "sessions.release",
                                "session.state", "session.events", "session.request", "session.captureOptions", "hierarchy.capture", "hierarchy.details", "hierarchy.cachedDetails",
                                "transfer.begin", "transfer.append", "transfer.read", "transfer.release"]

    func handle(_ request: InspectionRequest, clientIdentifier: String) async -> InspectionResponse {
        InspectionEnvironment.shared().operationContextProvider = { InspectionOperationContext.values }
        observeSharedEvents()
        let logicalIdentifier = request.parameters?["clientIdentifier"]?.stringValue ?? clientIdentifier
        let owner = logicalIdentifier == clientIdentifier ? clientIdentifier : clientIdentifier + ":" + logicalIdentifier
        let context = ["clientIdentifier": logicalIdentifier, "operationIdentifier": request.identifier]
        return await InspectionOperationContext.$values.withValue(context) {
            if request.method.hasPrefix("transfer.") || Self.sharedMethods.contains(request.method) {
                return await handleShared(request, connectionIdentifier: clientIdentifier, owner: owner)
            }
            if request.method == "ping" || request.method == "targets.list"
                || (request.parameters?["sessionIdentifier"] == nil
                    && InspectionCompatibilityRoutes.methods.contains(request.method))
            {
                return await handleCompatibility(request, owner: owner)
            }
            let response = await handleCommand(request, clientIdentifier: owner)
            if response.error == nil, request.method == "sessions.open",
               let identifier = response.metadata?.sessionIdentifier, let session = sessions[identifier]
            {
                publishSessionEvent("targets.attached", session: session, context: context)
            } else if response.error == nil, request.method == "sessions.close" {
                publish?(InspectionEvent(topic: "targets.detached", payload: [
                    "targetIdentifier": .string(response.metadata?.sessionIdentifier ?? ""),
                    "clientIdentifier": .string(logicalIdentifier), "operationIdentifier": .string(request.identifier),
                ]))
            }
            return response
        }
    }

    private func handleCompatibility(_ request: InspectionRequest, owner: String) async -> InspectionResponse {
        var session: InspectionSession?
        var committedMetadata: InspectionMetadata?
        var committedState: InspectionValue?
        let context = InspectionOperationContext.values
        let receipts = [InspectionSession.didReloadNotification, InspectionSession.didUpdateNotification].map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { notification in
                guard let completedSession = notification.object as? InspectionSession else { return }
                MainActor.assumeIsolated {
                    guard completedSession.lastOperationContext == context else { return }
                    committedMetadata = self.metadata(session: completedSession, fromCache: false)
                    committedState = self.state(completedSession)
                }
            }
        }
        defer { for receipt in receipts {
            NotificationCenter.default.removeObserver(receipt)
        } }
        do {
            if let targetIdentifier = request.parameters?["targetIdentifier"]?.stringValue {
                session = sessions[targetIdentifier]
                if session == nil, let legacyIdentifier = UInt(targetIdentifier) {
                    let matches = sessions.values.filter { $0.inspectableApp.appInfo?.appInfoIdentifier == legacyIdentifier }
                    if matches.count == 1 {
                        session = matches.first
                    }
                }
                if let session {
                    try validateSession(session, request: request)
                    sessionClients[session.sessionIdentifier, default: []].insert(owner)
                    if session.captureDate == nil, request.method != "hierarchy.refresh" {
                        try await ensureInitialCapture(session)
                    }
                }
            }
            let response = await compatibility.handle(request, sessions: Array(sessions.values))
            var result = response.result
            if ["invoke.method", "attribute.modify"].contains(request.method), var object = result?.objectValue, let session {
                var operationState = (committedState ?? state(session)).objectValue ?? [:]
                operationState["serviceInstanceIdentifier"] = .string(instanceIdentifier)
                object["inspectionState"] = .object(operationState)
                result = .object(object)
            }
            return InspectionResponse(identifier: response.identifier, result: result, error: response.error,
                                      metadata: committedMetadata ?? metadata(session: session, fromCache: ["ping", "targets.list", "hierarchy.read", "hierarchy.find", "attributes.read"].contains(request.method)))
        } catch {
            return .init(identifier: request.identifier, result: nil, error: failure(for: error),
                         metadata: metadata(session: session, fromCache: true))
        }
    }

    private func handleShared(_ request: InspectionRequest, connectionIdentifier: String, owner: String) async -> InspectionResponse {
        var session: InspectionSession?
        var fromCache = true
        var responseMetadata: InspectionMetadata?
        do {
            let result: InspectionValue
            switch request.method {
            case "authorization.request":
                guard let envelope = request.parameters?["request"], let authorizationRequest else { throw InspectionFailure.invalidParameters }
                result = try .object(["response": await authorizationRequest(envelope)])
            case "transfer.begin":
                guard let manifest = request.parameters?["manifest"] else { throw InspectionFailure.invalidParameters }
                try transfers.beginUpload(manifest.decode(InspectionTransferManifest.self), owner: connectionIdentifier)
                result = .object(["accepted": .bool(true)])
            case "transfer.append":
                let identifier = try requiredString("transferIdentifier", in: request)
                let encoded = try requiredString("data", in: request)
                guard encoded.utf8.count <= (InspectionTransferStore.maximumChunkByteCount + 2) / 3 * 4,
                      let data = Data(base64Encoded: encoded),
                      let offset = request.parameters?["offset"]?.integerValue, offset >= 0, offset <= Int64(Int.max)
                else { throw InspectionFailure.invalidParameters }
                try transfers.append(data, offset: Int(offset), identifier: identifier, owner: connectionIdentifier)
                result = .object(["accepted": .bool(true)])
            case "transfer.read":
                let identifier = try requiredString("transferIdentifier", in: request)
                guard let offset = request.parameters?["offset"]?.integerValue, offset >= 0, offset <= Int64(Int.max)
                else { throw InspectionFailure.invalidParameters }
                let data = try transfers.read(identifier: identifier, offset: Int(offset), owner: connectionIdentifier)
                result = .object(["offset": .integer(offset), "data": .string(data.base64EncodedString())])
            case "transfer.release":
                try transfers.release(identifier: requiredString("transferIdentifier", in: request), owner: connectionIdentifier)
                result = .object(["released": .bool(true)])
            case "targets.models":
                _ = try await discover()
                let models: [[String: Any]] = targets.keys.sorted().compactMap { identifier in
                    guard let application = targets[identifier], isConnected(application), let information = application.appInfo else { return nil }
                    return ["targetIdentifier": identifier, "appInfo": information,
                            "transportIdentifier": application.transportIdentifier ?? "unknown"]
                }
                result = try modelResult(models, owner: connectionIdentifier, session: nil)
            case "targets.attach":
                let response = await handleCommand(InspectionRequest(identifier: request.identifier, method: "sessions.open",
                                                                     parameters: request.parameters), clientIdentifier: owner)
                guard response.error == nil, let identifier = response.metadata?.sessionIdentifier,
                      let attached = sessions[identifier] else { return response }
                session = attached
                publishSessionEvent("targets.attached", session: attached, context: InspectionOperationContext.values)
                result = .object(["targetIdentifier": .string(identifier), "session": state(attached)])
            case "session.events":
                result = .object(["subscribed": .bool(true)])
            default:
                let identifier = request.parameters?["sessionIdentifier"]?.stringValue ?? request.parameters?["targetIdentifier"]?.stringValue
                guard let identifier, let existing = sessions[identifier] else { throw missingSession() }
                session = existing
                if request.method == "sessions.release" || request.method == "targets.detach" {
                    sessionClients[identifier]?.remove(owner)
                    result = .object(["released": .bool(true), "targetIdentifier": .string(identifier)])
                } else {
                    if request.method != "session.state" {
                        try validateSession(existing, request: request)
                    }
                    sessionClients[identifier, default: []].insert(owner)
                    switch request.method {
                    case "sessions.retain", "session.state": result = state(existing)
                    case "hierarchy.cachedDetails":
                        result = try modelResult(existing.accumulatedDetails, owner: connectionIdentifier, session: existing)
                    case "hierarchy.capture":
                        if request.parameters?["fresh"]?.booleanValue == true {
                            _ = try await InspectionSignalAwaiter.allValues(
                                of: existing.refreshHierarchy(initiator: request.parameters?["initiator"]?.stringValue ?? "host"),
                                as: LookinHierarchyInfo.self
                            )
                            fromCache = false
                        } else if existing.captureDate == nil {
                            try await ensureInitialCapture(existing, initiator: request.parameters?["initiator"]?.stringValue ?? "host")
                            fromCache = false
                        }
                        result = try modelResult(existing.readHierarchy(), owner: connectionIdentifier, session: existing, fromCache: fromCache)
                    case "session.captureOptions":
                        guard request.parameters?["connectionGeneration"]?.integerValue != nil,
                              request.parameters?["hierarchyRevision"]?.integerValue != nil,
                              let options = request.parameters?["options"],
                              let dictionary = try JSONSerialization.jsonObject(with: JSONEncoder().encode(options)) as? [String: Any]
                        else { throw InspectionFailure.invalidParameters }
                        _ = try await InspectionSignalAwaiter.allValues(
                            of: existing.updateCaptureOptions(dictionary, initiator: request.parameters?["initiator"]?.stringValue ?? "host"),
                            as: LookinHierarchyInfo.self
                        )
                        fromCache = false
                        result = try modelResult(existing.readHierarchy(), owner: connectionIdentifier, session: existing, fromCache: false)
                    case "session.request", "hierarchy.details":
                        let requestType = request.method == "hierarchy.details" ? 203 : request.parameters?["requestType"]?.integerValue
                        guard let requestType, [203, 204, 205, 206, 207, 208, 209, 213, 214].contains(requestType) else {
                            throw InspectionFailure.invalidParameters
                        }
                        var payload: Any?
                        if let transferIdentifier = request.parameters?["payloadTransferIdentifier"]?.stringValue {
                            payload = try InspectionModelArchive.decode(transfers.consumeUpload(identifier: transferIdentifier, owner: connectionIdentifier))
                        }
                        let responseModel: [String: Any]
                        var committedState: InspectionValue?
                        let signal = existing.request(withType: UInt32(requestType), payload: payload)
                            .doCompleted {
                                responseMetadata = self.metadata(session: existing, fromCache: false)
                                committedState = self.state(existing)
                            }.doError { _ in
                                responseMetadata = self.metadata(session: existing, fromCache: false)
                                committedState = self.state(existing)
                            }
                        do {
                            let responses = try await InspectionSignalAwaiter.allValues(
                                of: signal, as: AnyObject.self
                            )
                            responseModel = ["values": responses]
                        } catch {
                            // The graphical client still receives the target's original NSError.
                            responseModel = ["error": error as NSError]
                        }
                        fromCache = false
                        result = try modelResult(responseModel, owner: connectionIdentifier, session: existing,
                                                 fromCache: false, committedMetadata: responseMetadata, committedState: committedState)
                    default: throw InspectionFailure.unknownMethod
                    }
                }
            }
            return .init(identifier: request.identifier, result: result, error: nil, metadata: responseMetadata ?? metadata(session: session, fromCache: fromCache))
        } catch {
            return .init(identifier: request.identifier, result: nil, error: failure(for: error), metadata: metadata(session: session, fromCache: true))
        }
    }

    private func modelResult(_ model: Any, owner: String, session: InspectionSession?, fromCache: Bool = true,
                             committedMetadata: InspectionMetadata? = nil, committedState: InspectionValue? = nil) throws -> InspectionValue
    {
        let archive = try InspectionModelArchive.encode(model)
        let manifest = try transfers.publish(archive, owner: owner, metadata: committedMetadata ?? metadata(session: session, fromCache: fromCache))
        var result: [String: InspectionValue] = try ["transfer": .encoding(manifest)]
        if let session {
            result["session"] = committedState ?? state(session)
        }
        return .object(result)
    }

    private func state(_ session: InspectionSession) -> InspectionValue {
        var result = sessionDescription(session).objectValue ?? [:]
        result["applicationName"] = .string(session.inspectableApp.appInfo?.appName ?? "")
        result["transportIdentifier"] = .string(session.inspectableApp.transportIdentifier ?? "")
        result["capabilities"] = .object([
            "basicInspection": .bool(true),
            "swiftUI": .bool(ConnectionManager.sharedInstance().isLicenseVerified(for: session.inspectableApp.channel)),
        ])
        result["requiresRefresh"] = .bool(session.requiresRefresh)
        result["captureOptions"] = .object([:])
        // JSONSerialization preserves the Foundation values used by the core options.
        if let encoded = try? JSONSerialization.data(withJSONObject: session.captureOptions),
           let options = try? JSONDecoder().decode(InspectionValue.self, from: encoded)
        {
            result["captureOptions"] = options
        }
        result["captureDate"] = session.captureDate.map { .double($0.timeIntervalSinceReferenceDate) } ?? .null
        result["connectionLossBannerMessage"] = session.connectionLossBannerMessage.map(InspectionValue.string) ?? .null
        result["lastReloadInitiator"] = .string(session.lastReloadInitiator)
        return .object(result)
    }

    private func validateSession(_ session: InspectionSession, request: InspectionRequest) throws {
        guard isConnected(session.inspectableApp), session.connectionLossBannerMessage == nil else {
            throw InspectionFailure(code: "session.disconnected", message: "The target disconnected. Discover and attach again.")
        }
        if let instance = request.parameters?["serviceInstanceIdentifier"]?.stringValue, instance != instanceIdentifier {
            throw InspectionFailure(code: "service.restarted", message: "This request belongs to an earlier service instance.")
        }
        if let generation = request.parameters?["connectionGeneration"]?.integerValue,
           generation < 0 || UInt64(generation) != session.connectionGeneration
        {
            throw InspectionFailure(code: "session.stale", message: "The target connection changed.")
        }
        if let revision = request.parameters?["hierarchyRevision"]?.integerValue,
           revision < 0 || UInt64(revision) != session.hierarchyRevision
        {
            throw InspectionFailure(code: "session.stale", message: "The hierarchy changed. Read it before changing capture options or remote objects.")
        }
    }

    private func observeSharedEvents() {
        guard observers.isEmpty else { return }
        pushSubscription = ConnectionManager.sharedInstance().didReceivePush.subscribeNext { [weak self] value in
            MainActor.assumeIsolated {
                guard let self, let message = value as? RACTuple,
                      (message.second as? NSNumber)?.uint32Value == 305,
                      let channel = message.first as? Lookin_PTChannel,
                      let session = self.sessions.values.first(where: { $0.inspectableApp.channel === channel }) else { return }
                self.publishSessionEvent("capabilities.swiftUIDetected", session: session, context: [:])
            }
        }
        let topics: [(Notification.Name, String)] = [
            (InspectionSession.didReloadNotification, "hierarchy.reloaded"),
            (InspectionSession.didUpdateNotification, "hierarchy.detailsChanged"),
            (InspectionSession.didDisconnectNotification, "targets.disconnected"),
            (InspectionSession.didReconnectNotification, "targets.reconnected"),
        ]
        for (name, topic) in topics {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                guard let session = notification.object as? InspectionSession else { return }
                MainActor.assumeIsolated {
                    guard let self, self.sessions[session.sessionIdentifier] != nil else { return }
                    self.publishSessionEvent(topic, session: session, context: session.lastOperationContext)
                }
            })
        }
    }

    private func publishSessionEvent(_ topic: String, session: InspectionSession, context: [String: String]) {
        if topic == "targets.reconnected", let targetIdentifier = sessionTargets[session.sessionIdentifier] {
            targets[targetIdentifier] = session.inspectableApp
        }
        var payload = state(session).objectValue ?? [:]
        payload["targetIdentifier"] = .string(session.sessionIdentifier)
        payload["serviceInstanceIdentifier"] = .string(instanceIdentifier)
        payload["nodeCount"] = .integer(Int64(session.rawFlatItems?.count ?? 0))
        payload["initiator"] = .string(session.lastReloadInitiator)
        for (name, value) in context {
            payload[name] = .string(value)
        }
        publish?(InspectionEvent(topic: topic, payload: payload))
    }
}
