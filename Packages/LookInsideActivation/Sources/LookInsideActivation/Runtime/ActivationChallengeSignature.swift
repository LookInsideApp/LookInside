import Foundation

/// Input of the 220/221 license handshake signature: the 32-byte nonce from
/// `LookinRequestTypeLicenseChallenge` (hex-encoded) and the Server's instance
/// identifier. Same fields as the helper's `license.sign_challenge` request.
struct ActivationSignChallengeRequest: Codable, Sendable {
    let nonce: String
    let serverInstanceID: String
    let subjectUDIDHint: String?

    init(nonce: String, serverInstanceID: String, subjectUDIDHint: String? = nil) {
        self.nonce = nonce
        self.serverInstanceID = serverInstanceID
        self.subjectUDIDHint = subjectUDIDHint
    }

    private enum CodingKeys: String, CodingKey {
        case nonce
        case serverInstanceID = "server_instance_id"
        case subjectUDIDHint = "subject_udid_hint"
    }
}

/// Result of signing a license challenge. The Host forwards the three values
/// unchanged in the 221 `LicenseVerify` request.
public struct ActivationChallengeSignature: Equatable, Sendable {
    /// RSA-PKCS1v15-SHA256 signature over `nonce || server_instance_id.utf8`.
    public let signature: Data
    /// DER bytes of the intermediate certificate issued by LookInside Web.
    public let intermediateCertificateDER: Data
    /// Device UDID bound into the intermediate certificate lease.
    public let udid: String

    public init(signature: Data, intermediateCertificateDER: Data, udid: String) {
        self.signature = signature
        self.intermediateCertificateDER = intermediateCertificateDER
        self.udid = udid
    }

    /// The helper's `license.sign_challenge` response payload for this signature.
    public var responsePayload: ActivationSignChallengeResponsePayload {
        ActivationSignChallengeResponsePayload(
            signature: signature.base64EncodedString(),
            intermediateCertDER: intermediateCertificateDER.base64EncodedString(),
            udid: udid
        )
    }
}

/// Wire shape of the helper's `license.sign_challenge` response payload, kept
/// so the in-process result can be compared byte-for-byte with the helper's.
public struct ActivationSignChallengeResponsePayload: Codable, Equatable, Sendable {
    /// Base64-encoded RSA-PKCS1v15-SHA256 signature over `nonce || server_instance_id.utf8`.
    public let signature: String
    /// Base64-encoded DER bytes of the intermediate certificate issued by LookInsideWeb.
    public let intermediateCertDER: String
    public let udid: String

    private enum CodingKeys: String, CodingKey {
        case signature
        case intermediateCertDER = "intermediate_cert_der"
        case udid
    }
}
