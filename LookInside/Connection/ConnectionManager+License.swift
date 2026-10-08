//
//  ConnectionManager+License.swift
//  LookInside
//
//  The 220 LicenseChallenge / 221 LicenseVerify handshake that unlocks the
//  licensed features on one channel. A request on a channel without a
//  handshake still runs; the Server then withholds those features.
//

import Foundation
import LookInsideHostCore

extension ConnectionManager {
    /// Makes sure the license handshake has run on `channel`, then calls
    /// `completion` with whether the channel is licensed. Concurrent callers
    /// share one handshake.
    ///
    /// - Parameter force: run a new handshake even when the channel is
    ///   already licensed (the activation changed).
    func ensureLicenseHandshake(on channel: ServerChannel?, force: Bool, completion: ((Bool) -> Void)?) {
        guard let channel, channel.isConnected else {
            completion?(false)
            return
        }
        let state = channel.connectionState
        let gatekeeper = SwiftUISupportGatekeeper.sharedInstance()
        let admission = state.licenseHandshake.admit(
            force: force,
            isActivated: gatekeeper.activationState == .activated,
            completion: completion
        )
        guard admission == .mayStart else { return }

        // The activation runtime's signing policy holds handshakes back
        // before the first window, after a refused keychain prompt, and on a
        // channel whose handshake already failed. The request then runs
        // unlicensed.
        guard gatekeeper.shouldStartLicenseHandshake(onChannel: state.licenseChannelID) else {
            state.licenseHandshake.finish(verified: false)
            return
        }

        state.licenseHandshake.markStarted()
        let environment = ServerChannelLicenseEnvironment(channel: channel, manager: self)
        LicenseHandshakeFlow.run(in: environment, channelDescription: String(format: "%p", channel)) { failure in
            if let failure {
                let error = ConnectionError.licenseHandshakeError(failure)
                NSLog(
                    "LookinClient - license handshake failed, domain:%@, code:%@, description:%@",
                    error.domain,
                    NSNumber(value: error.code),
                    error.localizedDescription
                )
            }
            state.licenseHandshake.finish(verified: failure == nil)
        }
    }

    // MARK: - Activation changes

    /// The license was activated, changed or lost. Without a license every
    /// channel loses its licensed state; with one, every connected channel
    /// runs a new handshake.
    func handleActivationStateDidChange() {
        let channels = connectedChannels()
        guard SwiftUISupportGatekeeper.sharedInstance().activationState == .activated else {
            for channel in channels {
                channel.connectionState.licenseHandshake.revokeVerification()
            }
            return
        }
        for channel in channels {
            ensureLicenseHandshake(on: channel, force: true) { verified in
                NSLog("LookinClient - activation-state license handshake finished, verified:%@", NSNumber(value: verified))
            }
        }
    }

    /// Handshakes that the signing policy held back may start: the first
    /// window appeared, Try Again or the keychain explainer cleared the wait
    /// after a refused keychain prompt, or that wait ended. Each connected
    /// channel that is not licensed tries once, through the policy; channels
    /// that are already licensed are left alone.
    func handleLicenseHandshakeAvailabilityDidChange() {
        guard SwiftUISupportGatekeeper.sharedInstance().activationState == .activated else { return }
        for channel in connectedChannels() {
            ensureLicenseHandshake(on: channel, force: false) { verified in
                NSLog("LookinClient - resumed license handshake finished, verified:%@", NSNumber(value: verified))
            }
        }
    }
}

/// The Host side of `LicenseHandshakeFlow` for one channel: Lookin
/// frames through the connection manager, and the activation runtime's
/// signing policy and license key through the gatekeeper.
@MainActor
private final class ServerChannelLicenseEnvironment: LicenseHandshakeEnvironment {
    private let channel: ServerChannel
    private let manager: ConnectionManager
    private let channelID: String
    private let timeoutInterval: TimeInterval

    init(channel: ServerChannel, manager: ConnectionManager) {
        self.channel = channel
        self.manager = manager
        channelID = channel.connectionState.licenseChannelID
        timeoutInterval = PreferenceManager.shared.licenseHandshakeTimeoutInterval
    }

    var isChannelConnected: Bool {
        channel.isConnected
    }

