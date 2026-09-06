// Publishes inspection-session state. Target UI changes remain observable only
// after an explicit capture or an existing server push.

import Foundation

@MainActor
public final class LKMCPBridgeEventPublisher {
    private let broadcast: @MainActor (LKMCPBridgeEvent) -> Void
    private var globalDisposables: [RACDisposable] = []
    private var hasStarted = false

    public init(broadcast: @escaping @MainActor (LKMCPBridgeEvent) -> Void) {
        self.broadcast = broadcast
    }

    private static func onMainActor(_ body: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { body() }
        } else {
            Task { @MainActor in body() }
        }
    }

    public func start() {
        guard !hasStarted else { return }
        hasStarted = true
        let notifications = NotificationCenter.default
        notifications.addObserver(self, selector: #selector(sessionDidOpen(_:)),
                                  name: InspectionSession.didOpenNotification, object: nil)
        notifications.addObserver(self, selector: #selector(sessionDidClose(_:)),
                                  name: InspectionSession.didCloseNotification, object: nil)
        notifications.addObserver(self, selector: #selector(sessionDidReload(_:)),
                                  name: InspectionSession.didReloadNotification, object: nil)
        notifications.addObserver(self, selector: #selector(sessionDidDisconnect(_:)),
                                  name: InspectionSession.didDisconnectNotification, object: nil)
        notifications.addObserver(self, selector: #selector(activationStateDidChange(_:)),
                                  name: LKSwiftUISupportGatekeeper.activationStateDidChangeNotification, object: nil)
        if let connectionManager = ConnectionManager.sharedInstance() {
            let subscription = connectionManager.didReceivePush.subscribeNext { [weak self] value in
                Self.onMainActor {
                    guard let self, let message = value as? RACTuple,
                          let requestType = message.second as? NSNumber,
                          requestType.uint32Value == 305
                    else { return }
                    let channel = message.first as? Lookin_PTChannel
                    let session = InspectionSessionLookup.enumerateSessions().first {
                        $0.inspectableApp.channel === channel
                    }
                    var payload = self.targetPayload(for: session?.inspectableApp.appInfo)
                    payload["capability"] = .string("swiftUI")
                    self.broadcast(LKMCPBridgeEvent(topic: "capabilities.swiftUIDetected", payload: payload))
                }
            }
            globalDisposables.append(subscription)
        }
    }

    public func stop() {
        guard hasStarted else { return }
        hasStarted = false
        NotificationCenter.default.removeObserver(self)
        for subscription in globalDisposables {
            subscription.dispose()
        }
        globalDisposables.removeAll()
    }

    @objc private func sessionDidOpen(_ notification: Notification) {
        guard let session = notification.object as? InspectionSession else { return }
        broadcast(LKMCPBridgeEvent(topic: "targets.attached", payload: targetPayload(for: session.inspectableApp.appInfo)))
    }

    @objc private func sessionDidClose(_ notification: Notification) {
        let applicationInfo = notification.userInfo?["appInfo"] as? LookinAppInfo
        Self.onMainActor { [weak self] in
            guard let self else { return }
            self.broadcast(LKMCPBridgeEvent(topic: "targets.detached", payload: self.targetPayload(for: applicationInfo)))
        }
    }

    @objc private func sessionDidReload(_ notification: Notification) {
        guard let session = notification.object as? InspectionSession else { return }
        var payload = targetPayload(for: session.inspectableApp.appInfo)
        payload["nodeCount"] = .integer(Int64(session.rawFlatItems?.count ?? 0))
        payload["initiator"] = .string(session.lastReloadInitiator)
        broadcast(LKMCPBridgeEvent(topic: "hierarchy.reloaded", payload: payload))
    }

    @objc private func sessionDidDisconnect(_ notification: Notification) {
        guard let session = notification.object as? InspectionSession else { return }
        broadcast(LKMCPBridgeEvent(topic: "targets.disconnected", payload: targetPayload(for: session.inspectableApp.appInfo)))
    }

    @objc private func activationStateDidChange(_: Notification) {
        let state = LKSwiftUISupportGatekeeper.sharedInstance().activationState
        let stateName: String
        switch state {
        case .activated: stateName = "activated"
        case .notActivated: stateName = "notActivated"
        case .unknown: stateName = "unknown"
        @unknown default: stateName = "unknown"
        }
        broadcast(LKMCPBridgeEvent(topic: "license.stateChanged", payload: ["state": .string(stateName)]))
    }

    private func targetPayload(for applicationInfo: LookinAppInfo?) -> [String: LKMCPBridgeJSONValue] {
        guard let applicationInfo else { return [:] }
        var payload: [String: LKMCPBridgeJSONValue] = [
            "targetIdentifier": .string(String(applicationInfo.appInfoIdentifier)),
        ]
        if let name = applicationInfo.appName, !name.isEmpty {
            payload["applicationName"] = .string(name)
        }
        if let identifier = applicationInfo.appBundleIdentifier, !identifier.isEmpty {
            payload["bundleIdentifier"] = .string(identifier)
        }
        if let description = applicationInfo.deviceDescription, !description.isEmpty {
            payload["deviceDescription"] = .string(description)
        }
        if let description = applicationInfo.osDescription, !description.isEmpty {
            payload["operatingSystemDescription"] = .string(description)
        }
        return payload
    }
}
