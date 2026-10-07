import Foundation

/// The answer to a 220 or 221 request on the channel.
public enum LicenseExchangeResult {
    /// The Server answered. `error` is the response attachment's error and
    /// `payload` its data.
    case response(error: NSError?, payload: Any?)
    /// The request failed on the channel (timeout, disconnect, ...).
    case transportFailure(NSError)
}

/// What signing the challenge produced.
public struct LicenseSigning: Sendable {
    public var signature: Data?
    public var intermediateCertificateDER: Data?
    public var udid: String?
    /// How long the key took in its turn (including a keychain prompt),
    /// without the wait behind other uses of the key.
    public var keyUseDuration: TimeInterval
    /// Set when signing threw.
    public var failureDescription: String?
    public var failed: Bool
    /// When the signature was ready, on the environment's clock.
    public var finishedAt: TimeInterval

    public init(
        signature: Data? = nil,
        intermediateCertificateDER: Data? = nil,
        udid: String? = nil,
        keyUseDuration: TimeInterval = 0,
        failureDescription: String? = nil,
        failed: Bool = false,
        finishedAt: TimeInterval
    ) {
        self.signature = signature
        self.intermediateCertificateDER = intermediateCertificateDER
        self.udid = udid
        self.keyUseDuration = keyUseDuration
        self.failureDescription = failureDescription
        self.failed = failed
        self.finishedAt = finishedAt
    }
}

/// The 221 LicenseVerify request.
public struct LicenseVerifyRequest {
    public let challenge: LicenseChallenge
    /// The 220's own payload, whose nonce and server instance id objects go
    /// back to the Server unchanged.
    public let challengePayload: Any?
    public let signature: Data
    public let intermediateCertificateDER: Data
    /// Empty when the runtime gave none.
    public let udid: String
}

/// Why a handshake ended without a license.
public enum LicenseHandshakeFailure: Error {
    /// The 220 response carried an error.
    case challengeRejected(NSError)
    case malformedChallenge(LicenseChallenge.Malformed)
    case challengeTransport(NSError)
    /// Signing failed or returned no signature or certificate.
    case signingFailed(detail: String?)
    /// A retry was due, but the channel is gone or the signing policy holds
    /// it back.
    case retryHeldBack
    /// The Server rejected the 221.
    case verifyRejected(NSError)
    case verifyTransport(NSError)
}

/// What a license handshake needs from the Host, for one channel.
///
/// Every call and completion happens on the main actor; `sign` may do its
/// work elsewhere as long as its completion comes back there.
@MainActor
public protocol LicenseHandshakeEnvironment: AnyObject {
    var isChannelConnected: Bool { get }
    /// The current time; only differences are used.
    func now() -> TimeInterval
    /// Asks the activation runtime's signing policy whether a handshake may
    /// start on this channel now.
    func shouldStartHandshake() -> Bool
    /// Tells the signing policy that the Server refused this channel's
    /// handshake, so it is not repeated.
    func noteHandshakeFailed()
    func sendChallenge(completion: @escaping (LicenseExchangeResult) -> Void)
    func sendVerify(_ request: LicenseVerifyRequest, completion: @escaping (LicenseExchangeResult) -> Void)
    /// Signs the challenge with this Mac's license key.
    func sign(_ challenge: LicenseChallenge, completion: @escaping (LicenseSigning) -> Void)
    /// The release the Server reported in a well-formed 220 (both fields nil
    /// for a 0.2.9 or older Server). Drives the upgrade hint only.
    func noteServerRelease(_ release: ServerRelease)
    func log(_ message: String)
}

public extension LicenseHandshakeEnvironment {
    func noteServerRelease(_: ServerRelease) {}
}

/// One license handshake: 220 LicenseChallenge, signature, 221
/// LicenseVerify, with at most one retry when the signing was slow (see
/// `LicenseHandshakeRetryPolicy`). The caller asks the signing policy
/// before the first attempt; a retry asks again.
@MainActor
public enum LicenseHandshakeFlow {
    /// Runs the handshake. `completion` gets `nil` when the Server accepted
    /// the signature.
    public static func run(
        in environment: LicenseHandshakeEnvironment,
        channelDescription: String,
        allowsRetry: Bool = true,
        completion: @escaping (LicenseHandshakeFailure?) -> Void
    ) {
        environment.log("LookInside - License: starting handshake on channel \(channelDescription) (sending 220 LicenseChallenge).")
        environment.sendChallenge { result in
            switch result {
            case let .transportFailure(error):
                environment.log("LookInside - License: 220 challenge transport error: \(error.localizedDescription)")
                completion(.challengeTransport(error))
            case let .response(error?, _):
                environment.log("LookInside - License: 220 challenge errored: \(error.localizedDescription)")
                environment.noteHandshakeFailed()
                completion(.challengeRejected(error))
            case let .response(nil, payload):
                switch LicenseChallenge.parse(payload) {
                case let .failure(malformed):
                    environment.log(
                        "LookInside - License: 220 challenge payload malformed (nonce_len=\(malformed.nonceLength), server_instance_id_len=\(malformed.serverInstanceIDLength))."
                    )
                    environment.noteHandshakeFailed()
                    completion(.malformedChallenge(malformed))
                case let .success(challenge):
                    let release = ServerRelease.parse(payload)
                    environment.log(
                        "LookInside - License: 220 Server release \(release.version ?? "<none>") (build \(release.build.map(String.init) ?? "<none>"))."
                    )
                    environment.noteServerRelease(release)
                    environment.log(
                        "LookInside - License: 220 challenge OK (server_instance_id=\(challenge.serverInstanceID)); requesting signature from the activation runtime."
                    )
                    sign(
                        challenge,
                        payload: payload,
                        in: environment,
                        channelDescription: channelDescription,
                        allowsRetry: allowsRetry,
                        completion: completion
                    )
                }
            }
        }
    }

