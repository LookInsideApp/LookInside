import CryptoKit
import Dispatch
import Foundation

public struct InspectionTransferManifest: Codable, Sendable {
    public static let currentEncoding = "lookin-keyed-archive"
    public static let currentPayloadVersion = 1
    public let transferIdentifier: String
    public let encoding: String
    public let payloadVersion: Int
    public let byteCount: Int
    public let checksum: String
    public let chunkByteCount: Int
    public let metadata: InspectionMetadata?

    public init(transferIdentifier: String = UUID().uuidString, data: Data, metadata: InspectionMetadata? = nil) {
        self.transferIdentifier = transferIdentifier
        encoding = Self.currentEncoding
        payloadVersion = Self.currentPayloadVersion
        byteCount = data.count
        checksum = Self.digest(data)
        chunkByteCount = InspectionTransferStore.maximumChunkByteCount
        self.metadata = metadata
    }

    public func validate() throws {
        guard encoding == Self.currentEncoding, payloadVersion == Self.currentPayloadVersion,
              UUID(uuidString: transferIdentifier) != nil,
              byteCount > 0, byteCount <= InspectionTransferStore.maximumArchiveByteCount,
              chunkByteCount > 0, chunkByteCount <= InspectionTransferStore.maximumChunkByteCount,
              checksum.count == 64, checksum.allSatisfy({ $0.isHexDigit && !$0.isUppercase })
        else { throw InspectionFailure(code: "transfer.invalidManifest", message: "The model transfer manifest is invalid or unsupported.") }
    }

    public static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

/// A connection owns its transfers. No file names or local paths cross the wire.
/// Capacity is reserved at creation, including uploads that have not arrived yet.
@MainActor
public final class InspectionTransferStore {
    public nonisolated static let maximumChunkByteCount = 256 * 1024
    public nonisolated static let maximumArchiveByteCount = 128 * 1024 * 1024
    public nonisolated static let maximumStoredByteCount = 256 * 1024 * 1024

    private struct Transfer {
        let owner: String
        let manifest: InspectionTransferManifest
        let deadline: TimeInterval
        let isUpload: Bool
        var data: Data
    }

    private var transfers: [String: Transfer] = [:]
    private let lifetime: TimeInterval
    private let clock: () -> TimeInterval
    private var expiration: DispatchSourceTimer?

    public init(lifetime: TimeInterval = 60, clock: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.lifetime = lifetime
        self.clock = clock
        let expiration = DispatchSource.makeTimerSource(queue: .main)
        expiration.schedule(deadline: .now() + 1, repeating: .seconds(1))
        expiration.setEventHandler { [weak self] in self?.expire() }
        self.expiration = expiration
        expiration.resume()
    }

    deinit { expiration?.cancel() }

    public func publish(_ data: Data, owner: String, metadata: InspectionMetadata? = nil) throws -> InspectionTransferManifest {
        let manifest = InspectionTransferManifest(data: data, metadata: metadata)
        try reserve(manifest)
        transfers[manifest.transferIdentifier] = Transfer(owner: owner, manifest: manifest,
                                                          deadline: clock() + lifetime, isUpload: false, data: data)
        return manifest
    }

    public func beginUpload(_ manifest: InspectionTransferManifest, owner: String) throws {
        try reserve(manifest)
        transfers[manifest.transferIdentifier] = Transfer(owner: owner, manifest: manifest,
                                                          deadline: clock() + lifetime, isUpload: true, data: Data())
    }

    public func append(_ data: Data, offset: Int, identifier: String, owner: String) throws {
        var transfer = try ownedTransfer(identifier, owner: owner)
        guard transfer.isUpload, offset == transfer.data.count, !data.isEmpty,
              data.count <= transfer.manifest.chunkByteCount,
              data.count <= transfer.manifest.byteCount - offset
        else { throw InspectionFailure(code: "transfer.invalidChunk", message: "The chunk is oversized, out of order, or outside the transfer.") }
        transfer.data.append(data)
        transfers[identifier] = transfer
    }

