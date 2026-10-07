import CryptoKit
import Foundation

/// Owns `state.json`.
///
/// Other processes write the same file: a second LookInside instance, or the
/// 2.3.x helper after a downgrade. Every write therefore starts from what is
/// on disk when the file changed since this store last read or wrote it, and
/// `reloadIfChanged()` picks up a newer file, so one process never writes
/// back a stale snapshot over another one's newer state.
///
/// A trial lives in memory only. A changed file replaces it only when the
/// file's own license material grants access (another process activated or
/// renewed); an expired or revoked license on disk, or a file that only
/// changed its telemetry, leaves the trial in place.
actor ActivationStateStore {
    private let url: URL
    private let now: @Sendable () -> Date
    private var cachedState: ActivationPersistedState
    /// The activation session was recorded as transient (a trial session
    /// before its entitlement is known) and is not on disk.
    private var holdsTransientSession = false
    /// The file version this store last read or wrote.
    private var diskVersion: DiskVersion?

    init(url: URL, now: @escaping @Sendable () -> Date = { Date() }) {
        self.url = url
        self.now = now
        cachedState = Self.loadState(from: url)
        diskVersion = DiskVersion(url: url)
    }

    /// Starts from a state already read with `loadState(from:)`.
    init(url: URL, initialState: ActivationPersistedState, now: @escaping @Sendable () -> Date = { Date() }) {
        self.url = url
        self.now = now
        cachedState = initialState
        diskVersion = DiskVersion(url: url)
    }

    func snapshot() -> ActivationPersistedState {
        cachedState
    }

    /// Re-reads `state.json` when it changed since this store last read or
    /// wrote it. Returns `true` when it adopted the file.
    @discardableResult
    func reloadIfChanged() -> Bool {
        reloadFromDisk()
    }

    func recordDeviceFingerprint(_ fingerprint: DeviceFingerprint) throws {
        reloadFromDisk()
        cachedState.deviceFingerprint = fingerprint
        try persist()
    }

    func recordActivationSession(_ session: ActivationSession) throws {
        reloadFromDisk()
        cachedState.activationSession = session
        cachedState.updatedAt = Date()
        holdsTransientSession = false
        try persist()
    }

    func recordTransientActivationSession(_ session: ActivationSession) throws {
        reloadFromDisk()
        cachedState.activationSession = session
        cachedState.updatedAt = Date()
        holdsTransientSession = true
        try persist()
    }

    func recordEntitlementStatus(_ status: EntitlementStatus) throws {
        reloadFromDisk()
        cachedState.entitlementStatus = status
        cachedState.updatedAt = Date()
        try persist()
    }

    func recordIssuedLease(_ lease: IntermediateCertificateLease) throws {
        reloadFromDisk()
        guard let status = cachedState.entitlementStatus else {
            return
        }
        cachedState.entitlementStatus = EntitlementStatus(
            license: status.license.applying(lease: lease),
            deviceBinding: status.deviceBinding,
            currentLease: lease,
            activationSession: cachedState.activationSession ?? status.activationSession,
            isEligibleForActivation: status.isEligibleForActivation,
            isEligibleForRenewal: status.isEligibleForRenewal,
            requiresLiveRefresh: status.requiresLiveRefresh,
            lastFetchedAt: Date(),
            informationalMessage: status.informationalMessage,
            warningMessage: status.warningMessage
        )
        cachedState.updatedAt = Date()
        try persist()
    }

    func recordActivationResponse(_ response: HostActivationResponse) throws {
        reloadFromDisk()
        cachedState.activationResponse = response
        cachedState.updatedAt = Date()
        try persist()
    }

    func recordRenewAttempt(success: Bool, error: String?, at date: Date = Date()) throws {
        reloadFromDisk()
        cachedState.lastRenewAttemptAt = date
        if success {
            cachedState.lastRenewSucceededAt = date
            cachedState.lastRenewError = nil
        } else {
            cachedState.lastRenewFailedAt = date
            cachedState.lastRenewError = error
        }
        cachedState.updatedAt = date
        try persist()
    }

    private var holdsMemoryOnlyMaterial: Bool {
        holdsTransientSession || cachedState.entitlementStatus?.license.licenseClass == .trial
    }

    private func persist() throws {
        var diskState = cachedState.diskBackedState
        if holdsTransientSession {
            diskState.activationSession = nil
        }
        let data: Data
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            data = try ActivationStateCoding.encoder.encode(diskState)
            try data.write(to: url, options: .atomic)
        } catch {
            throw ActivationError.stateStoreFailure(error.localizedDescription)
        }
        diskVersion = DiskVersion(url: url, contents: data)
    }

    /// Adopts the file when it changed since this store last read or wrote
    /// it (modification date, size, file number, then a content digest). A
    /// file that is missing, unchanged or cannot be decoded leaves the cache
    /// as it is. A trial held in memory survives unless the new file grants
    /// access on its own.
    @discardableResult
    private func reloadFromDisk() -> Bool {
        guard let stamp = DiskStamp(url: url), stamp != diskVersion?.stamp else {
            return false
        }
        guard let data = try? Data(contentsOf: url) else {
            return false
        }
        let version = DiskVersion(stamp: stamp, contents: data)
        guard version.digest != diskVersion?.digest else {
            diskVersion = version
            return false
        }
        guard let diskState = try? ActivationStateCoding.decoder.decode(ActivationPersistedState.self, from: data)
        else {
            return false
        }
        diskVersion = version
        var merged = diskState.diskBackedState
        if holdsMemoryOnlyMaterial, Self.grantsAccess(merged, at: now()) == false {
            merged.activationSession = cachedState.activationSession
            merged.entitlementStatus = cachedState.entitlementStatus
            merged.activationResponse = cachedState.activationResponse
        } else {
            holdsTransientSession = false
        }
        cachedState = merged
        return true
    }

    /// `true` when `state` holds license material that grants access at
    /// `date`: an activation or renewal another process stored.
    private static func grantsAccess(_ state: ActivationPersistedState, at date: Date) -> Bool {
        ActivationAccessEvaluator.decision(from: state, evaluatedAt: date).grantsAccess
    }

    static func loadState(from url: URL) -> ActivationPersistedState {
        guard let data = try? Data(contentsOf: url),
              let state = try? ActivationStateCoding.decoder.decode(ActivationPersistedState.self, from: data)
        else {
            return ActivationPersistedState()
        }
        return state.diskBackedState
    }
}

/// One version of `state.json`: its file attributes and a digest of its
/// contents. The attributes answer "changed?" cheaply; the digest tells a
/// rewrite with the same contents from a real change.
private struct DiskVersion {
    let stamp: DiskStamp
    let digest: SHA256.Digest

    init(stamp: DiskStamp, contents: Data) {
        self.stamp = stamp
        digest = SHA256.hash(data: contents)
    }

    init?(url: URL, contents: Data? = nil) {
        guard let stamp = DiskStamp(url: url),
              let contents = contents ?? (try? Data(contentsOf: url))
        else {
            return nil
        }
        self.init(stamp: stamp, contents: contents)
    }
}

/// Identifies one file on disk. An atomic write replaces the file, so the
/// file number changes even when the date and size do not.
private struct DiskStamp: Equatable {
    let modificationDate: Date?
    let size: Int?
    let fileNumber: Int?

    init?(url: URL) {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return nil
        }
        modificationDate = attributes[.modificationDate] as? Date
        size = (attributes[.size] as? NSNumber)?.intValue
        fileNumber = (attributes[.systemFileNumber] as? NSNumber)?.intValue
    }
}
