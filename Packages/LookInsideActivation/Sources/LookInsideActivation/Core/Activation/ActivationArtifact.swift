import Foundation

public struct ActivationArtifact: Codable, Sendable, Equatable {
    public let name: String
    public let payload: Data
    public let digest: String

    public init(name: String, payload: Data, digest: String) {
        self.name = name
        self.payload = payload
        self.digest = digest
    }
}