    public func read(identifier: String, offset: Int, owner: String) throws -> Data {
        let transfer = try ownedTransfer(identifier, owner: owner)
        guard !transfer.isUpload, offset >= 0, offset < transfer.data.count else {
            throw InspectionFailure(code: "transfer.invalidChunk", message: "The chunk offset is outside the download.")
        }
        return transfer.data.subdata(in: offset ..< min(transfer.data.count, offset + transfer.manifest.chunkByteCount))
    }

    /// Only complete, verified uploads may reach a model decoder. Consuming is
    /// destructive even on checksum failure; clients must create a new transfer.
    public func consumeUpload(identifier: String, owner: String) throws -> Data {
        let transfer = try ownedTransfer(identifier, owner: owner)
        guard transfer.isUpload else { throw InspectionFailure.invalidParameters }
        transfers.removeValue(forKey: identifier)
        guard transfer.data.count == transfer.manifest.byteCount,
              InspectionTransferManifest.digest(transfer.data) == transfer.manifest.checksum
        else {
            throw InspectionFailure(code: "transfer.corrupted", message: "The model transfer is incomplete or its checksum does not match.")
        }
        return transfer.data
    }

    public func release(identifier: String, owner: String) throws {
        _ = try ownedTransfer(identifier, owner: owner)
        transfers.removeValue(forKey: identifier)
    }

    public func disconnect(owner: String) {
        transfers = transfers.filter { $0.value.owner != owner }
    }

    public func expire() {
        let now = clock()
        transfers = transfers.filter { $0.value.deadline > now }
    }

    private func reserve(_ manifest: InspectionTransferManifest) throws {
        try manifest.validate()
        expire()
        guard transfers[manifest.transferIdentifier] == nil,
              transfers.count < 64,
              transfers.values.reduce(0, { $0 + $1.manifest.byteCount }) <= Self.maximumStoredByteCount - manifest.byteCount
        else { throw InspectionFailure(code: "transfer.capacityExceeded", message: "Finish or release existing model transfers before starting another.") }
    }

    private func ownedTransfer(_ identifier: String, owner: String) throws -> Transfer {
        expire()
        guard let transfer = transfers[identifier], transfer.owner == owner else {
            throw InspectionFailure(code: "transfer.notFound", message: "The transfer expired, was released, or belongs to another connection.")
        }
        return transfer
    }
}

/// Accumulates bounded chunks and exposes bytes only after complete validation.
public struct InspectionTransferAssembler {
    public let manifest: InspectionTransferManifest
    private var data = Data()

    public init(manifest: InspectionTransferManifest) throws {
        try manifest.validate()
        self.manifest = manifest
    }

    public var nextOffset: Int {
        data.count
    }

    public var isComplete: Bool {
        data.count == manifest.byteCount
    }

    public mutating func append(_ chunk: Data, offset: Int) throws {
        guard offset == data.count, !chunk.isEmpty, chunk.count <= manifest.chunkByteCount,
              chunk.count <= manifest.byteCount - data.count
        else {
            throw InspectionFailure(code: "transfer.invalidChunk", message: "The model download is out of order or exceeds its manifest.")
        }
        data.append(chunk)
    }

    public func finish() throws -> Data {
        guard isComplete, InspectionTransferManifest.digest(data) == manifest.checksum else {
            throw InspectionFailure(code: "transfer.corrupted", message: "The complete model could not be verified.")
        }
        return data
    }
}

public extension InspectionValue {
    static func encoding<Value: Encodable>(_ value: Value) throws -> InspectionValue {
        try JSONDecoder().decode(InspectionValue.self, from: JSONEncoder().encode(value))
    }

    func decode<Value: Decodable>(_ type: Value.Type) throws -> Value {
        try JSONDecoder().decode(type, from: JSONEncoder().encode(self))
    }
}
