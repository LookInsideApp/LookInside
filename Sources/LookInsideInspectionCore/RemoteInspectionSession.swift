import Foundation
import LookInsideInspectionProtocol

/// A graphical projection of a service-owned session. The inherited cache is
/// updated only from verified transfers; every remote operation uses the socket.
@MainActor
@objc(LKRemoteInspectionSession)
public final class RemoteInspectionSession: InspectionSession {
    private let client: InspectionServiceClient
    private let targetIdentifier: String
    private let clientIdentifier = UUID().uuidString
    private var attachedIdentifier: String?
    private var attachedInstance: String?
    private var attachmentTask: Task<Void, Error>?
    private var reconciliationTask: Task<Void, Never>?
    private var needsReconciliation = false
    private var clientReferenceCount = 0
    private var targetIsDisconnected = false
    private var announcedConnectionGeneration: UInt64 = 0

    init(application: RemoteInspectableApp) {
        client = application.client
        targetIdentifier = application.targetIdentifier
        super.init(inspectableApp: application, captureOptions: [:])
        client.register(self)
    }

    deinit {
        let client = client
        let identifier = attachedIdentifier
        let instance = attachedInstance
        let owner = clientIdentifier
        reconciliationTask?.cancel()
        Task { @MainActor in
            if let identifier, client.connection.isConnected, client.serviceInstanceIdentifier == instance {
                _ = try? await client.connection.request("sessions.release", parameters: [
                    "sessionIdentifier": .string(identifier), "clientIdentifier": .string(owner),
                ])
            }
        }
    }

    override public func retainClientReference() {
        clientReferenceCount += 1
    }

    override public func releaseClientReference() {
        clientReferenceCount = max(0, clientReferenceCount - 1)
        guard clientReferenceCount == 0, let attachedIdentifier else { return }
        reconciliationTask?.cancel()
        Task {
            guard client.connection.isConnected else { return }
            _ = try? await client.connection.request("sessions.release", parameters: [
                "sessionIdentifier": .string(attachedIdentifier), "clientIdentifier": .string(clientIdentifier),
            ])
        }
    }

    func readOrCapture() -> RACSignal<AnyObject> {
        InspectionServiceClient.signal { try [await self.capture(fresh: false, initiator: "host")] }
    }

    override public func refreshHierarchy(initiator: String) -> RACSignal<AnyObject> {
        InspectionServiceClient.signal { try [await self.capture(fresh: true, initiator: initiator)] }
    }

    override public func updateCaptureOptions(_ options: [String: Any], initiator: String) -> RACSignal<AnyObject> {
        InspectionServiceClient.signal {
            try await self.attach()
            var parameters = self.parameters(requiringCurrentHierarchy: true)
            parameters["options"] = try JSONDecoder().decode(InspectionValue.self, from: JSONSerialization.data(withJSONObject: options))
            parameters["initiator"] = .string(initiator)
            let response = try await self.client.send("session.captureOptions", parameters: parameters)
            return try [await self.installHierarchy(response)]
        }
    }

    override public func detailResponses(packages: [LookinStaticAsyncUpdateTasksPackage]) -> RACSignal<AnyObject> {
        request(withType: UInt32(LookinRequestTypeHierarchyDetails), payload: packages)
    }

    override public func request(withType requestType: UInt32, payload: Any?) -> RACSignal<AnyObject> {
        InspectionServiceClient.signal {
            try await self.attach()
            var parameters = self.parameters(requiringCurrentHierarchy: true)
            parameters["requestType"] = .integer(Int64(requestType))
            if let payload {
                let archive = try InspectionModelArchive.encode(payload)
                parameters["payloadTransferIdentifier"] = try .string(await self.client.connection.upload(archive))
            }
            do {
                let response = try await self.client.send("session.request", parameters: parameters)
                guard let model = try await self.client.model(from: response) as? [String: Any] else { throw InspectionSignalError.invalidResponse }
                let state = try self.state(from: response)
                let values = model["values"] as? [AnyObject] ?? []
                let details = values.flatMap { value -> [LookinDisplayItemDetail] in
                    if let detail = value as? LookinDisplayItemDetail {
                        return [detail]
                    }
                    return value as? [LookinDisplayItemDetail] ?? []
                }
                try self.validate(state: state, allowingNewHierarchy: false)
                self.applyMirroredHierarchy(nil, details: details, state: state)
                if let error = model["error"] as? NSError {
                    throw error
                }
                return values
            } catch {
                if [204, 206, 209, 214].contains(requestType),
                   error is CancellationError || (error as? InspectionFailure)?.code == "service.disconnected"
                   || (error as? InspectionFailure)?.code == "operation.timeout"
                {
                    self.markMirrorDisconnected("The operation's result is unknown. Refresh before retrying.")
                    throw NSError(domain: InspectionSessionErrorDomain, code: InspectionSessionErrorCode.executionUnknown.rawValue,
                                  userInfo: [NSLocalizedDescriptionKey: "The target may have executed the operation. Do not retry automatically.", NSUnderlyingErrorKey: error])
                }
                throw error
            }
        }
    }

