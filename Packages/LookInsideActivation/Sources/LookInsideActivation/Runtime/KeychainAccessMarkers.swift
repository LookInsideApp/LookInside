import Foundation

/// What the Host remembers about the license key between launches, to decide
/// whether the keychain explainer is needed.
///
/// The markers live in the Host's own defaults, never in `state.json`, which
/// the 2.3.x helper also reads and writes. Each marker stores the identity
/// of the key it is about (the public-key hash, see
/// `IntermediateKeyStore.keyIdentity()`), so a marker for one key never
/// covers another: when the key changes, the explainer may show again.
///
/// They only make the explainer go away: a key the Host created, or one
/// that signed without a prompt, has an access list that already lists the
/// Host; a key whose explainer the user confirmed with Continue does not get
/// it again, even when it still prompts (one-time Allow).
final class KeychainAccessMarkers: Sendable {
    static let keyCreatedByHostKey = "LookInsideActivation.LicenseKeyCreatedByHost.KeyIdentity"
    static let keySignedWithoutPromptKey = "LookInsideActivation.LicenseKeySignedWithoutPrompt.KeyIdentity"
    static let explainerConfirmedKey = "LookInsideActivation.KeychainExplainerConfirmed.KeyIdentity"

    private let read: @Sendable (String) -> String?
    private let write: @Sendable (String, String) -> Void

    /// Markers in `defaults` (the Host's standard defaults in the app).
    convenience init(defaults: UserDefaults) {
        nonisolated(unsafe) let defaults = defaults
        self.init(
            read: { defaults.string(forKey: $0) },
            write: { defaults.set($1, forKey: $0) }
        )
    }

    /// Markers read and set through `read` and `write` (marker name, key
    /// identity), for tests.
    init(
        read: @escaping @Sendable (String) -> String?,
        write: @escaping @Sendable (String, String) -> Void
    ) {
        self.read = read
        self.write = write
    }

    /// `true` while the key with `identity` may still need the explainer:
    /// the Host did not create it, it has not signed without a prompt, and
    /// the user has not confirmed the explainer for it.
    func mayNeedExplainer(forKey identity: String) -> Bool {
        [Self.keyCreatedByHostKey, Self.keySignedWithoutPromptKey, Self.explainerConfirmedKey]
            .allSatisfy { read($0) != identity }
    }

    func noteKeyCreatedByHost(_ identity: String) {
        note(Self.keyCreatedByHostKey, identity)
    }

    func noteKeySignedWithoutPrompt(_ identity: String) {
        note(Self.keySignedWithoutPromptKey, identity)
    }

    func noteExplainerConfirmed(_ identity: String) {
        note(Self.explainerConfirmedKey, identity)
    }

    private func note(_ marker: String, _ identity: String) {
        guard read(marker) != identity else { return }
        write(marker, identity)
    }
}
