import CryptoKit
import Foundation

struct LocalActivationMaterialIssuer: ActivationMaterialIssuing {
    private let clock: any Clock

    init(clock: any Clock = SystemClock()) {
        self.clock = clock
    }

    func issueActivation(
        for challenge: ClientActivationChallenge,
        license: LicenseEnvelope,
        policy: ActivationPolicy,
        secureTimestamp: SecureTimestampToken?
    ) async throws -> SignedActivationEnvelope {
        let issuedAt = clock.now()
        let expiresAt = min(
            issuedAt.addingTimeInterval(policy.activationLifetime),
            license.certificateChain.intermediateExpiresAt
        )
        let summary: [String: String] = [
            "license_id": license.licenseID,
            "device_id": challenge.device.deviceID,
            "issued_at": ActivationStateCoding.iso8601Formatter.string(from: issuedAt),
            "expires_at": ActivationStateCoding.iso8601Formatter.string(from: expiresAt),
            "timestamped": secureTimestamp == nil ? "false" : "true",
        ]
        let payloadData = try JSONSerialization.data(withJSONObject: summary, options: [.sortedKeys])
        let artifact = ActivationArtifact(
            name: "activation.json",
            payload: payloadData,
            digest: SHA256.hash(data: payloadData).compactMap { String(format: "%02x", $0) }.joined()
        )

        return SignedActivationEnvelope(
            activationID: UUID().uuidString.lowercased(),
            challengeNonce: challenge.nonce,
            licenseID: license.licenseID,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            intermediateCertificateID: license.certificateChain.intermediateCertificateID,
            boundUDID: challenge.device.deviceID,
            artifacts: [artifact]
        )
    }
}