    private func attach() async throws {
        try await client.connect()
        if let attachmentTask {
            return try await attachmentTask.value
        }
        if attachedIdentifier != nil {
            guard attachedInstance == client.serviceInstanceIdentifier else {
                throw InspectionFailure(code: "service.restarted", message: "Select the target again after the service restarts.")
            }
            return
        }
        let task = Task {
            defer { attachmentTask = nil }
            var parameters: [String: InspectionValue] = [
                "targetIdentifier": .string(targetIdentifier), "clientIdentifier": .string(clientIdentifier),
            ]
            if let options = client.initialCaptureOptionsProvider?() {
                parameters["initialCaptureOptions"] = try JSONDecoder().decode(InspectionValue.self,
                                                                               from: JSONSerialization.data(withJSONObject: options))
            }
            let response = try await client.send("targets.attach", parameters: parameters)
            guard let identifier = response.result?.objectValue?["targetIdentifier"]?.stringValue else { throw InspectionSignalError.invalidResponse }
            attachedIdentifier = identifier
            attachedInstance = client.serviceInstanceIdentifier
            try applyMirroredHierarchy(nil, details: nil, state: state(from: response))
        }
        attachmentTask = task
        try await task.value
    }

    private func capture(fresh: Bool, initiator: String) async throws -> LookinHierarchyInfo {
        try await attach()
        var parameters = parameters(requiringCurrentHierarchy: false)
        parameters["fresh"] = .bool(fresh)
        parameters["initiator"] = .string(initiator)
        return try await installHierarchy(client.send("hierarchy.capture", parameters: parameters))
    }

    private func installHierarchy(_ response: InspectionResponse) async throws -> LookinHierarchyInfo {
        guard let hierarchy = try await client.model(from: response) as? LookinHierarchyInfo else { throw InspectionSignalError.invalidResponse }
        let state = try state(from: response)
        try validate(state: state, allowingNewHierarchy: true)
        applyMirroredHierarchy(hierarchy, details: nil, state: state)
        return try readHierarchy()
    }

    private func parameters(requiringCurrentHierarchy: Bool) -> [String: InspectionValue] {
        var result: [String: InspectionValue] = [
            "sessionIdentifier": .string(attachedIdentifier ?? sessionIdentifier),
            "serviceInstanceIdentifier": .string(attachedInstance ?? ""),
            "clientIdentifier": .string(clientIdentifier),
        ]
        if requiringCurrentHierarchy {
            result["connectionGeneration"] = .integer(Int64(connectionGeneration))
            result["hierarchyRevision"] = .integer(Int64(hierarchyRevision))
        }
        return result
    }

    private func state(from response: InspectionResponse) throws -> [String: Any] {
        guard let value = response.result?.objectValue?["session"],
              let state = try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any]
        else { throw InspectionSignalError.invalidResponse }
        return state
    }

    private func validate(state: [String: Any], allowingNewHierarchy: Bool) throws {
        guard !targetIsDisconnected else {
            throw InspectionFailure(code: "session.disconnected", message: "The target disconnected while its model was being transferred.")
        }
        guard state["sessionIdentifier"] as? String == attachedIdentifier,
              let generation = state["connectionGeneration"] as? UInt64,
              let revision = state["hierarchyRevision"] as? UInt64,
              generation >= connectionGeneration,
              generation >= announcedConnectionGeneration,
              generation > connectionGeneration || revision >= hierarchyRevision,
              allowingNewHierarchy || (generation == connectionGeneration && revision == hierarchyRevision)
        else { throw InspectionFailure(code: "session.stale", message: "The model belongs to an earlier hierarchy. Read the current snapshot again.") }
    }

    func receive(_ event: InspectionEvent) {
        guard event.payload?["targetIdentifier"]?.stringValue == attachedIdentifier else { return }
        if let generation = event.payload?["connectionGeneration"]?.integerValue, generation >= 0 {
            announcedConnectionGeneration = max(announcedConnectionGeneration, UInt64(generation))
        }
        if event.topic == "targets.disconnected" {
            targetIsDisconnected = true
            needsReconciliation = false
            markMirrorDisconnected("The inspected application disconnected.")
            return
        }
        if event.topic == "targets.reconnected" {
            targetIsDisconnected = false
        }
        guard ["hierarchy.reloaded", "hierarchy.detailsChanged", "targets.reconnected"].contains(event.topic),
              event.payload?["clientIdentifier"]?.stringValue != clientIdentifier else { return }
        needsReconciliation = true
        guard reconciliationTask == nil else { return }
        reconciliationTask = Task { [weak self] in
            guard let self else { return }
            defer { reconciliationTask = nil }
            while needsReconciliation, !targetIsDisconnected, !Task.isCancelled {
                needsReconciliation = false
                do {
                    let response = try await client.send("session.state", parameters: parameters(requiringCurrentHierarchy: false))
                    if response.metadata?.connectionGeneration != connectionGeneration || response.metadata?.hierarchyRevision != hierarchyRevision {
                        _ = try await capture(fresh: false, initiator: "host")
                    } else {
                        let detailsResponse = try await client.send("hierarchy.cachedDetails", parameters: parameters(requiringCurrentHierarchy: true))
                        guard let details = try await client.model(from: detailsResponse) as? [LookinDisplayItemDetail] else { throw InspectionSignalError.invalidResponse }
                        let state = try state(from: detailsResponse)
                        try validate(state: state, allowingNewHierarchy: false)
                        applyMirroredHierarchy(nil, details: details, state: state)
                    }
                } catch let failure as InspectionFailure where failure.code == "session.stale" {
                    needsReconciliation = true
                } catch {
                    if !Task.isCancelled {
                        markMirrorDisconnected(error.localizedDescription)
                    }
                }
            }
        }
    }
}
