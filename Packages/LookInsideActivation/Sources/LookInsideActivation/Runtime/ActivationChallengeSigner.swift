import Foundation

/// Pure validation and message-assembly logic for `license.sign_challenge`.
///
/// Extracted so the gating rules (entitlement liveness, lease validity, nonce
/// shape) can be unit-tested without standing up a Unix socket. The actual
/// RSA signature stays in `IntermediateKeyStore` — this type only
/// decides whether to sign and what bytes go in.
enum ActivationChallengeSigner {
    struct ValidatedRequest {
        let lease: IntermediateCertificateLease
        let message: Data
        let certificateDER: Data
    }

    static func validate(
        request: ActivationSignChallengeRequest,
        snapshot: ActivationPersistedState,
        decision: ActivationAccessDecision,
        evaluatedAt now: Date
    ) throws -> ValidatedRequest {
        guard let nonce = Data(hexString: request.nonce), nonce.count == 32 else {
            throw ActivationError.invalidRequest("`nonce` must be 32 hex-encoded bytes.")
        }
        guard let serverIDData = request.serverInstanceID.data(using: .utf8),
              !request.serverInstanceID.isEmpty
        else {
            throw ActivationError.invalidRequest("`server_instance_id` must be a non-empty UTF-8 string.")
        }

        switch decision.decision {
        case .allow, .allowWithWarning:
            break
        case .block:
            throw ActivationError.licenseNotActivated(
                "Activation has expired or is awaiting review; refresh license status before signing."
            )
        }

        guard let lease = snapshot.entitlementStatus?.currentLease else {
            throw ActivationError.licenseNotActivated("No intermediate certificate lease is available on this device.")
        }
        guard lease.expiresAt > now else {
            throw ActivationError.licenseNotActivated("Intermediate certificate has expired.")
        }
        guard let certificateDER = certificateDER(fromPEM: lease.certificatePEM) else {
            throw ActivationError.signingFailed("Stored certificate PEM could not be decoded to DER.")
        }

        var message = Data(capacity: nonce.count + serverIDData.count)
        message.append(nonce)
        message.append(serverIDData)

        return ValidatedRequest(lease: lease, message: message, certificateDER: certificateDER)
    }

    static func certificateDER(fromPEM pem: String) -> Data? {
        let body =
            pem
                .split(whereSeparator: \.isNewline)
                .filter { !$0.hasPrefix("-----") }
                .joined()
        return Data(base64Encoded: body)
    }
}
