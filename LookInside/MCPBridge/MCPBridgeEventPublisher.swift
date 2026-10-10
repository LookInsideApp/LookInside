// MCPBridgeEventPublisher.swift
//
// Turns host-side state changes into `MCPBridgeEvent` frames and hands
// them to `MCPBridgeServer.broadcast(event:)`.
//
// What belongs here, and what deliberately does not:
//
// Only things a bridge client cannot learn on its own get published. A
// client that calls a tool already has the tool's return value, so
// echoing the same fact back as an event would be noise at best and, at
// worst, read as independent news about the app.
//
// That rules out the data source's three item-change signals
// (`itemDidChangeAttrGroup`, `itemDidChangeHiddenAlphaValue`,
// `itemsDidChangeFrame`). All three fire only from inside
// `StaticHierarchyDataSource.modify(with:)`, which is
// the moment fetched detail lands in the cache -- and the fetch was
// almost always the caller's own `details.read` / `screenshot.read` /
// `attribute.modify`. Publishing them would tell a client "something
// changed" about a change it just made.
//
// `hierarchy.reloaded` is the one case where the client's own action and
// a human's produce the same signal, so it carries an `initiator` field
// instead of being dropped.
//
// What this publisher does NOT and cannot offer: notice that the
// inspected app's UI changed by itself. LookInside is a manual-refresh
// inspector; the host only learns the UI moved when someone asks it to
// look. Every topic here is about the *host's* state, never about the
// target app spontaneously changing. The CLI's resource descriptions say
// so in as many words, because a client that assumes otherwise will
// subscribe and then wait forever.
//
// Subscription filtering is not done here. The host stays ignorant of how
// many bridge clients exist and what each one cares about; it broadcasts
// to every open connection and lets each client filter. That keeps this
// file free of any Model Context Protocol concepts, which the GPL/MIT
// split requires.

import AppKit
import Foundation
import os
import FoundationToolbox

@Loggable(subsystem: "com.lookinside.app", category: "MCPBridge.Events")
@MainActor
final class MCPBridgeEventPublisher {

    /// Where finished events go. Injected rather than reaching for the
    /// server singleton so this type can be exercised without a socket.
    private let broadcast: @MainActor (MCPBridgeEvent) -> Void

    /// The channel-end and push listeners; they live as long as the
    /// publisher runs.
    private var connectionTasks: [Task<Void, Never>] = []

    /// One reload subscription per open live document. Documents come and
    /// go, so these are attached on open and cancelled on close; a stale one
    /// would keep publishing reloads for a window nobody can see.
    private var documentSubscriptions: [ObjectIdentifier: SyncSubscription] = [:]

    private var hasStarted = false

    init(broadcast: @escaping @MainActor (MCPBridgeEvent) -> Void) {
        self.broadcast = broadcast
    }

    // MARK: - Lifecycle

    /// Idempotent. The bridge server starts asynchronously and may be
    /// asked to start more than once over a process's life.
    func start() {
        guard hasStarted == false else { return }
        hasStarted = true

        subscribeToDocumentLifecycle()
        subscribeToConnectionManager()
        subscribeToActivationState()

        // Documents can already exist: a document opened by an auto-connect
        // environment variable races the bridge's start. Adopt whatever is
        // already open rather than only ever seeing the next one.
        for document in MCPBridgeLiveDocumentLookup.enumerateLiveDocuments() {
            attachReloadSubscription(to: document)
        }
    }

    func stop() {
        guard hasStarted else { return }
        hasStarted = false
        NotificationCenter.default.removeObserver(self)
        for task in connectionTasks {
            task.cancel()
        }
        connectionTasks.removeAll()
        for subscription in documentSubscriptions.values {
            subscription.cancel()
        }
        documentSubscriptions.removeAll()
    }

    // MARK: - Document lifecycle