    private static func sign(
        _ challenge: LicenseChallenge,
        payload: Any?,
        in environment: LicenseHandshakeEnvironment,
        channelDescription: String,
        allowsRetry: Bool,
        completion: @escaping (LicenseHandshakeFailure?) -> Void
    ) {
        let challengeReceivedAt = environment.now()
        environment.sign(challenge) { signing in
            // A failed or refused signing is recorded by the activation
            // runtime, which then holds every automatic signing back, so it
            // is never retried here.
            guard !signing.failed,
                  let signature = signing.signature, !signature.isEmpty,
                  let certificate = signing.intermediateCertificateDER, !certificate.isEmpty
            else {
                let detail = signing.failureDescription ?? "License signing failed."
                environment.log("LookInside - License: sign_challenge failed: \(detail)")
                completion(.signingFailed(detail: signing.failureDescription))
                return
            }
            let challengeAge = signing.finishedAt - challengeReceivedAt
            if LicenseHandshakeRetryPolicy.shouldRequestFreshChallenge(challengeAge: challengeAge, allowsRetry: allowsRetry) {
                environment.log(
                    "LookInside - License: the signature arrived \(seconds(challengeAge))s after the challenge (key use \(seconds(signing.keyUseDuration))s), past its lifetime; requesting a fresh 220."
                )
                retry(in: environment, channelDescription: channelDescription, completion: completion)
                return
            }
            let udid = signing.udid ?? ""
            environment.log(
                "LookInside - License: signature obtained (sig=\(signature.count)b, intermediate=\(certificate.count)b, udid=\(udid.isEmpty ? "<none>" : udid)); sending 221 LicenseVerify."
            )
            let request = LicenseVerifyRequest(
                challenge: challenge,
                challengePayload: payload,
                signature: signature,
                intermediateCertificateDER: certificate,
                udid: udid
            )
            environment.sendVerify(request) { result in
                switch result {
                case let .transportFailure(error):
                    environment.log("LookInside - License: 221 verify transport error: \(error.localizedDescription)")
                    completion(.verifyTransport(error))
                case let .response(error?, _):
                    environment.log("LookInside - License: 221 verify rejected by server: \(error.localizedDescription)")
                    if LicenseHandshakeRetryPolicy.shouldRetryAfterRejection(keyUseDuration: signing.keyUseDuration, allowsRetry: allowsRetry) {
                        environment.log(
                            "LookInside - License: signing took \(seconds(signing.keyUseDuration))s before the rejection; retrying once with a fresh 220."
                        )
                        retry(in: environment, channelDescription: channelDescription, completion: completion)
                        return
                    }
                    environment.noteHandshakeFailed()
                    completion(.verifyRejected(error))
                case .response(nil, _):
                    environment.log("LookInside - License: 221 verify accepted; channel \(channelDescription) marked licensed.")
                    completion(nil)
                }
            }
        }
    }

    /// The single retry. It is an automatic use of the license key like the
    /// first attempt: the signing policy decides whether it may start (it
    /// may not after a refused prompt, for example). After a one-time Allow
    /// it raises another keychain prompt; only Always Allow makes it silent.
    private static func retry(
        in environment: LicenseHandshakeEnvironment,
        channelDescription: String,
        completion: @escaping (LicenseHandshakeFailure?) -> Void
    ) {
        guard environment.isChannelConnected, environment.shouldStartHandshake() else {
            environment.log("LookInside - License: the signing policy holds the retry back on channel \(channelDescription).")
            completion(.retryHeldBack)
            return
        }
        run(in: environment, channelDescription: channelDescription, allowsRetry: false, completion: completion)
    }

    private nonisolated static func seconds(_ interval: TimeInterval) -> String {
        String(format: "%.0f", interval)
    }
}
