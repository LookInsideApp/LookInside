import Foundation

public struct ServerSecureTimestampService: Sendable {
    private let clock: any Clock
    private let trustValidator: any TrustChainValidating
    private let rootTimestampSigner: any RootTimestampSigning

    public init(
        clock: any Clock = SystemClock(),
        trustValidator: any TrustChainValidating = DateBoundTrustChainValidator(),
        rootTimestampSigner: any RootTimestampSigning
    ) {
        self.clock = clock
        self.trustValidator = trustValidator
        self.rootTimestampSigner = rootTimestampSigner
    }

    public func issueTimestamp(
        for request: SecureTimestampRequest,
        license: LicenseEnvelope
    ) async throws -> SecureTimestampToken {
        let now = clock.now()
        try trustValidator.validate(license.certificateChain, at: now)
        return try await rootTimestampSigner.sign(request: request, at: now)
    }
}