    func now() -> TimeInterval {
        Date().timeIntervalSince1970
    }

    func shouldStartHandshake() -> Bool {
        SwiftUISupportGatekeeper.sharedInstance().shouldStartLicenseHandshake(onChannel: channelID)
    }

    func noteHandshakeFailed() {
        SwiftUISupportGatekeeper.sharedInstance().noteLicenseHandshakeFailed(onChannel: channelID)
    }

    func sendChallenge(completion: @escaping (LicenseExchangeResult) -> Void) {
        send(type: UInt32(LookinRequestTypeLicenseChallenge), data: nil, completion: completion)
    }

    func sendVerify(_ request: LicenseVerifyRequest, completion: @escaping (LicenseExchangeResult) -> Void) {
        // The 221 carries the challenge's own nonce and server instance id
        // objects back, as the Objective-C Host did.
        let challengePayload = request.challengePayload as? NSDictionary
        let nonce = (challengePayload?["nonce"] as? NSData) ?? (request.challenge.nonce as NSData)
        let serverInstanceID = (challengePayload?["server_instance_id"] as? NSString)
            ?? (request.challenge.serverInstanceID as NSString)
        let payload = NSDictionary(
            objects: [
                nonce,
                serverInstanceID,
                request.signature as NSData,
                request.intermediateCertificateDER as NSData,
                request.udid as NSString,
            ],
            forKeys: [
                "nonce" as NSString,
                "server_instance_id" as NSString,
                "signature" as NSString,
                "intermediate_cert_der" as NSString,
                "udid" as NSString,
            ]
        )
        send(type: UInt32(LookinRequestTypeLicenseVerify), data: payload, completion: completion)
    }

    /// Signing blocks until the key is free and the keychain answers,
    /// possibly behind a prompt, so it runs off the main thread.
    func sign(_ challenge: LicenseChallenge, completion: @escaping (LicenseSigning) -> Void) {
        let channelID = channelID
        let signed = MainThreadCallback(completion)
        DispatchQueue.global(qos: .userInitiated).async {
            let signing = Self.signChallenge(challenge, channelID: channelID)
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    signed.callback(signing)
                }
            }
        }
    }

    func noteServerRelease(_ release: ServerRelease) {
        ServerUpgradeHint.noteRelease(release, on: channel)
    }

    func log(_ message: String) {
        NSLog("%@", message)
    }

    private func send(type: UInt32, data: NSObject?, completion: @escaping (LicenseExchangeResult) -> Void) {
        let sink = ResponseSink { event in
            switch event {
            case let .response(attachment):
                completion(.response(error: attachment?.error as NSError?, payload: attachment?.data))
            case let .failure(error):
                completion(.transportFailure(error))
            case .completion:
                break
            }
        }
        manager.sendFrame(type: type, channel: channel, data: data, timeoutInterval: timeoutInterval, sink: sink)
    }

    private nonisolated static func signChallenge(_ challenge: LicenseChallenge, channelID: String) -> LicenseSigning {
        var signature: NSData?
        var intermediateCertDER: NSData?
        var udid: NSString?
        var keyUseDuration: TimeInterval = 0
        var failureDescription: String?
        do {
            try SwiftUISupportGatekeeper.sharedInstance().signChallenge(
                nonce: challenge.nonce,
                serverInstanceID: challenge.serverInstanceID,
                channelID: channelID,
                signature: &signature,
                intermediateCertDER: &intermediateCertDER,
                udid: &udid,
                keyUseDuration: &keyUseDuration
            )
        } catch {
            failureDescription = error.localizedDescription
        }
        return LicenseSigning(
            signature: signature as Data?,
            intermediateCertificateDER: intermediateCertDER as Data?,
            udid: udid as String?,
            keyUseDuration: keyUseDuration,
            failureDescription: failureDescription,
            failed: failureDescription != nil,
            finishedAt: Date().timeIntervalSince1970
        )
    }
}

/// Carries a main-actor callback through a background hop.
@MainActor
private final class MainThreadCallback<Value> {
    let callback: (Value) -> Void

    init(_ callback: @escaping (Value) -> Void) {
        self.callback = callback
    }
}