    private func subscribeToDocumentLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDocumentDidOpen(_:)),
            name: LiveDocument.didOpenNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDocumentWillClose(_:)),
            name: LiveDocument.willCloseNotification,
            object: nil
        )
    }

    @objc private func handleDocumentDidOpen(_ notification: Notification) {
        guard let document = notification.object as? LiveDocument else { return }
        attachReloadSubscription(to: document)
        // Carries the whole target record rather than just an identifier:
        // a client that learns a target appeared will immediately want to
        // know what it is, and the round-trip back to `targets.list` buys
        // nothing the host does not already have in hand.
        broadcast(
            MCPBridgeEvent(
                topic: "targets.attached",
                payload: targetPayload(for: document)
            )
        )
    }

    @objc private func handleDocumentWillClose(_ notification: Notification) {
        guard let document = notification.object as? LiveDocument else { return }
        detachReloadSubscription(from: document)
        broadcast(
            MCPBridgeEvent(
                topic: "targets.detached",
                payload: targetPayload(for: document)
            )
        )
    }

    // MARK: - Per-document reload subscription

    private func attachReloadSubscription(to document: LiveDocument) {
        let key = ObjectIdentifier(document)
        guard documentSubscriptions[key] == nil else { return }
        guard let dataSource = document.hierarchyDataSource else { return }

        // `didReloadHierarchyInfo` is the data source's own announcement
        // that it has finished absorbing a new tree, so by the time this
        // fires the hierarchy a client would read is already the new one.
        // It is sent synchronously on the main thread, so the payload is
        // read before a later reload can overwrite `lastReloadInitiator`.
        documentSubscriptions[key] = dataSource.didReloadHierarchyInfo.observe { [weak self, weak document] in
            MainActor.assumeIsolated {
                guard let self, let document else { return }
                self.publishHierarchyReloaded(for: document)
            }
        }
    }

    private func detachReloadSubscription(from document: LiveDocument) {
        documentSubscriptions.removeValue(forKey: ObjectIdentifier(document))?.cancel()
    }

    private func publishHierarchyReloaded(for document: LiveDocument) {
        var payload = targetPayload(for: document)
        payload["nodeCount"] = .integer(Int64(document.hierarchyDataSource?.rawFlatItems?.count ?? 0))
        // `agent` means "a bridge client asked for this", so a client that
        // did the asking can recognize its own echo and ignore it. Only
        // `host` is news.
        let initiator = document.staticWindowController?.lastReloadInitiator ?? .host
        payload["initiator"] = .string(initiator == .agent ? "agent" : "host")
        broadcast(MCPBridgeEvent(topic: "hierarchy.reloaded", payload: payload))
    }

    // MARK: - Connection manager

    private func subscribeToConnectionManager() {
        let connectionManager = ConnectionManager.shared

        // A channel ending is the one thing here that is genuinely about
        // the target app rather than the host: the app was killed, the USB
        // cable came out, the simulator shut down. A client holding object
        // identifiers for that target needs to stop trusting them.
        let endedChannels = connectionManager.channelWillEndEvents()
        connectionTasks.append(Task { [weak self] in
            for await channel in endedChannels {
                self?.publishDisconnected(channel: channel)
            }
        })

        let pushes = connectionManager.pushEvents()
        connectionTasks.append(Task { [weak self] in
            for await push in pushes {
                self?.handleServerPush(push)
            }
        })
    }

    /// Resolves a channel back to the document that owns it, so an event can
    /// name a target identifier the client already knows rather than an
    /// opaque channel the bridge protocol never exposes.
    private func document(forChannel channel: ServerChannel) -> LiveDocument? {
        LiveDocumentController.shared.liveDocument(for: channel)
    }

    private func publishDisconnected(channel: ServerChannel) {
        guard let document = document(forChannel: channel) else { return }
        broadcast(
            MCPBridgeEvent(
                topic: "targets.disconnected",
                payload: targetPayload(for: document)
            )
        )
    }

    private func handleServerPush(_ push: ConnectionPush) {
        guard push.type == UInt32(LookinPush_SwiftUISupportDetected) else { return }
        var payload: [String: MCPBridgeJSONValue] = [:]
        if let document = document(forChannel: push.channel) {
            payload = targetPayload(for: document)
        }
        payload["capability"] = .string("swiftUI")
        broadcast(MCPBridgeEvent(topic: "capabilities.swiftUIDetected", payload: payload))
    }

    // MARK: - Activation state

    private func subscribeToActivationState() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActivationStateDidChange(_:)),
            name: SwiftUISupportGatekeeper.activationStateDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleActivationStateDidChange(_: Notification) {
        // Read silently: asking for protected-feature access would put an
        // activation window on screen, which an event handler must never do.
        let state = SwiftUISupportGatekeeper.sharedInstance().activationState
        broadcast(
            MCPBridgeEvent(
                topic: "license.stateChanged",
                payload: ["state": .string(Self.wireName(for: state))]
            )
        )
    }

    private static func wireName(for state: SwiftUISupportActivationState) -> String {
        switch state {
        case .activated:
            "activated"
        case .notActivated:
            "notActivated"
        case .unknown:
            "unknown"
        }
    }

    // MARK: - Payload helper

    /// The same target description `targets.list` returns, minus the
    /// fields that require a round-trip. Kept in one place so every topic
    /// names a target the same way.
    private func targetPayload(for document: LiveDocument) -> [String: MCPBridgeJSONValue] {
        var payload: [String: MCPBridgeJSONValue] = [:]
        guard let appInfo = document.inspectableApp.appInfo else {
            return payload
        }
        payload["targetIdentifier"] = .string(String(appInfo.appInfoIdentifier))
        if let applicationName = appInfo.appName, applicationName.isEmpty == false {
            payload["applicationName"] = .string(applicationName)
        }
        if let bundleIdentifier = appInfo.appBundleIdentifier, bundleIdentifier.isEmpty == false {
            payload["bundleIdentifier"] = .string(bundleIdentifier)
        }
        if let deviceDescription = appInfo.deviceDescription, deviceDescription.isEmpty == false {
            payload["deviceDescription"] = .string(deviceDescription)
        }
        if let operatingSystemDescription = appInfo.osDescription, operatingSystemDescription.isEmpty == false {
            payload["operatingSystemDescription"] = .string(operatingSystemDescription)
        }
        return payload
    }
}
